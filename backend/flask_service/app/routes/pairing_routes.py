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