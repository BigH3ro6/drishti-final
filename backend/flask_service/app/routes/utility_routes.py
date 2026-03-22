import os
import requests
from flask import Blueprint, request, jsonify, current_app
from dotenv import load_dotenv
import uuid
from datetime import datetime, timezone
import cloudinary
import cloudinary.uploader

env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
print(f"Loading .env from: {env_path}")
load_dotenv(env_path)

utility_bp = Blueprint('utility', __name__)


@utility_bp.route('/api/weather', methods=['GET'])
def get_weather():
    lat = request.args.get('lat')
    lng = request.args.get('lng')
    
    if not lat or not lng:
        return jsonify({"error": "Missing lat or lng parameters"}), 400
    
    api_key = os.getenv('OPENWEATHERMAP_API_KEY')
    if not api_key:
        return jsonify({"error": "OpenWeatherMap API key not configured", "debug": "Key not found in env"}), 500
    
    try:
        weather_url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lng}&appid={api_key}&units=metric"
        response = requests.get(weather_url, timeout=10)
        
        if response.status_code != 200:
            return jsonify({"error": "Failed to fetch weather data", "details": response.json(), "debug_key": api_key[:10]}), response.status_code
        
        data = response.json()
        
        temp = round(data['main']['temp'])
        condition = data['weather'][0]['main']
        description = data['weather'][0]['description']
        location = data.get('name', 'Unknown location')
        
        tts_string = f"It is {temp} degrees and {condition} in {location}"
        
        return jsonify({
            "location": location,
            "temp_c": temp,
            "temp_f": round(temp * 9/5 + 32),
            "condition": condition,
            "description": description,
            "tts_string": tts_string
        }), 200
        
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Request failed: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"error": f"Unexpected error: {str(e)}"}), 500


@utility_bp.route('/api/voice/messages', methods=['GET'])
def get_voice_messages():
    try:
        chat_id = request.args.get('chat_id')

        if not chat_id:
            return jsonify({"error": "chat_id is required"}), 400

        db = current_app.db
        messages_ref = db.collection('messages').where('chat_id', '==', chat_id)
        docs = messages_ref.stream()

        messages = []
        for doc in docs:
            msg_data = doc.to_dict()
            if 'id' not in msg_data:
                msg_data['id'] = doc.id
            messages.append(msg_data)

        def safe_sort_key(msg):
            ts = msg.get('timestamp')
            if hasattr(ts, 'timestamp'):
                return ts.timestamp()
            elif isinstance(ts, str):
                try:
                    # Convert the string into a sortable number
                    dt = datetime.strptime(ts, '%a, %d %b %Y %H:%M:%S GMT')
                    return dt.timestamp()
                except Exception:
                    return 0 # Put unreadable strings at the top
                    
            return 0 
        messages.sort(key=safe_sort_key)

        return jsonify({
            "status": "success",
            "messages": messages,
            "count": len(messages) 
        }), 200

    except Exception as e:
        print(f"Fetch Error: {e}")
        return jsonify({"error": str(e)}), 500


@utility_bp.route('/api/voice/messages/<message_id>', methods=['DELETE'])
def delete_voice_message(message_id):
    try:
        db = current_app.db
        
        # Target the specific document in the 'messages' collection and delete it
        db.collection('messages').document(message_id).delete()
        
        return jsonify({
            "status": "success", 
            "message": f"Message {message_id} deleted successfully"
        }), 200
        
    except Exception as e:
        return jsonify({"error": f"Failed to delete message: {str(e)}"}), 500
    
@utility_bp.route('/api/voice/upload', methods=['POST'])
def upload_voice_message():
    try:
        # 1. Grab the metadata from the Flutter request
        sender_id = request.form.get('sender_id')
        receiver_id = request.form.get('receiver_id')
        chat_id = request.form.get('chat_id')
        
        # 2. Grab the actual audio file
        if 'audio' not in request.files:
            return jsonify({"error": "No audio file provided"}), 400
            
        audio_file = request.files['audio']
        
        # 3. Upload to Cloudinary 
        # Note: resource_type='video' is required for audio files in Cloudinary!
        upload_result = cloudinary.uploader.upload(
            audio_file, 
            resource_type="video",
            folder="drishti/voice_notes" # Keeps your cloud storage organized
        )
        
        # This is the "content_url" your Flutter UI is looking for!
        audio_url = upload_result.get('secure_url') 
        
        # 4. Save the metadata to Firestore
        db = current_app.db # Assuming you attached your Firestore client to current_app
        message_id = str(uuid.uuid4())
        
        message_data = {
            "id": message_id,
            "chat_id": chat_id,
            "sender_id": sender_id,
            "receiver_id": receiver_id,
            "content_url": audio_url,
            "timestamp": datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT'),
            "read_status": False,
            "type": "VOICE"
        }
        
        db.collection('messages').document(message_id).set(message_data)
        
        return jsonify({
            "status": "success",
            "message": "Voice note uploaded",
            "data": message_data
        }), 200

    except Exception as e:
        print(f"Upload Error: {e}")
        return jsonify({"error": str(e)}), 500

