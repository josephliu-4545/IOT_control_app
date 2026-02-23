# Smart IoT Health Ecosystem (Flutter + Firebase + Render Backend)

This repository contains:

- A **Flutter** app (Smart Health Dashboard)
- A standalone **Node.js (Express)** backend (hosted on Render)
- A **Firebase/Firestore** data layer for real-time updates and device command orchestration

The system supports an end-to-end pipeline:

1. Flutter sends an **analyze environment** command to Firestore (`device_commands`)
2. Device uploads an image to the backend (`/device/upload-image`)
3. Backend runs a HuggingFace model (currently **ViT**) and writes `environment_analysis`
4. Flutter streams the latest analysis from Firestore and displays it on the dashboard

---

## Features

- **Dashboard screen (Flutter)**
  - Live sensor cards (heart rate, SpO₂, Wi‑Fi, battery, solar)
  - Environment Analysis card (risk level, lighting, hazards, summary)
  - Analyze button that writes a Firestore command

- **Live Health Dashboard screen (Flutter)**
  - Pull-to-refresh view backed by the Render backend `/device/dashboard`
  - Shows latest reading + history + summary

- **Backend (Node/Express on Render)**
  - Device authentication via `x-device-id` and `x-device-token`
  - Image uploads stored under `server/uploads` and served as `/uploads/...`
  - Writes analysis results to Firestore (`environment_analysis`)

- **Architecture**
  - `DashboardViewModel` (Provider + ChangeNotifier) subscribes to Firestore streams
  - `FirebaseIoTService` provides typed streams for:
    - sensor snapshots
    - glasses state
    - environment analysis
  - `DeviceCommandService` writes device commands to Firestore

---

## Project Structure

```text
lib/
 ├── main.dart                # App entry, theme, Provider setup
 ├── firebase_options.dart     # Firebase config (FlutterFire)
 ├── screens/
 │    ├── dashboard.dart      # Main dashboard + environment analysis card
 │    ├── health.dart         # Animated heart + HR trend chart
 │    ├── live_dashboard.dart # REST-backed dashboard screen
 ├── services/
 │    ├── firebase_iot_service.dart
 │    ├── device_command_service.dart
 │    ├── dashboard_api_service.dart
 ├── models/
 │    ├── environment_analysis.dart
 │    ├── snapshots.dart
 ├── widgets/
 │    ├── sensor_card.dart    # Reusable neon metric card widget
 ├── utils/
 │    ├── constants.dart      # Colors + spacing

server/
 ├── server.js                # Express backend (Render)
 ├── package.json             # Backend dependencies
 └── uploads/                 # Uploaded images (served as /uploads)
```

---

## Firestore Collections

- `device_commands`
  - Created by Flutter (Analyze button)
  - Consumed by the device/backend pipeline

- `environment_analysis`
  - Written by backend after image upload + HF analysis
  - Streamed by Flutter dashboard

- `heart_rate_analysis`
  - Written by backend telemetry endpoint

- `device_images`
  - Written by backend when an image is uploaded

---

## Running the Flutter App

1. Install Flutter (3.x) and Dart SDK.
2. From the project root, fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Ensure an emulator or device is available, then run:

   ```bash
   flutter run
   ```

Firebase is initialized with `DefaultFirebaseOptions.currentPlatform`.

To run unit/widget tests:

```bash
flutter test
```

---

## Running the Backend (server/)

From `server/`:

```bash
npm install
npm start
```

### Required environment variables

- `HF_TOKEN`
- One of:
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
  - or `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`

### Key endpoints

- `GET /health`
- `GET /device/commands` (device polls for pending commands)
- `POST /device/upload-image` (multipart field `image`)
- `POST /device/telemetry/heart-rate`
- `GET /device/dashboard`

All device endpoints require headers:

- `x-device-id`
- `x-device-token`

---

## Tech Stack

- **Flutter** (Dart)
- **Firebase**: `firebase_core`, `cloud_firestore`, `firebase_auth`
- **State management:** Provider + ChangeNotifier
- **Backend:** Node.js + Express + Firestore (firebase-admin)
- **AI inference:** HuggingFace router API (currently `google/vit-base-patch16-224`)
- **Fonts:** Google Fonts (Poppins)

This project is structured to be easy to extend with additional IoT devices and
virtual pins as your Smart Health Ecosystem grows.
