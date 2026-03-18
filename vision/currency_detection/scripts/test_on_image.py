from ultralytics import YOLO
import cv2

# load model
model = YOLO("../models/best.pt")

# load image
img = cv2.imread("test_images/sample28.jpeg")

results = model(img)

best_label = None
best_conf = 0

for r in results:
    for box in r.boxes:

        cls = int(box.cls[0])
        conf = float(box.conf[0])

        if conf < 0.6:
            continue

        label = model.names[cls]

        if conf > best_conf:
            best_conf = conf
            best_label = label

        x1, y1, x2, y2 = map(int, box.xyxy[0])

        cv2.rectangle(img, (x1,y1),(x2,y2),(0,255,0),2)
        cv2.putText(img, f"{label} {conf:.2f}", (x1,y1-10),
                    cv2.FONT_HERSHEY_SIMPLEX,0.7,(0,255,0),2)

print("Best Detection:", best_label, best_conf)

cv2.imshow("Result", img)
cv2.waitKey(0)
cv2.destroyAllWindows()
