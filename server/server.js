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

// Language mapping for translation models
const TRANSLATION_MODELS = {
  'my': 'facebook/m2m100_418M',     // Burmese
  'es': 'facebook/m2m100_418M',     // Spanish
  'fr': 'facebook/m2m100_418M',     // French
  'de': 'facebook/m2m100_418M',     // German
  'zh': 'facebook/m2m100_418M',     // Chinese
  'ja': 'facebook/m2m100_418M',     // Japanese
  'ru': 'facebook/m2m100_418M',     // Russian
  'ar': 'facebook/m2m100_418M',     // Arabic
  'hi': 'facebook/m2m100_418M',     // Hindi
};

// Simple translations for common environment analysis terms
// Fallback when HF translation fails or for offline use
const TRANSLATION_FALLBACKS = {
  'es': {
    'Detected objects': 'Objetos detectados',
    'AI failed to analyze image': 'La IA no pudo analizar la imagen',
    'unknown': 'desconocido',
    'low': 'bajo',
    'medium': 'medio',
    'high': 'alto',
  },
  'fr': {
    'Detected objects': 'Objets détectés',
    'AI failed to analyze image': 'L\'IA n\'a pas pu analyser l\'image',
    'unknown': 'inconnu',
    'low': 'faible',
    'medium': 'moyen',
    'high': 'élevé',
  },
  'de': {
    'Detected objects': 'Erkannte Objekte',
    'AI failed to analyze image': 'KI konnte das Bild nicht analysieren',
    'unknown': 'unbekannt',
    'low': 'niedrig',
    'medium': 'mittel',
    'high': 'hoch',
  },
  'zh': {
    'Detected objects': '检测到的物体',
    'AI failed to analyze image': 'AI 无法分析图像',
    'unknown': '未知',
    'low': '低',
    'medium': '中',
    'high': '高',
  },
  'ja': {
    'Detected objects': '検出された物体',
    'AI failed to analyze image': 'AI が画像を分析できませんでした',
    'unknown': '不明',
    'low': '低',
    'medium': '中',
    'high': '高',
  },
  'ru': {
    'Detected objects': 'Обнаруженные объекты',
    'AI failed to analyze image': 'ИИ не смог проанализировать изображение',
    'unknown': 'неизвестно',
    'low': 'низкий',
    'medium': 'средний',
    'high': 'высокий',
  },
  'ar': {
    'Detected objects': 'الأجسام المكتشفة',
    'AI failed to analyze image': 'فشل الذكاء الاصطناعي في تحليل الصورة',
    'unknown': 'غير معروف',
    'low': 'منخفض',
    'medium': 'متوسط',
    'high': 'عالي',
  },
  'hi': {
    'Detected objects': 'पहचाने गए वस्तुएं',
    'AI failed to analyze image': 'AI छवि का विश्लेषण करने में विफल रहा',
    'unknown': 'अज्ञात',
    'low': 'कम',
    'medium': 'मध्यम',
    'high': 'उच्च',
  },
  'my': {
    'Detected objects': 'တွေ့ရှိသော အရာဝတ္ထုများ',
    'AI failed to analyze image': 'AI သည် ပုံကို ခွဲခြမ်းစိတ်ဖြာရန် မအောင်မြင်ခဲ့ပါ',
    'unknown': 'မသိရှိပါ',
    'low': 'နိမ့်',
    'medium': 'အလတ်',
    'high': 'မြင့်',
  },
};

async function translateText(text, targetLang) {
  if (!text || targetLang === 'en' || targetLang === 'en-US') {
    return text;
  }

  const langCode = targetLang.split('-')[0].toLowerCase();

  // Try HF translation first
  try {
    const model = TRANSLATION_MODELS[langCode];
    if (!model) {
      throw new Error(`No translation model for ${langCode}`);
    }

    const response = await axios.post(
      `https://router.huggingface.co/hf-inference/models/${model}`,
      {
        inputs: text,
        parameters: {
          src_lang: 'en',
          tgt_lang: langCode,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.HF_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 10000,
      }
    );

    if (response.data && response.data[0] && response.data[0].translation_text) {
      return response.data[0].translation_text;
    }
  } catch (error) {
    console.error('HF Translation error:', error.message);
  }

  // Fallback to simple term replacement
  const fallbackDict = TRANSLATION_FALLBACKS[langCode];
  if (fallbackDict) {
    let translated = text;
    for (const [en, translatedTerm] of Object.entries(fallbackDict)) {
      translated = translated.replace(new RegExp(en, 'gi'), translatedTerm);
    }
    return translated;
  }

  // Last resort: return original
  return text;
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

    // Get language from header (e.g., 'en-US', 'my-MM')
    const langHeader = req.header('x-lang') || 'en-US';
    const langCode = langHeader.split('-')[0].toLowerCase();
    console.log('Translation request - langHeader:', langHeader, 'langCode:', langCode);

    if (!hfResult || !Array.isArray(hfResult)) {
      // Translate error message if needed
      let errorSummary = 'AI failed to analyze image.';
      if (langCode !== 'en') {
        try {
          console.log('Translating error message:', errorSummary);
          errorSummary = await translateText(errorSummary, langHeader);
          console.log('Translated error message:', errorSummary);
        } catch (e) {
          console.error('Error translation failed:', e);
          // Keep English if translation fails
        }
      }
      result = {
        lighting: 'unknown',
        hazards: [],
        summary: errorSummary,
        risk_level: 'unknown',
      };
    } else {
      const formattedLabels = hfResult
        .slice()
        .sort((a, b) => (b?.score ?? 0) - (a?.score ?? 0))
        .slice(0, 7)
        .flatMap((p) => {
          const score = Number(p?.score ?? 0);
          const rawLabel = String(p?.label ?? '').trim();
          if (!rawLabel) return [];

          const labels = rawLabel
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);

          return labels.map((label) => `${label} (${score.toFixed(2)})`);
        });

      // Language already extracted above

      console.log('Original labels:', formattedLabels);
      
      // Translate individual object names for better results
      const translatedLabels = await Promise.all(
        formattedLabels.map(async (label) => {
          // Extract object name (remove score part)
          const match = label.match(/^(.+?)\s+\(/);
          const objectName = match ? match[1] : label;
          const scorePart = label.includes('(') ? label.substring(label.indexOf('(')) : '';
          
          console.log('Processing label:', label, 'objectName:', objectName);
          
          if (langCode === 'en') {
            return label; // No translation needed
          }
          
          try {
            console.log('Translating object:', objectName, 'to:', langHeader);
            const translatedName = await translateText(objectName, langHeader);
            console.log('Translation result:', translatedName);
            return `${translatedName}${scorePart}`;
          } catch (e) {
            console.error(`Failed to translate "${objectName}":`, e);
            return label; // Keep original if translation fails
          }
        })
      );
      
      console.log('Translated labels:', translatedLabels);
      
      // Build translated summary
      const prefixText = langCode === 'en' ? 'Detected objects:' : await translateText('Detected objects:', langHeader);
      const summary = `${prefixText} ${translatedLabels.join(', ')}`;
      
      console.log('Final translated summary:', summary);

      result = {
        lighting: 'unknown',
        hazards: [],
        summary: summary,
        risk_level: 'low',
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
