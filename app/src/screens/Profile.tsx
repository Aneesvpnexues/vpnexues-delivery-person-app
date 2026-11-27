import { useEffect, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { Activity, Bike, Camera, Check, ChevronRight, File, Globe, Landmark, LogOut, Mail, Map, MapPin, MessageCircle, Moon, Navigation, Shield, SlidersHorizontal, Star, TriangleAlert, User, Users, Volume1, Wallet, Zap, type LucideIcon } from 'lucide-react'
import { BottomNav, Box, Btn, C, Field, Header, Ic, Modal, P, Pill, Screen, T, Tile, Toggle, card, pill, toast } from '../components/kit'
import { addressError, dobError, emailError } from '../lib/validate'
import { api, showError } from '../api/client'
import { LANGS, date, initials, maskPhone, useApi, useSession, type LangCode } from '../api/session'
import type { DocumentsResponse, PayoutMethod, Vehicle } from '../api/types'
import { avatarBg } from './OrderFlow'

const sec = (y: number, label: string) => <T x={20} y={y} s={11} wt={700} lh={15.4} c={C.accent} ls={1.2}>{label}</T>
const chev = <Ic icon={ChevronRight} s={16} c="#8a988f" />

type Row = { icon: LucideIcon; title: string; sub?: string; right?: ReactNode; go?: () => void; tile?: string; ic?: string }
function Rows({ y, h, rows, ts = 36 }: { y: number; h: number; rows: Row[]; ts?: number }) {
  return (
    <div style={{ position: 'absolute', left: 20, top: y, width: 372, padding: '0 16px', ...card }}>
      {rows.map((r, i) => (
        <div key={r.title} onClick={r.go} role={r.go ? 'button' : undefined}
          style={{ display: 'flex', alignItems: 'center', gap: 15, height: h, borderTop: i ? `1px solid ${C.tint5}` : 0, cursor: r.go ? 'pointer' : undefined }}>
          <Tile s={ts} bg={r.tile} icon={r.icon} c={r.ic} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <p style={{ font: '700 15px/21px Inter', color: C.ink, whiteSpace: 'nowrap' }}>{r.title}</p>
            {r.sub && <p style={{ font: '400 12px/16.8px Inter', color: C.muted, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.sub}</p>}
          </div>
          {r.right}
        </div>
      ))}
    </div>
  )
}
const val = (t: string) => <span style={{ font: '400 12px/17px Inter', color: C.muted, marginRight: 2, whiteSpace: 'nowrap', maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis' }}>{t}</span>
const KYC: Record<string, { label: string; color: string }> = {
  verified: { label: 'KYC verified', color: '#dfee91' }, in_review: { label: 'KYC in review', color: '#ffe08a' },
  not_started: { label: 'KYC not started', color: '#ffd0c8' }, rejected: { label: 'KYC needs attention', color: '#ffd0c8' },
}

export function Profile() {
  const nav = useNavigate()
  const { me, lang, signOut } = useSession()
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const methods = useApi<PayoutMethod[]>('/v1/payout-methods')
  const vehicle = useApi<Vehicle | null>('/v1/vehicle')
  const [out, setOut] = useState(false)
  const go = (id: string) => () => nav(P(id))
  const primary = methods.data?.find((m) => m.is_primary)
  const expiring = docs.data?.documents.filter((d) => d.expiring_soon).length ?? 0
  const missing = docs.data?.missing.length ?? 0
  const kyc = KYC[me?.kyc_status ?? 'not_started']
  return (
    <Screen>
      <Box x={0} y={0} w={412} h={289} r="0 0 36px 36px" bg="linear-gradient(125deg,#083f2a 0%,#1f7945 100%)" style={{ overflow: 'hidden' }}>
        <div style={{ position: 'absolute', left: 300, top: 40, width: 90, height: 130, borderRadius: '50%', background: 'rgba(120,180,60,.22)', transform: 'rotate(25deg)' }} />
      </Box>
      <T x={20} y={63} s={20} wt={700} lh={28} c="#fff">Profile</T>
      <Box onClick={go('1:2934')} x={344} y={52} w={48} h={48} r={24} bg="rgba(255,255,255,.14)"><Ic icon={SlidersHorizontal} x={15.5} y={15.5} s={17} c="#fff" /></Box>
      <Box x={20} y={115} w={72} h={72} r={36} bg={avatarBg} border="3px solid #9cc42c" style={{ color: '#fff', font: '700 22px/66px Inter', textAlign: 'center' }}>{initials(me?.full_name)}</Box>
      {me?.kyc_status === 'verified' && <Box x={71} y={163} w={22} h={22} r={11} bg="#9cc42c" border="2px solid #1a6a3f"><Ic icon={Check} x={3} y={3} s={12} sw={2.2} /></Box>}
      <T x={106} y={112} w={290} s={22} wt={700} lh={30} c="#fff" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{me?.full_name ?? ''}</T>
      <T x={106} y={141} w={290} s={12} lh={16.8} c="#dfeee0">{`Partner ID ${me?.partner_code ?? ''} · ${me?.hub?.name ?? me?.city.name ?? ''}`}</T>
      <Pill x={106} y={164} label={kyc.label} bg="rgba(255,255,255,.13)" color={kyc.color} />
      {[[me ? me.rating.toFixed(1) : '–', 'Rating'], [me ? me.deliveries.toLocaleString('en-IN') : '–', 'Deliveries'], [me ? date(me.partner_since, { month: 'short', year: '2-digit' }).replace(' ', ' ’') : '–', 'Partner since']].map(([a, b], i) => (
        <Box key={b} x={20 + i * 127} y={204} w={118} h={65} r={20} bg="rgba(255,255,255,.12)" style={{ textAlign: 'center', paddingTop: 10 }}>
          <p style={{ font: '700 16px/22px Inter', color: '#fff' }}>{a}</p>
          <p style={{ font: '500 11px/15.4px Inter', color: '#dfeee0', marginTop: 5 }}>{b}</p>
        </Box>
      ))}

      {sec(299, 'ACCOUNT')}
      <Rows y={324} h={54} ts={36} rows={[
        { icon: User, title: 'Personal info', right: chev, go: go('1:2459') },
        { icon: File, title: 'Documents', right: <>{missing ? <Pill label={`${missing} to upload`} {...pill.warn} style={{ marginRight: 10 }} /> : expiring ? <Pill label={`${expiring} expiring`} {...pill.warn} style={{ marginRight: 10 }} /> : null}{chev}</>, go: go('1:2564') },
        { icon: Landmark, title: 'Bank & UPI', right: <>{val(primary ? (primary.type === 'upi' ? primary.upi_vpa! : `${primary.bank_name ?? 'Bank'} ••${primary.account_last4}`) : 'Not added')}{chev}</>, go: go('1:2711') },
        { icon: Bike, title: 'Vehicle', right: <>{val(vehicle.data?.registration_number ?? 'Not added')}{chev}</>, go: go('1:2807') },
      ]} />
      {sec(556, 'APP & SUPPORT')}
      <Rows y={581} h={54} ts={36} rows={[
        { icon: Globe, title: 'Language', right: <>{val(lang)}{chev}</>, go: go('1:3080') },
        { icon: MessageCircle, title: 'Help & support', right: chev, go: go('1:3289') },
        { icon: TriangleAlert, tile: '#fde0dd', ic: '#c92526', title: 'SOS & emergency contacts', right: chev, go: go('1:3533') },
        { icon: LogOut, tile: '#fde0dd', ic: '#c92526', title: 'Log out', right: chev, go: () => setOut(true) },
      ]} />
      <BottomNav active="profile" />
      {out && (
        <Modal onClose={() => setOut(false)}>
          <p style={{ font: '700 18px/25px Inter', color: C.ink }}>Log out?</p>
          <p style={{ font: '500 13px/19px Inter', color: C.muted, margin: '6px 0 20px' }}>You’ll stop receiving new orders until you log in again.</p>
          <Btn w="100%" h={48} kind="danger" icon={LogOut} label="LOG OUT" onClick={async () => { setOut(false); await signOut(); toast('Logged out'); nav('/login', { replace: true }) }} />
          <div style={{ height: 10 }} />
          <Btn w="100%" h={48} kind="outline" label="CANCEL" onClick={() => setOut(false)} />
        </Modal>
      )}
    </Screen>
  )
}

export function PersonalInfo() {
  const nav = useNavigate()
  const { me, refreshMe } = useSession()
  const contacts = useApi<{ name: string; relationship: string; phone: string; is_primary: boolean }[]>('/v1/emergency-contacts')
  const [email, setEmail] = useState(me?.email ?? '')
  const [dob, setDob] = useState(me?.date_of_birth?.slice(0, 10) ?? '')
  const [blood, setBlood] = useState(me?.blood_group ?? '')
  const [addr, setAddr] = useState(me?.address ?? '')
  const [busy, setBusy] = useState(false)
  const dashed = { background: '#f4f6ee', border: '1px dashed #cfd8cb', borderRadius: 16 }
  const label = (x: number, y: number, t: ReactNode) => <T x={x} y={y} s={13} wt={600} lh={18.2}>{t}</T>
  const ec = contacts.data?.find((c) => c.is_primary) ?? contacts.data?.[0]
  const save = async () => {
    const bad = emailError(email) || dobError(dob) || addressError(addr)
    if (bad) return toast(bad)
    setBusy(true)
    try {
      await api('/v1/me', { method: 'PATCH', body: { email: email.trim() || null, dateOfBirth: dob || null, bloodGroup: blood || null, address: addr.trim() || null } })
      await refreshMe()
      toast('Changes saved')
      nav(P('1:2301'))
    } catch (e) { showError(e) } finally { setBusy(false) }
  }
  return (
    <Screen>
      <Header title="Personal info" to={P('1:2301')} />
      <Box x={154} y={98} w={104} h={104} r={52} bg="#eaf2d6" />
      <Box x={158} y={102} w={96} h={96} r={48} bg={avatarBg} style={{ color: '#fff', font: '700 30px/96px Inter', textAlign: 'center' }}>{initials(me?.full_name)}</Box>
      <Box onClick={() => toast('Profile photos are taken from your verified selfie')} x={220} y={160} w={38} h={38} r={19} bg={C.green} border="3px solid #fff"><Ic icon={Camera} x={8} y={8} s={16} c="#fff" /></Box>
      <T x={20} y={207} w={372} s={12} lh={16.8} c={C.muted} align="center">Photo must match your verified selfie</T>

      {label(20, 238, 'Full name')}
      <Box x={20} y={263} w={372} h={55} style={dashed} />
      <T x={37} y={279} w={210} s={16} wt={600} lh={22.4} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{me?.full_name}</T>
      <Pill x={255} y={279} w={120} label="As on Aadhaar" {...pill.ok} />

      {label(20, 332, 'Mobile number')}
      <Box x={20} y={358} w={372} h={55} style={dashed} />
      <T x={37} y={374} w={250} s={16} wt={600} lh={22.4}>{me ? `+91 ${me.phone.slice(3, 8)} ${me.phone.slice(8)}` : ''}</T>
      <T x={300} y={376} w={75} s={13} wt={700} lh={18} c={C.accent} align="right">Verified</T>

      <Field y={427} label="Email (for payout statements)" value={email} onChange={setEmail} icon={Mail} inputMode="email" placeholder="you@example.com" />

      {label(20, 522, 'Date of birth')}
      <input aria-label="Date of birth" type="date" value={dob} max={new Date(Date.now() - 18 * 365.25 * 864e5).toISOString().slice(0, 10)} onChange={(e) => setDob(e.target.value)}
        style={{ position: 'absolute', left: 20, top: 548, width: 240, height: 55, borderRadius: 16, border: `1px solid ${C.line}`, background: '#fff', padding: '0 16px', font: '600 16px Inter', color: C.ink, outline: 0 }} />
      {label(272, 522, 'Blood group')}
      <select aria-label="Blood group" value={blood} onChange={(e) => setBlood(e.target.value)}
        style={{ position: 'absolute', left: 272, top: 548, width: 120, height: 55, borderRadius: 16, border: `1px solid ${C.line}`, background: '#fff', padding: '0 14px', font: '600 16px Inter', color: C.ink, outline: 0 }}>
        <option value="">–</option>
        {['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((b) => <option key={b}>{b}</option>)}
      </select>

      {label(20, 617, 'Current address')}
      <Box x={20} y={643} w={372} h={75} r={16} bg="#fff" border={`1px solid ${C.line}`} />
      <Ic icon={MapPin} x={38} y={659} s={16} c={C.muted} />
      <textarea aria-label="Current address" value={addr} onChange={(e) => setAddr(e.target.value)} placeholder="House, street, area, city, PIN"
        style={{ position: 'absolute', left: 69, top: 658, width: 312, height: 50, border: 0, outline: 0, resize: 'none', background: 'transparent', font: '600 15px/22px Inter', color: C.ink }} />

      <Box x={20} y={733} w={372} h={76} r={22} bg="#eef5db" border="1px solid #ddebc3" />
      <Tile x={37} y={750} s={44} bg="#fff" border="1px solid #e3ead8" icon={Users} />
      <T x={92} y={754} s={15} wt={700} lh={21}>Emergency contact</T>
      <T x={92} y={776} w={230} s={12} lh={16.8} c="#333">{ec ? `${ec.name} (${ec.relationship}) · ${maskPhone(ec.phone)}` : 'Not added yet'}</T>
      <T x={330} y={766} w={45} s={14} wt={700} lh={20} c={C.green} align="right" onClick={() => nav(P('1:3533'))}>{ec ? 'Edit' : 'Add'}</T>

      <Btn y={840} label={busy ? 'SAVING…' : 'SAVE CHANGES'} onClick={() => !busy && void save()} />
    </Screen>
  )
}

type SettingsRow = { auto_accept_nearby: boolean; navigation_app: string; new_order_sound: boolean; payout_alerts: boolean; offers_campaigns: boolean; dark_mode_at_night: boolean; data_saver: boolean; voice_navigation: boolean; fingerprint_unlock: boolean }
const KEYS: Record<keyof SettingsRow, string> = {
  auto_accept_nearby: 'autoAcceptNearby', navigation_app: 'navigationApp', new_order_sound: 'newOrderSound', payout_alerts: 'payoutAlerts', offers_campaigns: 'offersCampaigns',
  dark_mode_at_night: 'darkModeAtNight', data_saver: 'dataSaver', voice_navigation: 'voiceNavigation', fingerprint_unlock: 'fingerprintUnlock',
}
export function useSettings() {
  const q = useApi<SettingsRow>('/v1/me/settings')
  const update = async (k: keyof SettingsRow, v: boolean | string) => {
    const prev = q.data
    if (prev) q.setData({ ...prev, [k]: v })
    try { await api('/v1/me/settings', { method: 'PATCH', body: { [KEYS[k]]: v } }) } catch (e) { if (prev) q.setData(prev); showError(e) }
  }
  return { s: q.data, update }
}

export function Settings() {
  const nav = useNavigate()
  const { me, lang } = useSession()
  const { s, update } = useSettings()
  const tg = (k: keyof SettingsRow) => <Toggle on={!!s?.[k]} onChange={(v) => void update(k, v)} onColor={C.green} />
  const go = (id: string) => () => nav(P(id))
  return (
    <Screen>
      <Header title="Settings" to={P('1:2301')} />
      {sec(100, 'DELIVERIES')}
      <Rows y={125} h={60} rows={[
        { icon: Zap, title: 'Auto-accept nearby orders', sub: 'Within 2 km of your location', right: tg('auto_accept_nearby') },
        { icon: Map, title: 'City, hub & delivery radius', sub: `${me?.city.name ?? ''} · ${me?.hub?.name ?? 'No hub'} · ${me?.delivery_radius_km ?? 5} km`, right: chev, go: go('1:3906') },
        { icon: Navigation, title: 'Navigation', sub: s?.navigation_app === 'in_app' ? 'In-app maps' : 'Google Maps · turn-by-turn', right: <Toggle on={s?.navigation_app !== 'in_app'} onChange={(v) => void update('navigation_app', v ? 'google_maps' : 'in_app')} onColor={C.green} /> },
      ]} />
      {sec(317, 'ALERTS')}
      <Rows y={342} h={56.3} rows={[
        { icon: Volume1, title: 'New order sound', sub: 'Plays even on silent', right: tg('new_order_sound') },
        { icon: Wallet, title: 'Payout & bonus alerts', right: tg('payout_alerts') },
        { icon: Star, title: 'Offers & campaigns', right: tg('offers_campaigns') },
      ]} />
      {sec(523, 'APP')}
      <Rows y={549} h={56} rows={[
        { icon: Globe, title: 'Language', right: <>{val(lang)}{chev}</>, go: go('1:3080') },
        { icon: Moon, title: 'Dark mode for night shifts', right: tg('dark_mode_at_night') },
        { icon: Activity, title: 'Data saver', sub: 'Lighter maps on 3G / weak signal', right: tg('data_saver') },
      ]} />
      {sec(728, 'SECURITY')}
      <Rows y={754} h={63} rows={[
        { icon: Shield, title: 'Fingerprint unlock', right: tg('fingerprint_unlock') },
      ]} />
      <T x={20} y={889} w={372} s={12} wt={700} lh={17} align="center" onClick={go('1:3185')}>About Vpnexues</T>
    </Screen>
  )
}

const langs: { g: string; native: string; name: string; code: LangCode; soon?: boolean }[] = [
  { g: 'Aa', native: 'English', name: 'Default', code: 'en' },
  { g: 'த', native: 'தமிழ்', name: 'Tamil', code: 'ta' },
  { g: 'हि', native: 'हिन्दी', name: 'Hindi', code: 'hi' },
  { g: 'മ', native: 'മലയാളം', name: 'Malayalam', code: 'ml' },
  { g: 'తె', native: 'తెలుగు', name: 'Telugu · coming soon', code: 'te', soon: true },
  { g: 'ಕ', native: 'ಕನ್ನಡ', name: 'Kannada · coming soon', code: 'kn', soon: true },
]

export function Language() {
  const nav = useNavigate()
  const { lang, setLang } = useSession()
  const { s, update } = useSettings()
  const [sel, setSel] = useState(lang)
  const [busy, setBusy] = useState(false)
  useEffect(() => setSel(lang), [lang])
  const apply = async () => {
    setBusy(true)
    try { await setLang(sel); toast(`Language set to ${sel}`); nav(-1) } catch (e) { showError(e) } finally { setBusy(false) }
  }
  return (
    <Screen ol="b">
      <Header title="App language" />
      <T x={20} y={104} w={350} s={13.5} lh={19} c={C.muted}>Choose the language for menus, alerts and voice navigation.</T>
      <div style={{ position: 'absolute', left: 20, top: 154, width: 372, display: 'flex', flexDirection: 'column', gap: 12 }}>
        {langs.map((l) => {
          const on = sel === LANGS[l.code]
          return (
            <button key={l.code} type="button" disabled={l.soon} onClick={() => setSel(LANGS[l.code])}
              style={{ display: 'flex', alignItems: 'center', gap: 14, height: 73, padding: '0 15px', borderRadius: 22, textAlign: 'left', opacity: l.soon ? 0.5 : 1,
                background: on ? '#e6f2d6' : '#fff', border: on ? '1px solid #d3e6bd' : `1px solid ${C.line}`, boxShadow: on ? '0 0 0 4px rgba(9,83,52,.07)' : undefined }}>
              <span style={{ width: 48, height: 48, borderRadius: 14, background: on ? C.green : '#eef5db', color: on ? '#fff' : C.green, font: '700 20px/48px Inter', textAlign: 'center', flex: 'none' }}>{l.g}</span>
              <span style={{ flex: 1 }}>
                <span style={{ display: 'block', font: '700 17px/24px Inter', color: C.ink }}>{l.native}</span>
                <span style={{ display: 'block', font: '400 12px/16.8px Inter', color: C.muted }}>{l.name}</span>
              </span>
              {on && <Ic icon={Check} s={16} sw={2.2} />}
            </button>
          )
        })}
      </div>
      <Box x={20} y={663} w={372} h={65} r={22} bg="#eef5db" border="1px solid #ddebc3" />
      <T x={36} y={677} s={14} wt={700} lh={20}>Voice navigation in same language</T>
      <T x={36} y={698} s={12} lh={16.8} c="#222">Turn-by-turn directions</T>
      <Toggle x={325} y={681} on={!!s?.voice_navigation} onChange={(v) => void update('voice_navigation', v)} onColor={C.green} />
      <Btn y={839} label={busy ? 'SAVING…' : 'APPLY'} onClick={() => !busy && void apply()} />
    </Screen>
  )
}
