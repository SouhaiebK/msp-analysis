# Commandes de validation - Gate 12A

## Prérequis

1. Gate 8+9 PASS (API Analytics fonctionnelle en MOCK_MODE)
2. SERVICE_TOKEN connu (depuis `.env`)
3. Workflows n8n créés (WF-00, WF-01, WF-01A, WF-01B, WF-10, WF-20)

## Étapes de validation

### A) Vérifier Error Workflow configuré ✅

Les workflows ont été configurés via MCP pour utiliser WF-00 comme error workflow.

**Vérification**:
```bash
# Via MCP (déjà fait)
# Ou via UI n8n: Ouvrir chaque workflow -> Settings -> Error Workflow = WF-00
```

**Preuve**: Les settings montrent `"errorWorkflow": "bkGuLTagD6Bk3Lwn"` pour tous les workflows.

### B) Créer Credential Header Auth (ACTION MANUELLE REQUISE)

**⚠️ LIMITATION**: La création de credentials n'est pas disponible via MCP n8n. Cette étape doit être faite manuellement dans l'UI n8n.

#### Étapes dans l'UI n8n:

1. **Accéder à l'UI n8n**:
   - URL: http://localhost:5678 (local) ou https://n8n.76.13.98.217.sslip.io
   - Se connecter avec les credentials admin

2. **Créer le credential**:
   - Aller dans **Credentials** (menu latéral)
   - Cliquer sur **"Add Credential"**
   - Rechercher et sélectionner **"Header Auth"**
   - Remplir:
     - **Name**: `Analytics API Service Token`
     - **Header Name**: `Authorization`
     - **Header Value**: `Bearer <SERVICE_TOKEN>` (remplacer `<SERVICE_TOKEN>` par la valeur depuis `.env`)
   - Cliquer sur **"Save"**
   - **Noter l'ID du credential** (visible dans l'URL ou les détails)

3. **Associer le credential aux nodes HTTP Request**:

   Pour chaque workflow, ouvrir et configurer les nodes HTTP Request:

   **WF-01 - Node "Get Tenants"**:
   - Ouvrir WF-01
   - Cliquer sur le node "Get Tenants"
   - Dans **Authentication**, sélectionner **"Predefined Credential Type"**
   - Dans **Credential Type**, sélectionner **"Header Auth"**
   - Dans **Credential for Header Auth**, sélectionner **"Analytics API Service Token"**
   - Sauvegarder le workflow

   **WF-01A - Node "Call Ingest API"**:
   - Même procédure
   - URL: `http://analytics-api:8000/internal/ingest/tickets?tenant_id={{ $json.tenant_id }}`
   - Method: POST
   - Authentication: Header Auth (Analytics API Service Token)

   **WF-01B - Node "Call Ingest API"**:
   - Même procédure
   - URL: `http://analytics-api:8000/internal/ingest/time_entries?tenant_id={{ $json.tenant_id }}`
   - Method: POST
   - Authentication: Header Auth (Analytics API Service Token)

   **WF-10 - Node "Compute KPIs"**:
   - Même procédure
   - URL: `http://analytics-api:8000/internal/kpi/compute-daily?tenant_id={{ $json.tenant_id }}&date={{ $now.minus({days: 1}).toFormat('yyyy-MM-dd') }}`
   - Method: POST
   - Authentication: Header Auth (Analytics API Service Token)

   **WF-20 - Node "Generate Exports"**:
   - Même procédure
   - URL: `http://analytics-api:8000/internal/exports/generate?tenant_id={{ $json.tenant_id }}&date={{ $now.minus({days: 1}).toFormat('yyyy-MM-dd') }}`
   - Method: POST
   - Authentication: Header Auth (Analytics API Service Token)

**Preuve**: Captures d'écran de l'UI n8n montrant:
- Le credential créé (token masqué)
- Chaque node HTTP Request configuré avec le credential

### C) Vérifier WF-01 Execute Workflow IDs ✅

**Vérification via MCP**:
```bash
# Récupérer WF-01
n8n_get_workflow(id="NKCbs5jW7uf4heK4", mode="full")
```

**Résultat attendu**:
- Node "Ingest Tickets": `workflowId = "jZFWavySR2ODw8C0"` ✅
- Node "Ingest Time": `workflowId = "tXU9wCYyU089bLdh"` ✅

