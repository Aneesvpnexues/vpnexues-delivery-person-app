import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowUpRight, Download, Minus, Package, ReceiptText, Search, Star, type LucideIcon } from 'lucide-react'
import { BottomNav, Box, Btn, C, Field, Header, P, Pill, RoundBtn, Screen, T, Tile, card, toast } from '../components/kit'
import { date, inr, signedInr, time, useApi } from '../api/session'
import type { EarningsSummary } from '../api/types'

/* ---------------- Earnings ---------------- */
const PERIODS = { Today: 'today', Weekly: 'week', Monthly: 'month', Yearly: 'year' } as const
type Period = keyof typeof PERIODS
const tagFor = (p: Period) => {
  const now = new Date().toISOString()
  return p === 'Today' ? `TODAY · ${date(now, { weekday: 'short', day: 'numeric', month: 'short' }).toUpperCase()}`
    : p === 'Weekly' ? 'THIS WEEK' : p === 'Monthly' ? date(now, { month: 'long', year: 'numeric' }).toUpperCase() : `YEAR ${new Date().getFullYear()}`
}
const HOURS = [7, 9, 11, 13, 15, 17, 19]

export function Earnings() {
  const nav = useNavigate()
  const [p, setP] = useState<Period>('Today')
  const sum = useApi<EarningsSummary>(`/v1/earnings/summary?range=${PERIODS[p]}`)
  const d = sum.data
  const names = Object.keys(PERIODS) as Period[]
  const split = [d?.base_paise ?? 0, d?.distance_paise ?? 0, d?.extras_paise ?? 0]
  const total = split[0] + split[1] + split[2]
  const w = split.map((v) => (total ? Math.max(v ? 6 : 0, Math.round((v / total) * 326)) : 0))
  // Today's earnings in 2-hour buckets from 7 AM.
  const buckets = HOURS.map((h) => (d?.byHour ?? []).filter((x) => x.hour >= h && x.hour < h + 2).reduce((a, x) => a + x.paise, 0))
  const peak = Math.max(...buckets, 1)
  const hot = buckets.indexOf(Math.max(...buckets))
  const avg = d && d.deliveries ? Math.round((d.base_paise + d.distance_paise) / d.deliveries) : 0
  return (
    <Screen ol="c">
      <T x={20} y={49} s={24} wt={700} lh={33.6}>Earnings</T>
      <RoundBtn icon={ReceiptText} to={P('1:1953')} />
      <Box x={20} y={102} w={372} h={56} r={28} bg="#fff" border={`1px solid ${C.line}`} />
      <Box x={24 + names.indexOf(p) * 91} y={106} w={91} h={48} r={24} bg={C.green} shadow="0 6px 10px rgba(9,83,52,.12)" style={{ transition: 'left .2s' }} />
      {names.map((n, i) => (
        <Box key={n} onClick={() => setP(n)} x={24 + i * 91} y={106} w={91} h={48} style={{ font: '700 13px/18.2px Inter', color: n === p ? '#fff' : C.muted }}>{n}</Box>
      ))}

      <Box x={20} y={174} w={372} h={202} r={32} bg="linear-gradient(125deg,#063a2a 0%,#1f7945 100%)" shadow="0 18px 28px rgba(9,83,52,.2)" />
      <T x={40} y={199} s={11} wt={700} lh={15.4} c="#b6dc45">{tagFor(p)}</T>
      {sum.loading && <Pill x={278} y={193} w={94} label="Updating…" bg="#39773f" color="#dfee91" style={{ padding: '0 10px' }} />}
      <T x={40} y={222} s={34} wt={700} lh={46} c="#fff">{inr(d?.net_paise ?? 0, true)}</T>
      <T x={40} y={273} s={13} wt={500} lh={18.2} c="#cfe3d0">{`${d?.deliveries ?? 0} ${d?.deliveries === 1 ? 'delivery' : 'deliveries'} · after deductions`}</T>
      {[[String(d?.deliveries ?? 0), 'Deliveries'], [inr(avg), 'Avg. / delivery'], [inr(d?.availableBalancePaise ?? 0), 'Withdrawable']].map(([a, b], i) => (
        <Box key={b} x={40 + i * 113.5} y={294} w={105} h={60} r={18} bg="rgba(255,255,255,.1)" style={{ textAlign: 'center', paddingTop: 10 }}>
          <p style={{ font: '700 12px/17px Inter', color: '#fff' }}>{a}</p>
          <p style={{ font: '600 11px/15.4px Inter', color: '#dfeee0', marginTop: 5 }}>{b}</p>
        </Box>
      ))}

      <div style={{ position: 'absolute', left: 20, top: 391, width: 372, height: 167, ...card }} />
      <T x={37} y={408} s={16} wt={700} lh={22.4}>Today by hour</T>
      <T x={255} y={410} w={120} s={12} wt={600} lh={17} c={C.muted} align="right">7 AM – 9 PM</T>
      {buckets.map((v, i) => {
        const h = v ? Math.max(8, Math.round((v / peak) * 82)) : 3
        return (
          <div key={i}>
            <Box x={37 + i * 49.5} y={518 - h} w={42} h={h} r={h > 10 ? 10 : 2} bg={v && i === hot ? 'linear-gradient(180deg,#9cc42c,#0b5a36)' : '#dde8cf'} style={{ transition: 'height .2s, top .2s' }} />
            <T x={37 + i * 49.5} y={532} w={42} s={11} wt={600} lh={15.4} c={C.muted} align="center">{['7a', '9a', '11a', '1p', '3p', '5p', '7p'][i]}</T>
          </div>
        )
      })}

      <div style={{ position: 'absolute', left: 20, top: 572, width: 372, height: 174, ...card }} />
      <T x={37} y={590} s={16} wt={700} lh={22.4}>Every rupee, explained</T>
      {total ? (
        <>
          <Box x={37} y={619} w={w[0]} h={12} r="6px 0 0 6px" bg={C.green} />
          <Box x={37 + w[0] + 3} y={619} w={w[1]} h={12} bg="#9cc42c" />
          <Box x={37 + w[0] + w[1] + 6} y={619} w={w[2]} h={12} r="0 6px 6px 0" bg="#e0b021" />
        </>
      ) : <Box x={37} y={619} w={338} h={12} r={6} bg="#e2eadc" />}
      {[['Delivery pay', C.green], ['Distance pay', '#9cc42c'], ['Tips & bonuses', '#e0b021']].map(([l, c], i) => (
        <div key={l}>
          {i > 0 && <Box x={37} y={639 + i * 26} w={338} h={1} bg={C.tint5} />}
          <Box x={37} y={647 + i * 26} w={10} h={10} r={3} bg={c} />
          <T x={59} y={643 + i * 26} s={13} lh={18.2} c="#333">{l}</T>
          <T x={235} y={642 + i * 26} w={140} s={14} wt={700} lh={20} c="#222" align="right">{inr(split[i], true)}</T>
        </div>
      ))}

      <Box onClick={() => nav(P('1:2083'))} x={20} y={758} w={372} h={42} r={21} bg="#eef5db" style={{ font: '700 12px/17px Inter', color: '#3a4a40', textAlign: 'left', paddingLeft: 17 }}>
        {`Next weekly payout · ${date(d?.nextWeeklyPayoutAt, { weekday: 'short', day: 'numeric', month: 'short' }) || 'Monday'} · Withdraw now`}
      </Box>
      <BottomNav active="earnings" />
    </Screen>
  )
}

