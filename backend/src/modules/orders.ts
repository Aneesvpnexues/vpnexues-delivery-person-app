import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import { one, query, tx, type Db } from '../db.js'
import { AppError, notFound, parse } from '../lib/errors.js'
import { sameHash, sha256 } from '../lib/crypto.js'
import { partnerId } from '../lib/auth.js'
import { config } from '../config.js'

const LIST_COLS = `o.id, o.order_code, o.status, o.customer_name, o.drop_address, o.distance_km, o.eta_minutes, o.scheduled_for,
  (o.pay_base_paise + o.pay_distance_paise + o.tip_paise) AS earning_paise, o.created_at, o.delivered_at,
  h.name AS hub_name, (SELECT count(*) FROM order_crates c WHERE c.order_id = o.id) AS crate_count`

const point = z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }).partial()

/** Load an order that belongs to the caller, locked for update, or 404. */
async function myOrder(db: Db, id: string, pid: string) {
  const o = await one(`SELECT * FROM orders WHERE id = $1 AND partner_id = $2 FOR UPDATE`, [id, pid], db)
  if (!o) throw notFound('Order')
  return o
}

/** Move an order between states, enforcing the allowed transitions and logging an event. */
async function transition(db: Db, order: any, to: string, from: string[], pid: string, extra: { col?: string; lat?: number; lng?: number; note?: string } = {}) {
  if (!from.includes(order.status)) throw new AppError(409, 'BAD_ORDER_STATE', `Order is ${order.status}; cannot move to ${to}`)
  const col = extra.col ? `, ${extra.col} = now()` : ''
  await query(`UPDATE orders SET status = $2${col} WHERE id = $1`, [order.id, to], db)
  await query(`INSERT INTO order_events (order_id, status, actor, lat, lng, note) VALUES ($1, $2, $3, $4, $5, $6)`,
    [order.id, to, `partner:${pid}`, extra.lat ?? null, extra.lng ?? null, extra.note ?? null], db)
}

