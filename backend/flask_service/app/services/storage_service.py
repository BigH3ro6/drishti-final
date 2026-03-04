import os
import uuid
from datetime import datetime


def init_storage(app):
    bucket_name = os.getenv('FIREBASE_STORAGE_BUCKET')
    if bucket_name:
        app.bucket = app.storage_client.bucket(bucket_name)
    else:
        app.bucket = app.storage_client.bucket()
    return app.bucket


def upload_audio_file(audio_file, sender_id, chat_id):
    from firebase_admin import storage
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_id = str(uuid.uuid4())[:8]
    file_extension = audio_file.filename.split('.')[-1] if '.' in audio_file.filename else 'mp3'
    
    blob_path = f"voice_notes/{chat_id}/{sender_id}_{timestamp}_{unique_id}.{file_extension}"
    blob = storage.bucket().blob(blob_path)
    
    blob.upload_from_file(audio_file, content_type=f"audio/{file_extension}")
    
    blob.make_public()
    
    return {
        "download_url": blob.public_url,
        "blob_path": blob_path,
        "timestamp": timestamp
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
