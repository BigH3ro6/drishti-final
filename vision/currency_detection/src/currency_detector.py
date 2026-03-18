from ultralytics import YOLO
import cv2
from gtts import gTTS
import os
import time

# load trained model
model = YOLO("../models/best.pt")

# webcam
cap = cv2.VideoCapture(0)

last_spoken = ""
last_time = 0


def speak(text):
    filename = "output.mp3"
    
    tts = gTTS(text=text, lang='en')
    tts.save(filename)

    # play audio (Windows)
    os.system(f"start {filename}")

    # small delay to avoid file lock issues
    time.sleep(1)

    # delete file
    if os.path.exists(filename):
        os.remove(filename)


while True:

    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame)

    for r in results:
        for box in r.boxes:

            cls = int(box.cls[0])
            conf = float(box.conf[0])

            # filter weak detections
            if conf < 0.6:
                continue

            label = model.names[cls]
            text = label.replace("_", " ")

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            # draw bounding box
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            # show label + confidence
            display_text = f"{text} {conf:.2f}"
            cv2.putText(frame, display_text, (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

            current_time = time.time()

            # avoid repeating same speech too often
            if text != last_spoken or current_time - last_time > 3:
                print(text)
                speak(text)

                last_spoken = text
                last_time = current_time

    cv2.imshow("Currency Detection - Test Mode", frame)

    # press ESC or Q to exit
    key = cv2.waitKey(1) & 0xFF
    if key == 27 or key == ord('q'):
        break


cap.release()
cv2.destroyAllWindows()