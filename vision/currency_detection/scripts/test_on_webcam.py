import sys
import os
import cv2
import time
import threading
from gtts import gTTS

# Safe path setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

from src.currency_detector import detect_currency

# ===== GOOGLE TTS (TEST ONLY) =====
last_spoken = ""
last_time = 0


def speak(text):
    def run():
        filename = os.path.join(BASE_DIR, "output.mp3")
        tts = gTTS(text=text, lang='en')
        tts.save(filename)
        os.system(f"start {filename}")
    threading.Thread(target=run, daemon=True).start()


# ===== WEBCAM =====
cap = cv2.VideoCapture(0)

print("Starting webcam... Press ESC or Q to quit.")

while True:

    ret, frame = cap.read()
    if not ret:
        break

    result = detect_currency(frame)

    if result:
        label = result["currency"]
        conf = result["confidence"]

        current_time = time.time()

        # Draw label on frame
        cv2.putText(frame, f"{label} ({conf})",
                    (20, 50), cv2.FONT_HERSHEY_SIMPLEX,
                    1, (0, 255, 0), 2)

        # Speak only when new or after 3 seconds
        if label != last_spoken or current_time - last_time > 3:
            print(f"Detected: {label} ({conf})")
            speak(label)
            last_spoken = label
            last_time = current_time

    cv2.imshow("Webcam Test - Currency Detection", frame)

    key = cv2.waitKey(1) & 0xFF
    if key == 27 or key == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()