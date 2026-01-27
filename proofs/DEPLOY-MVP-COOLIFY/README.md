# Preuves: Déploiement MVP sur Coolify

Ce dossier contient les preuves du déploiement du MVP sur un VPS Ubuntu 24.04 avec Coolify.

## Structure

- **00_plan.md**: Plan détaillé du déploiement
- **10_commands.md**: Toutes les commandes à exécuter
- **20_outputs/**: Sorties des commandes et captures d'écran
  - `network_verification.txt` - Vérification réseau
  - `coolify_variables.png` - Variables d'environnement
  - `coolify_volumes.png` - Volumes montés
  - `migration_output.txt` - Output de la migration DB
  - `seed_output.txt` - Output du seed
  - `api_tests.txt` - Tests API (curl)
  - `n8n_credentials.png` - Credential créé dans n8n
  - `wf01_execution.json` - Exécution WF-01
  - `wf10_execution.json` - Exécution WF-10
  - `wf20_execution.json` - Exécution WF-20
  - `db_verification.txt` - Vérification données DB
- **40_verdict.md**: Verdict final (PASS/BLOCKED)

## Ordre d'exécution

1. Lire `00_plan.md` pour comprendre l'architecture
2. Suivre `10_commands.md` étape par étape
3. Capturer les outputs dans `20_outputs/`
4. Rédiger `40_verdict.md` avec le résultat final

## Points critiques

⚠️ **Réseau Coolify**: n8n et analytics-api doivent être sur le même Destination network pour communiquer via hostname interne.

⚠️ **Variables d'environnement**: SERVICE_TOKEN et DATABASE_URL doivent être correctement configurés.

⚠️ **Volumes**: mock-data doit être accessible en lecture seule, exports en lecture/écriture.

⚠️ **Migrations**: Le schéma DB doit être créé avant le seed.

## Statut

⏳ **EN ATTENTE** - Déploiement à effectuer
