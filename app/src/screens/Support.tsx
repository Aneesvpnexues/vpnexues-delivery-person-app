import { useEffect, useRef, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { ArrowLeft, ChevronDown, ChevronRight, ChevronUp, File, Landmark, Leaf, Lock, Map, MessageCircle, Navigation, Package, Phone as PhoneIcon, Plus, Search, Shield, ShieldCheck, Star, TriangleAlert, Wallet, Zap, type LucideIcon } from 'lucide-react'
import Phone from '../components/Phone'
import { Box, Btn, C, Field, Header, Ic, Logo, Modal, P, Pill, RoundBtn, Screen, T, Tile, card, pill, toast, useGoBack } from '../components/kit'
import { api, showError } from '../api/client'
import { firstName, initials, maskPhone, time, date, useApi, useSession } from '../api/session'
import type { Notification, OrderListItem } from '../api/types'
import { avatarBg } from './OrderFlow'

const sec = (y: number, label: string) => <T x={20} y={y} s={11} wt={700} lh={15.4} c={C.accent} ls={1.2}>{label}</T>
const chipS = (on: boolean): React.CSSProperties => ({ height: 40, padding: '0 15px', borderRadius: 20, background: on ? C.green : '#fff', border: on ? 0 : `1px solid ${C.line}`, color: on ? '#fff' : '#405947', font: '700 13px/18.2px Inter', whiteSpace: 'nowrap' })
/** tel: links open the phone dialer inside the Android app. */
const dial = (n: string) => { window.location.href = `tel:${n}` }

/* ---------------- Help & support ---------------- */
const faqs: { icon: LucideIcon; q: string; a: string }[] = [
  { icon: Wallet, q: 'When do I get paid?', a: 'Earnings from Monday to Sunday are paid every Monday by 6 PM. Need it sooner? Use Instant payout from the Earnings tab.' },
  { icon: File, q: 'Why is my document still in review?', a: 'Reviews take 2–24 hours. You’ll get a notification as each document is approved.' },
  { icon: Lock, q: 'Customer has no delivery code', a: 'Ask them to open the order in their app or check SMS. If it still fails, tap “Contact support” on the hand-over screen.' },
  { icon: Map, q: 'Changing my delivery zone', a: 'Open Settings → City, hub & delivery radius. Radius changes apply at once; city or hub changes are confirmed by support.' },
  { icon: Shield, q: 'What does accident cover include?', a: 'You are covered while online and on an active order. Use Safety & SOS to reach the safety team.' },
]
const ISSUES = ['Customer unreachable', 'Wrong address', 'Items damaged', 'Hub delay']

export function Help() {
  const nav = useNavigate()
  const { me } = useSession()
  const params = useSearchParams()[0]
  const active = useApi<OrderListItem[]>(params.get('order') ? null : '/v1/orders?tab=active&limit=1')
  const order = params.get('order') ? { id: params.get('order')!, code: params.get('code') ?? '' } : active.data?.[0] ? { id: active.data[0].id, code: active.data[0].order_code } : null
  const [q, setQ] = useState('')
  const [open, setOpen] = useState(0)
  const [issue, setIssue] = useState('')
  const list = faqs.filter((f) => !q || (f.q + f.a).toLowerCase().includes(q.toLowerCase()))
  const report = async (topic: string) => {
    if (!order) return
    setIssue(topic)
    try {
      const t = await api<{ id: string }>('/v1/support/tickets', { body: { topic, message: `${topic} on order #${order.code}.`, orderId: order.id } })
      toast('Reported. Support will reply in the chat.')
      nav(`${P('33:5')}?ticket=${t.id}`)
    } catch (e) { showError(e); setIssue('') }
  }
  const quick = [
    { icon: MessageCircle, title: 'Chat', sub: 'Reply in ~2 min', go: () => nav(P('33:5')) },
    { icon: PhoneIcon, title: 'Call', sub: '24 × 7 partner line', go: () => toast('The partner helpline number will appear here once it’s set up') },
    { icon: TriangleAlert, title: 'SOS', sub: 'Emergency', go: () => nav(P('1:3533')), red: true },
  ]
  return (
    <Screen ol="b">
      <Header title="Help & support" />
      <Box x={20} y={102} w={372} h={132} r={28} bg="linear-gradient(125deg,#063a2a 0%,#1f7945 100%)" shadow="0 18px 28px rgba(9,83,52,.2)" />
      <T x={38} y={121} w={340} s={20} wt={700} lh={28} c="#fff">{`Hi ${firstName(me?.full_name) || 'there'}, how can we help?`}</T>
      <Box x={38} y={160} w={336} h={56} r={28} bg="#fff" />
      <Ic icon={Search} x={54} y={179} s={18} c={C.muted} />
      <input aria-label="Search help" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search: payout, OTP, insurance…"
        style={{ position: 'absolute', left: 84, top: 176, width: 275, height: 24, border: 0, outline: 0, background: 'transparent', font: '600 15px/24px Inter', color: C.ink }} />

      {quick.map((c, i) => (
        <button key={c.title} type="button" onClick={c.go}
          style={{ position: 'absolute', left: 20 + i * 127.5, top: 248, width: 117, height: 142, borderRadius: 22, textAlign: 'left', padding: '15px 12px', background: c.red ? '#fff5f3' : '#fff', border: `1px solid ${c.red ? '#f5c9c4' : C.line}` }}>
          <Tile s={44} bg={c.red ? '#fde0dd' : '#eef5db'} icon={c.icon} c={c.red ? '#c92526' : undefined} />
          <span style={{ display: 'block', font: '700 14px/20px Inter', color: c.red ? '#c92526' : C.ink, marginTop: 9 }}>{c.title}</span>
          <span style={{ display: 'block', font: '400 12px/17px Inter', color: C.muted, marginTop: 7 }}>{c.sub}</span>
        </button>
      ))}

      <Box x={20} y={405} w={372} h={150} r={24} bg="#eef5db" border="1px solid #ddebc3" />
      {order ? (
        <>
          <T x={36} y={422} s={15} wt={700} lh={21}>{`Problem with #${order.code}?`}</T>
          <div style={{ position: 'absolute', left: 37, top: 451, width: 340, display: 'flex', flexWrap: 'wrap', gap: '8px 9px' }}>
            {ISSUES.map((c) => <button key={c} type="button" style={chipS(issue === c)} onClick={() => void report(c)}>{c}</button>)}
          </div>
        </>
      ) : (
        <>
          <T x={36} y={422} s={15} wt={700} lh={21}>No active order</T>
          <T x={36} y={448} w={330} s={13} lh={19} c={C.muted}>Problems with a delivery can be reported from the order itself. For anything else, start a chat.</T>
          <Btn x={36} y={500} w={160} h={40} fs={12} label="START A CHAT" to={P('33:5')} />
        </>
      )}

      {sec(570, 'POPULAR TOPICS')}
      <div className="scroll" style={{ position: 'absolute', left: 20, top: 596, width: 372, height: 319, display: 'flex', flexDirection: 'column', gap: 4, paddingBottom: 16 }}>
        {list.map((f, i) => {
          const on = open === i
          return (
            <button key={f.q} type="button" onClick={() => setOpen(on ? -1 : i)} style={{ flex: 'none', background: '#fff', borderRadius: 22, padding: '14px 12px', textAlign: 'left' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <Tile icon={f.icon} is={18} />
                <span style={{ flex: 1, font: '700 15px/20px Inter', color: C.ink }}>{f.q}</span>
                <Ic icon={on ? ChevronUp : ChevronDown} s={16} c="#8a988f" />
              </span>
              {on && <span style={{ display: 'block', font: '400 12.5px/18px Inter', color: C.muted, marginTop: 6 }}>{f.a}</span>}
            </button>
          )
        })}
        {!list.length && <p style={{ font: '500 13px/20px Inter', color: C.muted, textAlign: 'center', marginTop: 24 }}>No topics match “{q}”.</p>}
      </div>
    </Screen>
  )
}

/* ---------------- Support chat ---------------- */
type Msg = { id: number; sender: 'partner' | 'agent' | 'bot'; body: string; created_at: string }
const TOPICS = ['Verification', 'Payouts']
export function SupportChat() {
  const nav = useNavigate()
  const { me } = useSession()
  const [params, setParams] = useSearchParams()
  const tickets = useApi<{ id: string; topic: string; status: string }[]>(params.get('ticket') ? null : '/v1/support/tickets')
  const ticketId = params.get('ticket') ?? tickets.data?.find((t) => t.status !== 'closed')?.id ?? null
  const [msgs, setMsgs] = useState<Msg[]>([])
  const [draft, setDraft] = useState('')
  const [busy, setBusy] = useState(false)
  const end = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!ticketId) return
    let stop = false
    const load = () => api<Msg[]>(`/v1/support/tickets/${ticketId}/messages`).then((m) => !stop && setMsgs(m)).catch(() => {})
    void load()
    const t = setInterval(load, 10_000) // light polling until push notifications are wired up
    return () => { stop = true; clearInterval(t) }
  }, [ticketId])
  useEffect(() => { end.current?.scrollIntoView({ block: 'end' }) }, [msgs])

  const send = async (text: string, topic = 'General help') => {
    if (!text.trim() || busy) return
    setBusy(true)
    try {
      if (ticketId) {
        const m = await api<Msg>(`/v1/support/tickets/${ticketId}/messages`, { body: { message: text.trim() } })
        setMsgs((x) => [...x, m])
      } else {
        const t = await api<{ id: string }>('/v1/support/tickets', { body: { topic, message: text.trim() } })
        setParams({ ticket: t.id }, { replace: true })
      }
      setDraft('')
    } catch (e) { showError(e) } finally { setBusy(false) }
  }
  const greeting: Msg = { id: 0, sender: 'bot', body: `Hi ${firstName(me?.full_name) || 'there'}. Tell us what you need help with — a delivery, a payout or your documents — and a support agent will reply here.`, created_at: '' }
  return (
    <Phone>
      <Box onClick={() => nav(P('1:3289'))} x={20} y={40} w={64} h={44} r={16} bg="#fff" style={{ font: '700 11px/16px Inter', color: C.ink }}>BACK</Box>
      <T x={100} y={48} s={20} wt={700} lh={28}>Support chat</T>
      <T x={20} y={108} s={10.5} wt={700} lh={14} c={C.green}>{ticketId ? 'AGENTS USUALLY REPLY WITHIN A FEW MINUTES' : 'START A CONVERSATION'}</T>
      <div className="scroll" style={{ position: 'absolute', left: 20, top: 142, width: 372, height: 540, display: 'flex', flexDirection: 'column', gap: 10 }}>
        {[greeting, ...msgs].map((m) => {
          const mine = m.sender === 'partner'
          return (
            <div key={m.id} style={{ alignSelf: mine ? 'flex-end' : 'stretch', maxWidth: mine ? 300 : undefined, background: mine ? C.green : '#fff', color: mine ? '#fff' : C.ink, borderRadius: 20, padding: '12px 16px', font: '400 14.5px/22px Inter', flex: 'none' }}>
              {m.body}
              {m.created_at && <span style={{ display: 'block', font: '600 10.5px/14px Inter', opacity: 0.7, marginTop: 4 }}>{time(m.created_at)}</span>}
            </div>
          )
        })}
        <div ref={end} />
      </div>
      <textarea aria-label="Message" value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Type your message…"
        style={{ position: 'absolute', left: 20, top: 696, width: 274, height: 92, borderRadius: 20, border: 0, outline: 0, resize: 'none', background: '#fff', padding: '16px 18px', font: '400 13px/19px Inter', color: C.ink }} />
      <Box onClick={() => void send(draft)} x={304} y={696} w={88} h={92} r={20} bg={C.green} style={{ font: '700 12px/17px Inter', color: '#fff' }}>{busy ? '…' : 'SEND'}</Box>
      {TOPICS.map((k, i) => (
        <Box key={k} onClick={() => void send(`I need help with ${k.toLowerCase()}.`, k)} x={20 + i * 192} y={812} w={180} h={52} r={20} bg={C.green} style={{ font: '700 13px/18px Inter', color: '#fff' }}>{k}</Box>
      ))}
    </Phone>
  )
}

