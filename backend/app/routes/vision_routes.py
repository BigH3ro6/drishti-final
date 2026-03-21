from flask import Blueprint, request, jsonify
import requests

# 1. Create the API Gateway (Traffic Cop)
vision_bp = Blueprint('vision', __name__)

# 2. Create a quick test doorway
@vision_bp.route('/test', methods=['GET'])
def test_vision():
    return jsonify({"message": "Vision Gateway is awake and ready to forward!"}), 200

# 3. The Proxy Endpoint
@vision_bp.route('/detect', methods=['POST'])
def detect_obstacles():
    try:
        # Step A: The Bouncer - Check if an image was actually sent
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
            
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({"error": "Empty image file"}), 400

        # Step B: The Traffic Cop - Forward the exact image to the ML Server
        # NOTE:  placeholder link.
        YOLO_ENDPOINT = "https://placeholder-drishti-ml.com/predict"
        
        # Package the raw image up exactly how Flutter sent it
        files = {'image': (file.filename, file.read(), file.content_type)}
        
        # Forward the photo to the ML Team's Server
        ml_response = requests.post(YOLO_ENDPOINT, files=files)
        
        # If the ML server crashes or is offline, tell Flutter gracefully
        if ml_response.status_code != 200:
            return jsonify({"error": f"ML server failed! Status Code: {ml_response.status_code}"}), 500
            
        # Step C: Grab the ML team's finished math, and hand it straight back to Flutter
        return jsonify({
            "status": "success",
            "message": "Processed successfully by ML server",
            "data": ml_response.json() 
        }), 200

    except Exception as e:
        return jsonify({"error": f"Backend Error: {str(e)}"}), 500