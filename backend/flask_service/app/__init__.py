import os
from flask import Flask
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

# 1. Get the absolute path of the directory one level up (the project root)
env_path = os.path.join(os.path.dirname(_file_), '..', '.env')

load_dotenv(env_path, override=False)

def create_app():
    app = Flask(__name__)
    CORS(app)

    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    
    if not firebase_admin._apps:
        if cred_path:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            print("Firebase Admin Initialized")
        else:
            print("Error: GOOGLE_APPLICATION_CREDENTIALS not found in .env")

    app.db = firestore.client()

    from .services.storage_service import init_storage
    init_storage(app)

    @app.route('/')
    def index():
        return {"status": "Drishti Backend (Firebase) Online"}
    
    from .routes.main import main_bp
    app.register_blueprint(main_bp)

    from .routes.utility_routes import utility_bp
    app.register_blueprint(utility_bp)

    from .routes.vision_routes import vision_bp
    app.register_blueprint(vision_bp, url_prefix='/api/vision')
    
    from .routes.auth_routes import auth_bp
    app.register_blueprint(auth_bp) 

    from .routes.pairing_routes import pairing_bp
    app.register_blueprint(pairing_bp)
    
    from .routes.location_routes import location_bp
    app.register_blueprint(location_bp)
    
    from .routes.safety_routes import safety_bp
    app.register_blueprint(safety_bp)
    return app
