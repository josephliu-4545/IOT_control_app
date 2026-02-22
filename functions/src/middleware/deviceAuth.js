function deviceAuth({ admin }) {
  return async function deviceAuthMiddleware(req, res, next) {
    try {
      const deviceId = req.header('x-device-id');
      const deviceToken = req.header('x-device-token');

      if (!deviceId || !deviceToken) {
        return res.status(401).json({ error: 'Missing x-device-id or x-device-token' });
      }

      const doc = await admin.firestore().doc(`devices/${deviceId}`).get();
      if (!doc.exists) {
        return res.status(401).json({ error: 'Unknown device' });
      }

      const data = doc.data() || {};
      if (data.enabled !== true) {
        return res.status(403).json({ error: 'Device disabled' });
      }
      if (data.token !== deviceToken) {
        return res.status(401).json({ error: 'Invalid device token' });
      }

      req.device = { deviceId };
      return next();
    } catch (err) {
      return res.status(500).json({ error: 'Auth error', details: String(err) });
    }
  };
}

module.exports = { deviceAuth };
