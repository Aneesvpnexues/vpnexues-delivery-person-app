import type { FastifyInstance, FastifyRequest } from 'fastify'
import bcrypt from 'bcryptjs'
import { z } from 'zod'
import { config } from '../config.js'
import { one, query, tx, type Db } from '../db.js'
import { sendSms } from '../aws/sms.js'
import { AppError, parse } from '../lib/errors.js'
import { numericCode, opaqueToken, sameHash, sha256 } from '../lib/crypto.js'
import { partnerId, signPartnerAccessToken } from '../lib/auth.js'
import { classifyRefreshSession } from '../lib/sessionSecurity.js'

/** Indian mobile → E.164. Accepts "90000 00000", "+91 9000000000", "09000000000". */
export const phoneSchema = z
  .string()
  .transform((s) => s.replace(/[\s-]/g, '').replace(/^(\+91|91|0)(?=\d{10}$)/, ''))
  .refine((s) => /^[6-9]\d{9}$/.test(s), 'Enter a valid 10-digit Indian mobile number')
  .transform((s) => `+91${s}`)

const vehicleTypes = ['motorbike', 'scooter', 'electric_scooter', 'bicycle'] as const
const password = z.string().min(8, 'At least 8 characters').max(72)
  .refine((p) => /[A-Z]/.test(p) && /\d/.test(p) && /[^A-Za-z0-9]/.test(p), 'Needs an uppercase letter, a number and a symbol')

const DUMMY_HASH = bcrypt.hashSync('timing-equaliser', 12)

// ---------------- OTP helpers ----------------

type Purpose = 'signup' | 'login' | 'password_reset'

async function issueOtp(req: FastifyRequest, phone: string, purpose: Purpose, payload?: unknown) {
  // Simple per-phone throttle on top of the IP rate limit: max 1 code / 30 s.
  const recent = await one(`SELECT 1 FROM otp_codes WHERE phone = $1 AND purpose = $2 AND created_at > now() - interval '30 seconds'`, [phone, purpose])
  if (recent) throw new AppError(429, 'OTP_TOO_SOON', 'Please wait 30 seconds before requesting another code')

  const code = numericCode(6)
  await query(
    `INSERT INTO otp_codes (phone, purpose, code_hash, payload, expires_at) VALUES ($1, $2, $3, $4, now() + make_interval(secs => $5))`,
    [phone, purpose, sha256(`${phone}:${code}`), payload ? JSON.stringify(payload) : null, config.OTP_TTL_SECONDS],
  )
  await sendSms(req.log, phone, `${code} is your VP Nexues verification code. It expires in ${Math.round(config.OTP_TTL_SECONDS / 60)} minutes. Do not share it.`)
  return { sent: true, expiresIn: config.OTP_TTL_SECONDS, ...(config.OTP_DEV_ECHO ? { devCode: code } : {}) }
}

/**
 * Verify an OTP and, if correct, run `fn` in the same transaction.
 * A wrong code must still COMMIT its attempt counter (that's what enforces OTP_MAX_ATTEMPTS),
 * so the "wrong code" error is raised only after the transaction has committed.
 */
async function withOtp<T>(phone: string, purpose: Purpose, code: string, fn: (db: Db, payload: any) => Promise<T>): Promise<T> {
  const out = await tx(async (db) => {
    try {
      return { ok: true as const, value: await fn(db, await consumeOtp(db, phone, purpose, code)) }
    } catch (e) {
      if (e instanceof AppError && e.code === 'OTP_INVALID') return { ok: false as const, error: e }
      throw e
    }
  })
  if (!out.ok) throw out.error
  return out.value
}

/** Checks the latest unconsumed code; marks it consumed on success. Returns its payload. */
async function consumeOtp(db: Db, phone: string, purpose: Purpose, code: string) {
  const row = await one<{ id: string; code_hash: string; attempts: number; expired: boolean; payload: any }>(
    `SELECT id, code_hash, attempts, expires_at < now() AS expired, payload FROM otp_codes
     WHERE phone = $1 AND purpose = $2 AND consumed_at IS NULL ORDER BY created_at DESC LIMIT 1 FOR UPDATE`,
    [phone, purpose], db,
  )
  if (!row) throw new AppError(400, 'OTP_NOT_FOUND', 'Request a new code first')
  if (row.expired) throw new AppError(400, 'OTP_EXPIRED', 'This code has expired. Request a new one')
  if (row.attempts >= config.OTP_MAX_ATTEMPTS) throw new AppError(429, 'OTP_LOCKED', 'Too many wrong attempts. Request a new code')
  if (!sameHash(row.code_hash, sha256(`${phone}:${code}`))) {
    await query(`UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1`, [row.id], db)
    throw new AppError(400, 'OTP_INVALID', 'That code is not correct')
  }
  await query(`UPDATE otp_codes SET consumed_at = now() WHERE id = $1`, [row.id], db)
  return row.payload
}

