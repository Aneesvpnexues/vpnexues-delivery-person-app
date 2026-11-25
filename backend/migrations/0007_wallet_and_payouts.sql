-- 0007 · Earnings ledger and payouts
-- The ledger is append-only: balance = SUM(amount_paise). Never UPDATE or DELETE rows; correct with an 'adjustment'.

CREATE TABLE payouts (
  id                uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id        uuid          NOT NULL REFERENCES partners(id),
  payout_method_id  uuid          NOT NULL REFERENCES payout_methods(id),
  kind              payout_kind   NOT NULL,
  amount_paise      integer       NOT NULL CHECK (amount_paise > 0),
  fee_paise         integer       NOT NULL DEFAULT 0 CHECK (fee_paise >= 0),
  status            payout_status NOT NULL DEFAULT 'requested',
  utr               text,                          -- bank reference once paid
  failure_reason    text,
  idempotency_key   text          UNIQUE,          -- client-supplied, prevents double transfers
  requested_at      timestamptz   NOT NULL DEFAULT now(),
  processed_at      timestamptz,
  updated_at        timestamptz   NOT NULL DEFAULT now()
);
CREATE INDEX payouts_partner_idx ON payouts (partner_id, requested_at DESC);
CREATE INDEX payouts_pending_idx ON payouts (status) WHERE status IN ('requested', 'processing');
CREATE TRIGGER payouts_updated_at BEFORE UPDATE ON payouts FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE wallet_ledger (
  id            bigserial         PRIMARY KEY,
  partner_id    uuid              NOT NULL REFERENCES partners(id),
  type          ledger_entry_type NOT NULL,
  amount_paise  integer           NOT NULL CHECK (amount_paise <> 0),  -- +credit / −debit
  order_id      uuid              REFERENCES orders(id),
  payout_id     uuid              REFERENCES payouts(id),
  description   text              NOT NULL,
  created_at    timestamptz       NOT NULL DEFAULT now()
);
CREATE INDEX wallet_ledger_partner_idx ON wallet_ledger (partner_id, created_at DESC);
-- An order can be credited each earning type only once (makes delivery crediting idempotent).
CREATE UNIQUE INDEX wallet_ledger_order_type_idx ON wallet_ledger (order_id, type) WHERE order_id IS NOT NULL;

CREATE OR REPLACE FUNCTION wallet_ledger_immutable() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'wallet_ledger is append-only';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER wallet_ledger_no_update BEFORE UPDATE OR DELETE ON wallet_ledger FOR EACH ROW EXECUTE FUNCTION wallet_ledger_immutable();
