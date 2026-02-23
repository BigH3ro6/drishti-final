from flask import Blueprint, request, jsonify

# 1. Create the Blueprint
safety_bp = Blueprint('safety', __name__)

# --- ENDPOINT 1: THE LOCATION DOOR ---
@safety_bp.route('/location', methods=['POST'])
def update_location():
    # 1. Catch the data the phone sent!
    data = request.get_json()
    
    # 2. Extract the exact GPS coordinates from the package
    latitude = data.get('latitude', 'Unknown')
    longitude = data.get('longitude', 'Unknown')
    
    # We will write the database saving code here later!
    
    return jsonify({
        "status": "success", 
        "message": f"Location received perfectly! Lat: {latitude}, Lng: {longitude}"
    }), 200

# --- ENDPOINT 2: THE SOS DOOR ---
@safety_bp.route('/sos', methods=['POST'])
def trigger_sos():
    # 1. Catch the emergency data!
    data = request.get_json()
    user_id = data.get('user_id', 'Unknown User')
    
    # We will write the alarm and push notification code here later!
    
    return jsonify({
        "status": "emergency", 
        "message": f"SOS Triggered for user: {user_id}! Caregiver has been alerted."
    }), 200