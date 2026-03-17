import socketio
import time

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
    # This is a real Base64 string of a tiny 1x1 pixel black image
    # We use this so we don't need a real camera to test the pipes!
    tiny_image_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
    
    print("\n🚀 Fake Phone: Starting to send video frames...")
    
    # Send 10 frames to the server
    for i in range(10): 
        sio.emit('video_frame', {'image': tiny_image_b64})
        print(f"📤 Sent frame {i+1}/10")
        time.sleep(0.3) # Wait 0.3 seconds between frames so the Frame Dropper doesn't trash them

if __name__ == '__main__':
    print("🔄 Fake Phone: Attempting to connect to local server...")
    try:
        # We connect and pass our fake ID badge (user_id=test_user_99) to get past the bouncer!
        sio.connect('http://localhost:5000?user_id=test_user_99')
        
        # Start sending the fake video
        simulate_streaming()
        
        # Hang up the phone
        time.sleep(1)
        sio.disconnect()
        print("👋 Fake Phone: Disconnected. Test complete!")
        
    except Exception as e:
        print(f"⚠️ Test stopped. (Note: This is normal if you haven't turned the Flask server on yet! Error: {e})")