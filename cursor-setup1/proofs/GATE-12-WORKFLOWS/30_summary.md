# Résumé de la création des workflows n8n

## Date: 2026-01-25

## Workflows créés

### ✅ WF-00 Global Error Handler
- **ID**: `bkGuLTagD6Bk3Lwn`
- **Status**: Créé, désactivé
- **Node Count**: 2
- **Description**: Gère toutes les erreurs des workflows

### ✅ WF-01 Orchestrator Ingestion
- **ID**: `NKCbs5jW7uf4heK4`
- **Status**: Créé, désactivé
- **Node Count**: 6
- **Schedule**: Toutes les 15 minutes
- **Description**: Orchestre l'ingestion des données en appelant WF-01A et WF-01B pour chaque tenant
- **Structure**: 
  - Trigger toutes les 15 min → Get Tenants → Loop Tenants (splitInBatches)
  - Loop Tenants → Ingest Tickets (WF-01A) et Ingest Time (WF-01B) en parallèle
  - Ingest Tickets/Time → retour vers Loop Tenants pour continuer la boucle
  - Loop Tenants "done" → Done

### ✅ WF-01A Ingest Tickets
- **ID**: `jZFWavySR2ODw8C0`
- **Status**: Créé, désactivé
- **Node Count**: 2
- **Description**: Sous-workflow appelé par WF-01 pour ingérer les tickets

### ✅ WF-01B Ingest Time Entries
- **ID**: `tXU9wCYyU089bLdh`
- **Status**: Créé, désactivé
- **Node Count**: 2
- **Description**: Sous-workflow appelé par WF-01 pour ingérer les time entries

### ✅ WF-10 Daily KPI Compute
- **ID**: `8ds5mUQh9tJPWUKR`
- **Status**: Créé, désactivé
- **Node Count**: 2
- **Schedule**: 6h00 tous les jours (cron: `0 6 * * *`)
- **Description**: Calcule les KPIs quotidiens pour la veille

### ✅ WF-20 Export Power BI
- **ID**: `fge3tLFsO5hbBmhA`
- **Status**: Créé, désactivé
- **Node Count**: 2
- **Schedule**: 7h30 tous les jours (cron: `30 7 * * *`)
- **Description**: Génère les exports Power BI

## Points importants

### Format des connexions pour Split in Batches
Le nœud `Split in Batches` a deux sorties :
- `main[0]`: Pour chaque item dans la boucle
- `main[1]`: Quand la boucle est terminée ("done")

### Boucle dans WF-01
Les workflows appelés (`Ingest Tickets` et `Ingest Time`) doivent reconnecter vers `Loop Tenants` pour continuer l'itération jusqu'à ce que tous les tenants soient traités.

## Prochaines étapes

1. ✅ Création des workflows - TERMINÉ
2. ⏳ Tester chaque workflow (`n8n_test_workflow`)
3. ⏳ Activer les workflows (`n8n_update_partial_workflow` avec opération `updateSettings`)
4. ⏳ Configurer les credentials HTTP Header Auth pour SERVICE_TOKEN (si nécessaire)

## Fichiers de preuve

- `20_outputs/workflow_list_initial.json` - Liste initiale des workflows
- `20_outputs/wf00_created.json` - WF-00 créé
- `20_outputs/wf01a_created.json` - WF-01A créé
- `20_outputs/wf01b_created.json` - WF-01B créé
- `20_outputs/wf01_created.json` - WF-01 créé
- `20_outputs/wf10_created.json` - WF-10 créé
- `20_outputs/wf20_created.json` - WF-20 créé
- `20_outputs/workflow_list_final.json` - Liste finale des workflows
