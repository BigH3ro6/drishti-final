from flask_socketio import SocketIO, emit
import base64
import numpy as np
import cv2
import time
import random # NEW: Imported for our fake AI

# This initializes the high-speed two-way connection hub
socketio = SocketIO(cors_allowed_origins="*")

# Frame Dropper Settings
# Process max 5 frames per second (1 frame every 0.2 seconds) to save AI brain power
PROCESS_INTERVAL = 0.2  
last_frame_time = 0

#FPS Tracker Settings
fps_start_time = time.time()
processed_frame_count = 0

@socketio.on('connect')
def handle_connect():
    print("🟢 Mobile device connected to stream!")
    emit('server_response', {'message': 'Connected to Drishti Stream Hub!'})

@socketio.on('disconnect')
def handle_disconnect():
    print("🔴 Mobile device disconnected.")

@socketio.on('video_frame')
def handle_video_frame(data):
    # Bring in our global variables so we can update them
    global last_frame_time, fps_start_time, processed_frame_count
    
    # Frame Dropper Logic
    current_time = time.time()
    if (current_time - last_frame_time) < PROCESS_INTERVAL:
        # It hasn't been 0.2 seconds yet. Throw this frame in the trash!
        return
        
    # Update the clock for the next frame
    last_frame_time = current_time

    try:
        # 1. The phone sends the image as a Base64 string. We extract it.
        image_data = data.get('image')
        if not image_data:
            print("⚠️ Warning: Received empty image data.")
            return

        # Robust Error Handling
        # Catch broken Base64 strings (like dropped Wi-Fi packets)
        try:
            # 2. Decode the Base64 string into raw binary bytes
            image_bytes = base64.b64decode(image_data)
        except Exception as b64_err:
            print(f"⚠️ Base64 Decoding Error (dropped frame): {b64_err}")
            return
        
        # 3. Convert those bytes into a NumPy array (math format)
        np_arr = np.frombuffer(image_bytes, np.uint8)
        
        # 4. Tell OpenCV to read that array and turn it into a real image matrix!
        # Catch OpenCV failing to read the array if it's corrupted
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        
        if frame is None:
            print("⚠️ OpenCV Error: Frame is corrupted or unreadable (dropped frame).")
            return

        # FPS Tracker Logic
        # Add 1 to our count because we successfully processed a frame
        processed_frame_count += 1
        elapsed_time = current_time - fps_start_time
        
        # Every 1 second, calculate and print the FPS to the terminal
        if elapsed_time >= 1.0:
            current_fps = processed_frame_count / elapsed_time
            print(f"📊 STREAM HEALTH: {current_fps:.1f} FPS | Resolution: {frame.shape}")
            
            # Reset the clock and the counter for the next second
            fps_start_time = current_time
            processed_frame_count = 0

        # NEW: Dummy AI Placeholder
        # We are pretending this is the YOLOv8 model doing heavy math.
        # It creates a fake JSON response so the Flutter app can practice talking to the user.
        mock_obstacles = ["Chair", "Table", "Person", "Wall", "Door", "Stairs"]
        mock_directions = ["Slightly Left", "Straight Ahead", "Slightly Right"]
        
        ai_result = {
            "obstacle": random.choice(mock_obstacles),
            "distance": f"{random.uniform(0.5, 3.0):.1f}m", # Random math between 0.5m and 3.0m
            "direction": random.choice(mock_directions),
            "timestamp": current_time
        }
        
        # FIRE THE RESPONSE BACK TO THE PHONE!
        emit('ai_response', ai_result)

    except Exception as e:
        # Catch any other unexpected server crashes to keep the stream alive
        print(f"❌ Unexpected Stream Error: {e}")