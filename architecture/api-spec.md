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