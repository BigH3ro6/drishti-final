import os
import sys
import cv2
import numpy as np
from flask import Flask, request, jsonify

# Safe path setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

from src.currency_detector import detect_currency

app = Flask(__name__)


@app.route("/predict", methods=["POST"])
def predict():
    """
    Accepts a POST request with an image file.
    Returns detected currency note as JSON.

    Example response:
    {
        "success": true,
        "currency": "This is a 500 rupees note",
        "confidence": 0.98
    }
    """

    # Check if image was sent
    if "image" not in request.files:
        return jsonify({
            "success": False,
            "error": "No image provided. Send image as form-data with key 'image'"
        }), 400

    file = request.files["image"]

    # Check if file is empty
    if file.filename == "":
        return jsonify({
            "success": False,
            "error": "Empty file received"
        }), 400

    # Convert image to OpenCV format
    img_bytes = file.read()
    img_array = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    if img is None:
        return jsonify({
            "success": False,
            "error": "Invalid image format"
        }), 400

    # Run detection
    result = detect_currency(img)

    if result is None:
        return jsonify({
            "success": False,
            "currency": None,
            "message": "No currency note detected. Please take a clearer photo."
        }), 200

    # Format output message for backend developer
    currency_name = result["currency"]
    confidence = result["confidence"]

    return jsonify({
        "success": True,
        "currency": f"This is a {currency_name} note",
        "confidence": confidence
    }), 200


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "running",
        "model": "YOLOv8 Sri Lankan Currency Detector"
    }), 200


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)