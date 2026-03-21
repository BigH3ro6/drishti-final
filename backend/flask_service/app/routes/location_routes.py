from flask import Blueprint, request, jsonify
from firebase_admin import firestore
from datetime import datetime, timezone
from app.routes.pairing_routes import require_auth 

location_bp = Blueprint('location', __name__)
db = firestore.client()

# -------------------------------------------------------------------
# 1. VISUALLY IMPAIRED USER: Push current GPS coordinates to Firestore
# -------------------------------------------------------------------
@location_bp.route('/update-location', methods=['POST'])
@require_auth
def update_location():
    uid = request.user_uid
    data = request.json

    lat = data.get('latitude')
    lng = data.get('longitude')

    if lat is None or lng is None:
        return jsonify({"error": "Missing latitude or longitude"}), 400

    # Bundle the coordinates with a fresh timestamp
    location_data = {
        "latitude": lat,
        "longitude": lng,
        "updated_at": datetime.now(timezone.utc)
    }

    # Save it securely inside the user's main profile document
    db.collection('users').document(uid).update({
        "last_known_location": location_data
    })

    return jsonify({"message": "Location updated successfully"}), 200


# -------------------------------------------------------------------
# 2. CAREGIVER: Securely fetch the linked user's GPS coordinates
# -------------------------------------------------------------------
@location_bp.route('/get-location/<target_uid>', methods=['GET'])
@require_auth
def get_location(target_uid):
    caregiver_uid = request.user_uid

    link_doc = db.collection('users').document(caregiver_uid).collection('linked_blind_users').document(target_uid).get()
    
    if not link_doc.exists:
        return jsonify({"error": "Unauthorized. You are not linked to this user."}), 403

    # Fetch the patient's profile to grab their location data
    target_user_doc = db.collection('users').document(target_uid).get()
    if not target_user_doc.exists:
         return jsonify({"error": "User not found"}), 404

    user_data = target_user_doc.to_dict()
    location = user_data.get('last_known_location')

    if not location:
        return jsonify({"error": "No location data available for this user yet"}), 404

    return jsonify({"location": location}), 200

# -------------------------------------------------------------------
# 3. CAREGIVER: Save a specific place for Geofencing/Alerts
# -------------------------------------------------------------------
@location_bp.route('/add-saved-place', methods=['POST'])
@require_auth
def add_saved_place():
    uid = request.user_uid
    data = request.json

    name = data.get('name')
    lat = data.get('latitude')
    lng = data.get('longitude')

    if not name or lat is None or lng is None:
        return jsonify({"error": "Missing name, latitude, or longitude"}), 400

    # Bundle the place data with a default 100-meter alert radius
    place_data = {
        "name": name,
        "latitude": lat,
        "longitude": lng,
        "radius_meters": 100, 
        "alerts_enabled": True,
        "created_at": datetime.now(timezone.utc)
    }

    # Save it to a brand new 'saved_places' subcollection inside the caregiver's profile
    db.collection('users').document(uid).collection('saved_places').add(place_data)

    return jsonify({"message": "Saved place successfully added!"}), 201

# -------------------------------------------------------------------
# 4. CAREGIVER: Fetch all saved places
# -------------------------------------------------------------------
@location_bp.route('/get-saved-places', methods=['GET'])
@require_auth
def get_saved_places():
    uid = request.user_uid
    try:
        # Fetch all documents in the caregiver's saved_places subcollection
        places_ref = db.collection('users').document(uid).collection('saved_places').stream()
        
        places_list = []
        for doc in places_ref:
            place_data = doc.to_dict()
            place_data['id'] = doc.id 
            places_list.append(place_data)
            
        return jsonify({"places": places_list}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500