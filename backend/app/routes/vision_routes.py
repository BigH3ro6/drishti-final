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