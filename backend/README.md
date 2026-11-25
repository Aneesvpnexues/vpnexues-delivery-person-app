# VP Nexues Partner API

Backend for the VP Nexues delivery-partner app.
**Node 22 · TypeScript · Fastify 5 · PostgreSQL 16**, packaged as one Docker image for **AWS App Runner or ECS Fargate**, with **RDS PostgreSQL**, **S3** for documents and **SNS** for OTP SMS.

## Run locally

```bash
npm install
cp .env.example .env
npm run dev                 # http://localhost:4000  (auto-reloads)
```

The API boots **without a database**. `/health` works; data endpoints answer `503 DB_NOT_CONFIGURED` until `DATABASE_URL` is set.

### When you want a database

```bash
docker compose up -d db                      # Postgres 16 on localhost:5432
# in .env: DATABASE_URL=postgres://vpnexues:vpnexues@localhost:5432/vpnexues
npm run migrate                              # apply migrations/
npm run migrate -- --status                  # see applied / pending
```

## Migrations

Plain SQL in `migrations/`, applied in filename order by `scripts/migrate.ts`:
- **Forward-only.** Each file runs in its own transaction.
- **Locked.** An advisory lock stops two deploys migrating at the same time.
- **Checksummed.** Never edit a file that has already run; add `0010_...sql` instead.

