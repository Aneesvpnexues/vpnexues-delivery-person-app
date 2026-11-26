import { randomUUID } from 'node:crypto'
import fp from 'fastify-plugin'
import jwt from '@fastify/jwt'
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify'
import { config } from '../config.js'
import { one } from '../db.js'
import { AppError } from './errors.js'
import {
  ACCESS_TOKEN_AUDIENCE,
  ACCESS_TOKEN_ISSUER,
  buildAccessClaims,
  validateAccessClaims,
} from './sessionSecurity.js'

export type AdminRole = 'owner' | 'ops' | 'support'
/** Partner tokens are typ 'access'; ops-console tokens are typ 'admin'. Neither works on the other's routes. */
export type AccessClaims = {
  sub: string
  typ: 'access' | 'admin'
  role?: AdminRole
  jti?: string
  iss?: string
  aud?: string | string[]
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: AccessClaims
    user: AccessClaims
  }
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>
    authenticateAdmin: (req: FastifyRequest, reply: FastifyReply) => Promise<void>
  }
  interface FastifyRequest {
    admin?: { id: string; email: string; full_name: string; role: AdminRole }
  }
}

/** Registers JWT signing + `authenticate` (partners) and `authenticateAdmin` (ops console) preHandlers. */
export const authPlugin = fp(async (app) => {
  await app.register(jwt, {
    secret: config.JWT_SECRET,
    sign: {
      algorithm: 'HS256',
      expiresIn: config.ACCESS_TOKEN_TTL,
      iss: ACCESS_TOKEN_ISSUER,
      aud: ACCESS_TOKEN_AUDIENCE,
    },
    verify: { algorithms: ['HS256'] },
  })
  app.decorate('authenticate', async (req: FastifyRequest) => {
    try {
      await req.jwtVerify()
    } catch {
      throw new AppError(401, 'UNAUTHENTICATED', 'Sign in again to continue')
    }
    const claims = validateAccessClaims(req.user)
    if (!claims.ok) throw new AppError(401, 'UNAUTHENTICATED', claims.reason)
    if (req.user.typ !== 'access') throw new AppError(401, 'UNAUTHENTICATED', 'Wrong token type')
  })
  app.decorate('authenticateAdmin', async (req: FastifyRequest) => {
    try {
      await req.jwtVerify()
    } catch {
      throw new AppError(401, 'UNAUTHENTICATED', 'Sign in again to continue')
    }
    const claims = validateAccessClaims(req.user)
    if (!claims.ok) throw new AppError(401, 'UNAUTHENTICATED', claims.reason)
    if (req.user.typ !== 'admin') throw new AppError(401, 'UNAUTHENTICATED', 'Wrong token type')
    // Checked on every request so deactivating a staff account takes effect immediately.
    const a = await one(`SELECT id, email, full_name, role FROM admin_users WHERE id = $1 AND is_active`, [req.user.sub])
    if (!a) throw new AppError(401, 'UNAUTHENTICATED', 'This staff account is no longer active')
    req.admin = a
  })
})

/** Sign a partner access token with a unique jti; iss/aud/exp come from the plugin defaults. */
export function signPartnerAccessToken(app: FastifyInstance, partnerId: string) {
  return app.jwt.sign(buildAccessClaims(partnerId, randomUUID()))
}

export const partnerId = (req: FastifyRequest) => req.user.sub

/** preHandler: allow only the listed staff roles (owner is always allowed). */
export const requireRole = (...roles: AdminRole[]) => async (req: FastifyRequest) => {
  if (!req.admin || (req.admin.role !== 'owner' && !roles.includes(req.admin.role))) {
    throw new AppError(403, 'FORBIDDEN', 'Your role cannot do this')
  }
}
