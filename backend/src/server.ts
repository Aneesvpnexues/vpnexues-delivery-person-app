import { config } from './config.js'
import { pool } from './db.js'
import { buildApp } from './app.js'

const app = await buildApp()

// Graceful shutdown: ECS / App Runner send SIGTERM, then wait (stopTimeout) before SIGKILL.
// Stop accepting connections, finish in-flight requests, close the DB pool.
let closing = false
for (const sig of ['SIGTERM', 'SIGINT'] as const) {
  process.on(sig, async () => {
    if (closing) return
    closing = true
    app.log.info({ sig }, 'shutting down')
    const force = setTimeout(() => process.exit(1), 25_000).unref()
    try {
      await app.close()
      await pool?.end()
      clearTimeout(force)
      process.exit(0)
    } catch (err) {
      app.log.error({ err }, 'error during shutdown')
      process.exit(1)
    }
  })
}

try {
  await app.listen({ host: config.HOST, port: config.PORT })
  if (!pool) app.log.warn('DATABASE_URL is not set — API is up, but data endpoints will return 503 DB_NOT_CONFIGURED')
} catch (err) {
  app.log.error({ err }, 'failed to start')
  process.exit(1)
}
