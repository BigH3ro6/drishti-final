from flask import Flask
from app.routes.safety_routes import safety_bp
from app.routes.vision_routes import vision_bp
import firebase_admin
from firebase_admin import credentials, firestore

# --- 1. CONNECTING TO THE VAULT ---
# Tell Python exactly where the VIP Master Key is located
cred = credentials.Certificate("firebase-key.json")

# Turn on the Firebase connection
firebase_admin.initialize_app(cred)

# Create a 'db' variable that we will use to save data later!
db = firestore.client()
# ----------------------------------

# 2. Create the Flask App
app = Flask(__name__)

# 3. Connect our safety doors
app.register_blueprint(safety_bp, url_prefix='/api/safety')
app.register_blueprint(vision_bp, url_prefix='/vision')

# 4. A simple test route
@app.route('/')
def home():
    return "Drishti Backend is running perfectly, and Firebase is connected!"

if __name__ == '__main__':
    # Turn on the server
    app.run(debug=True)