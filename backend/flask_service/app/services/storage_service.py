import os
import uuid
from datetime import datetime
from dotenv import load_dotenv

env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(env_path)

import cloudinary
from cloudinary import uploader as cloudinary_uploader

def init_storage(app):
    cloudinary_url = os.getenv('CLOUDINARY_URL')
    print(f"DEBUG: CLOUDINARY_URL: {cloudinary_url}")
    
    if cloudinary_url:
        cloudinary.config().cloud_name = cloudinary.config().cloud_name
        cloudinary.config().api_key = cloudinary.config().api_key
        cloudinary.config().api_secret = cloudinary.config().api_secret
        
        parts = cloudinary_url.replace('cloudinary://', '').split('@')
        credentials = parts[0].split(':')
        cloud_name = parts[1] if len(parts) > 1 else None
        
        if cloud_name:
            cloudinary.config().cloud_name = cloud_name
        if len(credentials) >= 2:
            cloudinary.config().api_key = credentials[0]
            cloudinary.config().api_secret = credentials[1]
    
    print(f"DEBUG: Cloud name after config: {cloudinary.config().cloud_name}")
    
    app.cloudinary_configured = True
    return True


def upload_audio_file(audio_file, sender_id, chat_id):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_id = str(uuid.uuid4())[:8]
    file_extension = audio_file.filename.split('.')[-1] if '.' in audio_file.filename else 'mp3'
    
    audio_file.seek(0)
    
    public_id = f"voice_notes/{chat_id}/{sender_id}_{timestamp}_{unique_id}"
    
    print(f"DEBUG: Uploading with public_id: {public_id}")
    
    result = cloudinary_uploader.upload(
        audio_file,
        resource_type="auto",
        public_id=public_id,
        folder="drishti"
    )
    
    return {
        "download_url": result['secure_url'],
        "public_id": result['public_id'],
        "timestamp": timestamp,
        "duration": result.get('duration')
    }


def save_message_to_firestore(db, sender_id, receiver_id, chat_id, audio_url, duration=None):
    message_data = {
        "sender_id": sender_id,
        "receiver_id": receiver_id,
        "chat_id": chat_id,
        "type": "VOICE",
        "content_url": audio_url,
        "read_status": False,
        "timestamp": datetime.now()
    }
    
    if duration:
        message_data["duration"] = duration
    
    doc_ref = db.collection('messages').document()
    doc_ref.set(message_data)
    
    return doc_ref.id
