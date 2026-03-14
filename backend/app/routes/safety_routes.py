from flask import Blueprint, request, jsonify

# 1. Create the Blueprint 
safety_bp = Blueprint('safety', __name__)

# --- ENDPOINT 1: THE LOCATION DOOR ---
# The app will send GPS data here every 30 seconds
@safety_bp.route('/location', methods=['POST'])
def update_location():
    # We will write the database saving code here later!
    
    return jsonify({
        "status": "success", 
        "message": "Location received perfectly!"
    }), 200

# --- ENDPOINT 2: THE SOS DOOR ---
# The app will hit this when the panic button is pressed
@safety_bp.route('/sos', methods=['POST'])
def trigger_sos():
    # write the alarm and push notification code here later!
    
    return jsonify({
        "status": "emergency", 
        "message": "SOS Triggered! Caregiver has been alerted."
    }), 200