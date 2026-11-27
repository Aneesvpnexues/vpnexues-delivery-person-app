import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { AtSign, Check, ChevronRight, Landmark, Lock, Plus, Star, Trash2, TriangleAlert, Zap } from 'lucide-react'
import { Box, Btn, C, Field, Header, Ic, LinkText, Modal, P, Pill, Screen, Steps, T, Tile, Toggle, card, pill, toast } from '../components/kit'
import { api, showError } from '../api/client'
import { date, inr, useApi, useSession } from '../api/session'
import type { DocumentsResponse, EarningsSummary, PayoutMethod } from '../api/types'
import { accountError, ifscError, nameError, upiError } from '../lib/validate'

const hero = 'linear-gradient(125deg,#063a2a 0%,#1f7945 100%)'
const chip = (on: boolean): React.CSSProperties => ({ height: 40, padding: '0 15px', borderRadius: 20, background: on ? C.green : '#fff', border: on ? 0 : `1px solid ${C.line}`, color: on ? '#fff' : C.ink, font: '700 13px/18.2px Inter', whiteSpace: 'nowrap' })
const methodName = (m: PayoutMethod) => (m.type === 'upi' ? m.upi_vpa! : `${m.bank_name || 'Bank'} • • ${m.account_last4}`)
const verifyPill = (m: PayoutMethod) => (m.verification === 'verified' ? { label: 'Verified', ...pill.ok } : m.verification === 'failed' ? { label: 'Failed', ...pill.bad } : { label: 'Pending', ...pill.warn })
const FEE = 1000
const MIN = 10000

