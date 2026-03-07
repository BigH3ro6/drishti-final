from flask_socketio import SocketIO, emit
import base64
import numpy as np
import cv2

# This initializes the high-speed two-way connection hub
socketio = SocketIO(cors_allowed_origins="*")

@socketio.on('connect')
def handle_connect():
    print("🟢 Mobile device connected to stream!")
    emit('server_response', {'message': 'Connected to Drishti Stream Hub!'})

@socketio.on('disconnect')
def handle_disconnect():
    print("🔴 Mobile device disconnected.")

@socketio.on('video_frame')
def handle_video_frame(data):
    try:
        # 1. The phone sends the image as a Base64 string. We extract it.
        image_data = data.get('image')
        if not image_data:
            return

        # 2. Decode the Base64 string into raw binary bytes
        image_bytes = base64.b64decode(image_data)
        
        # 3. Convert those bytes into a NumPy array (math format)
        np_arr = np.frombuffer(image_bytes, np.uint8)
        
        # 4. Tell OpenCV to read that array and turn it into a real image matrix!
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        print(f"✅ Successfully decoded a frame! Size: {frame.shape}")

    except Exception as e:
        print(f"❌ Error decoding frame: {e}")