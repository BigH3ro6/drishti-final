from flask import Blueprint, request, jsonify
from datetime import datetime
from firebase_admin import firestore

safety_bp = Blueprint('safety', __name__)

@safety_bp.route('/sos', methods=['POST'])
def trigger_sos():
    try:
        data = request.get_json()
        
        # The Bouncer: Check for missing data
        if not data or 'latitude' not in data or 'longitude' not in data or 'user_id' not in data:
            return jsonify({"error": "Missing GPS location or user ID!"}), 400
            
        db = firestore.client()
        user_id = data['user_id']
        
        # --- REQUIREMENT 1: Update status = "SOS" in Firestore ---
        # We use merge=True so we don't accidentally delete the user's other profile info!
        db.collection('users').document(user_id).set({"status": "SOS"}, merge=True)
        
        # --- REQUIREMENT 2: Create a record in the 'incidents' collection ---
        incident_data = {
            "user_id": user_id,
            "latitude": data['latitude'],
            "longitude": data['longitude'],
            "timestamp": datetime.now(),
            "resolved": False
        }
        db.collection('incidents').add(incident_data)
        
        # --- REQUIREMENT 3: Push Notifications ---
        # (We will add the FCM notification code right here in the next step!)
        
        return jsonify({
            "message": "SOS triggered! User status updated and incident recorded."
        }), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
    
    
@safety_bp.route('/location', methods=['POST'])
def update_location():
    try:
        data = request.get_json()
        
        # 1. The Bouncer: Check for missing data
        if not data or 'latitude' not in data or 'longitude' not in data or 'user_id' not in data:
            return jsonify({"error": "Missing GPS location or user ID!"}), 400
            
        db = firestore.client()
        user_id = data['user_id']
        
        # 2. Prepare the tracking data
        location_data = {
            "latitude": data['latitude'],
            "longitude": data['longitude'],
            "last_updated": datetime.now()
        }
        
        # 3. Save to 'tracking' collection (Overwriting the previous location)
        db.collection('tracking').document(user_id).set(location_data, merge=True)
        
        return jsonify({
            "message": "Location updated successfully!"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500



    