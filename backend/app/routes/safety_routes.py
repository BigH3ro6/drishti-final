from flask import Blueprint, request, jsonify
from datetime import datetime, timezone #  IMPORTING THE TIME MACHINE

# 1. Create the Blueprint
safety_bp = Blueprint('safety', __name__)

# --- ENDPOINT 1: THE LOCATION DOOR ---
@safety_bp.route('/location', methods=['POST'])
def update_location():
    data = request.get_json()
    
    # THE BOUNCER
    if not data or 'latitude' not in data or 'longitude' not in data:
        return jsonify({
            "status": "error", 
            "message": "Bad Request: Missing latitude or longitude!"
        }), 400 
    
    # Grab the data
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    
    # 🕒 THE TIME STAMP: Get the exact current time in UTC
    timestamp = datetime.now(timezone.utc).isoformat()
    
    return jsonify({
        "status": "success", 
        "message": f"Location received at {timestamp}! Lat: {latitude}, Lng: {longitude}"
    }), 200

# --- ENDPOINT 2: THE SOS DOOR ---
@safety_bp.route('/sos', methods=['POST'])
def trigger_sos():
    data = request.get_json()
    
    # THE BOUNCER
    if not data or 'user_id' not in data:
        return jsonify({
            "status": "error", 
            "message": "Bad Request: Missing user_id!"
        }), 400
        
    user_id = data.get('user_id')
    
    # THE TIME STAMP
    timestamp = datetime.now(timezone.utc).isoformat()
    
    return jsonify({
        "status": "emergency", 
        "message": f"SOS Triggered for user {user_id} at {timestamp}! Caregiver alerted."
    }), 200