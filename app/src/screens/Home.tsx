import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MapPin, PackagePlus, ScanQrCode, Star, TriangleAlert, Wallet } from 'lucide-react'
import { BellBtn, BottomNav, Box, Btn, C, Ic, Logo, P, Pill, Screen, T, Tile, Toggle, pill } from '../components/kit'
import { date, firstName, greeting, inr, useApi, useSession } from '../api/session'
import { createDemoOrder, orderScreen, statusLabel } from '../api/orders'
import type { EarningsSummary, OrderListItem } from '../api/types'

export default function Home() {
  const nav = useNavigate()
  const { me, online, setOnline, trial } = useSession()
  const orders = useApi<OrderListItem[]>('/v1/orders?tab=active')
  const today = useApi<EarningsSummary>('/v1/earnings/summary?range=today')
  const notes = useApi<{ unreadCount: number }>('/v1/notifications?limit=1')
  const [creating, setCreating] = useState(false)
  const next = orders.data?.[0]
  const queued = (orders.data?.length ?? 0) - 1

  const demo = async () => {
    setCreating(true)
    const id = await createDemoOrder()
    setCreating(false)
    if (id) { await orders.reload(); nav(`${P('1:1223')}?id=${id}`) }
  }

  return (
    <Screen ol="c">
      <Logo x={20} y={51} s={44} />
      <T x={76} y={41} w={175} s={12} wt={700} lh={16.8} c={C.muted}>{date(new Date().toISOString(), { weekday: 'long', day: 'numeric', month: 'long' })}</T>
      <T x={76} y={59} w={170} s={18} wt={700} lh={22.5}>{`${greeting()},\n${firstName(me?.full_name) || 'partner'}`}</T>
      <Box onClick={() => nav(P('1:3533'))} x={251} y={49} w={81} h={48} r={24} bg="#c92526" shadow="0 10px 20px rgba(9,83,52,.2)">
        <Ic icon={TriangleAlert} x={15} y={15} s={16} c="#fff" />
        <T x={37} y={15} s={14} wt={700} lh={19.6} c="#fff">SOS</T>
      </Box>
      <BellBtn dot={(notes.data?.unreadCount ?? 0) > 0} />

      <Box x={20} y={121} w={372} h={50} r={25} bg="#fff" />
      <Box x={31} y={135} w={23} h={23} r={12} bg={online ? '#d9f0df' : '#e6e9e4'} />
      <Box x={37} y={141} w={11} h={11} r={6} bg={online ? '#2fb463' : '#9aa69e'} />
      <T x={59} y={137} s={14} wt={700} lh={19.6}>{online ? 'Online' : 'Offline'}</T>
      <T x={online ? 107 : 111} y={137} w={218} s={12} wt={500} lh={19.6} c={C.muted} onClick={() => nav(P('1:3906'))}>
        {`· ${me?.hub?.name.replace(/ Hub$/, '') ?? 'No hub'} · ${me?.delivery_radius_km ?? 5} km · Change`}
      </T>
      <Toggle x={332} y={131} on={online} onChange={async (v) => { const ok = await setOnline(v); if (ok && !v) nav(P('1:1698')) }} />

      <Box x={20} y={188} w={372} h={352} r={32} bg="linear-gradient(125deg,#063a2a 0%,#1f7945 100%)" shadow="0 18px 28px rgba(9,83,52,.2)" />
      {next ? (
        <>
          <Pill x={117} y={210} w={168} label={next.status === 'assigned' ? 'New order · tap to accept' : `Next · ${statusLabel[next.status].toLowerCase()}`} bg="#356d35" color="#dfee91" style={{ justifyContent: 'center' }} />
          <T x={33} y={246} w={346} s={20} wt={700} lh={26} c="#fff" align="center" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {next.status === 'picked_up' || next.status === 'arrived' ? `#${next.order_code} is on its way` : `#${next.order_code} is waiting at the hub`}
          </T>
          <Box x={110} y={292} w={184} h={184} r={92} border="1px dashed #b9c74a" />
          <Box x={119} y={301} w={166} h={166} r={83} bg="rgba(40,96,52,.9)" />
          <Box x={128} y={310} w={148} h={148} r={74} bg="#41652f" />
          <Box onClick={() => nav(orderScreen(next.id, next.status))} x={136} y={318} w={132} h={132} r={66} bg="radial-gradient(circle at 50% 38%,#fff27a 0%,#f8dc36 55%,#efc81f 100%)">
            <Ic icon={ScanQrCode} x={45} y={23} s={42} sw={2.6} />
            <T x={0} y={66} w={132} s={16} wt={700} lh={26.6} c={C.green} align="center">{next.status === 'assigned' ? 'View order' : 'Continue'}</T>
            <T x={0} y={94} w={132} s={10} wt={600} lh={11.8} c="#49622d" align="center">{statusLabel[next.status]}</T>
          </Box>
          <Pill x={44} y={500.5} w={175} label={next.hub_name} bg="#34825a" color="#fff" />
          <Pill x={235.75} y={500.5} w={132} label={`${next.crate_count} crate${next.crate_count === 1 ? '' : 's'}`} bg="#34825a" color="#fff" style={{ padding: '0 5px', gap: 6, justifyContent: 'center' }} />
        </>
      ) : (
        <>
          <Pill x={131} y={210} w={150} label={orders.loading ? 'Checking orders…' : 'All caught up'} bg="#356d35" color="#dfee91" style={{ justifyContent: 'center' }} />
          <T x={43} y={244} w={326} s={22} wt={700} lh={28.2} c="#fff" align="center">{orders.loading ? 'Loading your orders' : 'No orders right now'}</T>
          <T x={53} y={280} w={306} s={13} wt={500} lh={19} c="#cfe3d0" align="center">
            {online ? 'Stay online inside your zone. New orders appear here the moment the hub assigns them.' : 'Go online to start receiving orders from your hub.'}
          </T>
          <Box x={136} y={340} w={140} h={140} r={70} bg="rgba(255,255,255,.08)" border="1px dashed rgba(185,199,74,.6)">
            <Ic icon={PackagePlus} x={45} y={45} s={50} c="#dfee91" sw={1.6} />
          </Box>
          {trial && !orders.loading && (
            <Btn x={56} y={490} w={300} h={40} fs={12} kind="yellow" label={creating ? 'CREATING…' : 'CREATE A DEMO ORDER (TRIAL)'} onClick={() => !creating && void demo()} />
          )}
        </>
      )}

      <Box x={20} y={556} w={372} h={157} r={24} bg="#fff" shadow="0 8px 22px rgba(9,83,52,.05)" />
      {next ? (
        <>
          <T x={37} y={574} s={16} wt={700} lh={22.4}>Then deliver to</T>
          <Pill x={240} y={572} w={135} label={statusLabel[next.status]} style={{ justifyContent: 'center' }} />
          <Tile x={37} y={609} bg="#fff3bf" icon={MapPin} />
          <T x={85} y={608} w={210} s={15} wt={700} lh={21}>{next.customer_name}</T>
          <T x={85} y={629} w={215} s={12} lh={16.8} c={C.muted} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{next.drop_address}</T>
          <T x={300} y={609} w={75} s={17} wt={700} lh={23.8} c={C.accent} align="right">{inr(next.earning_paise)}</T>
          <Box x={37} y={658} w={338} h={1} bg={C.tint5} />
          <T x={37} y={668} w={338} s={13} wt={500} lh={18.2} c={C.muted}>
            {`${next.distance_km} km${next.eta_minutes ? ` · ${next.eta_minutes} min` : ''} · ${next.crate_count} crates${queued > 0 ? ` · ${queued} more queued` : ''}`}
          </T>
        </>
      ) : (
        <>
          <T x={37} y={574} s={16} wt={700} lh={22.4}>Your day so far</T>
          <Pill x={265} y={572} w={110} label={online ? 'Online' : 'Offline'} {...(online ? pill.ok : pill.warn)} style={{ justifyContent: 'center' }} />
          <Tile x={37} y={609} icon={Wallet} />
          <T x={85} y={608} s={15} wt={700} lh={21}>{`${today.data?.deliveries ?? 0} ${today.data?.deliveries === 1 ? 'delivery' : 'deliveries'} today`}</T>
          <T x={85} y={629} s={12} lh={16.8} c={C.muted}>Earnings are credited the moment you hand over</T>
          <T x={260} y={609} w={115} s={17} wt={700} lh={23.8} c={C.accent} align="right">{inr(today.data?.net_paise ?? 0)}</T>
          <Box x={37} y={658} w={338} h={1} bg={C.tint5} />
          <T x={37} y={668} s={13} wt={500} lh={18.2} c={C.green} onClick={() => nav(P('1:1816'))}>View earnings →</T>
        </>
      )}

      <Box x={20} y={724} w={372} h={70} r={22} bg="#eef5db" />
      <T x={37} y={739} s={14} wt={700} lh={22.4}>{`Today: ${inr(today.data?.net_paise ?? 0)} earned`}</T>
      <T x={37} y={761} w={280} s={11} lh={18.2} c={C.muted}>{`Available to withdraw: ${inr(today.data?.availableBalancePaise ?? 0)}`}</T>
      <Box onClick={() => nav(P('1:2083'))} x={330} y={739} w={40} h={40} r={14}><Tile s={40} bg="#f7ebc0" icon={Star} /></Box>

      <BottomNav active="home" />
    </Screen>
  )
}
