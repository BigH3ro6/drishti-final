import requests
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
url = "http://127.0.0.1:5000/predict"

# Test all images in test_images folder
test_images_dir = os.path.join(BASE_DIR, "test_images")

for image_name in os.listdir(test_images_dir):
    if image_name.endswith((".jpeg", ".jpg", ".png")):
        image_path = os.path.join(test_images_dir, image_name)

        with open(image_path, "rb") as f:
            response = requests.post(url, files={"image": f})
            result = response.json()

        print(f"Image: {image_name}")
        print(f"Result: {result}")
        print("-" * 40)

