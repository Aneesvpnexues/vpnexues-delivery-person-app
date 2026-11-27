# syntax=docker/dockerfile:1
# Dual backend — selectable build targets:
#   * default (no --target)  -> Spring Boot Java API  (Render)
#   * --target node-runtime  -> Node/Fastify API      (AWS App Runner / ECS)

# ======================== Node/Fastify (optional) ========================
FROM node:22-alpine AS node-build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine AS node-runtime
ENV NODE_ENV=production \
    PORT=4000 \
    NODE_EXTRA_CA_CERTS=/app/certs/rds-global-bundle.pem
WORKDIR /app
RUN apk add --no-cache tini wget \
 && mkdir -p certs \
 && wget -qO certs/rds-global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
COPY --from=node-build /app/node_modules ./node_modules
COPY --from=node-build /app/dist ./dist
COPY package.json ./
COPY migrations ./migrations
USER node
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT}/health || exit 1
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/src/server.js"]

# ======================== Spring Boot (DEFAULT) ========================
# Must be the last stage so `docker build` without --target produces the Java image.
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
