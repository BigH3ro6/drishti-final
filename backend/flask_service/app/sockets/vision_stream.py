from flask_socketio import SocketIO, emit
from flask import request
import base64
import numpy as np
import cv2
import time
import random

# This initializes the high-speed two-way connection hub
socketio = SocketIO(cors_allowed_origins="*")

# Frame Dropper Settings
# Process max 5 frames per second (1 frame every 0.2 seconds) to save AI brain power
PROCESS_INTERVAL = 0.2  
last_frame_time = 0

# FPS Tracker Settings
fps_start_time = time.time()
processed_frame_count = 0

# Memory Cleanup Tracker
# We will track who is actively streaming so we can delete their data when they leave
active_streams = {}

@socketio.on('connect')
def handle_connect():
    # NEW: WebSocket Security
    # The frontend MUST send a user_id to connect. If they don't, reject them!
    user_id = request.args.get('user_id')
    if not user_id:
        print("⛔ Security Alert: Connection rejected! Missing user_id.")
        return False # This instantly blocks the connection

    # Add the authenticated user to our tracker
    client_id = request.sid
    # We now store their specific user_id so we know exactly who is streaming
    active_streams[client_id] = user_id 
    
    print(f"🟢 User [{user_id}] connected securely! (Session: {client_id})")
    emit('server_response', {'message': 'Securely connected to Drishti Stream Hub!'})

@socketio.on('disconnect')
def handle_disconnect():
    # Clean Disconnect Memory Cleanup
    client_id = request.sid
    if client_id in active_streams:
        user_id = active_streams[client_id]
        del active_streams[client_id]
        print(f"🔴 User [{user_id}] disconnected. 🧹 Memory wiped clean!")
    else:
        print(f"🔴 Unknown device ({client_id}) disconnected.")

@socketio.on('video_frame')
def handle_video_frame(data):
    # Ghost Frame Blocker
    if request.sid not in active_streams:
        return
        
    global last_frame_time, fps_start_time, processed_frame_count
    
    # Frame Dropper Logic
    current_time = time.time()
    if (current_time - last_frame_time) < PROCESS_INTERVAL:
        return
        
    last_frame_time = current_time

    try:
        # 1. The phone sends the image as a Base64 string. We extract it.
        image_data = data.get('image')
        if not image_data:
            print("⚠️ Warning: Received empty image data.")
            return

        # Robust Error Handling
        try:
            # 2. Decode the Base64 string into raw binary bytes
            image_bytes = base64.b64decode(image_data)
        except Exception as b64_err:
            print(f"⚠️ Base64 Decoding Error: {b64_err}")
            return
        
        # 3. Convert those bytes into a NumPy array (math format)
        np_arr = np.frombuffer(image_bytes, np.uint8)
        
        # 4. Tell OpenCV to read that array and turn it into a real image matrix!
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        
        if frame is None:
            print("⚠️ OpenCV Error: Frame is corrupted or unreadable.")
            return

        # FPS Tracker Logic
        processed_frame_count += 1
        elapsed_time = current_time - fps_start_time
        
        if elapsed_time >= 1.0:
            current_fps = processed_frame_count / elapsed_time
            print(f"📊 STREAM HEALTH: {current_fps:.1f} FPS | Resolution: {frame.shape}")
            fps_start_time = current_time
            processed_frame_count = 0

        # Dummy AI Placeholder
        # TODO: PHASE 3 - DELETE THIS MOCK DATA AND PLUG IN REAL YOLO MODEL HERE
        mock_obstacles = ["Chair", "Table", "Person", "Wall", "Door", "Stairs"]
        mock_directions = ["Slightly Left", "Straight Ahead", "Slightly Right"]
        
        ai_result = {
            "obstacle": random.choice(mock_obstacles),
            "distance": f"{random.uniform(0.5, 3.0):.1f}m",
            "direction": random.choice(mock_directions),
            "timestamp": current_time
        }
        
        # FIRE THE RESPONSE BACK TO THE PHONE!
        emit('ai_response', ai_result)

    except Exception as e:
        print(f"❌ Unexpected Stream Error: {e}")