# Plan: Gate 12A - Workflows n8n opérationnels contre Analytics API en MOCK_MODE

## Objectif

Fermer Gate-12A en rendant les workflows n8n opérationnels contre l'API Analytics en mode MOCK.

## Prérequis

- ✅ Gate 8+9 PASS (API interne répond)
- ✅ SERVICE_TOKEN connu (depuis .env)
- ✅ Workflows existent:
  - WF-00: `bkGuLTagD6Bk3Lwn` (Global Error Handler)
  - WF-01: `NKCbs5jW7uf4heK4` (Orchestrator Ingestion)
  - WF-01A: `jZFWavySR2ODw8C0` (Ingest Tickets)
  - WF-01B: `tXU9wCYyU089bLdh` (Ingest Time Entries)
  - WF-10: `8ds5mUQh9tJPWUKR` (Daily KPI Compute)
  - WF-20: `fge3tLFsO5hbBmhA` (Export Power BI)

## Étapes

### A) Câbler Error Workflow ✅

Pour WF-01, WF-01A, WF-01B, WF-10, WF-20:
- Workflow Settings -> Error workflow = WF-00 (`bkGuLTagD6Bk3Lwn`)
- Utilisé `n8n_update_partial_workflow` avec opération `updateSettings`

**Status**: ✅ Complété via MCP

### B) Credentials

**Limitation MCP**: La création de credentials n'est pas disponible via MCP n8n. Les credentials doivent être créés manuellement dans l'UI n8n.

**Action requise**:
1. Dans l'UI n8n (http://localhost:5678 ou https://n8n.76.13.98.217.sslip.io):
   - Aller dans Credentials
   - Créer un nouveau credential de type "Header Auth"
   - Nom: "Analytics API Service Token"
   - Header Name: `Authorization`
   - Header Value: `Bearer <SERVICE_TOKEN>` (remplacer par la valeur depuis .env)
   - Sauvegarder

2. Associer ce credential à tous les nodes HTTP Request:
   - WF-01: Node "Get Tenants"
   - WF-01A: Node "Call Ingest API"
   - WF-01B: Node "Call Ingest API"
   - WF-10: Node "Compute KPIs"
   - WF-20: Node "Generate Exports"

**Note**: Cette étape nécessite l'accès à l'UI n8n. Les nodes peuvent être mis à jour via MCP une fois le credential créé.

### C) Vérifier WF-01 Execute Workflow IDs ✅

- Node "Ingest Tickets" workflowId = `jZFWavySR2ODw8C0` ✅
- Node "Ingest Time" workflowId = `tXU9wCYyU089bLdh` ✅

**Status**: ✅ Vérifié - IDs corrects

### D) Activation + Tests

1. **Activer WF-10** et exécuter manuellement
   - Doit appeler `/internal/kpi/compute-daily`
   - Vérifier les logs analytics-api
   - Vérifier les données dans `kpi_daily`

2. **Activer WF-01** et exécuter manuellement
   - Doit boucler sur les tenants
   - Doit appeler `/internal/ingest/tickets` pour chaque tenant
   - Doit appeler `/internal/ingest/time_entries` pour chaque tenant
   - Vérifier les données dans `raw_tickets` et `raw_time_entries`

## Preuves attendues

- Captures UI n8n (error workflow configuré, credentials créés)
- Exports JSON des workflows (post-configuration)
- Outputs des exécutions manuelles
- Logs analytics-api
- Requêtes DB (counts par tenant)
