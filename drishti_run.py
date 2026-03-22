import cv2
import os
import time
import matplotlib.pyplot as plt
from ultralytics import YOLO

# 1. SETUP
model_path = r'C:\Users\USER\Downloads\Obstacle_Detection_Project\drishti-final\ml_pipeline_Obstacle_det\runs\detect\Drishti_Final_Push\v11n_augmented_852\weights\best.pt'
model = YOLO(model_path)

# NEW: Dedicated folder for Live Mobility Scene recordings
OUTPUT_DIR = r'C:\Users\USER\Downloads\Obstacle_Detection_Project\drishti-final\output_lives'
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# Unique filename with timestamp (e.g., live_test_20260319_1410.mp4)
timestamp = time.strftime("%Y%m%d_%H%M%S")
video_save_path = os.path.join(OUTPUT_DIR, f"live_test_{timestamp}.mp4")

# 2. CAMERA FINDER (Iriun usually sits at Index 1 or 2)
def get_camera():
    for index in [1, 2, 0]:
        cap = cv2.VideoCapture(index)
        if cap.isOpened():
            ret, _ = cap.read()
            if ret: return cap
            cap.release()
    return None

cap = get_camera()
if cap is None:
    print("ERROR: No camera detected. Open Iriun on your iPhone first.")
    exit()

# 3. VIDEO WRITER CONFIG
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = 15  # Adjust based on your Lenovo LOQ's processing speed
fourcc = cv2.VideoWriter_fourcc(*'mp4v') 
out = cv2.VideoWriter(video_save_path, fourcc, fps, (frame_width, frame_height))

# 4. GUI SETUP
plt.ion()
fig, ax = plt.subplots(figsize=(10, 6))
fig.canvas.manager.set_window_title('Drishti AI: Live Mobility Scene')

print(f"RECORDING STARTED: Saving to {video_save_path}")

try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret: break

        # Run AI (Using 0.5 confidence for the street test)
        results = model.predict(frame, conf=0.5, verbose=False)
        annotated_frame = results[0].plot()
        
        # SAVE TO FILE
        out.write(annotated_frame)

        # DISPLAY IN WINDOW
        frame_rgb = cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB)
        ax.clear()
        ax.imshow(frame_rgb)
        ax.axis('off')
        
        # Terminal Feedback for important obstacles
        for box in results[0].boxes:
            label = model.names[int(box.cls[0])]
            if label.lower() in ["zebra_crossing", "pothole"]:
                print(f"{label.upper()} DETECTED!")

        plt.draw()
        plt.pause(0.01)

        if not plt.fignum_exists(fig.number):
            break

except KeyboardInterrupt:
    print("\nStopping...")

finally:
    cap.release()
    out.release() # This "finalizes" the video file so it's playable
    plt.close('all')
    print(f"Live test saved successfully: {video_save_path}")