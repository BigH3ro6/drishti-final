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
        
        # Step C: Feed the picture to the YOLOv8 Brain
        #  The AI looks at the photo!
        results = model(img)
        
        # Step D: Extract the detected obstacles
        detected_objects = []
        
        # The AI might find multiple things, so we loop through them
        for r in results:
            for box in r.boxes:
                class_id = int(box.cls[0])
                confidence = float(box.conf[0])
                
                # Only keep obstacles the AI is more than 50% sure about
                if confidence > 0.5:
                    # Step E: Distance Math
                    # Extract the box coordinates: x1 (left), y1 (top), x2 (right), y2 (bottom)
                    x1, y1, x2, y2 = box.xyxy[0].tolist()
                    
                    # Calculate how tall the object is in pixels
                    pixel_height = y2 - y1
                    
                    #  Distance = (Real Height * Focal Length) / Pixel Height
                    #  constant '1000' as a baseline multiplier for the camera lens
                    distance_meters = round(1000 / (pixel_height + 0.0001), 2)
                    
                    # Step F: Left / Center / Right positioning
                    image_width = img.shape[1]
                    box_center_x = (x1 + x2) / 2
                    
                    if box_center_x < (image_width / 3):
                        position = "Left"
                    elif box_center_x > (2 * image_width / 3):
                        position = "Right"
                    else:
                        position = "Center"
                    
                    # Step G: Translate the Class ID to a real English word
                    object_name = model.names[class_id]
                    
                    detected_objects.append({
                        "object_name": object_name,
                        "class_id": class_id,
                        "confidence": round(confidence, 2),
                        "distance_meters": distance_meters,
                        "position": position,
                        "box_coordinates": [round(x1), round(y1), round(x2), round(y2)]
                    })
                    
        # Step H: Final Polish - Sort obstacles so the closest ones are first!
        detected_objects.sort(key=lambda x: x['distance_meters'])
                    
        return jsonify({
            "status": "success",
            "message": "Vision AI fully operational!",
            "total_obstacles": len(detected_objects), 
            "data": detected_objects
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    