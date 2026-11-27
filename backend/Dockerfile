# syntax=docker/dockerfile:1
# Both backend implementations are kept as selectable build targets:
#   * default / --target runtime      -> Node/Fastify API (AWS App Runner / ECS Fargate)
#   * --target java-runtime           -> Spring Boot API from origin/anees

# --- Spring Boot API (origin/anees): docker build --target java-runtime . ---
FROM maven:3.9-eclipse-temurin-21 AS java-build
WORKDIR /app
COPY pom.xml .
RUN mvn -B -q dependency:go-offline || true
COPY src ./src
RUN mvn -B -DskipTests clean package

FROM eclipse-temurin:21-jre-jammy AS java-runtime
WORKDIR /app
COPY --from=java-build /app/target/partner-api-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

# --- Node/Fastify API (HEAD): default production image ---
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine AS runtime
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
