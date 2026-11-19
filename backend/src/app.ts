import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import rateLimit from '@fastify/rate-limit'
import { randomUUID } from 'node:crypto'
import { config, isProd } from './config.js'
import { dbHealthy } from './db.js'
import { registerErrorHandler } from './lib/errors.js'
import { authPlugin } from './lib/auth.js'
import authRoutes from './modules/auth.js'
import partnerRoutes, { geoRoutes } from './modules/partner.js'
import documentRoutes from './modules/documents.js'
import moneyRoutes from './modules/money.js'
import orderRoutes from './modules/orders.js'
import engagementRoutes from './modules/engagement.js'
import trialRoutes from './modules/trial.js'
import adminRoutes from './modules/admin.js'

const startedAt = Date.now()

export async function buildApp() {
  const app = Fastify({
    // JSON logs on stdout → CloudWatch Logs via the awslogs driver / App Runner. Pretty enough locally too.
    logger: {
      level: config.LOG_LEVEL,
      redact: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.refreshToken', '*.accountNumber', '*.code'],
    },
    // Behind an AWS ALB / App Runner, trust X-Forwarded-For so req.ip is the real client.
    trustProxy: true,
    // Honour the ALB trace header so logs line up with AWS X-Ray / ALB access logs.
    genReqId: (req) => (req.headers['x-amzn-trace-id'] as string) ?? (req.headers['x-request-id'] as string) ?? randomUUID(),
    bodyLimit: 1_048_576,
  })

  registerErrorHandler(app)
  await app.register(helmet, { contentSecurityPolicy: false })
  await app.register(cors, {
    origin: config.CORS_ORIGINS.split(',').map((s) => s.trim()),
    credentials: false,
    // @fastify/cors only allows GET/HEAD/POST by default; the app also sends PUT/PATCH/DELETE.
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
    maxAge: 86400,
  })
  // In-memory limiter is fine for a single task; switch to the Redis store (ElastiCache) when running >1 task.
  await app.register(rateLimit, { global: true, max: 300, timeWindow: '1 minute' })
  await app.register(authPlugin)

  // ---- Health checks (ALB target group / App Runner / ECS container health) ----
  // logLevel 'warn' keeps the load balancer's every-few-seconds health probes out of the logs.
  app.get('/health', { logLevel: 'warn', config: { rateLimit: false } }, async () => ({ status: 'ok', uptimeSeconds: Math.round((Date.now() - startedAt) / 1000) }))
  app.get('/health/ready', { logLevel: 'warn', config: { rateLimit: false } }, async (_req, reply) => {
    const db = await dbHealthy()
    const ready = db !== false
    reply.status(ready ? 200 : 503)
    return { status: ready ? 'ready' : 'degraded', database: db === null ? 'not_configured' : db ? 'up' : 'down', env: config.NODE_ENV, trial: config.TRIAL_MODE }
  })

  // ---- API v1 ----
  await app.register(async (v1) => {
    await v1.register(geoRoutes)
    await v1.register(authRoutes, { prefix: '/auth' })
    await v1.register(partnerRoutes, { prefix: '/me' })
    await v1.register(documentRoutes)
    await v1.register(moneyRoutes)
    await v1.register(orderRoutes, { prefix: '/orders' })
    await v1.register(engagementRoutes)
    await v1.register(trialRoutes, { prefix: '/trial' })
    await v1.register(adminRoutes, { prefix: '/admin' })
  }, { prefix: '/v1' })

  if (!isProd) {
    app.get('/', async () => ({ name: 'VP Nexues Partner API', version: '0.1.0', docs: 'See README.md → API reference', health: '/health/ready' }))
  }
  return app
}
