# Plan: Déploiement MVP sur VPS Ubuntu 24.04 avec Coolify

## Objectif

Déployer le MVP de la plateforme MSP Analytics sur un VPS Ubuntu 24.04 avec Coolify, permettant à n8n d'appeler analytics-api en mode MOCK pour ingérer des données et calculer des KPIs.

## Architecture cible

```
┌─────────────────┐
│   n8n (Coolify) │
│   Port: 5678    │
└────────┬────────┘
         │ HTTP (hostname interne)
         │ http://analytics-api:8000
         ▼
┌─────────────────┐
│ analytics-api   │
│ (Coolify)       │
│ Port: 8000      │
└────────┬────────┘
         │ PostgreSQL
         ▼
┌─────────────────┐
│   Postgres       │
│   (Coolify)      │
│   Port: 5432    │
└─────────────────┘
```

## Prérequis

- ✅ VPS Ubuntu 24.04 avec Coolify installé
- ✅ Postgres déployé sur Coolify (ou externe)
- ✅ n8n déployé sur Coolify
- ✅ Accès SSH au VPS
- ✅ Accès à l'UI Coolify
- ✅ Accès à l'UI n8n

## Étapes de déploiement

### ÉTAPE 1 — Vérifier réseau Coolify ⚠️ CRITIQUE

**Objectif**: S'assurer que n8n et analytics-api peuvent communiquer via hostname interne.

**Actions**:
1. Identifier le Destination utilisé par n8n et Postgres
2. Vérifier si analytics-api sera dans la même "Destination network"
3. Si n8n et analytics-api sont des "service stacks" séparées:
   - Activer "Connect to Predefined Networks" pour les deux stacks sur le même Destination
   - Vérifier que les conteneurs se ping par hostname

**Vérifications**:
- Depuis n8n container: `curl http://analytics-api:8000/health`
- Depuis analytics-api container: `ping postgres` (si dans même réseau)

**Preuves**: Captures d'écran Coolify (réseaux) + outputs curl/ping

### ÉTAPE 2 — Variables & secrets (Coolify)

**Objectif**: Configurer toutes les variables d'environnement nécessaires pour analytics-api.

