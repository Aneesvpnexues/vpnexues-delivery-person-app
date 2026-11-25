import { Link, useLocation } from 'react-router-dom'
import Phone from '../components/Phone'

export default function ComingSoon() {
  const { pathname } = useLocation()
  return (
    <Phone>
      <div style={{ padding: 40, paddingTop: 300, textAlign: 'center', color: 'var(--primary-29)' }}>
        <p style={{ font: '700 22px/30px Inter' }}>{pathname}</p>
        <p style={{ font: '400 14px/22px Inter', marginTop: 8 }}>This screen hasn't been built yet.</p>
        <Link to="/" style={{ display: 'inline-block', marginTop: 24, font: '700 14px Inter' }}>← Back to start</Link>
      </div>
    </Phone>
  )
}
