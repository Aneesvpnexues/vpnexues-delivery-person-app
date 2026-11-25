import { useRef, useState, type CSSProperties } from 'react'
import { Navigate, useNavigate, useSearchParams } from 'react-router-dom'
import { ArrowLeft, ArrowRight, Check, CornerUpRight, Flashlight, Keyboard, MessageCircle, Navigation, Package, Phone, ScanLine, TriangleAlert } from 'lucide-react'
import { Box, Btn, C, Ic, LinkText, Modal, P, Pill, RoundBtn, Screen, T, card, pill, toast } from '../components/kit'
import { topBleed } from '../components/ui'
import { api, showError } from '../api/client'
import { Loading, initials, inr, time, useApi, useSession } from '../api/session'
import { orderScreen, statusLabel } from '../api/orders'
import type { OrderDetail, OrderStatus } from '../api/types'
import mapDetails from '../assets/art/map-details.png'
import mapTrip from '../assets/art/map-trip.png'

export const avatarBg = 'linear-gradient(135deg,#9cc42c 0%,#247947 100%)'

/** Read ?id= and load that order. */
export function useOrder() {
  const id = useSearchParams()[0].get('id')
  const q = useApi<OrderDetail>(id ? `/v1/orders/${id}` : null)
  return { id, ...q }
}
export const earning = (o: OrderDetail) => o.pay_base_paise + o.pay_distance_paise + o.tip_paise
const mapsUrl = (o: OrderDetail, to: 'pickup' | 'drop') => {
  const [lat, lng] = to === 'pickup' ? [o.pickup.lat, o.pickup.lng] : [o.drop_lat, o.drop_lng]
  return `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}&travelmode=two-wheeler`
}
const openMaps = (url: string) => { window.open(url, '_blank') }

/* ---------------- Order details ---------------- */
const STEPS: { key: OrderStatus; label: string; hint: string }[] = [
  { key: 'assigned', label: 'Order assigned', hint: 'Accept to lock it in' },
  { key: 'accepted', label: 'Accepted', hint: 'Head to the hub' },
  { key: 'picked_up', label: 'Picked up', hint: 'Scan every crate’s QR at the hub' },
  { key: 'arrived', label: 'At doorstep', hint: 'Swipe when you arrive' },
  { key: 'delivered', label: 'Delivered', hint: 'Customer shares a 4-digit code' },
]
const stepIndex = (s: OrderStatus) => (s === 'at_pickup' ? 1 : Math.max(0, STEPS.findIndex((x) => x.key === s)))

