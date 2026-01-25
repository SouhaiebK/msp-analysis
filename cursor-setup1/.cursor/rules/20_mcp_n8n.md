# Règles MCP n8n

## Accès MCP

Cursor a accès au serveur MCP n8n:
```
URL: http://n8n.76.13.98.217.sslip.io/mcp-server/http
Name: n8n-mcp
```

## Quand Utiliser MCP n8n

### ✅ Utiliser MCP pour:
- Créer de nouveaux workflows
- Lister les workflows existants
- Activer/désactiver des workflows
- Exécuter des workflows manuellement pour tests
- Récupérer la structure d'un workflow

### ❌ NE PAS utiliser MCP pour:
- Créer des credentials avec des secrets (utiliser UI n8n)
- Modifier des workflows en production critique sans backup
- Supprimer des workflows sans confirmation explicite

## Convention de Nommage Workflows

```
WF-00 → Error Handler (toujours le premier)
WF-01 → Orchestrator principal
WF-01A, WF-01B → Sub-workflows du WF-01
WF-10 → Jobs quotidiens (KPI)
WF-20 → Exports
WF-99 → Utilitaires/debug
```

## Procédure de Création

1. **Vérifier** si le workflow existe déjà:
   ```
   MCP: workflow_list
   ```

2. **Créer** le workflow (désactivé par défaut):
   ```
   MCP: workflow_create { "name": "WF-XX ...", "active": false, ... }
   ```

3. **Tester** avec exécution manuelle:
   ```
   MCP: workflow_execute { "id": "<workflow_id>" }
   ```

4. **Vérifier** le résultat dans les logs n8n

5. **Activer** si le test est OK:
   ```
   MCP: workflow_activate { "id": "<workflow_id>" }
   ```

## Proof Pack pour Workflows

Après création de workflows, documenter dans `proofs/`:

```
proofs/GATE-12-WORKFLOWS/
├── 10_commands.md        # Commandes MCP exécutées
├── 20_outputs/
│   ├── workflow_list.json
│   ├── wf00_created.json
│   ├── wf01_created.json
│   └── wf01_test_run.json
└── 40_verdict.md         # Liste des workflows + status
```

## Gestion des Erreurs MCP

Si une commande MCP échoue:
1. Vérifier que le serveur n8n est accessible
2. Vérifier les credentials MCP
3. Ne pas réessayer en boucle - signaler l'erreur
4. Proposer une alternative (export JSON manuel)

## Sécurité

```
⚠️ Les credentials avec secrets NE DOIVENT PAS être créés via MCP.
   Configurer les credentials sensibles via l'UI n8n:
   - API keys
   - Tokens d'authentification
   - Mots de passe
   
   MCP peut RÉFÉRENCER ces credentials par leur nom, pas les créer.
```
