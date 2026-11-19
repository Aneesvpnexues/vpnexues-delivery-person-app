import type { FastifyInstance } from 'fastify'
import { randomBytes, randomUUID } from 'node:crypto'
import { config } from '../config.js'
import { one, query, tx } from '../db.js'
import { AppError } from '../lib/errors.js'
import { sha256 } from '../lib/crypto.js'
import { partnerId } from '../lib/auth.js'

/** Hand-over code used by every demo order (shown in the app as "Demo delivery code"). */
export const DEMO_DELIVERY_CODE = '7391'

const DEMO_CUSTOMERS = [
  { name: 'Priya Sharma', phone: '+919876543210', address: '24, 2nd Avenue, Anna Nagar East, Chennai 600102', lat: 13.0905, lng: 80.2152, km: 3.2, eta: 18, base: 6000, dist: 2500, tip: 0, note: 'Ring the bell twice. Leave with security if not home.' },
  { name: 'Rahul Menon', phone: '+919845012345', address: '11, 6th Street, Anna Nagar West, Chennai 600040', lat: 13.0869, lng: 80.2016, km: 4.1, eta: 22, base: 5000, dist: 2000, tip: 1000, note: 'Call on arrival.' },
  { name: 'Meena R.', phone: '+919790011223', address: '7, Shanthi Colony, Anna Nagar, Chennai 600040', lat: 13.0838, lng: 80.2129, km: 2.4, eta: 12, base: 5000, dist: 1500, tip: 0, note: '' },
]

/**
 * Trial-only helpers so the app can be exercised end to end before the ops console exists.
 * Registered only when TRIAL_MODE=true; in production these routes do not exist.
 */
export default async function trialRoutes(app: FastifyInstance) {
  if (!config.TRIAL_MODE && config.NODE_ENV === 'production') return
  app.addHook('preHandler', app.authenticate)

  /**
   * Activate the signed-in partner (as if ops approved KYC), verify their payout methods,
   * and assign a fresh demo order with two crates. Max 3 open demo orders per partner.
   */
  app.post('/demo-order', async (req, reply) => {
    const pid = partnerId(req)
    const out = await tx(async (db) => {
      const p = await one<{ hub_id: string | null; city_id: number }>(`SELECT hub_id, city_id FROM partners WHERE id = $1 FOR UPDATE`, [pid], db)
      if (!p) throw new AppError(404, 'NOT_FOUND', 'Partner not found')
      const hub = p.hub_id ?? (await one<{ id: string }>(`SELECT id FROM hubs WHERE is_active ORDER BY created_at LIMIT 1`, [], db))?.id
      if (!hub) throw new AppError(400, 'NO_HUB', 'No delivery hub is set up yet')

      await query(`UPDATE partners SET status = 'active', kyc_status = 'verified', hub_id = $2 WHERE id = $1`, [pid, hub], db)
      await query(`UPDATE payout_methods SET verification = 'verified', verified_name = COALESCE(account_holder_name, verified_name) WHERE partner_id = $1 AND deleted_at IS NULL`, [pid], db)

      const open = await one<{ n: number }>(`SELECT count(*)::int AS n FROM orders WHERE partner_id = $1 AND status NOT IN ('delivered', 'cancelled')`, [pid], db)
      if (open!.n >= 3) throw new AppError(409, 'TOO_MANY_OPEN', 'Finish your open demo orders first')

      const c = DEMO_CUSTOMERS[open!.n % DEMO_CUSTOMERS.length]
      const id = randomUUID()
      const order = await one<{ id: string; order_code: string }>(
        `INSERT INTO orders (id, order_code, hub_id, partner_id, status, customer_name, customer_phone, drop_address, drop_lat, drop_lng,
           drop_instructions, delivery_code_hash, distance_km, eta_minutes, pay_base_paise, pay_distance_paise, tip_paise, assigned_at)
         VALUES ($1, 'VPN-' || nextval('order_number_seq'), $2, $3, 'assigned', $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, now())
         RETURNING id, order_code`,
        [id, hub, pid, c.name, c.phone, c.address, c.lat, c.lng, c.note || null, sha256(`${id}:${DEMO_DELIVERY_CODE}`), c.km, c.eta, c.base, c.dist, c.tip], db,
      )
      const tag = randomBytes(4).toString('hex').toUpperCase()
      await query(
        `INSERT INTO order_crates (order_id, position, label, weight_grams, qr_code) VALUES ($1, 1, 'Vegetables', 4000, $2), ($1, 2, 'Fruits & greens', 2500, $3)`,
        [id, `VPN-CRATE-${tag}-1`, `VPN-CRATE-${tag}-2`], db,
      )
      await query(`INSERT INTO order_events (order_id, status, actor, note) VALUES ($1, 'assigned', 'system', 'Demo order (trial)')`, [id], db)
      await query(
        `INSERT INTO notifications (partner_id, category, title, body, action_url) VALUES ($1, 'order', $2, $3, $4)`,
        [pid, `New order assigned · #${order!.order_code}`, `${c.name} · ${c.km} km · ₹${(c.base + c.dist + c.tip) / 100}`, `/orders/${id}`], db,
      )
      return order!
    })
    reply.status(201)
    return { ...out, deliveryCode: DEMO_DELIVERY_CODE }
  })
}
