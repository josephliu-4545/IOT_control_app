# Firebase Cloud Functions Backend (IoT)

This folder scaffolds a Firebase Cloud Functions backend for the Flutter IoT app.

## What this backend does

- Devices authenticate using headers:
  - `x-device-id`
  - `x-device-token`

The token is validated against Firestore:

`devices/{deviceId}`

```json
{
  "token": "YOUR_DEVICE_SECRET_TOKEN",
  "enabled": true
}
```

## Deploy prerequisites

- Install Firebase CLI
- Login: `firebase login`
- Initialize Firebase in this repo (if not already):
  - `firebase init functions firestore`
  - Choose **JavaScript**
  - Use Node 18

This repo includes `firebase.json` and `firestore.rules` already.

## Install dependencies

From repo root:

```bash
cd functions
npm install
```

## Local emulation

```bash
firebase emulators:start --only functions,firestore
```

Health check:

```bash
curl http://127.0.0.1:5001/<PROJECT_ID>/<REGION>/api/health
```

## Deploy

```bash
firebase deploy --only functions
firebase deploy --only firestore:rules
```

## Device endpoints

All endpoints are served under the exported function name `api`.

Example base URL (production):

```
https://<REGION>-<PROJECT_ID>.cloudfunctions.net/api
```

### A) Poll commands

`GET /device/commands?deviceId=esp32cam-001`

Headers:

- `x-device-id: esp32cam-001`
- `x-device-token: <token>`

Response:

- If none: `{ "command": null }`
- If exists: `{ "command": { "id": "...", "deviceId": "...", "command": "analyze_environment", ... } }`

Example curl:

```bash
curl "https://<REGION>-<PROJECT_ID>.cloudfunctions.net/api/device/commands?deviceId=esp32cam-001" \
  -H "x-device-id: esp32cam-001" \
  -H "x-device-token: <token>"
```

### B) Upload an image for environment analysis

`POST /device/upload-image`

This backend accepts **multipart/form-data** with:

- file field: `image` (JPEG)
- optional text field: `commandId` (a Firestore `device_commands` doc id)

Example curl:

```bash
curl -X POST "https://<REGION>-<PROJECT_ID>.cloudfunctions.net/api/device/upload-image" \
  -H "x-device-id: esp32cam-001" \
  -H "x-device-token: <token>" \
  -F "commandId=<DEVICE_COMMAND_DOC_ID>" \
  -F "image=@/path/to/photo.jpg;type=image/jpeg"
```

What happens:

- Uploads to Storage: `environment/{deviceId}/{timestamp}.jpg`
- Generates a signed download URL
- Calls `aiService.analyzeEnvironment(...)` (currently stub)
- Writes to Firestore `environment_analysis`:

```json
{
  "deviceId": "esp32cam-001",
  "imageUrl": "https://...",
  "result": {
    "lighting": "unknown",
    "hazards": [],
    "summary": "...",
    "risk_level": "unknown"
  },
  "createdAt": "<serverTimestamp>"
}
```

### C) Heart-rate telemetry

`POST /device/telemetry/heart-rate`

Headers:

- `x-device-id`
- `x-device-token`

JSON body:

```json
{ "bpm": 72, "spo2": 98 }
```

Example curl:

```bash
curl -X POST "https://<REGION>-<PROJECT_ID>.cloudfunctions.net/api/device/telemetry/heart-rate" \
  -H "Content-Type: application/json" \
  -H "x-device-id: esp32cam-001" \
  -H "x-device-token: <token>" \
  -d '{"bpm":72,"spo2":98}'
```

This writes:

- `heart_rate_telemetry` (raw)
- `heart_rate_analysis` (rule-based)

## Firestore Rules

See `firestore.rules`.

Important:

- Mobile users must be authenticated to read analysis.
- Users can create commands only for devices they’re allowed to control:

`user_devices/{uid}/devices/{deviceId}` must exist.

- Devices do **not** write to Firestore directly; only the backend does.
