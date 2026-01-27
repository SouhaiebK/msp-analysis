# GATE 1 - Réseau Coolify entre stacks

## Instructions

### 1.1) Configuration Coolify UI

Dans l'UI Coolify:
1. Stack n8n → Settings → Activer "Connect to Predefined Networks"
2. Sélectionner le réseau de la Destination (nom exact)
3. Redeploy stack n8n
4. Stack analytics-api → Settings → Activer "Connect to Predefined Networks"
5. Sélectionner le même réseau Destination
6. Redeploy stack analytics-api

Créer `coolify_config.txt` avec confirmation.

### 1.2) Identification hostname réel

```bash
# Sur le VPS (SSH)
docker ps | grep -i "analytics"  # Noter nom container exact
docker inspect <analytics_container_name> --format '{{json .NetworkSettings.Networks}}' > container_network.json
docker network inspect <DESTINATION_NETWORK_NAME> | head -n 80 > network_inspect.txt
```

### 1.3) Tests connectivité depuis n8n

```bash
# Sur le VPS (SSH)
docker ps | grep -i "n8n"  # Identifier container n8n web (pas worker)

# Test DNS (remplacer <HOST_ANALYTICS> par le hostname réel trouvé en 1.2)
docker exec -it <n8n_container> sh -lc 'getent hosts <HOST_ANALYTICS> || nslookup <HOST_ANALYTICS> || true' > dns_test.txt

# Test HTTP (remplacer <HOST_ANALYTICS> et <PORT>)
docker exec -it <n8n_container> sh -lc 'curl -sS -D- http://<HOST_ANALYTICS>:<PORT>/health || curl -sS -D- http://<HOST_ANALYTICS>:<PORT>/' > http_test.txt
```

## Critère PASS

- Les 2 stacks sur même réseau Destination
- DNS résout depuis n8n
- curl retourne HTTP 200 ou réponse applicative attendue
