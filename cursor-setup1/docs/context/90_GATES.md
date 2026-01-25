# 90 - Gates du Projet

## Définition

Les "Gates" sont des checkpoints de validation qui garantissent que chaque étape est complète et vérifiée avant de passer à la suivante.

```
Chaque Gate = Objectif + Preuves Attendues + Commandes de Validation
```

---

## Gate 0: Foundation ✅ COMPLÉTÉ
**Objectif**: Infrastructure de base prête.

### Preuves
- [x] VPS Hostinger KVM2 provisionné
- [x] Coolify installé et accessible
- [x] n8n Community déployé
- [x] PostgreSQL déployé
- [x] 3 réseaux Docker configurés (backend, egress, frontend)

### Validation
```bash
# Docker services running
docker compose ps

# n8n accessible
curl http://localhost:5678/healthz

# PostgreSQL accessible
docker compose exec postgres pg_isready
```

---

## Gate 5.1: Mock Mode + Tenant Alignment ✅ COMPLÉTÉ
**Objectif**: Architecture multi-tenant planifiée, isolation réseau validée.

### Preuves
- [x] Documentation architecture (réseaux)
- [x] Strategy multi-tenant définie (tenant depuis auth)
- [x] Rate limiting strategy (Redis window fixe)

### Ce qui manque pour compléter Gate 5.1
- [ ] Code analytics-api/ créé
- [ ] Fichiers mock-data/ générés
- [ ] Schema DB appliqué

---

## Gate 6: Bootstrap Cursor
**Objectif**: Environnement Cursor configuré avec rules, commands, context pack.

### Preuves Attendues
```
proofs/GATE-6-BOOTSTRAP/
├── 20_outputs/
│   ├── git_status.txt
│   ├── tree_cursor.txt
│   └── tree_docs.txt
└── 40_verdict.md
```

### Checklist
- [ ] `.cursor/rules/00_guardrails.md` créé
- [ ] `.cursor/rules/10_stack_commands.md` créé
- [ ] `.cursor/commands/verify.md` créé
- [ ] `docs/context/*.md` (6 fichiers) créés
- [ ] `proofs/` dossier initialisé
- [ ] Git commit du bootstrap

### Validation
```bash
ls -la .cursor/rules/
ls -la .cursor/commands/
ls -la docs/context/
```

---

## Gate 7: Mock Data
**Objectif**: Données de simulation multi-tenant prêtes.

### Preuves Attendues
```
proofs/GATE-7-MOCKDATA/
├── 20_outputs/
│   ├── tenant_list.json
│   ├── ticket_count.txt
│   └── validation.txt
└── 40_verdict.md
```

### Checklist
- [ ] `mock-data/tenants.json` (2 tenants)
- [ ] `mock-data/tickets/*.json` (50-100 par tenant)
- [ ] `mock-data/time_entries/*.json` (100 par tenant)
- [ ] `mock-data/csat/*.json` (30 par tenant)
- [ ] `mock-data/security_alerts/*.json` (40 par tenant)
- [ ] Script de génération documenté

### Validation
```bash
# Count tickets
jq length mock-data/tickets/tenant_demo_cca.json

# Validate JSON structure
python -m json.tool mock-data/tickets/tenant_demo_cca.json > /dev/null

# Check all tenants have data
for tenant in tenant_demo_cca tenant_demo_client2; do
  echo "$tenant tickets: $(jq length mock-data/tickets/$tenant.json)"
done
```

---

## Gate 8: Analytics API Skeleton
**Objectif**: API FastAPI fonctionnelle avec auth et health check.

### Preuves Attendues
```
proofs/GATE-8-API/
├── 20_outputs/
│   ├── health_check.txt
│   ├── auth_test.txt
│   ├── pytest.txt
│   └── mypy.txt
└── 40_verdict.md
```

### Checklist
- [ ] `analytics-api/` structure créée
- [ ] `main.py` avec app FastAPI
- [ ] `/health` endpoint
- [ ] Auth middleware (API key extraction)
- [ ] Rate limiting middleware
- [ ] Config (settings.py)
- [ ] Dockerfile
- [ ] Tests de base

### Validation
```bash
# Start API
docker compose up -d analytics-api

# Health check
curl -f http://localhost:8000/health

# Auth required
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/v1/kpis/daily
# Expected: 401

# With valid key
curl -H "X-API-Key: test-key" http://localhost:8000/v1/kpis/daily
```

---

## Gate 9: Database Schema
**Objectif**: Schema PostgreSQL multi-tenant avec RLS.

### Preuves Attendues
```
proofs/GATE-9-SCHEMA/
├── 20_outputs/
│   ├── migrations.txt
│   ├── tables.txt
│   └── rls_test.txt
└── 40_verdict.md
```

