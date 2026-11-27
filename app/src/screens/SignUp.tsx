import { useState, type CSSProperties } from 'react'
import { useNavigate } from 'react-router-dom'
import { api, showError } from '../api/client'
import { useApi, useSession } from '../api/session'
import { toast } from '../components/toast'
import Phone from '../components/Phone'
import { Backdrop, BackBar, Box, C, Img, PrimaryButton, T, inputBox } from '../components/ui'
import { digits, mobileError, nameError, referralError } from '../lib/validate'
import user from '../assets/ui/user.svg'
import pin from '../assets/ui/pin.svg'
import down from '../assets/ui/down.svg'
import gift from '../assets/ui/gift.svg'
import check from '../assets/ui/check.svg'

const vehicles = [
  { label: 'Motorbike', value: 'motorbike', x: 20, w: 89 },
  { label: 'Scooter', value: 'scooter', x: 116.8, w: 70.3 },
  { label: 'Electric scooter', value: 'electric_scooter', x: 194.9, w: 119.3 },
  { label: 'Bicycle', value: 'bicycle', x: 326.1, w: 65.9 },
]
type City = { id: number; name: string; state: string }

export const fieldInput: CSSProperties = {
  position: 'absolute', background: 'transparent', border: 0, outline: 0, fontSize: 16, fontWeight: 600, color: C.ink, fontFamily: 'inherit',
}

