import os
import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from ultralytics import YOLO

app = FastAPI(
    title="Drishti Currency Detection API",
    description="Sri Lankan currency note detection API for the Drishti assistive app for visually impaired users",
    version="1.0.0"
)

# Load model
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
model_path = os.path.join(BASE_DIR, "models", "best.pt")
model = YOLO(model_path)


def detect_currency(image):
    results = model(image, verbose=False)

    best_label = None
    best_conf = 0

    for r in results:
        for box in r.boxes:
            cls = int(box.cls[0])
            conf = float(box.conf[0])

            if conf < 0.6:
                continue

            label = model.names[cls].replace("_", " ")

            if conf > best_conf:
                best_conf = conf
                best_label = label

    if best_label is None:
        return None

    return {
        "currency": best_label,
        "confidence": round(best_conf, 2)
    }


@app.get("/")
def read_root():
    return {"message": "Drishti Currency Detection API is running"}


@app.get("/health")
def health():
    return {
        "status": "running",
        "model": "YOLOv8 Sri Lankan Currency Detector"
    }


@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    """
    Detect Sri Lankan currency note from an uploaded image.

    - **image**: Image file (JPEG/PNG)

    Returns detected currency note as text.
    """

    if not image.filename:
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "No image provided"}
        )

    img_bytes = await image.read()
    img_array = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    if img is None:
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": "Invalid image format"}
        )

    result = detect_currency(img)

    if result is None:
        return JSONResponse(
            status_code=200,
            content={
                "success": False,
                "currency": None,
                "message": "No currency note detected. Please take a clearer photo."
            }
        )

    return JSONResponse(
        status_code=200,
        content={
            "success": True,
            "currency": f"This is a {result['currency']} note",
            "confidence": result["confidence"]
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
    