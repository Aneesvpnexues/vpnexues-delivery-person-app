import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api, showError, type Tokens } from '../api/client'
import { useSession } from '../api/session'
import { toast } from '../components/toast'
import Phone from '../components/Phone'
import { Backdrop, BackBar, Box, C, Img, OutlineButton, PrimaryButton, T, inputBox } from '../components/ui'
import { fieldInput } from './SignUp'
import { digits, mobileError } from '../lib/validate'
import logo from '../assets/logo.png'
import lock from '../assets/ui/lock.svg'
import eyeButton from '../assets/ui/eye-button.svg'
import eye from '../assets/ui/eye.svg'
import check from '../assets/ui/check2.svg'

export default function Login() {
  const nav = useNavigate()
  const { signIn, setPending } = useSession()
  const [tab, setTab] = useState<'password' | 'otp'>('otp')
  const [mobile, setMobile] = useState('')
  const [password, setPassword] = useState('')
  const [show, setShow] = useState(false)
  const [keep, setKeep] = useState(true)
  const [busy, setBusy] = useState(false)
  const [tried, setTried] = useState(false)
  const mErr = mobileError(mobile)
  const pErr = tab === 'password' ? (!password ? 'Enter your password' : password.length < 8 ? 'Password must be at least 8 characters' : '') : ''

  const submit = async () => {
    setTried(true)
    if (mErr) return toast(mErr)
    if (pErr) return toast(pErr)
    const phone = digits(mobile).slice(-10)
    setBusy(true)
    try {
      if (tab === 'password') {
        await signIn(await api<Tokens>('/v1/auth/login', { body: { phone, password }, auth: false }))
        nav('/home', { replace: true })
      } else {
        const r = await api<{ devCode?: string }>('/v1/auth/login/otp/start', { body: { phone }, auth: false })
        setPending({ purpose: 'login', phone, devCode: r.devCode })
        nav('/otp')
      }
    } catch (e) {
      showError(e)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Phone>
      <Backdrop outlines={['21.75% 8.74% 63.52% 48.54%', '31.26% 51.46% 54.01% 5.83%', '58.03% 51.46% 27.23% 5.83%', '72.79% 5.58% 12.48% 51.7%']} />
      <BackBar to="/" right={<T x={286} y={57} w={106} s={12} wt={700} lh={16.8} c={C.green} align="right" to="/help">Need help?</T>} />

      <Box x={20} y={110} w={56} h={56} r={28} style={{ overflow: 'hidden' }}>
        <img src={logo} alt="VP Nexues" style={{ position: 'absolute', height: '735.29%', left: '-115.89%', top: '-70.59%', width: '331.13%', maxWidth: 'none' }} />
      </Box>
      <T x={90} y={122} w={280} s={11} wt={700} lh={15.4} c={C.accent} ls={0.9}>VP NEXUES PARTNER</T>
      <T x={90} y={137} w={280} s={12} wt={500} lh={16.8} c={C.muted}>Delivery partner app</T>
      <T x={20} y={181} w={372} s={29} wt={700} lh={40.6}>Welcome back.</T>
      <T x={20} y={224} w={380} s={15} wt={500} lh={21} c={C.muted}>Log in to see today’s deliveries and payouts.</T>

      {/* Password login removed: partners sign in with a one-time code only. */}

      <T x={20} y={334} w={372} wt={600} lh={18.2}>Mobile number</T>
      <Box x={20} y={360} w={372} h={55} r={16} style={{ ...inputBox(), ...(tried && mErr ? { border: '1.5px solid #b3261e' } : {}) }} />
      {tried && mErr && <T x={20} y={416} w={372} s={11.5} wt={600} lh={14} c="#b3261e">{mErr}</T>}
      <T x={37} y={377} w={38} s={16} wt={600} lh={22.4}>+91</T>
      <Box x={74.5} y={377} w={1} h={21} bg={C.line} />
      <input aria-label="Mobile number" inputMode="numeric" autoComplete="tel-national" placeholder="10-digit number" maxLength={10} style={{ ...fieldInput, left: 87, top: 377, width: 260, height: 22 }} value={mobile} onChange={(e) => setMobile(e.target.value.replace(/\D/g, '').slice(0, 10))} onKeyDown={(e) => e.key === 'Enter' && tab === 'otp' && void submit()} />

      {tab === 'password' ? (
        <>
          <T x={20} y={432} w={372} wt={600} lh={18.2}>Password</T>
          <T x={252} y={432} w={140} wt={700} lh={18.2} c={C.green} align="right" onClick={() => { setTab('otp'); toast('Log in with a one-time code, then set a new password in Settings') }}>Forgot password?</T>
          <Box x={20} y={458} w={372} h={55} r={16} style={{ ...inputBox(true), ...(tried && pErr ? { border: '1.5px solid #b3261e' } : {}) }} />
          {tried && pErr && <T x={20} y={514} w={372} s={11.5} wt={600} lh={14} c="#b3261e">{pErr}</T>}
          <Img src={lock} x={38} y={476} w={18} h={18} />
          <input aria-label="Password" type={show ? 'text' : 'password'} autoComplete="current-password" placeholder="Your password" style={{ ...fieldInput, left: 67, top: 474, width: 250, height: 22 }} value={password} onChange={(e) => setPassword(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && void submit()} />
          <Box onClick={() => setShow(!show)} x={334} y={465} w={40} h={40}>
            <Img src={eyeButton} x={0} y={0} w={40} h={40} />
            <Img src={eye} x={12} y={12} w={16} h={16} />
          </Box>
        </>
      ) : (
        <>
          <T x={20} y={432} w={372} s={13} wt={500} lh={19.5} c={C.muted}>We’ll text a 6-digit one-time code to this number.</T>
        </>
      )}

      <Box onClick={() => setKeep(!keep)} x={20} y={529} w={22} h={22} r={4} bg={keep ? C.green : '#fff'} border={keep ? undefined : `1.5px solid ${C.line}`}>
        {keep && <img src={check} alt="" style={{ position: 'absolute', left: 2, top: 1, width: 20, height: 20 }} />}
      </Box>
      <T x={54} y={530} w={338} wt={500} lh={18.2} c={C.muted}>Keep me logged in on this phone</T>

      <PrimaryButton y={687} label={busy ? 'PLEASE WAIT…' : tab === 'password' ? 'LOG IN' : 'SEND CODE'} onClick={() => !busy && void submit()} />


      <Box x={20} y={820} w={122} h={1} bg={C.tint5} />
      <Box x={270} y={820} w={122} h={1} bg={C.tint5} />
      <T x={144} y={812} w={125} s={12} wt={500} lh={16.8} c={C.muted} align="center">New to VP Nexues?</T>
      <OutlineButton y={840} label="CREATE A PARTNER ACCOUNT" to="/signup" />
    </Phone>
  )
}