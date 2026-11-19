/**
 * Create (or reset the password of) an ops-console staff account.
 *
 *   npm run admin:create -- --email you@company.com --name "Your Name" --role owner
 *
 * The password is typed at a hidden prompt (or read from ADMIN_PASSWORD for automation) and is never
 * written to the terminal history, logs or the repo. Uses DATABASE_URL from .env.
 */
import bcrypt from 'bcryptjs'
import pg from 'pg'
import { createInterface } from 'node:readline'
import { dbSslOptions } from '../src/lib/dbSsl.js'

// Flags may arrive three ways: `--email x` in argv; as npm_config_* env vars (npm in PowerShell
// swallows the flags); or as bare positional values `email name role`.
const positional = process.argv.slice(2).filter((a, i, all) => !a.startsWith('--') && !all[i - 1]?.startsWith('--'))
const arg = (name: string, pos: number) => {
  const i = process.argv.indexOf(`--${name}`)
  if (i > 0) return process.argv[i + 1]
  return process.env[`npm_config_${name}`] || positional[pos]
}

function hiddenPrompt(question: string): Promise<string> {
  return new Promise((resolve) => {
    const rl = createInterface({ input: process.stdin, output: process.stdout, terminal: true })
    const out = rl as unknown as { _writeToOutput: (s: string) => void; output: NodeJS.WriteStream }
    let muted = false
    out._writeToOutput = (s: string) => { if (!muted || s.includes('\n')) out.output.write(muted ? '\n' : s) }
    rl.question(question, (answer) => { rl.close(); resolve(answer) })
    muted = true
  })
}

async function main() {
  let email = arg('email', 0)
  let name = arg('name', 1)
  let role = arg('role', 2) ?? 'ops'
  // PowerShell + npm can also drop the quotes, splitting "VPN Admin" into two words.
  // Fall back to: the value with "@" is the email, a trailing owner/ops/support is the role, the rest is the name.
  if (!['owner', 'ops', 'support'].includes(role) || !email?.includes('@')) {
    const words = [...positional]
    const at = words.findIndex((w) => w.includes('@'))
    if (at >= 0) email = words.splice(at, 1)[0]
    if (['owner', 'ops', 'support'].includes(words[words.length - 1] ?? '')) role = words.pop()!
    if (words.length) name = words.join(' ')
  }
  if (!email || !name || !['owner', 'ops', 'support'].includes(role)) {
    console.error('Usage: npm run admin:create -- --email you@company.com --name "Your Name" --role owner|ops|support')
    process.exit(1)
  }
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set (put it in .env)')

  let password = process.env.ADMIN_PASSWORD
  if (!password) {
    password = await hiddenPrompt('Password (10+ chars, upper, lower, number): ')
    const again = await hiddenPrompt('Repeat password: ')
    if (password !== again) throw new Error('Passwords do not match')
  }
  if (password.length < 10 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/\d/.test(password)) {
    throw new Error('Password needs 10+ characters with upper- and lower-case letters and a number')
  }

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: dbSslOptions() })
  await client.connect()
  try {
    const { rows } = await client.query(
      `INSERT INTO admin_users (email, full_name, role, password_hash) VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name, role = EXCLUDED.role, password_hash = EXCLUDED.password_hash, is_active = true
       RETURNING (xmax = 0) AS created`,
      [email, name, role, await bcrypt.hash(password, 12)],
    )
    console.log(rows[0].created ? `Created ${role} account for ${email}` : `Updated ${email} (role ${role}, new password, re-activated)`)
  } finally {
    await client.end()
  }
}

main().catch((e) => { console.error(e.message); process.exit(1) })
