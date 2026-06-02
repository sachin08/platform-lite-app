
console.log("payments - test deployment ✅");

const express = require('express');
const app = express();

app.use(express.json());

const PORT = process.env.PORT || 4000;

app.get('/health', (req, res) => {
  res.send({ status: 'UP' });
});

app.get('/info', (req, res) => {
  res.json({
    service: "payments",
    message: "Service running 🚀"
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`payments running on port ${PORT}`);
});