/* ---------------- Transactions ---------------- */
type Txn = { id: number; type: string; amount_paise: number; description: string; created_at: string; order_code: string | null; utr: string | null; payout_status: string | null }
const ICON: Record<string, { icon: LucideIcon; bg: string; ic?: string }> = {
  delivery_base: { icon: Package, bg: '#eef5db' }, delivery_distance: { icon: Package, bg: '#eef5db' },
  tip: { icon: Star, bg: '#fff3bf', ic: '#825605' }, bonus: { icon: Star, bg: '#fff3bf', ic: '#825605' }, incentive: { icon: Star, bg: '#fff3bf', ic: '#825605' },
  payout: { icon: ArrowUpRight, bg: '#e0eff3', ic: '#145b73' }, payout_fee: { icon: Minus, bg: '#fde0dd', ic: '#c92526' },
  deduction: { icon: Minus, bg: '#fde0dd', ic: '#c92526' }, adjustment: { icon: Minus, bg: '#fde0dd', ic: '#c92526' },
}
const CATS = [['All', 'all'], ['Earnings', 'earnings'], ['Payouts', 'payouts'], ['Bonuses', 'bonuses'], ['Deductions', 'deductions']] as const

export function Transactions() {
  const nav = useNavigate()
  const [cat, setCat] = useState<(typeof CATS)[number][1]>('all')
  const [q, setQ] = useState('')
  const [search, setSearch] = useState('')
  const list = useApi<{ items: Txn[]; nextCursor: number | null }>(`/v1/transactions?filter=${cat}&limit=100${search ? `&search=${encodeURIComponent(search)}` : ''}`)
  const month = useApi<EarningsSummary>('/v1/earnings/summary?range=month')
  const payouts = useApi<{ amount_paise: number; requested_at: string; status: string }[]>('/v1/payouts')
  const thisMonth = new Date().toISOString().slice(0, 7)
  const paidOut = (payouts.data ?? []).filter((x) => x.requested_at.slice(0, 7) === thisMonth && x.status !== 'failed').reduce((a, x) => a + x.amount_paise, 0)
  const monthName = date(new Date().toISOString(), { month: 'long' })
  const items = list.data?.items ?? []
  return (
    <Screen>
      <Header title="Transactions" />
      <RoundBtn icon={Download} x={344} y={41} onClick={() => toast('Statement downloads are coming soon')} />
      <div onKeyDown={(e) => e.key === 'Enter' && setSearch(q.trim())} onBlur={() => setSearch(q.trim())}>
        <Field y={103} value={q} onChange={(v) => { setQ(v); if (!v) setSearch('') }} icon={Search} placeholder="Search order ID or UTR" />
      </div>
      <div style={{ position: 'absolute', left: 20, top: 173, display: 'flex', gap: 6 }}>
        {CATS.map(([label, key]) => (
          <button key={key} type="button" onClick={() => setCat(key)}
            style={{ height: 40, padding: key === 'all' ? '0 12px' : '0 12.5px', borderRadius: 20, background: cat === key ? C.green : '#fff', border: cat === key ? 0 : `1px solid ${C.line}`, color: cat === key ? '#fff' : C.ink, font: '700 12px/17px Inter' }}>
            {label}
          </button>
        ))}
      </div>
      {[[`In · ${monthName}`, '+' + inr(month.data?.net_paise ?? 0), C.accent], [`Paid out · ${monthName}`, inr(paidOut), C.ink]].map(([l, v, c], i) => (
        <div key={l} style={{ position: 'absolute', left: 20 + i * 191, top: 227, width: 181, height: 71, padding: '12px 14px', ...card, borderRadius: 22, boxShadow: 'none' }}>
          <p style={{ font: '600 11px/15.4px Inter', color: C.muted }}>{l}</p>
          <p style={{ font: '700 17px/24px Inter', color: c, marginTop: 3 }}>{v}</p>
        </div>
      ))}
      <T x={20} y={313} s={11} wt={700} lh={15.4} c={C.accent} ls={1.2}>TRANSACTIONS</T>
      <div className="scroll" style={{ position: 'absolute', left: 20, top: 340, width: 372, height: 470, display: 'flex', flexDirection: 'column', gap: 8 }}>
        {items.map((t) => {
          const k = ICON[t.type] ?? ICON.adjustment
          const neg = t.amount_paise < 0
          const sub = `${date(t.created_at)} · ${time(t.created_at)}${t.utr ? ` · UTR ${t.utr}` : ''}${t.payout_status ? ` · ${t.payout_status}` : ''}`
          return (
            <button key={t.id} type="button" onClick={() => t.type === 'payout' && nav(P('1:2083'))}
              style={{ display: 'flex', alignItems: 'center', gap: 15, minHeight: 66, padding: '10px 16px', borderRadius: 22, background: '#fff', textAlign: 'left', flex: 'none' }}>
              <Tile s={44} bg={k.bg} icon={k.icon} c={k.ic} is={18} />
              <span style={{ flex: 1, minWidth: 0 }}>
                <span style={{ display: 'block', font: '700 13px/18.2px Inter', color: C.ink }}>{t.description}</span>
                <span style={{ display: 'block', font: '400 12px/16.8px Inter', color: C.muted, marginTop: 3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</span>
              </span>
              <span style={{ font: '700 15px/21px Inter', color: neg ? (t.type === 'payout' ? C.ink : '#c92526') : C.accent, whiteSpace: 'nowrap' }}>{signedInr(t.amount_paise)}</span>
            </button>
          )
        })}
        {list.loading && !items.length && <p style={{ font: '500 13px/20px Inter', color: C.muted, textAlign: 'center', marginTop: 40 }}>Loading…</p>}
        {!list.loading && !items.length && <p style={{ font: '500 13px/20px Inter', color: C.muted, textAlign: 'center', marginTop: 40 }}>{search ? 'No transactions match your search.' : 'No transactions yet. Earnings appear here after each delivery.'}</p>}
      </div>
      <Btn y={823} kind="outline" icon={Download} label="DOWNLOAD STATEMENT (PDF)" onClick={() => toast('Statement downloads are coming soon')} />
    </Screen>
  )
}
