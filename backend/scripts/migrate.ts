/**
 * Minimal forward-only migration runner with fail-closed target protection.
 *
 *   npm run migrate              # explicit target required (isolated Supabase or local loopback)
 *   npm run migrate -- --status  # read-only status; never creates schema_migrations
 *   node dist/scripts/migrate.js # in the container — run as a one-off task before deploying
 *
 * Applies every migrations/NNNN_*.sql not yet recorded in schema_migrations, each in its own
 * transaction, in filename order. A Postgres advisory lock stops two deploys migrating at once.
 * Applied files are checksummed; editing one after it ran is reported as an error — add a new file instead.
 *
 * Target identity is based on the Supabase project reference derived from DATABASE_URL, never
 * current_database(). The shared Buyer/Seller project must never be selected.
 */
import { readdir, readFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import pg from 'pg'
import { dbSslOptions } from '../src/lib/dbSsl.js'
import { runReadOnlyInspection } from '../src/lib/dbInspection.js'
import { assertAllowedMigrationTarget } from '../src/lib/supabaseIdentity.js'
import { redactConfigValues } from '../src/lib/redact.js'

const here = path.dirname(fileURLToPath(import.meta.url))
// Works both from scripts/ (tsx) and dist/scripts/ (compiled).
const migrationDirCandidates = [
  path.resolve(here, '../migrations'),
  path.resolve(here, '../../migrations'),
]
const statusOnly = process.argv.includes('--status')

const SHARED_PROJECT_TABLE_NAMES = new Set([
  'users',
  'orders',
  'order_items',
  'addresses',
  'seller_orders',
  'seller_locations',
  'notifications',
  'fcm_tokens',
])

async function resolveMigrationsDir(): Promise<string> {
  for (const candidate of migrationDirCandidates) {
    try {
      await readdir(candidate)
      return candidate
    } catch {
      // Try the next compiled/source location.
    }
  }
  throw new Error('Could not locate the migrations directory')
}

const checksum = (sql: string) =>
  createHash('sha256').update(sql.replace(/\r\n/g, '\n')).digest('hex')

async function main() {
  const url = process.env.DATABASE_URL
  if (!url) throw new Error('DATABASE_URL is not set')

  // Fail closed before opening any network connection.
  const target = assertAllowedMigrationTarget(url, process.env)

  const client = new pg.Client({ connectionString: url, ssl: dbSslOptions() })
  await client.connect()

  let locked = false
  try {
    await client.query('SELECT pg_advisory_lock(727274)')
    locked = true

    const query = (sql: string, params?: unknown[]) => client.query(sql, params)
    const inspection = await runReadOnlyInspection(query)
    const migrationsDir = await resolveMigrationsDir()
    const files = (await readdir(migrationsDir))
      .filter((f) => /^\d{4}_.+\.sql$/.test(f))
      .sort()

    const applied = new Map(
      inspection.migrations.map((m) => [m.filename, m.checksum] as const),
    )

    if (statusOnly) {
      console.log(
        target.kind === 'isolated'
          ? `Target: approved Supabase project ${target.projectRef}`
          : 'Target: local loopback database',
      )
      for (const f of files) {
        if (applied.has(f)) {
          if (applied.get(f) !== checksum(await readFile(path.join(migrationsDir, f), 'utf8'))) {
            console.log(`  changed ${f}`)
          } else {
            console.log(`  applied ${f}`)
          }
        } else {
          console.log(`  pending ${f}`)
        }
      }
      console.log('Read-only status complete; no changes were made.')
      return
    }

    if (!inspection.migrationsTableExists) {
      const collisions = inspection.tables.filter(
        (t) => t.table_schema === 'public' && SHARED_PROJECT_TABLE_NAMES.has(t.table_name),
      )
      if (inspection.baseTableCount > 0 || collisions.length > 0) {
        const detail = collisions.length
          ? ` Conflicting tables: ${collisions.map((t) => `public.${t.table_name}`).join(', ')}.`
          : ''
        throw new Error(
          `Refusing to initialize migrations on a non-empty public schema (${inspection.baseTableCount} base table(s)).${detail}`,
        )
      }
    }

    await client.query(`CREATE TABLE IF NOT EXISTS public.schema_migrations (
      filename text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())`)

    // Re-read under the advisory lock after the table is present.
    const appliedRows = (
      await client.query('SELECT filename, checksum FROM public.schema_migrations')
    ).rows as Array<{ filename: string; checksum: string }>
    const appliedAfterCreate = new Map(appliedRows.map((r) => [r.filename, r.checksum] as const))

    let ran = 0
    for (const f of files) {
      const sql = await readFile(path.join(migrationsDir, f), 'utf8')
      // Checksum LF-normalised text so a Windows checkout (CRLF) doesn't look like an edited migration.
      const sum = checksum(sql)
      if (appliedAfterCreate.has(f)) {
        if (appliedAfterCreate.get(f) !== sum) {
          throw new Error(`${f} was modified after being applied. Create a new migration instead.`)
        }
        continue
      }

      process.stdout.write(`→ ${f} ... `)
      await client.query('BEGIN')
      try {
        await client.query(sql)
        await client.query(
          'INSERT INTO public.schema_migrations (filename, checksum) VALUES ($1, $2)',
          [f, sum],
        )
        await client.query('COMMIT')
        console.log('ok')
        ran++
      } catch (e) {
        await client.query('ROLLBACK')
        console.log('FAILED')
        throw e
      }
    }

    console.log(ran ? `Applied ${ran} migration(s).` : 'Database is up to date.')
  } finally {
    if (locked) await client.query('SELECT pg_advisory_unlock(727274)').catch(() => {})
    await client.end()
  }
}

main().catch((e) => {
  const message = e instanceof Error ? e.message : String(e)
  console.error(`[migrate] failed: ${redactConfigValues(message)}`)
  process.exit(1)
})
