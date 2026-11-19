import raw from './nav.txt?raw'

export type Hotspot = { x: number; y: number; w: number; h: number; to: string; overlay: boolean }
export type Screen = { id: string; name: string; w: number; h: number; path: string; popup: boolean; hotspots: Hotspot[] }

/** Routes for screens that are hand-built components (or referenced by them). */
const fixed: Record<string, string> = {
  '1:2': '/', '1:152': '/signup', '1:260': '/login', '1:364': '/otp', '1:461': '/password',
  '1:583': '/documents-onboarding', '1:814': '/home', '1:3289': '/help',
}
const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')

export const screens: Record<string, Screen> = {}
for (const line of raw.split('\n')) {
  if (!line.trim()) continue
  const [id, name, size, hs = ''] = line.split('|')
  const [w, h] = size.split('x').map(Number)
  screens[id] = {
    id, name, w, h, popup: w !== 412 || h !== 915, path: fixed[id] ?? '/' + slug(name),
    hotspots: hs.split(';').filter(Boolean).map((s) => {
      const [x, y, hw, hh, d] = s.split(',')
      const overlay = d[0] === 'o'
      return { x: +x, y: +y, w: +hw, h: +hh, to: d.replace(/^[os]/, ''), overlay }
    }),
  }
}
// Links the prototype leaves out but the flow needs.
screens['1:814'].hotspots.push({ x: 136, y: 318, w: 132, h: 132, to: '1:4029', overlay: false })
screens['1:1593'].hotspots.push({ x: 20, y: 792, w: 372, h: 56, to: '1:814', overlay: false })
