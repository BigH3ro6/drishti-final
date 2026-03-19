import cv2
import matplotlib.pyplot as plt
from ultralytics import YOLO
import time
import os

# 1. SETUP - Use Absolute Path for your model
# (Matches the path seen in your VS Code sidebar)
model_path = r'C:\Users\USER\Downloads\Obstacle_Detection_Project\drishti-final\ml_pipeline_Obstacle_det\runs\detect\Drishti_Final_Push\v11n_augmented_852\weights\best.pt'
model = YOLO(model_path)

# 2. CAMERA FINDER - Scans Index 1 (Iriun), then 2, then 0 (Internal Cam)
def get_camera():
    for index in [1, 2, 0]:
        cap = cv2.VideoCapture(index)
        if cap.isOpened():
            ret, frame = cap.read()
            if ret:
                print(f"Camera found at Index {index}")
                return cap
            cap.release()
    return None

cap = get_camera()

if cap is None:
    print("ERROR: No camera detected. Ensure Iriun is open on your iPhone and Laptop.")
    exit()

# 3. GUI SETUP - Uses Matplotlib for "Notebook-safe" display
plt.ion()  # Turn on interactive mode
fig, ax = plt.subplots(figsize=(10, 6))
fig.canvas.manager.set_window_title('Drishti AI Live Vision')

print("DRISHTI SYSTEM LIVE: Point your iPhone at the road...")
print("TIP: Close the window or press Ctrl+C in terminal to stop.")

try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret: break

        # 4. RUN AI DETECTION (Conf 0.3 for good balance)
        results = model.predict(frame, conf=0.5, verbose=False)
        
        # 5. DRAW LABELS & BOXES
        annotated_frame = results[0].plot()
        
        # 6. UPDATE DISPLAY
        frame_rgb = cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB)
        ax.clear()
        ax.imshow(frame_rgb)
        ax.axis('off')
        
        # Check for detections and print to terminal for feedback
        for box in results[0].boxes:
            class_id = int(box.cls[0])
            label = model.names[class_id]
            if label.lower() == "zebra_crossing":
                print(f"ALERT: {label.upper()} DETECTED!")

        plt.draw()
        plt.pause(0.001)

        # 7. SAFE CLOSE - Stop if user clicks the "X" on the window
        if not plt.fignum_exists(fig.number):
            break

except KeyboardInterrupt:
    print("\nManual Stop Requested.")

finally:
    # 8. CLEANUP
    cap.release()
    plt.close('all')
    print("Drishti System Shutdown Cleanly.")