export default function SignUp() {
  const nav = useNavigate()
  const { setPending } = useSession()
  const cities = useApi<City[]>('/v1/cities')
  const [name, setName] = useState('')
  const [mobile, setMobile] = useState('')
  const [cityId, setCityId] = useState<number | null>(null)
  const [pickCity, setPickCity] = useState(false)
  const [vehicle, setVehicle] = useState('Motorbike')
  const [ref, setRef] = useState('')
  const [agree, setAgree] = useState(false)
  const [busy, setBusy] = useState(false)
  const [tried, setTried] = useState(false)
  const [touched, setTouched] = useState<Record<string, boolean>>({})
  const city = cities.data?.find((c) => c.id === cityId)
  const touch = (k: string) => setTouched((t) => (t[k] ? t : { ...t, [k]: true }))
  const errs = {
    name: nameError(name, 'your full name as on Aadhaar'),
    mobile: mobileError(mobile),
    city: cityId ? '' : 'Choose your city',
    ref: referralError(ref),
    agree: agree ? '' : 'Accept the partner terms to continue',
  }
  const err = (k: keyof typeof errs) => ((tried || touched[k]) ? errs[k] : '')
  const ErrText = ({ k, x = 20, y, w = 372 }: { k: keyof typeof errs; x?: number; y: number; w?: number }) =>
    err(k) ? <T x={x} y={y} w={w} s={11.5} wt={600} lh={14} c="#b3261e">{err(k)}</T> : null

  const sendOtp = async () => {
    setTried(true)
    const first = errs.name || errs.mobile || errs.city || errs.ref || errs.agree
    if (first) return toast(first)
    let phone = digits(mobile)
    if (phone.length === 12 && phone.startsWith('91')) phone = phone.slice(2)
    if (phone.length === 11 && phone.startsWith('0')) phone = phone.slice(1)
    const body = {
      fullName: name.trim().replace(/\s+/g, ' '), phone, cityId, acceptedTerms: true,
      vehicleType: vehicles.find((v) => v.label === vehicle)!.value,
      ...(ref.trim() ? { referralCode: ref.trim() } : {}),
    }
    setBusy(true)
    try {
      const r = await api<{ devCode?: string }>('/v1/auth/signup/start', { body, auth: false })
      setPending({ purpose: 'signup', phone, devCode: r.devCode, signup: body })
      nav('/otp')
    } catch (e) {
      showError(e)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Phone>
      <Backdrop />
      <BackBar title="Create account" to="/" right={<T x={325} y={57} w={68} s={11} wt={700} lh={15.4} c={C.muted} align="right">Step 1 of 5</T>} />
      {[20, 96, 172, 248, 324].map((x, i) => (
        <Box key={x} x={x} y={104} w={70} h={6} r={3} bg={i === 0 ? C.lime : C.line} />
      ))}
      <T x={20} y={129} w={372} s={11} wt={700} lh={15.4} c={C.accent} ls={1.2}>JOIN THE HARVEST CREW</T>
      <T x={20} y={149} w={380} s={29} wt={700} lh={34.8}>
        Ride with us.{' '}
        <span style={{ backgroundImage: 'linear-gradient(173deg,#247947 0%,#8a7600 71.4%)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' }}>Earn fresh.</span>
      </T>
      <T x={20} y={191} w={385} s={13.2} wt={500} lh={19.8} c={C.muted}>{'Takes about 5 minutes. Keep your Aadhaar, driving licence\nand bank details ready.'}</T>

      <T x={20} y={246} w={372} wt={600} lh={18.2}>Full name (as on Aadhaar)</T>
      <Box x={20} y={272} w={372} h={55} r={16} style={{ ...inputBox(), ...(err('name') ? { border: '1.5px solid #b3261e' } : {}) }} />
      <Img src={user} x={38} y={290} w={18} h={18} />
      <input aria-label="Full name" placeholder="As printed on your Aadhaar" autoComplete="name" style={{ ...fieldInput, left: 67, top: 288, width: 320, height: 22 }} value={name} onChange={(e) => setName(e.target.value.replace(/[^A-Za-z .'-]/g, ''))} onBlur={() => touch('name')} maxLength={60} />
      <ErrText k="name" y={330} />

      <T x={20} y={343} w={372} wt={600} lh={18.2}>Mobile number</T>
      <Box x={20} y={369} w={372} h={55} r={16} style={{ ...inputBox(true), ...(err('mobile') ? { border: '1.5px solid #b3261e' } : {}) }} />
      <T x={37} y={386} w={38} s={16} wt={600} lh={22.4}>+91</T>
      <Box x={74.5} y={386} w={1} h={21} bg={C.line} />
      <input aria-label="Mobile number" inputMode="numeric" autoComplete="tel-national" placeholder="10-digit number" maxLength={10} style={{ ...fieldInput, left: 87, top: 386, width: 260, height: 22 }} value={mobile} onChange={(e) => setMobile(e.target.value.replace(/\D/g, '').slice(0, 10))} onBlur={() => touch('mobile')} />
      {err('mobile')
        ? <T x={20} y={433} w={372} s={12} wt={600} lh={16.8} c="#b3261e">{err('mobile')}</T>
        : <T x={20} y={433} w={372} s={12} wt={500} lh={16.8} c={C.muted}>We will send a 6-digit OTP to this number.</T>}

      <T x={20} y={466} w={372} wt={600} lh={18.2}>City</T>
      <Box x={20} y={492} w={372} h={55} r={16} style={{ ...inputBox(), ...(err('city') ? { border: '1.5px solid #b3261e' } : {}) }} />
      <Img src={pin} x={38} y={510} w={18} h={18} />
      <button type="button" aria-label="City" onClick={() => { setPickCity(!pickCity); touch('city') }}
        style={{ ...fieldInput, left: 67, top: 500, width: 310, height: 38, textAlign: 'left', color: city ? C.ink : '#9aa69e' }}>
        {city ? city.name : cities.loading ? 'Loading cities…' : 'Choose your city'}
      </button>
      <Img src={down} x={358} y={509} w={19} h={19} style={{ pointerEvents: 'none' }} />
      {!pickCity && <ErrText k="city" y={549} />}
      {pickCity && (
        <div style={{ position: 'absolute', left: 20, top: 551, width: 372, zIndex: 20, background: '#fff', borderRadius: 16, border: `1px solid ${C.line}`, boxShadow: '0 16px 30px rgba(9,83,52,.14)', overflow: 'hidden' }}>
          {(cities.data ?? []).map((c, i) => (
            <button key={c.id} type="button" onClick={() => { setCityId(c.id); setPickCity(false) }}
              style={{ display: 'block', width: '100%', height: 50, padding: '0 18px', textAlign: 'left', borderTop: i ? `1px solid ${C.tint5}` : 0, background: c.id === cityId ? '#eef5db' : '#fff', font: '600 15px/50px Inter', color: C.ink }}>
              {c.name} <span style={{ color: C.muted, fontWeight: 400, fontSize: 13 }}>· {c.state}</span>
            </button>
          ))}
          {!cities.loading && !cities.data?.length && <p style={{ padding: 16, font: '500 13px Inter', color: C.muted }}>Couldn’t load cities. Check your connection.</p>}
        </div>
      )}

      <T x={20} y={562} w={372} wt={600} lh={18.2}>How will you deliver?</T>
      {vehicles.map((v) => {
        const on = vehicle === v.label
        return (
          <Box key={v.label} onClick={() => setVehicle(v.label)} x={v.x} y={587} w={v.w} h={40} r={20}
            bg={on ? C.green : '#fff'} border={on ? undefined : `1px solid ${C.line}`}
            style={{ color: on ? '#fff' : C.ink, fontSize: 13, fontWeight: 700, whiteSpace: 'nowrap' }}>
            {v.label}
          </Box>
        )
      })}

      <T x={20} y={658} w={372} wt={600} lh={18.2}>Referral code <span style={{ fontWeight: 400, color: C.muted }}>(optional)</span></T>
      <Box x={20} y={683} w={372} h={55} r={16} style={{ ...inputBox(), ...(err('ref') ? { border: '1.5px solid #b3261e' } : {}) }} />
      <Img src={gift} x={38} y={702} w={17} h={17} />
      <input aria-label="Referral code" placeholder="e.g. VPN–ANNA25" style={{ ...fieldInput, left: 67, top: 700, width: 300, height: 22 }} value={ref} onChange={(e) => setRef(e.target.value)} onBlur={() => touch('ref')} maxLength={20} />
      <ErrText k="ref" y={741} />

      <Box onClick={() => { setAgree(!agree); touch('agree') }} x={20} y={761.75} w={22} h={22} r={4} bg={agree ? C.green : '#fff'} border={agree ? undefined : `1.5px solid ${err('agree') ? '#b3261e' : C.line}`}>
        {agree && <img src={check} alt="" style={{ position: 'absolute', left: 2, top: 2, width: 18, height: 18 }} />}
      </Box>
      <T x={54} y={762.75} w={340} s={12.5} lh={17.5} c={C.muted}>
        I agree to the <b>Partner terms</b> and <b>Privacy policy</b>, and
      </T>
      <PrimaryButton y={803.88} label={busy ? 'SENDING…' : 'SEND OTP'} onClick={() => !busy && void sendOtp()} />
      <T x={20} y={880} w={372} lh={18.2} align="center" c="#222" to="/login">
        Already a partner? <b style={{ color: C.green }}>Log in</b>
      </T>
    </Phone>
  )
}
