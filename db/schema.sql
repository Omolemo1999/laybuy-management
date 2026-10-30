CREATE TABLE IF NOT EXISTS tenants (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT NOT NULL, slug TEXT NOT NULL UNIQUE,
 email TEXT NOT NULL, phone TEXT, address TEXT, status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','suspended')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS users (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
 email TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, full_name TEXT NOT NULL, phone TEXT,
 role TEXT NOT NULL CHECK(role IN ('owner','staff','customer','platform_admin')),
 email_verified_at TIMESTAMPTZ, disabled_at TIMESTAMPTZ, session_version INTEGER NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS users_tenant_idx ON users(tenant_id);
CREATE TABLE IF NOT EXISTS sessions (sid VARCHAR PRIMARY KEY, sess JSON NOT NULL, expire TIMESTAMPTZ NOT NULL);
CREATE INDEX IF NOT EXISTS sessions_expire_idx ON sessions(expire);
CREATE TABLE IF NOT EXISTS products (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 sku TEXT, name TEXT NOT NULL, description TEXT, unit_price_cents BIGINT NOT NULL CHECK(unit_price_cents > 0),
 stock_qty INTEGER NOT NULL DEFAULT 0 CHECK(stock_qty >= 0), active BOOLEAN NOT NULL DEFAULT true,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE(tenant_id,sku)
);
CREATE TABLE IF NOT EXISTS laybys (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id UUID NOT NULL REFERENCES tenants(id), customer_id UUID NOT NULL REFERENCES users(id),
 product_id UUID NOT NULL REFERENCES products(id), reference TEXT NOT NULL UNIQUE, quantity INTEGER NOT NULL CHECK(quantity > 0),
 unit_price_cents BIGINT NOT NULL, total_cents BIGINT NOT NULL, paid_cents BIGINT NOT NULL DEFAULT 0,
 deposit_cents BIGINT NOT NULL DEFAULT 0, instalment_cents BIGINT NOT NULL, frequency TEXT NOT NULL CHECK(frequency IN ('weekly','fortnightly','monthly','flexible')),
 expected_completion DATE NOT NULL, status TEXT NOT NULL DEFAULT 'pending_acceptance' CHECK(status IN ('pending_acceptance','active','paid','ready_for_collection','collected','cancellation_requested','cancelled','expired','refunded')),
 terms_version TEXT NOT NULL DEFAULT 'CPA62-v1', terms_accepted_at TIMESTAMPTZ NOT NULL, customer_accepted_at TIMESTAMPTZ,
 collection_code_hash TEXT, collected_at TIMESTAMPTZ, collected_by UUID REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 CHECK(paid_cents <= total_cents)
);
CREATE INDEX IF NOT EXISTS laybys_tenant_idx ON laybys(tenant_id,created_at DESC);
CREATE INDEX IF NOT EXISTS laybys_customer_idx ON laybys(customer_id,created_at DESC);
CREATE TABLE IF NOT EXISTS payments (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id UUID NOT NULL REFERENCES tenants(id), layby_id UUID NOT NULL REFERENCES laybys(id),
 customer_id UUID NOT NULL REFERENCES users(id), provider TEXT NOT NULL DEFAULT 'paystack', reference TEXT NOT NULL UNIQUE,
 amount_cents BIGINT NOT NULL CHECK(amount_cents > 0), currency TEXT NOT NULL DEFAULT 'ZAR', status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','success','failed','reversed','refunded')),
 provider_transaction_id TEXT, channel TEXT, paid_at TIMESTAMPTZ, raw_verified JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS payments_layby_idx ON payments(layby_id,created_at DESC);
CREATE TABLE IF NOT EXISTS webhook_events (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), provider TEXT NOT NULL, event_key TEXT NOT NULL UNIQUE,
 received_at TIMESTAMPTZ NOT NULL DEFAULT now(), processed_at TIMESTAMPTZ, status TEXT NOT NULL DEFAULT 'received'
);
CREATE TABLE IF NOT EXISTS audit_logs (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id UUID REFERENCES tenants(id), actor_id UUID REFERENCES users(id),
 action TEXT NOT NULL, entity_type TEXT, entity_id TEXT, ip INET, user_agent TEXT, metadata JSONB NOT NULL DEFAULT '{}', created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_tenant_idx ON audit_logs(tenant_id,created_at DESC);
CREATE TABLE IF NOT EXISTS email_tokens (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 token_hash TEXT NOT NULL UNIQUE, purpose TEXT NOT NULL CHECK(purpose IN ('verify','reset')), expires_at TIMESTAMPTZ NOT NULL, used_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS disputes (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id UUID NOT NULL REFERENCES tenants(id), layby_id UUID NOT NULL REFERENCES laybys(id),
 opened_by UUID NOT NULL REFERENCES users(id), reason TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','investigating','resolved','rejected')),
 resolution TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
