# Commandes: Déploiement MVP sur Coolify

## ÉTAPE 1 — Vérification réseau Coolify

### 1.1 Identifier les Destinations

**Dans l'UI Coolify**:
- Aller dans "Destinations"
- Noter le nom du Destination utilisé par n8n et Postgres

**Via SSH (si nécessaire)**:
```bash
# Lister les réseaux Docker
docker network ls

# Inspecter le réseau utilisé par n8n
docker inspect <n8n_container_name> | grep -A 10 "Networks"
```

### 1.2 Vérifier la connectivité depuis n8n

**Via terminal Coolify (exec dans n8n container)**:
```bash
# Ping analytics-api (si déployé)
ping -c 3 analytics-api

# Test HTTP
curl -v http://analytics-api:8000/health
```

**Si analytics-api n'est pas encore déployé**:
- Noter le hostname prévu: `analytics-api`
- Vérifier que n8n et analytics-api seront sur le même Destination

### 1.3 Configurer "Connect to Predefined Networks" (si nécessaire)

**Dans Coolify**:
- Pour n8n: Settings → Networks → Activer "Connect to Predefined Networks" → Sélectionner le Destination
- Pour analytics-api: Même configuration

**Preuve**: Capture d'écran Coolify montrant les réseaux configurés

---

## ÉTAPE 2 — Variables d'environnement

### 2.1 Générer SERVICE_TOKEN sécurisé

```bash
# Sur le VPS
openssl rand -hex 32
# Exemple output: a1b2c3d4e5f6... (utiliser cette valeur)
```

### 2.2 Configurer dans Coolify

**Pour analytics-api service**:
- Aller dans Settings → Environment Variables
- Ajouter:

```env
MOCK_MODE=true
MOCK_DATA_PATH=/app/mock-data
SERVICE_TOKEN=<valeur_générée>
DATABASE_URL=postgresql://msp:password@postgres:5432/msp_analytics
JWT_SECRET_KEY=<générer_avec_openssl_rand_hex_64>
REDIS_URL=redis://redis:6379/1
EXPORTS_PATH=/app/exports
```

**Note**: Utiliser "Secrets" pour SERVICE_TOKEN, DATABASE_URL, JWT_SECRET_KEY

**Preuve**: Capture d'écran Coolify (valeurs masquées)

---

## ÉTAPE 3 — Volumes

### 3.1 Préparer les dossiers sur le VPS

```bash
# Créer les dossiers
sudo mkdir -p /data/msp-analytics/mock-data
sudo mkdir -p /data/msp-analytics/exports

# Copier mock-data depuis le repo
# (si le repo est cloné sur le VPS)
sudo cp -r /path/to/repo/mock-data/* /data/msp-analytics/mock-data/

# Donner les permissions appropriées
sudo chown -R 1000:1000 /data/msp-analytics/mock-data
sudo chown -R 1000:1000 /data/msp-analytics/exports
```

### 3.2 Configurer dans Coolify

**Pour analytics-api service**:
- Settings → Volumes
- Ajouter:
  - Source: `/data/msp-analytics/mock-data`
  - Destination: `/app/mock-data`
  - Mode: `ro` (read-only)
- Ajouter:
  - Source: `/data/msp-analytics/exports`
  - Destination: `/app/exports`
  - Mode: `rw` (read-write)

**Preuve**: Capture d'écran Coolify montrant les volumes

### 3.3 Vérifier les volumes montés

**Via terminal Coolify (exec dans analytics-api container)**:
```bash
# Vérifier que mock-data est accessible
ls -la /app/mock-data

# Vérifier le contenu
cat /app/mock-data/tenants.json

# Vérifier que exports est accessible
ls -la /app/exports
```

---

## ÉTAPE 4 — Migrations + Seed

### 4.1 Installer psql client

```bash
# Sur le VPS (SSH)
sudo apt-get update
sudo apt-get install -y postgresql-client
```

### 4.2 Récupérer DATABASE_URL

**Depuis Coolify**:
- Aller dans les settings de Postgres (ou analytics-api)
- Copier la valeur de `DATABASE_URL` ou construire:
  - Format: `postgresql://user:password@host:5432/database`
  - Exemple: `postgresql://msp:password@postgres:5432/msp_analytics`

