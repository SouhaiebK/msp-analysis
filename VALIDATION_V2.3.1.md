# MSP Analytics Platform — Corrections V2.3.1

## Résumé des corrections appliquées

Ce document détaille les trois corrections demandées pour la validation V2.3.1, plus le correctif pour le test avec API key réelle.

---

## Correction 1 : Réseau backend avec `internal: true`

**Problème V2.3** : Le réseau `backend` était un bridge normal, permettant à tous les services (Postgres, Redis, Metabase) d'accéder à Internet via NAT Docker.

**Solution V2.3.1** : Ajout de `internal: true` sur le réseau `backend`, ce qui coupe l'accès Internet aux services qui n'ont que ce réseau.

```yaml
networks:
  backend:
    driver: bridge
    internal: true   # Coupe l'accès Internet aux services backend-only
  egress:
    driver: bridge   # Accès Internet pour analytics-api
  frontend:
    driver: bridge   # Pour les UIs exposées
```

**Résultat attendu** :

| Service | Réseaux | Accès Internet |
|---------|---------|----------------|
| postgres | backend | ✗ Non |
| redis | backend | ✗ Non |
| analytics-api | backend + egress | ✓ Oui (via egress) |
| n8n | backend + frontend | ✗ Non |
| n8n-worker | backend | ✗ Non |
| metabase | backend + frontend | ✗ Non |

---

## Correction 2 : Healthcheck Redis avec `CMD-SHELL`

**Problème V2.3** : L'utilisation de `["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]` ne permet pas l'expansion de la variable d'environnement car il n'y a pas de shell.

**Solution V2.3.1** : Utilisation de `CMD-SHELL` avec quotes appropriées.

```yaml
redis:
  healthcheck:
    test: ["CMD-SHELL", 'redis-cli -a "$REDIS_PASSWORD" ping | grep -q PONG']
    interval: 10s
    timeout: 5s
    retries: 5
```

**Explication** : `CMD-SHELL` invoque `/bin/sh -c`, permettant l'expansion de `$REDIS_PASSWORD`. Les quotes simples autour de la commande préservent les doubles quotes internes.

---

## Correction 3 : Rate Limiter avec INCR atomique

**Problème V2.3** : Le code utilisait `pipe.incr(key)` suivi de `pipe.expire(key, window)` à chaque requête, ce qui reset le TTL et crée un "piège à quotas" où le compteur ne retombe jamais tant qu'il y a du trafic.

**Solution V2.3.1** : INCR atomique + EXPIRE uniquement au premier hit + TTL réel dans `Retry-After`.

```python
# INCR atomique - retourne le nouveau count
count = await self.redis.incr(key)

# EXPIRE posé UNIQUEMENT au premier hit
if count == 1:
    await self.redis.expire(key, limit_config["window"])

# Vérifier si limite dépassée
if count > limit_config["requests"]:
    # Récupérer le TTL réel pour Retry-After
    ttl = await self.redis.ttl(key)
    raise HTTPException(
        status_code=429,
        detail={...},
        headers={"Retry-After": str(max(ttl, 1))}
    )
```

**Comportement attendu** (fenêtre fixe de 60 secondes, limite 60 requêtes) :

| Temps | Action | Count | TTL |
|-------|--------|-------|-----|
| T+0s | Requête 1 | 1 | 60s (EXPIRE posé) |
| T+1s | Requête 2 | 2 | 59s (pas de reset) |
| ... | ... | ... | ... |
| T+30s | Requête 60 | 60 | 30s |
| T+31s | Requête 61 | 61 | 29s → 429 (Retry-After: 29) |
| T+60s | Clé expire | - | - |
| T+61s | Requête 62 | 1 | 60s (nouvelle fenêtre) |

---

## Correction 4 : Validation avec API key réelle (pas de raccourci test)

**Problème soulevé** : Le script validate.sh utilisait une API key fictive `test_tenant123_...` qui passait par un raccourci dans AuthMiddleware, ce qui ne validait pas le flux complet d'authentification.

**Solution** : Ajout d'un script `seed.py` qui crée un tenant et une vraie API key en base de données, hashée avec SHA-256.

Le flux de validation est maintenant :

