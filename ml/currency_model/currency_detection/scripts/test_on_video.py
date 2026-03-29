import sys
import os
import cv2

# Safe path setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

from src.currency_detector import detect_currency

# ===== VIDEO PATH =====
# Place your video file inside test_images/ folder
VIDEO_PATH = os.path.join(BASE_DIR, "test_images", "sample_video.mp4")

cap = cv2.VideoCapture(VIDEO_PATH)

if not cap.isOpened():
    print("❌ Video not found. Check path:", VIDEO_PATH)
    exit()

print("Playing video... Press ESC or Q to quit.")

while True:

    ret, frame = cap.read()

    # Restart video when it ends
    if not ret:
        cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
        continue

    result = detect_currency(frame)

    if result:
        label = result["currency"]
        conf = result["confidence"]

        # Draw detection on frame
        cv2.putText(frame, f"{label} ({conf})",
                    (20, 50), cv2.FONT_HERSHEY_SIMPLEX,
                    1, (0, 255, 0), 2)

        print(f"Detected: {label} ({conf})")

    cv2.imshow("Video Test - Currency Detection", frame)

    key = cv2.waitKey(30) & 0xFF
    if key == 27 or key == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()