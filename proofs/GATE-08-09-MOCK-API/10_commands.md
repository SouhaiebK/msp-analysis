# Commandes de validation - Gate 8 + Gate 9

## Prérequis

1. Avoir un fichier `.env` configuré avec:
   - `DB_USER`, `DB_PASSWORD`
   - `REDIS_PASSWORD`
   - `JWT_SECRET_KEY`
   - `SERVICE_TOKEN` (ex: `test-service-token-123`)
   - `MOCK_MODE=true`
   - `MOCK_DATA_PATH=/app/mock-data`

## Étapes de validation

### 1. Build et démarrage des services

```bash
# Build et start tous les services
docker compose -p msp up -d --build

# Vérifier que les services sont healthy
docker compose -p msp ps
```

### 2. Application de la migration SQL

```bash
# Appliquer le schéma de base de données
docker compose -p msp exec postgres psql -U msp -d msp_analytics -f /tmp/migrations/001_initial_schema.sql

# OU copier le fichier et l'exécuter
docker cp analytics-api/migrations/001_initial_schema.sql msp-postgres:/tmp/
docker compose -p msp exec postgres psql -U msp -d msp_analytics -f /tmp/001_initial_schema.sql

# Vérifier les tables créées
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c "\dt"
```

### 3. Seed de la base de données

```bash
# Exécuter le script de seed
docker compose -p msp exec analytics-api python /app/seed_mock.py

# Sauvegarder les API keys générées (affichées dans la sortie)
```

### 4. Test du health check

```bash
# Test health endpoint
curl http://localhost:8000/health
```

**Résultat attendu:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "mock_mode": true
}
```

### 5. Test GET /internal/tenants

```bash
# Récupérer SERVICE_TOKEN depuis .env
export SERVICE_TOKEN="test-service-token-123"  # ou la valeur depuis .env

# Test endpoint interne
curl -H "Authorization: Bearer $SERVICE_TOKEN" http://localhost:8000/internal/tenants
```

**Résultat attendu:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "CCA Demo",
    "is_active": true,
    "llm_enabled": true
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Client 2 Demo",
    "is_active": true,
    "llm_enabled": false
  }
]
```

### 6. Test POST /internal/ingest/tickets

```bash
# Ingest tickets pour tenant_demo_cca
TENANT_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://localhost:8000/internal/ingest/tickets?tenant_id=$TENANT_ID"
```

**Résultat attendu:**
```json
{
  "message": "Tickets ingested successfully",
  "ingested": 5
}
```

### 7. Test POST /internal/ingest/time_entries

```bash
# Ingest time entries pour tenant_demo_cca
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://localhost:8000/internal/ingest/time_entries?tenant_id=$TENANT_ID"
```

**Résultat attendu:**
```json
{
  "message": "Time entries ingested successfully",
  "ingested": 5
}
```

### 8. Test POST /internal/kpi/compute-daily

```bash
# Calculer les KPIs pour une date
DATE="2026-01-20"
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://localhost:8000/internal/kpi/compute-daily?tenant_id=$TENANT_ID&date=$DATE"
```

**Résultat attendu:**
```json
{
  "message": "KPIs computed successfully",
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2026-01-20",
  "metrics": {
    "total_minutes": 75,
    "billable_minutes": 75,
    "tickets_created": 1,
    "tickets_closed": 1,
    "anomaly_detected": false
  }
}
```

### 9. Test GET /v1/kpis/daily (avec API Key)

```bash
# Utiliser l'API key générée par seed_mock.py
API_KEY="msp_ak_..."  # Remplacer par la clé générée

curl -H "X-API-Key: $API_KEY" \
  "http://localhost:8000/v1/kpis/daily?date=$DATE"
```

**Résultat attendu:**
```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2026-01-20",
  "kpis": {
    "time_consumption": {
      "total_minutes": 75,
      "billable_minutes": 75,
      "non_billable_minutes": 0
    },
    "tech_efficiency": {
      "avg_resolution_minutes": null,
      "first_call_resolution_rate": null,
      "avg_satisfaction_score": null
    },
    "ticket_trends": {
      "tickets_created": 1,
      "tickets_closed": 1,
      "tickets_open": 0,
      "tickets_high_priority": 1,
      "anomaly_detected": false,
      "z_score": 0.0
    }
  }
}
```

### 10. Test GET /v1/tickets/{id}/summary

```bash
# Récupérer le résumé d'un ticket
TICKET_ID="TKT-001"
curl -H "X-API-Key: $API_KEY" \
  "http://localhost:8000/v1/tickets/$TICKET_ID/summary"
```

**Résultat attendu:**
```json
{
  "ticket_id": "TKT-001",
  "summary": "Cannot access email",
  "status": "Closed",
  "priority": "High",
  "company": "Acme Corp",
  "owner": "tech1@msp.com",
  "created_at": "2026-01-20T09:00:00+00:00",
  "ai_summary": "Mock summary for ticket TKT-001. This is a placeholder for LLM-generated summary."
}
```

### 11. Test POST /internal/exports/generate

```bash
# Générer un export Power BI
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://localhost:8000/internal/exports/generate?tenant_id=$TENANT_ID&date=$DATE"
```

**Résultat attendu:**
```json
{
  "message": "Export generated successfully",
  "export_data": {
    "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
    "tenant_name": "CCA Demo",
    "date": "2026-01-20",
    "kpis": {
      "time_consumption": {...},
      "ticket_trends": {...}
    }
  }
}
```

### 12. Vérification de l'isolation multi-tenant

```bash
# Vérifier que tenant_demo_client2 ne voit pas les données de tenant_demo_cca
TENANT2_ID="550e8400-e29b-41d4-a716-446655440001"
API_KEY_TENANT2="msp_ak_..."  # API key pour tenant 2

# Ingest pour tenant 2
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://localhost:8000/internal/ingest/tickets?tenant_id=$TENANT2_ID"

# Vérifier que tenant 2 ne voit que ses propres tickets
curl -H "X-API-Key: $API_KEY_TENANT2" \
  "http://localhost:8000/v1/tickets/TKT-001/summary"
# Devrait retourner 404 (ticket appartient à tenant 1)

curl -H "X-API-Key: $API_KEY_TENANT2" \
  "http://localhost:8000/v1/tickets/TKT-101/summary"
# Devrait retourner le ticket de tenant 2
```

## Vérification de la base de données

```bash
# Compter les tickets par tenant
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, COUNT(*) FROM raw_tickets GROUP BY tenant_id"

# Compter les time entries par tenant
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, COUNT(*) FROM raw_time_entries GROUP BY tenant_id"

# Vérifier les KPIs calculés
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, kpi_date, tickets_created, total_minutes FROM kpi_daily ORDER BY kpi_date DESC"
```
