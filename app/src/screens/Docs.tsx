import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bike, Camera, ChevronRight, Clock, File, IdCard, LayoutGrid, Leaf, Pencil, Plus, ShieldCheck, TriangleAlert, Umbrella, Upload, type LucideIcon } from 'lucide-react'
import { Box, Btn, C, Field, Header, Ic, LinkText, Modal, P, Pill, RoundBtn, Screen, Steps, T, Tile, card, pill, toast } from '../components/kit'
import { api, showError } from '../api/client'
import { date, useApi, useSession } from '../api/session'
import { DOC_LABEL, quickUpload } from '../api/upload'
import type { DocType, DocumentsResponse, PartnerDocument, Vehicle as VehicleT } from '../api/types'
import rider from '../assets/art/rider.png'

export const docPill = (d?: PartnerDocument) =>
  !d ? { label: 'Not added', ...pill.bad }
    : d.status === 'verified' ? (d.expiring_soon ? { label: 'Expiring', ...pill.warn } : { label: 'Verified', ...pill.ok })
      : d.status === 'in_review' ? { label: 'In review', ...pill.info }
        : d.status === 'rejected' ? { label: 'Re-upload', ...pill.bad }
          : d.status === 'expired' ? { label: 'Expired', ...pill.bad } : { label: 'Pending', ...pill.warn }
const docSub = (d?: PartnerDocument) =>
  !d ? 'Tap to upload' : d.rejection_reason ? d.rejection_reason
    : d.valid_until ? `${d.status === 'expired' ? 'Expired' : 'Valid till'} ${date(d.valid_until, { month: 'short', year: 'numeric' })}`
      : d.number_masked ? d.number_masked : `Submitted ${date(d.submitted_at)}`

/** Upload a document of `type`; Aadhaar and PAN go through the Government ID screen (number + consent). */
export function useDocUpload(reload: () => Promise<void>) {
  const nav = useNavigate()
  const [busy, setBusy] = useState<DocType | null>(null)
  const upload = async (type: DocType) => {
    if (type === 'aadhaar' || type === 'pan') return nav(P('1:3651'))
    setBusy(type)
    try {
      if (await quickUpload(type, { camera: type === 'selfie' ? 'user' : undefined })) { toast(`${DOC_LABEL[type]} submitted for review`); await reload() }
    } catch (e) { showError(e) } finally { setBusy(null) }
  }
  return { upload, busy }
}

/* ---------------- Onboarding: verify documents ---------------- */
const ONBOARD: { type: DocType; icon: LucideIcon; title: string; sub: string; take?: boolean }[] = [
  { type: 'aadhaar', icon: IdCard, title: 'Aadhaar card', sub: 'Number + photo · e-KYC' },
  { type: 'pan', icon: File, title: 'PAN card', sub: 'Needed for payouts (TDS)' },
  { type: 'driving_licence', icon: IdCard, title: 'Driving licence', sub: 'Two-wheeler class' },
  { type: 'vehicle_rc', icon: Bike, title: 'Vehicle RC', sub: 'Registration certificate' },
  { type: 'selfie', icon: Camera, title: 'Live selfie', sub: 'Matched with your Aadhaar photo', take: true },
]

