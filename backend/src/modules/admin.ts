import type { FastifyInstance, FastifyRequest } from 'fastify'
import bcrypt from 'bcryptjs'
import { randomBytes, randomUUID } from 'node:crypto'
import { z } from 'zod'
import { one, query, tx, type Db } from '../db.js'
import { AppError, notFound, parse } from '../lib/errors.js'
import { numericCode, sha256 } from '../lib/crypto.js'
import { requireRole } from '../lib/auth.js'
import { presignDownload } from '../aws/s3.js'
import { phoneSchema } from './auth.js'
import { REQUIRED_DOCS } from './documents.js'

/**
 * Ops console API — /v1/admin. Staff sign in with email + password and receive an 8-hour JWT (typ 'admin').
 * Every change is written to admin_audit_log, and partner-facing changes also create an in-app notification.
 */

const DUMMY_HASH = bcrypt.hashSync('timing-equaliser', 12)
const IST_TODAY = `(date_trunc('day', now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata')`
const OPEN = `('assigned','accepted','at_pickup','picked_up','arrived')`

const staffPassword = z.string().min(10, 'At least 10 characters').max(72)
  .refine((p) => /[A-Z]/.test(p) && /[a-z]/.test(p) && /\d/.test(p), 'Needs upper- and lower-case letters and a number')
const idParam = z.object({ id: z.uuid() })
const paging = { page: z.coerce.number().int().min(1).default(1), pageSize: z.coerce.number().int().min(1).max(100).default(20) }
const blank = (s?: string) => (s && s.trim() ? s.trim() : null)

type Page = { page: number; pageSize: number }
const page = <T extends { total?: number }>(rows: T[], p: Page) => ({
  items: rows.map(({ total, ...r }) => r),
  total: rows[0]?.total ?? 0,
  page: p.page,
  pageSize: p.pageSize,
})

async function audit(db: Db, req: FastifyRequest, action: string, entity: string, entityId: string, details: Record<string, unknown> = {}) {
  await query(`INSERT INTO admin_audit_log (admin_id, action, entity, entity_id, details) VALUES ($1, $2, $3, $4, $5)`,
    [req.admin!.id, action, entity, entityId, JSON.stringify(details)], db)
}

async function notify(db: Db, partnerId: string, category: string, title: string, body: string, actionUrl: string | null = null) {
  await query(`INSERT INTO notifications (partner_id, category, title, body, action_url) VALUES ($1, $2, $3, $4, $5)`,
    [partnerId, category, title, body, actionUrl], db)
}

const actor = (req: FastifyRequest) => `ops:${req.admin!.email}`

