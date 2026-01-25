# Documentation: Accès à n8n

## Vue d'ensemble

n8n est l'outil d'orchestration utilisé dans la plateforme MSP Analytics pour exécuter des workflows automatisés (cron jobs, synchronisation de données, etc.).

## Configuration

### Accès local

- **URL**: `http://localhost:5678`
- **Port**: 5678 (bindé uniquement sur localhost pour la sécurité)
- **Authentification**: Basic Auth activée
- **Credentials**: Définis dans `.env` via `N8N_ADMIN_USER` et `N8N_ADMIN_PASSWORD`

### Configuration Docker

Le service n8n est défini dans `docker-compose.yml`:

```yaml
n8n:
  image: n8nio/n8n:latest
  container_name: msp-n8n
  ports:
    - "127.0.0.1:5678:5678"
  environment:
    - N8N_BASIC_AUTH_ACTIVE=true
    - N8N_ADMIN_USER=${N8N_ADMIN_USER}
    - N8N_ADMIN_PASSWORD=${N8N_ADMIN_PASSWORD}
```

## Endpoints disponibles

### Healthcheck

```bash
GET http://localhost:5678/healthz
```

Retourne le statut de santé du service n8n.

### API REST

L'API n8n est accessible via `/api/v1/` avec authentification basique.

#### Lister les workflows

```bash
GET http://localhost:5678/api/v1/workflows
Authorization: Basic <base64(user:password)>
```

#### Exécuter un workflow

```bash
POST http://localhost:5678/api/v1/workflows/<workflow-id>/execute
Authorization: Basic <base64(user:password)>
```

## Test d'accès

### Script de test automatique

Deux scripts sont disponibles pour tester l'accès à n8n:

#### Linux/Mac (Bash)

```bash
./scripts/test-n8n-access.sh
```

#### Windows (PowerShell)

```powershell
.\scripts\test-n8n-access.ps1
```

### Tests manuels

#### 1. Vérifier l'état Docker

```bash
docker compose -p msp ps n8n
```

#### 2. Tester le healthcheck

```bash
curl http://localhost:5678/healthz
```

#### 3. Tester l'authentification

```bash
# Charger les credentials depuis .env
source .env

# Tester l'API
curl -u "${N8N_ADMIN_USER}:${N8N_ADMIN_PASSWORD}" \
  http://localhost:5678/api/v1/workflows
```

#### 4. Accéder à l'interface web

Ouvrir dans un navigateur: `http://localhost:5678`

## Intégration avec MCP (Model Context Protocol)

Pour utiliser n8n via MCP dans Cursor:

1. **Configurer le serveur MCP n8n** dans les paramètres Cursor
2. **Vérifier la connexion** avec le script de test
3. **Utiliser les outils MCP** pour interagir avec n8n depuis Cursor

### Configuration MCP recommandée

```json
{
  "mcpServers": {
    "n8n": {
      "command": "npx",
      "args": ["-y", "@n8n/mcp-server"],
      "env": {
        "N8N_URL": "http://localhost:5678",
        "N8N_API_KEY": "<api-key-from-n8n>"
      }
    }
  }
}
```

## Dépannage

### Service non démarré

```bash
docker compose -p msp up -d n8n
```

### Vérifier les logs

```bash
docker compose -p msp logs -f n8n
```

### Problème d'authentification

1. Vérifier que `.env` contient `N8N_ADMIN_USER` et `N8N_ADMIN_PASSWORD`
2. Vérifier que les credentials sont corrects
3. Redémarrer le service: `docker compose -p msp restart n8n`

### Port déjà utilisé

Si le port 5678 est déjà utilisé:

1. Vérifier quel processus utilise le port: `netstat -ano | findstr :5678` (Windows) ou `lsof -i :5678` (Linux/Mac)
2. Modifier le port dans `docker-compose.yml` si nécessaire

## Sécurité

- Le port 5678 est bindé uniquement sur `127.0.0.1` (localhost) pour éviter l'exposition publique
- L'authentification basique est requise pour toutes les opérations API
- Les credentials ne doivent jamais être commités dans git (utiliser `.env` qui est dans `.gitignore`)

## Références

- [Documentation n8n](https://docs.n8n.io/)
- [API n8n](https://docs.n8n.io/api/)
- [MCP n8n Server](https://github.com/n8n-io/mcp-server-n8n)