/* ---------------- Bank payout ---------------- */
export function BankPayout() {
  const nav = useNavigate()
  const sum = useApi<EarningsSummary>('/v1/earnings/summary?range=week')
  const methods = useApi<PayoutMethod[]>('/v1/payout-methods')
  const [instant, setInstant] = useState(true)
  const [amount, setAmount] = useState(0)
  const [busy, setBusy] = useState(false)
  // One key per payout attempt: retries after a network error reuse it, so the server never pays twice.
  const [idem, setIdem] = useState(() => crypto.randomUUID())
  const balance = sum.data?.availableBalancePaise ?? 0
  const max = Math.max(0, balance - FEE)
  const primary = methods.data?.find((m) => m.is_primary)
  const fee = instant ? FEE : 0
  const fmt = (paise: number) => (paise / 100).toLocaleString('en-IN')

  const transfer = async () => {
    if (!instant) return toast(`Your balance is paid automatically on ${date(sum.data?.nextWeeklyPayoutAt, { weekday: 'long', day: 'numeric', month: 'short' })}`)
    if (!primary) return toast('Add a bank account or UPI ID first')
    if (amount < MIN) return toast(`Minimum instant payout is ${inr(MIN)}`)
    if (amount > max) return toast(`You can withdraw up to ${inr(max)} (after the ${inr(FEE)} fee)`)
    setBusy(true)
    try {
      await api('/v1/payouts/instant', { body: { amountPaise: amount }, headers: { 'Idempotency-Key': idem } })
      setIdem(crypto.randomUUID())
      toast(`${inr(amount)} payout requested to ${methodName(primary)}`)
      nav(P('1:1953'))
    } catch (e) {
      showError(e)
    } finally {
      setBusy(false)
    }
  }
  const opt = (y: number, h: number, on: boolean, title: string, sub: string, tag: React.ReactNode, pick: () => void) => (
    <>
      <Box onClick={pick} x={20} y={y} w={372} h={h} r={22} bg={on ? '#f6faea' : '#fff'} border={on ? `1.5px solid ${C.green}` : `1.5px solid ${C.line}`} shadow={on ? '0 0 0 4px rgba(9,83,52,.08)' : undefined} />
      <Box x={36} y={y + 24} w={20} h={20} r={10} bg="#fff" border={on ? `6px solid ${C.green}` : '1.5px solid #c9d3cb'} style={{ pointerEvents: 'none' }} />
      <T x={69} y={y + 15} s={15} wt={700} lh={21} style={{ pointerEvents: 'none' }}>{title}</T>
      <T x={69} y={y + 38} s={12} lh={16.8} c={C.muted} style={{ pointerEvents: 'none' }}>{sub}</T>
      {tag}
    </>
  )
  return (
    <Screen>
      <Header title="Bank payout" />
      <Box x={20} y={102} w={372} h={114} r={28} bg={hero} shadow="0 15px 25px rgba(9,83,52,.2)" />
      <T x={38} y={121} s={12} wt={700} lh={16.8} c="#cfe3d0">Available to withdraw</T>
      <T x={38} y={140} s={28} wt={700} lh={40} c="#fff">{sum.loading && !sum.data ? '…' : inr(balance, true)}</T>
      <T x={38} y={187} s={12} lh={16.8} c="#cfe3d0">{`Auto-payout ${date(sum.data?.nextWeeklyPayoutAt, { weekday: 'short', day: 'numeric', month: 'short' }) || 'every Monday'}`}</T>

      {opt(231, 69, !instant, 'Weekly payout', 'Free · lands Monday by 6 PM', <Pill x={314} y={245} w={62} label="Free" {...pill.ok} />, () => setInstant(false))}
      {opt(314, 70, instant, 'Instant payout', `Within 30 min · min ${inr(MIN)}`, <Pill x={294} y={328} w={82} label={`${inr(FEE)} fee`} {...pill.warn} />, () => setInstant(true))}

      <div style={{ position: 'absolute', left: 20, top: 400, width: 372, height: 163, ...card }} />
      <T x={36} y={416} s={13} wt={700} lh={18.2}>Amount</T>
      <T x={36} y={446} s={24} wt={700} lh={34} c={C.muted}>₹</T>
      <input aria-label="Amount" inputMode="numeric" placeholder="0" value={amount ? fmt(amount) : ''} onChange={(e) => setAmount((Number(e.target.value.replace(/\D/g, '')) || 0) * 100)}
        style={{ position: 'absolute', left: 62, top: 438, width: 300, height: 48, border: 0, outline: 0, background: 'transparent', font: '700 32px/48px Inter', color: C.ink }} />
      <Box x={36} y={494} w={339} h={2} bg={C.green} />
      <div style={{ position: 'absolute', left: 37, top: 507, display: 'flex', gap: 9 }}>
        {[50000, 100000, 200000].map((v) => (
          <button key={v} type="button" onClick={() => setAmount(Math.min(v, max))} style={chip(amount === v)}>{inr(v)}</button>
        ))}
        <button type="button" onClick={() => setAmount(max)} style={chip(amount === max && max > 0)}>All</button>
      </div>

      <div style={{ position: 'absolute', left: 20, top: 579, width: 372, height: 71, ...card }} />
      <Tile x={35} y={592} s={44} icon={primary?.type === 'upi' ? Zap : Landmark} />
      <T x={90} y={593} w={200} s={15} wt={700} lh={21}>{primary ? methodName(primary) : 'No payout account yet'}</T>
      <T x={90} y={617} w={200} s={12} lh={16.8} c={C.muted}>{primary ? `${primary.verification === 'verified' ? 'Verified' : 'Verification pending'} · Primary` : 'Add one to get paid'}</T>
      <T x={300} y={605} w={77} s={14} wt={700} lh={20} c={C.green} align="right" onClick={() => nav(P(primary ? '1:2711' : '17:1065'))}>{primary ? 'Change' : 'Add'}</T>

      {[['Amount', inr(amount, true)], [instant ? 'Instant fee (from balance)' : 'Fee', fee ? inr(fee, true) : 'Free']].map(([a, b], i) => (
        <div key={a}>
          <T x={24} y={666 + i * 27} s={13} lh={18.2} c={C.muted}>{a}</T>
          <T x={240} y={665 + i * 27} w={148} s={14} wt={700} lh={20} c="#222" align="right">{b}</T>
        </div>
      ))}
      <T x={24} y={721} s={14} wt={700} lh={20}>You receive</T>
      <T x={220} y={717} w={168} s={17} wt={700} lh={24} c={C.accent} align="right">{inr(amount, true)}</T>

      <Btn y={811} label={busy ? 'REQUESTING…' : instant ? `TRANSFER ${inr(amount)} NOW` : 'KEEP WEEKLY PAYOUT'} onClick={() => !busy && void transfer()} />
      <T x={20} y={876} w={372} s={11.5} lh={16} c={C.muted} align="center">Payouts go only to your verified primary account.</T>
    </Screen>
  )
}

