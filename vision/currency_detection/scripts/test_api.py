import requests
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
image_path = os.path.join(BASE_DIR, "test_images", "sample29.jpeg")

url = "http://127.0.0.1:5000/predict"

with open(image_path, "rb") as f:
    response = requests.post(url, files={"image": f})

print(response.json())


