import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

import {
  INSPECTION_STATEMENTS,
  runReadOnlyInspection,
} from '../src/lib/dbInspection.ts'
import {
  assertAllowedMigrationTarget,
  assertApprovedSupabaseTarget,
  deriveSupabaseRefFromUrl,
  TargetError,
} from '../src/lib/supabaseIdentity.ts'
import { redactConfigValues } from '../src/lib/redact.ts'

const APPROVED_REF = 'abcdefghijklmnopqrst'
const OTHER_REF = 'zyxwvutsrqponmlkjihg'
const POOLER_URL = `postgresql://postgres.${APPROVED_REF}:pw@aws-0-ap-south-1.pooler.supabase.com:6543/postgres`
const DIRECT_URL = `postgresql://postgres:pw@db.${OTHER_REF}.supabase.co:5432/postgres`
const LOCAL_URL = 'postgresql://vpnexues:vpnexues@localhost:5432/vpnexues'

function expectTargetError(fn: () => unknown, code: string) {
  assert.throws(fn, (error) => error instanceof TargetError && error.code === code)
}

test('database inspection statements are genuinely read-only', () => {
  const queryStatements = Object.entries(INSPECTION_STATEMENTS)
    .filter(([key]) => !['begin', 'commit', 'rollback'].includes(key))
    .map(([, sql]) => sql)

  assert.equal(INSPECTION_STATEMENTS.begin, 'BEGIN READ ONLY')
  assert.ok(queryStatements.length > 0)

  for (const sql of queryStatements) {
    assert.match(sql.trim(), /^SELECT\b/i)
    assert.doesNotMatch(
      sql,
      /\b(INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE|GRANT|REVOKE|COPY|CALL|DO)\b/i,
    )
  }
})

test('runReadOnlyInspection uses a read-only transaction and reports base-table count', async () => {
  const calls: string[] = []
  const result = await runReadOnlyInspection(async (sql) => {
    calls.push(sql)
    if (sql === INSPECTION_STATEMENTS.identity) {
      return { rows: [{ database_name: 'postgres' }] }
    }
    if (sql === INSPECTION_STATEMENTS.tables) {
      return {
        rows: [
          { table_schema: 'public', table_name: 'partners', table_type: 'BASE TABLE' },
          { table_schema: 'public', table_name: 'some_view', table_type: 'VIEW' },
        ],
      }
    }
    if (sql === INSPECTION_STATEMENTS.migrations) {
      return { rows: [{ migrations_table_exists: false, migrations: null }] }
    }
    return { rows: [] }
  })

  assert.equal(calls[0], 'BEGIN READ ONLY')
  assert.equal(calls.at(-1), 'COMMIT')
  assert.equal(result.baseTableCount, 1)
  assert.equal(result.migrationsTableExists, false)
  assert.deepEqual(result.migrations, [])
})

test('runReadOnlyInspection rolls back when inspection fails', async () => {
  const calls: string[] = []
  await assert.rejects(
    () =>
      runReadOnlyInspection(async (sql) => {
        calls.push(sql)
        if (sql === INSPECTION_STATEMENTS.tables) throw new Error('inspection failed')
        return { rows: [] }
      }),
    /inspection failed/,
  )
  assert.equal(calls.at(-1), 'ROLLBACK')
})

test('Supabase project reference is derived from pooler and direct URLs only', () => {
  const fromPooler = deriveSupabaseRefFromUrl(POOLER_URL)
  assert.deepEqual(fromPooler, {
    projectRef: APPROVED_REF,
    source: 'session_pooler_user',
  })

  const fromDirect = deriveSupabaseRefFromUrl(DIRECT_URL)
  assert.deepEqual(fromDirect, {
    projectRef: OTHER_REF,
    source: 'direct_host',
  })

  expectTargetError(
    () => deriveSupabaseRefFromUrl(`postgresql://postgres.${APPROVED_REF}:pw@db.${OTHER_REF}.supabase.co:5432/postgres`),
    'CONFLICTING_SUPABASE_REF',
  )
  expectTargetError(
    () => deriveSupabaseRefFromUrl(LOCAL_URL),
    'SUPABASE_REF_NOT_DERIVABLE',
  )
  expectTargetError(() => deriveSupabaseRefFromUrl('not-a-url'), 'INVALID_DATABASE_URL')
})

