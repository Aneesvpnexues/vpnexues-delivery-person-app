import { api, ApiError } from './client'
import type { DocType } from './types'

const TYPES = ['image/jpeg', 'image/png', 'application/pdf'] as const
const MAX_BYTES = 10 * 1024 * 1024

/** Open the phone's file / camera picker and resolve with the chosen file (or null if cancelled). */
export function pickFile(opts: { camera?: 'user' | 'environment'; pdf?: boolean } = {}): Promise<File | null> {
  return new Promise((resolve) => {
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = opts.pdf === false ? 'image/jpeg,image/png' : 'image/jpeg,image/png,application/pdf'
    if (opts.camera) input.setAttribute('capture', opts.camera)
    input.onchange = () => resolve(input.files?.[0] ?? null)
    input.addEventListener('cancel', () => resolve(null))
    input.click()
  })
}

/** Upload one file straight to storage via a presigned URL. Returns the storage key. */
export async function uploadFile(type: DocType, file: File, side: 'front' | 'back' | 'single' = 'single'): Promise<string> {
  const contentType = (file.type === 'image/jpg' ? 'image/jpeg' : file.type) as (typeof TYPES)[number]
  if (!TYPES.includes(contentType)) throw new ApiError(400, 'BAD_FILE', 'Use a JPG, PNG or PDF file')
  if (file.size > MAX_BYTES) throw new ApiError(400, 'FILE_TOO_BIG', 'That file is over 10 MB. Take a smaller photo and try again.')
  const u = await api<{ url: string; headers: Record<string, string>; key: string }>(`/v1/documents/${type}/upload-url`, { body: { contentType, side } })
  let res: Response
  try {
    res = await fetch(u.url, { method: 'PUT', headers: u.headers, body: file })
  } catch {
    throw new ApiError(0, 'NETWORK', 'Upload failed. Check your connection and try again.')
  }
  if (!res.ok) throw new ApiError(res.status, 'UPLOAD_FAILED', 'Upload failed. Please try again.')
  return u.key
}

/** Submit uploaded file key(s) for review. */
export function submitDocument(type: DocType, s3Keys: string[], extra: { number?: string; validUntil?: string; consent?: boolean } = {}) {
  return api(`/v1/documents/${type}/submit`, { body: { s3Keys, ...extra } })
}

/** Pick → upload → submit in one go, for documents that need no extra details. */
export async function quickUpload(type: DocType, opts: { camera?: 'user' | 'environment' } = {}) {
  const file = await pickFile({ camera: opts.camera, pdf: type !== 'selfie' })
  if (!file) return false
  const key = await uploadFile(type, file)
  await submitDocument(type, [key])
  return true
}

export const DOC_LABEL: Record<DocType, string> = {
  aadhaar: 'Aadhaar', pan: 'PAN card', driving_licence: 'Driving licence', vehicle_rc: 'Vehicle RC',
  vehicle_insurance: 'Insurance', pucc: 'Pollution (PUC)', police_verification: 'Police verification', selfie: 'Live selfie',
}
