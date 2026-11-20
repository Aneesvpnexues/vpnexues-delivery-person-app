-- V2 · Service geography: cities and delivery hubs (zones)

CREATE TABLE cities (
  id          smallserial PRIMARY KEY,
  name        text        NOT NULL UNIQUE,
  state       text        NOT NULL,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE hubs (
  id                     uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id                smallint    NOT NULL REFERENCES cities(id),
  name                   text        NOT NULL,
  address                text        NOT NULL,
  lat                    double precision NOT NULL,
  lng                    double precision NOT NULL,
  allowed_radii_km       smallint[]  NOT NULL DEFAULT '{3,5,7}',
  recommended_radius_km  smallint    NOT NULL DEFAULT 5,
  areas_by_radius        jsonb       NOT NULL DEFAULT '{}',
  is_active              boolean     NOT NULL DEFAULT true,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (city_id, name)
);
CREATE INDEX hubs_city_idx ON hubs (city_id) WHERE is_active;
CREATE TRIGGER hubs_updated_at BEFORE UPDATE ON hubs FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE hub_change_requests (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id    uuid        NOT NULL,
  to_city_id    smallint    NOT NULL REFERENCES cities(id),
  to_hub_id     uuid        REFERENCES hubs(id),
  status        text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  resolved_at   timestamptz
);
