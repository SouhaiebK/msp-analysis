#!/usr/bin/env python3
"""Docker healthcheck script for analytics-api."""
import sys
import os

# Add app to path
sys.path.insert(0, '/app')

try:
    from app.config import settings
    from app.database import engine
    
    # Check database connection
    with engine.connect() as conn:
        conn.execute("SELECT 1")
    
    print("OK")
    sys.exit(0)
except Exception as e:
    print(f"Healthcheck failed: {e}")
    sys.exit(1)