| File | Contents |
|---|---|
| 0001 | extensions (pgcrypto, citext), enum types, `set_updated_at()` trigger |
| 0002 | `cities`, `hubs` (radius options, areas), `hub_change_requests` |
| 0003 | `partners`, `partner_settings`, `otp_codes`, `sessions`, `device_tokens` |
| 0004 | `partner_documents` (S3 keys, masked numbers), `document_events`, `vehicles` |
| 0005 | `payout_methods`: bank (account number AES-encrypted, only last 4 shown) or UPI |
| 0006 | `orders`, `order_crates` (QR per crate), `order_events` (timeline) |
| 0007 | `payouts`, `wallet_ledger`: append-only; balance = sum; DB blocks UPDATE/DELETE |
| 0008 | `notifications`, `support_tickets` / `support_messages`, `emergency_contacts`, `sos_incidents`, `app_ratings` |
| 0009 | reference data: Chennai / Bengaluru / Coimbatore, Anna Nagar Hub |
| 0010 | Row Level Security on every table (locks Supabase's public API out) |

Money is always integer **paise**. Times are `timestamptz`; reports use `Asia/Kolkata`.

## API reference (`/v1`)

All responses are JSON. Errors are always `{ "error": { "code", "message", "details?" } }`, and the app should branch on `code`.
Authenticated routes need `Authorization: Bearer <accessToken>`. The access token lasts 15 min; renew it with `/auth/refresh`, which rotates the refresh token.

| Area | Endpoints |
|---|---|
| Health | `GET /health` (liveness) · `GET /health/ready` (checks DB) |
| Reference | `GET /cities` · `GET /cities/:id/hubs` |
| Sign up | `POST /auth/signup/start` → OTP · `POST /auth/signup/verify` → account + tokens · `POST /auth/password` |
| Login | `POST /auth/login` (phone + password) · `POST /auth/login/otp/start` · `POST /auth/login/otp/verify` |
| Session | `POST /auth/refresh` · `POST /auth/logout` · `POST /auth/password/reset/start` · `POST /auth/password/reset/verify` |
| Profile | `GET /me` · `PATCH /me` · `PUT /me/online` · `GET/PATCH /me/settings` · `POST /me/devices` |
| Zone | `GET /me/zone` · `PUT /me/zone/radius` · `POST /me/zone/change-request` |
| Documents | `GET /documents` · `POST /documents/:type/upload-url` (S3 presigned PUT) · `POST /documents/:type/submit` |
| Vehicle | `GET /vehicle` · `PUT /vehicle` |
| Payout methods | `GET /payout-methods` · `POST /payout-methods` · `PUT /payout-methods/:id/primary` · `DELETE /payout-methods/:id` |
| Earnings | `GET /earnings/summary?range=today\|week\|month\|year` · `GET /transactions?filter=&search=&before=` |
| Payouts | `GET /payouts` · `POST /payouts/instant` (needs `Idempotency-Key` header) |
| Orders | `GET /orders?tab=active\|upcoming\|completed` · `GET /orders/:id` |
| Delivery flow | `POST /orders/:id/accept` → `/at-pickup` → `/crates/scan` (each QR) → `/pickup` → `/arrive` → `/deliver` {code} → `/feedback` |
| Notifications | `GET /notifications?category=` · `POST /notifications/read-all` · `POST /notifications/:id/read` |
| Support | `GET/POST /support/tickets` · `GET/POST /support/tickets/:id/messages` |
| Safety | `POST /sos` · `GET/POST /emergency-contacts` · `DELETE /emergency-contacts/:id` |
| Other | `POST /app-rating` |

In development (`OTP_DEV_ECHO=true`), OTP endpoints return `devCode`, so the app can show "Demo code: …", and the SMS is only logged.

### Security built in
- **Codes and tokens:** OTPs, refresh tokens and delivery hand-over codes are stored only as SHA-256 hashes.
  - Wrong OTPs are counted and lock after 5 attempts.
  - Refresh-token reuse revokes every session for that partner.
- **Passwords:** bcrypt (cost 12). Unknown phone and wrong password take the same time and give the same error.
- **Personal data:** bank account numbers are encrypted with AES-256-GCM, and Aadhaar/PAN are stored masked. Customer phone numbers are never sent to partners.
- **Ownership:** every query is scoped to the signed-in partner, and S3 keys must be under the partner's own prefix.
- **Abuse protection:** rate limits (global, plus stricter ones on OTP and login), Helmet headers, a CORS allow-list, and secrets redacted from logs.
- **Money:**
  - Delivery earnings are credited in the same transaction that marks the order delivered.
  - The ledger can't be edited.
  - Instant payouts lock the partner row and need an idempotency key, so the same request never pays twice.

## Trial hosting: Render + Supabase

A low-cost setup for trying the app before moving to AWS. It uses the same code, with different settings.

| Piece | Service |
|---|---|
| API | Render web service (`render.yaml`) |
| Database | Supabase Postgres (Session pooler connection) |
| Document files | Supabase Storage through its S3-compatible endpoint |
| OTP | `TRIAL_MODE=true`: codes come back in the API response until Firebase/SMS is set up |

1. **Supabase:** create a project in the **Singapore** region and save the database password. Then collect:
   - **Connect → Session pooler** URI. Use this one: the direct URI is IPv6-only, and Render can't reach IPv6.
   - **Database settings → SSL → Download certificate.** This becomes `DB_SSL_CA`.
   - **Storage:** create a **private** bucket called `partner-documents`. Then under **S3 access keys** make a new key, and note the endpoint and region.
2. **Migrate from your PC:** `DATABASE_URL="<session pooler URI>" DB_SSL_CA="$(cat prod-ca-2021.crt)" npm run migrate`
3. **Render:** push this repo to GitHub, then go to **New → Blueprint** and pick the repo. Fill in the values it asks for (`DATABASE_URL`, `DB_SSL_CA`, `S3_ENDPOINT`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`). `JWT_SECRET` and `DATA_ENCRYPTION_KEY` are generated by Render.
4. **Check:** open `https://<service>.onrender.com/health/ready`. It should report `"database":"up"`.

Notes:
- **Free plan sleeps:** a Render free service sleeps after about 15 minutes idle, and the first request then takes about a minute.
- **Row-level security:** migration `0010` turns it on for every table, so Supabase's public API (anon key) can't read anything. The backend connects as the owner and isn't affected.
- **Don't change `DATA_ENCRYPTION_KEY` after partners add bank accounts.** Those account numbers are encrypted with it.
- **Moving to AWS later:** dump and restore the database, copy the bucket, then switch the settings to the AWS ones above.

## AWS deployment

```
App (Capacitor) ──HTTPS──► App Runner  ─or─  ALB → ECS Fargate (this image, ARM64)
                                  │
         ┌────────────────────────┼─────────────────────────┐
   RDS PostgreSQL 16         S3 documents bucket        SNS (OTP SMS)
   (private subnet)          (SSE-KMS, presigned PUT)
                                  │
        Secrets Manager → DATABASE_URL, JWT_SECRET, DATA_ENCRYPTION_KEY
        CloudWatch Logs ← JSON logs on stdout
```

Why the app is easy to move to AWS:
- **Config:** everything comes from environment variables, so there are no code changes between local and AWS. `src/config.ts` refuses to start in production with dev secrets or with `OTP_DEV_ECHO` on.
- **No stored AWS keys:** credentials come from the IAM task role through the SDK's default chain.
- **Health checks:** `/health` and `/health/ready` work with ALB target groups and App Runner.
- **Graceful shutdown:** `SIGTERM` drains requests, then closes the DB pool. `tini` is PID 1.
- **Request tracing:** the request ID comes from `X-Amzn-Trace-Id`, so logs line up with ALB/X-Ray.
- **RDS TLS:** the image bundles the RDS CA. Set `DB_SSL=true`.

### First deploy (checklist)
1. **ECR:** `docker build -t vpnexues-api . && docker tag … && docker push …`
2. **RDS:** PostgreSQL 16 in private subnets. Put `DATABASE_URL` in Secrets Manager under `vpnexues/prod/api`, along with `JWT_SECRET` (`openssl rand -base64 48`) and `DATA_ENCRYPTION_KEY` (`openssl rand -base64 32`).
3. **S3:** a private bucket `vpnexues-partner-documents-prod` with SSE-KMS. Apply the CORS rules in `deploy/aws/s3-documents-cors.json`.
4. **SNS SMS:** for India, register the sender ID and DLT template in AWS End User Messaging, then request a production spend limit.
5. **IAM:** create the task role from `deploy/aws/task-role-policy.json`. The execution role needs `secretsmanager:GetSecretValue` on the secret.
6. **Migrate:** run the image once with the command `node dist/scripts/migrate.js` (as a one-off ECS task, or App Runner pre-deploy).
7. **Service:** register `deploy/aws/ecs-task-definition.json` (fill in `<ACCOUNT_ID>`/`<TAG>`) and create a Fargate service behind an ALB. App Runner also works: port 4000, health path `/health`.

### Still to plug in (marked `TODO` in code)
- **Payment provider:** penny-drop verification for bank/UPI, and the payout worker that sends transfers and sets `utr`. Both should run through SQS.
- **Notifications:** push via FCM/APNs (Amazon SNS mobile push), using the tokens from `POST /me/devices`.
- **SOS fan-out:** alert the safety team and SMS the emergency contact.
- **Support desk:** connect support tickets to a desk tool.
- **Ops/admin API:** create and assign orders, review documents, activate partners. Until it exists, these are done directly in SQL.
- **Rate-limit store:** switch to Redis (ElastiCache) once you run more than one container.
