import os
import requests
from flask import Blueprint, request, jsonify, current_app
from dotenv import load_dotenv

env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
print(f"Loading .env from: {env_path}")
load_dotenv(env_path)

from ..services.storage_service import upload_audio_file, save_message_to_firestore

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


@utility_bp.route('/api/voice/upload', methods=['POST'])
def upload_voice():
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400
    
    audio_file = request.files['audio']
    sender_id = request.form.get('sender_id')
    receiver_id = request.form.get('receiver_id')
    chat_id = request.form.get('chat_id')
    
    if not all([sender_id, receiver_id, chat_id]):
        return jsonify({"error": "Missing required parameters: sender_id, receiver_id, chat_id"}), 400
    
    try:
        upload_result = upload_audio_file(audio_file, sender_id, chat_id)
        
        db = current_app.db
        message_id = save_message_to_firestore(
            db=db,
            sender_id=sender_id,
            receiver_id=receiver_id,
            chat_id=chat_id,
            audio_url=upload_result['download_url']
        )
        
        return jsonify({
            "status": "success",
            "message": "Voice message uploaded successfully",
            "audio_url": upload_result['download_url'],
            "message_id": message_id
        }), 200
        
    except Exception as e:
        error_msg = str(e)
        if "bucket does not exist" in error_msg:
            return jsonify({
                "error": "Firebase Storage bucket not configured",
                "details": "Please enable Firebase Storage and update FIREBASE_STORAGE_BUCKET in .env"
            }), 500
        return jsonify({"error": f"Upload failed: {str(e)}"}), 500
