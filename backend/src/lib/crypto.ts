import { createCipheriv, createDecipheriv, createHash, randomBytes, randomInt, timingSafeEqual } from 'node:crypto'
import { config } from '../config.js'

export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex')

/** Constant-time compare of two hex hashes. */
export function sameHash(a: string, b: string) {
  const x = Buffer.from(a, 'hex')
  const y = Buffer.from(b, 'hex')
  return x.length === y.length && timingSafeEqual(x, y)
}

export const numericCode = (digits: number) => Array.from({ length: digits }, () => randomInt(0, 10)).join('')
export const opaqueToken = () => randomBytes(32).toString('base64url')

const key = Buffer.from(config.DATA_ENCRYPTION_KEY, 'base64')
if (key.length !== 32) throw new Error('DATA_ENCRYPTION_KEY must be 32 bytes, base64-encoded')

/** AES-256-GCM. Output: base64(iv | tag | ciphertext). Swap for AWS KMS envelope encryption later if needed. */
export function encrypt(plain: string): string {
  const iv = randomBytes(12)
  const c = createCipheriv('aes-256-gcm', key, iv)
  const enc = Buffer.concat([c.update(plain, 'utf8'), c.final()])
  return Buffer.concat([iv, c.getAuthTag(), enc]).toString('base64')
}

export function decrypt(blob: string): string {
  const b = Buffer.from(blob, 'base64')
  const d = createDecipheriv('aes-256-gcm', key, b.subarray(0, 12))
  d.setAuthTag(b.subarray(12, 28))
  return Buffer.concat([d.update(b.subarray(28)), d.final()]).toString('utf8')
}
