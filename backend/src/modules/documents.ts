import type { FastifyInstance } from 'fastify'
import { randomUUID } from 'node:crypto'
import { z } from 'zod'
import { one, query, tx } from '../db.js'
import { ALLOWED_UPLOAD_TYPES, presignUpload, type UploadContentType } from '../aws/s3.js'
import { AppError, parse } from '../lib/errors.js'
import { partnerId } from '../lib/auth.js'

const docTypes = ['aadhaar', 'pan', 'driving_licence', 'vehicle_rc', 'vehicle_insurance', 'pucc', 'police_verification', 'selfie'] as const
export const REQUIRED_DOCS: readonly string[] = ['aadhaar', 'pan', 'driving_licence', 'vehicle_rc', 'vehicle_insurance', 'selfie']

/** Mask anything but the last 4 characters: "123456784821" → "XXXX XXXX 4821". */
const mask = (n: string) => {
  const s = n.replace(/\s/g, '')
  return ('X'.repeat(Math.max(0, s.length - 4)) + s.slice(-4)).replace(/(.{4})(?=.)/g, '$1 ')
}

/** Documents, government ID and vehicle — /v1/documents and /v1/vehicle. */
export default async function documentRoutes(app: FastifyInstance) {
  app.addHook('preHandler', app.authenticate)

  /** My documents / Verification dashboard: every document + overall progress. */
  app.get('/documents', async (req) => {
    const docs = await query(
      `SELECT id, type, status, number_masked, source, valid_until, rejection_reason, submitted_at, reviewed_at,
              (valid_until IS NOT NULL AND valid_until < current_date + 30) AS expiring_soon
       FROM partner_documents WHERE partner_id = $1 ORDER BY type`,
      [partnerId(req)],
    )
    const verified = docs.filter((d) => d.status === 'verified').length
    return { documents: docs, verifiedCount: verified, requiredCount: REQUIRED_DOCS.length, missing: REQUIRED_DOCS.filter((t) => !docs.some((d) => d.type === t)) }
  })

  /**
   * Step 1 of an upload: get a presigned S3 PUT URL. The app PUTs the file directly to S3,
   * then calls POST /documents/:type/submit with the returned key(s).
   */
  app.post('/documents/:type/upload-url', async (req) => {
    const { type } = parse(z.object({ type: z.enum(docTypes) }), req.params)
    const { contentType, side } = parse(z.object({
      contentType: z.enum(Object.keys(ALLOWED_UPLOAD_TYPES) as [UploadContentType, ...UploadContentType[]]),
      side: z.enum(['front', 'back', 'single']).default('single'),
    }), req.body)
    const key = `partners/${partnerId(req)}/documents/${type}/${side}-${randomUUID()}.${ALLOWED_UPLOAD_TYPES[contentType]}`
    return presignUpload(key, contentType)
  })

  /** Step 2: submit the document for review (Upload / Take buttons, Government ID → Submit). */
  app.post('/documents/:type/submit', async (req, reply) => {
    const { type } = parse(z.object({ type: z.enum(docTypes) }), req.params)
    const b = parse(z.object({
      s3Keys: z.array(z.string().min(5)).min(1).max(2),
      number: z.string().trim().min(4).max(30).optional(),
      validUntil: z.iso.date().optional(),
      consent: z.literal(true, { message: 'Consent is required for identity verification' }).optional(),
    }), req.body)
    const pid = partnerId(req)
    // Keys must be inside this partner's own prefix — stops one partner attaching another's files.
    if (b.s3Keys.some((k) => !k.startsWith(`partners/${pid}/documents/${type}/`))) throw new AppError(400, 'BAD_S3_KEY', 'Upload the file with an upload URL first')
    if ((type === 'aadhaar' || type === 'pan') && !b.consent) throw new AppError(400, 'CONSENT_REQUIRED', 'Consent is required for e-KYC')

    const doc = await tx(async (db) => {
      const d = await one(
        `INSERT INTO partner_documents (partner_id, type, status, number_masked, s3_keys, valid_until, submitted_at, rejection_reason)
         VALUES ($1, $2, 'in_review', $3, $4, $5, now(), NULL)
         ON CONFLICT (partner_id, type) DO UPDATE SET status = 'in_review', number_masked = EXCLUDED.number_masked,
           s3_keys = EXCLUDED.s3_keys, valid_until = EXCLUDED.valid_until, submitted_at = now(), rejection_reason = NULL, reviewed_at = NULL
         RETURNING id, type, status, number_masked, valid_until, submitted_at`,
        [pid, type, b.number ? mask(b.number) : null, b.s3Keys, b.validUntil ?? null], db,
      )
      await query(`INSERT INTO document_events (document_id, status) VALUES ($1, 'in_review')`, [d.id], db)
      await query(`UPDATE partners SET kyc_status = 'in_review' WHERE id = $1 AND kyc_status = 'not_started'`, [pid], db)
      return d
    })
    reply.status(201)
    return doc
  })

  /** My vehicle screen. */
  app.get('/vehicle', async (req) => (await one(`SELECT * FROM vehicles WHERE partner_id = $1`, [partnerId(req)])) ?? null)

  app.put('/vehicle', async (req) => {
    const b = parse(z.object({
      type: z.enum(['motorbike', 'scooter', 'electric_scooter', 'bicycle']),
      registrationNumber: z.string().trim().toUpperCase().regex(/^[A-Z]{2}\s?\d{1,2}\s?[A-Z]{0,3}\s?\d{1,4}$/, 'Enter a valid registration number'),
      makeModel: z.string().trim().max(60).optional(),
      year: z.number().int().min(1990).max(2100).optional(),
      colour: z.string().trim().max(30).optional(),
      fuel: z.enum(['petrol', 'electric', 'cng', 'none']).optional(),
    }), req.body)
    return one(
      `INSERT INTO vehicles (partner_id, type, registration_number, make_model, year, colour, fuel) VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (partner_id) DO UPDATE SET type = EXCLUDED.type, registration_number = EXCLUDED.registration_number,
         make_model = EXCLUDED.make_model, year = EXCLUDED.year, colour = EXCLUDED.colour, fuel = EXCLUDED.fuel
       RETURNING *`,
      [partnerId(req), b.type, b.registrationNumber, b.makeModel ?? null, b.year ?? null, b.colour ?? null, b.fuel ?? null],
    )
  })
}
