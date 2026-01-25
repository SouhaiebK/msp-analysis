# 50 - Intégration MCP n8n

## Vue d'Ensemble

Cursor a accès direct à n8n via MCP (Model Context Protocol). Cela permet de:
- **Créer des workflows** directement depuis Cursor
- **Lister les workflows** existants
- **Modifier/activer/désactiver** des workflows
- **Exécuter des workflows** manuellement

```
⚡ AVANTAGE: Pas besoin d'export JSON manuel ni d'import via l'UI n8n.
   Cursor peut créer et déployer les workflows en temps réel.
```

## Configuration MCP

### Serveur MCP n8n
```
URL: http://n8n.76.13.98.217.sslip.io/mcp-server/http
Type: url
Name: n8n-mcp
```

### Outils Disponibles via MCP

| Outil | Description |
|-------|-------------|
| `workflow_list` | Liste tous les workflows |
| `workflow_get` | Récupère un workflow par ID |
| `workflow_create` | Crée un nouveau workflow |
| `workflow_update` | Met à jour un workflow existant |
| `workflow_delete` | Supprime un workflow |
| `workflow_activate` | Active un workflow |
| `workflow_deactivate` | Désactive un workflow |
| `workflow_execute` | Exécute un workflow manuellement |
| `credentials_list` | Liste les credentials disponibles |

## Workflows à Créer via MCP

### WF-00: Global Error Handler
```json
{
  "name": "WF-00 Global Error Handler",
  "nodes": [
    {
      "type": "n8n-nodes-base.errorTrigger",
      "name": "Error Trigger"
    },
    {
      "type": "n8n-nodes-base.slack",
      "name": "Notify Slack",
      "parameters": {
        "channel": "#msp-alerts",
        "text": "🚨 Workflow Error: {{ $json.workflow.name }}\nNode: {{ $json.execution.error.node }}\nMessage: {{ $json.execution.error.message }}"
      }
    }
  ]
}
```

### WF-01: Orchestrator Ingestion
```json
{
  "name": "WF-01 Orchestrator Ingestion",
  "nodes": [
    {
      "type": "n8n-nodes-base.scheduleTrigger",
      "name": "Every 15 min",
      "parameters": {
        "rule": { "interval": [{ "field": "minutes", "minutesInterval": 15 }] }
      }
    },
    {
      "type": "n8n-nodes-base.httpRequest",
      "name": "Get Tenants",
      "parameters": {
        "url": "http://analytics-api:8000/internal/tenants",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "httpHeaderAuth"
      }
    },
    {
      "type": "n8n-nodes-base.splitInBatches",
      "name": "Loop Tenants"
    },
    {
      "type": "n8n-nodes-base.executeWorkflow",
      "name": "Ingest Tickets",
      "parameters": { "workflowId": "WF-01A" }
    }
  ]
}
```

### WF-01A: Ingest Tickets (Sub-workflow)
```json
{
  "name": "WF-01A Ingest Tickets",
  "nodes": [
    {
      "type": "n8n-nodes-base.executeWorkflowTrigger",
      "name": "Trigger"
    },
    {
      "type": "n8n-nodes-base.httpRequest",
      "name": "Call Ingest API",
      "parameters": {
        "method": "POST",
        "url": "http://analytics-api:8000/internal/ingest/tickets",
        "authentication": "predefinedCredentialType",
        "body": {
          "tenant_id": "={{ $json.tenant_id }}"
        }
      }
    }
  ]
}
```

### WF-10: Daily KPI Compute
```json
{
  "name": "WF-10 Daily KPI Compute",
  "nodes": [
    {
      "type": "n8n-nodes-base.scheduleTrigger",
      "name": "Daily 6h00",
      "parameters": {
        "rule": { "interval": [{ "field": "cronExpression", "expression": "0 6 * * *" }] }
      }
    },
    {
      "type": "n8n-nodes-base.httpRequest",
      "name": "Compute KPIs",
      "parameters": {
        "method": "POST",
        "url": "http://analytics-api:8000/internal/kpi/compute-daily",
        "body": {
          "date": "={{ $now.minus({days: 1}).toFormat('yyyy-MM-dd') }}"
        }
      }
    }
  ]
}
```

### WF-20: Export Power BI
```json
{
  "name": "WF-20 Export Power BI",
  "nodes": [
    {
      "type": "n8n-nodes-base.scheduleTrigger",
      "name": "Daily 7h30",
      "parameters": {
        "rule": { "interval": [{ "field": "cronExpression", "expression": "30 7 * * *" }] }
      }
    },
    {
      "type": "n8n-nodes-base.httpRequest",
      "name": "Generate Exports",
      "parameters": {
        "method": "POST",
        "url": "http://analytics-api:8000/internal/exports/generate"
      }
    }
  ]
}
```

