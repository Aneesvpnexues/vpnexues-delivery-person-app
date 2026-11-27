import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, ChevronLeft, LocateFixed } from 'lucide-react'
import Phone from '../components/Phone'
import { Box, Btn, C, Ic, LinkText, P, Pill, RoundBtn, Screen, T, card, pill, toast, useGoBack } from '../components/kit'
import { topBleed } from '../components/ui'
import { api, showError } from '../api/client'
import { useApi, useSession } from '../api/session'
import mapZone from '../assets/art/map-zone.png'

type ZoneData = { delivery_radius_km: number; hub_id: string | null; hub_name: string | null; lat: number | null; lng: number | null; allowed_radii_km: number[] | null; recommended_radius_km: number | null; areas_by_radius: Record<string, string[]> | null; city: string }

export function Zone() {
  const nav = useNavigate()
  const goBack = useGoBack(P('1:814'))
  const { refreshMe } = useSession()
  const z = useApi<ZoneData>('/v1/me/zone')
  const [km, setKm] = useState(5)
  const [busy, setBusy] = useState(false)
  useEffect(() => { if (z.data) setKm(z.data.delivery_radius_km) }, [z.data])
  const opts = (z.data?.allowed_radii_km?.length ? z.data.allowed_radii_km : [3, 5, 7]).slice(0, 3)
  const areas = z.data?.areas_by_radius?.[String(km)] ?? []
  const w = 331 / opts.length
  const save = async () => {
    setBusy(true)
    try {
      await api('/v1/me/zone/radius', { method: 'PUT', body: { radiusKm: km } })
      await refreshMe()
      toast(`Delivery radius set to ${km} km`)
      nav(P('1:814'))
    } catch (e) { showError(e) } finally { setBusy(false) }
  }
  return (
    <Screen>
      <img src={mapZone} alt="Zone map" style={topBleed(322)} />
      {/* goBack keeps shizan's nav(-1) behavior and adds a fallback route on fresh launches. */}
      <RoundBtn icon={ArrowLeft} x={20} y={48} onClick={goBack} />
      <RoundBtn icon={LocateFixed} x={344} y={48} onClick={() => void z.reload().then(() => toast('Zone refreshed'))} />
      <Pill x={20} y={279} w={155} label={`${km} km service radius`} color="#fff" dot="#b6dc45" />

      <T x={20} y={334} s={11} wt={700} lh={15.4} c={C.accent} ls={1.2}>MY ZONE</T>
      <T x={20} y={349} w={260} s={24} wt={700} lh={33} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{z.data?.hub_name ?? (z.loading ? 'Loading…' : 'No hub assigned')}</T>
      {z.data?.hub_name && <Pill x={289} y={344} w={103} label="Your hub" {...pill.ok} style={{ justifyContent: 'center' }} />}
      <T x={20} y={385} w={360} s={13.5} lh={21} c={C.muted}>Orders are offered only inside your radius. A bigger radius means more orders but longer trips.</T>

      <Box onClick={() => nav(P('17:39'))} x={20} y={438} w={372} h={64} r={22} bg="#fff" style={{ font: '700 15px/21px Inter', color: C.ink, textAlign: 'left', paddingLeft: 16 }}>{`${z.data?.city ?? '…'} · Change city / hub`}</Box>

      <div style={{ position: 'absolute', left: 20, top: 519, width: 372, height: 177, ...card }} />
      <T x={36} y={538} s={15} wt={700} lh={21}>Delivery radius</T>
      <T x={275} y={534} w={100} s={20} wt={700} lh={28} c={C.accent} align="right">{km} km</T>
      <Box x={36} y={577} w={339} h={56} r={28} bg="#fff" border={`1px solid ${C.line}`} />
      {opts.includes(km) && <Box x={40 + opts.indexOf(km) * w} y={581} w={w} h={48} r={24} bg={C.green} style={{ transition: 'left .2s' }} />}
      {opts.map((o, i) => (
        <Box key={o} onClick={() => setKm(o)} x={40 + i * w} y={581} w={w} h={48} style={{ font: '700 13px/18.2px Inter', color: o === km ? '#fff' : C.muted }}>{o} km</Box>
      ))}
      <T x={36} y={645} w={335} s={12} lh={18} c={C.muted}>{z.data?.recommended_radius_km ? `Recommended for this hub: ${z.data.recommended_radius_km} km.` : 'Pick the distance you’re comfortable riding.'}</T>

      <div style={{ position: 'absolute', left: 20, top: 710, width: 372, height: 80, ...card }} />
      <T x={36} y={721} s={15} wt={700} lh={21}>Areas covered</T>
      <div style={{ position: 'absolute', left: 36, top: 747, width: 340, display: 'flex', gap: 8, overflow: 'hidden' }}>
        {areas.length ? areas.map((a) => (
          <span key={a} style={{ height: 32, padding: '0 13px', borderRadius: 16, border: `1px solid ${C.line}`, font: '700 12px/30px Inter', color: '#405947', whiteSpace: 'nowrap' }}>{a}</span>
        )) : <span style={{ font: '500 12px/32px Inter', color: C.muted }}>Area list not available for this hub yet</span>}
      </div>
      <Btn y={806} label={busy ? 'SAVING…' : 'SAVE RADIUS'} onClick={() => !busy && void save()} />
      <LinkText y={876} s={13} label="Change city or request a different hub" to={P('17:39')} />
    </Screen>
  )
}

