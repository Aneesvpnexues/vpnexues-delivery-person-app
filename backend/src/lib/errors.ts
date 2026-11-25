import type { FastifyInstance } from 'fastify'
import { ZodError, type ZodType } from 'zod'

/** Error with an HTTP status and a stable machine-readable code for the app to switch on. */
export class AppError extends Error {
  constructor(public status: number, public code: string, message: string, public details?: unknown) {
    super(message)
  }
}

export const notFound = (what: string) => new AppError(404, 'NOT_FOUND', `${what} not found`)
export const conflict = (code: string, msg: string) => new AppError(409, code, msg)
export const badRequest = (code: string, msg: string) => new AppError(400, code, msg)

/** Validate request input with zod; throws a 400 with field details on failure. */
export function parse<T>(schema: ZodType<T>, input: unknown): T {
  const r = schema.safeParse(input ?? {})
  if (!r.success) throw r.error
  return r.data
}

export function registerErrorHandler(app: FastifyInstance) {
  app.setErrorHandler((err: any, req, reply) => {
    if (err instanceof AppError) {
      return reply.status(err.status).send({ error: { code: err.code, message: err.message, details: err.details } })
    }
    if (err instanceof ZodError) {
      return reply.status(400).send({
        error: { code: 'VALIDATION_FAILED', message: 'Some fields are invalid', details: err.issues.map((i) => ({ field: i.path.join('.'), message: i.message })) },
      })
    }
    if (err.statusCode && err.statusCode < 500) {
      return reply.status(err.statusCode).send({ error: { code: err.code ?? 'BAD_REQUEST', message: err.message } })
    }
    // Postgres unique violation → 409
    if (err.code === '23505') {
      return reply.status(409).send({ error: { code: 'ALREADY_EXISTS', message: 'A record with these details already exists' } })
    }
    req.log.error({ err }, 'unhandled error')
    return reply.status(500).send({ error: { code: 'INTERNAL', message: 'Something went wrong' } })
  })

  app.setNotFoundHandler((req, reply) => {
    reply.status(404).send({ error: { code: 'ROUTE_NOT_FOUND', message: `${req.method} ${req.url} does not exist` } })
  })
}
