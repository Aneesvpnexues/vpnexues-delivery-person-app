export type TestSession = {
  id: string
  partner_id: string
  hash: string
  revoked: boolean
  expired: boolean
  user_agent: string | null
  ip: string | null
}

export type TestPartner = {
  id: string
  phone: string
  password_hash: string | null
  status: string
}

export declare const state: {
  partner: TestPartner
  sessions: Map<string, TestSession>
}

export declare function __reset(): Promise<void>
export declare function activeSessions(): TestSession[]

export declare const pool: null
export declare function dbHealthy(): Promise<boolean>

export declare function query(
  sql: string,
  params?: unknown[],
  db?: unknown,
): Promise<unknown[]>

export declare function one<T = unknown>(
  sql: string,
  params?: unknown[],
  db?: unknown,
): Promise<T | undefined>

export declare function tx<T>(
  fn: (db: { query: typeof query }) => Promise<T> | T,
): Promise<T>
