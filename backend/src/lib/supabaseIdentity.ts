/**
 * Fail-closed Supabase target identity checks.
 *
 * We deliberately do NOT use current_database() as identity: both Supabase
 * projects can report the same database name ("postgres"). The approved
 * project reference is taken from the connection URL and compared with an
 * explicitly approved 20-character reference supplied by the project owner
 * through APPROVED_SUPABASE_PROJECT_REF.
 */

const SUPABASE_REF_PATTERN = /^[a-z0-9]{20}$/
const POOLER_USER_PATTERN = /^postgres\.([a-z0-9]{20})$/
const DIRECT_HOST_PATTERN = /^db\.([a-z0-9]{20})\.supabase\.co$/
const LOOPBACK_HOSTS = new Set(['localhost', '127.0.0.1', '::1'])

export type ProjectRefSource = 'session_pooler_user' | 'direct_host'

export type ApprovedTarget = {
  projectRef: string
  source: ProjectRefSource
}

export type MigrationTargetCheck =
  | ({ kind: 'isolated' } & ApprovedTarget)
  | { kind: 'local' }

export class TargetError extends Error {
  constructor(public readonly code: string, message: string) {
    super(message)
    this.name = 'TargetError'
  }
}

function parseUrl(databaseUrl: string): URL {
  try {
    return new URL(databaseUrl)
  } catch {
    throw new TargetError('INVALID_DATABASE_URL', 'DATABASE_URL is not a valid URL')
  }
}

/** Derive a Supabase project reference without ever returning the URL or password. */
export function deriveSupabaseRefFromUrl(databaseUrl: string): ApprovedTarget {
  const url = parseUrl(databaseUrl)
  const host = url.hostname.toLowerCase().replace(/^\[|\]$/g, '')
  const user = decodeURIComponent(url.username).toLowerCase()

  const fromUser = POOLER_USER_PATTERN.exec(user)?.[1]
  const fromHost = DIRECT_HOST_PATTERN.exec(host)?.[1]

  if (fromUser && fromHost && fromUser !== fromHost) {
    throw new TargetError(
      'CONFLICTING_SUPABASE_REF',
      'DATABASE_URL contains conflicting Supabase project references',
    )
  }

  if (fromUser) return { projectRef: fromUser, source: 'session_pooler_user' }
  if (fromHost) return { projectRef: fromHost, source: 'direct_host' }

  throw new TargetError(
    'SUPABASE_REF_NOT_DERIVABLE',
    'Cannot derive a Supabase project reference. Use the Session pooler URI (postgres.<ref> user) or the direct db.<ref>.supabase.co host.',
  )
}

/**
 * Refuse to continue unless:
 *  1. migration target is explicitly 'isolated', and
 *  2. an owner-approved project reference is configured, and
 *  3. the reference is not the known shared Buyer/Seller project, and
 *  4. the reference derived from DATABASE_URL matches it exactly.
 */
export function assertApprovedSupabaseTarget(
  databaseUrl: string,
  env: NodeJS.ProcessEnv = process.env,
): ApprovedTarget {
  const migrationTarget = (env.MIGRATION_TARGET ?? '').trim().toLowerCase()
  if (migrationTarget !== 'isolated') {
    throw new TargetError(
      'MIGRATION_TARGET_NOT_ISOLATED',
      'MIGRATION_TARGET must be exactly "isolated" for Delivery App development migrations',
    )
  }

  const approvedRef = (env.APPROVED_SUPABASE_PROJECT_REF ?? '').trim().toLowerCase()
  if (!SUPABASE_REF_PATTERN.test(approvedRef)) {
    throw new TargetError(
      'APPROVED_REF_INVALID',
      'APPROVED_SUPABASE_PROJECT_REF must be the 20-character Supabase project reference approved by the project owner',
    )
  }

  const forbiddenRef = (env.FORBIDDEN_SHARED_SUPABASE_PROJECT_REF ?? '').trim().toLowerCase()
  if (forbiddenRef && forbiddenRef === approvedRef) {
    throw new TargetError(
      'SHARED_PROJECT_REF_FORBIDDEN',
      'The configured project reference is explicitly forbidden for Delivery App migrations',
    )
  }

  const derived = deriveSupabaseRefFromUrl(databaseUrl)
  if (derived.projectRef !== approvedRef) {
    throw new TargetError(
      'SUPABASE_REF_MISMATCH',
      'DATABASE_URL project reference does not match the approved Supabase project',
    )
  }

  return derived
}

/**
 * Guard used by the migration runner.
 *
 * - `isolated`: only the owner-approved Supabase project reference may proceed.
 * - `local`: only an explicit loopback Postgres URL may proceed.
 *
 * Any other or missing MIGRATION_TARGET fails closed before a connection is opened.
 */
export function assertAllowedMigrationTarget(
  databaseUrl: string,
  env: NodeJS.ProcessEnv = process.env,
): MigrationTargetCheck {
  const migrationTarget = (env.MIGRATION_TARGET ?? '').trim().toLowerCase()

  if (migrationTarget === 'isolated') {
    return { kind: 'isolated', ...assertApprovedSupabaseTarget(databaseUrl, env) }
  }

  if (migrationTarget === 'local') {
    const url = parseUrl(databaseUrl)
    const host = url.hostname.toLowerCase().replace(/^\[|\]$/g, '')
    if (!LOOPBACK_HOSTS.has(host)) {
      throw new TargetError(
        'LOCAL_TARGET_REQUIRED',
        'MIGRATION_TARGET=local is only allowed for a loopback Postgres URL',
      )
    }
    return { kind: 'local' }
  }

  throw new TargetError(
    'MIGRATION_TARGET_INVALID',
    'MIGRATION_TARGET must be exactly "isolated" or "local"; refusing to migrate an unknown target',
  )
}
