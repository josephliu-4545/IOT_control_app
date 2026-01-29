# Smart IoT Health Ecosystem (Flutter + Blynk)

This Flutter app is a **dark, minimal Smart Health Dashboard** for an IoT system
built around **ESP32** devices and **Blynk Cloud**. It currently simulates:

- A **smart wristband** (heart-rate + SpO₂ + Wi‑Fi + battery + solar status)
- A pair of **smart glasses** (camera control, environment monitoring,
  connection status)

The app is designed to run entirely in **dummy mode** for development and
testing, and can later be switched to **live mode** to read/write from real
ESP32 hardware via Blynk.

---

## Features

- **Dashboard screen**
  - System online/offline banner
  - Heart Rate (BPM)
  - Oxygen / SpO₂ (%)
  - Wi‑Fi signal strength (%)
  - Battery level (%) + solar charging status
  - Smart glasses:
    - Camera card with dummy toggle bottom sheet
    - Environment card (ambient temperature around glasses)
    - Link status card (connected/offline)

- **Health screen**
  - Large animated heart with live BPM
  - Simple line chart (sparkline) of recent heart‑rate history

- **Architecture**
  - `BlynkService` encapsulates all HTTP access to the Blynk Cloud REST API
  - `DashboardViewModel` (Provider + ChangeNotifier) polls Blynk every 2s and
    exposes:
    - `SensorSnapshot` (wristband vitals)
    - `GlassesSnapshot` (smart glasses state)
  - All UI stays in the `screens/` and `widgets/` layer.

---

## Project Structure

```text
lib/
 ├── main.dart                # App entry, theme, Provider setup
 ├── screens/
 │    ├── dashboard.dart      # Main dashboard + smart glasses UI
 │    ├── health.dart         # Animated heart + HR trend chart
 ├── services/
 │    ├── blynk_service.dart  # Blynk Cloud read/write + dummy simulation
 ├── widgets/
 │    ├── sensor_card.dart    # Reusable neon metric card widget
 ├── utils/
 │    ├── constants.dart      # Colors, spacing, Blynk config
```

---

## Blynk & ESP32 Mapping

All Blynk configuration lives in `lib/utils/constants.dart` under `BlynkConfig`.

### Mode switch

```dart
class BlynkConfig {
  // true  -> dummy data (no network calls)
  // false -> live data from Blynk Cloud
  static const bool useDummyData = true;

  static const String baseUrl = 'https://blynk.cloud/external/api';
  static const String authToken = 'YOUR_BLYNK_AUTH_TOKEN';
}
```

Change `useDummyData` to `false` and set a real `authToken` to enable live mode.

### Wristband virtual pins

These are read by `BlynkService.fetchSensorSnapshot()` and displayed on the
dashboard and health screens:

```dart
// Wristband
static const String pinHeartRate = 'V0';    // BPM
static const String pinOxygen    = 'V1';    // SpO₂ %
static const String pinWifi      = 'V2';    // Wi‑Fi signal %
static const String pinBattery   = 'V3';    // Battery level %
// Optional: add a solar pin (e.g. V4) for more precise solar status.
```

On the ESP32 wristband, write sensor values to these pins; the app will read
them every 2 seconds.

### Smart glasses virtual pins

These are handled by `BlynkService.fetchGlassesSnapshot()` and
`BlynkService.setGlassesCamera()`:

```dart
// Smart glasses
static const String pinGlassesCamera      = 'V10'; // 0 = off, 1 = on
static const String pinGlassesTemperature = 'V11'; // e.g. °C
static const String pinGlassesLink        = 'V12'; // 0 = offline, 1 = connected
```

- Glasses ESP32 should **listen** on `V10` to toggle the camera/recording.
- It should **write** ambient temperature to `V11` and link state to `V12`.

In dummy mode these pins are **simulated** inside `BlynkService` and no network
calls are made.

---

## Running the App

1. Install Flutter (3.x) and Dart SDK.
2. From the project root, fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Ensure an emulator or device is available, then run:

   ```bash
   flutter run
   ```

By default, the app runs in **dummy mode** (`useDummyData = true`) and
generates realistic‑looking values without any hardware.

To run unit/widget tests:

```bash
flutter test
```

---

## Switching to Live Blynk / ESP32 Hardware

When your ESP32 devices are ready:

1. Update `BlynkConfig`:

   ```dart
   static const bool useDummyData = false;
   static const String authToken = 'YOUR_REAL_BLYNK_TOKEN';
   ```

2. Configure your Blynk template so that:

   - Wristband virtual pins match `V0–V3`.
   - Glasses virtual pins match `V10–V12`.

3. Program the ESP32 devices to read/write those pins. The Flutter app will
   start consuming **live data** through `BlynkService` without any UI changes.

4. (Optional future step) Use `DashboardViewModel.setGlassesCamera(bool on)`
   from the smart glasses camera bottom sheet to send real camera ON/OFF
   commands via `V10`.

---

## Tech Stack

- **Flutter 3.x** (Dart)
- **State management:** Provider + ChangeNotifier
- **API:** Blynk Cloud REST API (`http` package)
- **Fonts:** Google Fonts (Poppins)
- **Style:** Dark, minimal, smartwatch‑inspired dashboard UI

This project is structured to be easy to extend with additional IoT devices and
virtual pins as your Smart Health Ecosystem grows.