export function OrderDetails() {
  const nav = useNavigate()
  const { id, data: o, loading, reload } = useOrder()
  const [busy, setBusy] = useState(false)
  if (!id) return <Navigate to={P('1:944')} replace />
  if (loading && !o) return <Loading label="Loading order…" />
  if (!o) return <Navigate to={P('1:944')} replace />
  const current = stepIndex(o.status)
  const at = (k: OrderStatus) => o.timeline.find((e) => e.status === k)?.at

  const primary = async () => {
    if (o.status === 'assigned') {
      setBusy(true)
      try { await api(`/v1/orders/${o.id}/accept`, { method: 'POST' }); toast('Order accepted. Head to the hub.'); await reload() } catch (e) { showError(e) } finally { setBusy(false) }
    } else if (o.status === 'accepted' || o.status === 'at_pickup') nav(`${P('1:4029')}?id=${o.id}`)
    else nav(orderScreen(o.id, o.status))
  }
  const label = o.status === 'assigned' ? (busy ? 'ACCEPTING…' : 'ACCEPT ORDER') : o.status === 'accepted' || o.status === 'at_pickup' ? 'SCAN PICKUP QR'
    : o.status === 'picked_up' ? 'CONTINUE TRIP' : o.status === 'arrived' ? 'HAND OVER ORDER' : 'BACK TO ORDERS'

  return (
    <Screen>
      <img src={mapDetails} alt="Route map" style={topBleed(232)} />
      <RoundBtn icon={ArrowLeft} x={20} y={48} onClick={() => nav(P('1:944'))} />
      <Pill x={257} y={60} w={135} label={statusLabel[o.status]} style={{ justifyContent: 'center' }} />
      <Pill x={20} y={190} w={121} label={`${o.distance_km} km${o.eta_minutes ? ` · ${o.eta_minutes} min` : ''}`} bg="#fff" color="#3a4a40" dot="#555" style={{ justifyContent: 'center' }} />
      <Btn x={259} y={174} w={133} h={48} fs={12} icon={Navigation} label="NAVIGATE"
        onClick={() => openMaps(mapsUrl(o, current <= 1 ? 'pickup' : 'drop'))} />

      <T x={20} y={248} s={11} wt={700} lh={15.4} c={C.accent} ls={0.3}>ORDER</T>
      <T x={20} y={261} s={28} wt={700} lh={38}>#{o.order_code}</T>
      <T x={292} y={247} w={100} s={12} lh={16.8} c={C.muted} align="right">You earn</T>
      <T x={292} y={266} w={100} s={24} wt={700} lh={32} c={C.accent} align="right">{inr(earning(o))}</T>

      <div style={{ position: 'absolute', left: 20, top: 314, width: 372, height: 262, ...card }} />
      <Box x={46} y={346} w={2} h={Math.max(0, current) * 48} bg={C.accent} />
      <Box x={46} y={346 + current * 48} w={2} h={(4 - current) * 48 - 10} bg="#e2eadc" />
      {STEPS.map((s, i) => {
        const cy = 340 + i * 48
        const done = i < current || o.status === 'delivered'
        const cur = i === current && o.status !== 'delivered'
        const t = at(s.key)
        return (
          <div key={s.key}>
            {cur ? (
              <>
                <Box x={36} y={cy - 11} w={22} h={22} r={11} bg="#e3ecb5" />
                <Box x={40} y={cy - 7} w={14} h={14} r={7} bg="#fff" border={`4px solid ${C.green}`} />
              </>
            ) : done ? (
              <>
                <Box x={40} y={cy - 7} w={14} h={14} r={7} bg="#d9ecd9" />
                <Box x={43} y={cy - 4} w={8} h={8} r={4} bg={C.accent} />
              </>
            ) : (
              <Box x={41} y={cy - 6} w={12} h={12} r={6} bg="#fff" border="2px solid #c9d6c9" />
            )}
            <T x={69} y={cy - 11} s={14} wt={700} lh={19.6} c={done || cur ? C.ink : C.muted}>{s.label}</T>
            <T x={69} y={cy + 9} s={12} lh={16.8} c={C.muted}>{t ? `${time(t)}${i === 2 ? ` · ${o.crates.length} crates` : ''}` : s.hint}</T>
          </div>
        )
      })}

      <div style={{ position: 'absolute', left: 20, top: 592, width: 372, height: 86, ...card }} />
      <Box x={37} y={611} w={48} h={48} r={24} bg={avatarBg} style={{ color: '#fff', font: '700 14px/48px Inter', textAlign: 'center' }}>{initials(o.customer_name)}</Box>
      <T x={97} y={608} s={15} wt={700} lh={21}>{o.customer_name}</T>
      <T x={97} y={628} w={215} s={12} lh={18} c={C.muted} style={{ maxHeight: 36, overflow: 'hidden' }}>{o.drop_address}</T>
      <RoundBtn icon={Phone} x={328} y={611} onClick={() => toast(`Calls connect through a masked number (${o.customer_phone_masked}). Coming soon.`)} />

      <Box x={20} y={694} w={372} h={67} r={22} bg="#fff5d9" border="1px solid #f0dc8c" />
      <Ic icon={MessageCircle} x={36} y={709} s={16} c="#795109" />
      <T x={65} y={707} w={315} s={13.5} lh={20} c="#795109" style={{ maxHeight: 40, overflow: 'hidden' }}>
        <b>Customer note:</b> {o.drop_instructions || 'No special instructions.'}
      </T>

      <Btn y={782} icon={o.status === 'accepted' || o.status === 'at_pickup' ? ScanLine : undefined} label={label}
        onClick={() => (o.status === 'delivered' || o.status === 'cancelled' ? nav(P('1:1072')) : !busy && void primary())} />
      <LinkText y={862} s={14} label="Report a problem with this order" to={`${P('1:3289')}?order=${o.id}&code=${o.order_code}`} />
    </Screen>
  )
}

