FROM node:22.12.0 AS builder

WORKDIR /app

# Install deps FIRST (before copying all files)
COPY package*.json ./
RUN npm install

# Then copy source
COPY . .
RUN npm run build