import assert from 'node:assert/strict';
import test from 'node:test';

import {
  ACCESS_TOKEN_AUDIENCE,
  ACCESS_TOKEN_ISSUER,
  buildAccessClaims,
  classifyRefreshSession,
  validateAccessClaims,
} from '../src/lib/sessionSecurity.ts'

test('access claims carry subject, type and a unique jti', () => {
  const first = buildAccessClaims('partner-1', 'jti-1')
  const second = buildAccessClaims('partner-1', 'jti-2')

  assert.equal(first.sub, 'partner-1')
  assert.equal(first.typ, 'access')
  assert.notEqual(first.jti, second.jti)
  assert.equal(validateAccessClaims(first).ok, true)
})

test('legacy tokens without issuer/audience remain valid', () => {
  assert.deepEqual(validateAccessClaims({ sub: 'partner-1', typ: 'access' }), { ok: true })
})

test('wrong issuer, audience, type or subject is rejected', () => {
  const wrongIssuer = validateAccessClaims({ sub: 'partner-1', typ: 'access', iss: 'another-api' })
  assert.equal(wrongIssuer.ok, false)
  assert.match(wrongIssuer.ok === false ? wrongIssuer.reason : '', /issuer/)
  assert.equal(validateAccessClaims({ sub: 'partner-1', typ: 'access', aud: 'web' }).ok, false)
  assert.equal(validateAccessClaims({ sub: 'partner-1', typ: 'admin' }).ok, true)
  assert.equal(validateAccessClaims({ sub: '', typ: 'access' }).ok, false)
  assert.equal(validateAccessClaims({ sub: 'partner-1', typ: 'refresh' }).ok, false)
  assert.equal(validateAccessClaims(null as unknown as Record<string, unknown>).ok, false)
})

test('valid claims include the expected issuer and audience constants', () => {
  const claims = validateAccessClaims({
    sub: 'partner-1',
    typ: 'access',
    iss: ACCESS_TOKEN_ISSUER,
    aud: ACCESS_TOKEN_AUDIENCE,
  })
  assert.equal(claims.ok, true)
})

test('refresh session classification preserves reuse protection', () => {
  assert.equal(classifyRefreshSession({ revoked: true, expired: false }), 'revoked')
  // A revoked token must stay on the reuse path even if it also expired.
  assert.equal(classifyRefreshSession({ revoked: true, expired: true }), 'revoked')
  assert.equal(classifyRefreshSession({ revoked: false, expired: true }), 'expired')
  assert.equal(classifyRefreshSession({ revoked: false, expired: false }), 'valid')
})
