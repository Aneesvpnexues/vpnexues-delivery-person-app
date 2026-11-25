import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import Splash from './screens/Splash'
import SignUp from './screens/SignUp'
import Login from './screens/Login'
import Otp from './screens/Otp'
import Password from './screens/Password'
import ComingSoon from './screens/ComingSoon'
import { screens } from './nav'
import { built } from './screens/registry'
import { RequireAuth, SessionProvider, useSession } from './api/session'

const handBuilt = new Set(['1:2', '1:152', '1:260', '1:364', '1:461'])

/** Public screens send signed-in partners straight to Home. */
function PublicOnly({ children }: { children: React.ReactElement }) {
  const { status } = useSession()
  return status === 'in' ? <Navigate to="/home" replace /> : children
}

export default function App() {
  return (
    <SessionProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<PublicOnly><Splash /></PublicOnly>} />
          <Route path="/signup" element={<PublicOnly><SignUp /></PublicOnly>} />
          <Route path="/login" element={<PublicOnly><Login /></PublicOnly>} />
          <Route path="/otp" element={<Otp />} />
          <Route path="/password" element={<RequireAuth><Password /></RequireAuth>} />
          {Object.values(screens)
            .filter((s) => !handBuilt.has(s.id) && !s.popup)
            .map((s) => (
              <Route key={s.id} path={s.path} element={<RequireAuth>{built[s.id] ?? <ComingSoon />}</RequireAuth>} />
            ))}
          <Route path="*" element={<ComingSoon />} />
        </Routes>
      </BrowserRouter>
    </SessionProvider>
  )
}
