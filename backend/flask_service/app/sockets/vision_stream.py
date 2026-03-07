from flask_socketio import SocketIO, emit
import base64
import numpy as np
import cv2
import time

socketio = SocketIO(cors_allowed_origins="*")

# NEW Frame Dropper Settings 
# Process max 5 frames per second (1 frame every 0.2 seconds) to save AI brain power
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
    
    # NEW: Frame Dropper Logic
    current_time = time.time()
    if (current_time - last_frame_time) < PROCESS_INTERVAL:
        # It hasn't been 0.2 seconds yet. Throw this frame in the trash.
        return
        
    # Update the clock for the next frame
    last_frame_time = current_time

    try:
        # 1. Extract Base64
        image_data = data.get('image')
        if not image_data:
            return

        # 2. Decode to Bytes
        image_bytes = base64.b64decode(image_data)
        
        # 3. Convert to Math Array
        np_arr = np.frombuffer(image_bytes, np.uint8)
        
        # 4. Turn into OpenCV Image Matrix
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        print(f"✅ Processed a frame! Size: {frame.shape}")

    except Exception as e:
        print(f"❌ Error decoding frame: {e}")