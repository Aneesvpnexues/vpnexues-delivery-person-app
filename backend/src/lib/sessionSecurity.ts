/**
 * Pure, dependency-free helpers for partner session security.
 * Kept separate from Fastify/pg so they can be unit-tested without a database.
 */

export const ACCESS_TOKEN_ISSUER = 'vpnexues-partner-api'
export const ACCESS_TOKEN_AUDIENCE = 'vpnexues-partner-app'

export type ClaimValidationResult = { ok: true } | { ok: false; reason: string }

/** Shape shared by partner ('access') and ops-console ('admin') tokens. */
export type SessionClaims = {
  sub?: unknown
  typ?: unknown
  role?: unknown
  jti?: unknown
  iss?: unknown
  aud?: unknown
}

/**
 * Claims used when signing a new partner access token. `iss`, `aud` and `exp`
 * are added by the JWT plugin's global sign options; `jti` is added here so
 * each access token is individually identifiable.
 */
export function buildAccessClaims(partnerId: string, jti: string) {
  return { sub: partnerId, typ: 'access' as const, jti }
}

/**
 * Validate claims after signature verification.
 *
 * Issuer/audience are enforced when present. Tokens issued before these
 * claims were introduced are still accepted, so the existing React client
 * and already-issued tokens keep working during rollout.
 */
export function validateAccessClaims(claims: SessionClaims): ClaimValidationResult {
  if (!claims || typeof claims !== 'object') return { ok: false, reason: 'Malformed token' }
  if (typeof claims.sub !== 'string' || claims.sub.length === 0) return { ok: false, reason: 'Malformed token' }
  if (claims.typ !== 'access' && claims.typ !== 'admin') return { ok: false, reason: 'Wrong token type' }
  if (claims.jti !== undefined && (typeof claims.jti !== 'string' || claims.jti.length === 0)) {
    return { ok: false, reason: 'Malformed token' }
  }
  if (claims.iss !== undefined && claims.iss !== ACCESS_TOKEN_ISSUER) {
    return { ok: false, reason: 'Wrong token issuer' }
  }
  if (claims.aud !== undefined) {
    const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud]
    if (!audiences.includes(ACCESS_TOKEN_AUDIENCE)) return { ok: false, reason: 'Wrong token audience' }
  }
  return { ok: true }
}

export type RefreshSessionSnapshot = { revoked: boolean; expired: boolean }

/**
 * Reuse detection deliberately takes precedence over expiry: a replayed,
 * revoked token must always take the "revoke every session" path.
 */
export function classifyRefreshSession(session: RefreshSessionSnapshot): 'revoked' | 'expired' | 'valid' {
  if (session.revoked) return 'revoked'
  if (session.expired) return 'expired'
  return 'valid'
}
