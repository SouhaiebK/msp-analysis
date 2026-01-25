# Guardrails Projet MSP Analytics Platform

## 1) Principes Fondamentaux

### KISS/YAGNI
- Pas d'over-engineering: MVP d'abord, robustesse ensuite
- DRY: si la logique se répète plus d'une fois, l'extraire
- Préférer des fonctions petites et lisibles
- Les commentaires expliquent "pourquoi", pas "quoi"

### Evidence-First
- Aucune affirmation sans preuve
- Pas de "ça devrait marcher" - uniquement "voici la commande + output"
- Toute commande exécutée doit avoir son output sauvegardé dans `proofs/`
- Contexte dynamique: ne pas coller de gros outputs dans le chat

### Plan Avant Code
- Pour changements multi-fichiers (>20 lignes ou >3 fichiers): Plan Mode obligatoire
- Proposer un plan en 3-5 étapes AVANT de coder
- Attendre validation explicite ("GO") avant d'implémenter

### Tests et Rollback
- Ne JAMAIS modifier les tests pour les faire passer sans justification
- Toujours proposer des steps de rollback
- Si un test échoue: diagnostiquer d'abord, corriger ensuite

## 2) Sécurité (OBLIGATOIRE - NON NÉGOCIABLE)

### Isolation Multi-Tenant
```
⚠️ CRITIQUE: tenant_id DOIT être dérivé du JWT/API-key
           JAMAIS du body de la requête
           JAMAIS du query parameter non validé
```

### Secrets
- JAMAIS de hardcoding de clés/tokens/passwords dans le code
- Utiliser `.env` uniquement
- Ne pas logger PII, tokens, secrets, raw credentials
- Valider que les secrets sont présents au démarrage

### Validation des Inputs
- Tous les inputs API: validation Pydantic stricte
- Rejeter les champs inconnus (`extra='forbid'`)
- Échapper le contenu user-provided dans l'UI
- Ne jamais faire confiance aux données côté client

### AuthZ Server-Side
- L'isolation tenant doit être enforced côté serveur
- Vérifier les permissions à chaque endpoint
- Rate limiting par tenant/endpoint

## 3) Proof Pack (Obligatoire par Tâche)

Chaque tâche DOIT avoir un Proof Pack dans `proofs/TASK-xxx/`:

```
proofs/TASK-xxx/
├── 00_plan.md           # Plan validé avant implémentation
├── 10_commands.md       # Liste des commandes exécutées
├── 20_outputs/          # Outputs bruts (stdout/stderr)
│   ├── test_run.txt
│   ├── lint.txt
│   └── ...
├── 30_diff.patch        # git diff du changement
└── 40_verdict.md        # PASS/FAIL + justification + next steps
```

### Format du Verdict
```markdown
# Verdict: TASK-xxx

## Status: PASS | FAIL

## Résumé
[1-2 phrases sur ce qui a été fait]

## Preuves
- [ ] Tests passent: proofs/TASK-xxx/20_outputs/pytest.txt
- [ ] Lint OK: proofs/TASK-xxx/20_outputs/lint.txt
- [ ] Type check OK: proofs/TASK-xxx/20_outputs/mypy.txt

## Risques / Notes
[Ce qui pourrait mal tourner, ce qu'on a ignoré]

## Next Steps
1. ...
2. ...
```

## 4) Anti-Hallucination

### Quand Tu Ne Sais Pas
- Dire "Je ne suis pas sûr" et proposer une étape de vérification
- Ne pas inventer de commandes: vérifier qu'elles existent
- Grep/search le codebase au lieu de supposer la structure

### Découverte de Contexte
- Utiliser `find`, `grep`, `rg` pour découvrir le code existant
- Inspecter `package.json`, `pyproject.toml`, `Makefile` avant de proposer des commandes
- Lire les fichiers avant de les modifier

## 5) Conventions de Nommage

### Fichiers
- API: `snake_case.py`
- Tests: `test_<module>.py`
- Configs: `lowercase-with-dashes.yml`

### Variables/Fonctions
- Python: `snake_case`
- TypeScript/React: `camelCase` pour fonctions, `PascalCase` pour composants

### Commits
```
<type>(<scope>): <description>

feat(api): add KPI compute endpoint
fix(auth): correct tenant extraction from JWT
docs(readme): update deployment instructions
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
