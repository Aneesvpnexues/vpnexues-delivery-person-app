/**
 * Genuinely read-only database inspection.
 *
 * Every statement is a SELECT. The whole inspection runs inside a READ ONLY
 * transaction. There is no DDL, no DML, no schema creation, and no writes to
 * schema_migrations. This is safe to run before deciding whether migrations
 * may proceed.
 */

export const INSPECTION_STATEMENTS = {
  begin: 'BEGIN READ ONLY',
  identity: `SELECT current_database() AS database_name, current_user AS role_name, version() AS server_version`,
  tables: `SELECT table_schema, table_name, table_type
           FROM information_schema.tables
           WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
           ORDER BY 1, 2`,
  extensions: `SELECT extname FROM pg_extension ORDER BY extname`,
  publicTypes: `SELECT typname FROM pg_type WHERE typnamespace = 'public'::regnamespace ORDER BY typname`,
  roles: `SELECT rolname FROM pg_roles WHERE rolname IN ('anon', 'authenticated', 'service_role') ORDER BY rolname`,
  migrations: `SELECT to_regclass('public.schema_migrations') IS NOT NULL AS migrations_table_exists,
                      CASE
                        WHEN to_regclass('public.schema_migrations') IS NULL THEN NULL
                        ELSE (
                          SELECT COALESCE(json_agg(row_to_json(m) ORDER BY m.filename), '[]'::json)
                          FROM (
                            SELECT filename, checksum, applied_at
                            FROM public.schema_migrations
                          ) m
                        )
                      END AS migrations`,
  commit: 'COMMIT',
  rollback: 'ROLLBACK',
} as const

export type InspectionQuery = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>

export type MigrationRow = {
  filename: string
  checksum: string
  applied_at: string
}

export type DbInspection = {
  server: Record<string, unknown> | null
  tables: Array<{ table_schema: string; table_name: string; table_type: string }>
  baseTableCount: number
  extensions: string[]
  publicTypes: string[]
  roles: string[]
  migrationsTableExists: boolean
  migrations: MigrationRow[]
}

/** Run the inspection through a supplied query function; never issues writes. */
export async function runReadOnlyInspection(query: InspectionQuery): Promise<DbInspection> {
  await query(INSPECTION_STATEMENTS.begin)
  try {
    const identity = await query(INSPECTION_STATEMENTS.identity)
    const tables = await query(INSPECTION_STATEMENTS.tables)
    const extensions = await query(INSPECTION_STATEMENTS.extensions)
    const publicTypes = await query(INSPECTION_STATEMENTS.publicTypes)
    const roles = await query(INSPECTION_STATEMENTS.roles)
    const migrations = await query(INSPECTION_STATEMENTS.migrations)

    await query(INSPECTION_STATEMENTS.commit)

    const migrationRow = migrations.rows[0] ?? {}

    return {
      server: identity.rows[0] ?? null,
      tables: tables.rows,
      baseTableCount: tables.rows.filter((t) => t.table_type === 'BASE TABLE').length,
      extensions: extensions.rows.map((r) => r.extname),
      publicTypes: publicTypes.rows.map((r) => r.typname),
      roles: roles.rows.map((r) => r.rolname),
      migrationsTableExists: Boolean(migrationRow.migrations_table_exists),
      migrations: (migrationRow.migrations ?? []) as MigrationRow[],
    }
  } catch (error) {
    await query(INSPECTION_STATEMENTS.rollback).catch(() => {})
    throw error
  }
}
