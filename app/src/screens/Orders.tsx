import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Check, MapPin, Package, PackagePlus, Search, WifiOff, X } from 'lucide-react'
import { BellBtn, BottomNav, Box, Btn, C, Ic, P, Pill, RoundBtn, Screen, T, Tile, Toggle, card, pill, useDemo } from '../components/kit'
import { date, inr, time, useApi, useSession } from '../api/session'
import { createDemoOrder, orderScreen, statusLabel } from '../api/orders'
import type { OrderListItem, OrderStatus } from '../api/types'
import basket from '../assets/art/basket.png'

type Tab = 'active' | 'upcoming' | 'completed'
const tabIds: Record<Tab, string> = { active: '1:944', upcoming: '17:242', completed: '1:1072' }
const progress: Partial<Record<OrderStatus, number>> = { assigned: 1, accepted: 2, at_pickup: 2, picked_up: 3, arrived: 4 }

function Tabs({ tab, y = 104 }: { tab: Tab; y?: number }) {
  const nav = useNavigate()
  const order: Tab[] = ['active', 'upcoming', 'completed']
  const i = order.indexOf(tab)
  return (
    <>
      <Box x={20} y={y} w={372} h={56} r={28} bg="#fff" border={`1px solid ${C.line}`} />
      <Box x={24 + i * 121.33} y={y + 4} w={121.33} h={48} r={24} bg={C.green} shadow="0 6px 10px rgba(9,83,52,.12)" />
      {order.map((t, j) => (
        <Box key={t} onClick={() => nav(P(tabIds[t]), { replace: true })} x={24 + j * 121.33} y={y + 4} w={121.33} h={48}
          style={{ font: '700 12px/18.2px Inter', color: t === tab ? '#fff' : C.muted }}>
          {t[0].toUpperCase() + t.slice(1)}
        </Box>
      ))}
    </>
  )
}

function OrderCard({ o, primary }: { o: OrderListItem; primary: boolean }) {
  const nav = useNavigate()
  const ready = o.status !== 'assigned'
  const steps = progress[o.status] ?? 0
  const sub = o.scheduled_for ? `Scheduled · ${date(o.scheduled_for)} ${time(o.scheduled_for)}` : `Assigned ${time(o.created_at)} · ${o.crate_count} crates`
  return (
    <div style={{ flex: 'none', width: 372, padding: '16px 16px 16px', ...card }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <p style={{ font: '700 18px/25.2px Inter', color: C.ink }}>#{o.order_code}</p>
          <p style={{ font: '400 12px/16.8px Inter', color: C.muted, marginTop: 2 }}>{sub}</p>
        </div>
        {ready ? <Pill label={statusLabel[o.status]} style={{ marginTop: 10 }} /> : <Pill label="New · accept it" {...pill.warn} style={{ marginTop: 10 }} />}
      </div>
      <div style={{ display: 'flex', gap: 3.7, marginTop: 9 }}>
        {[0, 1, 2, 3].map((i) => (
          <span key={i} style={{ flex: 1, height: 5, borderRadius: 3, background: i < steps ? (ready ? C.accent : '#e9b32c') : '#e2eadc' }} />
        ))}
      </div>
      {[
        { icon: Package, bg: '#eef5db', a: o.hub_name, b: 'Pickup point' },
        { icon: MapPin, bg: '#fff3bf', a: o.customer_name, b: o.drop_address },
      ].map((r, i) => (
        <div key={i} style={{ display: 'flex', gap: 12, marginTop: i ? 6 : 11, alignItems: 'flex-start' }}>
          <Tile bg={r.bg} icon={r.icon} />
          <div style={{ minWidth: 0 }}>
            <p style={{ font: '700 15px/21px Inter', color: C.ink }}>{r.a}</p>
            <p style={{ font: '400 12px/16.8px Inter', color: C.muted, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 290 }}>{r.b}</p>
          </div>
        </div>
      ))}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 11 }}>
        <span style={{ font: '500 13px/18.2px Inter', color: C.muted }}>{`${o.distance_km} km${o.eta_minutes ? ` · ${o.eta_minutes} min` : ''}`}</span>
        <span style={{ font: '700 17px/23.8px Inter', color: C.accent }}>{inr(o.earning_paise)}</span>
      </div>
      <div style={{ marginTop: 14 }}>
        <Btn w="100%" h={primary ? 48 : 40} fs={primary ? 14 : 12} kind={primary ? 'primary' : 'muted'}
          label={o.status === 'assigned' ? 'VIEW & ACCEPT' : primary ? 'CONTINUE ORDER' : 'VIEW ORDER'} onClick={() => nav(orderScreen(o.id, o.status))} />
      </div>
    </div>
  )
}

