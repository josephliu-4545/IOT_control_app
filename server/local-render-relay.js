const http = require('http');
const https = require('https');

const PORT = Number(process.env.LOCAL_RELAY_PORT || 8787);
const RENDER_HOST = 'iot-control-app.onrender.com';
const ALLOWED_PATHS = new Set([
  '/health',
  '/device/upload-image',
  '/device/dashboard',
]);

const server = http.createServer((request, response) => {
  const incomingUrl = new URL(request.url, `http://${request.headers.host}`);
  if (!ALLOWED_PATHS.has(incomingUrl.pathname)) {
    response.writeHead(404, { 'content-type': 'text/plain' });
    response.end('Not found');
    return;
  }

  const headers = { ...request.headers, host: RENDER_HOST };
  console.log(`${new Date().toISOString()} ${request.method} ${incomingUrl.pathname}`);

  const upstream = https.request(
    {
      hostname: RENDER_HOST,
      port: 443,
      path: `${incomingUrl.pathname}${incomingUrl.search}`,
      method: request.method,
      headers,
      timeout: 120000,
    },
    (upstreamResponse) => {
      console.log(
        `${new Date().toISOString()} ${incomingUrl.pathname} -> ${upstreamResponse.statusCode}`,
      );
      response.writeHead(upstreamResponse.statusCode || 502, upstreamResponse.headers);
      upstreamResponse.pipe(response);
    },
  );

  upstream.on('timeout', () => {
    upstream.destroy(new Error('Render did not respond within 120 seconds'));
  });
  upstream.on('error', (error) => {
    console.error('RELAY ERROR:', error.message);
    if (!response.headersSent) {
      response.writeHead(502, { 'content-type': 'application/json' });
    }
    response.end(JSON.stringify({ error: 'Relay failed', details: error.message }));
  });

  request.pipe(upstream);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Local Render relay listening on http://0.0.0.0:${PORT}`);
  console.log(`Phone backend URL: http://172.20.10.4:${PORT}`);
});
