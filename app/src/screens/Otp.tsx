import { useEffect, useRef, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { api, showError, type Tokens } from '../api/client'
import { maskPhone, useSession } from '../api/session'
import { toast } from '../components/toast'
import Phone from '../components/Phone'
import { Backdrop, BackBar, Box, C, Img, PrimaryButton, T } from '../components/ui'
import haloOuter from '../assets/ui/halo-outer.svg'
import haloInner from '../assets/ui/halo-inner.svg'
import haloDisc from '../assets/ui/halo-disc.svg'
import { MessageSquareMore, Smartphone } from 'lucide-react'
import { Ic } from '../components/kit'
import checkGreen from '../assets/ui/check-green.svg'
import clock from '../assets/ui/clock.svg'

const xs = [20, 83.8, 147.6, 211.4, 275.2, 339]

export default function Otp() {
  const nav = useNavigate()
  const { pending, setPending, signIn } = useSession()
  const [digits, setDigits] = useState<string[]>(() => (pending?.devCode ?? '').padEnd(6, ' ').split('').map((c) => c.trim()))
  const [busy, setBusy] = useState(false)
  const [wait, setWait] = useState(30)
  const refs = useRef<(HTMLInputElement | null)[]>([])
  useEffect(() => {
    if (wait <= 0) return
    const t = setTimeout(() => setWait(wait - 1), 1000)
    return () => clearTimeout(t)
  }, [wait])
  if (!pending) return <Navigate to="/signup" replace />
  const isSignup = pending.purpose === 'signup'
  const phone10 = pending.phone.replace(/\D/g, '').slice(-10)

  const verify = async () => {
    const code = digits.join('')
    if (!/^\d{6}$/.test(code)) return toast('Enter all 6 digits')
    setBusy(true)
    try {
      const t = await api<Tokens>(isSignup ? '/v1/auth/signup/verify' : '/v1/auth/login/otp/verify', { body: { phone: pending.phone, code }, auth: false })
      await signIn(t)
      // `pending` is left in place on purpose: router navigation is a deferred transition, so clearing it
      // here would re-render this screen first and bounce to /signup. The next sign-up/login overwrites it.
      nav(isSignup ? '/password' : '/home', { replace: true })
    } catch (e) {
      showError(e)
    } finally {
      setBusy(false)
    }
  }
  const resend = async () => {
    if (wait > 0) return
    try {
      const r = isSignup
        ? await api<{ devCode?: string }>('/v1/auth/signup/start', { body: pending.signup, auth: false })
        : await api<{ devCode?: string }>('/v1/auth/login/otp/start', { body: { phone: pending.phone }, auth: false })
      setPending({ ...pending, devCode: r.devCode })
      setDigits((r.devCode ?? '').padEnd(6, ' ').split('').map((c) => c.trim()))
      setWait(30)
      toast('A new code is on its way')
    } catch (e) {
      showError(e)
    }
  }

  const set = (i: number, v: string) => {
    const d = v.replace(/\D/g, '').slice(-1)
    setDigits((p) => p.map((x, j) => (j === i ? d : x)))
    if (d && i < 5) refs.current[i + 1]?.focus()
  }

  return (
    <Phone>
      <Backdrop outlines={['3.27% 49.51% 82% 7.77%', '46.89% 6.8% 38.38% 50.49%', '79.02% 49.51% 6.25% 7.77%']} />
      <BackBar title="Verify mobile" to={isSignup ? '/signup' : '/login'} right={isSignup ? <T x={325} y={57} w={68} s={11} wt={700} lh={15.4} c={C.muted} align="right">Step 2 of 5</T> : undefined} />
      {isSignup && [20, 96, 172, 248, 324].map((x, i) => (
        <Box key={x} x={x} y={104} w={70} h={6} r={3} bg={i === 0 ? C.green : i === 1 ? C.lime : C.line} />
      ))}

      <Img src={haloOuter} x={126} y={130} w={160} h={160} />
      <Img src={haloInner} x={140} y={144} w={132} h={132} />
      <Img src={haloDisc} x={164 - 18} y={168 - 6} w={84 * 1.4286} h={84 * 1.4286} />
      <Box x={170} y={174} w={72} h={72} r={24} bg="linear-gradient(140deg,#1f7945 0%,#095334 100%)" shadow="0 12px 20px rgba(9,83,52,.22)" />
      <Ic icon={Smartphone} x={188} y={192} s={36} c="#fff" sw={1.8} />
      <Box x={222} y={164} w={30} h={30} r={15} bg={C.yellow} border="3px solid #f7f8f1" shadow="0 4px 10px rgba(9,83,52,.18)">
        <Ic icon={MessageSquareMore} x={4.5} y={4.5} s={15} c={C.green} sw={2.4} />
      </Box>

      <T x={20} y={294} w={372} s={28} wt={700} lh={36.4} align="center">Enter the 6-digit code</T>
      <T x={20} y={334} w={372} s={14.5} wt={500} lh={20.3} c={C.muted} align="center">
        Sent to {maskPhone('+91' + phone10)} · <b style={{ color: C.green, cursor: 'pointer' }} onClick={() => nav(isSignup ? '/signup' : '/login')}>Edit</b>
      </T>

      {xs.map((x, i) => {
        const focus = i === Math.min(5, digits.findIndex((d) => !d) === -1 ? 5 : digits.findIndex((d) => !d))
        return (
          <input
            key={x}
            ref={(el) => { refs.current[i] = el }}
            aria-label={`OTP digit ${i + 1}`}
            inputMode="numeric"
            autoComplete={i === 0 ? 'one-time-code' : 'off'}
            maxLength={1}
            value={digits[i]}
            onFocus={(e) => e.target.select()}
            onChange={(e) => set(i, e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Backspace' && !digits[i] && i > 0) refs.current[i - 1]?.focus() }}
            style={{
              position: 'absolute', left: x, top: 381, width: 53, height: 61, borderRadius: 15, background: '#fff', textAlign: 'center',
              fontFamily: 'inherit', fontSize: 24, fontWeight: 700, color: C.ink, outline: 0,
              border: focus ? `1.4px solid ${C.green}` : `1px solid ${C.line}`,
              boxShadow: focus ? '0 0 0 4px rgba(9,83,52,.08)' : undefined,
            }}
          />
        )
      })}

      <Box x={20} y={459} w={372} h={48} r={16} bg="#e5f4e9" border="1px solid #c4e7ce" />
      <Img src={checkGreen} x={36} y={475} w={16} h={16} />
      <T x={64} y={473} w={314} s={13.5} wt={500} lh={18.9} c={C.green}>
        {pending.devCode ? `Trial code: ${pending.devCode} · filled in for you` : 'Code sent by SMS · valid for 5 minutes'}
      </T>

      <Box x={20} y={524} w={372} h={64} r={23} bg="#fff" border="1px solid #e9ece5" shadow="0 8px 15px rgba(9,83,52,.04)" />
      <Img src={clock} x={37} y={548} w={16} h={16} />
      <T x={64} y={547} w={230} s={13.5} lh={18.9} c="#222">Need another code?</T>
      <T x={267} y={547} w={101} s={13.5} wt={700} lh={18.9} c={wait > 0 ? '#90a496' : C.green} align="right" onClick={() => void resend()}>{wait > 0 ? `Resend in ${wait}s` : 'Resend'}</T>

      <T x={20} y={604} w={372} s={13.5} wt={500} lh={18.9} c={C.muted} align="center">
        Didn’t get it? <b style={{ color: C.green, cursor: 'pointer' }} onClick={() => toast('Call-based codes are coming soon. Use Resend for now.')}>Get the code on a call</b>
      </T>
      <PrimaryButton y={808} label={busy ? 'VERIFYING…' : isSignup ? 'VERIFY & CONTINUE' : 'VERIFY & LOG IN'} onClick={() => !busy && void verify()} />
    </Phone>
  )
}
