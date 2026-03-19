from flask import Blueprint, request, jsonify
import os
from werkzeug.utils import secure_filename

obstacle_bp = Blueprint('obstacle_bp', __name__)

# Ensure an upload folder exists
UPLOAD_FOLDER = 'uploads/obstacles'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ---------------------------------------------------------
# METHOD 1: IMAGE UPLOAD (Fast, lower bandwidth)
# ---------------------------------------------------------
@obstacle_bp.route('/detect-obstacle-image', methods=['POST'])
def detect_obstacle_image():
    if 'file' not in request.files:
        return jsonify({"error": "No image file provided"}), 400
    
    file = request.files['file']
    filename = secure_filename(file.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)

    # TODO: Pass 'filepath' to your Machine Learning Model here!
    # result = my_ml_model.predict_image(filepath)
    
    # Mock Response for now
    mock_result = "I see a chair 2 meters ahead."

    # Clean up the file after processing to save space
    os.remove(filepath)

    return jsonify({"message": mock_result}), 200

# ---------------------------------------------------------
# METHOD 2: VIDEO UPLOAD (5-10 seconds, better context)
# ---------------------------------------------------------
@obstacle_bp.route('/detect-obstacle-video', methods=['POST'])
def detect_obstacle_video():
    if 'file' not in request.files:
        return jsonify({"error": "No video file provided"}), 400
    
    file = request.files['file']
    filename = secure_filename(file.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)

    # TODO: Pass 'filepath' to your Machine Learning Model here!
    # result = my_ml_model.process_video(filepath)
    
    # Mock Response for now
    mock_result = "Stairs detected moving downwards."

    # Clean up the file after processing
    os.remove(filepath)

    return jsonify({"message": mock_result}), 200