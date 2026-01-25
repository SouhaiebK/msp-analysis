# Commande /verify

## Description
Exécute les validations du stack et génère un Proof Pack avec les résultats.

## Usage
```
/verify TASK-001
```

## Ce que fait cette commande

### 1. Crée la structure Proof Pack
```bash
mkdir -p proofs/<TASK_NAME>/20_outputs
```

### 2. Exécute les validations
```bash
# Tests (si pytest disponible)
pytest -v > proofs/<TASK_NAME>/20_outputs/pytest.txt 2>&1

# Type check (si mypy configuré)
mypy analytics_api/ > proofs/<TASK_NAME>/20_outputs/mypy.txt 2>&1

# Lint (si ruff/flake8 configuré)
ruff check . > proofs/<TASK_NAME>/20_outputs/lint.txt 2>&1

# Docker health (si docker compose actif)
docker compose ps > proofs/<TASK_NAME>/20_outputs/docker_status.txt 2>&1
curl -s http://localhost:8000/health > proofs/<TASK_NAME>/20_outputs/health.txt 2>&1
```

### 3. Génère le diff
```bash
git diff > proofs/<TASK_NAME>/30_diff.patch
```

### 4. Crée le verdict
Génère `proofs/<TASK_NAME>/40_verdict.md` avec:
- Status: PASS si tous les checks OK, FAIL sinon
- Liste des checks avec résultats
- Chemins vers les outputs
- Next steps

## Template de Verdict

```markdown
# Verdict: <TASK_NAME>

## Status: PASS | FAIL

## Date: <timestamp>

## Checks

| Check | Result | Output |
|-------|--------|--------|
| pytest | ✅ PASS | proofs/<TASK_NAME>/20_outputs/pytest.txt |
| mypy | ✅ PASS | proofs/<TASK_NAME>/20_outputs/mypy.txt |
| ruff | ✅ PASS | proofs/<TASK_NAME>/20_outputs/lint.txt |
| health | ✅ PASS | proofs/<TASK_NAME>/20_outputs/health.txt |

## Résumé
[Ce qui a été validé]

## Issues Trouvées
[Si FAIL: détails des erreurs]

## Next Steps
1. Si PASS: merge/commit
2. Si FAIL: corriger les issues listées
```

## Notes d'Implémentation

- Si un check n'est pas applicable (ex: pas de tests), noter "SKIP"
- Capturer stderr ET stdout (2>&1)
- Ne pas échouer si une commande n'existe pas, noter "NOT FOUND"
- Toujours créer le fichier 10_commands.md avec la liste des commandes exécutées
