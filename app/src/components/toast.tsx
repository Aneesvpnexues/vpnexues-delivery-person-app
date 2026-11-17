import { useEffect, useState } from 'react'

/** Short status message shown at the bottom of the phone canvas. Works on every screen. */
let pushToast: (m: string) => void = () => {}
export const toast = (m: string) => pushToast(m)

export function Toast() {
  const [msg, setMsg] = useState<string | null>(null)
  useEffect(() => {
    pushToast = (m) => setMsg(m)
    return () => { pushToast = () => {} }
  }, [])
  useEffect(() => {
    if (!msg) return
    const t = setTimeout(() => setMsg(null), Math.min(5000, 1800 + msg.length * 30))
    return () => clearTimeout(t)
  }, [msg])
  if (!msg) return null
  return (
    <div role="status" style={{ position: 'absolute', left: 40, right: 40, bottom: 110, zIndex: 60, background: '#173e30', color: '#fff', borderRadius: 16, padding: '12px 16px', font: '600 13px/18px Inter', textAlign: 'center', boxShadow: '0 12px 24px rgba(0,0,0,.2)' }}>
      {msg}
    </div>
  )
}
