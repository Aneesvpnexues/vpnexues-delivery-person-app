import type { FastifyInstance } from 'fastify'
import { z } from 'zod'
import { config } from '../config.js'
import { one, query, tx } from '../db.js'
import { AppError, notFound, parse } from '../lib/errors.js'
import { encrypt } from '../lib/crypto.js'
import { partnerId } from '../lib/auth.js'

const METHOD_COLS = `id, type, account_holder_name, account_last4, ifsc, bank_name, branch, account_type, upi_vpa,
                     is_primary, is_backup, verification, verified_name, created_at`

const bankSchema = z.object({
  type: z.literal('bank_account'),
  accountHolderName: z.string().trim().min(2).max(80),
  accountNumber: z.string().regex(/^\d{9,18}$/, 'Account number must be 9–18 digits'),
  confirmAccountNumber: z.string(),
  ifsc: z.string().trim().toUpperCase().regex(/^[A-Z]{4}0[A-Z0-9]{6}$/, 'Enter a valid IFSC'),
  bankName: z.string().trim().max(80).optional(),
  branch: z.string().trim().max(120).optional(),
  accountType: z.enum(['savings', 'current']).default('savings'),
  makePrimary: z.boolean().default(true),
}).refine((b) => b.accountNumber === b.confirmAccountNumber, { message: 'Account numbers do not match', path: ['confirmAccountNumber'] })

const upiSchema = z.object({
  type: z.literal('upi'),
  upiVpa: z.string().trim().toLowerCase().regex(/^[\w.-]{2,256}@[a-z]{2,64}$/, 'Enter a valid UPI ID'),
  makePrimary: z.boolean().default(false),
  keepBankAsBackup: z.boolean().default(true),
})