/* ---------------- shared bank-account form ---------------- */
type BankValue = { name: string; acc: string; acc2: string; ifsc: string; bank: string; type: 'savings' | 'current' }
function useBankForm(holder = '') {
  return useState<BankValue>({ name: holder, acc: '', acc2: '', ifsc: '', bank: '', type: 'savings' })
}
function BankForm({ top, v, set }: { top: number; v: BankValue; set: (v: BankValue) => void }) {
  const match = v.acc.length >= 9 && v.acc === v.acc2
  const found = /^[A-Z]{4}0[A-Z0-9]{6}$/.test(v.ifsc)
  return (
    <>
      <Field y={top} label="Account holder name" value={v.name} onChange={(name) => set({ ...v, name })} placeholder="As on your bank passbook" />
      <T x={20} y={top + 89} s={12} wt={500} lh={16.8} c={C.muted}>Must match the name on your Aadhaar.</T>
      <Field y={top + 122} label="Account number" value={v.acc} onChange={(x) => set({ ...v, acc: x.replace(/\D/g, '') })} type="password" inputMode="numeric" placeholder="9–18 digits" right={<Ic icon={Lock} s={19} />} />
      <Field y={top + 217} label="Re-enter account number" value={v.acc2} onChange={(x) => set({ ...v, acc2: x.replace(/\D/g, '') })} inputMode="numeric" ok={match} right={match ? <Ic icon={Check} s={19} sw={2} /> : undefined} />
      <Field y={top + 311} label="IFSC code" value={v.ifsc} onChange={(x) => set({ ...v, ifsc: x.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 11) })} placeholder="e.g. HDFC0001234" right={found ? <Pill label="Valid" {...pill.ok} /> : undefined} />
      <Box x={20} y={top + 405} w={372} h={73} r={22} bg="#eef5db" border="1px solid #ddebc3" />
      <Tile x={35} y={top + 420} s={44} bg="#fff" border="1px solid #e3ead8" icon={Landmark} is={20} />
      <input aria-label="Bank name" value={v.bank} onChange={(e) => set({ ...v, bank: e.target.value })} placeholder="Bank name (e.g. HDFC Bank)"
        style={{ position: 'absolute', left: 90, top: top + 421, width: 280, height: 22, border: 0, outline: 0, background: 'transparent', font: '700 15px/21px Inter', color: C.ink }} />
      <T x={90} y={top + 445} s={12} wt={500} lh={16.8} c={C.muted}>{found ? `Branch code ${v.ifsc.slice(5)}` : 'Enter the IFSC from your cheque book'}</T>
      <T x={20} y={top + 492} s={13} wt={600} lh={18.2}>Account type</T>
      <div style={{ position: 'absolute', left: 20, top: top + 517, display: 'flex', gap: 9 }}>
        {(['savings', 'current'] as const).map((t) => <button key={t} type="button" onClick={() => set({ ...v, type: t })} style={chip(v.type === t)}>{t[0].toUpperCase() + t.slice(1)}</button>)}
      </div>
    </>
  )
}
async function saveBank(v: BankValue) {
  const bad = nameError(v.name, 'the account holder’s name') || accountError(v.acc)
  if (bad) { toast(bad); return false }
  if (!v.acc2) { toast('Re-enter your account number'); return false }
  if (v.acc !== v.acc2) { toast('The account numbers don’t match'); return false }
  const ifsc = ifscError(v.ifsc)
  if (ifsc) { toast(ifsc); return false }
  if (v.bank.trim() && v.bank.trim().length < 3) { toast('Enter a valid bank name'); return false }
  try {
    await api('/v1/payout-methods', { body: { type: 'bank_account', accountHolderName: v.name.trim(), accountNumber: v.acc, confirmAccountNumber: v.acc2, ifsc: v.ifsc, bankName: v.bank.trim() || undefined, accountType: v.type, makePrimary: true } })
    toast('Bank account saved. Verification takes a few minutes.')
    return true
  } catch (e) {
    showError(e)
    return false
  }
}

export function BankOnboarding() {
  const nav = useNavigate()
  const { me } = useSession()
  const [v, set] = useBankForm(me?.full_name ?? '')
  const [busy, setBusy] = useState(false)
  return (
    <Screen ol="b">
      <Header title="Payout account" to={P('1:583')} />
      <Steps step={5} />
      <T x={20} y={122} w={382} s={24} wt={700} lh={30}>{'Where should we send your\nearnings?'}</T>
      <T x={20} y={188} s={13.5} wt={500} lh={18.9} c={C.muted}>Weekly payouts every Monday, straight to your bank.</T>
      <BankForm top={220} v={v} set={set} />
      <Btn y={792} label={busy ? 'SAVING…' : 'VERIFY & FINISH'} onClick={async () => { if (busy) return; setBusy(true); if (await saveBank(v)) nav(P('1:3906')); setBusy(false) }} />
      <LinkText y={862} label="Use a UPI ID instead" to={P('1:2195')} />
    </Screen>
  )
}

