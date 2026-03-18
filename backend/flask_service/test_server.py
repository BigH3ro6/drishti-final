import os
import sys
from flask import Flask

# This finds the 'backend' folder automatically
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if base_dir not in sys.path:
    sys.path.append(base_dir)

from app.sockets.vision_stream import socketio 

test_app = Flask(__name__)
socketio.init_app(test_app)

if __name__ == '__main__':
    print("🚀 Server: Starting on Port 5000...")
    socketio.run(test_app, host='0.0.0.0', port=5000, allow_unsafe_werkzeug=True)