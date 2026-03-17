import socketio
import time
import base64
import os

# 1. Create a fake mobile app client
sio = socketio.Client()

# 2. Listen for the connection success
@sio.event
def connect():
    print("✅ Fake Phone: Successfully connected to Drishti Hub!")

# 3. Listen for the Welcome Message
@sio.on('server_response')
def on_server_response(data):
    print(f"📩 Server Welcome: {data}")

# 4. Listen for our Dummy AI from Commit 6!
@sio.on('ai_response')
def on_ai_response(data):
    print(f"🤖 AI Prediction Received: {data['obstacle']} detected {data['distance']} away, {data['direction']}.")

def simulate_streaming():
    # NEW: Read the real image from your folder
    image_path = "test_image.jpg" # Change to .png if your file is a PNG!
    
    if not os.path.exists(image_path):
        print(f"❌ Error: Could not find '{image_path}'. Did you drag a picture into the folder?")
        return

    # Convert the real picture into a massive Base64 text string
    with open(image_path, "rb") as image_file:
        real_image_b64 = base64.b64encode(image_file.read()).decode('utf-8')
    
    print(f"\n🚀 Fake Phone: Starting to send REAL video frames from '{image_path}'...")
    
    # Send 10 real frames to the server
    for i in range(10): 
        sio.emit('video_frame', {'image': real_image_b64})
        print(f"📤 Sent real frame {i+1}/10")
        time.sleep(0.3)

if __name__ == '__main__':
    print("🔄 Fake Phone: Attempting to connect to local server...")
    try:
        sio.connect('http://localhost:5000?user_id=test_user_99')
        
        simulate_streaming()
        
        time.sleep(1)
        sio.disconnect()
        print("👋 Fake Phone: Disconnected. Test complete!")
        
    except Exception as e:
        print(f"⚠️ Test stopped. (Note: This is normal if you haven't turned the Flask server on yet! Error: {e})")