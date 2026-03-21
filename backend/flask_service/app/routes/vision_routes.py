import os
import base64
import numpy as np
import cv2
import pytesseract
import requests
from flask import Blueprint, request, jsonify

# Tesseract Configuration
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Initialize Blueprint
vision_bp = Blueprint('vision', __name__)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# -------------------------------------------------------------------
# 1. TEXT READING ROUTE
# -------------------------------------------------------------------
@vision_bp.route('/read-text', methods=['POST'])
def read_text():
    data = request.get_json()
    if not data or 'image' not in data:
        return jsonify({"error": "No image provided"}), 400
    
    try:
        image_data = base64.b64decode(data['image'])
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            return jsonify({"error": "Failed to decode image"}), 400
        
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        text1 = pytesseract.image_to_string(gray)
        
        thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
        text2 = pytesseract.image_to_string(thresh)
        
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        text3 = pytesseract.image_to_string(blur)
        
        texts = [text1, text2, text3]
        best_text = max(texts, key=lambda x: len(x.strip()))
        
        return jsonify({
            "status": "success",
            "text": best_text.strip() if best_text.strip() else "No text detected"
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------------------------------------------
# 2. CURRENCY DETECTION ROUTES
# -------------------------------------------------------------------
@vision_bp.route('/detect-currency', methods=['POST'])
def detect_currency():
    if 'image' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    file = request.files['image']
    
    if file.filename == '':
        return jsonify({"error": "No file selected"}), 400
    
    if not allowed_file(file.filename):
        return jsonify({"error": "Only JPG, JPEG, PNG files are allowed"}), 400
    
    try:
        # 1. Pull the URL securely from the .env file
        currency_endpoint = os.getenv("CURRENCY_API_URL")
        
        # 2. Add a failsafe just in case the .env variable is missing
        if not currency_endpoint:
             return jsonify({"error": "Server misconfiguration: Missing CURRENCY_API_URL"}), 500

        files = {'image': (file.filename, file.read(), file.content_type)}
        response = requests.post(
            f"{currency_endpoint}/predict", 
            files=files,
            timeout=30
        )
        
        if response.status_code == 200:
            return jsonify(response.json()), 200
        else:
            return jsonify({
                "error": "Currency detection service failed",
                "details": response.text
            }), 503
            
    except requests.exceptions.Timeout:
        return jsonify({"error": "Currency detection service timed out"}), 503
    except requests.exceptions.ConnectionError:
        return jsonify({"error": "Currency detection service unavailable"}), 503
    except Exception as e:
        return jsonify({"error": f"Failed to process request: {str(e)}"}), 500


@vision_bp.route('/currency/health', methods=['GET'])
def currency_health():
    return jsonify({
        "success": True,
        "message": "Currency detection backend is running"
    }), 200

# -------------------------------------------------------------------
# 3. OBSTACLE DETECTION ROUTES 
# -------------------------------------------------------------------
@vision_bp.route('/test', methods=['GET'])
def test_vision():
    return jsonify({"message": "Vision Gateway is awake and ready to forward!"}), 200


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
        YOLO_ENDPOINT = os.getenv("OBSTACLE_PREDICT_IMAGE_URL")
        
        if not YOLO_ENDPOINT:
            return jsonify({"error": "Server misconfiguration: Missing OBSTACLE_PREDICT_IMAGE_URL"}), 500
        
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