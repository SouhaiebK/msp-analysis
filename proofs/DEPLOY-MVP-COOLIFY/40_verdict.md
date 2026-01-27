# Verdict: Déploiement MVP sur Coolify

## Date: [À COMPLÉTER APRÈS DÉPLOIEMENT]

## Résumé

**STATUS: ⏳ EN ATTENTE**

Ce verdict sera complété après l'exécution du déploiement selon le plan dans `00_plan.md` et les commandes dans `10_commands.md`.

## Checklist de validation

### ÉTAPE 1 — Réseau Coolify
- [ ] Destination identifié pour n8n et Postgres
- [ ] analytics-api configuré sur le même Destination
- [ ] "Connect to Predefined Networks" activé si nécessaire
- [ ] Test de connectivité: `curl http://analytics-api:8000/health` depuis n8n ✅

**Preuve**: `20_outputs/network_verification.txt`

### ÉTAPE 2 — Variables & secrets
- [ ] MOCK_MODE=true configuré
- [ ] MOCK_DATA_PATH=/app/mock-data configuré
- [ ] SERVICE_TOKEN configuré (secret fort)
- [ ] DATABASE_URL configuré correctement
- [ ] JWT_SECRET_KEY configuré
- [ ] Autres variables nécessaires configurées

**Preuve**: `20_outputs/coolify_variables.png`

### ÉTAPE 3 — Volumes
- [ ] mock-data monté en lecture seule
- [ ] exports monté en lecture/écriture
- [ ] Vérification: `ls -la /app/mock-data` dans le conteneur ✅
- [ ] Vérification: `ls -la /app/exports` dans le conteneur ✅

**Preuve**: `20_outputs/coolify_volumes.png`

### ÉTAPE 4 — Migrations + seed
- [ ] psql client installé sur le VPS
- [ ] Migration appliquée: `001_initial_schema.sql` ✅
- [ ] Tables créées vérifiées: `\dt` ✅
- [ ] Seed exécuté: `python /app/seed_mock.py` ✅
- [ ] Tenants créés vérifiés: `SELECT * FROM tenants;` ✅
- [ ] API keys générées vérifiées: `SELECT * FROM api_keys;` ✅

**Preuves**: 
- `20_outputs/migration_output.txt`
- `20_outputs/seed_output.txt`

### ÉTAPE 5 — Tests API
- [ ] Health check: `curl http://analytics-api:8000/health` → 200 ✅
- [ ] Liste tenants: `curl -H "Authorization: Bearer $SERVICE_TOKEN" /internal/tenants` → 200 ✅
- [ ] Ingestion tickets: `POST /internal/ingest/tickets?tenant_id=...` → 200 ✅
- [ ] Ingestion time entries: `POST /internal/ingest/time_entries?tenant_id=...` → 200 ✅
- [ ] Compute KPIs: `POST /internal/kpi/compute-daily?tenant_id=...&date=...` → 200 ✅
- [ ] Public API: `GET /v1/kpis/daily?date=...` avec X-API-Key → 200 ✅

**Preuve**: `20_outputs/api_tests.txt`

### ÉTAPE 6 — n8n Credentials
- [ ] Credential "Header Auth" créé dans n8n
- [ ] Credential associé à WF-01 "Get Tenants" ✅
- [ ] Credential associé à WF-01A "Call Ingest API" ✅
- [ ] Credential associé à WF-01B "Call Ingest API" ✅
- [ ] Credential associé à WF-10 "Compute KPIs" ✅
- [ ] Credential associé à WF-20 "Generate Exports" ✅

**Preuve**: `20_outputs/n8n_credentials.png`

### ÉTAPE 7 — Exécution workflows
- [ ] WF-01 exécuté manuellement → Succès ✅
  - Boucle sur tenants ✅
  - Appelle /internal/ingest/tickets ✅
  - Appelle /internal/ingest/time_entries ✅
  - Données dans raw_tickets ✅
  - Données dans raw_time_entries ✅
- [ ] WF-10 exécuté manuellement → Succès ✅
  - Appelle /internal/kpi/compute-daily ✅
  - Données dans kpi_daily ✅
- [ ] WF-20 exécuté manuellement → Succès ✅
  - Appelle /internal/exports/generate ✅
  - Fichiers créés dans /app/exports ✅

**Preuves**:
- `20_outputs/wf01_execution.json`
- `20_outputs/wf10_execution.json`
- `20_outputs/wf20_execution.json`
- `20_outputs/db_verification.txt`

## Résultat final

### ✅ PASS si:
- Toutes les étapes sont complétées avec succès
- n8n peut appeler analytics-api via hostname interne
- Tous les tests API retournent 200/201
- Les workflows s'exécutent sans erreur
- Les données sont ingérées et les KPIs calculés

### ❌ BLOCKED si:
- Problème de réseau (n8n ne peut pas joindre analytics-api)
- Erreurs d'authentification (SERVICE_TOKEN incorrect)
- Erreurs de connexion DB (DATABASE_URL incorrect)
- Volumes non montés (mock-data non accessible)
- Migrations non appliquées (tables manquantes)
- Workflows échouent avec erreurs

## Bloqueurs identifiés

[Liste des bloqueurs rencontrés, le cas échéant]

## Solutions appliquées

[Liste des solutions appliquées pour résoudre les bloqueurs]

## Notes importantes

[Notes sur le déploiement, points d'attention, améliorations futures]

## Prochaines étapes

1. [Si PASS] Automatiser les déploiements futurs
2. [Si PASS] Configurer les cron jobs dans n8n
3. [Si BLOCKED] Résoudre les bloqueurs identifiés
4. [Si BLOCKED] Réessayer le déploiement

---

**Verdict final**: [PASS / BLOCKED]

**Date**: [À COMPLÉTER]

**Validé par**: [À COMPLÉTER]
