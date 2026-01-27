-- Initial database schema for MSP Analytics Platform
-- Multi-tenant with strict isolation

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: tenants
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    llm_enabled BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: api_keys
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    key_hash TEXT NOT NULL UNIQUE,  -- SHA-256 hash of the API key
    name TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    last_used_at TIMESTAMPTZ
);

CREATE INDEX idx_api_keys_tenant_id ON api_keys(tenant_id);
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);

-- Table: raw_tickets
CREATE TABLE raw_tickets (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    cw_ticket_id TEXT NOT NULL,
    board TEXT,
    status TEXT,
    priority TEXT,
    summary TEXT,
    description TEXT,
    company TEXT,
    owner TEXT,
    created_at_remote TIMESTAMPTZ,
    updated_at_remote TIMESTAMPTZ,
    sla_status TEXT,
    estimated_hours NUMERIC(10, 2),
    ingested_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, cw_ticket_id)
);

CREATE INDEX idx_raw_tickets_tenant_company ON raw_tickets(tenant_id, company);
CREATE INDEX idx_raw_tickets_tenant_status ON raw_tickets(tenant_id, status);
CREATE INDEX idx_raw_tickets_tenant_created ON raw_tickets(tenant_id, created_at_remote);

-- Table: raw_time_entries
CREATE TABLE raw_time_entries (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    cw_time_entry_id TEXT NOT NULL,
    cw_ticket_id TEXT,
    member TEXT,
    work_type TEXT,
    billable BOOLEAN DEFAULT true,
    minutes INTEGER,
    notes TEXT,
    date_worked DATE,
    ingested_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, cw_time_entry_id)
);

CREATE INDEX idx_raw_time_entries_tenant_ticket ON raw_time_entries(tenant_id, cw_ticket_id);
CREATE INDEX idx_raw_time_entries_tenant_date ON raw_time_entries(tenant_id, date_worked);

-- Table: kpi_daily
CREATE TABLE kpi_daily (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    kpi_date DATE NOT NULL,
    
    -- KPI 04: Time Consumption
    total_minutes INTEGER DEFAULT 0,
    billable_minutes INTEGER DEFAULT 0,
    non_billable_minutes INTEGER DEFAULT 0,
    
    -- KPI 07: Tech Efficiency
    avg_resolution_minutes NUMERIC(10, 2),
    first_call_resolution_rate NUMERIC(5, 2),  -- Percentage
    avg_satisfaction_score NUMERIC(3, 2),
    
    -- KPI 11: Ticket Trends
    tickets_created INTEGER DEFAULT 0,
    tickets_closed INTEGER DEFAULT 0,
    tickets_open INTEGER DEFAULT 0,
    tickets_high_priority INTEGER DEFAULT 0,
    anomaly_detected BOOLEAN DEFAULT false,
    z_score NUMERIC(10, 4),
    
    computed_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, kpi_date)
);

CREATE INDEX idx_kpi_daily_tenant_date ON kpi_daily(tenant_id, kpi_date);

-- Enable Row Level Security (RLS) for multi-tenant isolation
-- Note: RLS policies will be set per-tenant via application context
-- For now, we rely on application-level filtering
