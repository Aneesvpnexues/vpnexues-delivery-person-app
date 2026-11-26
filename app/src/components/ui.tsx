import type { CSSProperties, ReactNode, MouseEventHandler } from 'react'
import { Link } from 'react-router-dom'
import glowTop from '../assets/ui/glow-top.svg'
import glowSoft from '../assets/ui/glow-soft.svg'
import outline from '../assets/ui/outline.svg'
import backButton from '../assets/ui/back-button.svg'
import backIcon from '../assets/ui/back-icon.svg'
import leavesImg from '../assets/art/leaves.png'

export const C = {
  bg: '#f7f8f1',
  ink: '#173e30',
  green: '#095334',
  accent: '#247947',
  muted: '#5e6b62',
  line: '#dfe5dd',
  tint5: '#edf0ea',
  surface: '#fff',
  yellow: '#f8d92f',
  lime: '#9cc42c',
}

type Pos = { x?: number; y?: number; w?: number | string; h?: number | string; r?: number | string }

/**
 * Full-width design elements (x=0, w=412) stretch to the real screen edges on phones, and ones
 * touching the top / bottom of the canvas stretch behind the status / navigation bar, so wide
 * phones never show a strip of page background beside a header, map or sheet.
 */
function bleed(x: unknown, y: unknown, w: unknown, h: unknown): CSSProperties {
  if (x !== 0 || w !== 412) return {}
  const top = y === 0
  const bottom = typeof y === 'number' && typeof h === 'number' && y + h >= 915
  const extraH = [top && 'var(--bleed-top, 0px)', bottom && 'var(--bleed-bottom, 0px)'].filter(Boolean).join(' + ')
  return {
    left: 'calc(-1 * var(--bleed-x, 0px))',
    width: 'calc(412px + 2 * var(--bleed-x, 0px))',
    ...(top ? { top: 'calc(-1 * var(--bleed-top, 0px))' } : {}),
    ...(extraH && typeof h === 'number' ? { height: `calc(${h}px + ${extraH})` } : {}),
  }
}

/** Full-bleed image pinned to the top of the screen (maps, hero art). */
export const topBleed = (h: number): CSSProperties => ({
  position: 'absolute', left: 'calc(-1 * var(--bleed-x, 0px))', top: 'calc(-1 * var(--bleed-top, 0px))',
  width: 'calc(412px + 2 * var(--bleed-x, 0px))', height: `calc(${h}px + var(--bleed-top, 0px))`, objectFit: 'cover', maxWidth: 'none',
})

/**
 * Map artwork with the route / pill / buttons drawn into it. It must stay at its exact design size
 * (412 x h) or those baked-in shapes drift away from the live overlays placed on top. A blurred,
 * stretched copy fills the safe-area / side bleed instead.
 */
export function MapArt({ src, h, alt }: { src: string; h: number; alt: string }) {
  return (
    <>
      <div aria-hidden style={{ ...topBleed(h), objectFit: undefined, overflow: 'hidden', pointerEvents: 'none' }}>
        <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', filter: 'blur(12px)', transform: 'scale(1.08)' }} />
      </div>
      <img src={src} alt={alt} draggable={false} style={{ position: 'absolute', left: 0, top: 0, width: 412, height: h, maxWidth: 'none' }} />
    </>
  )
}

/** Absolutely positioned box (design canvas coordinates). */
export function Box({
  x, y, w, h, r, bg, border, shadow, style, children, onClick, to,
}: Pos & {
  bg?: string; border?: string; shadow?: string; style?: CSSProperties; children?: ReactNode
  onClick?: MouseEventHandler; to?: string
}) {
  const s: CSSProperties = {
    position: 'absolute', left: x, top: y, width: w, height: h, borderRadius: r,
    background: bg, border, boxShadow: shadow, ...bleed(x, y, w, h), ...style,
  }
  if (to) return <Link to={to} style={{ ...s, display: 'block' }}>{children}</Link>
  if (onClick) return <button type="button" onClick={onClick} style={{ ...s, display: 'block' }}>{children}</button>
  return <div style={s}>{children}</div>
}

