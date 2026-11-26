import { createHash } from 'node:crypto'
import bcrypt from 'bcryptjs'

/**
 * Minimal in-memory stand-in for the auth tables. Used only by the isolated
 * backend contract test via stub-loader.mjs. It never opens a database client.
 */
export const state = {
  partner: {
    id: '11111111-1111-4111-8111-111111111111',
    phone: '+919000000000',
    password_hash: '',
    status: 'active',
  },
  sessions: new Map(),
}

let sequence = 0
const hash = (token) => createHash('sha256').update(token).digest('hex')
const normalise = (sql) => sql.replace(/\s+/g, ' ').trim()

export async function __reset() {
  state.sessions.clear()
  sequence = 0
  state.partner.password_hash = await bcrypt.hash('Passw0rd!', 4)
  state.partner.status = 'active'
}

export function activeSessions() {
  return [...state.sessions.values()]
}

export const pool = null
export async function dbHealthy() {
  return true
}

export async function query(sql, params = [], _db) {
  const s = normalise(sql)

  if (s.startsWith('INSERT INTO sessions')) {
    const [partnerId, refreshHash, userAgent, ip] = params
    const id = `session-${++sequence}`
    state.sessions.set(refreshHash, {
      id,
      partner_id: partnerId,
      hash: refreshHash,
      revoked: false,
      expired: false,
      user_agent: userAgent,
      ip,
    })
    return []
  }

  if (s.startsWith('UPDATE sessions SET revoked_at = now() WHERE partner_id')) {
    for (const session of state.sessions.values()) {
      if (session.partner_id === params[0] && !session.revoked) session.revoked = true
    }
    return []
  }

  if (s.startsWith('UPDATE sessions SET revoked_at = now(), last_used_at = now() WHERE id')) {
    const session = [...state.sessions.values()].find((row) => row.id === params[0])
    if (session) session.revoked = true
    return []
  }

  if (s.startsWith('UPDATE sessions SET revoked_at = now() WHERE refresh_token_hash')) {
    const session = state.sessions.get(params[0])
    if (session) session.revoked = true
    return []
  }

  if (s.startsWith('INSERT INTO partner_settings')) return []

  throw new Error(`Unhandled test SQL: ${s}`)
}

export async function one(sql, params = [], _db) {
  const s = normalise(sql)

  if (s.includes('FROM partners WHERE phone =')) {
    return state.partner.phone === params[0] ? state.partner : undefined
  }

  if (s.includes('FROM sessions WHERE refresh_token_hash =')) {
    const session = state.sessions.get(params[0])
    if (!session) return undefined
    return {
      id: session.id,
      partner_id: session.partner_id,
      revoked: session.revoked,
      expired: session.expired,
    }
  }

  throw new Error(`Unhandled test SQL: ${s}`)
}

export async function tx(fn) {
  // No real transaction: the fake store is already isolated per test.
  return fn({ query })
}
