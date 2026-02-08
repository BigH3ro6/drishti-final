# 👓 Drishti - Smart Vision Assistant

A comprehensive assistive technology system for the visually impaired. This monorepo contains the firmware for smart glasses, a Flutter mobile application, a Python Flask backend, and Machine Learning models.

## 📁 Project Structure

```text
drishti-monorepo/
├── apps/
│   └── user-mobile/         # 📱 Flutter App (The interface for the blind user)
│
├── backend/                 # ☁️ Cloud Layer
│   └── flask_service/       # Python Flask API + MongoDB connection
│       ├── app/             # Application logic (Routes, Models)
│       ├── .env             # Secrets (API Keys, DB URI) - DO NOT COMMIT
│       └── requirements.txt # Python dependencies
│
├── firmware/                # 🕶️ Edge Layer (Smart Glasses)
│   └── esp32-cam/           # C++ code for ESP32 microcontroller
│
└── ml/                      # 🤖 Machine Learning
    ├── training/            # Python notebooks for model training
    └── models/              # TFLite models for the mobile app

```

## 🚀 Quick Start Guide

### Prerequisites

* **Flutter SDK**: [Install Guide](https://docs.flutter.dev/get-started/install)
* **Python (3.8+)**: [Download](https://www.python.org/downloads/)
* **VS Code** with **PlatformIO Extension** (For ESP32 development)
* **MongoDB Atlas** account or local MongoDB Community Server.

---

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-org/drishti-monorepo.git
cd drishti-monorepo

```

### Step 2: ☁️ Backend Setup (Flask)

1. **Navigate to the backend folder:**
```bash
cd backend/flask_service

```


2. **Create a Virtual Environment:**
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Mac/Linux
python3 -m venv venv
source venv/bin/activate

```


3. **Install Dependencies:**
```bash
pip install -r requirements.txt

```


4. **Configure Environment:**
* Create a file named `.env` in `backend/flask_service/`.
* Add your connection string:
```text
MONGO_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/drishti_db
SECRET_KEY=your_secret_key_here

```




5. **Run the Server:**
```bash
python run.py

```


*You should see: `Running on http://0.0.0.0:5000*`

---

### Step 3: 📱 Mobile App Setup (Flutter)

1. **Navigate to the app folder:**
```bash
# Open a new terminal
cd apps/user-mobile

```


2. **Install Packages:**
```bash
flutter pub get

```


3. **Configure API Endpoint:**
* Find your laptop's Local IP address (`ipconfig` on Windows / `ifconfig` on Mac).
* Open `lib/config/constants.dart` (or wherever you store URLs).
* Update the `BASE_URL`:
```dart
const String BASE_URL = "http://YOUR_LAPTOP_IP:5000";

```




4. **Run the App:**
```bash
flutter run

```



---

### Step 4: 🕶️ Firmware Setup (ESP32)

1. Open the `firmware/esp32-cam` folder in **VS Code**.
2. Ensure the **PlatformIO** extension is installed.
3. Connect your ESP32-CAM via FTDI programmer.
4. Click the **Arrow Icon (→)** in the bottom toolbar to **Upload**.

---

## 👥 Team Workflow (6 Developers)

We follow a **Feature Branch** workflow. Direct commits to `main` are restricted.

### 1. Creating a New Feature

Always branch off from `main` before starting work.

```bash
# 1. Update your local main
git checkout main
git pull origin main

# 2. Create your feature branch
# Naming convention: category/description
git checkout -b feat/sos-voice-command
# OR
git checkout -b fix/login-bug

```

### 2. Committing Work

Write clear messages explaining *what* changed.

```bash
git add .
git commit -m "feat: implemented voice command listener"

```

### 3. Merging Code

1. Push your branch: `git push origin feat/sos-voice-command`
2. Go to GitHub and open a **Pull Request (PR)**.
3. Ask a teammate to review your code.
4. Once approved, merge into `main`.

---

## 🛠️ Common Troubleshooting

| Error | Solution |
| --- | --- |
| **Flutter: Connection Refused** | Ensure your phone and laptop are on the **same WiFi**. Check if `BASE_URL` matches your laptop's IP. |
| **Flask: Module not found** | Ensure your virtual environment is activated (`venv`). |
| **ESP32: Upload Failed** | Check if GPIO 0 is connected to GND (flash mode) and press the Reset button on the board. |
| **MongoDB Authentication Fail** | Check your `.env` file username/password. Ensure your IP is whitelisted in MongoDB Atlas. |

---

**Built by the Drishti Team**