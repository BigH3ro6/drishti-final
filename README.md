```markdown
# Drishti Monorepo

Drishti is a visually impaired assistance application that combines a Flutter mobile app with a Python/Flask backend and Firebase services.

## 📂 Project Structure

```text
drishti-monorepo/
├── apps/
│   └── user_mobile/          # Flutter Mobile Application
│       ├── android/          # Android Native Code
│       ├── ios/              # iOS Native Code
│       └── lib/
│           ├── config.dart   # Network Configuration (IP Address)
│           └── main.dart     # App Entry Point
├── backend/
│   └── flask_service/        # Python Flask API
│       ├── app/
│       │   ├── routes/       # API Endpoints
│       │   └── __init__.py   # App Factory
│       ├── certs/            # Firebase Admin SDK Keys (Ignored by Git)
│       ├── venv/             # Virtual Environment (Ignored by Git)
│       ├── run.py            # Server Entry Point
│       └── requirements.txt  # Python Dependencies
└── README.md                 # This file

```

---

## 🚀 Getting Started

To run this project locally, you need to set up both the **Backend** and the **Frontend**.

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Python 3.10+](https://www.python.org/downloads/)
* [Android Studio](https://developer.android.com/studio) (with Android SDK installed)
* A Firebase Project (Firestore Database enabled)

---

### 1️⃣ Backend Setup (Flask)

1. **Navigate to the service:**
```bash
cd backend/flask_service

```


2. **Create and Activate Virtual Environment:**
```bash
# Windows
python -m venv venv
.\venv\Scripts\activate

# Mac/Linux
python3 -m venv venv
source venv/bin/activate

```


3. **Install Dependencies:**
```bash
pip install -r requirements.txt

```


4. **Add Firebase Credentials:**
* Download your Firebase Admin SDK private key (`serviceAccountKey.json`).
* Create a folder named `certs` inside `backend/flask_service/`.
* Place the file at: `backend/flask_service/certs/serviceAccountKey.json`.


5. **Run the Server:**
```bash
python run.py

```


*Server should run on `http://0.0.0.0:5000*`

---

### 2️⃣ Frontend Setup (Flutter)

1. **Navigate to the app:**
```bash
cd apps/user_mobile

```


2. **Add Firebase Configuration:**
* Download `google-services.json` from Firebase Console (Android App).
* Place it in: `apps/user_mobile/android/app/google-services.json`.


3. **Configure Network IP:**
* Open `lib/config.dart`.
* Find your computer's local IP address (Run `ipconfig` on Windows or `ifconfig` on Mac).
* Update the `baseUrl`:
```dart
static const String baseUrl = "http://YOUR_LOCAL_IP:5000";

```




4. **Install Dependencies:**
```bash
flutter pub get

```


5. **Run the App:**
* Connect a physical device or start an emulator.
* Run:
```bash
flutter run

```





---

### 🛠 Troubleshooting

* **"No Android SDK found":** - Ensure you have the Android SDK installed via Android Studio.
* Run `flutter config --android-sdk "PATH_TO_SDK"`.
* Accept licenses: `flutter doctor --android-licenses`.


* **"Connection Failed" on App:**
* Ensure both devices are on the same WiFi.
* Check `lib/config.dart` has the correct IP.
* **Windows Users:** You may need to allow Python through the Firewall or disable the Firewall temporarily for testing.


