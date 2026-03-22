import os
import firebase_admin
from firebase_admin import credentials, firestore, auth

# This ensures Firebase only initializes once
if not firebase_admin._apps:
    # 1. Find exactly where this current python file is living
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 2. Go up two levels to the 'flask_service' folder, then into 'certs'
    base_dir = os.path.dirname(os.path.dirname(current_dir))
    cert_path = os.path.join(base_dir, 'certs', 'serviceAccountKey.json')
    
    try:
        # 3. Load the key and connect to Firebase
        cred = credentials.Certificate(cert_path)
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully!")
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        print(f"I was looking for the key here: {cert_path}")

# Export the database and auth modules so your other developers can use them!
db = firestore.client()
firebase_auth = auth