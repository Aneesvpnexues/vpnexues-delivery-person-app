import pg from 'pg'
import { config } from './config.js'
import { AppError } from './lib/errors.js'
import { dbSslOptions } from './lib/dbSsl.js'

// Return BIGINT/NUMERIC as JS numbers (safe for our value ranges: paise sums, counts, ratings).
pg.types.setTypeParser(pg.types.builtins.INT8, (v) => Number(v))
pg.types.setTypeParser(pg.types.builtins.NUMERIC, (v) => Number(v))

export const pool = config.DATABASE_URL
  ? new pg.Pool({
      connectionString: config.DATABASE_URL,
      max: config.DB_POOL_MAX,
      // RDS: DB_SSL=true (CA bundle via NODE_EXTRA_CA_CERTS). Supabase: DB_SSL_CA. See lib/dbSsl.ts.
      ssl: dbSslOptions(),
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000,
    })
  : null

function requirePool(): pg.Pool {
  if (!pool) throw new AppError(503, 'DB_NOT_CONFIGURED', 'Database is not configured yet (set DATABASE_URL).')
  return pool
}

export type Db = Pick<pg.PoolClient, 'query'>

export async function query<T extends pg.QueryResultRow = any>(sql: string, params: unknown[] = [], db?: Db): Promise<T[]> {
  const res = await (db ?? requirePool()).query<T>(sql, params)
  return res.rows
}

export async function one<T extends pg.QueryResultRow = any>(sql: string, params: unknown[] = [], db?: Db): Promise<T | undefined> {
  return (await query<T>(sql, params, db))[0]
}

/** Run `fn` inside a transaction; rolls back on any thrown error. */
export async function tx<T>(fn: (db: Db) => Promise<T>): Promise<T> {
  const client = await requirePool().connect()
  try {
    await client.query('BEGIN')
    const out = await fn(client)
    await client.query('COMMIT')
    return out
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {})
    throw e
  } finally {
    client.release()
  }
}

export async function dbHealthy(): Promise<boolean | null> {
  if (!pool) return null
  try {
    await pool.query('SELECT 1')
    return true
  } catch {
    return false
  }
}
