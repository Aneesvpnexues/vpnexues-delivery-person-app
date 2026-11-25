import { GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'
import { config } from '../config.js'
import { AppError } from '../lib/errors.js'

// Credentials: default provider chain (ECS task role / App Runner instance role / local ~/.aws profile).
// S3_ENDPOINT switches to an S3-compatible store (e.g. Supabase Storage) for non-AWS hosting.
const s3 = new S3Client({
  region: config.AWS_REGION,
  ...(config.S3_ENDPOINT ? { endpoint: config.S3_ENDPOINT, forcePathStyle: config.S3_FORCE_PATH_STYLE } : {}),
})
const sse = config.S3_SSE === 'none' ? undefined : config.S3_SSE

function bucket() {
  if (!config.S3_DOCUMENTS_BUCKET) throw new AppError(503, 'STORAGE_NOT_CONFIGURED', 'Document storage is not configured yet (set S3_DOCUMENTS_BUCKET).')
  return config.S3_DOCUMENTS_BUCKET
}

export const ALLOWED_UPLOAD_TYPES = { 'image/jpeg': 'jpg', 'image/png': 'png', 'application/pdf': 'pdf' } as const
export type UploadContentType = keyof typeof ALLOWED_UPLOAD_TYPES

/**
 * The app uploads files straight to S3 with a short-lived presigned PUT URL,
 * so large images never pass through the API container.
 */
export async function presignUpload(key: string, contentType: UploadContentType) {
  const url = await getSignedUrl(
    s3,
    new PutObjectCommand({ Bucket: bucket(), Key: key, ContentType: contentType, ServerSideEncryption: sse }),
    { expiresIn: config.S3_UPLOAD_URL_TTL_SECONDS },
  )
  return { url, method: 'PUT' as const, headers: { 'Content-Type': contentType, ...(sse ? { 'x-amz-server-side-encryption': sse } : {}) }, key, expiresIn: config.S3_UPLOAD_URL_TTL_SECONDS }
}

export async function presignDownload(key: string, expiresIn = 120) {
  return getSignedUrl(s3, new GetObjectCommand({ Bucket: bucket(), Key: key }), { expiresIn })
}
