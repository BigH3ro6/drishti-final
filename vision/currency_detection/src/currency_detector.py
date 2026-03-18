from ultralytics import YOLO
import cv2
from gtts import gTTS
import os
import time
import threading

# load trained model
model = YOLO("../models/best.pt")

cap = cv2.VideoCapture(0)

last_spoken = ""
last_time = 0


def speak(text):
    def run():
        filename = "output.mp3"
        tts = gTTS(text=text, lang='en')
        tts.save(filename)
        os.system(f"start {filename}")
    threading.Thread(target=run, daemon=True).start()


while True:

    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame)

    best_label = None
    best_conf = 0

    for r in results:
        for box in r.boxes:

            cls = int(box.cls[0])
            conf = float(box.conf[0])

            if conf < 0.6:
                continue

            label = model.names[cls]

            # track best detection only
            if conf > best_conf:
                best_conf = conf
                best_label = label

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"{label} {conf:.2f}", (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    # speak only BEST detection
    if best_label:
        text = best_label.replace("_", " ")
        current_time = time.time()

        if text != last_spoken or current_time - last_time > 3:
            print(text)
            speak(text)

            last_spoken = text
            last_time = current_time

    cv2.imshow("Currency Detection - Test Mode", frame)

    key = cv2.waitKey(1) & 0xFF
    if key == 27 or key == ord('q'):
        break


cap.release()
cv2.destroyAllWindows()