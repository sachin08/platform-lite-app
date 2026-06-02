const express = require('express');
const app = express();

app.use(express.json());

const PORT = process.env.PORT || 4000;

// ✅ health check
app.get('/health', (req, res) => {
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

// ✅ SAMPLE endpoint
app.get('/', (req, res) => {
  res.json({
    service: "orders-service ✅",
    message: "Orders API running 🚀"
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Orders service running on port ${PORT}`);
});