# 10 - Architecture Technique

## Diagramme High-Level

```mermaid
flowchart LR
    U[Users: Admin/Manager/Tech/Client] --> CF[Cloudflare: DNS/WAF/TLS]
    CF --> WEB[Web Dashboard]
    CF --> API[Analytics API - FastAPI]
    
    subgraph VPS[Single VPS - Coolify]
        API
        N8N[n8n Community]
        REDIS[Redis]
        PG[(PostgreSQL)]
    end
    
    N8N --> API
    API --> PG
    API --> REDIS
    API --> LLM[Claude API]
```

## Réseaux Docker (Isolation Sécurité)

| Réseau | Accès Internet | Services | Purpose |
|--------|---------------|----------|---------|
| `backend` | internal: true (NON) | PostgreSQL, Redis, n8n-worker | Données sensibles, pas d'egress |
| `egress` | OUI | analytics-api | Appels externes (LLM, webhooks) |
| `frontend` | localhost only | n8n UI, Metabase | UIs admin, pas exposées publiquement |

### Règles de Sécurité Réseau
1. PostgreSQL et Redis n'ont JAMAIS accès à Internet
2. Seul `analytics-api` peut faire des appels sortants (Claude API)
3. n8n UI accessible uniquement en local ou via tunnel sécurisé
4. Le client ne voit JAMAIS n8n ou les outils internes

## Flux de Données

### 1. Ingestion (Polling - toutes les 15 min)
```mermaid
sequenceDiagram
    participant N as n8n
    participant A as Analytics API
    participant S as PostgreSQL
    
    N->>A: POST /internal/ingest/tickets (tenant_id, cursor)
    A->>S: upsert raw_tickets
    A-->>N: 200 (next_cursor, stats)
```

### 2. Calcul KPIs (Daily - 6h00)
```mermaid
sequenceDiagram
    participant N as n8n
    participant A as Analytics API
    participant S as PostgreSQL
    
    N->>A: POST /internal/kpi/compute-daily (date=D-1)
    A->>S: SELECT aggregates FROM raw_*
    A->>S: INSERT INTO kpi_daily
    A-->>N: 200 (rows_written)
```

### 3. Export Power BI (Daily - 7h30)
```mermaid
sequenceDiagram
    participant N as n8n
    participant A as Analytics API
    participant S as PostgreSQL
    participant O as Storage/MinIO
    
    N->>A: POST /internal/exports/generate
    A->>S: SELECT kpi_daily WHERE tenant_id=...
    A->>O: write CSV per tenant
    A-->>N: 200 (export_locations)
```

## Composants Principaux

### Analytics API (FastAPI)
- Port: 8000
- Responsabilités:
  - Validation des inputs (Pydantic)
  - Extraction tenant depuis JWT/API-key
  - Rate limiting via Redis
  - Endpoints internes (n8n → API)
  - Endpoints publics (Dashboard → API)
  - Appels LLM pour résumés

### n8n (Orchestration)
- Port: 5678 (UI)
- **MCP Server**: http://n8n.76.13.98.217.sslip.io/mcp-server/http
- Responsabilités:
  - Cron jobs (polling, KPI compute, exports)
  - Orchestration des workflows
  - Error handling global
  - Notifications (Slack/Email)

> ⚡ **Cursor a accès direct à n8n via MCP!**
> Voir `docs/context/50_MCP_N8N.md` pour créer les workflows directement.

### PostgreSQL
- Port: 5432
- Responsabilités:
  - Stockage multi-tenant
  - RLS pour isolation
  - Tables raw_* + kpi_daily + audit_log

### Redis
- Port: 6379
- Responsabilités:
  - Rate limiting (fenêtre fixe par tenant/endpoint)
  - Cache optionnel
  - Idempotency keys

## Variables d'Environnement Clés

```env
# Database
DATABASE_URL=postgresql://user:pass@postgres:5432/msp_analytics

# Redis
REDIS_URL=redis://redis:6379

# Auth
SERVICE_TOKEN=<internal-token-for-n8n>
JWT_SECRET=<jwt-signing-secret>

# LLM
CLAUDE_API_KEY=<anthropic-api-key>

# Mode
MOCK_MODE=true|false
MOCK_DATA_PATH=/app/mock-data
```
