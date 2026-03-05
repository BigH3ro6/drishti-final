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
