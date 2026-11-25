import { useState, type CSSProperties, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft as ArrowLeftIcon, Bell, Home, Package, User, Wallet, type LucideIcon } from 'lucide-react'
import Phone from './Phone'
import { Backdrop, Box, C, Img, T } from './ui'
import outline from '../assets/ui/outline.svg'
import logo from '../assets/logo.png'
import { screens } from '../nav'
import { useSession } from '../api/session'

/** Route path of a Figma frame id. */
export const P = (id: string) => screens[id].path

/* ---------- partner state (online toggle, language) now comes from the signed-in session ---------- */
export function useDemo() {
  const s = useSession()
  return { online: s.online, setOnline: s.setOnline, lang: s.lang, setLang: s.setLang }
}

/* ---------- layout ---------- */
export const OL = {
  a: [[32, 30], [208, 429], [32, 723]],
  b: [[200, 199], [24, 286], [24, 531], [213, 666]],
  c: [[200, -97], [24, -10], [24, 242], [213, 377]],
} as const

export function Screen({ children, ol = 'a', bg }: { children: ReactNode; ol?: keyof typeof OL; bg?: string }) {
  return (
    <Phone>
      {bg && <div style={{ position: 'absolute', top: 'calc(-1 * var(--bleed-top, 0px))', bottom: 'calc(-1 * var(--bleed-bottom, 0px))', left: 'calc(-1 * var(--bleed-x, 0px))', right: 'calc(-1 * var(--bleed-x, 0px))', background: bg }} />}
      <Backdrop outlines={[]} />
      {children}
      {OL[ol].map(([x, y], i) => (
        <img key={i} src={outline} alt="" style={{ position: 'absolute', left: x - 1, top: y - 1, width: 178, height: 136, pointerEvents: 'none', opacity: 0.9 }} />
      ))}
    </Phone>
  )
}

/* ---------- toast: lives in Phone so it works on every screen ---------- */
export { toast } from './toast'

/* ---------- atoms ---------- */
export function Ic({ icon: I, x, y, s = 20, c = C.green, sw = 1.7, fill = 'none', style }: { icon: LucideIcon; x?: number; y?: number; s?: number; c?: string; sw?: number; fill?: string; style?: CSSProperties }) {
  return <I size={s} color={c} strokeWidth={sw} absoluteStrokeWidth fill={fill} style={{ position: x === undefined ? undefined : 'absolute', left: x, top: y, flex: 'none', pointerEvents: 'none', ...style }} />
}

export function Logo({ x, y, s }: { x: number; y: number; s: number }) {
  return (
    <Box x={x} y={y} w={s} h={s} r={s / 2} style={{ overflow: 'hidden' }}>
      <img src={logo} alt="VP Nexues" style={{ position: 'absolute', height: '735.29%', left: '-115.89%', top: '-70.59%', width: '331.13%', maxWidth: 'none' }} />
    </Box>
  )
}

/** Round white icon button (bell, search, settings…) */
export function RoundBtn({ icon, x = 344, y = 40, dot, onClick, to }: { icon: LucideIcon; x?: number; y?: number; dot?: boolean; onClick?: () => void; to?: string }) {
  const nav = useNavigate()
  return (
    <Box onClick={() => (to ? nav(to) : onClick?.())} x={x} y={y} w={48} h={48} r={24} bg="#fff" shadow="0 4px 12px rgba(9,83,52,.05)">
      <Ic icon={icon} x={14} y={14} />
      {dot && <span style={{ position: 'absolute', left: 29, top: 21, width: 5, height: 5, borderRadius: 3, background: '#e5484d' }} />}
    </Box>
  )
}
export const BellBtn = ({ dot = true }: { dot?: boolean }) => <RoundBtn icon={Bell} dot={dot} to={P('1:3417')} />

