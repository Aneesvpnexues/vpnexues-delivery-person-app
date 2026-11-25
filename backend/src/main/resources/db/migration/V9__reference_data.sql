-- V9 · Reference data (pilot cities and hub)

INSERT INTO cities (name, state) VALUES
  ('Chennai', 'Tamil Nadu'),
  ('Bengaluru', 'Karnataka'),
  ('Coimbatore', 'Tamil Nadu')
ON CONFLICT (name) DO NOTHING;

INSERT INTO hubs (city_id, name, address, lat, lng, allowed_radii_km, recommended_radius_km, areas_by_radius)
SELECT c.id, 'Anna Nagar Hub', '2nd Avenue, Anna Nagar, Chennai 600040', 13.0850, 80.2101, '{3,5,7}', 5,
       '{"3":["Anna Nagar East"],"5":["Anna Nagar East","Anna Nagar West"],"7":["Anna Nagar East","Anna Nagar West","Shenoy Nagar"]}'::jsonb
FROM cities c WHERE c.name = 'Chennai'
ON CONFLICT (city_id, name) DO NOTHING;
