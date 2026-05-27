# Use official Node.js image
FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./

# Install dependencies
RUN npm install -g npm@11
RUN npm ci --loglevel=error --no-audit --no-fund

# Copy rest of the app
COPY . .

# Expose app port
EXPOSE 4000

# Start the app
CMD ["node", "app.js"]
