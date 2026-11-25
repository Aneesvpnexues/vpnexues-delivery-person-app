-- V5 · Where partners get paid: bank accounts and UPI IDs

CREATE TABLE payout_methods (
  id                     uuid                PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id             uuid                NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  type                   payout_method_type  NOT NULL,
  account_holder_name    text,
  account_number_enc     text,
  account_last4          text,
  ifsc                   text CHECK (ifsc ~ '^[A-Z]{4}0[A-Z0-9]{6}$'),
  bank_name              text,
  branch                 text,
  account_type           text CHECK (account_type IN ('savings', 'current')),
  upi_vpa                text,
  is_primary             boolean             NOT NULL DEFAULT false,
  is_backup              boolean             NOT NULL DEFAULT false,
  verification           verification_status NOT NULL DEFAULT 'pending',
  verified_name          text,
  deleted_at             timestamptz,
  created_at             timestamptz         NOT NULL DEFAULT now(),
  updated_at             timestamptz         NOT NULL DEFAULT now(),
  CHECK (
    (type = 'bank_account' AND account_number_enc IS NOT NULL AND ifsc IS NOT NULL AND account_holder_name IS NOT NULL)
    OR (type = 'upi' AND upi_vpa IS NOT NULL)
  )
);
CREATE UNIQUE INDEX payout_methods_one_primary_idx ON payout_methods (partner_id) WHERE is_primary AND deleted_at IS NULL;
CREATE INDEX payout_methods_partner_idx ON payout_methods (partner_id) WHERE deleted_at IS NULL;
CREATE TRIGGER payout_methods_updated_at BEFORE UPDATE ON payout_methods FOR EACH ROW EXECUTE FUNCTION set_updated_at();
