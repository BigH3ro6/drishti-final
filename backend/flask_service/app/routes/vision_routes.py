import os
import base64
import numpy as np
import cv2
import pytesseract
from flask import Blueprint, request, jsonify

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

vision_bp = Blueprint('vision', __name__)

@vision_bp.route('/read-text', methods=['POST'])
def read_text():
    data = request.get_json()
    if not data or 'image' not in data:
        return jsonify({"error": "No image provided"}), 400
    
    try:
        image_data = base64.b64decode(data['image'])
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        text = pytesseract.image_to_string(image)
        
        return jsonify({
            "status": "success",
            "text": text.strip()
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
