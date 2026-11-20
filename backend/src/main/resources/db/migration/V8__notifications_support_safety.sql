-- V8 · Notifications, support chat, SOS / emergency contacts, app ratings

CREATE TABLE notifications (
  id          uuid                  PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id  uuid                  NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  category    notification_category NOT NULL,
  title       text                  NOT NULL,
  body        text                  NOT NULL,
  action_url  text,
  read_at     timestamptz,
  created_at  timestamptz           NOT NULL DEFAULT now()
);
CREATE INDEX notifications_partner_idx ON notifications (partner_id, created_at DESC);
CREATE INDEX notifications_unread_idx ON notifications (partner_id) WHERE read_at IS NULL;

CREATE TABLE support_tickets (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id  uuid          NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  order_id    uuid          REFERENCES orders(id),
  topic       text          NOT NULL,
  status      ticket_status NOT NULL DEFAULT 'open',
  created_at  timestamptz   NOT NULL DEFAULT now(),
  updated_at  timestamptz   NOT NULL DEFAULT now()
);
CREATE INDEX support_tickets_partner_idx ON support_tickets (partner_id, created_at DESC);
CREATE TRIGGER support_tickets_updated_at BEFORE UPDATE ON support_tickets FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE support_messages (
  id          bigserial   PRIMARY KEY,
  ticket_id   uuid        NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender      text        NOT NULL CHECK (sender IN ('partner', 'agent', 'bot')),
  body        text        NOT NULL,
  attachment_s3_key text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX support_messages_ticket_idx ON support_messages (ticket_id, created_at);

CREATE TABLE emergency_contacts (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id    uuid        NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  name          text        NOT NULL,
  relationship  text        NOT NULL,
  phone         text        NOT NULL,
  is_primary    boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX emergency_contacts_one_primary_idx ON emergency_contacts (partner_id) WHERE is_primary;

CREATE TABLE sos_incidents (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id    uuid        NOT NULL REFERENCES partners(id),
  order_id      uuid        REFERENCES orders(id),
  kind          text        NOT NULL DEFAULT 'sos' CHECK (kind IN ('sos', 'road_accident', 'harassment', 'medical', 'vehicle_breakdown', 'other')),
  lat           double precision,
  lng           double precision,
  details       text,
  status        sos_status  NOT NULL DEFAULT 'open',
  created_at    timestamptz NOT NULL DEFAULT now(),
  acknowledged_at timestamptz,
  resolved_at   timestamptz
);
CREATE INDEX sos_incidents_open_idx ON sos_incidents (created_at) WHERE status <> 'resolved';

CREATE TABLE app_ratings (
  id          bigserial   PRIMARY KEY,
  partner_id  uuid        NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  stars       smallint    NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment     text,
  app_version text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