/* ---------------- Add payout method (UPI / bank) ---------------- */
function MethodTabs({ mode }: { mode: 'bank' | 'upi' }) {
  const nav = useNavigate()
  return (
    <>
      <Box x={20} y={105} w={372} h={56} r={28} bg="#fff" border={`1px solid ${C.line}`} />
      <Box x={mode === 'upi' ? 206 : 24} y={109} w={182} h={48} r={24} bg={C.green} shadow="0 6px 10px rgba(9,83,52,.12)" />
      <Box onClick={() => nav(P('17:1065'), { replace: true })} x={24} y={109} w={182} h={48} style={{ font: '700 13px/18.2px Inter', color: mode === 'bank' ? '#fff' : C.muted }}>Bank account</Box>
      <Box onClick={() => nav(P('1:2195'), { replace: true })} x={206} y={109} w={182} h={48} style={{ font: '700 13px/18.2px Inter', color: mode === 'upi' ? '#fff' : C.muted }}>UPI ID</Box>
    </>
  )
}

export function AddPayout() {
  const nav = useNavigate()
  const methods = useApi<PayoutMethod[]>('/v1/payout-methods')
  const [upi, setUpi] = useState('')
  const [primary, setPrimary] = useState(true)
  const [backup, setBackup] = useState(true)
  const [busy, setBusy] = useState(false)
  const handle = '@' + (upi.split('@')[1] ?? '')
  const valid = /^[\w.-]{2,}@[a-z]{2,}$/i.test(upi)
  const bank = methods.data?.find((m) => m.type === 'bank_account')
  const save = async () => {
    const bad = upiError(upi)
    if (bad) return toast(bad)
    setBusy(true)
    try {
      await api('/v1/payout-methods', { body: { type: 'upi', upiVpa: upi.trim(), makePrimary: primary, keepBankAsBackup: backup } })
      toast('UPI ID saved. Verification takes a few minutes.')
      nav(P('1:2711'))
    } catch (e) { showError(e) } finally { setBusy(false) }
  }
  return (
    <Screen>
      <Header title="Add payout method" />
      <MethodTabs mode="upi" />
      <Box x={20} y={178} w={372} h={90} r={24} bg="#eef5db" border="1px solid #ddebc3" />
      <Tile x={37} y={197} s={52} r={16} bg="#fff" border="1px solid #e3ead8" icon={Zap} is={24} />
      <T x={102} y={195} s={16} wt={700} lh={22.4}>Get paid to UPI</T>
      <T x={102} y={219} w={280} s={12} lh={18} c="#333">Instant payouts land in seconds, any day of the week.</T>

      <Field y={286} label="UPI ID" value={upi} onChange={(x) => setUpi(x.trim())} icon={AtSign} placeholder="yourname@okhdfcbank" right={valid ? <Pill label="Looks right" {...pill.ok} /> : undefined} />
      <T x={20} y={381} w={372} s={12} lh={16.8} c={C.muted}>We check the name on this UPI ID against your Aadhaar after you save.</T>
      <T x={20} y={414} s={13} wt={700} lh={18.2}>Common handles</T>
      <div style={{ position: 'absolute', left: 20, top: 431, width: 300, display: 'flex', flexWrap: 'wrap', gap: '8px 9px' }}>
        {['@okhdfcbank', '@ybl', '@oksbi', '@paytm'].map((h) => (
          <button key={h} type="button" onClick={() => setUpi((upi.split('@')[0] || 'name') + h)} style={chip(handle === h)}>{h}</button>
        ))}
      </div>

      <div style={{ position: 'absolute', left: 20, top: 536, width: 372, height: 139, ...card }} />
      {([['Set as primary payout method', 'Weekly and instant payouts go here', primary, setPrimary], [bank ? `Keep ${methodName(bank)} as backup` : 'Keep my bank account as backup', 'Used if a UPI payout fails', backup, setBackup]] as const).map(([a, b, v, set], i) => (
        <div key={a}>
          {i > 0 && <Box x={36} y={605} w={339} h={1} bg={C.tint5} />}
          <T x={36} y={553 + i * 66} w={280} s={15} wt={700} lh={21}>{a}</T>
          <T x={36} y={576 + i * 66} s={12} lh={16.8} c={C.muted}>{b}</T>
          <Toggle x={326} y={557 + i * 66} on={v} onChange={set} onColor={C.green} />
        </div>
      ))}

      <Box x={20} y={692} w={372} h={87} r={22} bg="#fff5d9" border="1px solid #f0dc8c" />
      <Ic icon={TriangleAlert} x={36} y={708} s={16} c="#795109" />
      <T x={64} y={704} w={315} s={13.5} lh={20} c="#795109">For your safety, payouts only go to verified accounts. We’ll notify you when this UPI ID is verified.</T>
      <Btn y={782} label={busy ? 'SAVING…' : 'SAVE UPI ID'} onClick={() => !busy && void save()} />
      <LinkText y={861} label="Cancel" onClick={() => nav(-1)} />
    </Screen>
  )
}

