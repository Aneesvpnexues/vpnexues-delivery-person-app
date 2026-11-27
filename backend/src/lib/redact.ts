/** Redact connection strings and common secret assignments before logging errors. */
export function redactConfigValues(message: string): string {
  return message
    .replace(/(postgres(?:ql)?:\/\/)[^\s'"]+/gi, '$1<redacted>')
    .replace(/\b(password|pwd|secret|key|token)\s*=\s*[^\s,;&]+/gi, '$1=<redacted>')
}