function Empty({ y, title, text, onDemo }: { y: number; title: string; text: string; onDemo?: () => void }) {
  return (
    <>
      <div style={{ position: 'absolute', left: 20, top: y, width: 372, height: 293, ...card }} />
      <img src={basket} alt="" style={{ position: 'absolute', left: 120, top: y + 31, width: 180, height: 130 }} />
      <Pill x={149} y={y + 163} w={114} label="All caught up" {...pill.ok} style={{ justifyContent: 'center' }} />
      <T x={20} y={y + 197} w={372} s={20} wt={700} lh={28} align="center">{title}</T>
      <T x={40} y={y + 228} w={332} s={13.5} wt={500} lh={20} c={C.muted} align="center">{text}</T>
      {onDemo && <Btn x={56} y={y + 305} w={300} h={44} fs={12} kind="yellow" icon={PackagePlus} label="CREATE A DEMO ORDER (TRIAL)" onClick={onDemo} />}
    </>
  )
}

const ranges = [['Today', 'today'], ['This week', 'week'], ['This month', 'month'], ['All time', 'all']] as const

export default function Orders({ tab, offline }: { tab: Tab; offline?: boolean }) {
  const nav = useNavigate()
  const { online, setOnline } = useDemo()
  const { me, trial } = useSession()
  const [range, setRange] = useState<(typeof ranges)[number][1]>('today')
  const [q, setQ] = useState<string | null>(null)
  const list = useApi<OrderListItem[]>(`/v1/orders?tab=${tab}${tab === 'completed' ? `&range=${range}&limit=100` : ''}`)
  const isOffline = tab === 'active' && (offline || !online)
  const goOnline = async () => { if (await setOnline(true)) nav(P('1:944'), { replace: true }) }
  const demo = trial ? async () => { const id = await createDemoOrder(); if (id) nav(`${P('1:1223')}?id=${id}`) } : undefined
  const items = list.data ?? []

  return (
    <Screen>
      <T x={20} y={49} s={24} wt={700} lh={33.6}>Orders</T>
      {tab === 'completed' ? <RoundBtn icon={Search} onClick={() => setQ(q === null ? '' : null)} /> : <BellBtn dot={false} />}
      <Tabs tab={tab} y={tab === 'completed' ? 102 : 104} />

      {tab === 'active' && !isOffline && (
        <>
          <T x={20} y={176} w={374} s={29} wt={700} lh={40.6}>
            Let’s keep it <span style={{ backgroundImage: 'linear-gradient(95deg,#5d8a22,#8c7e0c)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' }}>fresh.</span>
          </T>
          <T x={20} y={215} s={13} wt={500} lh={18.2} c={C.muted}>{list.loading ? 'Loading your orders…' : `${items.length} active order${items.length === 1 ? '' : 's'}`}</T>
          {!list.loading && !items.length ? (
            <Empty y={250} title="No active orders right now" text="Stay online inside your zone. New orders appear here the moment the hub assigns them." onDemo={demo} />
          ) : (
            <div className="scroll" style={{ position: 'absolute', left: 20, top: 250, width: 372, height: 560, display: 'flex', flexDirection: 'column', gap: 14, paddingBottom: 16 }}>
              {items.map((o, i) => <OrderCard key={o.id} o={o} primary={i === 0} />)}
            </div>
          )}
        </>
      )}

      {isOffline && (
        <>
          <Box x={20} y={178} w={372} h={67} r={22} bg="#fff5d9" border="1px solid #f0dc8c" />
          <Ic icon={WifiOff} x={36} y={203} s={16} c="#795109" />
          <T x={65} y={194} w={255} s={13.5} wt={500} lh={20} c="#795109"><b>You’re offline.</b> Go online to receive new orders.</T>
          <Toggle x={328} y={197} on={false} onChange={() => void goOnline()} />
          <Empty y={264} title={items.length ? `${items.length} order${items.length === 1 ? '' : 's'} still open` : 'No active orders right now'}
            text={items.length ? 'Go online to keep working on your open orders.' : 'Go online inside your zone. New orders appear here the moment the hub assigns them.'} />
          <Btn x={20} y={735} w={198} label="GO ONLINE" onClick={() => void goOnline()} />
          <Btn x={229} y={735} w={163} kind="outline" label="MY ZONE" to={P('1:3906')} />
        </>
      )}

      {tab === 'upcoming' && (
        <>
          <T x={20} y={176} w={374} s={29} wt={700} lh={40.6}>Next in your queue</T>
          <T x={20} y={215} s={13} wt={500} lh={18.2} c={C.muted}>Scheduled orders show up here before they start.</T>
          {!list.loading && !items.length ? (
            <Empty y={250} title="Nothing scheduled yet" text="Orders booked for later in the day will appear here." />
          ) : (
            <div className="scroll" style={{ position: 'absolute', left: 20, top: 250, width: 372, height: 560, display: 'flex', flexDirection: 'column', gap: 14 }}>
              {items.map((o) => <OrderCard key={o.id} o={o} primary={false} />)}
            </div>
          )}
        </>
      )}

      {tab === 'completed' && (
        <>
          {[[String(items.filter((o) => o.status === 'delivered').length), 'Delivered'], [String(items.filter((o) => o.status === 'cancelled').length), 'Cancelled'], [me ? String(me.rating) : '–', 'Rating']].map(([n, l], i) => (
            <div key={l} style={{ position: 'absolute', left: 20 + i * 128, top: 175, width: 116, height: 74, textAlign: 'center', paddingTop: 11, ...card, borderRadius: 18, boxShadow: 'none' }}>
              <p style={{ font: '700 20px/28px Inter', color: C.ink }}>{n}</p>
              <p style={{ font: '600 11px/15.4px Inter', color: C.muted, marginTop: 6 }}>{l}</p>
            </div>
          ))}
          <div style={{ position: 'absolute', left: 20, top: 263, display: 'flex', gap: 9 }}>
            {ranges.map(([label, r]) => {
              const on = range === r
              return (
                <button key={r} type="button" onClick={() => setRange(r)}
                  style={{ height: 40, padding: '0 15px', borderRadius: 20, background: on ? C.green : '#fff', border: on ? 0 : `1px solid ${C.line}`, color: on ? '#fff' : C.ink, font: '700 13px/18.2px Inter', whiteSpace: 'nowrap' }}>
                  {label}
                </button>
              )
            })}
          </div>
          {q !== null && (
            <input autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search order or customer" aria-label="Search orders"
              style={{ position: 'absolute', left: 110, top: 44, width: 224, height: 40, borderRadius: 20, border: `1px solid ${C.line}`, padding: '0 16px', font: '500 13px Inter', outline: 0, background: '#fff' }} />
          )}
          <T x={20} y={321} s={11} wt={700} lh={15.4} c={C.accent} ls={0.3}>{ranges.find(([, r]) => r === range)![0].toUpperCase()}</T>
          {(() => {
            const shown = items.filter((o) => !q || `${o.order_code} ${o.customer_name}`.toLowerCase().includes(q.toLowerCase()))
            if (list.loading) return <T x={20} y={360} w={372} s={13} c={C.muted} align="center">Loading…</T>
            if (!shown.length) return <T x={20} y={370} w={372} s={13.5} wt={500} lh={20} c={C.muted} align="center">{q ? 'No orders match your search.' : 'No completed orders in this period yet.'}</T>
            return (
              <div className="scroll" style={{ position: 'absolute', left: 20, top: 349, width: 372, maxHeight: 460, padding: '0 16px', ...card }}>
                {shown.map((d, i) => {
                  const ok = d.status === 'delivered'
                  return (
                    <div key={d.id} style={{ display: 'flex', gap: 14, padding: '14px 0 12px', borderTop: i ? `1px solid ${C.tint5}` : 0 }}>
                      <Tile s={44} bg={ok ? '#eef5db' : '#fde0dd'} icon={ok ? Check : X} c={ok ? C.green : '#b3261e'} is={18} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <p style={{ font: '700 15px/21px Inter', color: C.ink, marginTop: 3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>#{d.order_code} · {d.customer_name}</p>
                        <p style={{ font: '400 12px/16.8px Inter', color: C.muted, marginTop: 1 }}>{ok ? `Delivered ${date(d.delivered_at)} ${time(d.delivered_at)} · ${d.distance_km} km` : 'Cancelled'}</p>
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 3 }}>
                        <span style={{ font: '700 15px/21px Inter', color: C.ink }}>{ok ? inr(d.earning_paise) : '–'}</span>
                        {ok ? <Pill label="Delivered" {...pill.ok} /> : <Pill label="Cancelled" {...pill.bad} />}
                      </div>
                    </div>
                  )
                })}
              </div>
            )
          })()}
        </>
      )}

      <BottomNav active="orders" />
    </Screen>
  )
}
