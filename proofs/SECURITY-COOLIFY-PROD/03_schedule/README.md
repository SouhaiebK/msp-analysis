# GATE 3 - Tests n8n Schedule Trigger

## Instructions

### 3.1) Vérifications UI

Dans l'UI n8n, pour chaque workflow Schedule Trigger (WF-01, WF-10, WF-20):
- Workflow SAVED (vérifier)
- Workflow ACTIVE (toggle activé)
- Timezone du workflow (Settings) notée

Créer liste dans `workflows_status.txt`:
```
Workflow | Saved | Active | Timezone | Interval
--------|-------|--------|----------|----------
WF-01   | Yes   | Yes    | UTC      | Every 15 min
WF-10   | Yes   | Yes    | UTC      | Daily 6h00
WF-20   | Yes   | Yes    | UTC      | Daily 7h30
```

### 3.2) Fix timezone (si nécessaire)

Dans Coolify env vars du service n8n:
- Ajouter: `GENERIC_TIMEZONE=America/Montreal` (ou timezone souhaitée)
- Redeploy / restart n8n

Preuve container:
```bash
# Sur le VPS (SSH)
docker exec -it <n8n_container> sh -lc 'echo $GENERIC_TIMEZONE; date; ls -la' > timezone_config.txt
```

### 3.3) Test schedule réel

Dans l'UI n8n:
1. Dupliquer un workflow test (ex: WF-10)
2. Modifier Schedule: "every 1 minute" pendant 5 minutes
3. Activer le workflow
4. Observer Executions dans UI n8n (compte + timestamps)

Preuve logs:
```bash
# Sur le VPS (SSH)
docker logs --since=10m <n8n_container> | tail -n 200 > logs_test.txt
```

Créer `executions_test.txt` avec compte et timestamps observés dans l'UI.

### 3.4) Option test CLI (self-host)

Si nécessaire:
```bash
# Sur le VPS (SSH)
docker exec -u node -it <n8n_container> n8n execute --id <WORKFLOW_ID> > cli_test.txt
```

## Critère PASS

- Timezone contrôlée (workflow et/ou global)
- Au moins 1 workflow schedule exécute réellement (preuves executions + logs)
- On sait déclencher en test via UI/trigger/CLI
