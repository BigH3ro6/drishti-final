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