// app/src/api/session.tsx

import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { API_URL, api, getTokens, getStoredMe, onSessionLost, setTokens, setStoredMe, showError, type Tokens } from './client'
import { toast } from '../components/toast'
import Phone from '../components/Phone'

/** GET /v1/me */
export type Me = {
  id: string; partner_code: string; full_name: string; phone: string; email: string | null
  status: 'onboarding' | 'active' | 'suspended' | 'deactivated'; kyc_status: 'not_started' | 'in_review' | 'verified' | 'rejected'
  is_online: boolean; language: LangCode; date_of_birth: string | null; blood_group: string | null; address: string | null
  rating: number; referral_code: string; vehicle_type: string; delivery_radius_km: number; partner_since: string
  city: { id: number; name: string }; hub: { id: string; name: string } | null; deliveries: number
}

export type LangCode = 'en' | 'ta' | 'hi' | 'ml' | 'te' | 'kn'
export const LANGS: Record<LangCode, string> = { en: 'English', ta: 'Tamil', hi: 'Hindi', ml: 'Malayalam', te: 'Telugu', kn: 'Kannada' }

/** Sign-up / login waiting for its OTP (kept across reloads of the OTP screen). */
export type PendingOtp = { purpose: 'signup' | 'login'; phone: string; devCode?: string; signup?: Record<string, unknown> }

type Session = {
  status: 'loading' | 'in' | 'out'
  me: Me | null
  refreshMe: () => Promise<Me | null>
  signIn: (t: Tokens) => Promise<Me | null>
  signOut: () => Promise<void>
  pending: PendingOtp | null
  setPending: (p: PendingOtp | null) => void
  online: boolean
  setOnline: (v: boolean) => Promise<boolean>
  lang: string
  setLang: (name: string) => Promise<void>
  trial: boolean
}

const Ctx = createContext<Session>(null as unknown as Session)
export const useSession = () => useContext(Ctx)

const PENDING_KEY = 'vpn.pending'
const readPending = (): PendingOtp | null => { try { return JSON.parse(sessionStorage.getItem(PENDING_KEY) ?? 'null') } catch { return null } }

export function SessionProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<Session['status']>(getTokens() ? 'loading' : 'out')
  const [me, setMeState] = useState<Me | null>(getStoredMe()) // Load from local storage initially
  const [pending, setPendingState] = useState<PendingOtp | null>(readPending)
  const [trial, setTrial] = useState(false)

  // Wrapper to update both state and local storage. Accepts direct value or updater function.
  const setMe = useCallback((m: Me | null | ((prev: Me | null) => Me | null)) => {
    setMeState((prev) => {
      const next = typeof m === 'function' ? m(prev) : m
      setStoredMe(next)
      return next
    })
  }, [])

  /** Bumped on every sign-out so a /v1/me request that was already in flight can't sign the partner back in. */
  const epoch = useRef(0)
  useEffect(() => {
    fetch(API_URL + '/health/ready').then((r) => r.json()).then((h) => setTrial(!!h.trial)).catch(() => {})
  }, [])

  const refreshMe = useCallback(async () => {
    const mine = epoch.current
    try {
      const m = await api<Me>('/v1/me')
      if (mine !== epoch.current || !getTokens()) return null // signed out while this was loading
      setMe(m)
      setStatus('in')
      return m
    } catch (e) {
      if (mine !== epoch.current) return null
      if (!getTokens()) setStatus('out')
      else { setStatus('in'); showError(e) }
      return null
    }
  }, [setMe])

  useEffect(() => { if (getTokens()) void refreshMe() }, [refreshMe])

  useEffect(() => {
    return onSessionLost(() => {
      // Invalidate any in-flight /v1/me request before clearing the session.
      epoch.current += 1
      setMe(null)
      setStatus('out')
      toast('Your session ended. Please log in again.')
    })
  }, [setMe])

  const signIn = useCallback(async (t: Tokens) => {
    setTokens(t)
    return refreshMe()
  }, [refreshMe])

  const signOut = useCallback(async () => {
    const t = getTokens()
    // Sign out on this phone first, right away. Revoking the token on the server can take up to a minute when the
    // free server is asleep, and must never keep the partner stuck on a screen they chose to leave.
    epoch.current += 1
    setTokens(null)
    setMe(null) // This clears state and local storage
    setPendingState(null)
    try { sessionStorage.removeItem(PENDING_KEY) } catch { /* ignore */ }
    setStatus('out')
    if (t) void api('/v1/auth/logout', { body: { refreshToken: t.refreshToken }, auth: false }).catch(() => {})
  }, [setMe])

  const setPending = useCallback((p: PendingOtp | null) => {
    setPendingState(p)
    try { p ? sessionStorage.setItem(PENDING_KEY, JSON.stringify(p)) : sessionStorage.removeItem(PENDING_KEY) } catch { /* ignore */ }
  }, [])

  const setOnline = useCallback(async (v: boolean) => {
    const prev = me
    if (me) setMe({ ...me, is_online: v })
    try {
      await api('/v1/me/online', { method: 'PUT', body: { online: v } })
      return true
    } catch (e) {
      setMe(prev)
      showError(e)
      return false
    }
  }, [me, setMe])

  const setLang = useCallback(async (name: string) => {
    const code = (Object.keys(LANGS) as LangCode[]).find((k) => LANGS[k] === name)
    if (!code) return
    await api('/v1/me', { method: 'PATCH', body: { language: code } })
    setMe((m) => (m ? { ...m, language: code } : m))
  }, [setMe])

  return (
    <Ctx.Provider value={{ status, me, refreshMe, signIn, signOut, pending, setPending,
      online: !!me?.is_online, setOnline, lang: LANGS[me?.language ?? 'en'], setLang, trial }}>
      {children}
    </Ctx.Provider>
  )
}

