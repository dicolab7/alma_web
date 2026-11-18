CREATE EXTENSION IF NOT EXISTS pgcrypto;
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('customer','admin'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE purchase_status AS ENUM ('pending','confirmed','cancelled','refunded','overdue'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE ledger_kind AS ENUM ('purchase','consumption','adjustment','refund'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE TABLE IF NOT EXISTS users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), role user_role NOT NULL DEFAULT 'customer', name text NOT NULL,
 email text NOT NULL UNIQUE, password_hash text NOT NULL, document text, phone text, asaas_customer_id text UNIQUE,
 active boolean NOT NULL DEFAULT true, accepted_terms_at timestamptz, accepted_privacy_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS purchases (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id),
 meters numeric(14,3) NOT NULL CHECK (meters > 0), amount_cents integer NOT NULL CHECK (amount_cents > 0),
 status purchase_status NOT NULL DEFAULT 'pending', asaas_payment_id text UNIQUE, billing_type text NOT NULL,
 invoice_url text, due_date date, created_at timestamptz NOT NULL DEFAULT now(), confirmed_at timestamptz
);
CREATE TABLE IF NOT EXISTS machines (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), customer_id uuid REFERENCES users(id), name text NOT NULL,
 external_id text, api_key_hash text NOT NULL, active boolean NOT NULL DEFAULT true, last_seen_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(customer_id, external_id)
);
ALTER TABLE machines ALTER COLUMN customer_id DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS machines_external_id_unique ON machines(external_id) WHERE external_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS meter_ledger (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), kind ledger_kind NOT NULL,
 meters numeric(14,3) NOT NULL CHECK (meters <> 0), purchase_id uuid REFERENCES purchases(id), machine_id uuid REFERENCES machines(id),
 idempotency_key text UNIQUE, description text, metadata jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS meter_ledger_user_idx ON meter_ledger(user_id, created_at DESC);
CREATE TABLE IF NOT EXISTS webhook_events (
 id text PRIMARY KEY, provider text NOT NULL, event_type text NOT NULL, payload jsonb NOT NULL, processed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS audit_logs (
 id bigserial PRIMARY KEY, actor_id uuid REFERENCES users(id), action text NOT NULL, entity_type text NOT NULL,
 entity_id text, metadata jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE OR REPLACE VIEW customer_balances AS SELECT u.id AS user_id,
 COALESCE(SUM(l.meters),0)::numeric(14,3) AS balance_meters FROM users u LEFT JOIN meter_ledger l ON l.user_id=u.id GROUP BY u.id;
ALTER TABLE users ADD COLUMN IF NOT EXISTS company_name text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS state_registration text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS postal_code text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS street text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_number text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS complement text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS neighborhood text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS state text;
CREATE TABLE IF NOT EXISTS auth_events (id bigserial PRIMARY KEY,email text,success boolean NOT NULL,ip_address text,user_agent text,failure_reason text,created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX IF NOT EXISTS auth_events_created_idx ON auth_events(created_at DESC);
CREATE TABLE IF NOT EXISTS credit_settings (id boolean PRIMARY KEY DEFAULT true CHECK(id),price_per_meter_cents integer NOT NULL DEFAULT 250,min_purchase_meters numeric(14,3) NOT NULL DEFAULT 10,updated_at timestamptz NOT NULL DEFAULT now());
INSERT INTO credit_settings(id) VALUES(true) ON CONFLICT DO NOTHING;
CREATE TABLE IF NOT EXISTS promotions (id uuid PRIMARY KEY DEFAULT gen_random_uuid(),name text NOT NULL,discount_percent numeric(5,2) NOT NULL CHECK(discount_percent>=0 AND discount_percent<=100),starts_at timestamptz,ends_at timestamptz,active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