/** Payout methods, earnings, transactions and payouts. */
export default async function moneyRoutes(app: FastifyInstance) {
  app.addHook('preHandler', app.authenticate)

  // ---------- Payout methods (Bank & UPI, Add payout method, Update bank account) ----------

  app.get('/payout-methods', async (req) =>
    query(`SELECT ${METHOD_COLS} FROM payout_methods WHERE partner_id = $1 AND deleted_at IS NULL ORDER BY is_primary DESC, created_at`, [partnerId(req)]))

  app.post('/payout-methods', async (req, reply) => {
    const b = parse(z.discriminatedUnion('type', [bankSchema as any, upiSchema]), req.body) as z.infer<typeof bankSchema> | z.infer<typeof upiSchema>
    const pid = partnerId(req)
    const m = await tx(async (db) => {
      if (b.makePrimary) await query(`UPDATE payout_methods SET is_primary = false WHERE partner_id = $1 AND is_primary`, [pid], db)
      if (b.type === 'upi' && b.makePrimary && b.keepBankAsBackup) {
        await query(`UPDATE payout_methods SET is_backup = true WHERE partner_id = $1 AND type = 'bank_account' AND deleted_at IS NULL`, [pid], db)
      }
      return b.type === 'bank_account'
        ? one(
            `INSERT INTO payout_methods (partner_id, type, account_holder_name, account_number_enc, account_last4, ifsc, bank_name, branch, account_type, is_primary)
             VALUES ($1, 'bank_account', $2, $3, $4, $5, $6, $7, $8, $9) RETURNING ${METHOD_COLS}`,
            [pid, b.accountHolderName, encrypt(b.accountNumber), b.accountNumber.slice(-4), b.ifsc, b.bankName ?? null, b.branch ?? null, b.accountType, b.makePrimary], db)
        : one(
            `INSERT INTO payout_methods (partner_id, type, upi_vpa, is_primary) VALUES ($1, 'upi', $2, $3) RETURNING ${METHOD_COLS}`,
            [pid, b.upiVpa, b.makePrimary], db)
    })
    // TODO: kick off verification (₹1 penny-drop / UPI name lookup) via the payments provider, async (SQS worker).
    reply.status(201)
    return m
  })

  app.put('/payout-methods/:id/primary', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    return tx(async (db) => {
      const m = await one(`SELECT id FROM payout_methods WHERE id = $1 AND partner_id = $2 AND deleted_at IS NULL FOR UPDATE`, [id, partnerId(req)], db)
      if (!m) throw notFound('Payout method')
      await query(`UPDATE payout_methods SET is_primary = false WHERE partner_id = $1 AND is_primary`, [partnerId(req)], db)
      return one(`UPDATE payout_methods SET is_primary = true WHERE id = $1 RETURNING ${METHOD_COLS}`, [id], db)
    })
  })

  app.delete('/payout-methods/:id', async (req) => {
    const { id } = parse(z.object({ id: z.uuid() }), req.params)
    const m = await one(`UPDATE payout_methods SET deleted_at = now(), is_primary = false WHERE id = $1 AND partner_id = $2 AND deleted_at IS NULL AND NOT is_primary RETURNING id`, [id, partnerId(req)])
    if (!m) throw new AppError(400, 'CANNOT_DELETE', 'Pick another primary method before removing this one')
    return { ok: true }
  })

  // ---------- Earnings (Earnings tab) ----------

  app.get('/earnings/summary', async (req) => {
    const { range } = parse(z.object({ range: z.enum(['today', 'week', 'month', 'year']).default('today') }), req.query)
    const trunc = { today: 'day', week: 'week', month: 'month', year: 'year' }[range]
    const pid = partnerId(req)
    const [totals, byHour, balance, nextPayout] = await Promise.all([
      one(
        `SELECT COALESCE(sum(amount_paise) FILTER (WHERE type IN ('delivery_base','delivery_distance','tip','bonus','incentive','deduction')), 0) AS net_paise,
                COALESCE(sum(amount_paise) FILTER (WHERE type = 'delivery_base'), 0)     AS base_paise,
                COALESCE(sum(amount_paise) FILTER (WHERE type = 'delivery_distance'), 0) AS distance_paise,
                COALESCE(sum(amount_paise) FILTER (WHERE type IN ('tip','bonus','incentive')), 0) AS extras_paise,
                count(DISTINCT order_id) FILTER (WHERE type = 'delivery_base') AS deliveries
         FROM wallet_ledger WHERE partner_id = $1 AND created_at >= date_trunc($2, now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata'`,
        [pid, trunc]),
      query(
        `SELECT extract(hour FROM created_at AT TIME ZONE 'Asia/Kolkata')::int AS hour, sum(amount_paise) AS paise
         FROM wallet_ledger WHERE partner_id = $1 AND type IN ('delivery_base','delivery_distance','tip')
           AND created_at >= date_trunc('day', now() AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'Asia/Kolkata'
         GROUP BY 1 ORDER BY 1`, [pid]),
      one(`SELECT COALESCE(sum(amount_paise), 0) AS paise FROM wallet_ledger WHERE partner_id = $1`, [pid]),
      one(`SELECT (date_trunc('week', now() AT TIME ZONE 'Asia/Kolkata') + interval '7 days 18 hours') AT TIME ZONE 'Asia/Kolkata' AS at`),
    ])
    return { range, ...totals, byHour, availableBalancePaise: balance!.paise, nextWeeklyPayoutAt: nextPayout!.at }
  })

  /** Transactions screen: search + filter chips, cursor pagination. */
  app.get('/transactions', async (req) => {
    const q = parse(z.object({
      filter: z.enum(['all', 'earnings', 'payouts', 'bonuses', 'deductions']).default('all'),
      search: z.string().trim().max(40).optional(),
      before: z.coerce.number().int().optional(),   // ledger id cursor
      limit: z.coerce.number().int().min(1).max(100).default(30),
    }), req.query)
    const types: Record<string, string[] | null> = {
      all: null,
      earnings: ['delivery_base', 'delivery_distance', 'tip'],
      payouts: ['payout', 'payout_fee'],
      bonuses: ['bonus', 'incentive'],
      deductions: ['deduction', 'adjustment'],
    }
    const rows = await query(
      `SELECT l.id, l.type, l.amount_paise, l.description, l.created_at, o.order_code, p.utr, p.status AS payout_status
       FROM wallet_ledger l LEFT JOIN orders o ON o.id = l.order_id LEFT JOIN payouts p ON p.id = l.payout_id
       WHERE l.partner_id = $1
         AND ($2::ledger_entry_type[] IS NULL OR l.type = ANY($2))
         AND ($3::text IS NULL OR o.order_code ILIKE '%' || $3 || '%' OR p.utr ILIKE '%' || $3 || '%' OR l.description ILIKE '%' || $3 || '%')
         AND ($4::bigint IS NULL OR l.id < $4)
       ORDER BY l.id DESC LIMIT $5`,
      [partnerId(req), types[q.filter], q.search || null, q.before ?? null, q.limit],
    )
    return { items: rows, nextCursor: rows.length === q.limit ? rows[rows.length - 1].id : null }
  })

  // ---------- Payouts (Bank payout → Instant payout) ----------

  app.get('/payouts', async (req) =>
    query(`SELECT p.*, m.type AS method_type, m.account_last4, m.upi_vpa FROM payouts p JOIN payout_methods m ON m.id = p.payout_method_id
           WHERE p.partner_id = $1 ORDER BY p.requested_at DESC LIMIT 50`, [partnerId(req)]))

  app.post('/payouts/instant', async (req, reply) => {
    const b = parse(z.object({ amountPaise: z.number().int().positive(), payoutMethodId: z.uuid().optional() }), req.body)
    const idem = req.headers['idempotency-key']
    if (typeof idem !== 'string' || idem.length < 8) throw new AppError(400, 'IDEMPOTENCY_KEY_REQUIRED', 'Send an Idempotency-Key header (e.g. a UUID)')
    if (b.amountPaise < config.INSTANT_PAYOUT_MIN_PAISE) throw new AppError(400, 'AMOUNT_TOO_LOW', `Minimum instant payout is ₹${config.INSTANT_PAYOUT_MIN_PAISE / 100}`)
    const pid = partnerId(req)

    const existing = await one(`SELECT * FROM payouts WHERE idempotency_key = $1 AND partner_id = $2`, [idem, pid])
    if (existing) return existing

    const payout = await tx(async (db) => {
      // Lock the partner row so two concurrent payouts can't both pass the balance check.
      await query(`SELECT 1 FROM partners WHERE id = $1 FOR UPDATE`, [pid], db)
      const method = await one<{ id: string }>(
        b.payoutMethodId
          ? `SELECT id FROM payout_methods WHERE id = $2 AND partner_id = $1 AND deleted_at IS NULL AND verification = 'verified'`
          : `SELECT id FROM payout_methods WHERE partner_id = $1 AND is_primary AND deleted_at IS NULL AND verification = 'verified'`,
        b.payoutMethodId ? [pid, b.payoutMethodId] : [pid], db)
      if (!method) throw new AppError(400, 'NO_VERIFIED_METHOD', 'Add and verify a bank account or UPI ID first')
      const fee = config.INSTANT_PAYOUT_FEE_PAISE
      const bal = await one<{ paise: number }>(`SELECT COALESCE(sum(amount_paise), 0) AS paise FROM wallet_ledger WHERE partner_id = $1`, [pid], db)
      if (bal!.paise < b.amountPaise + fee) throw new AppError(400, 'INSUFFICIENT_BALANCE', 'Amount plus fee is more than your available balance')
      const p = await one(
        `INSERT INTO payouts (partner_id, payout_method_id, kind, amount_paise, fee_paise, idempotency_key) VALUES ($1, $2, 'instant', $3, $4, $5) RETURNING *`,
        [pid, method.id, b.amountPaise, fee, idem], db)
      await query(
        `INSERT INTO wallet_ledger (partner_id, type, amount_paise, payout_id, description) VALUES
           ($1, 'payout', $2, $3, 'Instant payout'), ($1, 'payout_fee', $4, $3, 'Instant payout fee')`,
        [pid, -b.amountPaise, p.id, -fee], db)
      return p
    })
    // TODO: enqueue to SQS → payout worker calls the bank/UPI provider and sets status/utr.
    reply.status(201)
    return payout
  })
}
