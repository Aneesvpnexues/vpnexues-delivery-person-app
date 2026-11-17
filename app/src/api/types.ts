/** Shapes returned by the backend (see API documentation). Money is integer paise. */
export type OrderStatus = 'created' | 'assigned' | 'accepted' | 'at_pickup' | 'picked_up' | 'arrived' | 'delivered' | 'cancelled'

export type OrderListItem = {
  id: string; order_code: string; status: OrderStatus; customer_name: string; drop_address: string
  distance_km: number; eta_minutes: number | null; scheduled_for: string | null; earning_paise: number
  created_at: string; delivered_at: string | null; hub_name: string; crate_count: number
}

export type Crate = { id: string; position: number; label: string; weightGrams: number; scanned: boolean; trialQr?: string | null }

export type OrderDetail = {
  id: string; order_code: string; status: OrderStatus; customer_name: string; customer_phone_masked: string
  drop_address: string; drop_lat: number; drop_lng: number; drop_instructions: string | null; leave_at_door: boolean
  distance_km: number; eta_minutes: number | null; scheduled_for: string | null
  pay_base_paise: number; pay_distance_paise: number; tip_paise: number
  pickup: { id: string; name: string; address: string; lat: number; lng: number }
  crates: Crate[]; timeline: { status: OrderStatus; at: string }[]
}

export type EarningsSummary = {
  range: string; net_paise: number; base_paise: number; distance_paise: number; extras_paise: number; deliveries: number
  byHour: { hour: number; paise: number }[]; availableBalancePaise: number; nextWeeklyPayoutAt: string
}

export type PayoutMethod = {
  id: string; type: 'bank_account' | 'upi'; account_holder_name: string | null; account_last4: string | null; ifsc: string | null
  bank_name: string | null; branch: string | null; account_type: 'savings' | 'current' | null; upi_vpa: string | null
  is_primary: boolean; is_backup: boolean; verification: 'pending' | 'verified' | 'failed'; verified_name: string | null; created_at: string
}

export type DocType = 'aadhaar' | 'pan' | 'driving_licence' | 'vehicle_rc' | 'vehicle_insurance' | 'pucc' | 'police_verification' | 'selfie'
export type PartnerDocument = {
  id: string; type: DocType; status: 'pending_upload' | 'in_review' | 'verified' | 'rejected' | 'expired'
  number_masked: string | null; source: string; valid_until: string | null; rejection_reason: string | null
  submitted_at: string | null; reviewed_at: string | null; expiring_soon: boolean
}
export type DocumentsResponse = { documents: PartnerDocument[]; verifiedCount: number; requiredCount: number; missing: DocType[] }

export type Vehicle = { type: string; registration_number: string; make_model: string | null; year: number | null; colour: string | null; fuel: string | null }

export type Notification = { id: string; category: 'order' | 'payout' | 'account' | 'promo' | 'safety'; title: string; body: string; action_url: string | null; read_at: string | null; created_at: string }

export const ACTIVE: OrderStatus[] = ['assigned', 'accepted', 'at_pickup', 'picked_up', 'arrived']