test('approved Supabase target fails closed without explicit owner approval', () => {
  expectTargetError(
    () => assertApprovedSupabaseTarget(POOLER_URL, {}),
    'MIGRATION_TARGET_NOT_ISOLATED',
  )
  expectTargetError(
    () => assertApprovedSupabaseTarget(POOLER_URL, { MIGRATION_TARGET: 'shared' }),
    'MIGRATION_TARGET_NOT_ISOLATED',
  )
  expectTargetError(
    () => assertApprovedSupabaseTarget(POOLER_URL, { MIGRATION_TARGET: 'isolated' }),
    'APPROVED_REF_INVALID',
  )
  expectTargetError(
    () =>
      assertApprovedSupabaseTarget(DIRECT_URL, {
        MIGRATION_TARGET: 'isolated',
        APPROVED_SUPABASE_PROJECT_REF: APPROVED_REF,
      }),
    'SUPABASE_REF_MISMATCH',
  )
  expectTargetError(
    () =>
      assertApprovedSupabaseTarget(POOLER_URL, {
        MIGRATION_TARGET: 'isolated',
        APPROVED_SUPABASE_PROJECT_REF: APPROVED_REF,
        FORBIDDEN_SHARED_SUPABASE_PROJECT_REF: APPROVED_REF,
      }),
    'SHARED_PROJECT_REF_FORBIDDEN',
  )

  const ok = assertApprovedSupabaseTarget(POOLER_URL, {
    MIGRATION_TARGET: 'isolated',
    APPROVED_SUPABASE_PROJECT_REF: APPROVED_REF,
  })
  assert.equal(ok.projectRef, APPROVED_REF)
})

test('migration target allows only approved isolated or local loopback databases', () => {
  const isolated = assertAllowedMigrationTarget(POOLER_URL, {
    MIGRATION_TARGET: 'isolated',
    APPROVED_SUPABASE_PROJECT_REF: APPROVED_REF,
  })
  assert.equal(isolated.kind, 'isolated')

  const local = assertAllowedMigrationTarget(LOCAL_URL, { MIGRATION_TARGET: 'local' })
  assert.equal(local.kind, 'local')

  expectTargetError(() => assertAllowedMigrationTarget(POOLER_URL, {}), 'MIGRATION_TARGET_INVALID')
  expectTargetError(
    () => assertAllowedMigrationTarget(POOLER_URL, { MIGRATION_TARGET: 'local' }),
    'LOCAL_TARGET_REQUIRED',
  )
})

test('error logging redacts database URLs and secret assignments', () => {
  const redacted = redactConfigValues(`failed to connect with ${POOLER_URL} password=hunter2`)
  assert.doesNotMatch(redacted, /hunter2/)
  assert.doesNotMatch(redacted, new RegExp(APPROVED_REF))
  assert.match(redacted, /<redacted>/)
})

test('migration runner checks target before connecting and keeps status read-only', async () => {
  const here = path.dirname(fileURLToPath(import.meta.url))
  const source = await readFile(path.resolve(here, '../scripts/migrate.ts'), 'utf8')

  const guardIndex = source.indexOf('assertAllowedMigrationTarget(url, process.env)')
  const connectIndex = source.indexOf('await client.connect()')
  assert.ok(guardIndex > -1, 'migration target guard is missing')
  assert.ok(connectIndex > -1, 'database connect call is missing')
  assert.ok(guardIndex < connectIndex, 'target guard must run before connecting')

  const statusBranchIndex = source.indexOf('if (statusOnly)')
  const createTableIndex = source.indexOf('CREATE TABLE IF NOT EXISTS public.schema_migrations')
  assert.ok(statusBranchIndex > -1, 'status branch is missing')
  assert.ok(createTableIndex > -1, 'schema_migrations creation is missing')
  assert.ok(statusBranchIndex < createTableIndex, 'status must return before any DDL')
})

test('backend .gitignore excludes local env and credential files', async () => {
  const here = path.dirname(fileURLToPath(import.meta.url))
  const gitignore = await readFile(path.resolve(here, '../.gitignore'), 'utf8')
  for (const line of ['.env', '.env.*', '!.env.example', '*.pem', '*.key', '*service-account*.json']) {
    assert.ok(gitignore.includes(line), `missing .gitignore entry: ${line}`)
  }
})
