# Multi-stage Dockerfile for building the Astro site and serving with nginx
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --silent

# Copy source and build
COPY . .
RUN npm run build

FROM nginx:stable-alpine AS runner

# Copy built static site from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose default HTTP port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
