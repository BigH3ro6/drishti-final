from flask_socketio import SocketIO, emit
import base64
import numpy as np
import cv2
import time

socketio = SocketIO(cors_allowed_origins="*")

PROCESS_INTERVAL = 0.2  
last_frame_time = 0

@socketio.on('connect')
def handle_connect():
    print("🟢 Mobile device connected to stream!")
    emit('server_response', {'message': 'Connected to Drishti Stream Hub!'})

@socketio.on('disconnect')
def handle_disconnect():
    print("🔴 Mobile device disconnected.")

@socketio.on('video_frame')
def handle_video_frame(data):
    global last_frame_time
    
    current_time = time.time()
    if (current_time - last_frame_time) < PROCESS_INTERVAL:
        return
        
    last_frame_time = current_time

    try:
        image_data = data.get('image')
        if not image_data:
            print("⚠️ Warning: Received empty image data.")
            return

        # --- NEW: Robust Error Handling ---
        # 1. Catch broken Base64 strings (like dropped Wi-Fi packets)
        try:
            image_bytes = base64.b64decode(image_data)
        except Exception as b64_err:
            print(f"⚠️ Base64 Decoding Error (dropped frame): {b64_err}")
            return
        
        np_arr = np.frombuffer(image_bytes, np.uint8)
        
        # 2. Catch OpenCV failing to read the array
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        
        if frame is None:
            print("⚠️ OpenCV Error: Frame is corrupted or unreadable (dropped frame).")
            return

        print(f"✅ Processed a healthy frame! Size: {frame.shape}")

    except Exception as e:
        # 3. Catch any other unexpected server crashes to keep the stream alive
        print(f"❌ Unexpected Stream Error: {e}")