export default async function adminRoutes(app: FastifyInstance) {
  // ---------------- Sign in (no token yet) ----------------
  app.post('/auth/login', { config: { rateLimit: { max: 10, timeWindow: '10 minutes' } } }, async (req) => {
    const b = parse(z.object({ email: z.email(), password: z.string().min(1).max(72) }), req.body)
    const a = await one(`SELECT id, email, full_name, role, password_hash, is_active FROM admin_users WHERE email = $1`, [b.email])
    // Compare against a dummy hash when the account doesn't exist so response time doesn't reveal valid emails.
    const ok = await bcrypt.compare(b.password, a?.password_hash ?? DUMMY_HASH)
    if (!a || !ok || !a.is_active) throw new AppError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect')
    await query(`UPDATE admin_users SET last_login_at = now() WHERE id = $1`, [a.id])
    const token = app.jwt.sign({ sub: a.id, typ: 'admin', role: a.role }, { expiresIn: '8h' })
    return { token, expiresIn: 8 * 3600, admin: { id: a.id, email: a.email, full_name: a.full_name, role: a.role } }
  })

  // ---------------- Everything below needs a staff token ----------------
  await app.register(async (r) => {
    r.addHook('preHandler', r.authenticateAdmin)
    const ops = { preHandler: requireRole('ops') }
    const support = { preHandler: requireRole('ops', 'support') }

    r.get('/me', async (req) => req.admin)

    r.post('/me/password', async (req) => {
      const b = parse(z.object({ currentPassword: z.string().min(1), newPassword: staffPassword }), req.body)
      const a = await one(`SELECT password_hash FROM admin_users WHERE id = $1`, [req.admin!.id])
      if (!(await bcrypt.compare(b.currentPassword, a.password_hash))) throw new AppError(400, 'WRONG_PASSWORD', 'Current password is incorrect')
      await query(`UPDATE admin_users SET password_hash = $2 WHERE id = $1`, [req.admin!.id, await bcrypt.hash(b.newPassword, 12)])
      return { ok: true }
    })

    /** Dropdown data: cities and hubs. */
    r.get('/lookups', async () => {
      const [cities, hubs] = await Promise.all([
        query(`SELECT id, name, state, is_active FROM cities ORDER BY name`),
        query(`SELECT h.id, h.name, h.city_id, c.name AS city, h.address, h.lat, h.lng, h.is_active,
                      (SELECT count(*) FROM partners p WHERE p.hub_id = h.id AND p.status = 'active') AS active_partners,
                      (SELECT count(*) FROM partners p WHERE p.hub_id = h.id AND p.status = 'active' AND p.is_online) AS online_partners
               FROM hubs h JOIN cities c ON c.id = h.city_id ORDER BY c.name, h.name`),
      ])
      return { cities, hubs }
    })

    // ---------------- Dashboard ----------------
    r.get('/overview', async () => {
      const [k, series, openByStatus, recentOrders, activity] = await Promise.all([
        one(`SELECT
          (SELECT count(*) FROM partners) AS partners_total,
          (SELECT count(*) FROM partners WHERE status = 'active') AS partners_active,
          (SELECT count(*) FROM partners WHERE status = 'active' AND is_online) AS partners_online,
          (SELECT count(*) FROM partners WHERE status = 'onboarding') AS partners_onboarding,
          (SELECT count(*) FROM partners WHERE created_at >= ${IST_TODAY}) AS partners_new_today,
          (SELECT count(*) FROM partner_documents WHERE status = 'in_review') AS documents_in_review,
          (SELECT count(*) FROM orders WHERE created_at >= ${IST_TODAY}) AS orders_today,
          (SELECT count(*) FROM orders WHERE status = 'delivered' AND delivered_at >= ${IST_TODAY}) AS delivered_today,
          (SELECT count(*) FROM orders WHERE status = 'cancelled' AND cancelled_at >= ${IST_TODAY}) AS cancelled_today,
          (SELECT count(*) FROM orders WHERE status = 'created') AS orders_unassigned,
          (SELECT count(*) FROM orders WHERE status IN ${OPEN}) AS orders_in_progress,
          (SELECT round(avg(extract(epoch FROM delivered_at - assigned_at) / 60)) FROM orders
             WHERE status = 'delivered' AND delivered_at >= now() - interval '7 days' AND assigned_at IS NOT NULL) AS avg_delivery_minutes_7d,
          (SELECT COALESCE(sum(amount_paise), 0) FROM wallet_ledger WHERE type IN ('delivery_base','delivery_distance','tip') AND created_at >= ${IST_TODAY}) AS earnings_today_paise,
          (SELECT count(*) FROM payouts WHERE status IN ('requested','processing')) AS payouts_pending,
          (SELECT COALESCE(sum(amount_paise), 0) FROM payouts WHERE status IN ('requested','processing')) AS payouts_pending_paise,
          (SELECT count(*) FROM support_tickets WHERE status = 'open') AS tickets_open,
          (SELECT count(*) FROM sos_incidents WHERE status <> 'resolved') AS sos_open,
          (SELECT count(*) FROM hub_change_requests WHERE status = 'pending') AS zone_requests_pending`),
        query(`SELECT to_char(g.d, 'YYYY-MM-DD') AS day,
                 (SELECT count(*) FROM orders o WHERE (o.created_at AT TIME ZONE 'Asia/Kolkata')::date = g.d::date) AS created,
                 (SELECT count(*) FROM orders o WHERE o.status = 'delivered' AND (o.delivered_at AT TIME ZONE 'Asia/Kolkata')::date = g.d::date) AS delivered,
                 (SELECT COALESCE(sum(amount_paise), 0) FROM wallet_ledger l WHERE l.type IN ('delivery_base','delivery_distance','tip')
                    AND (l.created_at AT TIME ZONE 'Asia/Kolkata')::date = g.d::date) AS earnings_paise
               FROM generate_series((now() AT TIME ZONE 'Asia/Kolkata')::date - 13, (now() AT TIME ZONE 'Asia/Kolkata')::date, interval '1 day') AS g(d)
               ORDER BY g.d`),
        query(`SELECT status, count(*) AS n FROM orders WHERE status NOT IN ('delivered','cancelled') GROUP BY status`),
        query(`SELECT o.id, o.order_code, o.status, o.customer_name, o.created_at, h.name AS hub_name, p.full_name AS partner_name,
                      (o.pay_base_paise + o.pay_distance_paise + o.tip_paise) AS payout_paise
               FROM orders o JOIN hubs h ON h.id = o.hub_id LEFT JOIN partners p ON p.id = o.partner_id
               ORDER BY o.created_at DESC LIMIT 6`),
        query(`SELECT l.id, l.action, l.entity, l.entity_id, l.details, l.created_at, a.full_name AS admin_name
               FROM admin_audit_log l LEFT JOIN admin_users a ON a.id = l.admin_id ORDER BY l.id DESC LIMIT 8`),
      ])
      return { kpis: k, series, openByStatus, recentOrders, activity }
    })

    // ---------------- Partners ----------------
    const partnerSort: Record<string, string> = {
      recent: 'p.created_at DESC',
      name: 'p.full_name ASC',
      deliveries: 'deliveries DESC, p.full_name',
      assign: 'p.is_online DESC, open_orders ASC, p.rating DESC',
    }
    r.get('/partners', async (req) => {
      const q = parse(z.object({
        q: z.string().trim().max(60).optional(),
        status: z.enum(['onboarding', 'active', 'suspended', 'deactivated']).optional(),
        kyc: z.enum(['not_started', 'in_review', 'verified', 'rejected']).optional(),
        online: z.enum(['true', 'false']).optional(),
        hubId: z.uuid().optional(),
        sort: z.enum(['recent', 'name', 'deliveries', 'assign']).default('recent'),
        ...paging,
      }), req.query)
      const rows = await query(
        `SELECT p.id, p.partner_code, p.full_name, p.phone, p.status, p.kyc_status, p.is_online, p.last_online_at, p.vehicle_type,
                p.rating, p.created_at, p.hub_id, c.name AS city, h.name AS hub_name,
                (SELECT count(*) FROM orders o WHERE o.partner_id = p.id AND o.status = 'delivered') AS deliveries,
                (SELECT count(*) FROM orders o WHERE o.partner_id = p.id AND o.status IN ${OPEN}) AS open_orders,
                (SELECT count(*) FROM partner_documents d WHERE d.partner_id = p.id AND d.status = 'in_review') AS documents_in_review,
                count(*) OVER () AS total
         FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id
         WHERE ($1::text IS NULL OR p.full_name ILIKE '%' || $1 || '%' OR p.phone LIKE '%' || $1 || '%' OR p.partner_code ILIKE '%' || $1 || '%')
           AND ($2::partner_status IS NULL OR p.status = $2)
           AND ($3::kyc_status IS NULL OR p.kyc_status = $3)
           AND ($4::boolean IS NULL OR p.is_online = $4)
           AND ($5::uuid IS NULL OR p.hub_id = $5)
         ORDER BY ${partnerSort[q.sort]} LIMIT $6 OFFSET $7`,
        [blank(q.q), q.status ?? null, q.kyc ?? null, q.online ?? null, q.hubId ?? null, q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    r.get('/partners/:id', async (req) => {
      const { id } = parse(idParam, req.params)
      const p = await one(
        `SELECT p.id, p.partner_code, p.full_name, p.phone, p.email, p.status, p.kyc_status, p.is_online, p.last_online_at, p.language,
                p.date_of_birth, p.blood_group, p.address, p.rating, p.referral_code, p.vehicle_type, p.delivery_radius_km,
                p.created_at, p.city_id, c.name AS city, p.hub_id, h.name AS hub_name
         FROM partners p JOIN cities c ON c.id = p.city_id LEFT JOIN hubs h ON h.id = p.hub_id WHERE p.id = $1`, [id])
      if (!p) throw notFound('Partner')
      const [documents, vehicle, payoutMethods, stats, orders, emergency, history] = await Promise.all([
        query(`SELECT id, type, status, number_masked, source, valid_until, rejection_reason, submitted_at, reviewed_at, reviewed_by,
                      cardinality(s3_keys) AS file_count
               FROM partner_documents WHERE partner_id = $1 ORDER BY type`, [id]),
        one(`SELECT type, registration_number, make_model, year, colour, fuel FROM vehicles WHERE partner_id = $1`, [id]),
        query(`SELECT id, type, account_holder_name, account_last4, ifsc, bank_name, branch, upi_vpa, is_primary, verification, verified_name, created_at
               FROM payout_methods WHERE partner_id = $1 AND deleted_at IS NULL ORDER BY is_primary DESC, created_at`, [id]),
        one(`SELECT
               (SELECT COALESCE(sum(amount_paise), 0) FROM wallet_ledger WHERE partner_id = $1) AS balance_paise,
               (SELECT COALESCE(sum(amount_paise), 0) FROM wallet_ledger WHERE partner_id = $1 AND type IN ('delivery_base','delivery_distance','tip','bonus','incentive')) AS lifetime_earnings_paise,
               (SELECT count(*) FROM orders WHERE partner_id = $1 AND status = 'delivered') AS deliveries,
               (SELECT count(*) FROM orders WHERE partner_id = $1 AND status = 'cancelled') AS cancelled,
               (SELECT count(*) FROM orders WHERE partner_id = $1 AND status IN ${OPEN}) AS open_orders`, [id]),
        query(`SELECT o.id, o.order_code, o.status, o.customer_name, o.created_at, o.delivered_at,
                      (o.pay_base_paise + o.pay_distance_paise + o.tip_paise) AS payout_paise
               FROM orders o WHERE o.partner_id = $1 ORDER BY o.created_at DESC LIMIT 10`, [id]),
        query(`SELECT name, relationship, phone, is_primary FROM emergency_contacts WHERE partner_id = $1 ORDER BY is_primary DESC`, [id]),
        query(`SELECT l.action, l.details, l.created_at, a.full_name AS admin_name FROM admin_audit_log l LEFT JOIN admin_users a ON a.id = l.admin_id
               WHERE (l.entity = 'partner' AND l.entity_id = $1)
                  OR (l.entity = 'document' AND l.entity_id IN (SELECT id::text FROM partner_documents WHERE partner_id = $2))
               ORDER BY l.id DESC LIMIT 15`, [id, id]),
      ])
      return { ...p, documents, vehicle, payoutMethods, stats, orders, emergencyContacts: emergency, history, requiredDocuments: REQUIRED_DOCS }
    })

    r.patch('/partners/:id', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({
        status: z.enum(['onboarding', 'active', 'suspended', 'deactivated']).optional(),
        kycStatus: z.enum(['not_started', 'in_review', 'verified', 'rejected']).optional(),
        hubId: z.uuid().nullable().optional(),
        deliveryRadiusKm: z.number().int().min(1).max(25).optional(),
        reason: z.string().trim().max(300).optional(),
      }), req.body)
      return tx(async (db) => {
        const before = await one(`SELECT id, status, kyc_status, hub_id, delivery_radius_km, city_id FROM partners WHERE id = $1 FOR UPDATE`, [id], db)
        if (!before) throw notFound('Partner')
        if (b.hubId) {
          const hub = await one(`SELECT city_id FROM hubs WHERE id = $1`, [b.hubId], db)
          if (!hub) throw notFound('Hub')
          if (hub.city_id !== before.city_id) throw new AppError(400, 'HUB_OTHER_CITY', 'That hub is in another city. Approve a city change request instead')
        }
        const after = await one(
          `UPDATE partners SET
             status = COALESCE($2, status),
             kyc_status = COALESCE($3, kyc_status),
             hub_id = CASE WHEN $4 THEN $5::uuid ELSE hub_id END,
             delivery_radius_km = COALESCE($6, delivery_radius_km),
             is_online = CASE WHEN COALESCE($2, status) = 'active' THEN is_online ELSE false END
           WHERE id = $1 RETURNING id, status, kyc_status, hub_id, delivery_radius_km`,
          [id, b.status ?? null, b.kycStatus ?? null, b.hubId !== undefined, b.hubId ?? null, b.deliveryRadiusKm ?? null], db)
        await audit(db, req, 'partner.updated', 'partner', id, { before, after, reason: b.reason })
        if (b.status && b.status !== before.status) {
          const msg: Record<string, [string, string]> = {
            active: ['You’re approved to deliver', 'Your account is active. Go online to start receiving orders.'],
            suspended: ['Account suspended', b.reason || 'Your account has been suspended. Contact support for details.'],
            deactivated: ['Account deactivated', b.reason || 'Your account has been deactivated. Contact support for details.'],
            onboarding: ['Verification needed', b.reason || 'Please complete your verification to continue.'],
          }
          await notify(db, id, 'account', ...msg[b.status])
        }
        return after
      })
    })

    /** Mark a bank account / UPI ID as verified or failed (until penny-drop / UPI lookup is automated). */
    r.post('/payout-methods/:id/verification', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({ verification: z.enum(['verified', 'failed']), verifiedName: z.string().trim().max(100).optional() }), req.body)
      return tx(async (db) => {
        const m = await one(
          `UPDATE payout_methods SET verification = $2, verified_name = COALESCE($3, verified_name, account_holder_name)
           WHERE id = $1 AND deleted_at IS NULL RETURNING id, partner_id, type, verification, account_last4, upi_vpa`,
          [id, b.verification, b.verifiedName ?? null], db)
        if (!m) throw notFound('Payout method')
        await audit(db, req, `payout_method.${b.verification}`, 'partner', m.partner_id, { payoutMethodId: id })
        const what = m.type === 'upi' ? `UPI ID ${m.upi_vpa}` : `bank account ••${m.account_last4}`
        await notify(db, m.partner_id, 'payout', b.verification === 'verified' ? 'Payout method verified' : 'Payout method could not be verified',
          b.verification === 'verified' ? `Your ${what} is verified and ready for payouts.` : `We couldn’t verify your ${what}. Please check the details and add it again.`)
        return m
      })
    })

    // ---------------- KYC documents ----------------
    r.get('/documents', async (req) => {
      const q = parse(z.object({
        status: z.enum(['pending_upload', 'in_review', 'verified', 'rejected', 'expired']).default('in_review'),
        type: z.enum(['aadhaar', 'pan', 'driving_licence', 'vehicle_rc', 'vehicle_insurance', 'pucc', 'police_verification', 'selfie']).optional(),
        q: z.string().trim().max(60).optional(),
        ...paging,
      }), req.query)
      const rows = await query(
        `SELECT d.id, d.type, d.status, d.number_masked, d.source, d.valid_until, d.rejection_reason, d.submitted_at, d.reviewed_at, d.reviewed_by,
                cardinality(d.s3_keys) AS file_count, p.id AS partner_id, p.full_name AS partner_name, p.partner_code, p.phone, c.name AS city,
                count(*) OVER () AS total
         FROM partner_documents d JOIN partners p ON p.id = d.partner_id JOIN cities c ON c.id = p.city_id
         WHERE d.status = $1 AND ($2::document_type IS NULL OR d.type = $2)
           AND ($3::text IS NULL OR p.full_name ILIKE '%' || $3 || '%' OR p.phone LIKE '%' || $3 || '%' OR p.partner_code ILIKE '%' || $3 || '%')
         ORDER BY ${q.status === 'in_review' ? 'd.submitted_at ASC' : 'COALESCE(d.reviewed_at, d.updated_at) DESC'}
         LIMIT $4 OFFSET $5`,
        [q.status, q.type ?? null, blank(q.q), q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    /** Short-lived links to view the uploaded images / PDFs. */
    r.get('/documents/:id/files', async (req) => {
      const { id } = parse(idParam, req.params)
      const d = await one<{ s3_keys: string[] }>(`SELECT s3_keys FROM partner_documents WHERE id = $1`, [id])
      if (!d) throw notFound('Document')
      return Promise.all(d.s3_keys.map(async (key) => ({
        key,
        name: key.split('/').pop(),
        kind: key.endsWith('.pdf') ? 'pdf' : 'image',
        url: await presignDownload(key, 300),
      })))
    })

    r.post('/documents/:id/review', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({
        decision: z.enum(['verified', 'rejected']),
        reason: z.string().trim().min(3).max(300).optional(),
        validUntil: z.iso.date().optional(),
      }), req.body)
      if (b.decision === 'rejected' && !b.reason) throw new AppError(400, 'REASON_REQUIRED', 'Tell the partner why the document was rejected')
      return tx(async (db) => {
        const d = await one(
          `UPDATE partner_documents SET status = $2, rejection_reason = $3, reviewed_at = now(), reviewed_by = $4, valid_until = COALESCE($5, valid_until)
           WHERE id = $1 AND status IN ('in_review', 'verified', 'rejected') RETURNING id, partner_id, type, status`,
          [id, b.decision, b.decision === 'rejected' ? b.reason : null, req.admin!.email, b.validUntil ?? null], db)
        if (!d) throw notFound('Document awaiting review')
        await query(`INSERT INTO document_events (document_id, status, note) VALUES ($1, $2, $3)`, [id, b.decision, b.reason ?? null], db)
        await audit(db, req, `document.${b.decision}`, 'document', id, { type: d.type, partnerId: d.partner_id, reason: b.reason })

        // KYC is complete once every required document is verified.
        const done = await one<{ n: number }>(
          `SELECT count(*)::int AS n FROM partner_documents WHERE partner_id = $1 AND status = 'verified' AND type = ANY($2)`,
          [d.partner_id, REQUIRED_DOCS], db)
        const allVerified = done!.n === REQUIRED_DOCS.length
        const kyc = allVerified ? 'verified' : b.decision === 'rejected' ? 'rejected' : 'in_review'
        await query(`UPDATE partners SET kyc_status = $2 WHERE id = $1`, [d.partner_id, kyc], db)

        const label = d.type.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase())
        await notify(db, d.partner_id, 'account',
          b.decision === 'verified' ? `${label} verified` : `${label} needs attention`,
          b.decision === 'verified'
            ? (allVerified ? 'All your documents are verified. You’ll be activated shortly.' : 'Thanks! This document is verified.')
            : `Please upload it again: ${b.reason}`,
          '/documents')
        return { ...d, partnerKycStatus: kyc, allVerified }
      })
    })

    // ---------------- Orders ----------------
    r.get('/orders', async (req) => {
      const q = parse(z.object({
        status: z.enum(['created', 'assigned', 'accepted', 'at_pickup', 'picked_up', 'arrived', 'delivered', 'cancelled', 'open']).optional(),
        hubId: z.uuid().optional(),
        partnerId: z.uuid().optional(),
        q: z.string().trim().max(60).optional(),
        ...paging,
      }), req.query)
      const statuses = q.status === 'open' ? ['created', 'assigned', 'accepted', 'at_pickup', 'picked_up', 'arrived'] : q.status ? [q.status] : null
      const rows = await query(
        `SELECT o.id, o.order_code, o.status, o.customer_name, o.drop_address, o.distance_km, o.eta_minutes, o.scheduled_for,
                (o.pay_base_paise + o.pay_distance_paise + o.tip_paise) AS payout_paise, o.created_at, o.assigned_at, o.delivered_at,
                h.name AS hub_name, p.id AS partner_id, p.full_name AS partner_name,
                (SELECT count(*) FROM order_crates c WHERE c.order_id = o.id) AS crate_count,
                count(*) OVER () AS total
         FROM orders o JOIN hubs h ON h.id = o.hub_id LEFT JOIN partners p ON p.id = o.partner_id
         WHERE ($1::order_status[] IS NULL OR o.status = ANY($1))
           AND ($2::uuid IS NULL OR o.hub_id = $2)
           AND ($3::uuid IS NULL OR o.partner_id = $3)
           AND ($4::text IS NULL OR o.order_code ILIKE '%' || $4 || '%' OR o.customer_name ILIKE '%' || $4 || '%' OR p.full_name ILIKE '%' || $4 || '%')
         ORDER BY o.created_at DESC LIMIT $5 OFFSET $6`,
        [statuses, q.hubId ?? null, q.partnerId ?? null, blank(q.q), q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    r.get('/orders/:id', async (req) => {
      const { id } = parse(idParam, req.params)
      const o = await one(
        `SELECT o.*, h.name AS hub_name, h.address AS hub_address, p.full_name AS partner_name, p.phone AS partner_phone, p.partner_code
         FROM orders o JOIN hubs h ON h.id = o.hub_id LEFT JOIN partners p ON p.id = o.partner_id WHERE o.id = $1`, [id])
      if (!o) throw notFound('Order')
      delete o.delivery_code_hash
      const [crates, events] = await Promise.all([
        query(`SELECT id, position, label, weight_grams, qr_code, scanned_at, damaged FROM order_crates WHERE order_id = $1 ORDER BY position`, [id]),
        query(`SELECT id, status, actor, note, lat, lng, created_at FROM order_events WHERE order_id = $1 ORDER BY created_at`, [id]),
      ])
      return { ...o, crates, events }
    })

    /** Create an order (optionally assigning it straight away). The delivery code is returned once — share it with the customer. */
    r.post('/orders', ops, async (req, reply) => {
      const b = parse(z.object({
        hubId: z.uuid(),
        customerName: z.string().trim().min(2).max(80),
        customerPhone: phoneSchema,
        dropAddress: z.string().trim().min(8).max(300),
        dropLat: z.number().min(-90).max(90),
        dropLng: z.number().min(-180).max(180),
        dropInstructions: z.string().trim().max(300).optional(),
        leaveAtDoor: z.boolean().default(false),
        distanceKm: z.number().positive().max(100),
        etaMinutes: z.number().int().positive().max(600).optional(),
        scheduledFor: z.iso.datetime({ offset: true }).optional(),
        payBasePaise: z.number().int().min(0).max(1_000_000),
        payDistancePaise: z.number().int().min(0).max(1_000_000).default(0),
        tipPaise: z.number().int().min(0).max(1_000_000).default(0),
        crates: z.array(z.object({ label: z.string().trim().min(1).max(60), weightGrams: z.number().int().positive().max(100_000) })).min(1).max(20),
        partnerId: z.uuid().optional(),
      }), req.body)
      const out = await tx(async (db) => {
        if (!(await one(`SELECT 1 FROM hubs WHERE id = $1 AND is_active`, [b.hubId], db))) throw notFound('Active hub')
        if (b.partnerId) await assignablePartner(db, b.partnerId)
        const id = randomUUID()
        const code = numericCode(4)
        const o = await one(
          `INSERT INTO orders (id, order_code, hub_id, partner_id, status, customer_name, customer_phone, drop_address, drop_lat, drop_lng,
             drop_instructions, leave_at_door, delivery_code_hash, distance_km, eta_minutes, scheduled_for, pay_base_paise, pay_distance_paise, tip_paise, assigned_at)
           VALUES ($1, 'VPN-' || nextval('order_number_seq'), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18,
                   CASE WHEN $3::uuid IS NULL THEN NULL ELSE now() END)
           RETURNING id, order_code, status`,
          [id, b.hubId, b.partnerId ?? null, b.partnerId ? 'assigned' : 'created', b.customerName, b.customerPhone, b.dropAddress, b.dropLat, b.dropLng,
            b.dropInstructions || null, b.leaveAtDoor, sha256(`${id}:${code}`), b.distanceKm, b.etaMinutes ?? null, b.scheduledFor ?? null,
            b.payBasePaise, b.payDistancePaise, b.tipPaise], db)
        const tag = randomBytes(4).toString('hex').toUpperCase()
        for (const [i, c] of b.crates.entries()) {
          await query(`INSERT INTO order_crates (order_id, position, label, weight_grams, qr_code) VALUES ($1, $2, $3, $4, $5)`,
            [id, i + 1, c.label, c.weightGrams, `VPN-CRATE-${tag}-${i + 1}`], db)
        }
        await query(`INSERT INTO order_events (order_id, status, actor, note) VALUES ($1, 'created', $2, NULL)`, [id, actor(req)], db)
        if (b.partnerId) {
          await query(`INSERT INTO order_events (order_id, status, actor) VALUES ($1, 'assigned', $2)`, [id, actor(req)], db)
          await notifyAssigned(db, b.partnerId, o.order_code, id, b.customerName, b.distanceKm, b.payBasePaise + b.payDistancePaise + b.tipPaise)
        }
        await audit(db, req, 'order.created', 'order', id, { orderCode: o.order_code, partnerId: b.partnerId })
        return { ...o, deliveryCode: code }
      })
      reply.status(201)
      return out
    })

    r.post('/orders/:id/assign', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const { partnerId } = parse(z.object({ partnerId: z.uuid() }), req.body)
      return tx(async (db) => {
        const o = await one(`SELECT * FROM orders WHERE id = $1 FOR UPDATE`, [id], db)
        if (!o) throw notFound('Order')
        if (!['created', 'assigned', 'accepted', 'at_pickup'].includes(o.status)) throw new AppError(409, 'BAD_ORDER_STATE', `A ${o.status.replace('_', ' ')} order can’t be reassigned`)
        if (o.partner_id === partnerId) throw new AppError(409, 'ALREADY_ASSIGNED', 'The order is already with this partner')
        await assignablePartner(db, partnerId)
        await query(`UPDATE orders SET partner_id = $2, status = 'assigned', assigned_at = now(), accepted_at = NULL WHERE id = $1`, [id, partnerId], db)
        await query(`UPDATE order_crates SET scanned_at = NULL WHERE order_id = $1`, [id], db)
        await query(`INSERT INTO order_events (order_id, status, actor, note) VALUES ($1, 'assigned', $2, $3)`,
          [id, actor(req), o.partner_id ? 'Reassigned by ops' : null], db)
        if (o.partner_id) await notify(db, o.partner_id, 'order', `Order #${o.order_code} reassigned`, 'The hub moved this order to another partner. No action needed.')
        await notifyAssigned(db, partnerId, o.order_code, id, o.customer_name, o.distance_km, o.pay_base_paise + o.pay_distance_paise + o.tip_paise)
        await audit(db, req, o.partner_id ? 'order.reassigned' : 'order.assigned', 'order', id, { orderCode: o.order_code, from: o.partner_id, to: partnerId })
        return { id, status: 'assigned', partnerId }
      })
    })

    r.post('/orders/:id/cancel', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const { reason } = parse(z.object({ reason: z.string().trim().min(3).max(300) }), req.body)
      return tx(async (db) => {
        const o = await one(`SELECT * FROM orders WHERE id = $1 FOR UPDATE`, [id], db)
        if (!o) throw notFound('Order')
        if (o.status === 'delivered' || o.status === 'cancelled') throw new AppError(409, 'BAD_ORDER_STATE', `Order is already ${o.status}`)
        await query(`UPDATE orders SET status = 'cancelled', cancelled_at = now(), cancel_reason = $2 WHERE id = $1`, [id, reason], db)
        await query(`INSERT INTO order_events (order_id, status, actor, note) VALUES ($1, 'cancelled', $2, $3)`, [id, actor(req), reason], db)
        if (o.partner_id) await notify(db, o.partner_id, 'order', `Order #${o.order_code} cancelled`, reason)
        await audit(db, req, 'order.cancelled', 'order', id, { orderCode: o.order_code, reason })
        return { id, status: 'cancelled' }
      })
    })

    /** New hand-over code (e.g. the customer lost it, or the partner got locked out after wrong tries). */
    r.post('/orders/:id/reset-code', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      return tx(async (db) => {
        const o = await one(`SELECT id, order_code, status FROM orders WHERE id = $1 FOR UPDATE`, [id], db)
        if (!o) throw notFound('Order')
        if (o.status === 'delivered' || o.status === 'cancelled') throw new AppError(409, 'BAD_ORDER_STATE', `Order is already ${o.status}`)
        const code = numericCode(4)
        await query(`UPDATE orders SET delivery_code_hash = $2, delivery_attempts = 0 WHERE id = $1`, [id, sha256(`${id}:${code}`)], db)
        await audit(db, req, 'order.code_reset', 'order', id, { orderCode: o.order_code })
        return { deliveryCode: code }
      })
    })

    // ---------------- Payouts ----------------
    r.get('/payouts', async (req) => {
      const q = parse(z.object({ status: z.enum(['requested', 'processing', 'paid', 'failed', 'pending']).optional(), q: z.string().trim().max(60).optional(), ...paging }), req.query)
      const statuses = q.status === 'pending' ? ['requested', 'processing'] : q.status ? [q.status] : null
      const rows = await query(
        `SELECT y.id, y.kind, y.amount_paise, y.fee_paise, y.status, y.utr, y.failure_reason, y.requested_at, y.processed_at,
                p.id AS partner_id, p.full_name AS partner_name, p.partner_code, p.phone,
                m.type AS method_type, m.account_last4, m.ifsc, m.bank_name, m.upi_vpa, m.account_holder_name, m.verification,
                count(*) OVER () AS total
         FROM payouts y JOIN partners p ON p.id = y.partner_id JOIN payout_methods m ON m.id = y.payout_method_id
         WHERE ($1::payout_status[] IS NULL OR y.status = ANY($1))
           AND ($2::text IS NULL OR p.full_name ILIKE '%' || $2 || '%' OR p.partner_code ILIKE '%' || $2 || '%' OR y.utr ILIKE '%' || $2 || '%')
         ORDER BY y.requested_at DESC LIMIT $3 OFFSET $4`,
        [statuses, blank(q.q), q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    r.post('/payouts/:id/status', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({
        status: z.enum(['processing', 'paid', 'failed']),
        utr: z.string().trim().min(6).max(40).optional(),
        failureReason: z.string().trim().min(3).max(300).optional(),
      }), req.body)
      if (b.status === 'paid' && !b.utr) throw new AppError(400, 'UTR_REQUIRED', 'Enter the bank reference (UTR) for a paid payout')
      if (b.status === 'failed' && !b.failureReason) throw new AppError(400, 'REASON_REQUIRED', 'Say why the payout failed')
      return tx(async (db) => {
        const y = await one(`SELECT * FROM payouts WHERE id = $1 FOR UPDATE`, [id], db)
        if (!y) throw notFound('Payout')
        const allowed: Record<string, string[]> = { requested: ['processing', 'paid', 'failed'], processing: ['paid', 'failed'] }
        if (!allowed[y.status]?.includes(b.status)) throw new AppError(409, 'BAD_PAYOUT_STATE', `A ${y.status} payout can’t be marked ${b.status}`)
        const out = await one(
          `UPDATE payouts SET status = $2::payout_status, utr = COALESCE($3, utr), failure_reason = $4,
             processed_at = CASE WHEN $2::payout_status IN ('paid','failed') THEN now() ELSE processed_at END
           WHERE id = $1 RETURNING id, status, utr, failure_reason, processed_at`,
          [id, b.status, b.utr ?? null, b.status === 'failed' ? b.failureReason : null], db)
        const rupees = `₹${(y.amount_paise / 100).toLocaleString('en-IN')}`
        if (b.status === 'failed') {
          // The ledger is append-only: give the money back with adjustment entries.
          await query(
            `INSERT INTO wallet_ledger (partner_id, type, amount_paise, payout_id, description) VALUES ($1, 'adjustment', $2, $3, 'Payout failed · amount returned')`,
            [y.partner_id, y.amount_paise, id], db)
          if (y.fee_paise > 0) {
            await query(
              `INSERT INTO wallet_ledger (partner_id, type, amount_paise, payout_id, description) VALUES ($1, 'adjustment', $2, $3, 'Payout failed · fee returned')`,
              [y.partner_id, y.fee_paise, id], db)
          }
          await notify(db, y.partner_id, 'payout', `Payout of ${rupees} failed`, `${b.failureReason}. The money is back in your balance.`)
        } else if (b.status === 'paid') {
          await notify(db, y.partner_id, 'payout', `${rupees} sent to your account`, `Bank reference (UTR): ${b.utr}`)
        }
        await audit(db, req, `payout.${b.status}`, 'payout', id, { partnerId: y.partner_id, amountPaise: y.amount_paise, utr: b.utr, reason: b.failureReason })
        return out
      })
    })

    // ---------------- Support desk ----------------
    r.get('/tickets', async (req) => {
      const q = parse(z.object({ status: z.enum(['open', 'waiting_on_partner', 'resolved', 'closed']).optional(), ...paging }), req.query)
      const rows = await query(
        `SELECT t.id, t.topic, t.status, t.created_at, t.updated_at, t.order_id, o.order_code,
                p.id AS partner_id, p.full_name AS partner_name, p.partner_code,
                m.body AS last_message, m.sender AS last_sender, m.created_at AS last_message_at,
                (SELECT count(*) FROM support_messages x WHERE x.ticket_id = t.id) AS message_count,
                count(*) OVER () AS total
         FROM support_tickets t JOIN partners p ON p.id = t.partner_id LEFT JOIN orders o ON o.id = t.order_id
         LEFT JOIN LATERAL (SELECT body, sender, created_at FROM support_messages WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1) m ON true
         WHERE ($1::ticket_status IS NULL OR t.status = $1)
         ORDER BY (t.status = 'open') DESC, t.updated_at DESC LIMIT $2 OFFSET $3`,
        [q.status ?? null, q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    r.get('/tickets/:id', async (req) => {
      const { id } = parse(idParam, req.params)
      const t = await one(
        `SELECT t.*, o.order_code, p.full_name AS partner_name, p.partner_code, p.phone AS partner_phone
         FROM support_tickets t JOIN partners p ON p.id = t.partner_id LEFT JOIN orders o ON o.id = t.order_id WHERE t.id = $1`, [id])
      if (!t) throw notFound('Ticket')
      const messages = await query(`SELECT id, sender, body, created_at FROM support_messages WHERE ticket_id = $1 ORDER BY created_at`, [id])
      return { ...t, messages }
    })

    r.post('/tickets/:id/messages', support, async (req, reply) => {
      const { id } = parse(idParam, req.params)
      const { message } = parse(z.object({ message: z.string().trim().min(1).max(2000) }), req.body)
      const m = await tx(async (db) => {
        const t = await one(`UPDATE support_tickets SET status = 'waiting_on_partner' WHERE id = $1 AND status <> 'closed' RETURNING id, partner_id, topic`, [id], db)
        if (!t) throw notFound('Open ticket')
        const m = await one(`INSERT INTO support_messages (ticket_id, sender, body) VALUES ($1, 'agent', $2) RETURNING id, sender, body, created_at`, [id, message], db)
        await notify(db, t.partner_id, 'account', `Support replied · ${t.topic}`, message.slice(0, 140), '/support')
        await audit(db, req, 'ticket.replied', 'ticket', id)
        return m
      })
      reply.status(201)
      return m
    })

    r.patch('/tickets/:id', support, async (req) => {
      const { id } = parse(idParam, req.params)
      const { status } = parse(z.object({ status: z.enum(['open', 'waiting_on_partner', 'resolved', 'closed']) }), req.body)
      return tx(async (db) => {
        const t = await one(`UPDATE support_tickets SET status = $2 WHERE id = $1 RETURNING id, status, partner_id, topic`, [id, status], db)
        if (!t) throw notFound('Ticket')
        if (status === 'resolved') await notify(db, t.partner_id, 'account', `Ticket resolved · ${t.topic}`, 'Reply in the chat if you still need help.', '/support')
        await audit(db, req, `ticket.${status}`, 'ticket', id)
        return t
      })
    })

    // ---------------- Safety ----------------
    r.get('/sos', async (req) => {
      const q = parse(z.object({ status: z.enum(['open', 'acknowledged', 'resolved', 'active']).default('active'), ...paging }), req.query)
      const statuses = q.status === 'active' ? ['open', 'acknowledged'] : [q.status]
      const rows = await query(
        `SELECT s.id, s.kind, s.status, s.lat, s.lng, s.details, s.created_at, s.acknowledged_at, s.resolved_at,
                p.id AS partner_id, p.full_name AS partner_name, p.phone AS partner_phone, p.partner_code, p.blood_group,
                o.order_code,
                (SELECT json_build_object('name', e.name, 'relationship', e.relationship, 'phone', e.phone)
                   FROM emergency_contacts e WHERE e.partner_id = p.id ORDER BY e.is_primary DESC LIMIT 1) AS emergency_contact,
                count(*) OVER () AS total
         FROM sos_incidents s JOIN partners p ON p.id = s.partner_id LEFT JOIN orders o ON o.id = s.order_id
         WHERE s.status = ANY($1::sos_status[])
         ORDER BY (s.status = 'open') DESC, s.created_at DESC LIMIT $2 OFFSET $3`,
        [statuses, q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    r.post('/sos/:id/status', support, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({ status: z.enum(['acknowledged', 'resolved']), note: z.string().trim().max(300).optional() }), req.body)
      return tx(async (db) => {
        const s = await one(
          `UPDATE sos_incidents SET status = $2::sos_status,
             acknowledged_at = COALESCE(acknowledged_at, now()),
             resolved_at = CASE WHEN $2::sos_status = 'resolved' THEN now() ELSE resolved_at END
           WHERE id = $1 AND status <> 'resolved' RETURNING id, status, partner_id`, [id, b.status], db)
        if (!s) throw notFound('Active SOS')
        if (b.status === 'acknowledged') await notify(db, s.partner_id, 'safety', 'Help is on the way', 'Our safety team has your alert and will call you now.')
        await audit(db, req, `sos.${b.status}`, 'sos', id, { note: b.note })
        return s
      })
    })

    // ---------------- City / hub change requests ----------------
    r.get('/zone-requests', async (req) => {
      const q = parse(z.object({ status: z.enum(['pending', 'approved', 'rejected', 'cancelled']).default('pending'), ...paging }), req.query)
      const rows = await query(
        `SELECT r.id, r.status, r.created_at, r.resolved_at, p.id AS partner_id, p.full_name AS partner_name, p.partner_code,
                fc.name AS from_city, fh.name AS from_hub, tc.name AS to_city, r.to_city_id, th.name AS to_hub, r.to_hub_id,
                count(*) OVER () AS total
         FROM hub_change_requests r JOIN partners p ON p.id = r.partner_id
         JOIN cities fc ON fc.id = p.city_id LEFT JOIN hubs fh ON fh.id = p.hub_id
         JOIN cities tc ON tc.id = r.to_city_id LEFT JOIN hubs th ON th.id = r.to_hub_id
         WHERE r.status = $1 ORDER BY r.created_at ${q.status === 'pending' ? 'ASC' : 'DESC'} LIMIT $2 OFFSET $3`,
        [q.status, q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    r.post('/zone-requests/:id/decision', ops, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({ decision: z.enum(['approved', 'rejected']), hubId: z.uuid().optional(), note: z.string().trim().max(300).optional() }), req.body)
      return tx(async (db) => {
        const r0 = await one(`SELECT * FROM hub_change_requests WHERE id = $1 AND status = 'pending' FOR UPDATE`, [id], db)
        if (!r0) throw notFound('Pending request')
        const hubId = b.hubId ?? r0.to_hub_id
        if (b.decision === 'approved') {
          if (hubId && !(await one(`SELECT 1 FROM hubs WHERE id = $1 AND city_id = $2`, [hubId, r0.to_city_id], db))) throw new AppError(400, 'HUB_OTHER_CITY', 'Pick a hub in the requested city')
          const busy = await one(`SELECT 1 FROM orders WHERE partner_id = $1 AND status IN ${OPEN}`, [r0.partner_id], db)
          if (busy) throw new AppError(409, 'PARTNER_BUSY', 'The partner has orders in progress. Approve after they finish')
          await query(`UPDATE partners SET city_id = $2, hub_id = $3, is_online = false WHERE id = $1`, [r0.partner_id, r0.to_city_id, hubId ?? null], db)
        }
        await query(`UPDATE hub_change_requests SET status = $2, to_hub_id = COALESCE($3, to_hub_id), resolved_at = now() WHERE id = $1`, [id, b.decision, hubId ?? null], db)
        await notify(db, r0.partner_id, 'account',
          b.decision === 'approved' ? 'Zone change approved' : 'Zone change not approved',
          b.decision === 'approved' ? 'Your new city / hub is active. Go online when you’re there.' : (b.note || 'Your current zone stays the same. Contact support for details.'))
        await audit(db, req, `zone_request.${b.decision}`, 'zone_request', id, { partnerId: r0.partner_id, hubId, note: b.note })
        return { id, status: b.decision }
      })
    })

    // ---------------- Audit log ----------------
    r.get('/audit', async (req) => {
      const q = parse(z.object({ entity: z.string().max(30).optional(), ...paging }), req.query)
      const rows = await query(
        `SELECT l.id, l.action, l.entity, l.entity_id, l.details, l.created_at, a.full_name AS admin_name, a.email AS admin_email,
                count(*) OVER () AS total
         FROM admin_audit_log l LEFT JOIN admin_users a ON a.id = l.admin_id
         WHERE ($1::text IS NULL OR l.entity = $1) ORDER BY l.id DESC LIMIT $2 OFFSET $3`,
        [q.entity ?? null, q.pageSize, (q.page - 1) * q.pageSize])
      return page(rows, q)
    })

    // ---------------- Staff accounts (owner only) ----------------
    const owner = { preHandler: requireRole() }
    r.get('/staff', owner, async () =>
      query(`SELECT id, email, full_name, role, is_active, last_login_at, created_at FROM admin_users ORDER BY created_at`))

    r.post('/staff', owner, async (req, reply) => {
      const b = parse(z.object({ email: z.email(), fullName: z.string().trim().min(2).max(80), role: z.enum(['owner', 'ops', 'support']), password: staffPassword }), req.body)
      const a = await tx(async (db) => {
        const a = await one(`INSERT INTO admin_users (email, full_name, role, password_hash) VALUES ($1, $2, $3, $4) RETURNING id, email, full_name, role, is_active, created_at`,
          [b.email, b.fullName, b.role, await bcrypt.hash(b.password, 12)], db)
        await audit(db, req, 'staff.created', 'staff', a.id, { email: b.email, role: b.role })
        return a
      })
      reply.status(201)
      return a
    })

    r.patch('/staff/:id', owner, async (req) => {
      const { id } = parse(idParam, req.params)
      const b = parse(z.object({ role: z.enum(['owner', 'ops', 'support']).optional(), isActive: z.boolean().optional() }), req.body)
      if (id === req.admin!.id) throw new AppError(400, 'SELF_EDIT', 'You can’t change your own role or access')
      return tx(async (db) => {
        const a = await one(`UPDATE admin_users SET role = COALESCE($2, role), is_active = COALESCE($3, is_active) WHERE id = $1
                             RETURNING id, email, full_name, role, is_active`, [id, b.role ?? null, b.isActive ?? null], db)
        if (!a) throw notFound('Staff account')
        await audit(db, req, 'staff.updated', 'staff', id, b)
        return a
      })
    })
  })
}

/** Only active partners can take orders. Returns the partner row. */
async function assignablePartner(db: Db, partnerId: string) {
  const p = await one(`SELECT id, status, full_name FROM partners WHERE id = $1`, [partnerId], db)
  if (!p) throw notFound('Partner')
  if (p.status !== 'active') throw new AppError(409, 'PARTNER_NOT_ACTIVE', `${p.full_name} is ${p.status} and can’t take orders`)
  return p
}

async function notifyAssigned(db: Db, partnerId: string, code: string, orderId: string, customer: string, km: number, paise: number) {
  await notify(db, partnerId, 'order', `New order assigned · #${code}`, `${customer} · ${Number(km)} km · ₹${paise / 100}`, `/orders/${orderId}`)
}