/** Wraps screens that need a signed-in partner. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { status } = useSession()
  if (status === 'out') return <Navigate to="/login" replace />
  if (status === 'loading') return <Loading />
  return <>{children}</>
}

export function Loading({ label = 'Loading…' }: { label?: string }) {
  return (
    <Phone>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14 }}>
        <span className="spin" style={{ width: 34, height: 34, borderRadius: 17, border: '3px solid #dfe5dd', borderTopColor: '#095334' }} />
        <p style={{ font: '600 14px/20px Inter', color: '#5e6b62' }}>{label}</p>
      </div>
    </Phone>
  )
}

/** Load JSON from the API. `path = null` skips loading. */
export function useApi<T>(path: string | null) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<unknown>(null)
  const [loading, setLoading] = useState(!!path)
  const seq = useRef(0)
  const load = useCallback(async () => {
    if (!path) return
    const n = ++seq.current
    setLoading(true)
    try {
      const d = await api<T>(path)
      if (n === seq.current) { setData(d); setError(null) }
    } catch (e) {
      if (n === seq.current) { setError(e); showError(e) }
    } finally {
      if (n === seq.current) setLoading(false)
    }
  }, [path])
  useEffect(() => { void load() }, [load])
  return { data, error, loading, reload: load, setData }
}

// ---------------- formatting ----------------
/** 8500 → "₹85", 124050 → "₹1,240.50"; `fixed` always shows paise. */
export function inr(paise: number | null | undefined, fixed = false) {
  const r = (paise ?? 0) / 100
  const s = Math.abs(r).toLocaleString('en-IN', { minimumFractionDigits: fixed || r % 1 ? 2 : 0, maximumFractionDigits: 2 })
  return (r < 0 ? '–₹' : '₹') + s
}
export const signedInr = (paise: number) => (paise >= 0 ? '+' : '') + inr(paise)
export const initials = (name?: string | null) => (name ?? '').split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]!.toUpperCase()).join('') || '··'
export const firstName = (name?: string | null) => (name ?? '').split(/\s+/)[0] ?? ''
const IST = 'Asia/Kolkata'
export const time = (iso?: string | null) => (iso ? new Date(iso).toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit', timeZone: IST }) : '')
export const date = (iso?: string | null, opts: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short' }) =>
  iso ? new Date(iso).toLocaleDateString('en-IN', { ...opts, timeZone: IST }) : ''
export const greeting = () => {
  const h = Number(new Date().toLocaleString('en-IN', { hour: 'numeric', hour12: false, timeZone: IST }))
  return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening'
}
export const maskPhone = (e164?: string | null) => {
  const d = (e164 ?? '').replace(/^\+91/, '')
  return d.length === 10 ? `+91 ${d.slice(0, 5)} •••${d.slice(-2)}` : e164 ?? ''
}