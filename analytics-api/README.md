# MSP Analytics API

API FastAPI pour la plateforme MSP Analytics.

## Structure

```
analytics-api/
├── Dockerfile              # Image Docker
├── requirements.txt        # Dépendances Python
├── healthcheck.py          # Healthcheck Docker
├── seed_mock.py            # Script de seed DB
├── migrations/            # Migrations SQL
│   └── 001_initial_schema.sql
├── alembic/               # Alembic (migrations Python)
│   ├── env.py
│   └── script.py.mako
└── app/
    ├── main.py            # Application FastAPI
    ├── config.py          # Configuration
    ├── database.py        # Connexion DB
    ├── models.py          # Modèles SQLAlchemy
    ├── auth/
    │   └── dependencies.py  # Dépendances auth
    └── routers/
        ├── health.py      # Health check
        ├── internal.py    # Endpoints internes (/internal/*)
        └── v1.py          # Endpoints publics (/v1/*)
```

## Configuration

Variables d'environnement requises (voir `.env.example`):

- `DATABASE_URL`: URL PostgreSQL
- `REDIS_URL`: URL Redis
- `JWT_SECRET_KEY`: Clé secrète JWT
- `SERVICE_TOKEN`: Token pour endpoints internes
- `MOCK_MODE`: `true` ou `false`
- `MOCK_DATA_PATH`: Chemin vers mock-data (défaut: `/app/mock-data`)

## Endpoints

### Health Check
- `GET /health` - Vérifie l'état de l'API

### Endpoints Internes (Service Token)
- `GET /internal/tenants` - Liste tous les tenants actifs
- `POST /internal/ingest/tickets?tenant_id=...` - Ingère tickets
- `POST /internal/ingest/time_entries?tenant_id=...` - Ingère time entries
- `POST /internal/kpi/compute-daily?tenant_id=...&date=YYYY-MM-DD` - Calcule KPIs
- `POST /internal/exports/generate?tenant_id=...&date=YYYY-MM-DD` - Génère exports

### Endpoints Publics (API Key)
- `GET /v1/kpis/daily?date=YYYY-MM-DD` - KPIs quotidiens
- `GET /v1/tickets/{cw_ticket_id}/summary` - Résumé ticket

## Développement

### Setup local

```bash
# Installer les dépendances
pip install -r requirements.txt

# Configurer .env
cp ../.env.example .env
# Éditer .env avec vos valeurs

# Lancer l'API
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Seed de la base de données

```bash
# Avec Docker
docker compose -p msp exec analytics-api python /app/seed_mock.py

# Local
python seed_mock.py
```

### Migrations

```bash
# Créer une nouvelle migration
alembic revision --autogenerate -m "Description"

# Appliquer les migrations
alembic upgrade head

# Revenir en arrière
alembic downgrade -1
```

## Mode Mock

Quand `MOCK_MODE=true`, l'API lit les données depuis les fichiers JSONL dans `mock-data/` au lieu d'appeler les vraies APIs.

Structure attendue:
```
mock-data/
├── tenants.json
├── tenant_demo_cca/
│   ├── tickets.jsonl
│   └── time_entries.jsonl
└── tenant_demo_client2/
    ├── tickets.jsonl
    └── time_entries.jsonl
```

## Tests

Les tests doivent être ajoutés dans `tests/` (structure à créer).

## Documentation API

Une fois l'API lancée, la documentation Swagger est disponible à:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
