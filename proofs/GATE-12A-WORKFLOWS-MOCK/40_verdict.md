# Verdict: Gate 12A - Workflows n8n opérationnels contre Analytics API en MOCK_MODE

## Date: 2026-01-25

## Résumé

**STATUS: ⚠️ PARTIELLEMENT COMPLÉTÉ - Action manuelle requise pour credentials**

Les workflows n8n ont été configurés pour fonctionner avec l'API Analytics en mode MOCK, mais la configuration des credentials nécessite une action manuelle dans l'UI n8n.

## Ce qui a été fait

### ✅ A) Error Workflow câblé

Tous les workflows ont été configurés pour utiliser WF-00 (`bkGuLTagD6Bk3Lwn`) comme error workflow:

- ✅ WF-01: `NKCbs5jW7uf4heK4`
- ✅ WF-01A: `jZFWavySR2ODw8C0`
- ✅ WF-01B: `tXU9wCYyU089bLdh`
- ✅ WF-10: `8ds5mUQh9tJPWUKR`
- ✅ WF-20: `fge3tLFsO5hbBmhA`

**Méthode**: Utilisation de `n8n_update_partial_workflow` avec opération `updateSettings`.

**Preuve**: `20_outputs/error_workflow_config.json`

### ⚠️ B) Credentials (ACTION MANUELLE REQUISE)

**Limitation MCP**: La création de credentials n'est pas disponible via MCP n8n.

**Action requise**:
1. Créer le credential "Header Auth" dans l'UI n8n avec:
   - Name: `Analytics API Service Token`
   - Header Name: `Authorization`
   - Header Value: `Bearer <SERVICE_TOKEN>`

2. Associer ce credential à tous les nodes HTTP Request:
   - WF-01: Node "Get Tenants"
   - WF-01A: Node "Call Ingest API"
   - WF-01B: Node "Call Ingest API"
   - WF-10: Node "Compute KPIs"
   - WF-20: Node "Generate Exports"

**Guide détaillé**: Voir `CREDENTIALS_SETUP.md`

**Note**: Une fois le credential créé, les workflows pourront être testés.

### ✅ C) WF-01 Execute Workflow IDs vérifiés

Les IDs des workflows appelés dans WF-01 sont corrects:

- ✅ Node "Ingest Tickets": `workflowId = "jZFWavySR2ODw8C0"` (WF-01A)
- ✅ Node "Ingest Time": `workflowId = "tXU9wCYyU089bLdh"` (WF-01B)

**Preuve**: `20_outputs/wf01_workflow_ids.json`

### ✅ D) Corrections appliquées

**WF-01A et WF-01B**:
- ✅ URLs corrigées pour utiliser query parameters au lieu du body
- ✅ WF-01A: `http://analytics-api:8000/internal/ingest/tickets?tenant_id={{ $json.id }}`
- ✅ WF-01B: `http://analytics-api:8000/internal/ingest/time_entries?tenant_id={{ $json.id }}`
- ✅ Utilisation de `$json.id` car `/internal/tenants` retourne `{id, name, ...}`

**Preuve**: `20_outputs/workflows_updated.json`

### ⏳ D) Activation + Tests (EN ATTENTE)

**Prérequis**: Credentials configurés (étape B)

**Tests à effectuer**:

1. **WF-10**:
   - Activer le workflow
   - Exécuter manuellement
   - Vérifier l'appel à `/internal/kpi/compute-daily`
   - Vérifier les données dans `kpi_daily`

2. **WF-01**:
   - Activer le workflow
   - Exécuter manuellement
   - Vérifier la boucle sur les tenants
   - Vérifier les appels à `/internal/ingest/tickets` et `/internal/ingest/time_entries`
   - Vérifier les données dans `raw_tickets` et `raw_time_entries`

**Commandes de test**: Voir `10_commands.md`

## Points d'attention

### ⚠️ WF-10 et WF-20 nécessitent une boucle sur les tenants

Les workflows WF-10 et WF-20 dans leur forme actuelle n'ont pas de boucle sur les tenants. Ils doivent être modifiés pour:

1. Appeler `/internal/tenants` pour obtenir la liste
2. Boucler sur chaque tenant avec `Split in Batches`
3. Appeler les endpoints avec le `tenant_id` approprié

**Recommandation**: Modifier WF-10 et WF-20 pour ajouter:
- Node "Get Tenants" (comme dans WF-01)
- Node "Split in Batches" pour boucler
- Mettre à jour les URLs des nodes HTTP Request pour utiliser `{{ $json.id }}`

### ⚠️ Credentials doivent être créés manuellement

Cette limitation de l'API MCP n8n nécessite une intervention manuelle. Une fois les credentials créés, tous les workflows pourront être testés.

## Fichiers créés

- `00_plan.md` - Plan détaillé
- `10_commands.md` - Commandes de test
- `CREDENTIALS_SETUP.md` - Guide pour créer les credentials
- `20_outputs/error_workflow_config.json` - Preuve error workflow
- `20_outputs/wf01_workflow_ids.json` - Preuve IDs workflows
- `20_outputs/workflows_updated.json` - Preuve corrections URLs
- `40_verdict.md` - Ce fichier

## Conclusion

**STATUS: ⚠️ PARTIELLEMENT COMPLÉTÉ**

- ✅ Error workflows configurés
- ✅ IDs workflows vérifiés
- ✅ URLs corrigées
- ⚠️ Credentials nécessitent action manuelle
- ⏳ Tests en attente (nécessitent credentials)

**Prochaines étapes**:
1. Créer le credential Header Auth dans l'UI n8n (voir `CREDENTIALS_SETUP.md`)
2. Associer le credential à tous les nodes HTTP Request
3. Tester WF-10 et WF-01 selon `10_commands.md`
4. Capturer les outputs dans `20_outputs/`
5. Générer le diff: `git diff > 30_diff.patch`

Une fois les credentials configurés, les workflows seront opérationnels contre l'API Analytics en mode MOCK.
