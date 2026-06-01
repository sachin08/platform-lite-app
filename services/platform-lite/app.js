//load env variables

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
}


const express = require('express');
const redis = require('redis');

const app = express();

const PORT = process.env.PORT || 3000;
const MESSAGE = "OIDC deployment ✅ 🔐";
// const MESSAGE = process.env.APP_MESSAGE || "Hello from Platform Lite 🚀";


// Redis client setup
// const redisClient = redis.createClient({
//     url: 'redis://redis:6379'  // 👈 service name from docker-compose
// });


// redisClient.connect().catch(console.error);

let redisClient;

if (process.env.REDIS_HOST) {
    redisClient = redis.createClient({
        url: `redis://${process.env.REDIS_HOST}:6379`
    });

    redisClient.connect()
        .then(() => console.log('✅ Connected to Redis'))
        .catch(err => {
            console.error('❌ Redis connection failed, falling back to app memory', err);
            redisClient = null;
        });
}

// Health check endpoint (super important in real-world apps)
app.get('/health', (req, res) => {
    res.json({ status: 'UP' });
});


// Endpoint using Redis
// app.get('/api/message', async (req, res) => {
//     try {
//         let message = await redisClient.get('message');

//         if (!message) {
//             message = MESSAGE;
//             await redisClient.set('message', message);
//         }

//         res.json({ message, source: 'redis-cache' });
//     } catch (err) {
//         res.status(500).json({ error: err.message });
//     }
// });

app.get('/api/message', async (req, res) => {
    try {
        if (redisClient) {
            let message = await redisClient.get('message');

            if (!message) {
                message = MESSAGE;
                await redisClient.set('message', message);
            }

            return res.json({ message, source: 'redis-cache' });
        }

        // fallback if redis not present
        res.json({ message: MESSAGE, source: 'app-memory' });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/orders', (req, res) => {
  res.json({
    service: "orders-service ✅",
    message: "Orders endpoint working 🚀"
  });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});