export function DocsOnboarding() {
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const { upload, busy } = useDocUpload(docs.reload)
  const byType = (t: DocType) => docs.data?.documents.find((d) => d.type === t)
  const done = ONBOARD.filter((d) => ['in_review', 'verified'].includes(byType(d.type)?.status ?? '')).length
  return (
    <Screen>
      <Header title="Verify your documents" to="/home" />
      <Steps step={4} />
      <Box x={20} y={122} w={372} h={117} r={23} bg="linear-gradient(103deg,#073e29 0%,#1b7849 100%)" shadow="0 15px 25px rgba(9,83,52,.2)" />
      <T x={38} y={149} s={11} wt={700} lh={15.4} c="#b6dc45" ls={0.8}>KYC PROGRESS</T>
      <T x={300} y={141} w={52} s={23} wt={700} lh={32.2} c="#fff" align="right">{done}</T>
      <T x={357} y={150} s={14} wt={700} lh={19.6} c="#a1c5ae">/ {ONBOARD.length}</T>
      <T x={38} y={178} s={18} wt={700} lh={25.2} c="#fff">{done >= ONBOARD.length ? 'All documents submitted' : 'Upload these to start delivering'}</T>
      <Box x={38} y={213} w={336} h={8} r={4} bg="#4a9371" />
      <Box x={38} y={213} w={(336 * done) / ONBOARD.length} h={8} r={4} bg="linear-gradient(90deg,#247947,#9cc42c)" style={{ transition: 'width .3s' }} />

      {ONBOARD.map((d, i) => {
        const y = 254 + i * 92
        const doc = byType(d.type)
        const ok = doc && ['in_review', 'verified'].includes(doc.status)
        const p = docPill(doc)
        return (
          <div key={d.type}>
            <Box x={20} y={y} w={372} h={80} r={18} bg={ok ? '#fff' : '#fbfcf6'} border={ok ? '1px solid #cce4cb' : '1.5px dashed #b6d1ae'} />
            <Tile x={35} y={y + 18} s={44} bg={ok ? undefined : '#fff'} border={ok ? undefined : '1px solid #e4eadf'} icon={d.icon} is={20} />
            <T x={93} y={y + 17} s={15} wt={700} lh={21}>{d.title}</T>
            <T x={93} y={y + 39} w={175} s={12} wt={500} lh={16.8} c={C.muted}>{doc ? docSub(doc) : d.sub}</T>
            {ok ? (
              <Pill x={287} y={y + 28} w={89} label={p.label} bg={p.bg} color={p.color} style={{ justifyContent: 'center' }} />
            ) : (
              <Btn x={d.take ? 296 : 264} y={y + 16} w={d.take ? 80 : 112} h={48} fs={12} kind={d.take ? 'outline' : 'primary'} icon={d.take ? undefined : Upload}
                label={busy === d.type ? '…' : d.take ? 'TAKE' : doc?.status === 'rejected' ? 'REDO' : 'UPLOAD'} onClick={() => !busy && void upload(d.type)} />
            )}
          </div>
        )
      })}

      <Box x={20} y={717} w={372} h={56} r={16} bg="#e5f3f8" border="1px solid #c4e7f1" />
      <Ic icon={Clock} x={37} y={729} s={16} c="#145b73" />
      <T x={61} y={726} w={320} s={13.5} wt={500} lh={20.25} c="#145b73">Verification usually takes <b>2–24 hours</b>. We’ll notify you as each document is approved.</T>
      <Btn y={792} label="CONTINUE TO BANK DETAILS" to={P('1:708')} />
      <LinkText y={862} label="I’ll finish this later" to={P('1:814')} />
    </Screen>
  )
}

/* ---------------- My documents ---------------- */
const thumbs = { green: 'linear-gradient(135deg,#e6f1cf,#d5e6b4)', blue: 'linear-gradient(135deg,#e0eff5,#c2e1ec)', yellow: 'linear-gradient(135deg,#fff2bb,#fde492)' }
const GRID: { type: DocType; tone: keyof typeof thumbs }[] = [
  { type: 'aadhaar', tone: 'green' }, { type: 'pan', tone: 'green' }, { type: 'driving_licence', tone: 'blue' },
  { type: 'vehicle_rc', tone: 'blue' }, { type: 'vehicle_insurance', tone: 'yellow' }, { type: 'police_verification', tone: 'green' },
]

