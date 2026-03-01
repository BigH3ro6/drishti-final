from flask import Blueprint, request, jsonify
from app.services.firebase_core import db
from app.middleware.auth_middleware import require_auth
from firebase_admin import firestore

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