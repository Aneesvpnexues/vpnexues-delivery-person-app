import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const DB_STUB = new URL('./inMemoryDb.js', import.meta.url).href
const SMS_STUB = new URL('./noopSms.js', import.meta.url).href

/**
 * Test-only ESM loader.
 *
 * - Redirects the auth module's database import to an in-memory fake.
 * - Redirects its SMS import to a no-op.
 * - Maps the source's `.js` specifiers to the actual `.ts` files so Node's
 *   built-in type stripping can load the same code that `tsx`/`tsc` use.
 *
 * Production startup never loads this file; no database or Supabase settings
 * are read or changed.
 */
export async function resolve(specifier, context, nextResolve) {
  const parent = context.parentURL ?? ''
  const fromSrc = parent.includes('/src/')

  if (fromSrc && specifier.endsWith('/db.js')) return nextResolve(DB_STUB, context)
  if (fromSrc && specifier.endsWith('/sms.js')) return nextResolve(SMS_STUB, context)

  if (fromSrc && specifier.endsWith('.js')) {
    const tsUrl = new URL(new URL(specifier, parent).href.replace(/\.js$/, '.ts'))
    if (existsSync(fileURLToPath(tsUrl))) return nextResolve(tsUrl.href, context)
  }

  return nextResolve(specifier, context)
}
