import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import { one, query, tx } from '../db.js'
import { AppError, notFound, parse } from '../lib/errors.js'
import { partnerId } from '../lib/auth.js'

const languages = ['en', 'ta', 'hi', 'ml', 'te', 'kn'] as const

/** Profile, online status, settings, zone — everything under /v1/me. */
export default async function partnerRoutes(app: FastifyInstance) {
  app.addHook('preHandler', app.authenticate)

  /** Profile screen header + Personal info. */
  app.get('/', async (req) => {
    const p = await one(
      `SELECT p.id, p.partner_code, p.full_name, p.phone, p.email, p.status, p.kyc_status, p.is_online, p.language,
              p.date_of_birth, p.blood_group, p.address, p.rating, p.referral_code, p.vehicle_type, p.delivery_radius_km,
              p.created_at AS partner_since,
              json_build_object('id', c.id, 'name', c.name) AS city,
              CASE WHEN h.id IS NULL THEN NULL ELSE json_build_object('id', h.id, 'name', h.name) END AS hub,
              (SELECT count(*) FROM orders o WHERE o.partner_id = p.id AND o.status = 'delivered') AS deliveries
       FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id
       WHERE p.id = $1`,
      [partnerId(req)],
    )
    if (!p) throw notFound('Partner')
    return p
  })

  /** Personal info → Save changes. Phone changes go through OTP (not here). */
  app.patch('/', async (req) => {
    const b = parse(z.object({
      email: z.email().nullable().optional(),
      dateOfBirth: z.iso.date().nullable().optional(),
      bloodGroup: z.enum(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']).nullable().optional(),
      address: z.string().trim().max(300).nullable().optional(),
      language: z.enum(languages).optional(),
    }), req.body)
    const map: Record<string, string> = { email: 'email', dateOfBirth: 'date_of_birth', bloodGroup: 'blood_group', address: 'address', language: 'language' }
    const keys = Object.keys(b).filter((k) => (b as any)[k] !== undefined)
    if (!keys.length) return { ok: true }
    const sets = keys.map((k, i) => `${map[k]} = $${i + 2}`).join(', ')
    await query(`UPDATE partners SET ${sets} WHERE id = $1`, [partnerId(req), ...keys.map((k) => (b as any)[k])])
    return { ok: true }
  })

  /** Home → Online / Offline toggle. Only fully-verified, active partners can go online. */
  app.put('/online', async (req) => {
    const { online } = parse(z.object({ online: z.boolean() }), req.body)
    const p = await one<{ status: string; kyc_status: string }>(`SELECT status, kyc_status FROM partners WHERE id = $1`, [partnerId(req)])
    if (!p) throw notFound('Partner')
    if (online && p.status !== 'active') throw new AppError(403, 'NOT_ACTIVE', 'Finish verification before going online')
    await query(`UPDATE partners SET is_online = $2, last_online_at = CASE WHEN $2 THEN now() ELSE last_online_at END WHERE id = $1`, [partnerId(req), online])
    return { online }
  })

  /** Settings screen. */
  app.get('/settings', async (req) => one(`SELECT * FROM partner_settings WHERE partner_id = $1`, [partnerId(req)]))

  app.patch('/settings', async (req) => {
    const b = parse(z.object({
      autoAcceptNearby: z.boolean(), navigationApp: z.enum(['google_maps', 'in_app']), newOrderSound: z.boolean(),
      payoutAlerts: z.boolean(), offersCampaigns: z.boolean(), darkModeAtNight: z.boolean(), dataSaver: z.boolean(),
      voiceNavigation: z.boolean(), fingerprintUnlock: z.boolean(),
    }).partial(), req.body)
    const snake = (k: string) => k.replace(/[A-Z]/g, (c) => '_' + c.toLowerCase())
    const keys = Object.keys(b)
    if (keys.length) {
      await query(`UPDATE partner_settings SET ${keys.map((k, i) => `${snake(k)} = $${i + 2}`).join(', ')} WHERE partner_id = $1`,
        [partnerId(req), ...keys.map((k) => (b as any)[k])])
    }
    return one(`SELECT * FROM partner_settings WHERE partner_id = $1`, [partnerId(req)])
  })

  /** My zone screen: hub, radius options, areas covered. */
  app.get('/zone', async (req) => {
    const z1 = await one(
      `SELECT p.delivery_radius_km, h.id AS hub_id, h.name AS hub_name, h.lat, h.lng, h.allowed_radii_km, h.recommended_radius_km, h.areas_by_radius, c.name AS city
       FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id WHERE p.id = $1`,
      [partnerId(req)],
    )
    if (!z1) throw notFound('Partner')
    return z1
  })

  /** My zone → Save radius. */
  app.put('/zone/radius', async (req) => {
    const { radiusKm } = parse(z.object({ radiusKm: z.number().int() }), req.body)
    const ok = await one(
      `UPDATE partners p SET delivery_radius_km = $2 FROM hubs h
       WHERE p.id = $1 AND h.id = p.hub_id AND $2 = ANY(h.allowed_radii_km) RETURNING p.delivery_radius_km`,
      [partnerId(req), radiusKm],
    )
    if (!ok) throw new AppError(400, 'RADIUS_NOT_ALLOWED', 'This radius is not available for your hub')
    return { radiusKm }
  })

  /** Change city or hub → Continue to support. Creates a request that ops/support approves. */
  app.post('/zone/change-request', async (req, reply) => {
    const b = parse(z.object({ cityId: z.number().int().positive(), hubId: z.uuid().optional() }), req.body)
    const r = await tx(async (db) => {
      await query(`UPDATE hub_change_requests SET status = 'cancelled', resolved_at = now() WHERE partner_id = $1 AND status = 'pending'`, [partnerId(req)], db)
      return one(`INSERT INTO hub_change_requests (partner_id, to_city_id, to_hub_id) VALUES ($1, $2, $3) RETURNING id, status, created_at`,
        [partnerId(req), b.cityId, b.hubId ?? null], db)
    })
    reply.status(201)
    return r
  })

  /** Register a push token (FCM/APNs). */
  app.post('/devices', async (req) => {
    const b = parse(z.object({ platform: z.enum(['android', 'ios', 'web']), token: z.string().min(10) }), req.body)
    await query(
      `INSERT INTO device_tokens (partner_id, platform, token) VALUES ($1, $2, $3)
       ON CONFLICT (token) DO UPDATE SET partner_id = EXCLUDED.partner_id, platform = EXCLUDED.platform`,
      [partnerId(req), b.platform, b.token],
    )
    return { ok: true }
  })
}

/** Public reference data: GET /v1/cities, GET /v1/cities/:id/hubs (sign-up city picker, change city). */
export async function geoRoutes(app: FastifyInstance) {
  app.get('/cities', async () => query(`SELECT id, name, state FROM cities WHERE is_active ORDER BY name`))
  app.get('/cities/:id/hubs', async (req) => {
    const { id } = parse(z.object({ id: z.coerce.number().int() }), req.params)
    return query(`SELECT id, name, address, lat, lng, allowed_radii_km FROM hubs WHERE city_id = $1 AND is_active ORDER BY name`, [id])
  })
}