/* ---------------- Scan pickup QR ---------------- */
const qr = ['###.#.##', '#.##.##.', '###..###', '.......#', '.#....##', '###..#.#', '#.##.#.#', '###.#.##']
const lime = '3px solid #b6dc45'
const corners: CSSProperties[] = [
  { left: 0, top: 0, borderTop: lime, borderLeft: lime, borderTopLeftRadius: 22 },
  { right: 0, top: 0, borderTop: lime, borderRight: lime, borderTopRightRadius: 22 },
  { left: 0, bottom: 0, borderBottom: lime, borderLeft: lime, borderBottomLeftRadius: 22 },
  { right: 0, bottom: 0, borderBottom: lime, borderRight: lime, borderBottomRightRadius: 22 },
]

export function PickupQR() {
  const nav = useNavigate()
  const { trial } = useSession()
  const { id, data: o, loading, reload } = useOrder()
  const [torch, setTorch] = useState(false)
  const [manual, setManual] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  if (!id) return <Navigate to={P('1:944')} replace />
  if (loading && !o) return <Loading label="Loading crates…" />
  if (!o) return <Navigate to={P('1:944')} replace />
  if (!['accepted', 'at_pickup'].includes(o.status)) return <Navigate to={orderScreen(o.id, o.status)} replace />
  const scanned = o.crates.filter((c) => c.scanned).length
  const all = scanned === o.crates.length && o.crates.length > 0

  const scan = async (code: string) => {
    setBusy(true)
    try {
      const r = await api<{ crate: { position: number; label: string }; scanned: number; total: number }>(`/v1/orders/${o.id}/crates/scan`, { body: { qrCode: code.trim() } })
      toast(`Crate ${r.crate.position} of ${r.total} verified · ${r.crate.label}`)
      setManual(null)
      await reload()
    } catch (e) { showError(e) } finally { setBusy(false) }
  }
  // No camera plugin yet: in trial mode the server shares each crate's QR, so a tap simulates the scan.
  const tapScan = () => {
    const next = o.crates.find((c) => !c.scanned)
    if (!next) return toast('All crates are scanned')
    if (trial && next.trialQr) void scan(next.trialQr)
    else setManual('')
  }
  const confirm = async () => {
    if (!all) return toast(`Scan all ${o.crates.length} crates first`)
    setBusy(true)
    try { await api(`/v1/orders/${o.id}/pickup`, { body: {} }); toast('Pickup confirmed. Trip started.'); nav(`${P('1:1359')}?id=${o.id}`, { replace: true }) }
    catch (e) { showError(e) } finally { setBusy(false) }
  }

  return (
    <Screen>
      <Box x={0} y={0} w={412} h={480} bg={`radial-gradient(circle at 50% 48%,${torch ? '#356f4f' : '#24523a'} 0%,#142a1f 62%,#0f2018 100%)`} />
      <Box onClick={() => nav(`${P('1:1223')}?id=${o.id}`)} x={20} y={48} w={48} h={48} r={24} bg="rgba(255,255,255,.13)"><Ic icon={ArrowLeft} x={14} y={14} c="#fff" /></Box>
      <T x={70} y={57} w={272} s={20} wt={700} lh={28} c="#fff" align="center">Scan pickup QR</T>
      <Box onClick={() => setTorch(!torch)} x={344} y={48} w={48} h={48} r={24} bg={torch ? 'rgba(182,220,69,.35)' : 'rgba(255,255,255,.13)'}><Ic icon={Flashlight} x={14} y={14} c="#fff" /></Box>

      <div role="button" aria-label="Scan next crate" onClick={() => !busy && tapScan()} style={{ position: 'absolute', left: 91, top: 115, width: 230, height: 230, cursor: 'pointer' }}>
        {corners.map((c, i) => <div key={i} style={{ position: 'absolute', width: 43, height: 43, ...c }} />)}
      </div>
      <Box x={125} y={149} w={162} h={162} r={14} bg="#f4f6f1" style={{ pointerEvents: 'none' }} />
      {qr.flatMap((row, r) => row.split('').map((c, i) => (c === '#' ? <Box key={`${r}-${i}`} x={137 + i * 16} y={161 + r * 16} w={13} h={13} r={3} bg="#10251a" style={{ pointerEvents: 'none' }} /> : null)))}
      <Box x={111} y={233} w={190} h={3} r={2} bg="#b6dc45" shadow="0 0 16px 5px rgba(182,220,69,.55)" style={{ pointerEvents: 'none' }} />
      {all && <Box x={170} y={194} w={72} h={72} r={36} bg="#1f7a45" border="4px solid #f4f6f1" style={{ pointerEvents: 'none' }}><Ic icon={Check} x={18} y={18} s={28} c="#fff" sw={2.4} /></Box>}
      <T x={20} y={379} w={372} s={14} wt={600} lh={20} c="#b6dc45" align="center">
        {all ? 'All crates verified' : trial ? 'Trial: tap the frame to scan the next crate' : 'Point at the QR label on each crate'}
      </T>

      <Box x={20} y={412} w={372} h={274} r={28} bg="#fff" border={`1px solid ${C.line}`} shadow="0 8px 20px rgba(9,83,52,.06)" />
      <Pill x={39} y={431} w={all ? 102 : 120} label={all ? 'QR verified' : 'Scanning crates'} {...(all ? pill.ok : pill.warn)} />
      <T x={39} y={462} w={250} s={20} wt={700} lh={28}>#{o.order_code}{all ? ' matched' : ''}</T>
      <T x={300} y={452} w={74} s={22} wt={700} lh={30} c={C.accent} align="right">{scanned}/{o.crates.length}</T>
      <T x={39} y={494} s={12} lh={16.8} c={C.muted}>{o.pickup.name}</T>
      {o.crates.slice(0, 2).map((c, i) => (
        <div key={c.id}>
          <Box x={39} y={520 + i * 78} w={334} h={69} r={18} bg={c.scanned ? '#f4f8ea' : '#fbfcf6'} border={c.scanned ? '1px solid #dbe7c2' : '1.5px dashed #c9d6c9'} />
          <Box x={53} y={537 + i * 78} w={36} h={36} r={12} bg="#fff" border="1px solid #e4eadf"><Ic icon={Package} x={8} y={8} s={18} /></Box>
          <T x={101} y={533 + i * 78} s={14} wt={700} lh={19.6}>{`Crate ${c.position} of ${o.crates.length}`}</T>
          <T x={101} y={558 + i * 78} s={12} lh={16.8} c={C.muted}>{`${c.label} · ${(c.weightGrams / 1000).toFixed(1)} kg · ${c.scanned ? 'verified' : 'not scanned'}`}</T>
          {c.scanned && <Ic icon={Check} x={345} y={546 + i * 78} s={16} c={C.accent} sw={2} />}
        </div>
      ))}

      <Box x={20} y={704} w={372} h={67} r={22} bg="#fff5d9" border="1px solid #f0dc8c" />
      <Ic icon={TriangleAlert} x={36} y={720} s={16} c="#795109" />
      <T x={64} y={716} w={320} s={14} lh={21} c="#795109">Seal broken or crate damaged? Don’t pick it up — report it to the hub first.</T>

      <Btn y={792} label={busy ? 'PLEASE WAIT…' : all ? 'CONFIRM PICKUP & START TRIP' : `SCAN ${o.crates.length - scanned} MORE CRATE${o.crates.length - scanned === 1 ? '' : 'S'}`}
        kind={all ? 'primary' : 'muted'} onClick={() => !busy && (all ? void confirm() : tapScan())} />
      <LinkText y={862} s={14} label="Enter crate code manually" onClick={() => setManual('')} />

      {manual !== null && (
        <Modal onClose={() => setManual(null)}>
          <p style={{ font: '700 18px/25px Inter', color: C.ink }}>Enter crate code</p>
          <p style={{ font: '500 13px/19px Inter', color: C.muted, margin: '6px 0 14px' }}>Type the code printed under the QR label.</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, height: 52, border: `1.5px solid ${C.green}`, borderRadius: 16, padding: '0 14px', marginBottom: 16 }}>
            <Ic icon={Keyboard} s={18} c={C.muted} />
            <input autoFocus aria-label="Crate code" value={manual} onChange={(e) => setManual(e.target.value.toUpperCase())} placeholder="VPN-CRATE-…"
              style={{ flex: 1, minWidth: 0, border: 0, outline: 0, background: 'transparent', font: '600 16px Inter', color: C.ink }} />
          </div>
          <Btn w="100%" h={48} label={busy ? 'CHECKING…' : 'VERIFY CRATE'} onClick={() => manual.trim() && !busy && void scan(manual)} />
        </Modal>
      )}
    </Screen>
  )
}

