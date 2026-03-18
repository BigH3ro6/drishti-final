import os
from ultralytics import YOLO

# Safe path to model
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
model_path = os.path.join(BASE_DIR, "models", "best.pt")

# Load model once
model = YOLO(model_path)


def detect_currency(image):
    """
    Takes an OpenCV image (numpy array).
    Returns the best detected currency note as a string.
    Returns None if nothing detected with sufficient confidence.
    """

    results = model(image, verbose=False)

    best_label = None
    best_conf = 0

    for r in results:
        boxes = r.boxes

        for box in boxes:

            cls = int(box.cls)
            conf = float(box.conf)

            if conf < 0.6:
                continue

            label = model.names[cls]

            if conf > best_conf:
                best_conf = conf
                best_label = label

    if best_label is None:
        return None

    return {
        "currency": best_label.replace("_", " "),
        "confidence": round(best_conf, 2)
    }