## Prompts Cursor pour Créer les Workflows

### Prompt: Créer tous les workflows MVP
```
MISSION: Créer les workflows n8n pour le MVP via MCP.

Tu as accès au serveur MCP n8n. Utilise-le pour:

1. Lister les workflows existants (workflow_list)
2. Créer les workflows suivants:
   - WF-00 Global Error Handler
   - WF-01 Orchestrator Ingestion (cron 15 min)
   - WF-01A Ingest Tickets (sub-workflow)
   - WF-01B Ingest Time Entries (sub-workflow)
   - WF-10 Daily KPI Compute (cron 6h00)
   - WF-20 Export Power BI (cron 7h30)

3. Configurer les credentials nécessaires:
   - HTTP Header Auth pour SERVICE_TOKEN
   
4. Activer les workflows

Réfère-toi à docs/context/50_MCP_N8N.md pour les specs des workflows.

Sauvegarde les preuves dans proofs/GATE-12-WORKFLOWS/:
- Liste des workflows créés
- IDs des workflows
- Status d'activation
```

### Prompt: Vérifier les workflows
```
MISSION: Vérifier l'état des workflows n8n.

Via MCP n8n:
1. Liste tous les workflows (workflow_list)
2. Pour chaque workflow WF-*, vérifie:
   - Est-il actif?
   - Dernière exécution?
   - Erreurs récentes?

Produis un rapport dans proofs/GATE-12-WORKFLOWS/40_verdict.md
```

### Prompt: Exécuter un workflow manuellement
```
MISSION: Tester le workflow WF-01 manuellement.

Via MCP n8n:
1. Récupère le workflow WF-01 (workflow_get)
2. Exécute-le (workflow_execute)
3. Vérifie le résultat

Sauvegarde l'output dans proofs/GATE-12-WORKFLOWS/20_outputs/wf01_test.json
```

## Bonnes Pratiques MCP n8n

### 1. Toujours vérifier avant de créer
```
Avant de créer un workflow, utilise workflow_list pour vérifier 
qu'il n'existe pas déjà (éviter les doublons).
```

### 2. Nommer de façon consistante
```
Convention: WF-XX <Nom Descriptif>
Exemples:
- WF-00 Global Error Handler
- WF-01 Orchestrator Ingestion
- WF-01A Ingest Tickets
```

### 3. Tester avant d'activer
```
1. Créer le workflow (désactivé par défaut)
2. Exécuter manuellement (workflow_execute)
3. Vérifier les résultats
4. Activer si OK (workflow_activate)
```

### 4. Gérer les credentials
```
Les credentials sensibles (API keys, tokens) doivent être 
configurés dans n8n UI, pas via MCP.
MCP peut les référencer mais pas les créer avec des valeurs sensibles.
```

## Architecture Workflows

```
┌─────────────────────────────────────────────────────────────┐
│                    WF-00 Error Handler                       │
│                    (reçoit toutes les erreurs)               │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ erreurs
┌─────────────────────────────┴───────────────────────────────┐
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   WF-01      │    │   WF-10      │    │   WF-20      │  │
│  │ Orchestrator │    │  KPI Daily   │    │ Export PBI   │  │
│  │  (15 min)    │    │   (6h00)     │    │   (7h30)     │  │
│  └──────┬───────┘    └──────────────┘    └──────────────┘  │
│         │                                                    │
│    ┌────┴────┬────────────┬────────────┐                    │
│    ▼         ▼            ▼            ▼                    │
│ ┌──────┐ ┌──────┐    ┌──────┐    ┌──────┐                  │
│ │WF-01A│ │WF-01B│    │WF-01C│    │WF-01D│                  │
│ │Ticket│ │ Time │    │ CSAT │    │Alerts│                  │
│ └──────┘ └──────┘    └──────┘    └──────┘                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Analytics API   │
                    │    (FastAPI)      │
                    └──────────────────┘
```

## Checklist Gate 12 (Workflows)

- [ ] WF-00 créé et configuré (Error Handler)
- [ ] WF-01 créé (Orchestrator)
- [ ] WF-01A/B/C/D créés (Sub-workflows ingestion)
- [ ] WF-10 créé (KPI Compute)
- [ ] WF-20 créé (Export Power BI)
- [ ] Credentials configurés
- [ ] Tous les workflows testés manuellement
- [ ] Tous les workflows activés
- [ ] Error Handler connecté à Slack/Email
