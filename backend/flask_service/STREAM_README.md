# 📷 Drishti Vision Stream (WebSocket API)

This document explains how the Flutter frontend should connect to the Python backend to stream video frames and receive real-time AI obstacle detection.

## 🔌 1. Connection Details
- Protocol: WebSockets (Socket.IO)
- URL: `http://<SERVER_IP>:5000`
- Authentication: You MUST pass a `user_id` parameter when connecting.
  - Example: `http://192.168.1.5:5000?user_id=blind_user_01`

## 📤 2. Sending Video to the Server
- Event Name: `video_frame`
- Data Format (JSON):
  {
    "image": "base64_encoded_string_here..."
  }

## 📥 3. Listening for AI Responses
- Event Name: `ai_response`
- Data Format (JSON):
  {
    "obstacle": "Chair",
    "distance": "1.5m",
    "direction": "Slightly Right",
    "timestamp": 1709485203.12
  }