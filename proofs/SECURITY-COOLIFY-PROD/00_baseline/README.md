# GATE 0 - Baseline: État initial Docker et Coolify

## Instructions

Ces commandes doivent être exécutées **sur le VPS** (via SSH) pour capturer l'état initial.

## Commandes à exécuter

### 0.1) État Docker sur VPS

```bash
# Sur le VPS (SSH)
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" > docker_ps.txt
docker network ls > docker_networks.txt
sudo ss -lntp > ss_listening.txt
```

Puis copier les fichiers vers ce dossier.

### 0.2) Configuration Coolify (UI)

Dans l'UI Coolify:
1. Aller dans "Destinations" (menu latéral)
2. Identifier les stacks:
   - Stack n8n (web + worker si présent)
   - Stack analytics-api
3. Pour chaque stack, noter:
   - Destination utilisée (nom exact)
   - Docker Network de la Destination (nom exact depuis Coolify UI)

Créer `coolify_stacks.txt` avec:
```
Stack n8n:
- Destination: <nom>
- Docker Network: <nom>

Stack analytics-api:
- Destination: <nom>
- Docker Network: <nom>
```

## Critère PASS

- Outputs complets des 3 commandes Docker/ss
- 3 infos documentées: Destination n8n, Destination analytics-api, Network Destination
