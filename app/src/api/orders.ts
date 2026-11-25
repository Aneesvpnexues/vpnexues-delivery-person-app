import { P } from '../components/kit'
import { toast } from '../components/toast'
import { api, showError } from './client'
import type { OrderStatus } from './types'

/** Screen for an order, by its current step. */
export function orderScreen(id: string, status: OrderStatus) {
  const frame = status === 'picked_up' ? '1:1359' : status === 'arrived' ? '1:1488' : '1:1223'
  return `${P(frame)}?id=${id}`
}

/** Trial only: ask the server for a demo order (also activates the partner). Returns the new order id. */
export async function createDemoOrder(): Promise<string | null> {
  try {
    const r = await api<{ id: string; order_code: string }>('/v1/trial/demo-order', { method: 'POST' })
    toast(`Demo order #${r.order_code} assigned to you`)
    return r.id
  } catch (e) {
    showError(e)
    return null
  }
}

export const statusLabel: Record<OrderStatus, string> = {
  created: 'Created', assigned: 'New order', accepted: 'Accepted', at_pickup: 'At the hub',
  picked_up: 'Out for delivery', arrived: 'At doorstep', delivered: 'Delivered', cancelled: 'Cancelled',
}
