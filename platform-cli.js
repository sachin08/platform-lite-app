#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const command = process.argv[2];
const serviceName = process.argv[3];

if (!command || !serviceName) {
  console.log("Usage: node platform-cli.js create-service <name>");
  process.exit(1);
}

if (command === "create-service") {
  const servicePath = path.join(__dirname, 'services', serviceName);

  if (fs.existsSync(servicePath)) {
    console.log("Service already exists ❌");
    process.exit(1);
  }

  // ✅ Create directory
  fs.mkdirSync(servicePath, { recursive: true });

  // ✅ Create app.js
  const appTemplate = `
const express = require('express');
const app = express();

app.use(express.json());

const PORT = process.env.PORT || 4000;

app.get('/health', (req, res) => {
  res.send({ status: 'UP' });
});

app.get('/info', (req, res) => {
  res.json({
    service: "${serviceName}",
    message: "Service running 🚀"
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(\`${serviceName} running on port \${PORT}\`);
});
`;

  fs.writeFileSync(path.join(servicePath, 'app.js'), appTemplate);

  // ✅ Create Dockerfile
  const dockerTemplate = `
FROM node:20.18-slim

WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./

# Install dependencies
RUN apt-get update && apt-get install -y wget
RUN npm install -g npm@latest
RUN npm install --omit=dev --no-package-lock

# Copy rest of the app
COPY . .

# Expose app port
EXPOSE 4000

# Start the app
CMD ["node", "app.js"]
`;

  fs.writeFileSync(path.join(servicePath, 'Dockerfile'), dockerTemplate);

  // ✅ Create package.json
  const packageTemplate = `
{
  "name": "${serviceName}",
  "version": "1.0.0",
  "main": "app.js",
  "type": "commonjs",
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^17.4.2",
    "redis": "^5.12.1"
  }
}
`;

  fs.writeFileSync(path.join(servicePath, 'package.json'), packageTemplate);

  console.log(`✅ Service ${serviceName} created successfully`);
}