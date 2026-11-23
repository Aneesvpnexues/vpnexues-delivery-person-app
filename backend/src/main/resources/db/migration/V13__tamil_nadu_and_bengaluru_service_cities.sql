-- V13 – Service coverage: all major Tamil Nadu cities and Bengaluru

INSERT INTO cities (name, state) VALUES
  ('Ariyalur', 'Tamil Nadu'),
  ('Chengalpattu', 'Tamil Nadu'),
  ('Cuddalore', 'Tamil Nadu'),
  ('Dharmapuri', 'Tamil Nadu'),
  ('Dindigul', 'Tamil Nadu'),
  ('Erode', 'Tamil Nadu'),
  ('Hosur', 'Tamil Nadu'),
  ('Kanchipuram', 'Tamil Nadu'),
  ('Kanyakumari', 'Tamil Nadu'),
  ('Karur', 'Tamil Nadu'),
  ('Krishnagiri', 'Tamil Nadu'),
  ('Kumbakonam', 'Tamil Nadu'),
  ('Mayiladuthurai', 'Tamil Nadu'),
  ('Nagapattinam', 'Tamil Nadu'),
  ('Namakkal', 'Tamil Nadu'),
  ('Nagercoil', 'Tamil Nadu'),
  ('Ooty', 'Tamil Nadu'),
  ('Perambalur', 'Tamil Nadu'),
  ('Pudukkottai', 'Tamil Nadu'),
  ('Ramanathapuram', 'Tamil Nadu'),
  ('Ranipet', 'Tamil Nadu'),
  ('Sivakasi', 'Tamil Nadu'),
  ('Sivaganga', 'Tamil Nadu'),
  ('Tenkasi', 'Tamil Nadu'),
  ('Thanjavur', 'Tamil Nadu'),
  ('Theni', 'Tamil Nadu'),
  ('Thoothukudi', 'Tamil Nadu'),
  ('Tirunelveli', 'Tamil Nadu'),
  ('Tiruppur', 'Tamil Nadu'),
  ('Tiruvallur', 'Tamil Nadu'),
  ('Tiruvannamalai', 'Tamil Nadu'),
  ('Tiruvarur', 'Tamil Nadu'),
  ('Vellore', 'Tamil Nadu'),
  ('Viluppuram', 'Tamil Nadu'),
  ('Virudhunagar', 'Tamil Nadu')
ON CONFLICT (name) DO NOTHING;

-- Ensure Bengaluru service city exists
INSERT INTO cities (name, state) VALUES ('Bengaluru', 'Karnataka')
ON CONFLICT (name) DO NOTHING;
