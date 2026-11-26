import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { Toast } from './toast'

const W = 412
const H = 915
/** Empty design space below the bottom nav (it ends at y=884). It may sit behind the Android
 *  navigation buttons, so it doesn't count when fitting the design to the screen. */
const BOTTOM_SLACK = 30

// The on-screen keyboard shrinks the viewport height. If we re-fit to that, the whole
// app "zooms out". So we remember the tallest height seen for the current width and
// keep using it; only a width change (rotation / window resize) resets it.
const stable = { w: 0, h: 0 }
function stableHeight() {
  const w = window.innerWidth
  const h = window.innerHeight
  if (w !== stable.w) { stable.w = w; stable.h = h }
  else stable.h = Math.max(stable.h, h)
  return stable.h
}

/** Gap kept between a focused field and the top of the keyboard (screen px). */
const KB_GAP = 16
const isField = (el: Element | null): el is HTMLElement =>
  !!el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT' || (el as HTMLElement).isContentEditable)

type Fit = { scale: number; h: number; left: number; top: number; bx: number; bt: number; bb: number; desk: boolean }

/**
 * Design canvas is 412x915, the same shape as most phones (20:9).
 * Phones: fill the width and draw edge to edge. The design already leaves its top ~40px for the
 * status bar, and only its empty bottom slack may go behind the navigation bar, so nothing is
 * hidden. Full-width art then stretches into any leftover sliver via the --bleed-* variables.
 * Desktop: show the phone frame centred, never larger than its design size.
 */
export default function Phone({ children }: { children: ReactNode }) {
  const probe = useRef<HTMLDivElement>(null)
  const [fit, setFit] = useState<Fit>({ scale: 0, h: 0, left: 0, top: 0, bx: 0, bt: 0, bb: 0, desk: false })

  useLayoutEffect(() => {
    const el = probe.current
    if (!el) return
    const measure = () => {
      const h = stableHeight()
      const vw = window.innerWidth
      // The probe carries the safe-area insets as padding (env() + Capacitor's --safe-area-* vars).
      const cs = getComputedStyle(el)
      const pl = parseFloat(cs.paddingLeft), pr = parseFloat(cs.paddingRight)
      const pt = parseFloat(cs.paddingTop), pb = parseFloat(cs.paddingBottom)
      const desk = vw > 600
      let next: Fit
      if (desk) {
        const s = Math.min(1, (vw - pl - pr) / W, (h - pt - pb) / H)
        next = { scale: s, h, left: (vw - W * s) / 2, top: Math.max(pt, (h - H * s) / 2), bx: 0, bt: 0, bb: 0, desk }
      } else {
        const aw = vw - pl - pr
        const usable = h - pb                       // everything above the navigation bar
        const s = Math.min(aw / W, usable / (H - BOTTOM_SLACK))
        const left = pl + (aw - W * s) / 2
        const top = Math.max(0, (usable - (H - BOTTOM_SLACK) * s) / 2)
        next = { scale: s, h, left, top, bx: left / s, bt: top / s, bb: Math.max(0, h - top - H * s) / s, desk }
      }
      setFit((f) => (Object.keys(next) as (keyof Fit)[]).every((k) => f[k] === next[k]) ? f : next)
    }
    measure()
    window.addEventListener('resize', measure)
    window.addEventListener('orientationchange', measure)
    return () => {
      window.removeEventListener('resize', measure)
      window.removeEventListener('orientationchange', measure)
    }
  }, [])

  // Keyboard open: never re-scale (see stableHeight), just slide the whole canvas up far enough that the
  // focused field stays visible above the keyboard. Slides back when the keyboard closes.
  const [lift, setLift] = useState(0)
  const liftRef = useRef(0)
  useEffect(() => {
    const vv = window.visualViewport
    let t = 0
    const apply = (v: number) => { v = Math.round(v); if (v !== liftRef.current) { liftRef.current = v; setLift(v) } }
    const update = () => {
      const el = document.activeElement
      const vh = vv?.height ?? window.innerHeight
      const offTop = vv?.offsetTop ?? 0
      const keyboard = stable.h - vh - offTop
      if (!isField(el) || keyboard < 120) return apply(0)
      const r = el.getBoundingClientRect()
      const bottom = r.bottom + liftRef.current        // where the field sits with no lift
      const topEdge = r.top + liftRef.current
      const need = bottom + KB_GAP - (vh + offTop)
      apply(need <= 0 ? 0 : Math.min(need, Math.max(0, topEdge - 12), keyboard))
      if (window.scrollY) window.scrollTo(0, 0)
    }
    const soon = () => { clearTimeout(t); t = window.setTimeout(update, 80) }
    vv?.addEventListener('resize', update)
    vv?.addEventListener('scroll', update)
    window.addEventListener('resize', update)
    document.addEventListener('focusin', soon)
    document.addEventListener('focusout', soon)
    return () => {
      clearTimeout(t)
      vv?.removeEventListener('resize', update)
      vv?.removeEventListener('scroll', update)
      window.removeEventListener('resize', update)
      document.removeEventListener('focusin', soon)
      document.removeEventListener('focusout', soon)
    }
  }, [])

  const { scale, h, left, top, bx, bt, bb, desk } = fit
  const vars = {
    '--bleed-x': `${bx}px`, '--bleed-top': `${bt}px`, '--bleed-bottom': `${bb}px`,
    '--bleed-right': `${bx}px`, // kept for CornerLeaves
  } as CSSProperties
  return (
    <div className={`stage ${desk ? 'desk' : ''}`} style={h ? { height: h } : undefined}>
      <div ref={probe} className="safe-probe" aria-hidden />
      <div style={{ position: 'absolute', left, top, width: W * scale, height: H * scale, visibility: scale ? 'visible' : 'hidden', transform: lift ? `translateY(${-lift}px)` : undefined, transition: 'transform .2s ease' }}>
        {/* On phones, edge art (headers, maps, glows, leaves) bleeds past the canvas to the real screen edges. */}
        <div className="phone" style={{ ...vars, transform: `scale(${scale})`, transformOrigin: 'top left', overflow: desk ? 'hidden' : 'visible' }}>
          {children}
          <Toast />
        </div>
      </div>
    </div>
  )
}
