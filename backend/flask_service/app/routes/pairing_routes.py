from flask import Blueprint, request, jsonify
from app.services.firebase_core import db
from app.middleware.auth_middleware import require_auth
import random
import string

# Blueprint to hold all the linking/pairing routes
pairing_bp = Blueprint('pairing', __name__)

@pairing_bp.route('/generate-code', methods=['POST'])
@require_auth
def generate_code():
    # 1. Get the Blind User's secure ID
    uid = request.user_uid
    
    # 2. Generate a 6-character random code (Uppercase letters and numbers)
    code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    
    # 3. Save this code to a new 'pairing_codes' collection in Firestore
    db.collection('pairing_codes').document(code).set({
        "blind_user_uid": uid,
        "status": "active"
    })
    
    # 4. Send the code back to the Flutter app so the screen can read it out loud
    return jsonify({"pairing_code": code}), 200



@pairing_bp.route('/link-caregiver', methods=['POST'])
@require_auth
def link_caregiver():
    # 1. Get the Caregiver's secure ID (from the middleware)
    caregiver_uid = request.user_uid
    
    # 2. Get the 6-digit code they typed into the Flutter app
    code = request.json.get('code')
    
    # 3. Look up this code in the database
    code_ref = db.collection('pairing_codes').document(code)
    code_doc = code_ref.get()
    
    # 4. If the code is fake or already used, reject them!
    if not code_doc.exists or code_doc.to_dict().get('status') != 'active':
        return jsonify({"error": "Invalid or expired pairing code"}), 400
        
    # 5. Find out which Blind User generated this code
    blind_uid = code_doc.to_dict().get('blind_user_uid')
    
    # 6. Link them together in the database!
    # (We save the Caregiver under the Blind User and the Blind User under the Caregiver)
    db.collection('users').document(blind_uid).collection('linked_caregivers').document(caregiver_uid).set({"status": "linked"})
    db.collection('users').document(caregiver_uid).collection('linked_blind_users').document(blind_uid).set({"status": "linked"})
    
    # 7. Deactivate the code so no one else can ever use it again
    code_ref.update({"status": "used"})
    
    return jsonify({"message": "Successfully linked to user!"}), 200

@pairing_bp.route('/linked-users', methods=['GET'])
@require_auth
def get_linked_users():
    uid = request.user_uid
    
    # 1. Find out who is asking (Caregiver or Blind User)
    user_doc = db.collection('users').document(uid).get()
    if not user_doc.exists:
        return jsonify({"error": "User profile not found"}), 404

    role = user_doc.to_dict().get('role')
    linked_users = []

    # 2. Look in the correct sub-folder based on their role
    if role == 'CAREGIVER':
        sub_col = 'linked_blind_users'
    else:
        sub_col = 'linked_caregivers'

    # 3. Get all the linked IDs
    links = db.collection('users').document(uid).collection(sub_col).get()

    # 4. Fetch the actual profile data (Name, Role, etc.) for each ID
    for link in links:
        linked_uid = link.id
        linked_profile = db.collection('users').document(linked_uid).get()
        if linked_profile.exists:
            profile_data = linked_profile.to_dict()
            profile_data['uid'] = linked_uid 
            linked_users.append(profile_data)

    return jsonify({"linked_users": linked_users}), 200

@pairing_bp.route('/unlink-user', methods=['POST'])
@require_auth
def unlink_user():
    uid = request.user_uid
    target_uid = request.json.get('target_uid')
    
    if not target_uid:
        return jsonify({"error": "Missing target_uid parameter"}), 400

    # 1. Find out who is asking so we know which folders to look in
    user_doc = db.collection('users').document(uid).get()
    if not user_doc.exists:
        return jsonify({"error": "User profile not found"}), 404

    role = user_doc.to_dict().get('role')

    # 2. Assign the correct folder names based on the role
    if role == 'CAREGIVER':
        my_sub_col = 'linked_blind_users'
        their_sub_col = 'linked_caregivers'
    else:
        my_sub_col = 'linked_caregivers'
        their_sub_col = 'linked_blind_users'

    # 3. Delete the link from my profile
    db.collection('users').document(uid).collection(my_sub_col).document(target_uid).delete()
    
    # 4. Delete the link from their profile
    db.collection('users').document(target_uid).collection(their_sub_col).document(uid).delete()

    return jsonify({"message": "Successfully unlinked users!"}), 200