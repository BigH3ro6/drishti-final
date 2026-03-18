import os
import cv2
from ultralytics import YOLO

# Safe path setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
model_path = os.path.join(BASE_DIR, "models", "best.pt")

model = YOLO(model_path)

cap = cv2.VideoCapture(0)
print("Starting webcam... Press ESC or Q to quit.")

while True:

    ret, frame = cap.read()
    if not ret:
        break

    results = model(frame, verbose=False)

    for r in results:
        boxes = r.boxes

        for box in boxes:

            cls = int(box.cls)
            conf = float(box.conf)
            label = model.names[cls]

            if conf < 0.6:
                continue

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            # Draw bounding box
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

            # Draw label background
            label_text = f"{label.replace('_', ' ')} {conf:.2f}"
            (w, h), _ = cv2.getTextSize(label_text,
                                         cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
            cv2.rectangle(frame, (x1, y1 - 25),
                          (x1 + w, y1), (0, 255, 0), -1)

            # Draw label text
            cv2.putText(frame, label_text, (x1, y1 - 5),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)

            print(f"Detected: {label} ({conf:.2f})")

    cv2.imshow("Currency Detection", frame)

    key = cv2.waitKey(1) & 0xFF
    if key == 27 or key == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
