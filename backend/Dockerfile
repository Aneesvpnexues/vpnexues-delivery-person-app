# syntax=docker/dockerfile:1
# Production image for AWS App Runner / ECS Fargate (linux/amd64 or linux/arm64 — Graviton is cheaper).

FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine
ENV NODE_ENV=production \
    PORT=4000 \
    # Trust the Amazon RDS CA bundle for TLS to the database (downloaded below).
    NODE_EXTRA_CA_CERTS=/app/certs/rds-global-bundle.pem
WORKDIR /app
RUN apk add --no-cache tini wget \
 && mkdir -p certs \
 && wget -qO certs/rds-global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
COPY migrations ./migrations
USER node
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT}/health || exit 1
# tini forwards SIGTERM so graceful shutdown works under ECS.
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/src/server.js"]