/* ---------------- Notifications ---------------- */
const NCAT: Record<string, string> = { All: 'all', Orders: 'order', Payouts: 'payout', Account: 'account' }
const NICON: Record<Notification['category'], { icon: LucideIcon; bg: string; ic?: string; to: string }> = {
  order: { icon: Package, bg: '#eef5db', to: '1:944' }, payout: { icon: Landmark, bg: '#fff3bf', to: '1:1953' },
  account: { icon: ShieldCheck, bg: '#e0eff3', ic: '#145b73', to: '1:3770' }, promo: { icon: Zap, bg: '#fff3bf', to: '1:1816' },
  safety: { icon: TriangleAlert, bg: '#fde0dd', ic: '#c92526', to: '1:3533' },
}
const ago = (iso: string) => {
  const m = Math.round((Date.now() - +new Date(iso)) / 60000)
  return m < 1 ? 'Just now' : m < 60 ? `${m} min ago` : m < 24 * 60 ? `${Math.round(m / 60)} h ago` : date(iso, { weekday: 'short', day: 'numeric', month: 'short' })
}
export function Notifications() {
  const nav = useNavigate()
  const [cat, setCat] = useState('All')
  const n = useApi<{ items: Notification[]; unreadCount: number }>(`/v1/notifications?category=${NCAT[cat]}`)
  const readAll = async () => {
    try { await api('/v1/notifications/read-all', { method: 'POST' }); await n.reload() } catch (e) { showError(e) }
  }
  const open = async (x: Notification) => {
    if (!x.read_at) api(`/v1/notifications/${x.id}/read`, { method: 'POST' }).catch(() => {})
    const order = x.action_url?.match(/^\/orders\/([0-9a-f-]{36})$/)?.[1]
    nav(order ? `${P('1:1223')}?id=${order}` : P(NICON[x.category].to))
  }
  const unread = n.data?.unreadCount ?? 0
  return (
    <Screen>
      <Header title="Notifications" />
      <T x={262} y={55} w={130} s={13} wt={700} lh={18.2} c={unread ? C.green : C.muted} align="right" onClick={() => void readAll()}>Mark all read</T>
      <div style={{ position: 'absolute', left: 20, top: 100, display: 'flex', gap: 9 }}>
        {Object.keys(NCAT).map((c) => (
          <button key={c} type="button" onClick={() => setCat(c)} style={{ ...chipS(cat === c), color: cat === c ? '#fff' : C.ink, padding: '0 14px' }}>{c === 'All' && unread ? `All · ${unread} new` : c}</button>
        ))}
      </div>
      {sec(163, 'NOTIFICATIONS')}
      <div className="scroll" style={{ position: 'absolute', left: 20, top: 180, width: 372, height: 735, display: 'flex', flexDirection: 'column', gap: 11, paddingBottom: 24 }}>
        {(n.data?.items ?? []).map((x) => {
          const k = NICON[x.category]
          const fresh = !x.read_at
          return (
            <div key={x.id} role="button" onClick={() => void open(x)}
              style={{ flex: 'none', position: 'relative', display: 'flex', gap: 12, padding: '13px 14px', borderRadius: 22, cursor: 'pointer', background: fresh ? '#f3f7e9' : '#fff', border: `1px solid ${fresh ? '#d6e5bf' : C.line}` }}>
              <Tile s={44} bg={k.bg} icon={k.icon} c={k.ic} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ font: '700 14.5px/20px Inter', color: C.ink, paddingRight: 14 }}>{x.title}</p>
                <p style={{ font: '400 12.5px/18px Inter', color: C.muted, marginTop: 3 }}>{x.body}</p>
                <p style={{ font: '700 11px/16px Inter', color: '#7b887f', marginTop: 6 }}>{ago(x.created_at)}</p>
              </div>
              {fresh && <span style={{ position: 'absolute', right: 14, top: 16, width: 9, height: 9, borderRadius: 5, background: C.accent }} />}
            </div>
          )
        })}
        {!n.loading && !n.data?.items.length && <p style={{ font: '500 13.5px/20px Inter', color: C.muted, textAlign: 'center', marginTop: 50 }}>No notifications yet. Order, payout and account updates will show up here.</p>}
        {n.loading && !n.data && <p style={{ font: '500 13px/20px Inter', color: C.muted, textAlign: 'center', marginTop: 50 }}>Loading…</p>}
      </div>
    </Screen>
  )
}

