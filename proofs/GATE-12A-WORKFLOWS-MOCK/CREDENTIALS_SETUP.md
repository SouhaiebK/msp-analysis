# Guide: Configuration des Credentials n8n

## ⚠️ Action Manuelle Requise

La création de credentials n'est **pas disponible via MCP n8n**. Cette étape doit être effectuée manuellement dans l'UI n8n.

## Étapes détaillées

### 1. Accéder à l'UI n8n

- **Local**: http://localhost:5678
- **Remote**: https://n8n.76.13.98.217.sslip.io
- Se connecter avec les credentials admin (depuis `.env`)

### 2. Créer le Credential Header Auth

1. Dans le menu latéral, cliquer sur **"Credentials"**
2. Cliquer sur **"Add Credential"** (bouton en haut à droite)
3. Dans la recherche, taper **"Header Auth"** et sélectionner
4. Remplir le formulaire:
   - **Name**: `Analytics API Service Token`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer <SERVICE_TOKEN>`
     - Remplacer `<SERVICE_TOKEN>` par la valeur depuis votre fichier `.env`
     - Exemple: `Bearer change-me-service-token-secure`
5. Cliquer sur **"Save"**
6. **Noter l'ID du credential** (visible dans l'URL après sauvegarde, format: `cred_xxxxx`)

### 3. Associer le Credential aux Nodes HTTP Request

Pour chaque workflow, suivre ces étapes:

#### WF-01 - Node "Get Tenants"

1. Ouvrir le workflow **WF-01 Orchestrator Ingestion**
2. Cliquer sur le node **"Get Tenants"**
3. Dans l'onglet **"Parameters"**:
   - **URL**: `http://analytics-api:8000/internal/tenants`
   - **Method**: `GET`
   - **Authentication**: Sélectionner **"Predefined Credential Type"**
   - **Credential Type**: Sélectionner **"Header Auth"**
   - **Credential for Header Auth**: Sélectionner **"Analytics API Service Token"**
4. Cliquer sur **"Save"** (en haut à droite du workflow)

#### WF-01A - Node "Call Ingest API"

1. Ouvrir le workflow **WF-01A Ingest Tickets**
2. Cliquer sur le node **"Call Ingest API"**
3. Dans l'onglet **"Parameters"**:
   - **URL**: `http://analytics-api:8000/internal/ingest/tickets?tenant_id={{ $json.tenant_id }}`
   - **Method**: `POST`
   - **Send Body**: ✅ Activé
   - **Body Content Type**: `JSON`
   - **Body**: Laisser vide (tenant_id dans query param)
   - **Authentication**: Sélectionner **"Predefined Credential Type"**
   - **Credential Type**: Sélectionner **"Header Auth"**
   - **Credential for Header Auth**: Sélectionner **"Analytics API Service Token"**
4. Sauvegarder le workflow

#### WF-01B - Node "Call Ingest API"

1. Ouvrir le workflow **WF-01B Ingest Time Entries**
2. Cliquer sur le node **"Call Ingest API"**
3. Dans l'onglet **"Parameters"**:
   - **URL**: `http://analytics-api:8000/internal/ingest/time_entries?tenant_id={{ $json.tenant_id }}`
   - **Method**: `POST`
   - **Send Body**: ✅ Activé
   - **Body Content Type**: `JSON`
   - **Body**: Laisser vide (tenant_id dans query param)
   - **Authentication**: Sélectionner **"Predefined Credential Type"**
   - **Credential Type**: Sélectionner **"Header Auth"**
   - **Credential for Header Auth**: Sélectionner **"Analytics API Service Token"**
4. Sauvegarder le workflow

#### WF-10 - Node "Compute KPIs"

1. Ouvrir le workflow **WF-10 Daily KPI Compute**
2. Cliquer sur le node **"Compute KPIs"**
3. Dans l'onglet **"Parameters"**:
   - **URL**: `http://analytics-api:8000/internal/kpi/compute-daily?tenant_id={{ $json.tenant_id }}&date={{ $now.minus({days: 1}).toFormat('yyyy-MM-dd') }}`
   - **Method**: `POST`
   - **Authentication**: Sélectionner **"Predefined Credential Type"**
   - **Credential Type**: Sélectionner **"Header Auth"**
   - **Credential for Header Auth**: Sélectionner **"Analytics API Service Token"**
4. Sauvegarder le workflow

**Note**: WF-10 doit d'abord obtenir la liste des tenants. Il faudra peut-être ajouter un node "Get Tenants" avant "Compute KPIs" ou modifier le workflow pour boucler sur les tenants.

#### WF-20 - Node "Generate Exports"

1. Ouvrir le workflow **WF-20 Export Power BI**
2. Cliquer sur le node **"Generate Exports"**
3. Dans l'onglet **"Parameters"**:
   - **URL**: `http://analytics-api:8000/internal/exports/generate?tenant_id={{ $json.tenant_id }}&date={{ $now.minus({days: 1}).toFormat('yyyy-MM-dd') }}`
   - **Method**: `POST`
   - **Authentication**: Sélectionner **"Predefined Credential Type"**
   - **Credential Type**: Sélectionner **"Header Auth"**
   - **Credential for Header Auth**: Sélectionner **"Analytics API Service Token"**
4. Sauvegarder le workflow

**Note**: WF-20 doit aussi obtenir la liste des tenants. Même remarque que pour WF-10.

## Vérification

Après avoir configuré tous les nodes:

1. Ouvrir chaque workflow
2. Vérifier que chaque node HTTP Request a:
   - ✅ Authentication configurée
   - ✅ Credential sélectionné
   - ✅ URL correcte

## Preuves à capturer

- Capture d'écran du credential créé (token masqué)
- Capture d'écran de chaque node HTTP Request configuré
- Export JSON de chaque workflow (après configuration)

## Alternative: Headers manuels

Si la création de credential pose problème, on peut aussi utiliser des headers manuels:

1. Dans chaque node HTTP Request:
   - **Send Headers**: ✅ Activé
   - **Headers**: Ajouter:
     - **Name**: `Authorization`
     - **Value**: `Bearer <SERVICE_TOKEN>` (expression: `Bearer {{ $env.SERVICE_TOKEN }}` ou valeur hardcodée)

**Note**: Cette méthode est moins sécurisée car le token peut être visible dans les logs n8n.
