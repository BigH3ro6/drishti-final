from flask import Blueprint, request, jsonify
from ultralytics import YOLO
import cv2
import numpy as np

# 1. Create the AI Hallway
vision_bp = Blueprint('vision', __name__)

# 2. Load the AI Brain! 
# We use 'yolov8n.pt' (the 'n' stands for nano) because it is ultra-fast for real-time video
print("Loading YOLOv8 AI Model... This might take a second...")
model = YOLO('yolov8n.pt')
print("AI Model loaded successfully!")

# 3. Create a quick test doorway
@vision_bp.route('/test', methods=['GET'])
def test_vision():
    return jsonify({"message": "Vision AI is awake and ready to see!"}), 200

# 4. The Core Object Detection Endpoint
@vision_bp.route('/detect', methods=['POST'])
def detect_obstacles():
    try:
        # Step A: The Bouncer - Check if an image was actually sent
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
            
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({"error": "Empty image file"}), 400

        # Step B: Translate the binary file into an OpenCV image
        file_bytes = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        if img is None:
            return jsonify({"error": "Failed to decode the image file. Is it corrupted?"}), 400
            
        # We will feed 'img' to the YOLO AI in the next commit!
        return jsonify({"message": "Image received successfully! Ready for AI."}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    