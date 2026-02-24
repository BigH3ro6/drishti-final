from flask import Blueprint, request, jsonify

# 1. Create the Blueprint
safety_bp = Blueprint('safety', __name__)

# --- ENDPOINT 1: THE LOCATION DOOR ---
@safety_bp.route('/location', methods=['POST'])
def update_location():
    data = request.get_json()
    
    # 🛑 THE BOUNCER: Check if the box is empty or missing data!
    if not data or 'latitude' not in data or 'longitude' not in data:
        return jsonify({
            "status": "error", 
            "message": "Bad Request: Missing latitude or longitude!"
        }), 400 # 400 means "You sent me bad data!"
    
    # If it passes the bouncer, grab the data
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    
    return jsonify({
        "status": "success", 
        "message": f"Location received perfectly! Lat: {latitude}, Lng: {longitude}"
    }), 200 # 200 means "OK / Success!"

# --- ENDPOINT 2: THE SOS DOOR ---
@safety_bp.route('/sos', methods=['POST'])
def trigger_sos():
    data = request.get_json()
    
    # 🛑 THE BOUNCER: Check if the emergency alert has a User ID
    if not data or 'user_id' not in data:
        return jsonify({
            "status": "error", 
            "message": "Bad Request: Missing user_id!"
        }), 400
        
    user_id = data.get('user_id')
    
    return jsonify({
        "status": "emergency", 
        "message": f"SOS Triggered for user: {user_id}! Caregiver has been alerted."
    }), 200