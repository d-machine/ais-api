FROM node:20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package*.json ./

RUN npm ci

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Copy data to dist directory
RUN cp -r ./data /

# Copy public files to dist directory
RUN cp -r src/static dist/

# Production image
FROM node:20-alpine

WORKDIR /app

# Copy built files and package files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/data ./data
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.env.development ./

# Install production dependencies only
RUN npm ci --only=production && \
    npm cache clean --force

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 hono && \
    chown -R hono:nodejs /app

USER hono

EXPOSE 3000

CMD ["npm", "start"] 