/* ---------------- Safety & SOS ---------------- */
type Contact = { id: string; name: string; relationship: string; phone: string; is_primary: boolean }
const INCIDENTS = [['Road accident', 'road_accident'], ['Vehicle breakdown', 'vehicle_breakdown'], ['Harassment', 'harassment'], ['Medical', 'medical'], ['Unsafe area', 'other']] as const
/** Current position if the partner allows location (Android shows its own permission prompt). */
const here = () => new Promise<{ lat?: number; lng?: number }>((resolve) => {
  if (!navigator.geolocation) return resolve({})
  navigator.geolocation.getCurrentPosition((p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }), () => resolve({}), { timeout: 6000, maximumAge: 60000 })
})

export function SOS() {
  const nav = useNavigate()
  const contacts = useApi<Contact[]>('/v1/emergency-contacts')
  const [incident, setIncident] = useState<string>('road_accident')
  const [hold, setHold] = useState(0)
  const [add, setAdd] = useState<{ name: string; relationship: string; phone: string } | null>(null)
  const timer = useRef<number | null>(null)
  const stop = () => { if (timer.current) window.clearInterval(timer.current); timer.current = null; setHold(0) }
  const raise = async (kind: string, details?: string) => {
    try {
      const loc = await here()
      await api('/v1/sos', { body: { kind, ...loc, ...(details ? { details } : {}) } })
      toast(kind === 'sos' ? 'SOS sent to the safety team. Stay where you are if it’s safe.' : 'Incident reported. The safety team will contact you.')
    } catch (e) { showError(e) }
  }
  const start = () => {
    stop()
    const t0 = Date.now()
    timer.current = window.setInterval(() => {
      const p = (Date.now() - t0) / 3000
      if (p >= 1) { stop(); void raise('sos') } else setHold(p)
    }, 50)
  }
  useEffect(() => stop, [])
  const saveContact = async () => {
    if (!add) return
    try {
      await api('/v1/emergency-contacts', { body: add })
      toast('Emergency contact saved')
      setAdd(null)
      await contacts.reload()
    } catch (e) { showError(e) }
  }
  const quick: { icon: LucideIcon; bg: string; ic: string; label: string; go: () => void }[] = [
    { icon: PhoneIcon, bg: '#fde0dd', ic: '#c92526', label: 'Call 112', go: () => dial('112') },
    { icon: Shield, bg: '#eef5db', ic: C.green, label: 'Safety team', go: () => nav(P('33:5')) },
    { icon: Navigation, bg: '#e0eff3', ic: '#145b73', label: 'Share live\nlocation', go: () => void raise('other', 'Shared live location from SOS screen') },
  ]
  const list = contacts.data ?? []
  return (
    <Screen ol="b">
      <Box x={0} y={0} w={412} h={420} bg="linear-gradient(180deg,#fde6e4 0%,rgba(253,230,228,.6) 45%,rgba(247,248,241,0) 100%)" />
      <Header title="Safety & SOS" />
      <Pill x={281} y={52} w={111} label="Cover active" {...pill.ok} />
      <Box x={111} y={112} w={190} h={190} r={95} bg="rgba(229,72,77,.09)" style={{ transform: `scale(${1 + hold * 0.12})` }} />
      <Box x={126} y={127} w={160} h={160} r={80} bg="rgba(229,72,77,.15)" />
      <button type="button" aria-label="Hold for SOS" onPointerDown={start} onPointerUp={stop} onPointerLeave={stop}
        style={{ position: 'absolute', left: 144, top: 140, width: 133, height: 133, borderRadius: 67, background: 'linear-gradient(135deg,#e7393c 0%,#b1171a 100%)', boxShadow: '0 16px 30px rgba(190,30,30,.35)', color: '#fff', touchAction: 'none' }}>
        <span style={{ display: 'block', font: '700 30px/38px Inter', marginTop: 4 }}>SOS</span>
        <span style={{ display: 'block', font: '700 10.5px/17px Inter' }}>{hold ? `Sending in ${Math.ceil(3 - hold * 3)}…` : 'Hold 3 seconds'}</span>
      </button>
      <T x={62} y={321} w={288} s={13.5} lh={20.5} c="#7a1f1f" align="center">Holding sends your location to the VP Nexues safety team. For immediate danger, also call 112.</T>

      {quick.map((c, i) => (
        <button key={c.label} type="button" onClick={c.go}
          style={{ position: 'absolute', left: 20 + i * 127.5, top: 401, width: 117, height: 95, borderRadius: 22, background: '#fff', border: '1px solid #f3d6d2', display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 12, gap: 4 }}>
          <Tile s={44} bg={c.bg} icon={c.icon} c={c.ic} />
          <span style={{ font: '700 12px/15px Inter', color: C.ink, whiteSpace: 'pre-line', textAlign: 'center' }}>{c.label}</span>
        </button>
      ))}

      <div style={{ position: 'absolute', left: 20, top: 510, width: 372, height: 209, ...card }} />
      <T x={36} y={525} s={15} wt={700} lh={21}>Report an incident</T>
      <T x={36} y={548} s={12} lh={16.8} c={C.muted}>Not an emergency? Tell us what happened.</T>
      <div style={{ position: 'absolute', left: 36, top: 569, width: 345, display: 'flex', flexWrap: 'wrap', gap: '2px 8px' }}>
        {INCIDENTS.map(([l, k]) => <button key={l} type="button" onClick={() => setIncident(k)} style={{ ...chipS(incident === k), color: incident === k ? '#fff' : C.ink }}>{l}</button>)}
      </div>
      <Btn x={37} y={659} w={338} h={55} kind="outline" label="SEND REPORT" onClick={() => void raise(incident, INCIDENTS.find(([, k]) => k === incident)![0])} />

      <div style={{ position: 'absolute', left: 20, top: 734, width: 372, height: 170, ...card }} />
      <T x={36} y={748} s={11} wt={700} lh={15.4} c={C.accent} ls={1.2}>EMERGENCY CONTACTS</T>
      {list.length < 3 && <T x={300} y={750} w={75} s={13} wt={700} lh={18} c={C.green} align="right" onClick={() => setAdd({ name: '', relationship: '', phone: '' })}>+ Add</T>}
      {list.slice(0, 2).map((c, i) => (
        <div key={c.id}>
          {i > 0 && <Box x={36} y={822} w={339} h={1} bg={C.tint5} />}
          <Box x={36} y={774 + i * 61} w={40} h={40} r={20} bg={i ? '#f8d92f' : avatarBg} style={{ color: i ? C.ink : '#fff', font: '700 13px/40px Inter', textAlign: 'center' }}>{initials(c.name)}</Box>
          <T x={91} y={775 + i * 61} w={190} s={15} wt={700} lh={21} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{`${c.name} · ${c.relationship}`}</T>
          <T x={91} y={797 + i * 61} s={12} lh={16.8} c={C.muted} onClick={() => dial(c.phone)}>{maskPhone(c.phone)}</T>
          {c.is_primary && <Pill x={292} y={782 + i * 61} w={83} label="Primary" {...pill.ok} />}
        </div>
      ))}
      {!contacts.loading && !list.length && (
        <>
          <T x={36} y={780} w={330} s={13} lh={19} c={C.muted}>Add someone we should call if you’re in an accident.</T>
          <Btn x={36} y={826} w={200} h={44} fs={12} icon={Plus} label="ADD CONTACT" onClick={() => setAdd({ name: '', relationship: '', phone: '' })} />
        </>
      )}

      {add && (
        <Modal onClose={() => setAdd(null)}>
          <p style={{ font: '700 18px/25px Inter', color: C.ink, marginBottom: 12 }}>Emergency contact</p>
          <div style={{ display: 'grid', gap: 10, marginBottom: 16 }}>
            <Field w={324} h={48} label="Name" value={add.name} onChange={(v) => setAdd({ ...add, name: v })} placeholder="Full name" />
            <Field w={324} h={48} label="Relationship" value={add.relationship} onChange={(v) => setAdd({ ...add, relationship: v })} placeholder="Sister, father, friend…" />
            <Field w={324} h={48} label="Mobile number" value={add.phone} onChange={(v) => setAdd({ ...add, phone: v.replace(/[^\d ]/g, '') })} inputMode="tel" placeholder="10-digit number" />
          </div>
          <Btn w="100%" h={48} label="SAVE CONTACT" onClick={() => void saveContact()} />
        </Modal>
      )}
    </Screen>
  )
}

