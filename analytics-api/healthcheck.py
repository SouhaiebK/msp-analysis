#!/usr/bin/env python3
"""Docker healthcheck script for analytics-api."""
import sys

# Add app to path
sys.path.insert(0, "/app")

def main() -> int:
    try:
        from app.database import engine

        # SQLAlchemy 2.x safe call
        with engine.connect() as conn:
            conn.exec_driver_sql("SELECT 1")

        print("OK")
        return 0
    except Exception as e:
        print(f"Healthcheck failed: {e}")
        return 1

if __name__ == "__main__":
    raise SystemExit(main())