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
  - Heart rate monitor button (navigates to HealthScreen)

- **Health Screen (Flutter)**
  - Real-time BPM display from ESP8266 heart rate sensor
  - Animated heart with glow effect
  - Historical trend chart
  - Supports JSON, plain text, and labeled response formats

- **Live Health Dashboard screen (Flutter)**
  - Pull-to-refresh view backed by the Render backend `/device/dashboard`
  - Shows latest reading + history + summary

- **Backend (Node/Express on Render)**
  - Device authentication via `x-device-id` and `x-device-token`
  - Image uploads stored under `server/uploads` and served as `/uploads/...`
  - Writes analysis results to Firestore (`environment_analysis`)

- **Architecture**
  - `DashboardViewModel` (Provider + ChangeNotifier) subscribes to Firestore streams
  - `PulseViewModel` manages ESP8266 heart rate sensor polling (500ms interval)
  - `EspPulseService` handles HTTP requests to local ESP8266 endpoint
  - `FirebaseIoTService` provides typed streams for:
    - sensor snapshots
    - glasses state
    - environment analysis
  - `DeviceCommandService` writes device commands to Firestore

- **Hardware Integration**
  - ESP8266-based heart rate sensor (WiFi-enabled)
  - Direct HTTP polling from Flutter app (`http://172.20.10.8/`)
  - CORS-enabled Arduino server for web compatibility

---

## Project Structure

```text
lib/
 ├── main.dart                # App entry, theme, Provider setup
 ├── firebase_options.dart     # Firebase config (FlutterFire)
 ├── config/
 │    ├── api_config.dart     # API endpoints (ESP32-CAM, Heart Rate Sensor)
 ├── screens/
 │    ├── dashboard.dart      # Main dashboard + environment analysis card
 │    ├── health.dart         # Animated heart + HR trend chart (ESP8266 data)
 │    ├── live_dashboard.dart # REST-backed dashboard screen
 ├── services/
 │    ├── firebase_iot_service.dart
 │    ├── device_command_service.dart
 │    ├── dashboard_api_service.dart
 │    ├── esp_pulse_service.dart    # ESP8266 heart rate HTTP client
 │    ├── pulse_view_model.dart      # Heart rate polling & state management
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

## Heart Rate Sensor (ESP8266) Setup

### Hardware Requirements
- ESP8266 (NodeMCU or Wemos D1 Mini)
- Pulse/Heart Rate Sensor (analog output connected to A0)

### Arduino Configuration

Upload this sketch to your ESP8266:

```cpp
#include <ESP8266WiFi.h>

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

WiFiServer server(80);
const int sensorPin = A0;

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\nWiFi connected");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  
  server.begin();
}

void loop() {
  WiFiClient client = server.available();
  if (!client) return;

  // Wait for request
  unsigned long timeout = millis() + 5000;
  while (!client.available() && millis() < timeout) delay(1);
  
  String requestLine = client.readStringUntil('\r');
  
  // Discard headers
  while (client.available()) {
    String header = client.readStringUntil('\n');
    if (header == "\r" || header.length() <= 1) break;
  }

  // Handle CORS preflight
  if (requestLine.indexOf("OPTIONS") >= 0) {
    client.print("HTTP/1.1 204 No Content\r\n");
    client.print("Access-Control-Allow-Origin: *\r\n");
    client.print("Access-Control-Allow-Methods: GET, OPTIONS\r\n");
    client.print("Connection: close\r\n\r\n");
    client.stop();
    return;
  }

  // Read sensor
  int rawValue = analogRead(sensorPin);
  int bpm = map(rawValue, 0, 1023, 60, 120);  // Adjust based on your sensor
  
  // JSON response
  String response = "{\"raw\":" + String(rawValue) + ",\"bpm\":" + String(bpm) + "}";
  
  client.print("HTTP/1.1 200 OK\r\n");
  client.print("Content-Type: application/json\r\n");
  client.print("Content-Length: " + String(response.length()) + "\r\n");
  client.print("Access-Control-Allow-Origin: *\r\n");
  client.print("Connection: close\r\n\r\n");
  client.print(response);
  
  client.flush();
  delay(100);
  client.stop();
}
```

### Supported Response Formats

The `EspPulseService` automatically parses these formats:
- **JSON**: `{"raw":1024,"bpm":72}`
- **Plain text with two numbers**: `512,72`
- **Labeled**: `BPM: 72` or `Real Heart Rate: 72`

### Configuration

Update the IP address in `lib/config/api_config.dart`:
```dart
static const String heartRateBaseUrl = 'http://YOUR_ESP_IP/';
```

**Note for Web**: The ESP8266 must send CORS headers (`Access-Control-Allow-Origin: *`) for browser compatibility.

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
- **Hardware:** ESP8266 WiFi module with heart rate sensor
- **AI inference:** HuggingFace router API (currently `google/vit-base-patch16-224`)
- **Fonts:** Google Fonts (Poppins)

This project is structured to be easy to extend with additional IoT devices and
virtual pins as your Smart Health Ecosystem grows.
