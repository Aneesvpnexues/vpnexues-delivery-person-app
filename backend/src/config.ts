import { z } from 'zod'

/**
 * All configuration comes from environment variables (12-factor), so the same image runs
 * locally, in staging and on AWS. On AWS, plain values go in the ECS task definition /
 * App Runner config and secrets (DATABASE_URL, JWT_SECRET, DATA_ENCRYPTION_KEY) are injected
 * from AWS Secrets Manager — the code never talks to Secrets Manager directly.
 */
const bool = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1')

// Built-in values for local development only. Production refuses to start with either of them.
// The data key is derived from readable text so no key-shaped literal sits in the repo.
const DEV_JWT_SECRET = 'dev-only-secret-change-me-dev-only-secret'
const DEV_DATA_KEY = Buffer.from('dev-only-key-dev-only-key-32byte').toString('base64')

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().default(4000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  CORS_ORIGINS: z.string().default('http://localhost:5173,http://localhost:5199,http://localhost:5200,capacitor://localhost,https://localhost'),

  // PostgreSQL (Amazon RDS / Aurora). Optional so the API can boot before a DB exists.
  DATABASE_URL: z.string().url().optional(),
  DB_SSL: z.enum(['true', 'false', '1', '0', 'no-verify']).default('false'), // see src/lib/dbSsl.ts
  DB_SSL_CA: z.string().optional(),       // PEM of the DB's CA (Supabase); newlines may be written as \n
  DB_POOL_MAX: z.coerce.number().int().default(10),

  // Auth
  JWT_SECRET: z.string().min(32).default(DEV_JWT_SECRET),
  ACCESS_TOKEN_TTL: z.string().default('15m'),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().default(30),
  OTP_TTL_SECONDS: z.coerce.number().int().default(300),
  OTP_MAX_ATTEMPTS: z.coerce.number().int().default(5),
  OTP_DEV_ECHO: bool.default(true),       // return the OTP in the API response (never in production)
  TRIAL_MODE: bool.default(false),        // hosted trial (Render/Supabase): allows OTP_DEV_ECHO with NODE_ENV=production

  // 32-byte key, base64. Encrypts bank account numbers at rest.
  DATA_ENCRYPTION_KEY: z.string().default(DEV_DATA_KEY),

  // AWS — credentials come from the default provider chain (ECS task role / App Runner instance role).
  AWS_REGION: z.string().default('ap-south-1'),
  S3_DOCUMENTS_BUCKET: z.string().optional(),
  // Leave unset on AWS. For an S3-compatible store (Supabase Storage, R2, MinIO) set the endpoint;
  // credentials then come from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.
  S3_ENDPOINT: z.string().url().optional(),
  S3_FORCE_PATH_STYLE: bool.default(false),
  S3_SSE: z.enum(['aws:kms', 'AES256', 'none']).default('aws:kms'),
  S3_UPLOAD_URL_TTL_SECONDS: z.coerce.number().int().default(300),
  SMS_PROVIDER: z.enum(['log', 'sns']).default('log'),
  SMS_SENDER_ID: z.string().default('VPNXUS'),

  // Business rules
  INSTANT_PAYOUT_FEE_PAISE: z.coerce.number().int().default(1000),
  INSTANT_PAYOUT_MIN_PAISE: z.coerce.number().int().default(10000),
})

const parsed = schema.safeParse(process.env)
if (!parsed.success) {
  console.error('Invalid environment configuration:\n' + parsed.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`).join('\n'))
  process.exit(1)
}

export const config = parsed.data
export const isProd = config.NODE_ENV === 'production'

if (isProd) {
  const problems: string[] = []
  if (config.JWT_SECRET === DEV_JWT_SECRET) problems.push('JWT_SECRET must be set')
  if (config.DATA_ENCRYPTION_KEY === DEV_DATA_KEY) problems.push('DATA_ENCRYPTION_KEY must be set')
  if (config.OTP_DEV_ECHO && !config.TRIAL_MODE) problems.push('OTP_DEV_ECHO must be false (or set TRIAL_MODE=true for a hosted trial)')
  if (!config.DATABASE_URL) problems.push('DATABASE_URL must be set')
  if (problems.length) {
    console.error('Refusing to start in production:\n  ' + problems.join('\n  '))
    process.exit(1)
  }
}

if (isProd && config.TRIAL_MODE) {
  console.warn('TRIAL_MODE is on: OTP codes are returned in API responses. Do not use with real partners.')
}
