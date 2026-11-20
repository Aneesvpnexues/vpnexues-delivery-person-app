-- V3 · Delivery partners, OTP codes and login sessions

CREATE TABLE partners (
  id                   uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_code         text           NOT NULL UNIQUE,
  full_name            text           NOT NULL,
  phone                text           NOT NULL UNIQUE,
  phone_verified_at    timestamptz,
  email                text           UNIQUE,
  password_hash        text,
  city_id              smallint       NOT NULL REFERENCES cities(id),
  hub_id               uuid           REFERENCES hubs(id),
  vehicle_type         vehicle_type   NOT NULL,
  delivery_radius_km   smallint       NOT NULL DEFAULT 5,
  status               partner_status NOT NULL DEFAULT 'onboarding',
  kyc_status           kyc_status     NOT NULL DEFAULT 'not_started',
  is_online            boolean        NOT NULL DEFAULT false,
  last_online_at       timestamptz,
  language             app_language   NOT NULL DEFAULT 'en',
  date_of_birth        date,
  blood_group          text           CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  address              text,
  photo_s3_key         text,
  referral_code        text           NOT NULL UNIQUE,
  referred_by_id       uuid           REFERENCES partners(id),
  rating               numeric(2,1)   NOT NULL DEFAULT 5.0 CHECK (rating BETWEEN 0 AND 5),
  created_at           timestamptz    NOT NULL DEFAULT now(),
  updated_at           timestamptz    NOT NULL DEFAULT now()
);
CREATE INDEX partners_hub_online_idx ON partners (hub_id) WHERE is_online AND status = 'active';
CREATE UNIQUE INDEX partners_email_lower_idx ON partners (lower(email));
CREATE UNIQUE INDEX partners_referral_upper_idx ON partners (upper(referral_code));
CREATE TRIGGER partners_updated_at BEFORE UPDATE ON partners FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE SEQUENCE partner_code_seq START 10001;

ALTER TABLE hub_change_requests
  ADD CONSTRAINT hub_change_requests_partner_fk FOREIGN KEY (partner_id) REFERENCES partners(id) ON DELETE CASCADE;

CREATE TABLE partner_settings (
  partner_id          uuid        PRIMARY KEY REFERENCES partners(id) ON DELETE CASCADE,
  auto_accept_nearby  boolean     NOT NULL DEFAULT false,
  navigation_app      text        NOT NULL DEFAULT 'google_maps',
  new_order_sound     boolean     NOT NULL DEFAULT true,
  payout_alerts       boolean     NOT NULL DEFAULT true,
  offers_campaigns    boolean     NOT NULL DEFAULT false,
  dark_mode_at_night  boolean     NOT NULL DEFAULT false,
  data_saver          boolean     NOT NULL DEFAULT true,
  voice_navigation    boolean     NOT NULL DEFAULT true,
  fingerprint_unlock  boolean     NOT NULL DEFAULT true,
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER partner_settings_updated_at BEFORE UPDATE ON partner_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE otp_codes (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         text        NOT NULL,
  purpose       otp_purpose NOT NULL,
  code_hash     text        NOT NULL,
  payload       jsonb,
  attempts      smallint    NOT NULL DEFAULT 0,
  expires_at    timestamptz NOT NULL,
  consumed_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX otp_codes_lookup_idx ON otp_codes (phone, purpose, created_at DESC) WHERE consumed_at IS NULL;

CREATE TABLE sessions (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id          uuid        NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  refresh_token_hash  text        NOT NULL UNIQUE,
  device_label        text,
  user_agent          text,
  ip                  inet,
  expires_at          timestamptz NOT NULL,
  revoked_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  last_used_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sessions_partner_idx ON sessions (partner_id) WHERE revoked_at IS NULL;

CREATE TABLE device_tokens (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id  uuid        NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  platform    text        NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  token       text        NOT NULL UNIQUE,
  created_at  timestamptz NOT NULL DEFAULT now()
);
