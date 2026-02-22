from flask import request, jsonify
from functools import wraps

def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # 1. Grab the Authorization header from the incoming request
        auth_header = request.headers.get('Authorization')
        
        # 2. If it's missing or formatted wrong, block them
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Missing or invalid token"}), 401

        # 3. Extract just the token part (ignoring the word "Bearer ")
        token = auth_header.split(' ')[1]
        
        # Firebase verification will go right here in the next step!
        return f(*args, **kwargs)
    return decorated_function