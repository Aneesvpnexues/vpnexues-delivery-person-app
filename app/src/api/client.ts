import { toast } from '../components/toast'

/** Backend base URL. Override at build time with VITE_API_URL (e.g. a local backend). */
export const API_URL = ((import.meta.env.VITE_API_URL as string | undefined) ?? 'https://vpnexues-api-3gsk.onrender.com').replace(/\/$/, '')

export type Tokens = { accessToken: string; refreshToken: string }

/** Error from the API, carrying the backend's stable error code (see API docs). */
export class ApiError extends Error {
  status: number
  code: string
  details?: { field: string; message: string }[]
  constructor(status: number, code: string, message: string, details?: { field: string; message: string }[]) {
    super(message)
    this.status = status
    this.code = code
    this.details = details
  }
}

// ---------------- token storage ----------------
// localStorage persists inside the Capacitor WebView. Move to @capacitor/preferences or the
// Android Keystore before a public release.
const KEY = 'vpn.session'
let tokens: Tokens | null = (() => {
  try { return JSON.parse(localStorage.getItem(KEY) ?? 'null') } catch { return null }
})()

export const getTokens = () => tokens
export function setTokens(t: Tokens | null) {
  tokens = t
  try { t ? localStorage.setItem(KEY, JSON.stringify(t)) : localStorage.removeItem(KEY) } catch { /* storage unavailable */ }
}

const lostListeners = new Set<() => void>()
/** Called when the session can't be renewed (refresh token expired or revoked). */
export const onSessionLost = (fn: () => void) => { lostListeners.add(fn); return () => { lostListeners.delete(fn) } }

// ---------------- requests ----------------
type Opts = { method?: string; body?: unknown; auth?: boolean; headers?: Record<string, string> }

let wakeNotified = false
async function send(path: string, o: Opts, access?: string) {
  const ctrl = new AbortController()
  const timeout = setTimeout(() => ctrl.abort(), 75_000) // a sleeping free Render instance takes ~50 s to wake
  const slow = setTimeout(() => { if (!wakeNotified) { wakeNotified = true; toast('Waking up the server… this can take up to a minute.') } }, 4_000)
  try {
    return await fetch(API_URL + path, {
      method: o.method ?? (o.body === undefined ? 'GET' : 'POST'),
      headers: {
        ...(o.body !== undefined ? { 'content-type': 'application/json' } : {}),
        ...(access ? { authorization: `Bearer ${access}` } : {}),
        ...o.headers,
      },
      body: o.body !== undefined ? JSON.stringify(o.body) : undefined,
      signal: ctrl.signal,
    })
  } catch {
    throw new ApiError(0, 'NETWORK', 'Can’t reach the server. Check your internet connection and try again.')
  } finally {
    clearTimeout(timeout)
    clearTimeout(slow)
  }
}

let refreshing: Promise<boolean> | null = null
/** Swap the refresh token for a new pair. Concurrent callers share one request. */
function refresh(): Promise<boolean> {
  if (!tokens?.refreshToken) return Promise.resolve(false)
  refreshing ??= (async () => {
    try {
      const r = await send('/v1/auth/refresh', { body: { refreshToken: tokens!.refreshToken } })
      if (!r.ok) return false
      const t = await r.json()
      setTokens({ accessToken: t.accessToken, refreshToken: t.refreshToken })
      return true
    } catch {
      return false
    } finally {
      refreshing = null
    }
  })()
  return refreshing
}

export async function api<T = any>(path: string, o: Opts = {}): Promise<T> {
  const auth = o.auth ?? true
  let res = await send(path, o, auth ? tokens?.accessToken : undefined)
  if (res.status === 401 && auth && tokens) {
    if (await refresh()) {
      res = await send(path, o, tokens?.accessToken)
    } else {
      setTokens(null)
      lostListeners.forEach((fn) => fn())
    }
  }
  const data = res.status === 204 ? null : await res.json().catch(() => null)
  if (!res.ok) {
    const e = data?.error
    throw new ApiError(res.status, e?.code ?? 'HTTP_' + res.status, e?.details?.[0]?.message ?? e?.message ?? 'Something went wrong. Please try again.', e?.details)
  }
  return data as T
}

/** Show an API error to the partner. */
export const showError = (e: unknown) => toast(e instanceof ApiError ? e.message : 'Something went wrong. Please try again.')