**Preuve**: Export JSON de WF-01 montrant les IDs corrects.

### D) Activation + Tests

#### 1. Préparer l'environnement

```bash
# Vérifier que l'API Analytics est démarrée
docker compose -p msp ps analytics-api

# Vérifier les logs
docker compose -p msp logs analytics-api --tail=50

# Vérifier que la DB est seedée
docker compose -p msp exec analytics-api python /app/seed_mock.py
```

#### 2. Activer et tester WF-10

**Via MCP**:
```bash
# Activer WF-10
n8n_update_partial_workflow(
  id="8ds5mUQh9tJPWUKR",
  operations=[{"type": "enableNode", "nodeId": "schedule-trigger-1"}]
)

# OU activer le workflow entier (si disponible)
# Note: L'activation complète du workflow peut nécessiter l'UI n8n
```

**Via UI n8n**:
- Ouvrir WF-10
- Cliquer sur le toggle **"Active"** en haut à droite
- Cliquer sur **"Execute Workflow"** (bouton play)

**Vérifications**:
```bash
# Vérifier les logs analytics-api
docker compose -p msp logs analytics-api --tail=100 | grep "kpi/compute-daily"

# Vérifier la DB
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, kpi_date, tickets_created, total_minutes FROM kpi_daily ORDER BY kpi_date DESC LIMIT 5"
```

**Preuve**: 
- Output de l'exécution n8n (succès)
- Logs analytics-api montrant l'appel à `/internal/kpi/compute-daily`
- Données dans `kpi_daily`

#### 3. Activer et tester WF-01

**Via UI n8n**:
- Ouvrir WF-01
- Activer le workflow
- Exécuter manuellement

**Vérifications**:
```bash
# Vérifier les logs analytics-api
docker compose -p msp logs analytics-api --tail=200 | grep -E "(ingest/tickets|ingest/time_entries|internal/tenants)"

# Vérifier les données ingérées
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, COUNT(*) as ticket_count FROM raw_tickets GROUP BY tenant_id"

docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, COUNT(*) as time_entry_count FROM raw_time_entries GROUP BY tenant_id"
```

**Preuve**:
- Output de l'exécution n8n montrant la boucle sur les tenants
- Logs analytics-api montrant les appels aux endpoints d'ingestion
- Données dans `raw_tickets` et `raw_time_entries` par tenant

#### 4. Vérifier l'isolation multi-tenant

```bash
# Compter les tickets par tenant
docker compose -p msp exec postgres psql -U msp -d msp_analytics -c \
  "SELECT tenant_id, COUNT(*) FROM raw_tickets GROUP BY tenant_id ORDER BY tenant_id"

# Vérifier que chaque tenant a ses propres données
# Tenant 1 (550e8400-e29b-41d4-a716-446655440000): devrait avoir 5 tickets
# Tenant 2 (550e8400-e29b-41d4-a716-446655440001): devrait avoir 2 tickets
```

## Commandes MCP pour tests

```python
# Lister les workflows
n8n_list_workflows()

# Récupérer un workflow
n8n_get_workflow(id="8ds5mUQh9tJPWUKR", mode="full")

# Tester WF-10 (si trigger manuel disponible)
n8n_test_workflow(workflowId="8ds5mUQh9tJPWUKR")

# Tester WF-01
n8n_test_workflow(workflowId="NKCbs5jW7uf4heK4")

# Vérifier les exécutions
n8n_executions(action="list", workflowId="8ds5mUQh9tJPWUKR", limit=5)
```

## Résultats attendus

### WF-10
- ✅ Appel à `/internal/kpi/compute-daily` pour chaque tenant
- ✅ KPIs calculés et insérés dans `kpi_daily`
- ✅ Pas d'erreurs dans les logs

### WF-01
- ✅ Appel à `/internal/tenants` pour obtenir la liste
- ✅ Boucle sur chaque tenant
- ✅ Appel à `/internal/ingest/tickets` pour chaque tenant
- ✅ Appel à `/internal/ingest/time_entries` pour chaque tenant
- ✅ Données ingérées dans `raw_tickets` et `raw_time_entries`
- ✅ Isolation multi-tenant respectée
