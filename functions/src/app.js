const express = require('express');
const cors = require('cors');

const { deviceRouter } = require('./routes/device');

function createApp({ admin }) {
  const app = express();

  app.use(cors({ origin: true }));

  // JSON body parsing for non-multipart routes.
  app.use(express.json({ limit: '2mb' }));

  app.get('/health', (_req, res) => {
    res.json({ ok: true });
  });

  app.use('/device', deviceRouter({ admin }));

  return app;
}

module.exports = { createApp };
