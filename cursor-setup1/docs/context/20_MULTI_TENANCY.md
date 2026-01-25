# 20 - Multi-Tenancy

## Principe Fondamental

```
⚠️ INVARIANT NON-NÉGOCIABLE:
Le tenant_id est TOUJOURS dérivé de l'authentification (JWT ou API-key).
Il n'est JAMAIS accepté depuis le body de la requête ou les query params non validés.
```

## Stratégie d'Isolation

### 1. Extraction du Tenant

```python
# ✅ CORRECT: Tenant extrait du token
def get_current_tenant(api_key: str = Header(..., alias="X-API-Key")) -> str:
    key_hash = sha256(api_key.encode()).hexdigest()
    key_record = db.query(APIKey).filter(APIKey.key_hash == key_hash).first()
    if not key_record or not key_record.is_active:
        raise HTTPException(401, "Invalid API key")
    return key_record.tenant_id

# ❌ INTERDIT: Tenant depuis le body
def bad_endpoint(request: Request):
    tenant_id = request.json().get("tenant_id")  # DANGER!
```

### 2. Application Automatique

```python
# Le tenant est injecté automatiquement dans toutes les queries
@app.get("/v1/kpis/daily")
def get_daily_kpis(
    date: str,
    tenant_id: str = Depends(get_current_tenant)
):
    # Le tenant_id est garanti par le Depends
    return db.query(KPIDaily).filter(
        KPIDaily.tenant_id == tenant_id,
        KPIDaily.kpi_date == date
    ).all()
```

## Schéma de Tables Multi-Tenant

### Table tenants
```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    llm_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Table api_keys
```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    key_hash TEXT NOT NULL UNIQUE,  -- SHA-256 de la clé
    name TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    last_used_at TIMESTAMPTZ
);
```

### Tables de Données (Pattern)
Toutes les tables de données incluent `tenant_id` comme première colonne de la PK:

```sql
CREATE TABLE raw_tickets (
    tenant_id UUID NOT NULL,
    cw_ticket_id TEXT NOT NULL,
    -- ... autres colonnes
    PRIMARY KEY (tenant_id, cw_ticket_id)
);

CREATE TABLE kpi_daily (
    tenant_id UUID NOT NULL,
    kpi_date DATE NOT NULL,
    -- ... métriques
    PRIMARY KEY (tenant_id, kpi_date)
);
```

## Rate Limiting par Tenant

### Stratégie: Fenêtre Fixe avec Redis

```python
RATE_LIMITS = {
    "v1/kpis": {"limit": 100, "window": 60},      # 100 req/min
    "v1/tickets": {"limit": 200, "window": 60},   # 200 req/min
    "internal/*": {"limit": 1000, "window": 60},  # 1000 req/min (n8n)
}

async def check_rate_limit(tenant_id: str, endpoint: str) -> bool:
    key = f"ratelimit:{tenant_id}:{endpoint}"
    config = RATE_LIMITS.get(endpoint, {"limit": 100, "window": 60})
    
    current = await redis.incr(key)
    if current == 1:
        # Premier hit: set TTL
        await redis.expire(key, config["window"])
    
    if current > config["limit"]:
        raise HTTPException(429, "Rate limit exceeded")
```

### Règle Importante TTL
```
⚠️ EXPIRE uniquement au premier hit (current == 1)
   NE PAS reset le TTL à chaque requête (évite extension infinie)
```

## RLS (Row Level Security) - PostgreSQL

### Activation
```sql
-- Activer RLS sur les tables
ALTER TABLE raw_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_daily ENABLE ROW LEVEL SECURITY;

-- Policy: user voit uniquement ses données
CREATE POLICY tenant_isolation ON raw_tickets
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

### Usage avec SQLAlchemy
```python
# Set le tenant dans la session PostgreSQL
def set_tenant_context(session, tenant_id: str):
    session.execute(text(f"SET app.tenant_id = '{tenant_id}'"))
```

## Tests d'Isolation

### Test: Tenant A ne voit pas Tenant B
```python
def test_tenant_isolation():
    # Créer données pour tenant_A et tenant_B
    create_ticket(tenant_id="A", ticket_id="TKT-001")
    create_ticket(tenant_id="B", ticket_id="TKT-002")
    
    # Requête avec API key de tenant_A
    response = client.get(
        "/v1/tickets",
        headers={"X-API-Key": API_KEY_TENANT_A}
    )
    
    # Doit voir TKT-001, pas TKT-002
    tickets = response.json()
    assert len(tickets) == 1
    assert tickets[0]["cw_ticket_id"] == "TKT-001"
```

### Test: Injection tenant_id ignorée
```python
def test_tenant_injection_ignored():
    # Essai d'injection via body
    response = client.post(
        "/v1/tickets",
        headers={"X-API-Key": API_KEY_TENANT_A},
        json={"tenant_id": "TENANT_B", "...": "..."}  # Injection
    )
    
    # Le tenant doit être A (depuis la clé), pas B
    created = response.json()
    assert created["tenant_id"] == "TENANT_A"
```
