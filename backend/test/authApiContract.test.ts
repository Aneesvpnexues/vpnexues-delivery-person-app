import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { register } from 'node:module'
import test from 'node:test'
import Fastify from 'fastify'

import { registerErrorHandler } from '../src/lib/errors.ts'
import {
  ACCESS_TOKEN_AUDIENCE,
  ACCESS_TOKEN_ISSUER,
} from '../src/lib/sessionSecurity.ts'
import { __reset, activeSessions, state } from './helpers/inMemoryDb.js'

// Must run before the auth source modules are imported: source `.js` imports
// are redirected to the in-memory DB/SMS stubs by this loader.
register(new URL('./helpers/stub-loader.mjs', import.meta.url).href, import.meta.url)

const { authPlugin } = await import('../src/lib/auth.ts')
const { default: authRoutes } = await import('../src/modules/auth.ts')

const LOGIN = { phone: '9000000000', password: 'Passw0rd!' }
const TOKEN_KEYS = ['accessToken', 'expiresIn', 'refreshToken', 'tokenType']
const hash = (token: string) => createHash('sha256').update(token).digest('hex')

type VerifiedTokenClaims = {
  sub: string
  typ: string
  iss: string
  aud: string
  jti: string
}

const isNonEmptyString = (value: unknown): value is string =>
  typeof value === 'string' && value.length > 0

/** Narrow Fastify's generic verified payload before reading token claims. */
function isVerifiedTokenClaims(value: unknown): value is VerifiedTokenClaims {
  if (typeof value !== 'object' || value === null) return false
  const candidate: Record<string, unknown> = value as Record<string, unknown>
  return (
    isNonEmptyString(candidate.sub) &&
    isNonEmptyString(candidate.typ) &&
    isNonEmptyString(candidate.iss) &&
    isNonEmptyString(candidate.aud) &&
    isNonEmptyString(candidate.jti)
  )
}

type TokenResponse = {
  accessToken: string
  refreshToken: string
  tokenType: string
  expiresIn: string
}

function isTokenResponse(value: unknown): value is TokenResponse {
  if (typeof value !== 'object' || value === null) return false
  const candidate: Record<string, unknown> = value as Record<string, unknown>
  return (
    isNonEmptyString(candidate.accessToken) &&
    isNonEmptyString(candidate.refreshToken) &&
    isNonEmptyString(candidate.tokenType) &&
    isNonEmptyString(candidate.expiresIn)
  )
}

function parseTokenResponse(value: unknown): TokenResponse {
  if (!isTokenResponse(value)) {
    throw new Error('Auth response is missing required token fields')
  }
  return value
}

async function buildApp() {
  await __reset()
  const app = Fastify({ logger: false })
  registerErrorHandler(app)
  await app.register(authPlugin)
  await app.register(async (v1) => {
    await v1.register(authRoutes, { prefix: '/auth' })
    v1.get('/contract-check', { preHandler: app.authenticate }, async (req) => ({
      sub: req.user.sub,
    }))
  }, { prefix: '/v1' })
  await app.ready()
  return app
}

async function login(app: Awaited<ReturnType<typeof buildApp>>) {
  const res = await app.inject({ method: 'POST', url: '/v1/auth/login', payload: LOGIN })
  assert.equal(res.statusCode, 200)
  return parseTokenResponse(res.json())
}

test('login returns the exact token contract consumed by Flutter', async () => {
  const app = await buildApp()
  try {
    const body = await login(app)

    assert.deepEqual(Object.keys(body).sort(), [...TOKEN_KEYS].sort())
    assert.equal(body.tokenType, 'Bearer')
    assert.equal(body.expiresIn, '15m')
    assert.ok(String(body.refreshToken).length >= 20)

    const verified = app.jwt.verify(body.accessToken)
    if (!isVerifiedTokenClaims(verified)) {
      throw new Error('Verified access token is missing required string claims')
    }
    assert.equal(verified.sub, state.partner.id)
    assert.equal(verified.typ, 'access')
    assert.equal(verified.iss, ACCESS_TOKEN_ISSUER)
    assert.equal(verified.aud, ACCESS_TOKEN_AUDIENCE)
    assert.match(verified.jti, /^[0-9a-f-]{36}$/)

    // Only refresh-token hashes are persisted; the raw token is never stored.
    assert.equal(state.sessions.has(hash(body.refreshToken)), true)
    assert.equal(state.sessions.has(body.refreshToken), false)
  } finally {
    await app.close()
  }
})

test('refresh returns a rotated token pair and replay revokes every session', async () => {
  const app = await buildApp()
  try {
    const first = await login(app)

    const rotatedRes = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first.refreshToken },
    })
    assert.equal(rotatedRes.statusCode, 200)
    const rotated = parseTokenResponse(rotatedRes.json())
    assert.deepEqual(Object.keys(rotated).sort(), [...TOKEN_KEYS].sort())
    assert.equal(rotated.tokenType, 'Bearer')
    assert.equal(rotated.expiresIn, '15m')
    assert.notEqual(rotated.accessToken, first.accessToken)
    assert.notEqual(rotated.refreshToken, first.refreshToken)

    assert.equal(state.sessions.get(hash(first.refreshToken))?.revoked, true)
    assert.equal(state.sessions.get(hash(rotated.refreshToken))?.revoked, false)

    // A valid access token still passes the hardened preHandler (no denylist).
    const check = await app.inject({
      method: 'GET',
      url: '/v1/contract-check',
      headers: { authorization: `Bearer ${first.accessToken}` },
    })
    assert.equal(check.statusCode, 200)
    assert.equal(check.json().sub, state.partner.id)

    const replay = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: first.refreshToken },
    })
    assert.equal(replay.statusCode, 401)
    assert.equal(replay.json().error.code, 'UNAUTHENTICATED')
    assert.equal(activeSessions().every((session) => session.revoked), true)

    const rotatedAfterReplay = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: rotated.refreshToken },
    })
    assert.equal(rotatedAfterReplay.statusCode, 401)
    assert.equal(rotatedAfterReplay.json().error.code, 'UNAUTHENTICATED')
  } finally {
    await app.close()
  }
})

test('logout consumes the refresh token without needing an access token', async () => {
  const app = await buildApp()
  try {
    const tokens = await login(app)
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/logout',
      payload: { refreshToken: tokens.refreshToken },
    })

    assert.equal(res.statusCode, 200)
    assert.deepEqual(res.json(), { ok: true })
    assert.equal(state.sessions.get(hash(tokens.refreshToken))?.revoked, true)

    const refresh = await app.inject({
      method: 'POST',
      url: '/v1/auth/refresh',
      payload: { refreshToken: tokens.refreshToken },
    })
    assert.equal(refresh.statusCode, 401)
  } finally {
    await app.close()
  }
})

test('partner access token works on protected routes but an admin token does not', async () => {
  const app = await buildApp()
  try {
    const tokens = await login(app)

    const partner = await app.inject({
      method: 'GET',
      url: '/v1/contract-check',
      headers: { authorization: `Bearer ${tokens.accessToken}` },
    })
    assert.equal(partner.statusCode, 200)

    const adminToken = app.jwt.sign({ sub: 'admin-1', typ: 'admin', role: 'owner' })
    const admin = await app.inject({
      method: 'GET',
      url: '/v1/contract-check',
      headers: { authorization: `Bearer ${adminToken}` },
    })
    assert.equal(admin.statusCode, 401)
    assert.equal(admin.json().error.code, 'UNAUTHENTICATED')
  } finally {
    await app.close()
  }
})
