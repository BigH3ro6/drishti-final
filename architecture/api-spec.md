```markdown
# Drishti API Specification v1.0

## Base URL
* **Development:** `http://localhost:5000/api/v1`
* **Production:** `https://drishti-backend-xyz.run.app/api/v1`

---

## 1. Vision & Intelligence Endpoints

### A. Obstacle Detection (Stream)
* **Endpoint:** `WS /ws/obstacle-stream` (WebSocket)
* **Description:** Continuous stream of low-res frames for real-time navigation.
* **Client Sends (Binary):** raw bytes of JPEG image (approx 15fps).
* **Server Returns (JSON):**
  ```json
  {
    "objects": [
      { "label": "stairs", "confidence": 0.95, "distance": "1.2m", "bbox": [10, 20, 100, 200] },
      { "label": "person", "confidence": 0.88, "distance": "2.0m", "bbox": [50, 60, 150, 300] }
    ],
    "alert_level": "CRITICAL" // CRITICAL | WARNING | SAFE
  }

```

### B. Currency Recognition (Snapshot)

* **Endpoint:** `POST /vision/currency`
* **Description:** High-res analysis of a single photo.
* **Request (Multipart/Form-Data):**
* `image`: (File) The captured photo.
* `user_id`: "user_123"


* **Response (200 OK):**
```json
{
  "currency": "LKR",
  "value": 500,
  "confidence": 0.98,
  "tts_string": "Five Hundred Rupees"
}

```



---

## 2. Utility Endpoints

### A. Weather Check

* **Endpoint:** `GET /utility/weather`
* **Query Params:** `lat`, `lng`
* **Response:**
```json
{
  "location": "Colombo",
  "temp_c": 30,
  "condition": "Rainy",
  "advisory": "Take an umbrella."
}

```



---

## 3. Real-Time Data (Firestore Schema)

For features like **Live Location** and **Chat**, we will NOT use the Python API to avoid latency. The App will write directly to Firebase Firestore, and the Caregiver App will listen to changes.

### Collection: `users/{userId}`

* `location`: `{ "lat": 6.927, "lng": 79.861, "timestamp": 1708324000 }` (Updated every 30s)
* `status`: `"SAFE" | "SOS" | "OFFLINE"`
* `caregiver_id`: "caregiver_456"

### Collection: `chats/{chatId}/messages`

* `sender_id`: "user_123"
* `type`: `"VOICE" | "TEXT"`
* `content_url`: "gs://voice-notes/audio_01.mp3" (For voice)
* `text_content`: "I am waiting at the bus stop." (For text replies)
* `timestamp`: 1708324050

---

## 4. Emergency Protocol (SOS)

### Trigger SOS

* **Method:** Firestore Update + Cloud Function (Backend Trigger)
* **Action:**
1. App updates `users/{uid}/status` to `"SOS"`.
2. Cloud Function detects change -> Sends FCM Notification to Caregiver.
3. Backend logs incident.



```