# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /workspace

# Copy workspace root files
COPY package*.json tsconfig.base.json ./

# Copy packages/lib
COPY packages/lib/package.json ./packages/lib/
COPY packages/lib/tsconfig.json ./packages/lib/
COPY packages/lib/src ./packages/lib/src

# Copy apps/frontend
COPY apps/frontend/package.json ./apps/frontend/
COPY apps/frontend/tsconfig.json ./apps/frontend/
COPY apps/frontend/vite.config.ts ./apps/frontend/
COPY apps/frontend/tailwind.config.js ./apps/frontend/
COPY apps/frontend/postcss.config.js ./apps/frontend/
COPY apps/frontend/index.html ./apps/frontend/
COPY apps/frontend/src ./apps/frontend/src

# Install all dependencies and build
RUN npm install
RUN npm run build -w lib
RUN npm run build -w frontend

# Stage 2: Serve
FROM nginx:alpine
COPY --from=builder /workspace/apps/frontend/dist /usr/share/nginx/html
RUN mkdir -p /usr/share/nginx/html && chown -R nginx:nginx /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
