/**
 * Read-only Supabase target inspection.
 *
 *   npm run db:inspect
 *
 * Requires DATABASE_URL plus APPROVED_SUPABASE_PROJECT_REF and
 * MIGRATION_TARGET=isolated. Prints JSON only; never prints credentials.
 */
import pg from 'pg'
import { dbSslOptions } from '../src/lib/dbSsl.js'
import { runReadOnlyInspection } from '../src/lib/dbInspection.js'
import { assertApprovedSupabaseTarget } from '../src/lib/supabaseIdentity.js'
import { redactConfigValues } from '../src/lib/redact.js'

async function main() {
  const databaseUrl = process.env.DATABASE_URL
  if (!databaseUrl) throw new Error('DATABASE_URL is not set')

  // Fail closed before opening a connection.
  const target = assertApprovedSupabaseTarget(databaseUrl, process.env)

  const client = new pg.Client({ connectionString: databaseUrl, ssl: dbSslOptions() })
  await client.connect()
  try {
    const inspection = await runReadOnlyInspection((sql, params) => client.query(sql, params))
    console.log(JSON.stringify({
      ok: true,
      approvedProjectRef: target.projectRef,
      projectRefSource: target.source,
      migrationTarget: 'isolated',
      ...inspection,
    }, null, 2))
  } finally {
    await client.end()
  }
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error)
  console.error(`[db:inspect] failed: ${redactConfigValues(message)}`)
  process.exitCode = 1
})
