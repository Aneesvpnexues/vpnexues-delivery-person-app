-- V6 · Orders, crates and the order timeline

CREATE SEQUENCE order_number_seq START 2001;

CREATE TABLE orders (
  id                    uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  order_code            text         NOT NULL UNIQUE,
  hub_id                uuid         NOT NULL REFERENCES hubs(id),
  partner_id            uuid         REFERENCES partners(id),
  status                order_status NOT NULL DEFAULT 'created',
  customer_name         text         NOT NULL,
  customer_phone        text         NOT NULL,
  drop_address          text         NOT NULL,
  drop_lat              double precision NOT NULL,
  drop_lng              double precision NOT NULL,
  drop_instructions     text,
  leave_at_door         boolean      NOT NULL DEFAULT false,
  delivery_code_hash    text         NOT NULL,
  delivery_attempts     smallint     NOT NULL DEFAULT 0,
  distance_km           numeric(5,2) NOT NULL,
  eta_minutes           smallint,
  scheduled_for         timestamptz,
  pay_base_paise        integer      NOT NULL DEFAULT 0 CHECK (pay_base_paise >= 0),
  pay_distance_paise    integer      NOT NULL DEFAULT 0 CHECK (pay_distance_paise >= 0),
  tip_paise             integer      NOT NULL DEFAULT 0 CHECK (tip_paise >= 0),
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

CREATE TABLE order_crates (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     uuid        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  position     smallint    NOT NULL,
  label        text        NOT NULL,
  weight_grams integer     NOT NULL CHECK (weight_grams > 0),
  qr_code      text        NOT NULL UNIQUE,
  scanned_at   timestamptz,
  damaged      boolean     NOT NULL DEFAULT false,
  UNIQUE (order_id, position)
);

CREATE TABLE order_events (
  id          bigserial    PRIMARY KEY,
  order_id    uuid         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status      order_status NOT NULL,
  actor       text         NOT NULL DEFAULT 'system',
  lat         double precision,
  lng         double precision,
  note        text,
  created_at  timestamptz  NOT NULL DEFAULT now()
);
CREATE INDEX order_events_order_idx ON order_events (order_id, created_at);
