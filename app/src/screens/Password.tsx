import { useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { api, showError } from '../api/client'
import { toast } from '../components/toast'
import Phone from '../components/Phone'
import { Backdrop, BackBar, Box, C, Img, PrimaryButton, T, inputBox } from '../components/ui'
import { fieldInput } from './SignUp'
import shield from '../assets/ui/shield.svg'
import lock from '../assets/ui/lock.svg'
import eyeButton from '../assets/ui/eye-button.svg'
import eye from '../assets/ui/eye.svg'
import eyeSlash from '../assets/ui/eye-slash.svg'
import reqOk from '../assets/ui/req-ok.svg'
import reqCheck from '../assets/ui/req-check.svg'
import matchCheck from '../assets/ui/match-check.svg'
import thumb from '../assets/ui/toggle-thumb.svg'

const grad = 'linear-gradient(173deg,#247947 0%,#9cc42c 71.4%)'

export default function Password() {
  const nav = useNavigate()
  const fromSettings = useSearchParams()[0].get('from') === 'settings'
  const [pw, setPw] = useState('')
  const [confirm, setConfirm] = useState('')
  const [show, setShow] = useState(false)
  const [finger, setFinger] = useState(true)
  const [busy, setBusy] = useState(false)

  const rules = [
    { label: 'At least 8 characters', ok: pw.length >= 8 },
    { label: 'One uppercase letter', ok: /[A-Z]/.test(pw) },
    { label: 'One number', ok: /\d/.test(pw) },
    { label: 'One symbol (@ # ! %)', ok: /[^A-Za-z0-9]/.test(pw) },
  ]
  const score = rules.filter((r) => r.ok).length
  const strength = ['Weak', 'Weak', 'Fair', 'Good', 'Strong'][score]
  const match = confirm.length > 0 && pw === confirm
  const save = async () => {
    if (score < 4) return toast('Your password needs all four items in the checklist')
    if (!match) return toast('The two passwords don’t match')
    setBusy(true)
    try {
      await api('/v1/auth/password', { body: { password: pw } })
      await api('/v1/me/settings', { method: 'PATCH', body: { fingerprintUnlock: finger } }).catch(() => {})
      toast('Password saved')
      if (fromSettings) nav(-1)
      else nav('/documents-onboarding', { replace: true })
    } catch (e) {
      showError(e)
    } finally {
      setBusy(false)
    }
  }

  return (
    <Phone>
      <Backdrop outlines={['21.75% 8.74% 63.52% 48.54%', '31.26% 51.46% 54.01% 5.83%', '58.03% 51.46% 27.23% 5.83%', '72.79% 5.58% 12.48% 51.7%']} />
      <BackBar title={fromSettings ? 'Change password' : 'Secure your account'} right={fromSettings ? undefined : <T x={325} y={57} w={68} s={11} wt={700} lh={15.4} c={C.muted} align="right">Step 3 of 5</T>} />
      {!fromSettings && [20, 96, 172, 248, 324].map((x, i) => (
        <Box key={x} x={x} y={104} w={70} h={6} r={3} bg={i < 2 ? C.green : i === 2 ? C.lime : C.line} />
      ))}

      <Box x={20} y={130} w={56} h={56} r={14} bg="#eef5db" />
      <Img src={shield} x={37.5} y={147.5} w={21} h={21} />
      <T x={90} y={135} w={302} s={20} wt={700} lh={28}>Create a password</T>
      <T x={90} y={162} w={307} s={13} wt={500} lh={18.2} c={C.muted}>You’ll use it with your mobile number to log in.</T>

      <T x={20} y={202} w={372} wt={600} lh={18.2}>New password</T>
      <Box x={20} y={228} w={372} h={55} r={16} style={inputBox(true)} />
      <Img src={lock} x={38} y={246} w={18} h={18} />
      <input aria-label="New password" type={show ? 'text' : 'password'} style={{ ...fieldInput, left: 67, top: 244, width: 250, height: 22 }} value={pw} onChange={(e) => setPw(e.target.value)} />
      <Box onClick={() => setShow(!show)} x={334} y={235} w={40} h={40}>
        <Img src={eyeButton} x={0} y={0} w={40} h={40} />
        <Img src={eye} x={12} y={12} w={16} h={16} />
        {!show && <Img src={eyeSlash} x={11} y={11} w={18} h={18} />}
      </Box>

      {[20, 114.5, 209, 303.5].map((x, i) => (
        <Box key={x} x={x} y={295} w={89} h={8} r={4} style={{ backgroundImage: i < score ? grad : undefined, backgroundColor: i < score ? undefined : C.line }} />
      ))}
      <T x={20} y={312} w={372} s={12} wt={500} lh={16.8} c={C.muted}>
        Strength: <b style={{ color: C.accent }}>{strength}</b>
      </T>

      <Box x={20} y={345} w={372} h={151} r={24} bg="#fff" border="1px solid #e9ece5" shadow="0 10px 18px rgba(9,83,52,.04)" />
      {rules.map((r, i) => (
        <div key={r.label}>
          <Img src={reqOk} x={36} y={361 + i * 32} w={22} h={22} style={{ opacity: r.ok ? 1 : 0.35 }} />
          {r.ok && <Img src={reqCheck} x={41} y={366 + i * 32} w={12} h={12} />}
          <T x={69} y={363 + i * 32} w={300} s={13.5} wt={500} lh={18.9}>{r.label}</T>
        </div>
      ))}

      <T x={20} y={512} w={372} wt={600} lh={18.2}>Confirm password</T>
      <Box x={20} y={538} w={372} h={55} r={16} style={{ background: '#fff', border: `1px solid ${match ? '#81c895' : C.line}` }} />
      <Img src={lock} x={38} y={556} w={18} h={18} />
      <input aria-label="Confirm password" type="password" style={{ ...fieldInput, left: 67, top: 554, width: 280, height: 22 }} value={confirm} onChange={(e) => setConfirm(e.target.value)} />
      {match && <Img src={matchCheck} x={358} y={555} w={19} h={19} />}
      {confirm.length > 0 && <T x={20} y={602} w={372} s={12} wt={700} lh={16.8} c={match ? C.accent : '#b3261e'}>{match ? 'Passwords match' : 'Passwords do not match'}</T>}

      <Box x={20} y={635} w={372} h={66} r={23} bg="#eef5db" border="1px solid #dfebc3" />
      <T x={36} y={649} w={280} s={15} wt={700} lh={21}>Unlock with fingerprint</T>
      <T x={36} y={670} w={280} s={12} wt={500} lh={16.8} c={C.muted}>Faster log in on this phone</T>
      <Box onClick={() => setFinger(!finger)} x={325} y={653} w={50} h={30} r={15} bg={finger ? C.green : '#c9d3cb'} style={{ transition: 'background .2s' }} />
      <Img src={thumb} x={(finger ? 348 : 328) - 3} y={656 - 2} w={30} h={28} style={{ transition: 'left .2s', pointerEvents: 'none' }} />

      <PrimaryButton y={839} label={busy ? 'SAVING…' : fromSettings ? 'SAVE PASSWORD' : 'SAVE & CONTINUE'} onClick={() => !busy && void save()} />
    </Phone>
  )
}