/** Orders tab + the whole delivery flow (accept → pickup QR → arrive → hand-over code → delivered). */
export default async function orderRoutes(app: FastifyInstance) {
  app.addHook('preHandler', app.authenticate)

  /** Orders tab: Active / Upcoming / Completed. */
  app.get('/', async (req) => {
    const q = parse(z.object({
      tab: z.enum(['active', 'upcoming', 'completed']).default('active'),
      range: z.enum(['today', 'week', 'month', 'all']).default('today'),
      limit: z.coerce.number().int().min(1).max(100).default(30),
    }), req.query)
    const where = {
      // $2 (range) only filters the completed tab, but every variant references it so Postgres can type the parameter.
      active: `$2::text IS NOT NULL AND o.status IN ('assigned','accepted','at_pickup','picked_up','arrived') AND (o.scheduled_for IS NULL OR o.scheduled_for <= now() + interval '30 minutes')`,
      upcoming: `$2::text IS NOT NULL AND o.status IN ('assigned','accepted') AND o.scheduled_for > now() + interval '30 minutes'`,
      completed: `o.status IN ('delivered','cancelled') AND ($2::text = 'all' OR COALESCE(o.delivered_at, o.cancelled_at) >= date_trunc(CASE $2 WHEN 'today' THEN 'day' ELSE $2 END, now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata')`,
    }[q.tab]
    const order = q.tab === 'completed' ? 'COALESCE(o.delivered_at, o.cancelled_at) DESC' : 'COALESCE(o.scheduled_for, o.created_at)'
    return query(`SELECT ${LIST_COLS} FROM orders o JOIN hubs h ON h.id = o.hub_id WHERE o.partner_id = $1 AND ${where} ORDER BY ${order} LIMIT $3`,
      [partnerId(req), q.range, q.limit])
  })

  /** Order details: pickup, drop, crates, timeline, pay breakdown. */
  app.get('/:id', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const o = await one(
      `SELECT o.id, o.order_code, o.status, o.customer_name, o.drop_address, o.drop_lat, o.drop_lng, o.drop_instructions, o.leave_at_door,
              o.distance_km, o.eta_minutes, o.scheduled_for, o.pay_base_paise, o.pay_distance_paise, o.tip_paise,
              -- never expose the customer's real number; the app calls through a masked line
              '+91 ••••• ' || right(o.customer_phone, 5) AS customer_phone_masked,
              json_build_object('id', h.id, 'name', h.name, 'address', h.address, 'lat', h.lat, 'lng', h.lng) AS pickup,
              COALESCE((SELECT json_agg(json_build_object('id', c.id, 'position', c.position, 'label', c.label, 'weightGrams', c.weight_grams, 'scanned', c.scanned_at IS NOT NULL,
                                                   'trialQr', CASE WHEN $3 THEN c.qr_code END) ORDER BY c.position)
                        FROM order_crates c WHERE c.order_id = o.id), '[]') AS crates,
              COALESCE((SELECT json_agg(json_build_object('status', e.status, 'at', e.created_at) ORDER BY e.created_at)
                        FROM order_events e WHERE e.order_id = o.id), '[]') AS timeline
       FROM orders o JOIN hubs h ON h.id = o.hub_id WHERE o.id = $1 AND o.partner_id = $2`,
      [id, partnerId(req), config.TRIAL_MODE],
    )
    if (!o) throw notFound('Order')
    return o
  })

  /** Accept an assigned order. */
  app.post('/:id/accept', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const pid = partnerId(req)
    await tx(async (db) => transition(db, await myOrder(db, id, pid), 'accepted', ['assigned'], pid, { col: 'accepted_at' }))
    return { status: 'accepted' }
  })

  /** Reached the hub. */
  app.post('/:id/at-pickup', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const loc = parse(point, req.body)
    const pid = partnerId(req)
    await tx(async (db) => transition(db, await myOrder(db, id, pid), 'at_pickup', ['accepted'], pid, loc))
    return { status: 'at_pickup' }
  })

  /** Scan pickup QR: record each crate's QR. Returns progress ("2/2"). */
  app.post('/:id/crates/scan', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const { qrCode, damaged } = parse(z.object({ qrCode: z.string().min(4).max(200), damaged: z.boolean().default(false) }), req.body)
    const pid = partnerId(req)
    return tx(async (db) => {
      const o = await myOrder(db, id, pid)
      if (!['accepted', 'at_pickup'].includes(o.status)) throw new AppError(409, 'BAD_ORDER_STATE', 'Crates can only be scanned before pickup')
      const crate = await one(`UPDATE order_crates SET scanned_at = COALESCE(scanned_at, now()), damaged = $3 WHERE order_id = $1 AND qr_code = $2 RETURNING position, label`, [id, qrCode, damaged], db)
      if (!crate) throw new AppError(400, 'QR_MISMATCH', 'This crate does not belong to this order')
      const p = await one(`SELECT count(*) FILTER (WHERE scanned_at IS NOT NULL) AS scanned, count(*) AS total FROM order_crates WHERE order_id = $1`, [id], db)
      return { crate, ...p, complete: p.scanned === p.total }
    })
  })

  /** Confirm pickup & start trip — all crates must be scanned and undamaged. */
  app.post('/:id/pickup', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const loc = parse(point, req.body)
    const pid = partnerId(req)
    await tx(async (db) => {
      const o = await myOrder(db, id, pid)
      const p = await one(`SELECT count(*) FILTER (WHERE scanned_at IS NULL) AS missing, count(*) FILTER (WHERE damaged) AS damaged FROM order_crates WHERE order_id = $1`, [id], db)
      if (p.missing > 0) throw new AppError(400, 'CRATES_NOT_SCANNED', `${p.missing} crate(s) still need scanning`)
      if (p.damaged > 0) throw new AppError(400, 'CRATE_DAMAGED', 'A crate is damaged — report it to the hub before picking up')
      await transition(db, o, 'picked_up', ['accepted', 'at_pickup'], pid, { col: 'picked_up_at', ...loc })
    })
    return { status: 'picked_up' }
  })

  /** "Swipe – I've arrived". */
  app.post('/:id/arrive', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const loc = parse(point, req.body)
    const pid = partnerId(req)
    await tx(async (db) => transition(db, await myOrder(db, id, pid), 'arrived', ['picked_up'], pid, { col: 'arrived_at', ...loc }))
    return { status: 'arrived' }
  })

  /** Hand over: check the customer's 4-digit code, mark delivered and credit earnings — atomically. */
  app.post('/:id/deliver', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const b = parse(z.object({ code: z.string().regex(/^\d{4}$/) }).extend(point.shape), req.body)
    const pid = partnerId(req)
    const result = await tx(async (db) => {
      const o = await myOrder(db, id, pid)
      if (o.status !== 'arrived') throw new AppError(409, 'BAD_ORDER_STATE', 'Mark the order as arrived first')
      if (o.delivery_attempts >= 5) throw new AppError(429, 'CODE_LOCKED', 'Too many wrong codes. Contact support')
      if (!sameHash(o.delivery_code_hash, sha256(`${o.id}:${b.code}`))) {
        await query(`UPDATE orders SET delivery_attempts = delivery_attempts + 1 WHERE id = $1`, [id], db)
        return { ok: false as const }
      }
      await transition(db, o, 'delivered', ['arrived'], pid, { col: 'delivered_at', lat: b.lat, lng: b.lng })
      const credits = [
        ['delivery_base', o.pay_base_paise, `Delivery · ${o.order_code}`],
        ['delivery_distance', o.pay_distance_paise, `Distance pay · ${o.distance_km} km`],
        ['tip', o.tip_paise, `Customer tip · ${o.order_code}`],
      ].filter(([, amt]) => (amt as number) > 0)
      for (const [type, amt, desc] of credits) {
        await query(`INSERT INTO wallet_ledger (partner_id, type, amount_paise, order_id, description) VALUES ($1, $2, $3, $4, $5) ON CONFLICT DO NOTHING`,
          [pid, type, amt, id, desc], db)
      }
      return { ok: true as const, earnedPaise: o.pay_base_paise + o.pay_distance_paise + o.tip_paise }
    })
    // Wrong-code counter must persist, so the 400 is raised after the transaction commits.
    if (!result.ok) throw new AppError(400, 'CODE_INVALID', 'That code is not correct. Ask the customer to check their app')
    return { status: 'delivered', earnedPaise: result.earnedPaise }
  })

  /** "How was the drop-off?" after delivery. */
  app.post('/:id/feedback', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const { dropOffEase } = parse(z.object({ dropOffEase: z.enum(['smooth', 'hard_to_find', 'long_wait']) }), req.body)
    const o = await one(`UPDATE orders SET drop_off_ease = $3 WHERE id = $1 AND partner_id = $2 AND status = 'delivered' RETURNING id`, [id, partnerId(req), dropOffEase])
    if (!o) throw notFound('Delivered order')
    return { ok: true }
  })
}
