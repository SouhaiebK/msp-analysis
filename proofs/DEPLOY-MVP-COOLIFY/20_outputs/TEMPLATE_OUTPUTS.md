# Template pour les outputs attendus

Ce fichier décrit le format attendu pour chaque fichier de preuve dans `20_outputs/`.

## network_verification.txt

```bash
# Vérification réseau depuis n8n container
$ docker exec msp-n8n ping -c 3 analytics-api
PING analytics-api (172.18.0.5) 56(84) bytes of data.
64 bytes from analytics-api (172.18.0.5): icmp_seq=1 ttl=64 time=0.123 ms
64 bytes from analytics-api (172.18.0.5): icmp_seq=2 ttl=64 time=0.098 ms
64 bytes from analytics-api (172.18.0.5): icmp_seq=3 ttl=64 time=0.105 ms

$ docker exec msp-n8n curl -v http://analytics-api:8000/health
*   Trying 172.18.0.5:8000...
* Connected to analytics-api (172.18.0.5) port 8000
> GET /health HTTP/1.1
> Host: analytics-api:8000
< HTTP/1.1 200 OK
{"status":"healthy"}
```

## migration_output.txt

```bash
$ psql "$DATABASE_URL" -f analytics-api/migrations/001_initial_schema.sql
CREATE EXTENSION
CREATE TABLE
CREATE TABLE
CREATE INDEX
...

$ psql "$DATABASE_URL" -c "\dt"
                    List of relations
 Schema |      Name       | Type  | Owner
--------+-----------------+-------+-------
 public | tenants         | table | msp
 public | api_keys        | table | msp
 public | raw_tickets      | table | msp
 public | raw_time_entries | table | msp
 public | kpi_daily       | table | msp
```

## seed_output.txt

```bash
$ python /app/seed_mock.py
Loading tenants from /app/mock-data/tenants.json
Creating tenant: 550e8400-e29b-41d4-a716-446655440000 (CCA Demo)
Generating API key for tenant: 550e8400-e29b-41d4-a716-446655440000
API Key: msp_550e8400_abc123...
Creating tenant: 550e8400-e29b-41d4-a716-446655440001 (Client 2 Demo)
Generating API key for tenant: 550e8400-e29b-41d4-a716-446655440001
API Key: msp_550e8400_def456...

Tenants seeded successfully!
```

## api_tests.txt

```bash
# 1. Health check
$ curl -v http://analytics-api:8000/health
HTTP/1.1 200 OK
{"status":"healthy"}

# 2. Liste tenants
$ curl -H "Authorization: Bearer $SERVICE_TOKEN" http://analytics-api:8000/internal/tenants
HTTP/1.1 200 OK
[{"id":"550e8400-e29b-41d4-a716-446655440000","name":"CCA Demo",...}]

# 3. Ingestion tickets
$ curl -X POST -H "Authorization: Bearer $SERVICE_TOKEN" "http://analytics-api:8000/internal/ingest/tickets?tenant_id=550e8400-e29b-41d4-a716-446655440000"
HTTP/1.1 200 OK
{"message":"Tickets ingested successfully","ingested":5}

# 4. Ingestion time entries
$ curl -X POST -H "Authorization: Bearer $SERVICE_TOKEN" "http://analytics-api:8000/internal/ingest/time_entries?tenant_id=550e8400-e29b-41d4-a716-446655440000"
HTTP/1.1 200 OK
{"message":"Time entries ingested successfully","ingested":10}

# 5. Compute KPIs
$ curl -X POST -H "Authorization: Bearer $SERVICE_TOKEN" "http://analytics-api:8000/internal/kpi/compute-daily?tenant_id=550e8400-e29b-41d4-a716-446655440000&date=2026-01-24"
HTTP/1.1 200 OK
{"message":"KPIs computed successfully","kpis_created":1}
```

## db_verification.txt

```bash
$ psql "$DATABASE_URL" -c "SELECT tenant_id, COUNT(*) as count FROM raw_tickets GROUP BY tenant_id;"
           tenant_id            | count
-------------------------------+-------
 550e8400-e29b-41d4-a716-446655440000 |     5
 550e8400-e29b-41d4-a716-446655440001 |     2

$ psql "$DATABASE_URL" -c "SELECT tenant_id, kpi_date, tickets_created, total_minutes FROM kpi_daily ORDER BY kpi_date DESC LIMIT 5;"
           tenant_id            |  kpi_date  | tickets_created | total_minutes
-------------------------------+------------+-----------------+---------------
 550e8400-e29b-41d4-a716-446655440000 | 2026-01-24 |               5 |           480
```

## wf01_execution.json

```json
{
  "workflow": "WF-01 Orchestrator Ingestion",
  "execution_id": "12345",
  "status": "success",
  "started_at": "2026-01-25T10:00:00Z",
  "finished_at": "2026-01-25T10:00:15Z",
  "nodes_executed": [
    {
      "name": "Get Tenants",
      "status": "success",
      "output": [{"id": "550e8400-e29b-41d4-a716-446655440000", "name": "CCA Demo"}]
    },
    {
      "name": "Ingest Tickets",
      "status": "success",
      "output": {"message": "Tickets ingested successfully", "ingested": 5}
    },
    {
      "name": "Ingest Time",
      "status": "success",
      "output": {"message": "Time entries ingested successfully", "ingested": 10}
    }
  ]
}
```

## Captures d'écran

### coolify_variables.png
- Capture de l'écran Coolify montrant les variables d'environnement configurées
- Les valeurs sensibles (SERVICE_TOKEN, DATABASE_URL) doivent être masquées

### coolify_volumes.png
- Capture de l'écran Coolify montrant les volumes montés
- Doit montrer:
  - `/data/msp-analytics/mock-data` → `/app/mock-data` (ro)
  - `/data/msp-analytics/exports` → `/app/exports` (rw)

### n8n_credentials.png
- Capture de l'écran n8n montrant le credential "Analytics API Service Token" créé
- Le token doit être masqué (ex: `Bearer ********`)
