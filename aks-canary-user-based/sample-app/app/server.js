/**
 * Sample app for canary POC.
 * Serves HTML that shows version (from env APP_VERSION) and echoes X-User-Id from request header.
 * Build two images: one with APP_VERSION=1 (stable), one with APP_VERSION=2 (canary).
 */
const http = require('http');

const PORT = process.env.PORT || 8080;
const APP_VERSION = process.env.APP_VERSION || '1';

const server = http.createServer((req, res) => {
  const userId = req.headers['x-user-id'] || '(not set)';
  const versionLabel = APP_VERSION === '2' ? 'canary' : 'stable';

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Canary Demo - v${APP_VERSION}</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 600px; margin: 2rem auto; padding: 0 1rem; }
    .version { font-size: 1.5rem; font-weight: bold; }
    .canary { color: #059669; }
    .stable { color: #2563eb; }
    code { background: #f1f5f9; padding: 2px 6px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>Canary Demo App</h1>
  <p class="version ${versionLabel}">Version: ${APP_VERSION} (${versionLabel})</p>
  <p>Request header <code>X-User-Id</code>: <code>${userId}</code></p>
  <p><small>Pod: ${process.env.HOSTNAME || 'unknown'}</small></p>
</body>
</html>
`;

  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(html);
});

server.listen(PORT, () => {
  console.log(`App v${APP_VERSION} listening on port ${PORT}`);
});