### 4.3 Appliquer la migration

```bash
# Sur le VPS (SSH)
# Remplacer $DATABASE_URL par la valeur réelle
export DATABASE_URL="postgresql://msp:password@postgres:5432/msp_analytics"

# Télécharger le fichier de migration (si nécessaire)
# Ou copier depuis le repo cloné
psql "$DATABASE_URL" -f analytics-api/migrations/001_initial_schema.sql
```

**Vérification**:
```bash
# Lister les tables créées
psql "$DATABASE_URL" -c "\dt"

# Vérifier la structure de tenants
psql "$DATABASE_URL" -c "\d tenants"

# Vérifier la structure de raw_tickets
psql "$DATABASE_URL" -c "\d raw_tickets"
```

**Preuve**: Output de `\dt` et `\d <table>`

### 4.4 Seed les données mock

**Via terminal Coolify (exec dans analytics-api container)**:
```bash
# Exécuter le script de seed
python /app/seed_mock.py
```

**Output attendu**:
```
Loading tenants from /app/mock-data/tenants.json
Creating tenant: 550e8400-e29b-41d4-a716-446655440000 (CCA Demo)
Generating API key for tenant: 550e8400-e29b-41d4-a716-446655440000
API Key: msp_xxxxx...
...
Tenants seeded successfully!
```

**Vérification**:
```bash
# Depuis le VPS (SSH)
psql "$DATABASE_URL" -c "SELECT id, name, is_active FROM tenants;"
psql "$DATABASE_URL" -c "SELECT tenant_id, name FROM api_keys;"
```

**Preuve**: Output complet de seed_mock.py + requêtes DB

---

## ÉTAPE 5 — Tests API

### 5.1 Préparer les variables

```bash
# Depuis le VPS (SSH) ou terminal Coolify
export SERVICE_TOKEN="<valeur_depuis_coolify>"
export TENANT_UUID="550e8400-e29b-41d4-a716-446655440000"
export DATE_TODAY="2026-01-24"
```

### 5.2 Tests depuis n8n container

**Via terminal Coolify (exec dans n8n container)**:

```bash
# 1. Health check
curl -v http://analytics-api:8000/health

# 2. Liste des tenants
curl -v -H "Authorization: Bearer $SERVICE_TOKEN" \
  http://analytics-api:8000/internal/tenants

# 3. Ingestion tickets
curl -v -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://analytics-api:8000/internal/ingest/tickets?tenant_id=$TENANT_UUID"

# 4. Ingestion time entries
curl -v -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://analytics-api:8000/internal/ingest/time_entries?tenant_id=$TENANT_UUID"

# 5. Compute KPIs
curl -v -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://analytics-api:8000/internal/kpi/compute-daily?tenant_id=$TENANT_UUID&date=$DATE_TODAY"

# 6. Vérifier les données ingérées
# (depuis le VPS)
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM raw_tickets WHERE tenant_id='$TENANT_UUID';"
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM raw_time_entries WHERE tenant_id='$TENANT_UUID';"
psql "$DATABASE_URL" -c "SELECT * FROM kpi_daily WHERE tenant_id='$TENANT_UUID' ORDER BY kpi_date DESC LIMIT 1;"
```

### 5.3 Test Public API (avec API Key)

**Récupérer l'API key**:
```bash
# Depuis la DB ou le output de seed_mock.py
psql "$DATABASE_URL" -c "SELECT key_hash FROM api_keys LIMIT 1;"
# Note: On ne peut pas récupérer la clé en clair depuis la DB (elle est hashée)
# Utiliser la valeur affichée par seed_mock.py
```

**Tester**:
```bash
# Remplacer <API_KEY> par la valeur depuis seed_mock.py output
export API_KEY="<API_KEY>"

curl -v -H "X-API-Key: $API_KEY" \
  "http://analytics-api:8000/v1/kpis/daily?date=$DATE_TODAY"
```

**Preuve**: Outputs de tous les curl avec codes HTTP 200/201

---

## ÉTAPE 6 — n8n Credentials (manuel UI)

