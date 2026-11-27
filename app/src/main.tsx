import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@fontsource/inter/400.css'
import '@fontsource/inter/500.css'
import '@fontsource/inter/600.css'
import '@fontsource/inter/700.css'
import './index.css'
import App from './App.tsx'
import { App as NativeApp } from '@capacitor/app'

// Android hardware back button: go back a screen. On the "root" screens (splash, login, home) leave the app instead,
// otherwise after Log out the back button bounces between the login page and old signed-in pages.
const ROOT_SCREENS = new Set(['/', '/login', '/home'])
NativeApp.addListener('backButton', ({ canGoBack }) => {
  if (canGoBack && !ROOT_SCREENS.has(window.location.pathname)) window.history.back()
  else NativeApp.exitApp()
}).catch(() => {})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
