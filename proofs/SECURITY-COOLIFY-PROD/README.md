# Sécurisation Coolify + n8n Production

Ce dossier contient les preuves de sécurisation de 3 risques critiques de production sur Coolify + n8n.

## Structure

- **00_baseline/** - État initial Docker et configuration Coolify
- **01_network/** - Configuration réseau inter-stacks (n8n ↔ analytics-api)
- **02_ports/** - Audit et correction exposition ports privés
- **03_schedule/** - Tests workflows Schedule Trigger
- **40_verdict.md** - Verdict final par gate

## Processus

Chaque gate doit être complété séquentiellement avec preuves complètes avant de passer au suivant.

### Règle critique

À chaque étape, exécuter les commandes et coller les OUTPUTS/LOGS complets. Si une sortie manque → BLOCKED pour ce gate.

Redacter tous les secrets (tokens, passwords) mais garder noms containers/réseaux/ports.

## Commandes à exécuter sur le VPS

Toutes les commandes doivent être exécutées sur le VPS via SSH. Voir les fichiers README.md dans chaque dossier pour les instructions détaillées.

## Statut

⏳ **EN ATTENTE** - Exécution sur le VPS requise
