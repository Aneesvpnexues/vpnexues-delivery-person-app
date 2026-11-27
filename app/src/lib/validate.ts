/**
 * Shared form validators. Each returns an error message, or '' when the value is fine,
 * so screens can show it inline and block the next step.
 */

export const digits = (s: string) => s.replace(/\D/g, '')

/** Indian mobile: 10 digits starting with 6-9 (a leading 0 / +91 / 91 is ignored). */
export function mobileError(raw: string): string {
  let d = digits(raw)
  if (!d) return 'Enter your mobile number'
  if (d.length === 12 && d.startsWith('91')) d = d.slice(2)
  if (d.length === 11 && d.startsWith('0')) d = d.slice(1)
  if (d.length !== 10) return 'Mobile number must be 10 digits'
  if (!/^[6-9]/.test(d)) return 'Mobile number must start with 6, 7, 8 or 9'
  if (/^(\d)\1{9}$/.test(d)) return 'Enter a real mobile number'
  return ''
}

export function nameError(raw: string, what = 'your full name'): string {
  const v = raw.trim().replace(/\s+/g, ' ')
  if (!v) return `Enter ${what}`
  if (v.length < 3) return 'Name is too short'
  if (v.length > 60) return 'Name is too long'
  if (!/^[A-Za-z][A-Za-z .'-]*$/.test(v)) return 'Use letters only (no numbers or symbols)'
  return ''
}

export function emailError(raw: string, required = false): string {
  const v = raw.trim()
  if (!v) return required ? 'Enter your email address' : ''
  return /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(v) ? '' : 'Enter a valid email address'
}

export function referralError(raw: string): string {
  const v = raw.trim()
  if (!v) return ''
  return /^[A-Za-z0-9\-–]{4,20}$/.test(v) ? '' : 'Referral code looks wrong'
}

export function aadhaarError(raw: string): string {
  const d = digits(raw)
  if (d.length !== 12) return 'Aadhaar number must be 12 digits'
  if (/^[01]/.test(d)) return 'Aadhaar number cannot start with 0 or 1'
  return ''
}

export const panError = (v: string) => (/^[A-Z]{5}\d{4}[A-Z]$/.test(v) ? '' : 'PAN must look like ABCDE1234F')

export const ifscError = (v: string) => (/^[A-Z]{4}0[A-Z0-9]{6}$/.test(v) ? '' : 'Enter a valid 11-character IFSC')

export function accountError(v: string): string {
  if (v.length < 9 || v.length > 18) return 'Account number must be 9–18 digits'
  if (/^(\d)\1+$/.test(v)) return 'Enter a real account number'
  return ''
}

export const upiError = (v: string) => (/^[\w.-]{2,}@[a-z]{2,}$/i.test(v.trim()) ? '' : 'Enter a valid UPI ID, like name@okhdfcbank')

/** Indian registration plate, e.g. TN02AB4821 or TN 02 AB 4821 (BH-series also accepted). */
export function vehicleRegError(raw: string): string {
  const v = raw.toUpperCase().replace(/[\s-]/g, '')
  if (!v) return 'Enter your vehicle registration number'
  if (!/^([A-Z]{2}\d{1,2}[A-Z]{0,3}\d{4}|\d{2}BH\d{4}[A-Z]{1,2})$/.test(v)) return 'Registration looks wrong. Example: TN 02 AB 4821'
  return ''
}

export function yearError(raw: string): string {
  if (!raw) return ''
  const y = Number(raw)
  const max = new Date().getFullYear() + 1
  return y >= 1990 && y <= max ? '' : `Enter a year between 1990 and ${max}`
}

/** `iso` is yyyy-mm-dd. Partners must be at least 18. */
export function dobError(iso: string): string {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return 'Enter a valid date of birth'
  const now = new Date()
  let age = now.getFullYear() - d.getFullYear()
  if (now < new Date(now.getFullYear(), d.getMonth(), d.getDate())) age -= 1
  if (age < 18) return 'You must be at least 18 years old'
  if (age > 80) return 'Enter a valid date of birth'
  return ''
}

export function addressError(raw: string): string {
  const v = raw.trim()
  if (!v) return ''
  return v.length >= 10 ? '' : 'Address is too short. Add house, street, area and PIN'
}
