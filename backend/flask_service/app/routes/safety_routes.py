from flask import Blueprint, request, jsonify
from datetime import datetime
from firebase_admin import firestore, messaging

safety_bp = Blueprint('safety', __name__)

@safety_bp.route('/api/safety/sos', methods=['POST'])
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
            "timestamp": firestore.SERVER_TIMESTAMP,
            "resolved": False
        }
        db.collection('incidents').add(incident_data)
        
        # --- REQUIREMENT 3: Push Notifications ---
        #  the FCM notification code 
        alert_message = messaging.Message(
            notification=messaging.Notification(
                title="🚨 EMERGENCY SOS 🚨",
                body="The user has triggered an SOS alert! Immediate assistance required."
            ),
            # We send this to a specific "channel" that the Caregiver's phone will be listening to
            topic=f"caregiver_alerts_{user_id}" 
        )
        
        # Fire the notification!
        messaging.send(alert_message)

        
        return jsonify({
            "message": "SOS triggered! User status updated and incident recorded."
        }), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

    
@safety_bp.route('/api/location', methods=['POST'])
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
            "last_updated": firestore.SERVER_TIMESTAMP
        }
        
        # 3. Save to 'tracking' collection (Overwriting the previous location)
        db.collection('tracking').document(user_id).set(location_data, merge=True)
        
        return jsonify({
            "message": "Location updated successfully!"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500



    