export function Pill({ x, y, w, label, bg = C.green, color = '#d6ee75', dot = color, style }: { x?: number; y?: number; w?: number; label: string; bg?: string; color?: string; dot?: string; style?: CSSProperties }) {
  return (
    <div style={{ position: x === undefined ? 'relative' : 'absolute', left: x, top: y, width: w, height: 24, borderRadius: 12, background: bg, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 11px', font: '700 11px/15.4px Inter', color, whiteSpace: 'nowrap', flex: 'none', ...style }}>
      <span style={{ width: 7, height: 7, borderRadius: 4, background: dot, flex: 'none' }} />
      {label}
    </div>
  )
}
export const pill = {
  ok: { bg: '#ddf2e4', color: C.green },
  warn: { bg: '#fff1cb', color: '#825605' },
  bad: { bg: '#fde0dd', color: '#b3261e' },
  info: { bg: '#e5f3f8', color: '#145b73' },
}

export function Tile({ x, y, s = 36, bg = '#eef5db', icon, c, r = 14, is = 21, border }: { x?: number; y?: number; s?: number; bg?: string; icon: LucideIcon; c?: string; r?: number; is?: number; border?: string }) {
  return (
    <div style={{ position: x === undefined ? 'relative' : 'absolute', left: x, top: y, width: s, height: s, borderRadius: r, background: bg, border, display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 'none' }}>
      <Ic icon={icon} s={is} c={c} />
    </div>
  )
}

export function Toggle({ x, y, on, onChange, onColor = C.accent }: { x?: number; y?: number; on: boolean; onChange: (v: boolean) => void; onColor?: string }) {
  return (
    <button type="button" role="switch" aria-checked={on} onClick={() => onChange(!on)}
      style={{ position: x === undefined ? 'relative' : 'absolute', left: x, top: y, width: 50, height: 30, borderRadius: 15, background: on ? onColor : '#c9d3cb', transition: 'background .2s', flex: 'none' }}>
      <span style={{ position: 'absolute', top: 3, left: on ? 23 : 3, width: 24, height: 24, borderRadius: 12, background: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,.15)', transition: 'left .2s' }} />
    </button>
  )
}

export const card: CSSProperties = { background: '#fff', border: `1px solid ${C.line}`, borderRadius: 24, boxShadow: '0 8px 20px rgba(9,83,52,.04)' }

export function Btn({ x = 20, y, w = 372, h = 56, label, onClick, to, kind = 'primary', fs = 14, icon }: { x?: number; y?: number; w?: number | string; h?: number; label: string; onClick?: () => void; to?: string; kind?: 'primary' | 'outline' | 'yellow' | 'muted' | 'danger'; fs?: number; icon?: LucideIcon }) {
  const nav = useNavigate()
  const k = {
    primary: { background: C.green, color: '#fff', boxShadow: '0 10px 18px rgba(9,83,52,.18)' },
    outline: { background: '#fff', color: C.green, border: `2px solid ${C.green}` },
    yellow: { background: C.yellow, color: C.green, boxShadow: '0 10px 18px rgba(9,83,52,.18)' },
    muted: { background: '#e3ebde', color: '#405947' },
    danger: { background: '#c92526', color: '#fff', boxShadow: '0 10px 18px rgba(201,37,38,.2)' },
  }[kind]
  return (
    <button type="button" onClick={() => (to ? nav(to) : onClick?.())}
      style={{ position: y === undefined ? 'relative' : 'absolute', left: y === undefined ? undefined : x, top: y, width: w, height: h, borderRadius: 28, font: `700 ${fs}px/21px Inter`, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, flex: 'none', ...k }}>
      {icon && <Ic icon={icon} s={16} c={k.color} />}
      {label}
    </button>
  )
}

/** Text link, centred under the main button */
export function LinkText({ y, label, to, onClick, s = 15 }: { y: number; label: string; to?: string; onClick?: () => void; s?: number }) {
  const nav = useNavigate()
  return <T x={20} y={y} w={372} s={s} wt={700} lh={21} c={C.green} align="center" onClick={() => (to ? nav(to) : onClick?.())}>{label}</T>
}

/* ---------- bottom navigation ---------- */
const tabs = [
  { key: 'home', label: 'Home', icon: Home, id: '1:814' },
  { key: 'orders', label: 'Orders', icon: Package, id: '1:944' },
  { key: 'earnings', label: 'Earnings', icon: Wallet, id: '1:1816' },
  { key: 'profile', label: 'Profile', icon: User, id: '1:2301' },
] as const
export function BottomNav({ active }: { active: (typeof tabs)[number]['key'] }) {
  const nav = useNavigate()
  return (
    <Box x={20} y={816} w={372} h={68} r={26} bg={C.green} shadow="0 12px 24px rgba(9,83,52,.2)">
      {tabs.map((t, i) => {
        const on = t.key === active
        const col = on ? C.yellow : '#cee3d0'
        return (
          <button key={t.key} type="button" onClick={() => nav(P(t.id))}
            style={{ position: 'absolute', left: 17 + i * 90, top: 7, width: 68, height: 54, borderRadius: 18, background: on ? '#246849' : 'transparent', color: col, font: '600 11px/15.4px Inter', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4 }}>
            <Ic icon={t.icon} c={col} />
            {t.label}
          </button>
        )
      })}
    </Box>
  )
}

/* ---------- headers ---------- */
export function Header({ title, to, right, y = 41 }: { title?: string; to?: string; right?: ReactNode; y?: number }) {
  const nav = useNavigate()
  return (
    <>
      <RoundBtn icon={ArrowLeftIcon} x={20} y={y} onClick={() => (to ? nav(to) : nav(-1))} />
      {title && <T x={80} y={y + 10} w={250} s={20} wt={700} lh={28}>{title}</T>}
      {right}
    </>
  )
}

/** Onboarding step bar (5 segments) */
export function Steps({ step }: { step: number }) {
  return (
    <>
      <T x={325} y={57} w={68} s={11} wt={700} lh={15.4} c={C.muted} align="right">Step {step} of 5</T>
      {[20, 96, 172, 248, 324].map((x, i) => (
        <Box key={x} x={x} y={104} w={70} h={6} r={3} bg={i < step - 1 ? C.green : i === step - 1 ? C.lime : C.line} />
      ))}
    </>
  )
}

/* ---------- form field (flow or absolute) ---------- */
export function Field({ x = 20, y, w = 372, label, value, onChange, icon, placeholder, type, right, focus, ok, h = 55, inputMode }: {
  x?: number; y?: number; w?: number; label?: string; value: string; onChange?: (v: string) => void; icon?: LucideIcon; placeholder?: string
  type?: string; right?: ReactNode; focus?: boolean; ok?: boolean; h?: number; inputMode?: 'numeric' | 'text' | 'email' | 'tel'
}) {
  const [f, setF] = useState(false)
  const active = focus || f
  return (
    <div style={{ position: y === undefined ? 'relative' : 'absolute', left: y === undefined ? undefined : x, top: y, width: w }}>
      {label && <p style={{ font: '600 13px/18.2px Inter', color: C.ink, marginBottom: 8 }}>{label}</p>}
      <div style={{ height: h, borderRadius: 16, background: '#fff', border: active ? `1.5px solid ${C.green}` : `1px solid ${ok ? '#81c895' : C.line}`, boxShadow: active ? '0 0 0 4px rgba(9,83,52,.08)' : undefined, display: 'flex', alignItems: 'center', gap: 11, padding: '0 17px' }}>
        {icon && <Ic icon={icon} s={18} c={C.muted} />}
        <input value={value} readOnly={!onChange} onChange={(e) => onChange?.(e.target.value)} placeholder={placeholder} type={type} inputMode={inputMode}
          onFocus={() => setF(true)} onBlur={() => setF(false)}
          style={{ flex: 1, minWidth: 0, border: 0, outline: 0, background: 'transparent', font: '600 16px/22.4px Inter', color: C.ink }} />
        {right}
      </div>
    </div>
  )
}

/* ---------- modal sheet ---------- */
export function Modal({ children, onClose, w = 372 }: { children: ReactNode; onClose: () => void; w?: number }) {
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 40, background: 'rgba(10,30,22,.45)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div onClick={(e) => e.stopPropagation()} style={{ position: 'relative', width: w, background: '#fff', borderRadius: 28, boxShadow: '0 24px 60px rgba(0,0,0,.25)', padding: 24 }}>
        {children}
      </div>
    </div>
  )
}

export { Box, C, Img, T }
