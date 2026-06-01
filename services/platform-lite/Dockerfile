# Use official Node.js image
FROM node:20.18-slim

# Set working directory
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
