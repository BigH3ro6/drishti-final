from flask import Flask
from flask_cors import CORS

# 1. We are importing YOUR doors from the file you just made!
from app.routes.safety_routes import safety_bp

# 2. This creates the actual Server Building
app = Flask(__name__)
CORS(app) # This unlocks the doors so the mobile app can reach them

# 3. This attaches your Safety doors to the building
app.register_blueprint(safety_bp, url_prefix='/api/v1/safety')

# 4. A simple front door just to test if the server is awake
@app.route('/', methods=['GET'])
def health_check():
    return {"status": "online", "message": "Drishti Backend is Awake!"}

# 5. This turns the power ON when you run the file
if __name__ == '__main__':
    print("Starting Drishti Server...")
    app.run(host='0.0.0.0', port=5000, debug=True)