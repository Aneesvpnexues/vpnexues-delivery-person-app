import { useRef, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { Camera, ChevronRight, MessageCircle, Package, Phone } from 'lucide-react'
import { Box, Btn, C, Header, Ic, LinkText, P, Pill, Screen, T, Tile, card, pill, toast } from '../components/kit'
import { api, showError } from '../api/client'
import { Loading, firstName, inr, time, useApi, useSession } from '../api/session'
import { orderScreen } from '../api/orders'
import type { EarningsSummary, OrderListItem } from '../api/types'
import { earning, useOrder } from './OrderFlow'
import deliveredArt from '../assets/art/delivered.png'

const grad = (a: string, b: string) => ({ backgroundImage: `linear-gradient(95deg,${a},${b})`, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' })

/* ---------------- Hand over (customer's 4-digit code) ---------------- */
export function HandOver() {
  const nav = useNavigate()
  const { trial } = useSession()
  const { id, data: o, loading } = useOrder()
  const [code, setCode] = useState(['', '', '', ''])
  const [focus, setFocus] = useState(0)
  const [busy, setBusy] = useState(false)
  const refs = useRef<(HTMLInputElement | null)[]>([])
  if (!id) return <Navigate to={P('1:944')} replace />
  if (loading && !o) return <Loading label="Loading order…" />
  if (!o) return <Navigate to={P('1:944')} replace />
  if (o.status === 'delivered') return <Navigate to={`${P('1:1593')}?id=${o.id}`} replace />
  if (o.status !== 'arrived') return <Navigate to={orderScreen(o.id, o.status)} replace />

  const set = (i: number, v: string) => {
    const d = v.replace(/\D/g, '').slice(-1)
    setCode((p) => p.map((x, j) => (j === i ? d : x)))
    if (d && i < 3) refs.current[i + 1]?.focus()
  }
  const confirm = async () => {
    const c = code.join('')
    if (!/^\d{4}$/.test(c)) return toast('Enter the 4-digit code from the customer')
    setBusy(true)
    try {
      await api(`/v1/orders/${o.id}/deliver`, { body: { code: c } })
      nav(`${P('1:1593')}?id=${o.id}`, { replace: true })
    } catch (e) {
      showError(e)
      setCode(['', '', '', '']); refs.current[0]?.focus()
    } finally {
      setBusy(false)
    }
  }
  const who = firstName(o.customer_name)
  const rows = [
    { icon: Phone, bg: '#eef5db', a: `Call ${who}`, b: 'Number is masked for privacy', go: () => toast(`Calls connect through a masked number (${o.customer_phone_masked}). Coming soon.`) },
    { icon: Camera, bg: '#eef5db', a: 'Leave with security', b: 'Photo proof · needs support approval', go: () => nav(`${P('1:3289')}?order=${o.id}&code=${o.order_code}`) },
    { icon: MessageCircle, bg: '#fff3bf', a: 'Contact support', b: 'Average reply under 2 minutes', go: () => nav(`${P('1:3289')}?order=${o.id}&code=${o.order_code}`) },
  ]
  return (
    <Screen>
      <Header title="Hand over order" to={`${P('1:1223')}?id=${o.id}`} />
      <Box x={283} y={41} w={109} h={55} r={28} bg="#e0eff3" border="1px solid #cfe3ea" style={{ display: 'flex', alignItems: 'center', gap: 7, paddingLeft: 13, font: '700 12px/17px Inter', color: '#145b73', whiteSpace: 'nowrap' }}>
        <span style={{ width: 7, height: 7, borderRadius: 4, background: '#145b73' }} />At doorstep
      </Box>

      <Box x={20} y={112} w={372} h={101} r={24} bg="linear-gradient(103deg,#073e29 0%,#1b7849 100%)" shadow="0 15px 25px rgba(9,83,52,.2)" />
      <Box x={38} y={135} w={56} h={56} r={16} bg="rgba(255,255,255,.13)"><Ic icon={Package} x={16} y={16} s={24} c="#b6dc45" /></Box>
      <T x={108} y={131} s={12} wt={700} lh={16.8} c="#cfe3d0">{`#${o.order_code} · ${o.crates.length} crates`}</T>
      <T x={108} y={150} w={265} s={18} wt={700} lh={24} c="#fff">{`Ask ${who} for their 4-digit delivery code`}</T>

      {[20, 116, 212, 308].map((x, i) => (
        <input key={x} ref={(el) => { refs.current[i] = el }} aria-label={`Delivery code digit ${i + 1}`} inputMode="numeric" maxLength={1} value={code[i]}
          onFocus={(e) => { setFocus(i); e.target.select() }} onChange={(e) => set(i, e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Backspace' && !code[i] && i > 0) refs.current[i - 1]?.focus(); if (e.key === 'Enter') void confirm() }}
          style={{ position: 'absolute', left: x, top: 236, width: 83, height: 70, borderRadius: 18, background: '#fff', textAlign: 'center', font: '700 28px/42px Inter', color: C.ink, outline: 0,
            border: focus === i ? `1.5px solid ${C.green}` : `1px solid ${C.line}`, boxShadow: focus === i ? '0 0 0 4px rgba(9,83,52,.08)' : undefined }} />
      ))}
      <T x={20} y={324} w={372} s={13.5} wt={500} lh={20} c={C.muted} align="center">The customer sees this code in their app and by SMS.</T>
      {trial && <T x={20} y={344} w={372} s={13.5} wt={700} lh={20} c={C.green} align="center">Trial demo orders use code 7391</T>}

      <div style={{ position: 'absolute', left: 20, top: 381, width: 372, height: 250, padding: '15px 16px 0', ...card }}>
        <p style={{ font: '700 11px/15.4px Inter', color: C.accent }}>CUSTOMER NOT ANSWERING?</p>
        {rows.map((r, i) => (
          <button key={r.a} type="button" onClick={r.go} style={{ display: 'flex', alignItems: 'center', gap: 14, width: '100%', height: 73, textAlign: 'left', borderTop: i ? `1px solid ${C.tint5}` : 0, marginTop: i ? 0 : -2 }}>
            <Tile s={44} bg={r.bg} icon={r.icon} />
            <span style={{ flex: 1 }}>
              <span style={{ display: 'block', font: '700 15px/21px Inter', color: C.ink }}>{r.a}</span>
              <span style={{ display: 'block', font: '400 12px/16.8px Inter', color: C.muted, marginTop: 2 }}>{r.b}</span>
            </span>
            <Ic icon={ChevronRight} s={16} c="#8a988f" />
          </button>
        ))}
      </div>
      <Btn y={840} label={busy ? 'CONFIRMING…' : 'CONFIRM DELIVERY'} onClick={() => !busy && void confirm()} />
    </Screen>
  )
}

/* ---------------- Delivered ---------------- */
const FEEDBACK = [['Smooth', 'smooth'], ['Hard to find', 'hard_to_find'], ['Long wait', 'long_wait']] as const

export function Delivered() {
  const nav = useNavigate()
  const { id, data: o, loading } = useOrder()
  const today = useApi<EarningsSummary>('/v1/earnings/summary?range=today')
  const next = useApi<OrderListItem[]>('/v1/orders?tab=active')
  const [fb, setFb] = useState<string | null>(null)
  if (!id) return <Navigate to={P('1:944')} replace />
  if (loading && !o) return <Loading label="Wrapping up…" />
  if (!o) return <Navigate to={P('1:944')} replace />
  const deliveredAt = o.timeline.find((e) => e.status === 'delivered')?.at
  const pickedAt = o.timeline.find((e) => e.status === 'picked_up')?.at
  const tripMin = deliveredAt && pickedAt ? Math.max(1, Math.round((+new Date(deliveredAt) - +new Date(pickedAt)) / 60000)) : null
  const nextOrder = next.data?.[0]

  const feedback = async (key: string) => {
    setFb(key)
    try { await api(`/v1/orders/${o.id}/feedback`, { body: { dropOffEase: key } }); toast('Thanks for the feedback') } catch (e) { showError(e) }
  }
  const line = (y: number, a: string, b: string, big = false) => (
    <>
      <T x={37} y={y} s={13} wt={500} lh={18.2} c={C.muted}>{a}</T>
      <T x={175} y={big ? y - 12 : y - 1} w={200} s={big ? 26 : 14} wt={700} lh={big ? 36 : 20} c={big ? C.accent : '#222'} align="right">{b}</T>
    </>
  )
  return (
    <Screen ol="b">
      <img src={deliveredArt} alt="" style={{ position: 'absolute', left: 96, top: 46, width: 228, height: 190 }} />
      <Pill x={121} y={250} w={170} label={`Delivered · ${time(deliveredAt)}`} {...pill.ok} style={{ justifyContent: 'center' }} />
      <T x={10} y={280} w={392} s={29} wt={700} lh={40.6} align="center">Fresh, and <span style={grad('#4f8a25', '#8c7e0c')}>right on time</span>.</T>
      <T x={20} y={331} w={372} s={13.5} wt={500} lh={20} c={C.muted} align="center">{`#${o.order_code} handed to ${o.customer_name}${tripMin ? ` · ${tripMin} min trip` : ''}`}</T>

      <div style={{ position: 'absolute', left: 20, top: 372, width: 372, height: 187, ...card }} />
      <Box x={39} y={371} w={334} h={4} r={2} bg="linear-gradient(90deg,#247947,#9cc42c 55%,#f8d92f)" />
      {line(405, 'You earned', '+' + inr(earning(o)), true)}
      {line(448, 'Base pay', inr(o.pay_base_paise))}
      {line(481, `Distance pay · ${o.distance_km} km${o.tip_paise ? ` · tip ${inr(o.tip_paise)}` : ''}`, inr(o.pay_distance_paise + o.tip_paise))}
      <Box x={37} y={511} w={338} h={1} bg={C.tint5} />
      {line(525, 'Today so far', today.data ? `${today.data.deliveries} ${today.data.deliveries === 1 ? 'delivery' : 'deliveries'} · ${inr(today.data.net_paise)}` : '…')}

      <Box x={20} y={578} w={372} h={69} r={22} bg="#eef5db" border="1px solid #dfebc3" />
      <T x={37} y={594} s={14} wt={700} lh={20}>Available to withdraw</T>
      <T x={235} y={593} w={140} s={14} wt={700} lh={20} c={C.accent} align="right">{inr(today.data?.availableBalancePaise ?? 0)}</T>
      <T x={37} y={617} w={338} s={12} lh={17} c={C.muted}>Weekly payout every Monday, or withdraw instantly.</T>

      <T x={20} y={663} s={13} wt={700} lh={18.2}>How was the drop-off?</T>
      <div style={{ position: 'absolute', left: 20, top: 689, display: 'flex', gap: 8 }}>
        {FEEDBACK.map(([label, key]) => (
          <button key={key} type="button" onClick={() => void feedback(key)}
            style={{ height: 40, padding: '0 15px', borderRadius: 20, background: fb === key ? C.green : '#fff', border: fb === key ? 0 : `1px solid ${C.line}`, color: fb === key ? '#fff' : C.ink, font: '700 13px/18.2px Inter' }}>
            {label}
          </button>
        ))}
      </div>
      {nextOrder
        ? <Btn y={781} label={`NEXT ORDER · #${nextOrder.order_code}`} onClick={() => nav(orderScreen(nextOrder.id, nextOrder.status))} />
        : <Btn y={781} label="BACK TO ORDERS" to={P('1:944')} />}
      <LinkText y={862} s={14} label="Back to home" to={P('1:814')} />
    </Screen>
  )
}