/** Absolutely positioned text. */
export function T({
  x, y, w, s = 13, wt = 400, c = C.ink, lh, align, ls, children, style, to, onClick, transform,
}: Pos & {
  s?: number; wt?: number; c?: string; lh?: number | string; align?: 'left' | 'center' | 'right'; ls?: number
  children: ReactNode; style?: CSSProperties; to?: string; onClick?: MouseEventHandler; transform?: string
}) {
  const st: CSSProperties = {
    position: 'absolute', left: x, top: y, width: w, fontSize: s, fontWeight: wt, color: c,
    lineHeight: typeof lh === 'number' ? `${lh}px` : lh ?? 1.35, textAlign: align, letterSpacing: ls,
    transform, wordBreak: 'break-word', whiteSpace: 'pre-wrap', ...style,
  }
  if (to) return <Link to={to} style={{ ...st, display: 'block' }}>{children}</Link>
  if (onClick) return <button type="button" onClick={onClick} style={{ ...st, display: 'block', textAlign: align ?? 'left' }}>{children}</button>
  return <p style={st}>{children}</p>
}

export function Img({ src, x, y, w, h, style }: { src: string; x: number; y: number; w: number; h: number; style?: CSSProperties }) {
  return <img src={src} alt="" draggable={false} style={{ position: 'absolute', left: x, top: y, width: w, height: h, maxWidth: 'none', ...style }} />
}

/** Rounded card/input style helper */
export const inputBox = (focused = false): CSSProperties => ({
  background: '#fff',
  border: focused ? `1.5px solid ${C.green}` : `1px solid ${C.line}`,
  boxShadow: focused ? '0 0 0 4px rgba(9,83,52,.08)' : undefined,
})

/** Top-right leaf cluster, pinned to the physical screen corner (the art is cut flat on its top/right edges). */
export function CornerLeaves() {
  return <img src={leavesImg} alt="" style={{ position: 'absolute', left: 'calc(326px + var(--bleed-right, 0px))', top: 'calc(-1 * var(--bleed-top, 0px))', width: 86, height: 86, pointerEvents: 'none', zIndex: 5 }} />
}

/** Ambient glows, top-right leaf cluster and faint leaf outlines shared by every screen. */
export function Backdrop({ outlines = ['3.27% 49.51% 82% 7.77%', '46.89% 6.8% 38.38% 50.49%', '75.41% 49.51% 9.85% 7.77%'] }: { outlines?: string[] }) {
  return (
    <>
      <Img src={glowTop} x={190} y={-150} w={370} h={370} />
      <Img src={glowSoft} x={-150} y={250} w={330} h={330} />
      <CornerLeaves />
      {outlines.map((o, i) => (
        <div key={i} style={{ position: 'absolute', inset: o }}>
          <img src={outline} alt="" style={{ position: 'absolute', inset: '-0.52% -0.44% -0.52% -0.57%', width: '100.99%', height: '101.04%', maxWidth: 'none' }} />
        </div>
      ))}
    </>
  )
}

/** Top bar: back button, optional title and right-hand slot */
export function BackBar({ title, right, to }: { title?: string; right?: ReactNode; to?: string }) {
  const inner = (
    <>
      <Img src={backButton} x={-12} y={-8} w={72} h={72} />
      <Img src={backIcon} x={15} y={14} w={20} h={20} />
    </>
  )
  return (
    <>
      {to ? (
        <Box to={to} x={20} y={41} w={48} h={48}>{inner}</Box>
      ) : (
        <Box onClick={() => history.back()} x={20} y={41} w={48} h={48}>{inner}</Box>
      )}
      {title !== undefined && <T x={80} y={51} w={246} s={20} wt={700} lh={28}>{title}</T>}
      {right}
    </>
  )
}

export function PrimaryButton({ y, label, to, onClick, w = 372, x = 20, bg = C.green, color = '#fff' }: { y: number; label: string; to?: string; onClick?: MouseEventHandler; w?: number; x?: number; bg?: string; color?: string }) {
  const style: CSSProperties = {
    position: 'absolute', left: x, top: y, width: w, height: 56, borderRadius: 28, background: bg,
    boxShadow: '0 10px 18px rgba(9,83,52,.18)', color, fontSize: 14, fontWeight: 700, lineHeight: '56px', textAlign: 'center', display: 'block',
  }
  return to ? <Link to={to} style={style}>{label}</Link> : <button type="button" onClick={onClick} style={style}>{label}</button>
}

export function OutlineButton({ y, label, to, onClick }: { y: number; label: string; to?: string; onClick?: MouseEventHandler }) {
  const style: CSSProperties = {
    position: 'absolute', left: 20, top: y, width: 372, height: 56, borderRadius: 28, background: '#fff',
    border: `2px solid ${C.green}`, color: C.green, fontSize: 14, fontWeight: 700, lineHeight: '52px', textAlign: 'center', display: 'block',
  }
  return to ? <Link to={to} style={style}>{label}</Link> : <button type="button" onClick={onClick} style={style}>{label}</button>
}
