# Proofs Directory

Ce dossier contient les **Proof Packs** - des preuves d'exécution pour chaque tâche/gate.

## Structure d'un Proof Pack

```
proofs/TASK-xxx/
├── 00_plan.md           # Plan validé avant implémentation
├── 10_commands.md       # Liste des commandes exécutées
├── 20_outputs/          # Outputs bruts des commandes
│   ├── pytest.txt
│   ├── mypy.txt
│   ├── lint.txt
│   └── ...
├── 30_diff.patch        # git diff du changement
└── 40_verdict.md        # Verdict final (PASS/FAIL)
```

## Pourquoi des Proof Packs?

1. **Traçabilité**: On peut remonter le film de chaque changement
2. **Vérification**: Preuves tangibles que les tests passent
3. **Contexte Cursor**: L'agent peut relire les proofs pour comprendre le contexte
4. **Audit**: Documentation automatique du travail effectué

## Convention de Nommage

- `TASK-xxx`: Tâche numérotée (ex: TASK-001, TASK-002)
- `GATE-x`: Gate du projet (ex: GATE-6-BOOTSTRAP)
- `FIX-xxx`: Correction de bug
- `REFACTOR-xxx`: Refactoring

## Exemple de Verdict (40_verdict.md)

```markdown
# Verdict: TASK-001 - Add health endpoint

## Status: PASS

## Date: 2026-01-24T10:30:00Z

## Résumé
Ajout de l'endpoint /health avec vérification DB et Redis.

## Checks
| Check | Result | Output |
|-------|--------|--------|
| pytest | ✅ PASS | proofs/TASK-001/20_outputs/pytest.txt |
| mypy | ✅ PASS | proofs/TASK-001/20_outputs/mypy.txt |
| curl /health | ✅ PASS | proofs/TASK-001/20_outputs/health.txt |

## Next Steps
1. Commit et push
2. Déployer via Coolify
```

## Commande /verify

Utiliser la commande Cursor `/verify TASK-xxx` pour:
1. Exécuter les validations automatiquement
2. Générer le Proof Pack
3. Produire le verdict

## Règles

1. **Ne jamais modifier les outputs** après génération
2. **Toujours inclure stderr** dans les captures
3. **Garder les proofs dans git** (sauf .gitignore les très gros fichiers)
4. **Un Proof Pack par tâche** - pas de mélange
