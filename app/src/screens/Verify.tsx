import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bike, Check, Clock, CreditCard, File, IdCard, Landmark, Leaf, Umbrella, Zap, type LucideIcon } from 'lucide-react'
import { Box, Btn, C, Field, Header, Ic, P, Pill, Screen, T, Tile, card, pill, toast } from '../components/kit'
import { showError } from '../api/client'
import { date, useApi } from '../api/session'
import { pickFile, submitDocument, uploadFile } from '../api/upload'
import type { DocType, DocumentsResponse, PartnerDocument, PayoutMethod } from '../api/types'
import { docPill } from './Docs'
import { aadhaarError } from '../lib/validate'

/* ---------------- Government ID (e-KYC) ---------------- */
type Slot = { file: File; key?: string }

export function GovId() {
  const nav = useNavigate()
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const [aadhaar, setAadhaar] = useState('')
  const [pan, setPan] = useState('')
  const [files, setFiles] = useState<Partial<Record<'aadhaar' | 'pan', Slot>>>({})
  const [consent, setConsent] = useState(false)
  const [busy, setBusy] = useState(false)
  const byType = (t: DocType) => docs.data?.documents.find((d) => d.type === t)
  const a = byType('aadhaar')
  const p = byType('pan')
  const submitted = [a, p].filter((d) => d && d.status !== 'rejected').length
  const aadhaarOk = !aadhaarError(aadhaar)
  const panOk = /^[A-Z]{5}\d{4}[A-Z]$/.test(pan)

  const choose = async (t: 'aadhaar' | 'pan') => {
    const f = await pickFile()
    if (f) setFiles((x) => ({ ...x, [t]: { file: f } }))
  }
  const submit = async () => {
    const jobs: { type: 'aadhaar' | 'pan'; number: string }[] = []
    if (aadhaar || files.aadhaar) {
      if (!aadhaarOk) return toast(aadhaarError(aadhaar))
      if (!files.aadhaar) return toast('Add a photo of your Aadhaar card')
      jobs.push({ type: 'aadhaar', number: aadhaar.replace(/\s/g, '') })
    }
    if (pan || files.pan) {
      if (!panOk) return toast('PAN must look like ABCDE1234F')
      if (!files.pan) return toast('Add a photo of your PAN card')
      jobs.push({ type: 'pan', number: pan })
    }
    if (!jobs.length) return toast('Enter your Aadhaar or PAN details first')
    if (!consent) return toast('Please give consent to continue')
    setBusy(true)
    try {
      for (const j of jobs) {
        const key = files[j.type]!.key ?? (await uploadFile(j.type, files[j.type]!.file, 'front'))
        setFiles((x) => ({ ...x, [j.type]: { ...x[j.type]!, key } }))
        await submitDocument(j.type, [key], { number: j.number, consent: true })
      }
      toast('Submitted for verification')
      nav(P('1:3770'))
    } catch (e) {
      showError(e)
    } finally {
      setBusy(false)
    }
  }
  const stepX = [94, 206, 318]
  const tile = (x: number, t: 'aadhaar' | 'pan', title: string) => {
    const f = files[t]
    const existing = byType(t)
    return (
      <>
        <Box onClick={() => void choose(t)} x={x} y={709} w={180} h={69} r={18} bg={f ? '#fff' : 'transparent'} border={f ? `1px solid ${C.line}` : '1.5px dashed #b6d1ae'} />
        <T x={x + 13} y={722} s={11} wt={700} lh={15.4} c={C.muted} style={{ pointerEvents: 'none' }}>{title}</T>
        <T x={x + 13} y={744} w={160} s={14} wt={600} lh={20} c={f ? C.accent : C.ink} style={{ pointerEvents: 'none', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {f ? `${f.file.name} ✓` : existing ? 'Replace photo' : '+ Add photo'}
        </T>
      </>
    )
  }
  return (
    <Screen>
      <Header title="Government ID" />
      <T x={332} y={57} w={60} s={11} wt={700} lh={15.4} c={C.muted} align="right">e-KYC</T>

      <Box x={20} y={102} w={372} h={195} r={28} bg="linear-gradient(125deg,#063a2a 0%,#1f7945 100%)" shadow="0 18px 28px rgba(9,83,52,.2)" />
      <Ic icon={Clock} x={39} y={123} s={18} c="#b6dc45" />
      <T x={70} y={121} w={300} s={15} wt={700} lh={21} c="#fff">{submitted === 2 ? 'Aadhaar & PAN submitted' : submitted === 1 ? '1 of 2 IDs submitted' : 'Add your Aadhaar and PAN'}</T>
      <T x={70} y={146} w={300} s={12} lh={18} c="#dfeee0">Verification takes <b style={{ color: '#fff' }}>2–24 hours</b>. We’ll send a notification when it’s done — you can keep using the app.</T>
      <Box x={108} y={229} w={84} h={2} bg={submitted ? '#b6dc45' : 'rgba(255,255,255,.25)'} />
      <Box x={220} y={229} w={84} h={2} bg={[a, p].some((d) => d?.status === 'verified') ? '#b6dc45' : 'rgba(255,255,255,.25)'} />
      <Box x={80} y={216} w={28} h={28} r={14} bg={submitted ? '#b6dc45' : 'rgba(255,255,255,.15)'} style={{ font: '700 12px/28px Inter', color: '#fff', textAlign: 'center' }}>{submitted ? <Ic icon={Check} x={7} y={7} s={14} sw={2.2} /> : '1'}</Box>
      <Box x={190} y={214} w={32} h={32} r={16} bg="#fff" border="4px solid #4d8a4a" style={{ font: '700 12px/24px Inter', color: C.green, textAlign: 'center' }}>2</Box>
      <Box x={304} y={216} w={28} h={28} r={14} bg="rgba(255,255,255,.15)" style={{ font: '700 12px/28px Inter', color: '#fff', textAlign: 'center' }}>3</Box>
      {[['Submitted', '#b6dc45'], ['Under review\n2–24 hours', '#fff'], ['Approved', '#b6dc45']].map(([l, c], i) => (
        <T key={i} x={stepX[i] - 70} y={251} w={140} s={11} wt={700} lh={15} c={c} align="center">{l}</T>
      ))}

      <Box onClick={() => toast('DigiLocker verification is coming soon. Enter your details below for now.')} x={20} y={312} w={372} h={116} r={24} bg="#f6faea" border="1.5px solid #9cc42c" />
      <Tile x={38} y={346} s={46} r={14} bg="#fff" border="1px solid #e3ead8" icon={Zap} />
      <T x={97} y={328} w={180} s={15} wt={700} lh={20} style={{ pointerEvents: 'none' }}>Verify instantly with DigiLocker</T>
      <T x={97} y={374} w={190} s={12} lh={21} c={C.muted} style={{ pointerEvents: 'none' }}>Fetches Aadhaar, PAN and DL securely · 1 min</T>
      <Pill x={300} y={359} w={75} label="Soon" {...pill.info} />

      <T x={20} y={452} w={372} s={11} wt={700} lh={15.4} c={C.muted} align="center">or enter manually</T>
      <Field y={475} label="Aadhaar number" value={aadhaar} onChange={(v) => setAadhaar(v.replace(/[^\d ]/g, '').slice(0, 14))} icon={IdCard} inputMode="numeric"
        placeholder={a?.number_masked ?? '12-digit number'} ok={aadhaarOk} right={a ? <Pill label={docPill(a).label} bg={docPill(a).bg} color={docPill(a).color} /> : undefined} />
      <T x={20} y={566} w={340} s={12} lh={18} c={C.muted}>Only the last 4 digits are stored.</T>
      <Field y={614} label="PAN" value={pan} onChange={(v) => setPan(v.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 10))} icon={File}
        placeholder={p?.number_masked ?? 'ABCDE1234F'} ok={panOk} right={p ? <Pill label={docPill(p).label} bg={docPill(p).bg} color={docPill(p).color} /> : undefined} />

      {tile(20, 'aadhaar', 'Aadhaar · photo')}
      {tile(212, 'pan', 'PAN · photo')}

      <Box onClick={() => setConsent(!consent)} x={20} y={799} w={22} h={22} r={4} bg={consent ? C.green : '#fff'} border={consent ? undefined : `1.5px solid ${C.line}`}>
        {consent && <Ic icon={Check} x={3} y={3} s={16} c="#fff" sw={2.2} />}
      </Box>
      <T x={52} y={796} w={340} s={12} lh={17} c={C.muted} onClick={() => setConsent(!consent)}>I consent to VP Nexues using my Aadhaar and PAN only for identity verification (e-KYC), as per UIDAI guidelines.</T>
      <Btn y={840} label={busy ? 'UPLOADING…' : 'SUBMIT FOR VERIFICATION'} onClick={() => !busy && void submit()} />
    </Screen>
  )
}

/* ---------------- Verification dashboard ---------------- */
type VRow = { icon: LucideIcon; bg?: string; title: string; sub: string; status: { label: string; bg: string; color: string }; to?: string }
function Group({ y, label, rows, rowH = 69 }: { y: number; label: string; rows: VRow[]; rowH?: number }) {
  const nav = useNavigate()
  return (
    <div style={{ position: 'absolute', left: 20, top: y, width: 372, padding: '13px 16px 4px', ...card }}>
      <p style={{ font: '700 11px/15.4px Inter', color: C.accent, letterSpacing: 1.2 }}>{label}</p>
      {rows.map((r, i) => (
        <div key={r.title} onClick={() => r.to && nav(P(r.to))} role={r.to ? 'button' : undefined}
          style={{ display: 'flex', alignItems: 'center', gap: 12, height: rowH, marginTop: i ? 0 : 6, borderTop: i ? `1px solid ${C.tint5}` : 0, cursor: r.to ? 'pointer' : undefined }}>
          <Tile s={44} bg={r.bg} icon={r.icon} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <p style={{ font: '700 15px/21px Inter', color: C.ink }}>{r.title}</p>
            <p style={{ font: '400 12px/16.8px Inter', color: C.muted, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.sub}</p>
          </div>
          <Pill label={r.status.label} bg={r.status.bg} color={r.status.color} />
        </div>
      ))}
    </div>
  )
}
const docSub = (d?: PartnerDocument, fallback = 'Not uploaded yet') =>
  !d ? fallback : d.status === 'verified' ? (d.valid_until ? `Valid till ${date(d.valid_until, { month: 'short', year: 'numeric' })}` : `Verified ${date(d.reviewed_at)}`)
    : d.status === 'rejected' ? d.rejection_reason ?? 'Not approved — upload again' : `Submitted ${date(d.submitted_at)} · result within 24 h`

export function Verification() {
  const nav = useNavigate()
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const methods = useApi<PayoutMethod[]>('/v1/payout-methods')
  const by = (t: DocType) => docs.data?.documents.find((d) => d.type === t)
  const bank = methods.data?.find((m) => m.is_primary)
  const total = (docs.data?.requiredCount ?? 6) + 1
  const verified = (docs.data?.verifiedCount ?? 0) + (bank?.verification === 'verified' ? 1 : 0)
  const deg = Math.round((verified / total) * 360)
  const issues = [
    ...(docs.data?.missing ?? []).map((t) => `${t.replace('_', ' ')} missing`),
    ...(docs.data?.documents.filter((d) => d.status === 'in_review').map((d) => `${d.type.replace('_', ' ')} in review`) ?? []),
    ...(!bank ? ['bank not added'] : bank.verification !== 'verified' ? ['bank pending'] : []),
  ]
  const ready = verified === total
  const firstIssue = docs.data?.documents.find((d) => d.expiring_soon) ?? null
  return (
    <Screen ol="b">
      <Header title="Verification" to={P('1:2564')} />
      <div style={{ position: 'absolute', left: 20, top: 103, width: 372, height: 147, ...card, borderRadius: 28 }} />
      <Box x={39} y={121} w={112} h={112} r={56} bg={`conic-gradient(#9cc42c 0deg ${deg}deg,#e2eadc ${deg}deg 360deg)`} />
      <Box x={52} y={134} w={86} h={86} r={43} bg="#fff" style={{ textAlign: 'center', paddingTop: 16 }}>
        <p style={{ font: '700 26px/34px Inter', color: C.ink }}>{verified}/{total}</p>
        <p style={{ font: '600 11px/15px Inter', color: C.muted }}>verified</p>
      </Box>
      <Pill x={169} y={129} label={ready ? 'Ready to deliver' : 'Verification in progress'} {...(ready ? pill.ok : pill.warn)} />
      <T x={169} y={160} w={210} s={15} wt={700} lh={21} style={{ maxHeight: 42, overflow: 'hidden' }}>
        {docs.loading ? 'Checking…' : issues.length ? issues.slice(0, 2).join(', ').replace(/^./, (c) => c.toUpperCase()) : 'Everything is verified'}
      </T>
      <T x={169} y={207} s={12} lh={16.8} c={C.muted}>{`${issues.length} item${issues.length === 1 ? '' : 's'} need${issues.length === 1 ? 's' : ''} attention`}</T>

      <Group y={267} label="IDENTITY" rowH={73} rows={[
        { icon: IdCard, title: 'Aadhaar e-KYC', sub: docSub(by('aadhaar')), status: docPill(by('aadhaar')), to: '1:3651' },
        { icon: File, title: 'PAN card', sub: docSub(by('pan')), status: docPill(by('pan')), to: '1:3651' },
      ]} />
      <Group y={466} label="VEHICLE & LICENCE" rows={[
        { icon: CreditCard, title: 'Driving licence', sub: docSub(by('driving_licence')), status: docPill(by('driving_licence')), to: '1:2564' },
        { icon: Bike, title: 'Vehicle RC', sub: docSub(by('vehicle_rc')), status: docPill(by('vehicle_rc')), to: '1:2807' },
        { icon: by('vehicle_insurance') ? Umbrella : Leaf, bg: '#fff3bf', title: 'Vehicle insurance', sub: docSub(by('vehicle_insurance')), status: docPill(by('vehicle_insurance')), to: '1:2807' },
      ]} />
      <Group y={739} label="BANK ACCOUNT" rowH={52} rows={[
        { icon: Landmark, title: bank ? (bank.type === 'upi' ? bank.upi_vpa! : `${bank.bank_name ?? 'Bank'} ••${bank.account_last4}`) : 'No payout account',
          sub: bank ? (bank.verification === 'verified' ? 'Name matched' : 'Verification pending') : 'Add one to get paid',
          status: bank ? (bank.verification === 'verified' ? { label: 'Verified', ...pill.ok } : { label: 'Pending', ...pill.warn }) : { label: 'Add', ...pill.bad }, to: '1:2711' },
      ]} />
      <Btn y={840} kind={firstIssue ? 'yellow' : 'primary'} label={firstIssue ? 'RENEW EXPIRING DOCUMENT' : ready ? 'BACK TO HOME' : 'COMPLETE MY DOCUMENTS'}
        onClick={() => nav(P(firstIssue ? '1:2564' : ready ? '1:814' : '1:2564'))} />
    </Screen>
  )
}
