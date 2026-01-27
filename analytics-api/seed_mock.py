#!/usr/bin/env python3
"""Seed database with mock tenants and API keys."""
import sys
import os
import json
from pathlib import Path
from hashlib import sha256
import secrets

# Add app to path
sys.path.insert(0, os.path.dirname(__file__))

from app.database import SessionLocal, engine, Base
from app.models import Tenant, APIKey
from app.config import settings

# Create tables
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    # Load tenants from mock-data/tenants.json
    mock_data_path = Path(settings.MOCK_DATA_PATH) if hasattr(settings, 'MOCK_DATA_PATH') else Path("/app/mock-data")
    tenants_file = mock_data_path / "tenants.json"
    
    if not tenants_file.exists():
        # Fallback to relative path
        tenants_file = Path(__file__).parent.parent / "mock-data" / "tenants.json"
    
    if not tenants_file.exists():
        print(f"ERROR: tenants.json not found at {tenants_file}")
        sys.exit(1)
    
    with open(tenants_file, "r") as f:
        tenants_data = json.load(f)
    
    print(f"Found {len(tenants_data)} tenants in mock data")
    
    # Store API keys to display later
    api_keys_generated = {}
    
    # Create tenants and API keys
    for tenant_data in tenants_data:
        tenant_id = tenant_data["id"]
        tenant_name = tenant_data["name"]
        
        # Check if tenant exists
        existing_tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
        
        if existing_tenant:
            print(f"Tenant {tenant_id} already exists, skipping...")
            # Check if API key exists
            existing_key = db.query(APIKey).filter(APIKey.tenant_id == tenant_id).first()
            if not existing_key:
                # Generate API key for existing tenant
                import uuid as uuid_lib
                tenant_uuid = uuid_lib.UUID(tenant_id) if isinstance(tenant_id, str) else tenant_id
                api_key_value = f"msp_ak_{secrets.token_urlsafe(32)}"
                key_hash = sha256(api_key_value.encode()).hexdigest()
                api_key = APIKey(
                    tenant_id=tenant_uuid,
                    key_hash=key_hash,
                    name=f"Default API Key for {tenant_name}",
                    is_active=True
                )
                db.add(api_key)
                api_keys_generated[tenant_id] = api_key_value
                print(f"  Created API key for existing tenant: {api_key_value}")
            continue
        
        # Create tenant
        tenant = Tenant(
            id=tenant_id,
            name=tenant_name,
            is_active=tenant_data.get("is_active", True),
            llm_enabled=tenant_data.get("llm_enabled", False)
        )
        db.add(tenant)
        print(f"Created tenant: {tenant_id} ({tenant_name})")
        
        # Generate API key
        api_key_value = f"msp_ak_{secrets.token_urlsafe(32)}"
        key_hash = sha256(api_key_value.encode()).hexdigest()
        
        api_key = APIKey(
            tenant_id=tenant_uuid,
            key_hash=key_hash,
            name=f"Default API Key for {tenant_name}",
            is_active=True
        )
        db.add(api_key)
        api_keys_generated[tenant_id] = api_key_value
        
        print(f"  Created API key: {api_key_value}")
        print(f"  Key hash: {key_hash}")
    
    db.commit()
    print("\n✅ Database seeded successfully!")
    print("\nAPI Keys created (save these for testing):")
    print("=" * 60)
    
    # Display generated API keys
    for tenant_data in tenants_data:
        tenant_id = tenant_data["id"]
        if tenant_id in api_keys_generated:
            print(f"Tenant: {tenant_data['name']} ({tenant_id})")
            print(f"  API Key: {api_keys_generated[tenant_id]}")
            print()
    
except Exception as e:
    db.rollback()
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
finally:
    db.close()
