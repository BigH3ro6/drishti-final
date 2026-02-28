from flask import Blueprint, request, jsonify
from datetime import datetime
from firebase_admin import firestore

# Create the Blueprint (The Doorway)
safety_bp = Blueprint('safety', __name__)

@safety_bp.route('/sos', methods=['POST'])
def trigger_sos():
    try:
        # 1. Receive the package from the mobile app
        data = request.get_json()
        
        # 2. The Bouncer: Check if anything is missing
        if not data or 'latitude' not in data or 'longitude' not in data or 'user_id' not in data:
            return jsonify({"error": "Missing GPS location or user ID!"}), 400
            
        # 3. Open the connection to the Firebase Vault
        db = firestore.client()
        
        # 4. Prepare the official file to be saved (with a time stamp!)
        sos_alert = {
            "user_id": data['user_id'],
            "latitude": data['latitude'],
            "longitude": data['longitude'],
            "timestamp": datetime.now(),
            "status": "active"
        }
        
        # 5. THE MAGIC: Save it permanently into a Firebase folder called 'sos_alerts'
        db.collection('sos_alerts').add(sos_alert)
        
        # 6. Tell the mobile app it worked!
        return jsonify({
            "message": "SOS Alert safely locked in the vault!", 
            "data": sos_alert
        }), 201
        
    except Exception as e:
        # If anything crashes, tell us what went wrong
        return jsonify({"error": str(e)}), 500