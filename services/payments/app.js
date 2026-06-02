
const express = require('express');
const app = express();
const COLOR = process.env.COLOR || "unknown";
const VERSION = process.env.GITHUB_SHA || "local";

app.use(express.json());

const PORT = process.env.PORT || 4000;

app.get('/payments/health', (req, res) => {
  res.send({ status: 'UP' });
});

app.get('/payments', (req, res) => {
  res.json({
    service: "payments",
    message: "Service running 🚀"
  });
});

app.get('/payments/info', (req, res) => {
  res.json({
    service: process.env.SERVICE_NAME,
    color: COLOR,
    version: VERSION
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`payments running on port ${PORT}`);
});
