# Drishti System Architecture

## 1. System Actors & Roles
* **Primary User (Blind):** Uses the system for navigation, safety, and daily tasks.
    * *Input:* Voice commands, Hardware Buttons (SOS), Camera feed.
    * *Output:* Audio feedback (Bone conduction/Speaker).
* **Secondary User (Caregiver):** Monitors safety and assists remotely.
    * *Input:* Text/Voice replies, Location map queries.
    * *Output:* Push Notifications (SOS), Live Location Map.

## 2. Core Modules & Data Flow

### A. The "Vision" Pipeline (Two Modes)
The system operates in two distinct modes to manage bandwidth and battery.

1.  **Continuous Mode (Obstacle Detection & Navigation):**
    * **Source:** Camera (Glasses/Phone) streams video frames (approx 5fps).
    * **Protocol:** WebSocket or MJPEG Stream over HTTP.
    * **Processing:** Backend runs `YOLOv8` (or similar) on every Nth frame.
    * **Response:** JSON stream of objects (`{ "obstacle": "stairs", "distance": "1.5m" }`) -> Converted to Audio cues.

2.  **On-Demand Mode (Currency & Weather):**
    * **Source:** User triggers "Read Currency" command.
    * **Protocol:** Single HTTP POST request (High-Res Image).
    * **Processing:** Backend runs `Currency Classifier` model.
    * **Response:** Single Text result ("500 Rupees") -> TTS (Text-to-Speech).

### B. The "Safety" Pipeline (Real-Time)
This relies on **Firebase Firestore** for instant syncing between Blind User and Caregiver.

* **SOS Trigger:**
    1.  Blind User presses button (Physical or App).
    2.  App writes `{ status: "EMERGENCY", location: [lat, lng] }` to Firestore.
    3.  Cloud Functions trigger **FCM (Firebase Cloud Messaging)**.
    4.  Caregiver phone rings (Critical Alert).

* **Live Tracking:**
    1.  Blind User app pushes GPS coords to Firestore every 30s.
    2.  Caregiver app listens to document changes and updates Map markers in real-time.

### C. Communication Loop
* **Voice Messages:**
    * Audio recorded -> Uploaded to Firebase Storage.
    * Download URL stored in Firestore Chat Collection.
    * Recipient plays audio from URL.

## 3. Technology Stack

* **Hardware (Edge):** ESP32-CAM (Primary) OR Mobile Phone Camera (Fallback).
* **Mobile App:** Flutter (Android/iOS) - Handles Logic, TTS, Location, Bluetooth.
* **Backend:** Python Flask (Hosted on Cloud Run/AWS EC2).
* **Database:** Firebase Firestore (NoSQL) & Realtime Database.
* **AI Models:**
    * *Obstacles:* YOLO / SSD MobileNet (Object Detection).
    * *Currency:* Custom CNN (Image Classification).
    * *Weather:* OpenWeatherMap API.

## 4. Fallback Strategy (Risk Management)
If IoT Hardware (Glasses) is not ready by the deadline:
* The **Mobile App** will take over the Camera and Audio roles.
* **No backend changes required** (API remains standard: receives Image, returns JSON).