1. Seed : création tenant + API key réelle en DB
2. AuthMiddleware : validation de l'API key contre la DB (hash comparison)
3. RateLimitMiddleware : rate limiting basé sur tenant_id validé
4. Test : 65 requêtes pour vérifier 60 OK + 5 × 429

---

## Commandes de validation

### Étape 1 : Configuration Docker Compose

```bash
cd /path/to/msp-analytics
docker compose -p msp config
```

**Sortie attendue** : Configuration YAML valide sans erreur, avec `networks.backend.internal: true` visible.

### Étape 2 : Démarrage des services

```bash
docker compose -p msp up -d --build
```

### Étape 3 : Vérification du statut

```bash
docker compose -p msp ps
```

**Sortie attendue** : Tous les services en état `Up (healthy)` après ~90 secondes.

### Étape 4 : Seed de la base de données

```bash
docker exec msp-analytics-api python /app/seed.py
```

**Sortie attendue** :
```
✓ Connected to database
✓ Tables created/verified
✓ Tenant created: <uuid>
✓ API key created: msp_ak_xxxx...
API Key (store securely, shown only once):
  msp_ak_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Étape 5 : Test d'isolation réseau

**Test A : Backend n'a PAS d'accès Internet**

```bash
docker run --rm --network msp_backend curlimages/curl:8.5.0 \
  -I --connect-timeout 5 https://example.com || echo "NO_EGRESS_OK"
```

**Sortie attendue** : Timeout ou erreur de connexion, puis `NO_EGRESS_OK`.

**Test B : Egress A accès Internet**

```bash
docker run --rm --network msp_egress curlimages/curl:8.5.0 \
  -I --connect-timeout 10 https://example.com
```

**Sortie attendue** : `HTTP/2 200` avec headers de example.com.

### Étape 6 : Test du Rate Limiter avec API key réelle

Le script validate.sh exécute automatiquement ce test après le seed.

**Sortie attendue** :

```
Testing rate limiter with REAL API key (prefix: msp_ak_xxxx...)
Limit: 60 requests per minute for /sync/ endpoints

Request 1: 200 OK
Request 2: 200 OK
Request 3: 200 OK
Request 60: 200 OK
Request 61: 429 Rate Limited (Retry-After: 58s)
Request 62: 429 Rate Limited (Retry-After: 57s)
...

RESULTS:
  Successful (200):    60
  Rate limited (429):  5
  Auth failed (401):   0
  Errors:              0
  Last Retry-After:    56s

✓ PASS: Rate limiter working correctly!
```

---

## Script de validation complet

```bash
./validate.sh
```

Ce script exécute automatiquement toutes les étapes ci-dessus et affiche un résumé.

---

## Checklist de validation finale

| # | Critère | Attendu |
|---|---------|---------|
| 1 | Docker Compose config valide | ✓ Pas d'erreur |
| 2 | Tous les services healthy | ✓ `Up (healthy)` |
| 3 | Redis healthcheck passe | ✓ Pas d'erreur auth |
| 4 | API key seedée en DB | ✓ Clé générée et hashée |
| 5 | Backend network isolé | ✓ Timeout sur curl externe |
| 6 | Egress network fonctionnel | ✓ 200 sur example.com |
| 7 | Auth via DB (pas shortcut) | ✓ 0 erreurs 401 |
| 8 | Rate limiter: 60 requêtes OK | ✓ 60 × 200 |
| 9 | Rate limiter: 61+ requêtes bloquées | ✓ 429 avec Retry-After > 0 |
| 10 | Retry-After décroît (pas de reset TTL) | ✓ TTL décroît naturellement |

---

## Fichiers modifiés

| Fichier | Modification |
|---------|--------------|
| `docker-compose.yml` | `networks.backend.internal: true` + healthcheck Redis `CMD-SHELL` |
| `analytics-api/app/middleware/rate_limit.py` | INCR + EXPIRE au 1er hit + TTL dans Retry-After |
| `analytics-api/app/middleware/auth.py` | Validation API key contre DB (avec fallback test) |
| `analytics-api/seed.py` | Nouveau script de seed tenant + API key |
| `validate.sh` | Appel au seed + test avec API key réelle |
