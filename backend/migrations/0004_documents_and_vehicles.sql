-- 0004 · KYC documents (files live in S3) and the partner's vehicle

CREATE TABLE partner_documents (
  id               uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id       uuid            NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  type             document_type   NOT NULL,
  status           document_status NOT NULL DEFAULT 'pending_upload',
  number_masked    text,                         -- e.g. "XXXX XXXX 4821" — never the full Aadhaar
  s3_keys          text[]          NOT NULL DEFAULT '{}',  -- front/back images in the documents bucket
  source           text            NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'digilocker')),
  valid_until      date,
  rejection_reason text,
  submitted_at     timestamptz,
  reviewed_at      timestamptz,
  reviewed_by      text,
  created_at       timestamptz     NOT NULL DEFAULT now(),
  updated_at       timestamptz     NOT NULL DEFAULT now(),
  UNIQUE (partner_id, type)                      -- latest version per type; history in document_events
);
CREATE INDEX partner_documents_review_idx ON partner_documents (status, submitted_at) WHERE status = 'in_review';
CREATE INDEX partner_documents_expiry_idx ON partner_documents (valid_until) WHERE status = 'verified';
CREATE TRIGGER partner_documents_updated_at BEFORE UPDATE ON partner_documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE document_events (
  id           bigserial       PRIMARY KEY,
  document_id  uuid            NOT NULL REFERENCES partner_documents(id) ON DELETE CASCADE,
  status       document_status NOT NULL,
  note         text,
  created_at   timestamptz     NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
  id                  uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id          uuid         NOT NULL UNIQUE REFERENCES partners(id) ON DELETE CASCADE,
  type                vehicle_type NOT NULL,
  registration_number text         NOT NULL,     -- "TN 02 AB 4821"
  make_model          text,                      -- "TVS Raider 125"
  year                smallint     CHECK (year BETWEEN 1990 AND 2100),
  colour              text,
  fuel                text         CHECK (fuel IN ('petrol', 'electric', 'cng', 'none')),
  created_at          timestamptz  NOT NULL DEFAULT now(),
  updated_at          timestamptz  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX vehicles_registration_idx ON vehicles (upper(replace(registration_number, ' ', '')));
CREATE TRIGGER vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
