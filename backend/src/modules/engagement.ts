import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import { one, query, tx } from '../db.js'
import { AppError, notFound, parse } from '../lib/errors.js'
import { partnerId } from '../lib/auth.js'
import { phoneSchema } from './auth.js'

/** Notifications, Help & support chat, Safety & SOS, app rating. */
export default async function engagementRoutes(app: FastifyInstance) {
  app.addHook('preHandler', app.authenticate)

  // ---------- Notifications ----------

  app.get('/notifications', async (req) => {
    const q = parse(z.object({
      category: z.enum(['all', 'order', 'payout', 'account', 'promo', 'safety']).default('all'),
      limit: z.coerce.number().int().min(1).max(100).default(50),
    }), req.query)
    const [items, unread] = await Promise.all([
      query(`SELECT id, category, title, body, action_url, read_at, created_at FROM notifications
             WHERE partner_id = $1 AND ($2::text = 'all' OR category::text = $2) ORDER BY created_at DESC LIMIT $3`,
        [partnerId(req), q.category, q.limit]),
      one(`SELECT count(*) AS n FROM notifications WHERE partner_id = $1 AND read_at IS NULL`, [partnerId(req)]),
    ])
    return { items, unreadCount: unread!.n }
  })

  app.post('/notifications/read-all', async (req) => {
    await query(`UPDATE notifications SET read_at = now() WHERE partner_id = $1 AND read_at IS NULL`, [partnerId(req)])
    return { ok: true }
  })

  app.post('/notifications/:id/read', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    await query(`UPDATE notifications SET read_at = COALESCE(read_at, now()) WHERE id = $1 AND partner_id = $2`, [id, partnerId(req)])
    return { ok: true }
  })

  // ---------- Support (Help & support → Support chat) ----------

  app.get('/support/tickets', async (req) =>
    query(`SELECT t.id, t.topic, t.status, t.order_id, t.created_at, t.updated_at,
                  (SELECT body FROM support_messages m WHERE m.ticket_id = t.id ORDER BY m.created_at DESC LIMIT 1) AS last_message
           FROM support_tickets t WHERE t.partner_id = $1 ORDER BY t.updated_at DESC LIMIT 50`, [partnerId(req)]))

  /** Messages for a ticket in the camelCase shape the Flutter app expects (`createdAt`, not `created_at`). */
  const ticketMessages = async (ticketId: string) => {
    const rows = await query(`SELECT id, sender, body, created_at FROM support_messages WHERE ticket_id = $1 ORDER BY created_at`, [ticketId])
    return rows.map((m) => ({ id: m.id, sender: m.sender, body: m.body, createdAt: m.created_at }))
  }

  app.get('/support/tickets/:id', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const t = await one(`SELECT id, topic, status, order_id, created_at, updated_at FROM support_tickets
           WHERE id = $1 AND partner_id = $2`, [id, partnerId(req)])
    if (!t) throw notFound('Ticket')
    return { ticket: t, messages: await ticketMessages(id) }
  })

  app.post('/support/tickets', async (req, reply) => {
    const b = parse(z.object({ topic: z.string().trim().min(2).max(80), message: z.string().trim().min(1).max(2000), orderId: z.uuid().optional() }), req.body)
    const t = await tx(async (db) => {
      const t = await one(`INSERT INTO support_tickets (partner_id, topic, order_id) VALUES ($1, $2, $3) RETURNING id, topic, status, created_at`,
        [partnerId(req), b.topic, b.orderId ?? null], db)
      await query(`INSERT INTO support_messages (ticket_id, sender, body) VALUES ($1, 'partner', $2)`, [t.id, b.message], db)
      return t
    })
    // TODO: route to the agent desk (e.g. Amazon Connect / Freshdesk) via SQS.
    reply.status(201)
    // Flutter expects `{ ticket, messages }`; the spread keeps the original flat fields for existing consumers.
    return { ...t, ticket: t, messages: await ticketMessages(t.id) }
  })

  app.get('/support/tickets/:id/messages', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    if (!(await one(`SELECT 1 FROM support_tickets WHERE id = $1 AND partner_id = $2`, [id, partnerId(req)]))) throw notFound('Ticket')
    return query(`SELECT id, sender, body, created_at FROM support_messages WHERE ticket_id = $1 ORDER BY created_at`, [id])
  })

  app.post('/support/tickets/:id/messages', async (req, reply) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const { message } = parse(z.object({ message: z.string().trim().min(1).max(2000) }), req.body)
    const m = await tx(async (db) => {
      const t = await one(`UPDATE support_tickets SET status = 'open' WHERE id = $1 AND partner_id = $2 AND status <> 'closed' RETURNING id`, [id, partnerId(req)], db)
      if (!t) throw notFound('Open ticket')
      return one(`INSERT INTO support_messages (ticket_id, sender, body) VALUES ($1, 'partner', $2) RETURNING id, sender, body, created_at`, [id, message], db)
    })
    reply.status(201)
    return m
  })

  // ---------- Safety & SOS ----------

  /** SOS hold-to-send / Report an incident. */
  app.post('/sos', async (req, reply) => {
    const b = parse(z.object({
      kind: z.enum(['sos', 'road_accident', 'harassment', 'medical', 'vehicle_breakdown', 'other']).default('sos'),
      lat: z.number().optional(), lng: z.number().optional(), orderId: z.uuid().optional(), details: z.string().max(1000).optional(),
    }), req.body)
    const s = await one(
      `INSERT INTO sos_incidents (partner_id, order_id, kind, lat, lng, details) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, kind, status, created_at`,
      [partnerId(req), b.orderId ?? null, b.kind, b.lat ?? null, b.lng ?? null, b.details ?? null])
    // TODO: page the safety team immediately (SNS topic → SMS/phone) and SMS the primary emergency contact.
    req.log.warn({ sosId: s.id, partner: partnerId(req), kind: b.kind }, 'SOS raised')
    reply.status(201)
    return s
  })

  app.get('/emergency-contacts', async (req) =>
    query(`SELECT id, name, relationship, phone, is_primary FROM emergency_contacts WHERE partner_id = $1 ORDER BY is_primary DESC, created_at`, [partnerId(req)]))

  app.post('/emergency-contacts', async (req, reply) => {
    const b = parse(z.object({ name: z.string().trim().min(2).max(60), relationship: z.string().trim().min(2).max(30), phone: phoneSchema, isPrimary: z.boolean().default(false) }), req.body)
    const c = await tx(async (db) => {
      const n = await one(`SELECT count(*) AS n FROM emergency_contacts WHERE partner_id = $1`, [partnerId(req)], db)
      if (n.n >= 3) throw new AppError(400, 'LIMIT_REACHED', 'You can save up to 3 emergency contacts')
      const primary = b.isPrimary || n.n === 0
      if (primary) await query(`UPDATE emergency_contacts SET is_primary = false WHERE partner_id = $1`, [partnerId(req)], db)
      return one(`INSERT INTO emergency_contacts (partner_id, name, relationship, phone, is_primary) VALUES ($1,$2,$3,$4,$5) RETURNING id, name, relationship, phone, is_primary`,
        [partnerId(req), b.name, b.relationship, b.phone, primary], db)
    })
    reply.status(201)
    return c
  })

  app.delete('/emergency-contacts/:id', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    await query(`DELETE FROM emergency_contacts WHERE id = $1 AND partner_id = $2`, [id, partnerId(req)])
    return { ok: true }
  })

  // ---------- About → Rate the partner app ----------

  app.post('/app-rating', async (req, reply) => {
    const b = parse(z.object({ stars: z.number().int().min(1).max(5), comment: z.string().max(1000).optional(), appVersion: z.string().max(20).optional() }), req.body)
    await query(`INSERT INTO app_ratings (partner_id, stars, comment, app_version) VALUES ($1, $2, $3, $4)`, [partnerId(req), b.stars, b.comment ?? null, b.appVersion ?? null])
    reply.status(201)
    return { ok: true }
  })
}
