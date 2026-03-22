from flask import Blueprint, request, jsonify
from app.services.firebase_core import db
from app.middleware.auth_middleware import require_auth
from firebase_admin import firestore
import cloudinary
import cloudinary.uploader

#Blueprint to hold all authentication routes
auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/sync-profile', methods=['POST'])
@require_auth
def sync_profile():
    # 1. Grab the secure User ID that Security Guard verified
    uid = request.user_uid
    
    # 2. Get the data the Flutter app sent
    data = request.json
    role = data.get('role')
    name = data.get('name', 'Unknown User')

    # 3. Security check: Make sure they pick a valid role
    if role not in ["BLIND", "CAREGIVER"]:
        return jsonify({"error": "Invalid role. Must be BLIND or CAREGIVER"}), 400

    # 4. Save them to the Firestore database!
    db.collection('users').document(uid).set({
        "name": name,
        "role": role,
        "created_at": firestore.SERVER_TIMESTAMP
    }, merge=True)
    
    return jsonify({"message": "Profile saved successfully!", "uid": uid}), 200

@auth_bp.route('/profile', methods=['GET'])
@require_auth
def get_profile():
    # 1. Grab the secure User ID
    uid = request.user_uid
    
    # 2. Go to the Firestore database and look for this specific user
    user_doc = db.collection('users').document(uid).get()
    
    # 3. If they don't exist in the database, tell the frontend
    if not user_doc.exists:
        return jsonify({"error": "User not found"}), 404
        
    # 4. If they do exist, send all their data back to the app!
    return jsonify(user_doc.to_dict()), 200

@auth_bp.route('/update-profile', methods=['PUT'])
@require_auth
def update_profile():
    uid = request.user_uid
    data = request.json
    
    update_data = {}
    if 'name' in data:
        update_data['name'] = data['name']
    if 'phone' in data:
        update_data['phone'] = data['phone']
    if 'medical_notes' in data:
        update_data['medical_notes'] = data['medical_notes']
        
    if update_data:
        db.collection('users').document(uid).update(update_data)
        
    return jsonify({"message": "Profile updated successfully!"}), 200

@auth_bp.route('/upload-profile-image', methods=['POST'])
@require_auth
def upload_profile_image():
    try:
        uid = request.user_uid
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
            
        image_file = request.files['image']

        # --- NEW: Delete the old image first! ---
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            old_url = user_doc.to_dict().get('profile_image_url')
            if old_url:
                try:
                    parts = old_url.split('/upload/')
                    if len(parts) > 1:
                        path_part = parts[1]
                        # Remove the 'v12345/' version tag if it exists
                        if path_part.startswith('v'):
                            path_part = path_part.split('/', 1)[1]
                        # Remove the '.jpg' or '.png' extension
                        public_id = path_part.rsplit('.', 1)[0]
                        
                        # Tell Cloudinary to delete the old file!
                        cloudinary.uploader.destroy(public_id)
                        print(f"Deleted old profile picture: {public_id}")
                except Exception as e:
                    print(f"Failed to delete old image: {e}")
        # ----------------------------------------
        
        # Upload the NEW image to Cloudinary
        upload_result = cloudinary.uploader.upload(
            image_file, 
            folder="drishti/profile_pictures"
        )
        
        image_url = upload_result.get('secure_url') 
        
        # Save the new URL into their Firestore profile
        db.collection('users').document(uid).update({
            "profile_image_url": image_url
        })
        
        return jsonify({"status": "success", "profile_image_url": image_url}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500