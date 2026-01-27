# Résumé: Modification WF-10 et WF-20

## Date: 2026-01-25

## Modifications appliquées

### WF-10 Daily KPI Compute

**Avant**: 
- Schedule Trigger → Compute KPIs (sans itération sur tenants)

**Après**:
- Schedule Trigger → Get Tenants → Loop Tenants → Compute KPIs → Loop Tenants (boucle)
- Loop Tenants (done) → Done

**Changements**:
1. Ajout du node "Get Tenants" (HTTP GET /internal/tenants)
2. Ajout du node "Loop Tenants" (Split In Batches, batchSize=1)
3. Modification du node "Compute KPIs":
   - URL: `http://analytics-api:8000/internal/kpi/compute-daily?tenant_id={{ $json.id }}&date={{ $now.toISODate() }}`
   - Utilise query parameters au lieu du body
   - Utilise `{{ $json.id }}` pour le tenant_id
   - Utilise `{{ $now.toISODate() }}` pour la date
4. Ajout du node "Done" (NoOp)
5. Configuration des connexions pour reboucler vers Loop Tenants

**Preuves**:
- `wf10_before.json` - Version avant
- `wf10_after.json` - Version après

### WF-20 Export Power BI

**Avant**: 
- Schedule Trigger → Generate Exports (sans itération sur tenants)

**Après**:
- Schedule Trigger → Get Tenants → Loop Tenants → Generate Exports → Loop Tenants (boucle)
- Loop Tenants (done) → Done

**Changements**:
1. Ajout du node "Get Tenants" (HTTP GET /internal/tenants)
2. Ajout du node "Loop Tenants" (Split In Batches, batchSize=1)
3. Modification du node "Generate Exports":
   - URL: `http://analytics-api:8000/internal/exports/generate?tenant_id={{ $json.id }}&date={{ $now.toISODate() }}`
   - Utilise query parameters
   - Utilise `{{ $json.id }}` pour le tenant_id
   - Utilise `{{ $now.toISODate() }}` pour la date
4. Ajout du node "Done" (NoOp)
5. Configuration des connexions pour reboucler vers Loop Tenants

**Preuves**:
- `wf20_before.json` - Version avant
- `wf20_after.json` - Version après

## Structure des connexions

Les deux workflows suivent maintenant le même pattern que WF-01:

```
Schedule Trigger
    ↓
Get Tenants (HTTP GET /internal/tenants)
    ↓
Loop Tenants (Split In Batches, batchSize=1)
    ├─→ [main[0]] → Compute KPIs / Generate Exports
    └─→ [main[1]] → Done
         ↑
         └─── (reboucle depuis Compute KPIs / Generate Exports)
```

## Error Workflow

✅ Les deux workflows conservent WF-00 (`bkGuLTagD6Bk3Lwn`) comme error workflow.

## Tests

**Note**: Les workflows avec Schedule Trigger ne peuvent pas être exécutés via l'API n8n. Ils doivent être exécutés manuellement depuis l'UI n8n.

**Pour tester**:
1. Ouvrir WF-10 dans l'UI n8n
2. Cliquer sur "Execute Workflow" (bouton play)
3. Vérifier que:
   - Get Tenants retourne la liste des tenants
   - Loop Tenants itère sur chaque tenant
   - Compute KPIs est appelé pour chaque tenant avec le bon tenant_id et date
   - La boucle se termine correctement sur "Done"

**Même procédure pour WF-20**.

## Points d'attention

⚠️ **Credential Header Auth**: Les nodes "Get Tenants" doivent avoir le credential Header Auth configuré (comme dans WF-01).

⚠️ **Date format**: `{{ $now.toISODate() }}` retourne la date au format ISO (YYYY-MM-DD), ce qui correspond au format attendu par l'API.

⚠️ **Expression tenant_id**: `{{ $json.id }}` est utilisé car `/internal/tenants` retourne `[{id: "...", name: "...", ...}, ...]` et Split In Batches itère sur ce tableau.

## Statut

✅ **MODIFICATIONS COMPLÉTÉES**

Les workflows WF-10 et WF-20 itèrent maintenant sur tous les tenants, comme WF-01.