// ---------------- Tokens ----------------

async function issueTokens(app: FastifyInstance, req: FastifyRequest, db: Db, pid: string) {
  const refreshToken = opaqueToken()
  await query(
    `INSERT INTO sessions (partner_id, refresh_token_hash, user_agent, ip, expires_at) VALUES ($1, $2, $3, $4, now() + make_interval(days => $5))`,
    [pid, sha256(refreshToken), req.headers['user-agent'] ?? null, req.ip, config.REFRESH_TOKEN_TTL_DAYS], db,
  )
  const accessToken = signPartnerAccessToken(app, pid)
  return { accessToken, refreshToken, tokenType: 'Bearer', expiresIn: config.ACCESS_TOKEN_TTL }
}

// ---------------- Routes ----------------

export default async function authRoutes(app: FastifyInstance) {
  const otpLimit = { config: { rateLimit: { max: 5, timeWindow: '10 minutes' } } }

  /** Sign up step 1 (Create account screen): validate details, text an OTP. */
  app.post('/signup/start', otpLimit, async (req) => {
    const body = parse(z.object({
      fullName: z.string().trim().min(2).max(80),
      phone: phoneSchema,
      cityId: z.number().int().positive(),
      vehicleType: z.enum(vehicleTypes),
      referralCode: z.string().trim().max(20).optional(),
      acceptedTerms: z.literal(true, { message: 'You must accept the partner terms' }),
    }), req.body)
    if (await one(`SELECT 1 FROM partners WHERE phone = $1`, [body.phone])) throw new AppError(409, 'PHONE_TAKEN', 'This number already has an account. Log in instead')
    if (!(await one(`SELECT 1 FROM cities WHERE id = $1 AND is_active`, [body.cityId]))) throw new AppError(400, 'CITY_UNAVAILABLE', 'We are not in this city yet')
    return issueOtp(req, body.phone, 'signup', body)
  })

  /** Sign up step 2 (Verify mobile screen): check OTP, create the partner, sign in. */
  app.post('/signup/verify', async (req, reply) => {
    const { phone, code } = parse(z.object({ phone: phoneSchema, code: z.string().regex(/^\d{6}$/) }), req.body)
    const out = await withOtp(phone, 'signup', code, async (db, p) => {
      const referrer = p.referralCode ? await one<{ id: string }>(`SELECT id FROM partners WHERE referral_code = $1`, [p.referralCode], db) : undefined
      const hub = await one<{ id: string }>(`SELECT id FROM hubs WHERE city_id = $1 AND is_active ORDER BY created_at LIMIT 1`, [p.cityId], db)
      const partner = await one<{ id: string; partner_code: string }>(
        `INSERT INTO partners (partner_code, full_name, phone, phone_verified_at, city_id, hub_id, vehicle_type, referral_code, referred_by_id)
         VALUES ('VPN-P-' || nextval('partner_code_seq'), $1, $2, now(), $3, $4, $5,
                 upper(substr(regexp_replace($1, '[^A-Za-z]', '', 'g'), 1, 4)) || '-' || upper(substr(md5(random()::text), 1, 6)), $6)
         RETURNING id, partner_code`,
        [p.fullName, phone, p.cityId, hub?.id ?? null, p.vehicleType, referrer?.id ?? null], db,
      )
      await query(`INSERT INTO partner_settings (partner_id) VALUES ($1)`, [partner!.id], db)
      return { partner, tokens: await issueTokens(app, req, db, partner!.id) }
    })
    reply.status(201)
    return { partnerId: out.partner!.id, partnerCode: out.partner!.partner_code, ...out.tokens, next: 'set_password' }
  })

  /** Sign up step 3 (Secure your account) — also used to change the password while signed in. */
  app.post('/password', { preHandler: app.authenticate }, async (req) => {
    const { password: pw } = parse(z.object({ password }), req.body)
    await query(`UPDATE partners SET password_hash = $2 WHERE id = $1`, [partnerId(req), await bcrypt.hash(pw, 12)])
    return { ok: true }
  })

  /** Login with phone + password (Welcome back → Password tab). */
  app.post('/login', { config: { rateLimit: { max: 10, timeWindow: '10 minutes' } } }, async (req) => {
    const { phone, password: pw } = parse(z.object({ phone: phoneSchema, password: z.string().min(1) }), req.body)
    const p = await one<{ id: string; password_hash: string | null; status: string }>(`SELECT id, password_hash, status FROM partners WHERE phone = $1`, [phone])
    // Same error for unknown phone and wrong password, and always run bcrypt to keep timing uniform.
    const ok = await bcrypt.compare(pw, p?.password_hash ?? DUMMY_HASH)
    if (!p || !ok) throw new AppError(401, 'BAD_CREDENTIALS', 'Phone number or password is incorrect')
    if (p.status === 'suspended' || p.status === 'deactivated') throw new AppError(403, 'ACCOUNT_BLOCKED', 'Your account is not active. Contact support')
    return tx((db) => issueTokens(app, req, db, p.id))
  })

  /** Login with a one-time code (Welcome back → One-time code tab). */
  app.post('/login/otp/start', otpLimit, async (req) => {
    const { phone } = parse(z.object({ phone: phoneSchema }), req.body)
    if (!(await one(`SELECT 1 FROM partners WHERE phone = $1`, [phone]))) throw new AppError(404, 'NO_ACCOUNT', 'No account with this number. Create one first')
    return issueOtp(req, phone, 'login')
  })

  app.post('/login/otp/verify', async (req) => {
    const { phone, code } = parse(z.object({ phone: phoneSchema, code: z.string().regex(/^\d{6}$/) }), req.body)
    return withOtp(phone, 'login', code, async (db) => {
      const p = await one<{ id: string }>(`SELECT id FROM partners WHERE phone = $1`, [phone], db)
      if (!p) throw new AppError(404, 'NO_ACCOUNT', 'No account with this number')
      return issueTokens(app, req, db, p.id)
    })
  })

  /** Forgot password: OTP, then set a new password. Revokes all sessions. */
  app.post('/password/reset/start', otpLimit, async (req) => {
    const { phone } = parse(z.object({ phone: phoneSchema }), req.body)
    // Don't reveal whether the number is registered.
    if (await one(`SELECT 1 FROM partners WHERE phone = $1`, [phone])) return issueOtp(req, phone, 'password_reset')
    return { sent: true, expiresIn: config.OTP_TTL_SECONDS }
  })

  app.post('/password/reset/verify', async (req) => {
    const body = parse(z.object({ phone: phoneSchema, code: z.string().regex(/^\d{6}$/), password }), req.body)
    const hash = await bcrypt.hash(body.password, 12)
    await withOtp(body.phone, 'password_reset', body.code, async (db) => {
      const p = await one<{ id: string }>(`UPDATE partners SET password_hash = $2 WHERE phone = $1 RETURNING id`, [body.phone, hash], db)
      if (p) await query(`UPDATE sessions SET revoked_at = now() WHERE partner_id = $1 AND revoked_at IS NULL`, [p.id], db)
    })
    return { ok: true }
  })

  /** Rotate the refresh token. Reusing an old token revokes every session (theft signal). */
  const refreshLimit = { config: { rateLimit: { max: 10, timeWindow: '1 minute' } } }
  app.post('/refresh', refreshLimit, async (req) => {
    const { refreshToken } = parse(z.object({ refreshToken: z.string().min(20) }), req.body)
    const out = await tx(async (db) => {
      const s = await one<{ id: string; partner_id: string; revoked: boolean; expired: boolean }>(
        `SELECT id, partner_id, revoked_at IS NOT NULL AS revoked, expires_at < now() AS expired FROM sessions WHERE refresh_token_hash = $1 FOR UPDATE`,
        [sha256(refreshToken)], db,
      )
      if (!s) throw new AppError(401, 'UNAUTHENTICATED', 'Sign in again to continue')
      // The row lock above serialises concurrent rotations. Reuse detection stays strict:
      // a revoked token is never accepted, even if it was replayed only milliseconds later.
      const state = classifyRefreshSession({ revoked: s.revoked, expired: s.expired })
      if (state === 'revoked') {
        req.log.warn(
          { event: 'refresh_token_reuse', partnerId: s.partner_id, requestId: req.id },
          'Refresh token reuse detected; revoking all sessions for this partner',
        )
        // Revoke every session, and let this COMMIT — throwing here would roll the revocation back.
        await query(`UPDATE sessions SET revoked_at = now() WHERE partner_id = $1 AND revoked_at IS NULL`, [s.partner_id], db)
        return null
      }
      if (state === 'expired') throw new AppError(401, 'UNAUTHENTICATED', 'Session expired. Sign in again')
      await query(`UPDATE sessions SET revoked_at = now(), last_used_at = now() WHERE id = $1`, [s.id], db)
      return issueTokens(app, req, db, s.partner_id)
    })
    if (!out) throw new AppError(401, 'UNAUTHENTICATED', 'Sign in again to continue')
    return out
  })

  /** Log out (Profile → Log out): revoke this device's refresh token. */
  app.post('/logout', async (req) => {
    const { refreshToken } = parse(z.object({ refreshToken: z.string().min(20) }), req.body)
    await query(`UPDATE sessions SET revoked_at = now() WHERE refresh_token_hash = $1 AND revoked_at IS NULL`, [sha256(refreshToken)])
    return { ok: true }
  })
}
