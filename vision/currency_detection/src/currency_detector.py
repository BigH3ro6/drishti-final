from ultralytics import YOLO
import cv2
import pyttsx3
import time

# load trained model (will add later)
model = YOLO("../models/best.pt")

engine = pyttsx3.init()

last_spoken = ""
last_time = 0

cap = cv2.VideoCapture(0)

while True:

    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame)

    for r in results:
        boxes = r.boxes

        for box in boxes:

            cls = int(box.cls[0])
            label = model.names[cls]

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            cv2.rectangle(frame,(x1,y1),(x2,y2),(0,255,0),2)
            cv2.putText(frame,label,(x1,y1-10),
                        cv2.FONT_HERSHEY_SIMPLEX,0.8,(0,255,0),2)

            current_time = time.time()

            if label != last_spoken or current_time-last_time > 3:

                text = f"{label} detected"
                print(text)

                engine.say(text)
                engine.runAndWait()

                last_spoken = label
                last_time = current_time

    cv2.imshow("Currency Detection", frame)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()