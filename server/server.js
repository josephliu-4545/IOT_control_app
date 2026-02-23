const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const axios = require('axios');
const multer = require('multer');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

dotenv.config();

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

function initFirebaseAdmin() {
  // Option 1: Provide full JSON in one env var (recommended on Render)
  // FIREBASE_SERVICE_ACCOUNT_JSON={...}
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const json = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    admin.initializeApp({
      credential: admin.credential.cert(json),
    });
    return;
  }

  // Option 2: Provide individual fields
  // FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY
  const projectId = requireEnv('FIREBASE_PROJECT_ID');
  const clientEmail = requireEnv('FIREBASE_CLIENT_EMAIL');
  const privateKey = requireEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n');

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });
}

initFirebaseAdmin();

const db = admin.firestore();

async function validateDevice(req) {
  const deviceId = req.header('x-device-id');
  const deviceToken = req.header('x-device-token');

  if (!deviceId || !deviceToken) {
    const err = new Error('Missing x-device-id or x-device-token');
    err.status = 401;
    throw err;
  }

  const doc = await db.doc(`devices/${deviceId}`).get();
  if (!doc.exists) {
    const err = new Error('Unknown device');
    err.status = 401;
    throw err;
  }

  const data = doc.data() || {};
  if (data.enabled !== true) {
    const err = new Error('Device disabled');
    err.status = 403;
    throw err;
  }
  if (data.token !== deviceToken) {
    const err = new Error('Invalid device token');
    err.status = 401;
    throw err;
  }

  return { deviceId };
}

async function aiAnalyzeEnvironmentStub({ deviceId, imageBase64 }) {
  void deviceId;
  void imageBase64;

  // Placeholder response structure (matches your Flutter model mapping).
  return {
    lighting: 'unknown',
    hazards: [],
    summary: 'AI stub: analysis not configured yet.',
    risk_level: 'unknown',
  };
}