### Checklist
- [ ] Tables: tenants, api_keys, raw_tickets, raw_time_entries, raw_csat, raw_security_alerts, kpi_daily, audit_log
- [ ] Primary keys composites (tenant_id, *)
- [ ] Foreign keys
- [ ] RLS policies activées
- [ ] Migrations Alembic

### Validation
```bash
# List tables
docker compose exec postgres psql -U msp -d msp_analytics -c "\dt"

# Check RLS
docker compose exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public'"
```

---

## Gate 10: Ingestion Endpoints
**Objectif**: Endpoints internes pour n8n fonctionnels.

### Preuves Attendues
```
proofs/GATE-10-INGEST/
├── 20_outputs/
│   ├── ingest_tickets.txt
│   ├── ingest_time.txt
│   ├── db_count.txt
│   └── pytest.txt
└── 40_verdict.md
```

### Checklist
- [ ] POST /internal/ingest/tickets
- [ ] POST /internal/ingest/time-entries
- [ ] POST /internal/ingest/csat
- [ ] POST /internal/ingest/alerts
- [ ] Upsert logic (idempotent)
- [ ] Service token auth

### Validation
```bash
# Ingest tickets
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tenant_id": "tenant_demo_cca"}' \
  http://localhost:8000/internal/ingest/tickets

# Check DB
docker compose exec postgres psql -U msp -d msp_analytics -c \
  "SELECT COUNT(*) FROM raw_tickets"
```

---

## Gate 11: KPI Compute
**Objectif**: Calcul des KPIs quotidiens fonctionnel.

### Preuves Attendues
```
proofs/GATE-11-KPI/
├── 20_outputs/
│   ├── compute_daily.txt
│   ├── kpi_results.json
│   └── pytest.txt
└── 40_verdict.md
```

### Checklist
- [ ] POST /internal/kpi/compute-daily
- [ ] GET /v1/kpis/daily
- [ ] KPIs MVP: Time Consumption, Tech Efficiency, Ticket Trends
- [ ] Table kpi_daily peuplée

### Validation
```bash
# Compute
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  -d '{"date": "2026-01-23"}' \
  http://localhost:8000/internal/kpi/compute-daily

# Read
curl -H "X-API-Key: $API_KEY" \
  "http://localhost:8000/v1/kpis/daily?date=2026-01-23"
```

---

## Gate 12: n8n Workflows
**Objectif**: Workflows n8n automatisant l'ingestion et les calculs.

### ⚡ Méthode: Via MCP (Accès Direct)
```
Cursor a accès au serveur MCP n8n!
URL: http://n8n.76.13.98.217.sslip.io/mcp-server/http

Cela permet de créer/modifier/activer les workflows directement 
depuis Cursor, sans passer par l'UI n8n.
```

Voir: `docs/context/50_MCP_N8N.md` pour les détails.

### Checklist
- [ ] WF-00: Global Error Handler
- [ ] WF-01: Orchestrator Ingestion
- [ ] WF-01A/B/C/D: Sub-workflows ingestion
- [ ] WF-10: Daily KPI Compute
- [ ] WF-20: Export Power BI

### Validation via MCP
```
# Lister les workflows créés
MCP: workflow_list

# Exécuter un workflow manuellement
MCP: workflow_execute (workflow_id)

# Vérifier le statut
MCP: workflow_get (workflow_id)
```

### Validation Traditionnelle
- Exécution manuelle de chaque workflow
- Vérification des données dans la DB
- Vérification des exports générés

---

## Gate 13: Dashboard MVP
**Objectif**: Interface visible pour le client.

### Options
1. **Metabase**: Configuration et dashboards
2. **React Dashboard**: Application web custom

### Preuves Attendues
- Screenshots des dashboards
- Données affichées correctement par tenant

---

## Gate 14: Validation Finale MVP
**Objectif**: MVP complet et démontrable.

### Checklist Globale
- [ ] Isolation multi-tenant vérifiée
- [ ] KPIs quotidiens visibles
- [ ] Exports Power BI générés
- [ ] Ingestion stable
- [ ] Audit logs fonctionnels
- [ ] Rate limiting testé
- [ ] Documentation utilisateur

### Commande de Validation Finale
```bash
./scripts/validate-mvp.sh
```

---

## Progression Actuelle

```
Gate 0  ████████████ 100% - Foundation
Gate 5.1 ██████████░░  85% - Mock Mode Planning
Gate 6  ░░░░░░░░░░░░   0% - Bootstrap Cursor ← PROCHAINE ÉTAPE
Gate 7  ░░░░░░░░░░░░   0% - Mock Data
Gate 8  ░░░░░░░░░░░░   0% - API Skeleton
...
```
