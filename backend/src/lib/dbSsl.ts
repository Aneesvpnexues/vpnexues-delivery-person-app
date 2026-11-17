import type { ConnectionOptions } from 'node:tls'

/**
 * TLS options for Postgres, shared by the API and the migration runner (reads env directly).
 *
 *   DB_SSL=false      no TLS (local Docker Postgres)
 *   DB_SSL=true       TLS, certificate verified against the Node trust store
 *                     (+ NODE_EXTRA_CA_CERTS = RDS bundle in the Docker image)
 *   DB_SSL_CA=<PEM>   TLS, verified against this CA — e.g. Supabase's "Download certificate".
 *                     Newlines may be written as \n so it fits in one env var.
 *   DB_SSL=no-verify  TLS without certificate checks. Trial use only; logs a warning.
 */
export function dbSslOptions(env: NodeJS.ProcessEnv = process.env): false | ConnectionOptions {
  const mode = (env.DB_SSL ?? 'false').toLowerCase()
  const ca = env.DB_SSL_CA?.replace(/\\n/g, '\n').trim()
  if (ca) return { ca, rejectUnauthorized: true }
  if (mode === 'no-verify') {
    console.warn('[db] DB_SSL=no-verify: TLS certificate is NOT verified. Set DB_SSL_CA for anything beyond a trial.')
    return { rejectUnauthorized: false }
  }
  if (mode === 'true' || mode === '1') return { rejectUnauthorized: true }
  return false
}
