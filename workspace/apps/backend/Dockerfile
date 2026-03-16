# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /workspace

# Copy workspace root files
COPY package*.json tsconfig.base.json ./

# Copy packages/lib
COPY packages/lib/package.json ./packages/lib/
COPY packages/lib/tsconfig.json ./packages/lib/
COPY packages/lib/src ./packages/lib/src

# Copy apps/backend
COPY apps/backend/package.json ./apps/backend/
COPY apps/backend/tsconfig.json ./apps/backend/
COPY apps/backend/src ./apps/backend/src

# Install all dependencies and build
RUN npm install
RUN npm run build -w lib
RUN npm run build -w backend

# Stage 2: Run
FROM node:22-alpine
WORKDIR /app

# Copy built backend and its node_modules
COPY --from=builder /workspace/apps/backend/dist ./dist
COPY --from=builder /workspace/apps/backend/package.json ./
COPY --from=builder /workspace/node_modules ./node_modules
COPY --from=builder /workspace/packages/lib/dist ./node_modules/lib/dist
COPY --from=builder /workspace/packages/lib/package.json ./node_modules/lib/

RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
RUN chown -R nodejs:nodejs /app
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/hello', r => process.exit(r.statusCode===200?0:1))"
CMD ["node", "dist/index.js"]
