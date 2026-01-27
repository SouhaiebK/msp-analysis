"""Authentication dependencies for FastAPI."""
from fastapi import Header, HTTPException, Depends
from sqlalchemy.orm import Session
from hashlib import sha256
from app.database import get_db
from app.models import APIKey, Tenant
from app.config import settings


async def verify_service_token(
    authorization: str = Header(..., alias="Authorization")
) -> bool:
    """Verify service token for internal endpoints."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = authorization.replace("Bearer ", "").strip()
    
    if not settings.SERVICE_TOKEN:
        raise HTTPException(status_code=500, detail="Service token not configured")
    
    if token != settings.SERVICE_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid service token")
    
    return True


async def get_tenant_from_api_key(
    x_api_key: str = Header(..., alias="X-API-Key"),
    db: Session = Depends(get_db)
) -> str:
    """Extract tenant_id from API key."""
    # Hash the API key
    key_hash = sha256(x_api_key.encode()).hexdigest()
    
    # Look up the API key
    api_key = db.query(APIKey).filter(
        APIKey.key_hash == key_hash,
        APIKey.is_active == True
    ).first()
    
    if not api_key:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Verify tenant is active
    tenant = db.query(Tenant).filter(
        Tenant.id == api_key.tenant_id,
        Tenant.is_active == True
    ).first()
    
    if not tenant:
        raise HTTPException(status_code=403, detail="Tenant is not active")
    
    # Update last_used_at
    api_key.last_used_at = datetime.utcnow()
    db.commit()
    
    return str(api_key.tenant_id)


async def get_tenant_from_query(
    tenant_id: str,
    db: Session = Depends(get_db),
    _: bool = Depends(verify_service_token)
) -> str:
    """Get tenant_id from query parameter (for internal endpoints only)."""
    # Verify tenant exists and is active
    tenant = db.query(Tenant).filter(
        Tenant.id == tenant_id,
        Tenant.is_active == True
    ).first()
    
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    
    return tenant_id
