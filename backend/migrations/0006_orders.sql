-- 0006 · Orders, the crates in each order, and the order timeline

CREATE SEQUENCE order_number_seq START 2001;

CREATE TABLE orders (
  id                    uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  order_code            text         NOT NULL UNIQUE,      -- "VPN-2048"
  hub_id                uuid         NOT NULL REFERENCES hubs(id),
  partner_id            uuid         REFERENCES partners(id),
  status                order_status NOT NULL DEFAULT 'created',
  -- customer & drop
  customer_name         text         NOT NULL,
  customer_phone        text         NOT NULL,             -- masked/proxied to the partner by the API
  drop_address          text         NOT NULL,
  drop_lat              double precision NOT NULL,
  drop_lng              double precision NOT NULL,
  drop_instructions     text,
  leave_at_door         boolean      NOT NULL DEFAULT false,
  -- delivery hand-over code (customer reads it out); hash only = hex(sha256("<order id>:<4-digit code>"))
  delivery_code_hash    text         NOT NULL,
  delivery_attempts     smallint     NOT NULL DEFAULT 0,
  -- trip
  distance_km           numeric(5,2) NOT NULL,
  eta_minutes           smallint,
  scheduled_for         timestamptz,                       -- null = ASAP, otherwise "Upcoming"
  -- partner earnings for this order (paise)
  pay_base_paise        integer      NOT NULL DEFAULT 0 CHECK (pay_base_paise >= 0),
  pay_distance_paise    integer      NOT NULL DEFAULT 0 CHECK (pay_distance_paise >= 0),
  tip_paise             integer      NOT NULL DEFAULT 0 CHECK (tip_paise >= 0),
  -- feedback after delivery
  drop_off_ease         text         CHECK (drop_off_ease IN ('smooth', 'hard_to_find', 'long_wait')),
  cancel_reason         text,
  assigned_at           timestamptz,
  accepted_at           timestamptz,
  picked_up_at          timestamptz,
  arrived_at            timestamptz,
  delivered_at          timestamptz,
  cancelled_at          timestamptz,
  created_at            timestamptz  NOT NULL DEFAULT now(),
  updated_at            timestamptz  NOT NULL DEFAULT now()
);
CREATE INDEX orders_partner_active_idx ON orders (partner_id, status) WHERE status NOT IN ('delivered', 'cancelled');
CREATE INDEX orders_partner_delivered_idx ON orders (partner_id, delivered_at DESC) WHERE status = 'delivered';
CREATE INDEX orders_hub_open_idx ON orders (hub_id, created_at) WHERE status IN ('created', 'assigned');
CREATE TRIGGER orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Each sealed crate has a QR label scanned at pickup.
CREATE TABLE order_crates (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     uuid        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  position     smallint    NOT NULL,                 -- "Crate 1 of 2"
  label        text        NOT NULL,                 -- "Vegetables"
  weight_grams integer     NOT NULL CHECK (weight_grams > 0),
  qr_code      text        NOT NULL UNIQUE,
  scanned_at   timestamptz,
  damaged      boolean     NOT NULL DEFAULT false,
  UNIQUE (order_id, position)
);

-- Append-only status history (also the source for the "Order placed / Packed / Ready" timeline).
CREATE TABLE order_events (
  id          bigserial    PRIMARY KEY,
  order_id    uuid         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status      order_status NOT NULL,
  actor       text         NOT NULL DEFAULT 'system',   -- 'system' | 'partner:<id>' | 'ops:<email>'
  lat         double precision,
  lng         double precision,
  note        text,
  created_at  timestamptz  NOT NULL DEFAULT now()
);
CREATE INDEX order_events_order_idx ON order_events (order_id, created_at);
