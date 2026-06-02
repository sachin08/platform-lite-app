const express = require('express');
const app = express();
const COLOR = process.env.COLOR || "unknown";
const VERSION = process.env.GITHUB_SHA || "local";


app.use(express.json());

const PORT = process.env.PORT || 4000;

// ✅ health check
app.get('/orders/health', (req, res) => {
  res.json({ status: 'UP' });
});

// ✅ in-memory "database"
let orders = [];

// ✅ CREATE order
app.post('/orders', (req, res) => {
  const newOrder = {
    id: Date.now(),
    item: req.body.item || "default-item",
    createdAt: new Date()
  };

  orders.push(newOrder);

  res.status(201).json(newOrder);
});

// ✅ GET all orders
app.get('/orders', (req, res) => {
  res.json(orders);
});


app.get('/orders/info', (req, res) => {
  res.json({
    service: process.env.SERVICE_NAME,
    color: COLOR,
    version: VERSION
  });
});


app.listen(PORT, '0.0.0.0', () => {
  console.log(`Orders service running on port ${PORT}`);
});