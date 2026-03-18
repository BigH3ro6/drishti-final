import os
from ultralytics import YOLO

# Safe path to model
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
model_path = os.path.join(BASE_DIR, "models", "best.pt")

# Load model once
model = YOLO(model_path)

# Class names
CLASS_NAMES = {
    0: "20 rupees",
    1: "50 rupees",
    2: "100 rupees",
    3: "500 rupees",
    4: "1000 rupees",
    5: "5000 rupees"
}


def detect_currency(image):
    """
    Takes an OpenCV image (numpy array).
    Returns the best detected currency note as a string.
    Returns None if nothing detected with sufficient confidence.
    """

    results = model(image)

    best_label = None
    best_conf = 0

    for r in results:
        for box in r.boxes:

            cls = int(box.cls[0])
            conf = float(box.conf[0])

            if conf < 0.5:
                continue

            label = CLASS_NAMES.get(cls, model.names[cls])

            if conf > best_conf:
                best_conf = conf
                best_label = label

    if best_label is None:
        return None

    return {
        "currency": best_label,
        "confidence": round(best_conf, 2)
    }