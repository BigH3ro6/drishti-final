from ultralytics import YOLO
import cv2
import os

# ===== SAFE PATH SETUP =====
BASE_DIR = os.path.dirname(os.path.dirname(__file__))

model_path = os.path.join(BASE_DIR, "models", "best.pt")
image_path = os.path.join(BASE_DIR, "test_images", "sample18.jpeg")

# ===== LOAD MODEL =====
model = YOLO(model_path)

# ===== LOAD IMAGE =====
img = cv2.imread(image_path)

if img is None:
    print("❌ Image not found. Check path:", image_path)
    exit()

# ===== RUN MODEL =====
results = model(img)

best_label = None
best_conf = 0

# ===== PROCESS RESULTS =====
for r in results:
    for box in r.boxes:

        cls = int(box.cls[0])
        conf = float(box.conf[0])
        label = model.names[cls]

        # DEBUG print
        print(f"Detected: {label} ({conf:.2f})")

        x1, y1, x2, y2 = map(int, box.xyxy[0])

        # ALWAYS draw bounding box
        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(img, f"{label} {conf:.2f}", (x1, y1 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        # FILTER for best detection only
        if conf < 0.6:
            continue

        if conf > best_conf:
            best_conf = conf
            best_label = label

# ===== OUTPUT =====
print("\n✅ Best Detection:", best_label, best_conf)

# ===== SHOW IMAGE =====
cv2.imshow("Detection Result", img)
cv2.waitKey(0)
cv2.destroyAllWindows()