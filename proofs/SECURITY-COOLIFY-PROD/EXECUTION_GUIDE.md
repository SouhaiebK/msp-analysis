# Guide d'exécution: Sécurisation Coolify + n8n Production

## Prérequis

- Accès SSH au VPS où sont déployés Coolify et les services
- Accès à l'UI Coolify
- Accès à l'UI n8n

## Ordre d'exécution

### GATE 0 — Baseline

1. **Sur le VPS (SSH)**:
   ```bash
   cd /path/to/repo
   chmod +x proofs/SECURITY-COOLIFY-PROD/00_baseline/collect_baseline.sh
   ./proofs/SECURITY-COOLIFY-PROD/00_baseline/collect_baseline.sh
   ```

2. **Dans l'UI Coolify**:
   - Aller dans "Destinations"
   - Identifier les stacks n8n et analytics-api
   - Noter Destination et Docker Network pour chaque stack
   - Créer `proofs/SECURITY-COOLIFY-PROD/00_baseline/coolify_stacks.txt`

3. **Vérifier**: Tous les fichiers de GATE 0 sont présents

### GATE 1 — Réseau Coolify

1. **Dans l'UI Coolify**:
   - Stack n8n → Settings → Activer "Connect to Predefined Networks"
   - Sélectionner le réseau Destination
   - Redeploy
   - Stack analytics-api → Même procédure
   - Créer `proofs/SECURITY-COOLIFY-PROD/01_network/coolify_config.txt`

2. **Sur le VPS (SSH)**:
   ```bash
   # Adapter DESTINATION_NETWORK selon votre configuration
   export DESTINATION_NETWORK="coolify-destination-1"  # À remplacer
   chmod +x proofs/SECURITY-COOLIFY-PROD/01_network/test_network.sh
   ./proofs/SECURITY-COOLIFY-PROD/01_network/test_network.sh
   ```

3. **Vérifier**: DNS et HTTP tests réussis

### GATE 2 — Ports privés

1. **Sur le VPS (SSH)**:
   ```bash
   chmod +x proofs/SECURITY-COOLIFY-PROD/02_ports/audit_ports.sh
   ./proofs/SECURITY-COOLIFY-PROD/02_ports/audit_ports.sh
   ```

2. **Analyser** les outputs et créer `audit_ports.txt` avec le tableau

3. **Dans l'UI Coolify**:
   - Appliquer les corrections (retirer ports, utiliser proxy, etc.)
   - Documenter dans `fixes_applied.txt`

4. **Sur le VPS (SSH)**:
   ```bash
   chmod +x proofs/SECURITY-COOLIFY-PROD/02_ports/verify_fixes.sh
   ./proofs/SECURITY-COOLIFY-PROD/02_ports/verify_fixes.sh
   ```

5. **Vérifier**: Aucun port privé sur 0.0.0.0

### GATE 3 — Schedule Trigger

1. **Dans l'UI n8n**:
   - Vérifier workflows WF-01, WF-10, WF-20 (Saved, Active, Timezone)
   - Créer `workflows_status.txt`

2. **Dans l'UI Coolify**:
   - Service n8n → Env vars → Ajouter `GENERIC_TIMEZONE=America/Montreal`
   - Redeploy n8n

3. **Sur le VPS (SSH)**:
   ```bash
   chmod +x proofs/SECURITY-COOLIFY-PROD/03_schedule/test_schedule.sh
   ./proofs/SECURITY-COOLIFY-PROD/03_schedule/test_schedule.sh
   ```

4. **Dans l'UI n8n**:
   - Dupliquer WF-10 → Modifier schedule "every 1 minute"
   - Activer et observer executions
   - Créer `executions_test.txt` avec compte et timestamps

5. **Vérifier**: Au moins 1 workflow s'exécute réellement

### Verdict final

Compléter `proofs/SECURITY-COOLIFY-PROD/40_verdict.md` avec:
- Statut PASS/BLOCKED pour chaque gate
- Justifications
- Fixes appliqués
- Risques restants

## Notes importantes

- **Redacter les secrets**: Tokens, passwords doivent être masqués dans les outputs
- **Garder les noms**: Containers, réseaux, ports doivent rester visibles
- **Outputs complets**: Si une sortie manque → BLOCKED pour ce gate
- **Séquentiel**: Ne pas passer au gate suivant si le précédent est BLOCKED
