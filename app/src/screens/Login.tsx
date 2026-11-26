// app/src/screens/Login.tsx

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api, showError, type Tokens } from '../api/client'
import { useSession } from '../api/session'
import { toast } from '../components/toast'
import Phone from '../components/Phone'
import { Backdrop, BackBar, Box, C, Img, OutlineButton, PrimaryButton, T, inputBox } from '../components/ui'
import { fieldInput } from './SignUp'
import logo from '../assets/logo.png'
import lock from '../assets/ui/lock.svg'
import eyeButton from '../assets/ui/eye-button.svg'
import eye from '../assets/ui/eye.svg'
import check from '../assets/ui/check2.svg'
import fingerprint from '../assets/ui/fingerprint.svg'

export default function Login() {
  const nav = useNavigate()
  const { signIn, setPending } = useSession()
  const [tab, setTab] = useState<'password' | 'otp'>('password')
  const [mobile, setMobile] = useState('')
  const [password, setPassword] = useState('')
  const [show, setShow] = useState(false)
  const [keep, setKeep] = useState(true)
  const [busy, setBusy] = useState(false)

  const submit = async () => {
    if (mobile.replace(/\D/g, '').length < 10) return toast('Enter your 10-digit mobile number')
    if (tab === 'password' && !password) return toast('Enter your password')
    setBusy(true)
    try {
      if (tab === 'password') {
        await signIn(await api<Tokens>('/v1/auth/login', { body: { phone: mobile, password }, auth: false }))
        nav('/home', { replace: true })
      } else {
        const r = await api<{ devCode?: string }>('/v1/auth/login/otp/start', { body: { phone: mobile }, auth: false })
        setPending({ purpose: 'login', phone: mobile, devCode: r.devCode })
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

      <Box x={20} y={262} w={372} h={56} r={28} bg="#fff" border={`1px solid ${C.line}`} />
      <Box x={tab === 'password' ? 24 : 206} y={266} w={182} h={48} r={24} bg={C.green} shadow="0 6px 10px rgba(9,83,52,.12)" style={{ transition: 'left .2s' }} />
      <Box onClick={() => setTab('password')} x={24} y={266} w={182} h={48} style={{ color: tab === 'password' ? '#fff' : C.muted, fontSize: 13, fontWeight: 700 }}>Password</Box>
      <Box onClick={() => setTab('otp')} x={206} y={266} w={182} h={48} style={{ color: tab === 'otp' ? '#fff' : C.muted, fontSize: 13, fontWeight: 700 }}>One-time code</Box>

      <T x={20} y={334} w={372} wt={600} lh={18.2}>Mobile number</T>
      <Box x={20} y={360} w={372} h={55} r={16} style={inputBox()} />
      <T x={37} y={377} w={38} s={16} wt={600} lh={22.4}>+91</T>
      <Box x={74.5} y={377} w={1} h={21} bg={C.line} />
      <input aria-label="Mobile number" inputMode="numeric" autoComplete="tel-national" placeholder="10-digit number" maxLength={11} style={{ ...fieldInput, left: 87, top: 377, width: 260, height: 22 }} value={mobile} onChange={(e) => setMobile(e.target.value.replace(/[^\d ]/g, ''))} />

      {tab === 'password' ? (
        <>
          <T x={20} y={432} w={372} wt={600} lh={18.2}>Password</T>
          <T x={252} y={432} w={140} wt={700} lh={18.2} c={C.green} align="right" onClick={() => { setTab('otp'); toast('Log in with a one-time code, then set a new password in Settings') }}>Forgot password?</T>
          <Box x={20} y={458} w={372} h={55} r={16} style={inputBox(true)} />
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

      <Box x={113} y={769} w={17} h={17}>
        <img src={fingerprint} alt="" style={{ position: 'absolute', left: '12.5%', top: '10.42%', width: '70.83%', height: '81.25%', maxWidth: 'none' }} />
      </Box>
      <T x={137} y={767} w={240} s={15} wt={700} lh={21} c={C.green} onClick={() => toast('Fingerprint login arrives in a later version. Use your password for now.')}>Log in with fingerprint</T>

      <Box x={20} y={820} w={122} h={1} bg={C.tint5} />
      <Box x={270} y={820} w={122} h={1} bg={C.tint5} />
      <T x={144} y={812} w={125} s={12} wt={500} lh={16.8} c={C.muted} align="center">New to VP Nexues?</T>
      <OutlineButton y={840} label="CREATE A PARTNER ACCOUNT" to="/signup" />
    </Phone>
  )
}