### 6.1 Créer le credential

**Dans l'UI n8n**:
1. Aller dans "Credentials" (menu latéral)
2. Cliquer sur "Add Credential"
3. Rechercher "Header Auth"
4. Remplir:
   - Name: `Analytics API Service Token`
   - Header Name: `Authorization`
   - Header Value: `Bearer <SERVICE_TOKEN>` (même valeur que dans Coolify)
5. Sauvegarder

**Preuve**: Capture d'écran du credential créé (token masqué)

### 6.2 Associer aux nodes HTTP Request

**Pour chaque workflow**:

**WF-01 - Node "Get Tenants"**:
- Ouvrir WF-01
- Cliquer sur "Get Tenants"
- Authentication: "Predefined Credential Type"
- Credential Type: "Header Auth"
- Credential: "Analytics API Service Token"
- Sauvegarder

**WF-01A - Node "Call Ingest API"**:
- Même procédure

**WF-01B - Node "Call Ingest API"**:
- Même procédure

**WF-10 - Node "Compute KPIs"**:
- Même procédure

**WF-20 - Node "Generate Exports"**:
- Même procédure

**Preuve**: Captures d'écran de chaque node configuré

---

## ÉTAPE 7 — Exécution workflows

### 7.1 WF-01 Orchestrator Ingestion

**Dans l'UI n8n**:
1. Ouvrir WF-01
2. Cliquer sur "Execute Workflow" (bouton play)
3. Attendre la fin de l'exécution

**Vérifications**:
```bash
# Depuis le VPS (SSH)
psql "$DATABASE_URL" -c "SELECT tenant_id, COUNT(*) as count FROM raw_tickets GROUP BY tenant_id;"
psql "$DATABASE_URL" -c "SELECT tenant_id, COUNT(*) as count FROM raw_time_entries GROUP BY tenant_id;"
```

**Preuve**: 
- Output n8n (succès)
- Logs analytics-api (via Coolify)
- Requêtes DB montrant les données ingérées

### 7.2 WF-10 Daily KPI Compute

**Dans l'UI n8n**:
1. Ouvrir WF-10
2. Exécuter manuellement

**Vérifications**:
```bash
psql "$DATABASE_URL" -c "SELECT tenant_id, kpi_date, tickets_created, total_minutes FROM kpi_daily ORDER BY kpi_date DESC LIMIT 10;"
```

**Preuve**: Output n8n + requête DB

### 7.3 WF-20 Export Power BI

**Dans l'UI n8n**:
1. Ouvrir WF-20
2. Exécuter manuellement

**Vérifications**:
```bash
# Via terminal Coolify (exec dans analytics-api container)
ls -la /app/exports/
cat /app/exports/*.json  # ou .csv selon le format
```

**Preuve**: Output n8n + liste des fichiers exports

---

## Commandes de vérification complète

### Vérifier l'état des services

```bash
# Depuis le VPS
docker ps | grep -E "(n8n|analytics-api|postgres)"

# Vérifier les logs analytics-api
docker logs msp-analytics-api --tail=50

# Vérifier les logs n8n
docker logs msp-n8n --tail=50
```

### Vérifier la connectivité réseau

```bash
# Depuis n8n container
docker exec msp-n8n ping -c 3 analytics-api
docker exec msp-n8n curl -v http://analytics-api:8000/health

# Depuis analytics-api container
docker exec msp-analytics-api ping -c 3 postgres
docker exec msp-analytics-api psql "$DATABASE_URL" -c "SELECT 1;"
```

### Vérifier les volumes

```bash
# Depuis analytics-api container
docker exec msp-analytics-api ls -la /app/mock-data/
docker exec msp-analytics-api ls -la /app/exports/
```

### Vérifier les données DB

```bash
# Depuis le VPS
psql "$DATABASE_URL" <<EOF
\dt
SELECT COUNT(*) FROM tenants;
SELECT COUNT(*) FROM api_keys;
SELECT COUNT(*) FROM raw_tickets;
SELECT COUNT(*) FROM raw_time_entries;
SELECT COUNT(*) FROM kpi_daily;
EOF
```