**Variables à configurer**:
- `MOCK_MODE=true`
- `MOCK_DATA_PATH=/app/mock-data`
- `SERVICE_TOKEN=<secret fort>` (générer un token sécurisé)
- `DATABASE_URL=postgresql://user:password@postgres:5432/msp_analytics`
- `EXPORTS_PATH=/app/exports` (optionnel)
- `JWT_SECRET_KEY=<secret>` (pour les endpoints /v1/*)
- `REDIS_URL=redis://redis:6379/1` (si Redis utilisé)

**Méthode Coolify**:
- Aller dans les settings de analytics-api
- Section "Environment Variables"
- Ajouter chaque variable
- Utiliser "Secrets" pour les valeurs sensibles (SERVICE_TOKEN, DATABASE_URL, JWT_SECRET_KEY)

**Preuves**: Capture d'écran Coolify montrant les variables configurées (valeurs masquées)

### ÉTAPE 3 — Volumes

**Objectif**: Monter les dossiers mock-data et exports dans le conteneur analytics-api.

**Volumes à monter**:
1. `mock-data` → `/app/mock-data` (lecture seule, ro)
2. `exports` → `/app/exports` (lecture/écriture, persistant)

**Méthode Coolify**:
- Dans les settings de analytics-api
- Section "Volumes"
- Ajouter:
  - Source: `/path/to/mock-data` (sur le VPS)
  - Destination: `/app/mock-data`
  - Mode: `ro` (read-only)
- Ajouter:
  - Source: `/path/to/exports` (sur le VPS)
  - Destination: `/app/exports`
  - Mode: `rw` (read-write)

**Note**: Les chemins sur le VPS doivent exister et contenir les données mock.

**Preuves**: Capture d'écran Coolify montrant les volumes montés

### ÉTAPE 4 — Migrations + seed

**Objectif**: Créer le schéma de base de données et peupler les tables initiales.

**4.1 Installer psql client (sur VPS)**:
```bash
sudo apt-get update
sudo apt-get install -y postgresql-client
```

**4.2 Appliquer la migration**:
```bash
# Récupérer DATABASE_URL depuis Coolify
psql "$DATABASE_URL" -f analytics-api/migrations/001_initial_schema.sql
```

**4.3 Seed les données mock**:
```bash
# Via terminal Coolify (exec dans le conteneur analytics-api)
python /app/seed_mock.py
```

**Vérifications**:
```bash
# Vérifier les tables créées
psql "$DATABASE_URL" -c "\dt"

# Vérifier les tenants seedés
psql "$DATABASE_URL" -c "SELECT id, name FROM tenants;"

# Vérifier les API keys générées
psql "$DATABASE_URL" -c "SELECT tenant_id, name FROM api_keys;"
```

**Preuves**: Outputs des commandes psql et seed_mock.py

### ÉTAPE 5 — Tests API

**Objectif**: Vérifier que l'API répond correctement et que l'authentification fonctionne.

**Tests depuis n8n container (ou host)**:

1. **Health check**:
```bash
curl http://analytics-api:8000/health
```

2. **Liste des tenants** (avec SERVICE_TOKEN):
```bash
curl -H "Authorization: Bearer $SERVICE_TOKEN" \
  http://analytics-api:8000/internal/tenants
```

3. **Ingestion tickets**:
```bash
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://analytics-api:8000/internal/ingest/tickets?tenant_id=550e8400-e29b-41d4-a716-446655440000"
```

4. **Ingestion time entries**:
```bash
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://analytics-api:8000/internal/ingest/time_entries?tenant_id=550e8400-e29b-41d4-a716-446655440000"
```

5. **Compute KPIs**:
```bash
curl -X POST \
  -H "Authorization: Bearer $SERVICE_TOKEN" \
  "http://analytics-api:8000/internal/kpi/compute-daily?tenant_id=550e8400-e29b-41d4-a716-446655440000&date=2026-01-24"
```

6. **Public API (avec API Key)**:
```bash
# Récupérer l'API key depuis la DB ou seed_mock.py output
curl -H "X-API-Key: <TENANT_API_KEY>" \
  "http://analytics-api:8000/v1/kpis/daily?date=2026-01-24"
```

**Preuves**: Outputs de tous les curl avec codes de retour 200/201

### ÉTAPE 6 — n8n Credentials (manuel UI)

**Objectif**: Configurer l'authentification dans n8n pour appeler analytics-api.

**Actions**:
1. Dans l'UI n8n, aller dans Credentials
2. Créer un nouveau credential de type "Header Auth":
   - Name: `Analytics API Service Token`
   - Header Name: `Authorization`
   - Header Value: `Bearer <SERVICE_TOKEN>` (même valeur que dans Coolify)
3. Associer ce credential à tous les nodes HTTP Request:
   - WF-01: Node "Get Tenants"
   - WF-01A: Node "Call Ingest API"
   - WF-01B: Node "Call Ingest API"
   - WF-10: Node "Compute KPIs"
   - WF-20: Node "Generate Exports"

**Preuves**: Captures d'écran n8n (credential créé, nodes configurés, token masqué)

### ÉTAPE 7 — Exécution workflows

**Objectif**: Vérifier que les workflows s'exécutent correctement en mode manuel.

**Tests**:

1. **WF-01 Orchestrator Ingestion**:
   - Exécuter manuellement
   - Vérifier: boucle sur tenants, appelle /internal/ingest/tickets et /internal/ingest/time_entries
   - Vérifier les données dans DB: `SELECT COUNT(*) FROM raw_tickets;`

2. **WF-10 Daily KPI Compute**:
   - Exécuter manuellement
   - Vérifier: appelle /internal/kpi/compute-daily pour chaque tenant
   - Vérifier les données dans DB: `SELECT * FROM kpi_daily ORDER BY kpi_date DESC LIMIT 5;`

3. **WF-20 Export Power BI**:
   - Exécuter manuellement
   - Vérifier: appelle /internal/exports/generate
   - Vérifier les fichiers dans `/app/exports`

**Preuves**: 
- Outputs n8n (succès des exécutions)
- Logs analytics-api (via Coolify logs)
- Requêtes DB montrant les données ingérées

## Critères de succès

✅ **PASS** si:
- n8n peut appeler analytics-api via hostname interne
- Tous les tests API retournent 200/201
- Les workflows s'exécutent sans erreur
- Les données sont ingérées dans la DB
- Les KPIs sont calculés

❌ **BLOCKED** si:
- Problème de réseau (n8n ne peut pas joindre analytics-api)
- Erreurs d'authentification (SERVICE_TOKEN incorrect)
- Erreurs de connexion DB (DATABASE_URL incorrect)
- Volumes non montés (mock-data non accessible)
- Migrations non appliquées (tables manquantes)

## Structure des preuves

```
proofs/DEPLOY-MVP-COOLIFY/
├── 00_plan.md              (ce fichier)
├── 10_commands.md           (toutes les commandes)
├── 20_outputs/
│   ├── network_verification.txt
│   ├── coolify_variables.png
│   ├── coolify_volumes.png
│   ├── migration_output.txt
│   ├── seed_output.txt
│   ├── api_tests.txt
│   ├── n8n_credentials.png
│   ├── wf01_execution.json
│   ├── wf10_execution.json
│   ├── wf20_execution.json
│   └── db_verification.txt
└── 40_verdict.md            (PASS/BLOCKED + raisons)
```