/* ---------------- About ---------------- */
export function About() {
  const [rate, setRate] = useState(false)
  const [stars, setStars] = useState(5)
  const values: { icon: LucideIcon; bg: string; ic?: string; a: string; b: string }[] = [
    { icon: Leaf, bg: '#eef5db', a: 'Freshness first', b: 'Harvested, packed and delivered within hours.' },
    { icon: Wallet, bg: '#fff3bf', a: 'Fair, transparent pay', b: 'Every rupee you earn is itemised in the app.' },
    { icon: Shield, bg: '#e0eff3', ic: '#145b73', a: 'Safety on every ride', b: 'One-tap SOS and accident cover while on duty.' },
  ]
  const links = [['Partner terms of service'], ['Privacy policy'], ['Grievance officer', 'Response within 15 days'], ['Open-source licences']]
  const goBack = useGoBack(P('1:2301'))
  const submit = async () => {
    setRate(false)
    try { await api('/v1/app-rating', { body: { stars, appVersion: '0.1.0' } }); toast(`Thanks for the ${stars}-star rating!`) } catch (e) { showError(e) }
  }
  return (
    <Screen ol="b">
      <Box x={0} y={0} w={412} h={220} bg="linear-gradient(180deg,#f1f6e3 0%,#f1f6e3 62%,#e4eed0 62%,#e4eed0 100%)" />
      <RoundBtn icon={ArrowLeft} x={20} y={52} onClick={goBack} />
      <T x={80} y={51} s={20} wt={700} lh={28}>About</T>
      <Logo x={168} y={93} s={76} />
      <T x={20} y={176} w={372} s={24} wt={700} lh={34} c="#0f5132" align="center">VP NEXUES</T>
      <T x={10} y={233} w={392} s={22} wt={700} lh={30} align="center">
        {'From the farm to the doorstep,\n'}
        <span style={{ backgroundImage: 'linear-gradient(95deg,#4f8a25,#8c7e0c)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' }}>the same day.</span>
      </T>
      <T x={30} y={300} w={352} s={13.5} lh={20.5} c={C.muted} align="center">VP Nexues connects local growers with homes and businesses. Our delivery partners are the last, most important mile.</T>

      <div style={{ position: 'absolute', left: 20, top: 376, width: 372, padding: '0 16px', ...card }}>
        {values.map((v, i) => (
          <div key={v.a} style={{ display: 'flex', alignItems: 'center', gap: 12, height: 70, borderTop: i ? `1px solid ${C.tint5}` : 0 }}>
            <Tile s={44} bg={v.bg} icon={v.icon} c={v.ic} />
            <div>
              <p style={{ font: '700 15px/21px Inter', color: C.ink }}>{v.a}</p>
              <p style={{ font: '400 12px/16.8px Inter', color: C.muted, marginTop: 2, whiteSpace: 'nowrap' }}>{v.b}</p>
            </div>
          </div>
        ))}
      </div>
      <div style={{ position: 'absolute', left: 20, top: 605, width: 372, padding: '0 16px', ...card }}>
        {links.map(([a, b], i) => (
          <button key={a} type="button" onClick={() => toast(`${a} will open here once it’s published`)}
            style={{ display: 'flex', alignItems: 'center', width: '100%', height: b ? 72 : 48, textAlign: 'left', borderTop: i ? `1px solid ${C.tint5}` : 0 }}>
            <span style={{ flex: 1 }}>
              <span style={{ display: 'block', font: '700 15px/21px Inter', color: C.ink }}>{a}</span>
              {b && <span style={{ display: 'block', font: '400 12px/16.8px Inter', color: C.muted, marginTop: 2 }}>{b}</span>}
            </span>
            <Ic icon={ChevronRight} s={16} c="#8a988f" />
          </button>
        ))}
      </div>
      <Btn y={838} kind="outline" icon={Star} label="RATE THE PARTNER APP" onClick={() => setRate(true)} />

      {rate && (
        <Modal onClose={() => setRate(false)}>
          <p style={{ font: '700 18px/25px Inter', color: C.ink }}>Rate the partner app</p>
          <p style={{ font: '500 13px/19px Inter', color: C.muted, margin: '6px 0 16px' }}>How has delivering with VP Nexues been so far?</p>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 10, marginBottom: 20 }}>
            {[1, 2, 3, 4, 5].map((n) => (
              <button key={n} type="button" aria-label={`${n} star`} onClick={() => setStars(n)}><Ic icon={Star} s={34} c={n <= stars ? '#e0b021' : '#c9d3cb'} fill={n <= stars ? '#f8d92f' : 'none'} /></button>
            ))}
          </div>
          <Btn w="100%" h={46} label="SUBMIT RATING" onClick={() => void submit()} />
        </Modal>
      )}
    </Screen>
  )
}
