-- 0011 · Ops console: staff accounts and an audit trail of every change they make.
--
-- Staff sign in with email + password (separate from partner phone/OTP auth) and get a short-lived
-- JWT with typ = 'admin'. Partner routes reject that token type and admin routes reject partner tokens.
-- Create the first account with:  npm run admin:create -- --email you@company.com --name "Your Name" --role owner

CREATE TABLE admin_users (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  email          citext      NOT NULL UNIQUE,
  full_name      text        NOT NULL,
  password_hash  text        NOT NULL,                 -- bcrypt
  -- owner: everything · ops: partners, KYC, orders, payouts · support: tickets, SOS, read-only elsewhere
  role           text        NOT NULL DEFAULT 'ops' CHECK (role IN ('owner', 'ops', 'support')),
  is_active      boolean     NOT NULL DEFAULT true,
  last_login_at  timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Who did what, when. Append-only like the wallet ledger.
CREATE TABLE admin_audit_log (
  id          bigserial   PRIMARY KEY,
  admin_id    uuid        REFERENCES admin_users(id),
  action      text        NOT NULL,                    -- 'document.verified', 'order.assigned', 'payout.paid', ...
  entity      text        NOT NULL,                    -- 'partner' | 'document' | 'order' | 'payout' | 'ticket' | 'sos' | 'zone_request'
  entity_id   text        NOT NULL,
  details     jsonb       NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX admin_audit_log_entity_idx ON admin_audit_log (entity, entity_id, created_at DESC);
CREATE INDEX admin_audit_log_recent_idx ON admin_audit_log (created_at DESC);

CREATE OR REPLACE FUNCTION admin_audit_log_immutable() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'admin_audit_log is append-only';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER admin_audit_log_no_update BEFORE UPDATE OR DELETE ON admin_audit_log FOR EACH ROW EXECUTE FUNCTION admin_audit_log_immutable();

-- Queues the console reads constantly.
CREATE INDEX support_tickets_status_idx ON support_tickets (status, updated_at DESC);
CREATE INDEX hub_change_requests_pending_idx ON hub_change_requests (created_at) WHERE status = 'pending';
CREATE INDEX orders_created_idx ON orders (created_at DESC);

-- Same lock-down as 0010 for the new tables (see that file for why).
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON admin_users, admin_audit_log FROM anon, authenticated;
    REVOKE ALL ON SEQUENCE admin_audit_log_id_seq FROM anon, authenticated;
  END IF;
END $$;
