/**
 * Minimal forward-only migration runner.
 *
 *   npm run migrate              # local (reads .env)
 *   npm run migrate -- --status  # list applied / pending without changing anything
 *   node dist/scripts/migrate.js # in the container — run as a one-off ECS task before deploying a new version
 *
 * Applies every migrations/NNNN_*.sql not yet recorded in schema_migrations, each in its own
 * transaction, in filename order. A Postgres advisory lock stops two deploys migrating at once.
 * Applied files are checksummed; editing one after it ran is reported as an error — add a new file instead.
 */
import { readdir, readFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import pg from 'pg'
import { dbSslOptions } from '../src/lib/dbSsl.js'

const here = path.dirname(fileURLToPath(import.meta.url))
// Works both from scripts/ (tsx) and dist/scripts/ (compiled).
const dir = [path.resolve(here, '../migrations'), path.resolve(here, '../../migrations')]
const statusOnly = process.argv.includes('--status')

async function main() {
  const url = process.env.DATABASE_URL
  if (!url) throw new Error('DATABASE_URL is not set')
  const client = new pg.Client({ connectionString: url, ssl: dbSslOptions() })
  await client.connect()

  let migrationsDir = dir[0]
  try { await readdir(migrationsDir) } catch { migrationsDir = dir[1] }
  const files = (await readdir(migrationsDir)).filter((f) => /^\d{4}_.+\.sql$/.test(f)).sort()

  try {
    await client.query('SELECT pg_advisory_lock(727274)')
    await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
      filename text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())`)
    const applied = new Map((await client.query('SELECT filename, checksum FROM schema_migrations')).rows.map((r) => [r.filename, r.checksum]))

    let ran = 0
    for (const f of files) {
      const sql = await readFile(path.join(migrationsDir, f), 'utf8')
      // Checksum LF-normalised text so a Windows checkout (CRLF) doesn't look like an edited migration.
      const sum = createHash('sha256').update(sql.replace(/\r\n/g, '\n')).digest('hex')
      if (applied.has(f)) {
        if (applied.get(f) !== sum) throw new Error(`${f} was modified after being applied. Create a new migration instead.`)
        if (statusOnly) console.log(`  applied  ${f}`)
        continue
      }
      if (statusOnly) { console.log(`  pending  ${f}`); continue }
      process.stdout.write(`→ ${f} ... `)
      await client.query('BEGIN')
      try {
        await client.query(sql)
        await client.query('INSERT INTO schema_migrations (filename, checksum) VALUES ($1, $2)', [f, sum])
        await client.query('COMMIT')
        console.log('ok')
        ran++
      } catch (e) {
        await client.query('ROLLBACK')
        console.log('FAILED')
        throw e
      }
    }
    if (!statusOnly) console.log(ran ? `Applied ${ran} migration(s).` : 'Database is up to date.')
  } finally {
    await client.query('SELECT pg_advisory_unlock(727274)').catch(() => {})
    await client.end()
  }
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e)
  process.exit(1)
})
