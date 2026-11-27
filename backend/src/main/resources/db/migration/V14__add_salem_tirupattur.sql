-- V14 – Add missing Tamil Nadu service cities

INSERT INTO cities (name, state) VALUES
  ('Salem', 'Tamil Nadu'),
  ('Tirupathur', 'Tamil Nadu'),
  ('Tirupattur', 'Tamil Nadu')
ON CONFLICT (name) DO NOTHING;
