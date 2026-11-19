import { Link } from 'react-router-dom'
import Phone from '../components/Phone'
import logo from '../assets/logo.png'
import glowTop from '../assets/glow-top.svg'
import glowSoft from '../assets/glow-soft.svg'
import leaf from '../assets/leaf-deco.svg'
import { CornerLeaves } from '../components/ui'
import scooter from '../assets/illustration-scooter.svg'

export default function Splash() {
  return (
    <Phone>
      <img className="abs" src={glowTop} alt="" style={{ left: 190, top: -150, width: 370, height: 370 }} />
      <img className="abs" src={glowSoft} alt="" style={{ left: -150, top: 250, width: 330, height: 330 }} />
      <img className="abs" src={leaf} alt="" style={{ left: 358, top: 90, width: 60, height: 90 }} />

      <CornerLeaves />
      <div className="abs" style={{ left: 48, top: 56, width: 68, height: 68, borderRadius: 62, overflow: 'hidden', boxShadow: '0 13px 30px rgba(9,83,52,.12)' }}>
        <img src={logo} alt="VP Nexues" style={{ position: 'absolute', height: '735.29%', left: '-115.89%', top: '-70.59%', width: '331.13%', maxWidth: 'none' }} />
      </div>
      <p className="abs" style={{ left: 134, top: 57.7, font: '700 30px/40.3px Inter', color: 'var(--primary-29)' }}>VP NEXUES</p>
      <div className="abs" style={{ left: 136, top: 102, width: 132, height: 20, borderRadius: 12, background: '#ffcd24', font: '700 12px/20px Inter', color: '#3a3e34', textAlign: 'center' }}>
        Delivery partner app
      </div>

      <img className="abs" src={scooter} alt="" style={{ left: 105, top: 234, width: 200, height: 232 }} />

      <h1 className="abs" style={{ left: 47.7, top: 540, width: 244, font: '700 50px/50px Inter', background: 'linear-gradient(90deg,#247947 3%,#e9d231)', WebkitBackgroundClip: 'text', color: 'transparent' }}>
        Fresh Deliveries
      </h1>
      <p className="abs" style={{ left: 47.7, top: 653, width: 260, font: '700 24px/36px Inter', color: 'var(--ink-muted)' }}>Delivery Partner App</p>

      <Link to="/signup" className="abs" style={{ left: 20, top: 735, width: 372, height: 56, borderRadius: 28, background: 'var(--yellow)', boxShadow: '0 10px 18px rgba(9,83,52,.18)', font: '700 14px/56px Inter', color: '#095334', textAlign: 'center' }}>
        GET STARTED
      </Link>
      <Link to="/login" className="abs" style={{ left: 30, top: 821.5, width: 352, font: '700 14px/21px Inter', color: 'var(--primary-29)', textAlign: 'center' }}>
        I ALREADY HAVE AN ACCOUNT
      </Link>
    </Phone>
  )
}
