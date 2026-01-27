# Plan: Gate 8 + Gate 9 - Mock API Implementation

## Objectif

Implémenter Gate 8 (FastAPI endpoints internes) + Gate 9 (DB schema) en mode MOCK pour que les workflows n8n fonctionnent.

## Contraintes

- **MOCK_MODE=true** => toutes les routes `/internal/ingest/*` lisent des fichiers locaux `MOCK_DATA_PATH`
- **Multi-tenant strict**: chaque write/read doit filtrer `tenant_id`
- **Auth**:
  - Routes `/internal/*` protégées par `SERVICE_TOKEN` (Authorization: Bearer <service_token>)
  - Routes `/v1/*` protégées par `X-API-Key` (clé par tenant, hash en DB)

## Ce qui a été implémenté

### 1. DB Schema (Postgres)
- ✅ Table `tenants` (id, name, is_active, llm_enabled)
- ✅ Table `api_keys` (id, tenant_id, key_hash, name, is_active, last_used_at)
- ✅ Table `raw_tickets` (tenant_id, cw_ticket_id, board, status, priority, summary, description, company, owner, created_at_remote, updated_at_remote, sla_status, estimated_hours)
- ✅ Table `raw_time_entries` (tenant_id, cw_time_entry_id, cw_ticket_id, member, work_type, billable, minutes, notes, date_worked)
- ✅ Table `kpi_daily` (tenant_id, kpi_date, total_minutes, billable_minutes, non_billable_minutes, avg_resolution_minutes, first_call_resolution_rate, avg_satisfaction_score, tickets_created, tickets_closed, tickets_open, tickets_high_priority, anomaly_detected, z_score)
- ✅ Migrations SQL dans `analytics-api/migrations/001_initial_schema.sql`

### 2. Seed MOCK
- ✅ Structure `mock-data/` créée:
  - `mock-data/tenants.json` (2 tenants avec UUIDs)
  - `mock-data/tenant_demo_cca/tickets.jsonl` (5 tickets)
  - `mock-data/tenant_demo_cca/time_entries.jsonl` (5 time entries)
  - `mock-data/tenant_demo_client2/tickets.jsonl` (2 tickets)
  - `mock-data/tenant_demo_client2/time_entries.jsonl` (2 time entries)
- ✅ Script `seed_mock.py` créé:
  - Crée tenants + api_keys en DB
  - Génère et affiche les clés API pour tests

### 3. FastAPI Endpoints MVP
- ✅ `GET /health` - Health check
- ✅ `GET /internal/tenants` (service token) -> liste tenants actifs
- ✅ `POST /internal/ingest/tickets?tenant_id=...` -> lit `tenantX/tickets.jsonl` -> upsert `raw_tickets`
- ✅ `POST /internal/ingest/time_entries?tenant_id=...` -> lit `tenantX/time_entries.jsonl` -> upsert `raw_time_entries`
- ✅ `POST /internal/kpi/compute-daily?tenant_id=...&date=YYYY-MM-DD` -> calcule KPIs et upsert `kpi_daily`
- ✅ `POST /internal/exports/generate?tenant_id=...&date=YYYY-MM-DD` -> génère un JSON par tenant (mock)
- ✅ `GET /v1/kpis/daily?date=YYYY-MM-DD` (X-API-Key) -> retourne kpis du tenant
- ✅ `GET /v1/tickets/{cw_ticket_id}/summary` (X-API-Key) -> retourne résumé "mock"

### 4. Configuration
- ✅ Variables d'environnement: `MOCK_MODE`, `MOCK_DATA_PATH`, `SERVICE_TOKEN`, `DATABASE_URL`
- ✅ Docker compose: `analytics-api` voit `/app/mock-data` (volume monté)
- ✅ `.env.example` mis à jour avec `SERVICE_TOKEN`, `MOCK_MODE`, `MOCK_DATA_PATH`

## Structure des fichiers créés

```
analytics-api/
├── Dockerfile
├── requirements.txt
├── healthcheck.py
├── seed_mock.py
├── migrations/
│   └── 001_initial_schema.sql
├── alembic.ini
├── alembic/
│   ├── env.py
│   └── script.py.mako
├── exports/ (directory)
└── app/
    ├── __init__.py
    ├── main.py
    ├── config.py
    ├── database.py
    ├── models.py
    ├── auth/
    │   └── dependencies.py
    └── routers/
        ├── __init__.py
        ├── health.py
        ├── internal.py
        └── v1.py

mock-data/
├── tenants.json
├── tenant_demo_cca/
│   ├── tickets.jsonl
│   └── time_entries.jsonl
└── tenant_demo_client2/
    ├── tickets.jsonl
    └── time_entries.jsonl
```

## Tests à effectuer

1. Build et démarrage des services Docker
2. Application de la migration SQL
3. Seed de la base de données
4. Test des endpoints internes avec SERVICE_TOKEN
5. Test des endpoints publics avec X-API-Key
6. Vérification de l'isolation multi-tenant