async function analyzeImageWithHF(imageBuffer) {
  try {
    const base64 = imageBuffer.toString('base64');

    const response = await axios.post(
      'https://router.huggingface.co/hf-inference/models/google/vit-base-patch16-224',
      {
        inputs: `data:image/jpeg;base64,${base64}`,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.HF_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );

    return response.data;
  } catch (error) {
    console.error('HF ERROR FULL:', {
      status: error.response?.status,
      data: error.response?.data,
      message: error.message,
    });
    return null;
  }
}

function analyzeHeartRate({ bpm, prevBpm }) {
  const flags = [];

  if (bpm < 40) flags.push('low');
  if (bpm > 120) flags.push('high');

  let delta = null;
  if (Number.isFinite(prevBpm)) {
    delta = Math.abs(bpm - prevBpm);
    if (delta >= 30) flags.push('spike');
  }

  const hasSpike = flags.includes('spike');
  const hasLowOrHigh = flags.includes('low') || flags.includes('high');

  let primaryStatus = 'normal';
  if (hasSpike) {
    primaryStatus = 'critical';
  } else if (hasLowOrHigh) {
    primaryStatus = 'warning';
  }

  const reasonParts = [];
  if (flags.includes('low')) reasonParts.push('BPM below 40.');
  if (flags.includes('high')) reasonParts.push('BPM above 120.');
  if (flags.includes('spike')) {
    reasonParts.push(
      delta == null
        ? 'Spike detected.'
        : `Spike detected (Δ${delta} from previous BPM).`
    );
  }

  const reason = reasonParts.length ? reasonParts.join(' ') : 'Within normal range.';
  return { flags, primaryStatus, reason };
}

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use('/uploads', express.static(uploadsDir));

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => {
      cb(null, uploadsDir);
    },
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '') || '.jpg';
      const safeExt = ext.length <= 10 ? ext : '.jpg';
      cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${safeExt}`);
    },
  }),
  limits: {
    fileSize: 2 * 1024 * 1024, // 2MB
  },
});

app.get('/health', (_req, res) => {
  res.send('ok');
});

app.get('/device/commands', async (req, res) => {
  try {
    const { deviceId } = await validateDevice(req);

    const queryDeviceId = req.query.deviceId;
    if (!queryDeviceId || queryDeviceId !== deviceId) {
      return res.status(400).json({ error: 'deviceId query param must match x-device-id' });
    }

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

    await doc.ref.set(
      {
        status: 'running',
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return res.json({ command: payload });
  } catch (err) {
    const status = err.status || 500;
    return res.status(status).json({ error: err.message || 'Error', details: String(err) });
  }
});

app.get('/device/dashboard', async (req, res) => {
  try {
    const { deviceId } = await validateDevice(req);

    function normalizeHeartRateAnalysisDoc(doc) {
      if (!doc || typeof doc !== 'object') return doc;

      if (doc.primaryStatus) {
        return {
          ...doc,
          flags: Array.isArray(doc.flags) ? doc.flags : [],
          primaryStatus: doc.primaryStatus,
        };
      }

      if (!doc.status) {
        return {
          ...doc,
          flags: Array.isArray(doc.flags) ? doc.flags : [],
          primaryStatus: 'normal',
        };
      }

      const status = String(doc.status);
      if (status === 'low') return { ...doc, flags: ['low'], primaryStatus: 'warning' };
      if (status === 'high') return { ...doc, flags: ['high'], primaryStatus: 'warning' };
      if (status === 'spike') return { ...doc, flags: ['spike'], primaryStatus: 'critical' };
      if (status === 'normal') return { ...doc, flags: [], primaryStatus: 'normal' };
      return { ...doc, flags: [], primaryStatus: 'normal' };
    }

    const queryDeviceId = req.query.deviceId;
    if (!queryDeviceId || queryDeviceId !== deviceId) {
      return res.status(400).json({ error: 'deviceId query param must match x-device-id' });
    }

    const latestQuery = db
      .collection('heart_rate_analysis')
      .where('deviceId', '==', deviceId)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    const historyQuery = db
      .collection('heart_rate_analysis')
      .where('deviceId', '==', deviceId)
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    const latestImageQuery = db
      .collection('device_images')
      .where('deviceId', '==', deviceId)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    const [latestSnap, historySnap, latestImageSnap] = await Promise.all([
      latestQuery,
      historyQuery,
      latestImageQuery,
    ]);

    const latestRaw = latestSnap.empty
      ? null
      : { id: latestSnap.docs[0].id, ...latestSnap.docs[0].data() };

    const latest = latestRaw ? normalizeHeartRateAnalysisDoc(latestRaw) : null;

    const history = historySnap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .map(normalizeHeartRateAnalysisDoc);

    const summary = {
      totalReadings: history.length,
      critical: history.filter((d) => d.primaryStatus === 'critical').length,
      warning: history.filter((d) => d.primaryStatus === 'warning').length,
      normal: history.filter((d) => d.primaryStatus === 'normal').length,
    };

    const latestImage = latestImageSnap.empty
      ? null
      : { id: latestImageSnap.docs[0].id, ...latestImageSnap.docs[0].data() };

    return res.json({ ok: true, latest, history, summary, latestImage });
  } catch (err) {
    const status = err.status || 500;
    return res.status(status).json({ error: err.message || 'Error', details: String(err) });
  }
});

app.post('/device/upload-image', upload.single('image'), async (req, res) => {
  try {
    const { deviceId } = await validateDevice(req);

    if (!req.file || !req.file.path || !req.file.filename) {
      return res.status(400).json({ error: 'Missing multipart file field "image"' });
    }

    const imageUrl = `https://iot-control-app.onrender.com/uploads/${req.file.filename}`;

    await db.collection('device_images').add({
      deviceId,
      imageUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Convert image to base64 for AI stub (do NOT store in Firestore; can exceed 1MB doc limit).
    const imageBytes = await fs.promises.readFile(req.file.path);
    const imageBase64 = imageBytes.toString('base64');

    const hfResult = await analyzeImageWithHF(imageBytes);

    let result;

    if (!hfResult || !Array.isArray(hfResult)) {
      result = {
        lighting: 'unknown',
        hazards: [],
        summary: 'AI failed to analyze image.',
        risk_level: 'unknown',
      };
    } else {
      function normalizeLabel(raw) {
        const label = String(raw || '').toLowerCase();
        if (!label) return '';

        if (label.includes('cat')) return 'cat';
        if (label.includes('tissue') || label.includes('paper')) return 'tissue';
        if (label.includes('plunger') || label.includes('plumber')) return 'plunger';
        return label;
      }

      const cleanedLabels = Array.from(
        new Set(
          hfResult
            .filter((p) => (p?.score ?? 0) > 0.15)
            .slice()
            .sort((a, b) => (b?.score ?? 0) - (a?.score ?? 0))
            .slice(0, 7)
            .map((p) => normalizeLabel(p?.label))
            .filter(Boolean)
        )
      );

      const hazardKeywords = {
        sharp: ['knife', 'scissors'],
        fire: ['fire', 'flame', 'smoke'],
        fall: ['stairs', 'ladder'],
        trip: ['cable', 'wire'],
        breakable: ['glass', 'bottle'],
      };

      const hazardSet = new Set();
      for (const label of cleanedLabels) {
        const lower = label.toLowerCase();
        for (const [category, keywords] of Object.entries(hazardKeywords)) {
          if (keywords.some((k) => lower.includes(k))) {
            hazardSet.add(category);
          }
        }
      }
      const hazards = Array.from(hazardSet);

      let riskLevel = 'low';
      if (hazards.includes('fire') || hazards.includes('sharp')) {
        riskLevel = 'high';
      } else if (hazards.length > 0) {
        riskLevel = 'medium';
      }

      result = {
        lighting: 'unknown',
        hazards,
        summary: `Detected objects: ${cleanedLabels.join(', ')}`,
        risk_level: riskLevel,
      };
    }

    const analysisRef = await db.collection('environment_analysis').add({
      deviceId,
      imageInfo: {
        mimeType: req.file.mimetype,
        sizeBytes: req.file.size,
      },
      result,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Mark command completed.
    const commandId = req.body?.commandId;
    if (commandId) {
      await db.collection('device_commands').doc(String(commandId)).set(
        {
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          resultRef: analysisRef,
        },
        { merge: true }
      );
    } else {
      // Fallback: mark newest running command completed.
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

    return res.json({ ok: true, analysisId: analysisRef.id, result });
  } catch (err) {
    const status = err.status || 500;
    return res.status(status).json({ error: err.message || 'Error', details: String(err) });
  }
});

app.post('/device/telemetry/heart-rate', async (req, res) => {
  try {
    const { deviceId } = await validateDevice(req);

    const bpm = Number(req.body?.bpm);
    const spo2 = Number(req.body?.spo2);

    if (!Number.isFinite(bpm) || !Number.isFinite(spo2)) {
      return res.status(400).json({ error: 'Body must include numeric bpm and spo2' });
    }

    // Get previous bpm (for spike detection)
    const prevSnap = await db
      .collection('heart_rate_analysis')
      .where('deviceId', '==', deviceId)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    const prevBpm = prevSnap.empty ? null : Number(prevSnap.docs[0].data()?.bpm);

    const analysis = analyzeHeartRate({ bpm, prevBpm });

    const docRef = await db.collection('heart_rate_analysis').add({
      deviceId,
      bpm,
      spo2,
      flags: analysis.flags,
      primaryStatus: analysis.primaryStatus,
      reason: analysis.reason,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({
      ok: true,
      id: docRef.id,
      analysis: {
        bpm,
        spo2,
        flags: analysis.flags,
        primaryStatus: analysis.primaryStatus,
        reason: analysis.reason,
      },
    });
  } catch (err) {
    const status = err.status || 500;
    return res.status(status).json({ error: err.message || 'Error', details: String(err) });
  }
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  // Intentionally console.log for Render logs.
  // eslint-disable-next-line no-console
  console.log(`Server listening on port ${port}`);
});
