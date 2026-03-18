from ultralytics import YOLO
import cv2

# load trained model
model = YOLO("vision/currency_detection/models/best.pt")

cap = cv2.VideoCapture(0)

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

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            # draw box
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            # show label + confidence
            text = f"{label} {conf:.2f}"
            cv2.putText(frame, text, (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    cv2.imshow("Currency Detection - Test Mode", frame)

    # press q to exit
    key = cv2.waitKey(1) & 0xFF

    if key == 27 or key == ord('q'):
       break

cap.release()
cv2.destroyAllWindows()