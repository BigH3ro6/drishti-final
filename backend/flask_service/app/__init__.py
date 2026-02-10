import os
from flask import Flask
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    CORS(app)  # Allows Flutter to talk to this backend

    # Initialize Firebase Admin SDK
    # This gives your backend "God Mode" (read/write anything)
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    
    if not firebase_admin._apps:
        if cred_path:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin Initialized")
        else:
            print("❌ Error: GOOGLE_APPLICATION_CREDENTIALS not found in .env")

    # Initialize Firestore DB Client
    app.db = firestore.client()

    # Register Routes (Placeholder)
    @app.route('/')
    def index():
        return {"status": "Drishti Backend (Firebase) Online"}

    return app