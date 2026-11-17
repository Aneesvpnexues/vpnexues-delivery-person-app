import { useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
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

  const { scale, h, left, top, bx, bt, bb, desk } = fit
  const vars = {
    '--bleed-x': `${bx}px`, '--bleed-top': `${bt}px`, '--bleed-bottom': `${bb}px`,
    '--bleed-right': `${bx}px`, // kept for CornerLeaves
  } as CSSProperties
  return (
    <div className={`stage ${desk ? 'desk' : ''}`} style={h ? { height: h } : undefined}>
      <div ref={probe} className="safe-probe" aria-hidden />
      <div style={{ position: 'absolute', left, top, width: W * scale, height: H * scale, visibility: scale ? 'visible' : 'hidden' }}>
        {/* On phones, edge art (headers, maps, glows, leaves) bleeds past the canvas to the real screen edges. */}
        <div className="phone" style={{ ...vars, transform: `scale(${scale})`, transformOrigin: 'top left', overflow: desk ? 'hidden' : 'visible' }}>
          {children}
          <Toast />
        </div>
      </div>
    </div>
  )
}
