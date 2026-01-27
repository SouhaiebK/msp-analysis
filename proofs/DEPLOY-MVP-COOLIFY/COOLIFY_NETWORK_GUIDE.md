# Guide: Configuration réseau Coolify pour communication inter-services

## Problème

Pour que n8n puisse appeler analytics-api via hostname interne (`http://analytics-api:8000`), les deux services doivent être sur le même réseau Docker.

## Solution: Destination Network dans Coolify

### Concept

Dans Coolify, les services peuvent être déployés sur différents "Destinations". Pour que deux services communiquent via hostname interne, ils doivent être sur le même Destination network.

### Étapes de configuration

#### 1. Identifier le Destination utilisé

**Dans l'UI Coolify**:
1. Aller dans "Destinations" (menu latéral)
2. Noter le nom du Destination utilisé par n8n et Postgres
   - Exemple: `coolify-destination-1` ou `default`

#### 2. Vérifier la configuration de n8n

**Pour n8n service**:
1. Ouvrir les settings de n8n
2. Aller dans "Networks" ou "Advanced"
3. Vérifier:
   - **Destination**: Doit être le même que Postgres
   - **Connect to Predefined Networks**: Peut être activé si nécessaire

#### 3. Configurer analytics-api

**Lors du déploiement de analytics-api**:
1. Dans les settings de analytics-api
2. **Destination**: Sélectionner le même Destination que n8n et Postgres
3. **Connect to Predefined Networks**: Activer si nécessaire
4. **Hostname**: Le hostname interne sera automatiquement `analytics-api` (nom du service)

#### 4. Vérifier la connectivité

**Depuis n8n container**:
```bash
# Via terminal Coolify (exec dans n8n container)
ping -c 3 analytics-api
curl -v http://analytics-api:8000/health
```

**Résultat attendu**:
- `ping` doit réussir (réponse depuis analytics-api)
- `curl` doit retourner `{"status":"healthy"}` ou similaire

### Cas particuliers

#### Service Stacks séparées

Si n8n et analytics-api sont dans des "service stacks" différentes:

1. **Pour chaque stack**:
   - Ouvrir les settings de la stack
   - Aller dans "Networks"
   - Activer "Connect to Predefined Networks"
   - Sélectionner le même Destination

2. **Vérifier**:
   - Les deux stacks sont sur le même Destination
   - Les conteneurs peuvent se ping mutuellement

#### Postgres externe

Si Postgres est déployé ailleurs (pas sur Coolify):

1. **Option 1**: Utiliser l'IP externe dans DATABASE_URL
   ```env
   DATABASE_URL=postgresql://user:password@postgres-external-ip:5432/db
   ```

2. **Option 2**: Configurer un réseau Docker personnalisé
   - Créer un réseau Docker externe
   - Connecter analytics-api et Postgres à ce réseau
   - Utiliser le hostname Postgres dans DATABASE_URL

### Dépannage

#### Problème: `curl: (6) Could not resolve host: analytics-api`

**Cause**: Les services ne sont pas sur le même réseau.

**Solution**:
1. Vérifier que n8n et analytics-api sont sur le même Destination
2. Redémarrer les deux services
3. Vérifier avec `docker network ls` et `docker inspect <container>`

#### Problème: `Connection refused` ou timeout

**Cause**: analytics-api n'écoute pas sur le port 8000 ou le firewall bloque.

**Solution**:
1. Vérifier que analytics-api écoute sur `0.0.0.0:8000` (pas `127.0.0.1`)
2. Vérifier les logs analytics-api: `docker logs msp-analytics-api`
3. Tester depuis le host: `curl http://localhost:8000/health` (si port exposé)

#### Problème: Les services ne peuvent pas se ping

**Cause**: Les réseaux Docker ne sont pas connectés.

**Solution**:
1. Vérifier les réseaux Docker:
   ```bash
   docker network ls
   docker network inspect <network_name>
   ```
2. Vérifier que les deux conteneurs sont sur le même réseau:
   ```bash
   docker inspect <n8n_container> | grep -A 10 "Networks"
   docker inspect <analytics-api_container> | grep -A 10 "Networks"
   ```

### Commandes utiles

```bash
# Lister les réseaux Docker
docker network ls

# Inspecter un réseau
docker network inspect <network_name>

# Inspecter un conteneur (réseaux)
docker inspect <container_name> | grep -A 20 "Networks"

# Tester la connectivité depuis un conteneur
docker exec <container_name> ping -c 3 <other_container_hostname>
docker exec <container_name> curl -v http://<other_container_hostname>:<port>/health
```

### Vérification finale

**Checklist**:
- [ ] n8n et analytics-api sont sur le même Destination
- [ ] "Connect to Predefined Networks" est activé si nécessaire
- [ ] `ping analytics-api` depuis n8n réussit
- [ ] `curl http://analytics-api:8000/health` depuis n8n retourne 200

**Preuve**: Capturer les outputs de ces commandes dans `20_outputs/network_verification.txt`
