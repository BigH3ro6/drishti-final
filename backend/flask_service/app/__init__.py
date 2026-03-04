import os
from flask import Flask
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore, storage
from dotenv import load_dotenv

load_dotenv()

def create_app():
    app = Flask(__name__)
    CORS(app)  # Allows Flutter to talk to this backend

    # Initialize Firebase Admin SDK
    # This gives your backend "God Mode" (read/write anything)
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    bucket_name = os.getenv('FIREBASE_STORAGE_BUCKET')
    
    if not firebase_admin._apps:
        if cred_path:
            firebase_options = {'storageBucket': bucket_name} if bucket_name else None
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred, firebase_options)
            print("Firebase Admin Initialized")
        else:
            print("Error: GOOGLE_APPLICATION_CREDENTIALS not found in .env")

    # Initialize Firestore DB Client
    app.db = firestore.client()

    # Initialize Firebase Storage
    app.bucket = storage.bucket()
    app.storage_client = storage

    # Register Routes (Placeholder)
    @app.route('/')
    def index():
        return {"status": "Drishti Backend (Firebase) Online"}
    
    # Register Blueprints
    from .routes.main import main_bp
    app.register_blueprint(main_bp)

    from .routes.utility_routes import utility_bp
    app.register_blueprint(utility_bp)

    return app