type City = { id: number; name: string; state: string }
export function ChangeCity() {
  const nav = useNavigate()
  const goBack = useGoBack(P('1:3906'))
  const { me } = useSession()
  const cities = useApi<City[]>('/v1/cities')
  const [cityId, setCityId] = useState<number | null>(me?.city.id ?? null)
  const hubs = useApi<{ id: string; name: string }[]>(cityId ? `/v1/cities/${cityId}/hubs` : null)
  const [busy, setBusy] = useState(false)
  const city = cities.data?.find((c) => c.id === cityId)
  const same = cityId === me?.city.id
  const hub = hubs.data?.[0]
  const request = async () => {
    if (!cityId) return toast('Choose a city')
    if (same && (!hub || hub.id === me?.hub?.id)) return toast('That’s already your city and hub')
    setBusy(true)
    try {
      await api('/v1/me/zone/change-request', { body: { cityId, ...(hub ? { hubId: hub.id } : {}) } })
      toast('Request sent. Support will confirm the change.')
      nav(P('1:3289'))
    } catch (e) { showError(e) } finally { setBusy(false) }
  }
  return (
    <Phone>
      <Box onClick={goBack} x={12} y={44} w={48} h={44}><Ic icon={ChevronLeft} x={6} y={11} s={22} sw={3} c={C.ink} /></Box>
      <T x={80} y={51} s={20} wt={700} lh={28}>Change city or hub</T>
      <T x={20} y={122} s={22} wt={700} lh={30}>Choose your delivery city</T>
      <T x={20} y={164} s={13} lh={18.2}>{`Current city: ${me?.city.name ?? '…'}`}</T>
      {(cities.data ?? []).slice(0, 3).map((c, i) => (
        <Box key={c.id} onClick={() => setCityId(c.id)} x={20} y={201 + i * 58} w={372} h={48} r={16} bg={cityId === c.id ? C.green : '#fff'}
          style={{ font: '700 15px/21px Inter', color: cityId === c.id ? '#fff' : C.ink, textAlign: 'left', paddingLeft: 18 }}>{c.name}</Box>
      ))}
      <Box x={20} y={400} w={372} h={172} r={22} bg="#fff" />
      <T x={38} y={421} s={15} wt={700} lh={21}>Delivery hub</T>
      <T x={38} y={456} w={340} s={20} wt={700} lh={28}>{hubs.loading ? 'Loading…' : hub ? hub.name : `${city?.name ?? 'This city'} · hub to be confirmed`}</T>
      <T x={38} y={495} w={300} s={13.5} lh={19}>Changing your hub or city? Support will confirm coverage before the change takes effect.</T>
      <Box x={20} y={596} w={372} h={148} r={22} bg="#eaf2d9" />
      <T x={38} y={617} s={15} wt={700} lh={21}>Keep your current zone active</T>
      <T x={38} y={650} w={330} s={13.5} lh={19}>{`Your current ${me?.city.name ?? ''} zone stays unchanged until support confirms the move.`}</T>
      <Btn y={784} label={busy ? 'SENDING…' : 'SEND REQUEST TO SUPPORT'} onClick={() => !busy && void request()} />
      <T x={20} y={860} w={372} s={14} wt={700} lh={20} align="center" onClick={goBack}>Keep my current location</T>
    </Phone>
  )
}