export function MyDocuments() {
  const nav = useNavigate()
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const { upload, busy } = useDocUpload(docs.reload)
  const byType = (t: DocType) => docs.data?.documents.find((d) => d.type === t)
  const attention = docs.data?.documents.find((d) => d.expiring_soon || d.status === 'rejected' || d.status === 'expired')
  const missing = docs.data?.missing.filter((t) => t !== 'selfie') ?? []
  return (
    <Screen>
      <Header title="My documents" to={P('1:2301')} />
      <RoundBtn icon={Plus} x={344} y={41} to={P('1:3651')} />
      {attention || missing.length ? (
        <>
          <Box x={20} y={102} w={372} h={88} r={22} bg="#fff5d9" border="1px solid #f0dc8c" />
          <Ic icon={TriangleAlert} x={36} y={139} s={16} c="#795109" />
          <T x={64} y={117} w={215} s={13.5} lh={19.5} c="#795109">
            {attention
              ? `${DOC_LABEL[attention.type]} ${attention.status === 'rejected' ? 'was not approved' : attention.status === 'expired' ? 'has expired' : 'expires soon'}. Update it to keep receiving orders.`
              : `${missing.length} document${missing.length === 1 ? '' : 's'} still to upload: ${missing.map((t) => DOC_LABEL[t]).join(', ')}.`}
          </T>
          <Btn x={287} y={126} w={90} h={40} fs={13} kind="yellow" label={attention ? 'UPDATE' : 'UPLOAD'} onClick={() => void upload((attention?.type ?? missing[0]) as DocType)} />
        </>
      ) : (
        <>
          <Box x={20} y={102} w={372} h={88} r={22} bg="#eef5db" border="1px solid #ddebc3" />
          <Ic icon={ShieldCheck} x={36} y={139} s={16} />
          <T x={64} y={125} w={300} s={13.5} lh={19.5} c={C.green}>{docs.loading ? 'Loading your documents…' : 'All your documents are up to date.'}</T>
        </>
      )}

      {GRID.map((g, i) => {
        const d = byType(g.type)
        const x = 20 + (i % 2) * 192
        const y = 204 + Math.floor(i / 2) * 201
        const p = docPill(d)
        return (
          <div key={g.type} onClick={() => !busy && void upload(g.type)} role="button"
            style={{ position: 'absolute', left: x, top: y, width: 180, height: 188, padding: 10, cursor: 'pointer', ...card, borderColor: p.bg === pill.warn.bg ? '#f0dc8c' : C.line, opacity: busy === g.type ? 0.6 : 1 }}>
            <div style={{ position: 'relative', height: 84, borderRadius: 14, background: thumbs[g.tone] }}>
              <span style={{ position: 'absolute', left: 12, top: 14, width: 26, height: 26, borderRadius: 6, background: 'rgba(255,255,255,.75)' }} />
              {[17, 27, 36].map((t) => <span key={t} style={{ position: 'absolute', left: 46, top: t, width: 101, height: 3.5, background: '#a9c4a2' }} />)}
              {!d && <span style={{ position: 'absolute', right: 10, bottom: 10 }}><Ic icon={Upload} s={18} /></span>}
            </div>
            <p style={{ font: '700 15px/21px Inter', color: C.ink, marginTop: 9 }}>{DOC_LABEL[g.type]}</p>
            <p style={{ font: '400 12px/16.8px Inter', color: C.muted, margin: '5px 0 8px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{busy === g.type ? 'Uploading…' : docSub(d)}</p>
            <Pill label={p.label} bg={p.bg} color={p.color} />
          </div>
        )
      })}

      <div onClick={() => nav(P('1:3770'))} role="button" style={{ position: 'absolute', left: 20, top: 822, width: 372, height: 76, cursor: 'pointer', ...card }} />
      <Tile x={37} y={838} s={44} icon={LayoutGrid} is={20} />
      <T x={92} y={838} s={15} wt={700} lh={21} style={{ pointerEvents: 'none' }}>Verification dashboard</T>
      <T x={92} y={861} s={12} lh={16.8} c={C.muted} style={{ pointerEvents: 'none' }}>Status, expiry and renewals in one place</T>
      <Ic icon={ChevronRight} x={360} y={853} s={16} c="#8a988f" />
    </Screen>
  )
}

/* ---------------- My vehicle ---------------- */
const VTYPES = [['Motorbike', 'motorbike'], ['Scooter', 'scooter'], ['Electric scooter', 'electric_scooter'], ['Bicycle', 'bicycle']] as const
const FUELS = [['Petrol', 'petrol'], ['Electric', 'electric'], ['CNG', 'cng'], ['None', 'none']] as const
const label = (list: readonly (readonly [string, string])[], v?: string | null) => list.find(([, k]) => k === v)?.[0] ?? '–'
const chip = (on: boolean): React.CSSProperties => ({ height: 36, padding: '0 12px', borderRadius: 18, background: on ? C.green : '#fff', border: on ? 0 : `1px solid ${C.line}`, color: on ? '#fff' : C.ink, font: '700 12px/17px Inter', whiteSpace: 'nowrap' })

export function Vehicle() {
  const { me } = useSession()
  const v = useApi<VehicleT | null>('/v1/vehicle')
  const docs = useApi<DocumentsResponse>('/v1/documents')
  const { upload, busy } = useDocUpload(docs.reload)
  const [edit, setEdit] = useState<{ type: string; reg: string; model: string; year: string; colour: string; fuel: string } | null>(null)
  const [saving, setSaving] = useState(false)
  const byType = (t: DocType) => docs.data?.documents.find((d) => d.type === t)
  const open = () => setEdit({ type: v.data?.type ?? me?.vehicle_type ?? 'motorbike', reg: v.data?.registration_number ?? '', model: v.data?.make_model ?? '', year: v.data?.year ? String(v.data.year) : '', colour: v.data?.colour ?? '', fuel: v.data?.fuel ?? 'petrol' })
  const save = async () => {
    if (!edit) return
    setSaving(true)
    try {
      await api('/v1/vehicle', { method: 'PUT', body: { type: edit.type, registrationNumber: edit.reg, makeModel: edit.model || undefined, year: edit.year ? Number(edit.year) : undefined, colour: edit.colour || undefined, fuel: edit.fuel } })
      toast('Vehicle saved')
      setEdit(null)
      await v.reload()
    } catch (e) { showError(e) } finally { setSaving(false) }
  }
  const specs = [['MAKE & MODEL', v.data?.make_model || '–'], ['YEAR', v.data?.year ? String(v.data.year) : '–'], ['COLOUR', v.data?.colour || '–'], ['FUEL', label(FUELS, v.data?.fuel)], ['OWNER', me?.full_name ?? '–'], ['TYPE', label(VTYPES, v.data?.type)]]
  const vdocs: { type: DocType; icon: LucideIcon; bg?: string }[] = [{ type: 'vehicle_rc', icon: File }, { type: 'vehicle_insurance', icon: Umbrella, bg: '#fff3bf' }, { type: 'pucc', icon: Leaf }]
  const ins = byType('vehicle_insurance')
  return (
    <Screen>
      <Header title="My vehicle" to={P('1:2301')} />
      <RoundBtn icon={Pencil} x={344} y={41} onClick={open} />
      <Box x={20} y={102} w={372} h={253} r={28} bg="#eef5db" border="1px solid #ddebc3" />
      <img src={rider} alt="" style={{ position: 'absolute', left: 100, top: 118, width: 215, height: 135 }} />
      <Box onClick={open} x={104} y={260} w={205} h={42} r={6} bg="#fff" border="2px solid #222" style={{ overflow: 'hidden' }}>
        <div style={{ position: 'absolute', left: 0, top: 0, width: 21, height: '100%', background: '#2450a8', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ transform: 'rotate(-90deg)', font: '700 7px/7px Inter', color: '#fff' }}>IND</span>
        </div>
        <span style={{ position: 'absolute', left: 21, right: 0, top: 0, font: `700 ${v.data ? 20 : 13}px/38px Inter`, color: v.data ? '#111' : C.muted, letterSpacing: v.data ? 1.5 : 0, textAlign: 'center' }}>
          {v.data?.registration_number ?? (v.loading ? '…' : 'Tap to add')}
        </span>
      </Box>
      <T x={20} y={317} w={372} s={13} wt={500} lh={18.2} c="#224a36" align="center">
        {v.data ? `${label(VTYPES, v.data.type)} · ${label(FUELS, v.data.fuel)} · ${me?.status === 'active' ? 'Active for deliveries' : 'Pending approval'}` : 'Add your vehicle to start delivering'}
      </T>

      <div style={{ position: 'absolute', left: 20, top: 370, width: 372, height: 180, ...card }} />
      {specs.map(([l, val], i) => (
        <div key={l}>
          <T x={37 + (i % 2) * 175} y={388 + Math.floor(i / 2) * 54} s={10.5} wt={700} lh={14.7} c={C.muted}>{l}</T>
          <T x={37 + (i % 2) * 175} y={405 + Math.floor(i / 2) * 54} w={165} s={15} wt={700} lh={21} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{val}</T>
        </div>
      ))}

      <div style={{ position: 'absolute', left: 20, top: 565, width: 372, height: 222, padding: '0 16px', ...card }}>
        {vdocs.map((d, i) => {
          const doc = byType(d.type)
          const p = docPill(doc)
          return (
            <div key={d.type} role="button" onClick={() => !busy && void upload(d.type)} style={{ display: 'flex', alignItems: 'center', gap: 15, height: 73, borderTop: i ? `1px solid ${C.tint5}` : 0, cursor: 'pointer' }}>
              <Tile s={44} bg={d.bg} icon={d.icon} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ font: '700 15px/21px Inter', color: C.ink }}>{DOC_LABEL[d.type]}</p>
                <p style={{ font: '400 12px/16.8px Inter', color: C.muted, marginTop: 3 }}>{busy === d.type ? 'Uploading…' : docSub(doc)}</p>
              </div>
              <Pill label={p.label} bg={p.bg} color={p.color} />
            </div>
          )
        })}
      </div>
      <Btn y={782} label={busy === 'vehicle_insurance' ? 'UPLOADING…' : ins ? 'RENEW INSURANCE' : 'UPLOAD INSURANCE'} onClick={() => !busy && void upload('vehicle_insurance')} />
      <LinkText y={861} s={14} label={v.data ? 'Edit vehicle details' : 'Add vehicle details'} onClick={open} />

      {edit && (
        <Modal onClose={() => setEdit(null)}>
          <p style={{ font: '700 18px/25px Inter', color: C.ink, marginBottom: 12 }}>Vehicle details</p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 12 }}>
            {VTYPES.map(([l, k]) => <button key={k} type="button" style={chip(edit.type === k)} onClick={() => setEdit({ ...edit, type: k })}>{l}</button>)}
          </div>
          <div style={{ display: 'grid', gap: 10 }}>
            <Field w={324} label="Registration number" value={edit.reg} onChange={(x) => setEdit({ ...edit, reg: x.toUpperCase() })} placeholder="TN 02 AB 4821" h={48} />
            <Field w={324} label="Make & model" value={edit.model} onChange={(x) => setEdit({ ...edit, model: x })} placeholder="e.g. TVS Raider 125" h={48} />
            <div style={{ display: 'flex', gap: 10 }}>
              <div><Field w={157} label="Year" value={edit.year} onChange={(x) => setEdit({ ...edit, year: x.replace(/\D/g, '').slice(0, 4) })} inputMode="numeric" placeholder="2022" h={48} /></div>
              <div><Field w={157} label="Colour" value={edit.colour} onChange={(x) => setEdit({ ...edit, colour: x })} placeholder="Green" h={48} /></div>
            </div>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, margin: '12px 0 16px' }}>
            {FUELS.map(([l, k]) => <button key={k} type="button" style={chip(edit.fuel === k)} onClick={() => setEdit({ ...edit, fuel: k })}>{l}</button>)}
          </div>
          <Btn w="100%" h={48} label={saving ? 'SAVING…' : 'SAVE VEHICLE'} onClick={() => !saving && void save()} />
        </Modal>
      )}
    </Screen>
  )
}
