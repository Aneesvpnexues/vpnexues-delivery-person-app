-- V1 · Shared enum types and helpers
-- Money is always stored as integer paise (₹1 = 100 paise).
-- gen_random_uuid() is built into PostgreSQL 13+, so no extension is required.

CREATE TYPE vehicle_type        AS ENUM ('motorbike', 'scooter', 'electric_scooter', 'bicycle');
CREATE TYPE partner_status      AS ENUM ('onboarding', 'active', 'suspended', 'deactivated');
CREATE TYPE kyc_status          AS ENUM ('not_started', 'in_review', 'verified', 'rejected');
CREATE TYPE app_language        AS ENUM ('en', 'ta', 'hi', 'ml', 'te', 'kn');

CREATE TYPE document_type       AS ENUM ('aadhaar', 'pan', 'driving_licence', 'vehicle_rc', 'vehicle_insurance', 'pucc', 'police_verification', 'selfie');
CREATE TYPE document_status     AS ENUM ('pending_upload', 'in_review', 'verified', 'rejected', 'expired');

CREATE TYPE payout_method_type  AS ENUM ('bank_account', 'upi');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'failed');

CREATE TYPE order_status        AS ENUM ('created', 'assigned', 'accepted', 'at_pickup', 'picked_up', 'arrived', 'delivered', 'cancelled');
CREATE TYPE ledger_entry_type   AS ENUM ('delivery_base', 'delivery_distance', 'tip', 'bonus', 'incentive', 'deduction', 'payout', 'payout_fee', 'adjustment');
CREATE TYPE payout_kind         AS ENUM ('weekly', 'instant');
CREATE TYPE payout_status       AS ENUM ('requested', 'processing', 'paid', 'failed');

CREATE TYPE otp_purpose         AS ENUM ('signup', 'login', 'password_reset', 'phone_change');
CREATE TYPE notification_category AS ENUM ('order', 'payout', 'account', 'promo', 'safety');
CREATE TYPE ticket_status       AS ENUM ('open', 'waiting_on_partner', 'resolved', 'closed');
CREATE TYPE sos_status          AS ENUM ('open', 'acknowledged', 'resolved');

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