/* ---------------- On the way ---------------- */
export function Delivering() {
  const nav = useNavigate()
  const { id, data: o, loading } = useOrder()
  const [dx, setDx] = useState(0)
  const [busy, setBusy] = useState(false)
  const start = useRef<number | null>(null)
  const max = 306
  if (!id) return <Navigate to={P('1:944')} replace />
  if (loading && !o) return <Loading label="Loading trip…" />
  if (!o) return <Navigate to={P('1:944')} replace />
  if (o.status !== 'picked_up') return <Navigate to={orderScreen(o.id, o.status)} replace />

  const arrive = async () => {
    if (busy) return
    setBusy(true)
    try { await api(`/v1/orders/${o.id}/arrive`, { body: {} }); nav(`${P('1:1488')}?id=${o.id}`, { replace: true }) }
    catch (e) { showError(e); setDx(0) } finally { setBusy(false) }
  }
  const street = o.drop_address.split(',').slice(0, 2).join(',')
  return (
    <Screen>
      <img src={mapTrip} alt="Route map" style={topBleed(500)} />
      <RoundBtn icon={ArrowLeft} x={20} y={54} onClick={() => nav(`${P('1:1223')}?id=${o.id}`)} />
      <Box onClick={() => openMaps(mapsUrl(o, 'drop'))} x={95} y={48} w={297} h={58} r={24} bg="#073d2a" shadow="0 10px 20px rgba(9,83,52,.2)" />
      <Ic icon={CornerUpRight} x={114} y={68} s={18} c="#fff" />
      <T x={141} y={58} w={240} s={15} wt={700} lh={21} c="#fff" style={{ pointerEvents: 'none' }}>Open turn-by-turn in Maps</T>
      <T x={141} y={79} w={240} s={12} lh={16.8} c="#cfe3d0" style={{ pointerEvents: 'none', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{street}</T>
      <Box onClick={() => nav(P('1:3533'))} x={340} y={300} w={52} h={52} r={26} bg="#c92526" shadow="0 10px 20px rgba(9,83,52,.2)" style={{ color: '#fff', font: '700 12px/17px Inter' }}>SOS</Box>

      <Box x={0} y={484} w={412} h={431} r="28px 28px 0 0" bg="#fff" shadow="0 -8px 24px rgba(9,83,52,.08)" />
      <Box x={186} y={494} w={40} h={4} r={2} bg={C.line} />
      <Box x={20} y={514} w={130} h={54} r={27} bg="#e0eff3" border="1px solid #cfe3ea" style={{ display: 'flex', alignItems: 'center', gap: 7, paddingLeft: 13, font: '700 12px/17px Inter', color: '#145b73', whiteSpace: 'nowrap' }}>
        <span style={{ width: 7, height: 7, borderRadius: 4, background: '#145b73' }} />Out for delivery
      </Box>
      <T x={252} y={533} w={140} s={12} wt={700} lh={16.8} c={C.muted} align="right">#{o.order_code}</T>
      <T x={20} y={577} s={36} wt={700} lh={44}>{o.eta_minutes ? `${o.eta_minutes} min` : `${o.distance_km} km`}</T>
      <T x={20} y={619} s={13} wt={500} lh={18.2} c={C.muted}>{`${o.distance_km} km trip · picked up ${time(o.timeline.find((e) => e.status === 'picked_up')?.at)}`}</T>
      <T x={292} y={610} w={100} s={18} wt={700} lh={25} c={C.accent} align="right">{inr(earning(o))}</T>
      <Box x={20} y={652} w={372} h={7} r={4} bg="#e2eadc" />
      <Box x={20} y={652} w={208} h={7} r={4} bg="linear-gradient(90deg,#247947,#9cc42c)" />
      <Box x={20} y={676} w={44} h={44} r={22} bg={avatarBg} style={{ color: '#fff', font: '700 13px/44px Inter', textAlign: 'center' }}>{initials(o.customer_name)}</Box>
      <T x={76} y={679} w={200} s={15} wt={700} lh={21}>{o.customer_name}</T>
      <T x={76} y={699} w={200} s={12} lh={16.8} c={C.muted} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{o.drop_address}</T>
      <RoundBtn icon={MessageCircle} x={284} y={674} onClick={() => nav(`${P('1:3289')}?order=${o.id}&code=${o.order_code}`)} />
      <RoundBtn icon={Phone} x={344} y={674} onClick={() => toast(`Calls connect through a masked number (${o.customer_phone_masked}). Coming soon.`)} />
      {o.drop_instructions && <T x={20} y={738} w={372} s={12.5} lh={18} c="#795109"><b>Note:</b> {o.drop_instructions}</T>}

      <Box x={20} y={824} w={372} h={63} r={32} bg="linear-gradient(90deg,#dfeac2,#eef5db)" border="1px solid #c5d9a4" />
      <T x={84} y={845} w={300} s={14} wt={700} lh={21} c={C.green} align="center" style={{ opacity: 1 - dx / max }}>{busy ? 'MARKING ARRIVED…' : 'SWIPE – I’VE ARRIVED'}</T>
      <button type="button" aria-label="Swipe when arrived" onClick={() => dx === 0 && void arrive()}
        onPointerDown={(e) => { start.current = e.clientX; e.currentTarget.setPointerCapture(e.pointerId) }}
        onPointerMove={(e) => { if (start.current !== null) setDx(Math.max(0, Math.min(max, (e.clientX - start.current) * (412 / Math.min(412, window.innerWidth))))) }}
        onPointerUp={() => { if (start.current !== null) { start.current = null; if (dx > max * 0.7) void arrive(); else setDx(0) } }}
        style={{ position: 'absolute', left: 27 + dx, top: 830, width: 52, height: 52, borderRadius: 26, background: C.green, boxShadow: '0 8px 16px rgba(9,83,52,.25)', touchAction: 'none' }}>
        <Ic icon={ArrowRight} x={16} y={16} c="#fff" />
      </button>
    </Screen>
  )
}
