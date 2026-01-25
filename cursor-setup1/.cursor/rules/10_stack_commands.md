# Commandes du Stack MSP Analytics

## Backend (analytics-api/)

### Tests
```bash
# Tous les tests
pytest

# Un fichier spécifique
pytest tests/test_auth.py

# Avec coverage
pytest --cov=analytics_api --cov-report=html

# Verbose
pytest -v
```

### Type Checking
```bash
mypy analytics_api/
```

### Linting
```bash
# Check
ruff check .

# Fix automatique
ruff check --fix .

# Format
ruff format .
```

### Serveur de Développement
```bash
# Mode dev avec reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Avec logs détaillés
uvicorn main:app --reload --log-level debug
```

## Docker / Coolify

### Docker Compose Local
```bash
# Démarrer tous les services
docker compose up -d

# Voir les logs en temps réel
docker compose logs -f analytics-api

# Logs d'un service spécifique
docker compose logs -f postgres

# Redémarrer un service
docker compose restart analytics-api

# Arrêter tout
docker compose down

# Arrêter avec suppression des volumes
docker compose down -v
```

### Debug Container
```bash
# Shell dans le container API
docker compose exec analytics-api /bin/bash

# Shell dans PostgreSQL
docker compose exec postgres psql -U msp -d msp_analytics

# Voir les ressources utilisées
docker stats
```

## Base de Données

### PostgreSQL Direct
```bash
# Via docker
docker compose exec postgres psql -U msp -d msp_analytics

# Lister les tables
\dt

# Voir le schéma d'une table
\d raw_tickets

# Query simple
SELECT COUNT(*) FROM raw_tickets;

# Quitter
\q
```

### Migrations (si Alembic)
```bash
# Créer une migration
alembic revision --autogenerate -m "description"

# Appliquer les migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Redis

```bash
# CLI Redis
docker compose exec redis redis-cli

# Voir toutes les clés
KEYS *

# Voir les clés de rate limit
KEYS ratelimit:*

# Supprimer une clé
DEL ratelimit:tenant_demo:v1/kpis

# Quitter
exit
```

## Validation / Tests d'Intégration

```bash
# Script de validation complet
./scripts/validate.sh

# Test manuel du health check
curl http://localhost:8000/health

# Test avec API key
curl -H "X-API-Key: <key>" http://localhost:8000/v1/kpis/daily

# Test rate limiting (110 requêtes)
for i in {1..110}; do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -H "X-API-Key: test" \
    http://localhost:8000/v1/kpis/daily
done
```

## n8n

### Via Interface
- URL: http://localhost:5678 (ou via tunnel Cloudflare)
- Workflows visibles dans l'UI

### CLI (si disponible)
```bash
# Export workflows
curl -H "X-N8N-API-KEY: <key>" http://localhost:5678/api/v1/workflows

# Health check
curl http://localhost:5678/healthz
```

## Git

```bash
# Status
git status -sb

# Diff des changements
git diff

# Diff staged
git diff --cached

# Créer un patch
git diff > proofs/TASK-xxx/30_diff.patch

# Commits récents
git log -n 10 --oneline --decorate

# Branches
git branch -a
```

## Commandes Non Trouvées

Les commandes suivantes n'existent PAS encore dans le repo et devront être créées:

- [ ] `make test` - À ajouter dans Makefile
- [ ] `make lint` - À ajouter dans Makefile
- [ ] `./scripts/seed.py` - À créer pour le seeding
- [ ] `./scripts/export.py` - À créer pour les exports Power BI

## Notes

- Toujours vérifier que les commandes existent avant de les proposer
- Sauvegarder les outputs dans `proofs/TASK-xxx/20_outputs/`
- Si une commande échoue, capturer le stderr aussi
