from flask import request, jsonify
from functools import wraps
from app.services.firebase_core import firebase_auth

def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Missing or invalid token"}), 401

        token = auth_header.split(' ')[1]
        
        try:
            # Send the token to Google to verify it
            decoded_token = firebase_auth.verify_id_token(token)
            
            # Attach the user's secure ID to the request so our routes can use it
            request.user_uid = decoded_token['uid']
            
        except Exception as e:
            # If the token is fake or expired, block them!
            return jsonify({"error": f"Invalid token: {str(e)}"}), 401

        return f(*args, **kwargs)
    return decorated_function