const express = require('express');
const Busboy = require('busboy');

const { deviceAuth } = require('../middleware/deviceAuth');
const { uploadJpegToStorageAndGetUrl } = require('../services/storage');
const { analyzeEnvironment } = require('../services/aiService');
const { analyzeHeartRateTelemetry } = require('../services/heartRateAnalysis');

function deviceRouter({ admin }) {
  const router = express.Router();

  const auth = deviceAuth({ admin });

  // A) GET /device/commands?deviceId=...
  router.get('/commands', auth, async (req, res) => {
    const queryDeviceId = req.query.deviceId;
    const deviceId = req.device.deviceId;

    if (!queryDeviceId || queryDeviceId !== deviceId) {
      return res.status(400).json({ error: 'deviceId query param must match x-device-id' });
    }

    try {
      const db = admin.firestore();
      const snap = await db
        .collection('device_commands')
        .where('deviceId', '==', deviceId)
        .where('status', '==', 'pending')
        .orderBy('createdAt', 'asc')
        .limit(1)
        .get();

      if (snap.empty) {
        return res.json({ command: null });
      }

      const doc = snap.docs[0];
      const payload = { id: doc.id, ...doc.data() };

      // Optionally mark as running to prevent duplicate processing.
      await doc.ref.update({
        status: 'running',
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({ command: payload });
    } catch (err) {
      return res.status(500).json({ error: 'Failed to fetch commands', details: String(err) });
    }
  });

  // B) POST /device/upload-image
  // Auth required (deviceAuth)
  // Accept multipart/form-data with field name: image
  router.post('/upload-image', auth, async (req, res) => {
    const deviceId = req.device.deviceId;

    const busboy = Busboy({ headers: req.headers });

    let commandId = null;
    let imageBuffer = null;
    let imageMime = null;

    busboy.on('field', (name, value) => {
      if (name === 'commandId') commandId = value;
    });

    busboy.on('file', (name, file, info) => {
      if (name !== 'image') {
        file.resume();
        return;
      }

      imageMime = info.mimeType;
      const chunks = [];
      file.on('data', (d) => chunks.push(d));
      file.on('end', () => {
        imageBuffer = Buffer.concat(chunks);
      });
    });

    busboy.on('finish', async () => {
      try {
        if (!imageBuffer || imageBuffer.length === 0) {
          return res.status(400).json({ error: 'Missing image file field "image"' });
        }

        if (imageMime && imageMime !== 'image/jpeg' && imageMime !== 'image/jpg') {
          return res.status(400).json({ error: 'Only image/jpeg is supported' });
        }

        const { imagePath, imageUrl } = await uploadJpegToStorageAndGetUrl({
          admin,
          deviceId,
          imageBuffer,
        });

        const result = await analyzeEnvironment({ imageUrl, imageBuffer });

        const db = admin.firestore();
        const analysisRef = await db.collection('environment_analysis').add({
          deviceId,
          imageUrl,
          imagePath,
          result,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mark the related command completed.
        if (commandId) {
          await db.collection('device_commands').doc(commandId).set(
            {
              status: 'completed',
              completedAt: admin.firestore.FieldValue.serverTimestamp(),
              resultRef: analysisRef,
            },
            { merge: true }
          );
        } else {
          // Fallback: mark the newest running command completed.
          const runningSnap = await db
            .collection('device_commands')
            .where('deviceId', '==', deviceId)
            .where('status', '==', 'running')
            .orderBy('startedAt', 'desc')
            .limit(1)
            .get();

          if (!runningSnap.empty) {
            await runningSnap.docs[0].ref.set(
              {
                status: 'completed',
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                resultRef: analysisRef,
              },
              { merge: true }
            );
          }
        }

        return res.json({ ok: true, imageUrl, analysisId: analysisRef.id, result });
      } catch (err) {
        return res.status(500).json({ error: 'Upload/analyze failed', details: String(err) });
      }
    });

    req.pipe(busboy);
  });

  // C) POST /device/telemetry/heart-rate
  router.post('/telemetry/heart-rate', auth, async (req, res) => {
    const deviceId = req.device.deviceId;

    const bpm = Number(req.body?.bpm);
    const spo2 = Number(req.body?.spo2);

    if (!Number.isFinite(bpm) || !Number.isFinite(spo2)) {
      return res.status(400).json({ error: 'Body must include numeric bpm and spo2' });
    }

    try {
      const db = admin.firestore();

      await db.collection('heart_rate_telemetry').add({
        deviceId,
        bpm,
        spo2,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const analysis = await analyzeHeartRateTelemetry({ admin, deviceId, bpm });

      await db.collection('heart_rate_analysis').add({
        deviceId,
        bpm,
        spo2,
        status: analysis.status,
        reason: analysis.reason,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({ ok: true, analysis });
    } catch (err) {
      return res.status(500).json({ error: 'Telemetry failed', details: String(err) });
    }
  });

  return router;
}

module.exports = { deviceRouter };