export function EditBankAccount() {
  const nav = useNavigate()
  const { me } = useSession()
  const [v, set] = useBankForm(me?.full_name ?? '')
  const [busy, setBusy] = useState(false)
  return (
    <Screen ol="b">
      <Header title="Add bank account" to={P('1:2711')} />
      <T x={20} y={122} w={382} s={24} wt={700} lh={30}>{'Where should we send your\nearnings?'}</T>
      <T x={20} y={188} s={13.5} wt={500} lh={18.9} c={C.muted}>This becomes your primary payout account.</T>
      <BankForm top={220} v={v} set={set} />
      <Btn y={782} label={busy ? 'SAVING…' : 'SAVE BANK ACCOUNT'} onClick={async () => { if (busy) return; setBusy(true); if (await saveBank(v)) nav(P('1:2711')); setBusy(false) }} />
      <LinkText y={862} label="Use a UPI ID instead" to={P('1:2195')} />
    </Screen>
  )
}

/* ---------------- Bank & UPI ---------------- */
export function BankDetails() {
  const nav = useNavigate()
  const methods = useApi<PayoutMethod[]>('/v1/payout-methods')
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const [pick, setPick] = useState<PayoutMethod | null>(null)
  const list = methods.data ?? []
  const primary = list.find((m) => m.is_primary) ?? list[0]
  const others = useMemo(() => list.filter((m) => m !== primary), [list, primary])
  const pan = docs.data?.documents.find((d) => d.type === 'pan')

  const makePrimary = async (m: PayoutMethod) => {
    try { await api(`/v1/payout-methods/${m.id}/primary`, { method: 'PUT' }); toast(`${methodName(m)} is now your primary account`); setPick(null); await methods.reload() } catch (e) { showError(e) }
  }
  const remove = async (m: PayoutMethod) => {
    try { await api(`/v1/payout-methods/${m.id}`, { method: 'DELETE' }); toast('Payout method removed'); setPick(null); await methods.reload() } catch (e) { showError(e) }
  }
  const row = (y: number, a: string, b: string, right: React.ReactNode, go?: () => void) => (
    <>
      <T x={36} y={y} s={15} wt={700} lh={21}>{a}</T>
      <T x={36} y={y + 23} w={250} s={12} lh={16.8} c={C.muted}>{b}</T>
      {right}
      {go && <Box onClick={go} x={20} y={y - 14} w={372} h={70} />}
    </>
  )
  return (
    <Screen>
      <Header title="Bank & UPI" to={P('1:2301')} />
      <Box x={20} y={104} w={372} h={200} r={28} bg="linear-gradient(140deg,#0a4a30 0%,#2f7a3b 55%,#479440 100%)" shadow="0 18px 28px rgba(9,83,52,.2)" />
      {primary ? (
        <>
          <T x={40} y={122} w={240} s={17} wt={700} lh={24} c="#fff">{primary.type === 'upi' ? 'UPI' : primary.bank_name || 'Bank account'}</T>
          <Pill x={289} y={124} w={83} label="Primary" bg="#f8d92f" color="#3a3e34" dot="#095334" />
          <Box x={40} y={167} w={40} h={30} r={8} bg="linear-gradient(135deg,#f3d721,#c4a300)" />
          <T x={40} y={206} w={330} s={primary.type === 'upi' ? 18 : 22} wt={700} lh={30} c="#fff" ls={primary.type === 'upi' ? 0 : 5}>
            {primary.type === 'upi' ? primary.upi_vpa! : `••••  ••••  ${primary.account_last4}`}
          </T>
          <T x={40} y={258} w={200} s={12} wt={500} lh={16.8} c="#dfeee0">
            {primary.type === 'upi' ? (primary.verification === 'verified' ? 'VERIFIED' : 'VERIFICATION PENDING') : `${(primary.account_holder_name ?? '').toUpperCase()} · ${(primary.account_type ?? '').toUpperCase()}`}
          </T>
          <T x={232} y={258} w={140} s={12} wt={500} lh={16.8} c="#dfeee0" align="right">{primary.ifsc ?? ''}</T>
        </>
      ) : (
        <>
          <T x={40} y={128} w={330} s={20} wt={700} lh={28} c="#fff">{methods.loading ? 'Loading…' : 'No payout account yet'}</T>
          <T x={40} y={164} w={330} s={13} lh={19} c="#dfeee0">Add a bank account or UPI ID to receive your weekly and instant payouts.</T>
          {!methods.loading && <Btn x={40} y={232} w={190} h={44} fs={12} kind="yellow" icon={Plus} label="ADD ACCOUNT" to={P('17:1065')} />}
        </>
      )}

      <div className="scroll" style={{ position: 'absolute', left: 20, top: 322, width: 372, maxHeight: 160, display: 'flex', flexDirection: 'column', gap: 10 }}>
        {(primary ? [primary, ...others] : []).map((m) => (
          <button key={m.id} type="button" onClick={() => setPick(m)}
            style={{ flex: 'none', display: 'flex', alignItems: 'center', gap: 12, height: 75, padding: '0 16px', textAlign: 'left', ...card }}>
            <Tile s={44} icon={m.type === 'upi' ? Zap : Landmark} />
            <span style={{ flex: 1, minWidth: 0 }}>
              <span style={{ display: 'block', font: '700 15px/21px Inter', color: C.ink, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{methodName(m)}</span>
              <span style={{ display: 'block', font: '400 12px/16.8px Inter', color: C.muted }}>{`${m.type === 'upi' ? 'UPI' : 'Bank'} · added ${date(m.created_at)}${m.is_primary ? ' · primary' : m.is_backup ? ' · backup' : ''}`}</span>
            </span>
            <Pill {...verifyPill(m)} />
          </button>
        ))}
      </div>

      <div style={{ position: 'absolute', left: 20, top: 494, width: 372, height: 216, ...card }} />
      {row(509, 'Payout schedule', 'Every Monday · automatic', <T x={300} y={522} w={75} s={14} wt={700} lh={20} c={C.green} align="right">Withdraw</T>, () => nav(P('1:2083')))}
      <Box x={36} y={566} w={339} h={1} bg={C.tint5} />
      {row(580, 'PAN linked for TDS', pan ? `${pan.number_masked ?? 'PAN'} · ${pan.status.replace('_', ' ')}` : 'Add your PAN in Documents', pan ? <Pill x={290} y={590} w={85} label={pan.status === 'verified' ? 'Linked' : 'In review'} {...(pan.status === 'verified' ? pill.ok : pill.warn)} /> : <Ic icon={ChevronRight} x={360} y={593} s={16} c="#8a988f" />, () => nav(P('1:3651')))}
      <Box x={36} y={637} w={339} h={1} bg={C.tint5} />
      {row(651, 'Payout history', 'Every payout with its bank reference', <Ic icon={ChevronRight} x={360} y={664} s={16} c="#8a988f" />, () => nav(P('1:1953')))}

      <Btn y={760} kind="outline" icon={Plus} label="ADD BANK ACCOUNT" to={P('17:1065')} />
      <Btn y={830} kind="outline" icon={Zap} label="ADD UPI ID" to={P('1:2195')} />

      {pick && (
        <Modal onClose={() => setPick(null)}>
          <p style={{ font: '700 18px/25px Inter', color: C.ink }}>{methodName(pick)}</p>
          <p style={{ font: '500 13px/19px Inter', color: C.muted, margin: '6px 0 18px' }}>
            {pick.is_primary ? 'This is your primary payout account.' : 'Make this your primary account, or remove it.'}
          </p>
          {!pick.is_primary && <Btn w="100%" h={48} icon={Star} label="MAKE PRIMARY" onClick={() => void makePrimary(pick)} />}
          {!pick.is_primary && <div style={{ height: 10 }} />}
          <Btn w="100%" h={48} kind={pick.is_primary ? 'muted' : 'danger'} icon={Trash2} label={pick.is_primary ? 'PRIMARY CAN’T BE REMOVED' : 'REMOVE'} onClick={() => (pick.is_primary ? toast('Choose another primary account first') : void remove(pick))} />
        </Modal>
      )}
    </Screen>
  )
}
