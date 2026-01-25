# 30 - Mock Mode

## Principe

Le Mock Mode permet de développer et tester sans accès aux vraies APIs (ConnectWise, SmileBack, SentinelOne, Defender).

```
MOCK_MODE=true  → Lit les fichiers JSON locaux
MOCK_MODE=false → Appelle les vraies APIs
```

## Configuration

### Variables d'Environnement
```env
MOCK_MODE=true
MOCK_DATA_PATH=/app/mock-data
```

### Structure des Fichiers Mock
```
mock-data/
├── tenants.json
├── tickets/
│   ├── tenant_demo_cca.json
│   └── tenant_demo_client2.json
├── time_entries/
│   ├── tenant_demo_cca.json
│   └── tenant_demo_client2.json
├── csat/
│   ├── tenant_demo_cca.json
│   └── tenant_demo_client2.json
└── security_alerts/
    ├── tenant_demo_cca.json
    └── tenant_demo_client2.json
```

## Format des Fichiers JSON

### tenants.json
```json
[
  {
    "id": "tenant_demo_cca",
    "name": "CCA Demo",
    "is_active": true,
    "llm_enabled": true
  },
  {
    "id": "tenant_demo_client2",
    "name": "Client 2 Demo",
    "is_active": true,
    "llm_enabled": false
  }
]
```

### tickets/tenant_demo_cca.json
```json
[
  {
    "tenant_id": "tenant_demo_cca",
    "cw_ticket_id": "TKT-001",
    "board": "Service",
    "status": "In Progress",
    "priority": "High",
    "summary": "Cannot access email",
    "description": "User reports Outlook not loading...",
    "company": "Acme Corp",
    "owner": "tech1@msp.com",
    "created_at_remote": "2026-01-20T09:00:00Z",
    "updated_at_remote": "2026-01-20T14:30:00Z",
    "sla_status": "OK",
    "estimated_hours": 2.0
  }
]
```

### time_entries/tenant_demo_cca.json
```json
[
  {
    "tenant_id": "tenant_demo_cca",
    "cw_time_entry_id": "TE-001",
    "cw_ticket_id": "TKT-001",
    "member": "tech1@msp.com",
    "work_type": "Remote Support",
    "billable": true,
    "minutes": 45,
    "notes": "Troubleshooting Outlook connectivity",
    "date_worked": "2026-01-20"
  }
]
```

### csat/tenant_demo_cca.json
```json
[
  {
    "tenant_id": "tenant_demo_cca",
    "survey_id": "SRV-001",
    "ticket_id": "TKT-001",
    "score": 5,
    "sentiment": "positive",
    "comment": "Quick resolution, very happy!",
    "submitted_at": "2026-01-20T16:00:00Z"
  }
]
```

### security_alerts/tenant_demo_cca.json
```json
[
  {
    "tenant_id": "tenant_demo_cca",
    "source": "sentinelone",
    "alert_id": "S1-001",
    "severity": "high",
    "title": "Suspicious PowerShell execution",
    "device": "LAPTOP-001",
    "status": "resolved",
    "detected_at": "2026-01-19T08:15:00Z"
  },
  {
    "tenant_id": "tenant_demo_cca",
    "source": "defender",
    "alert_id": "DEF-001",
    "severity": "medium",
    "title": "Potentially unwanted application detected",
    "device": "DESKTOP-002",
    "status": "investigating",
    "detected_at": "2026-01-20T11:30:00Z"
  }
]
```

## Implémentation dans l'API

### Service avec Mode Switching
```python
from pathlib import Path
import json
from app.config import settings

class TicketService:
    def __init__(self):
        self.mock_mode = settings.MOCK_MODE
        self.mock_path = Path(settings.MOCK_DATA_PATH)
    
    async def get_tickets(self, tenant_id: str) -> list:
        if self.mock_mode:
            return self._load_mock_tickets(tenant_id)
        else:
            return await self._fetch_real_tickets(tenant_id)
    
    def _load_mock_tickets(self, tenant_id: str) -> list:
        file_path = self.mock_path / "tickets" / f"{tenant_id}.json"
        if not file_path.exists():
            return []
        with open(file_path) as f:
            return json.load(f)
    
    async def _fetch_real_tickets(self, tenant_id: str) -> list:
        # Appel réel à ConnectWise API
        integration = await self._get_integration(tenant_id, "connectwise")
        # ... implementation réelle
```

## Génération de Données Mock

### Script de Génération
```python
# scripts/generate_mock_data.py
import json
import random
from datetime import datetime, timedelta

def generate_tickets(tenant_id: str, count: int = 50):
    statuses = ["New", "In Progress", "Waiting", "Closed"]
    priorities = ["Low", "Medium", "High", "Critical"]
    boards = ["Service", "Project", "Sales"]
    
    tickets = []
    for i in range(count):
        created = datetime.now() - timedelta(days=random.randint(0, 30))
        tickets.append({
            "tenant_id": tenant_id,
            "cw_ticket_id": f"TKT-{i+1:04d}",
            "board": random.choice(boards),
            "status": random.choice(statuses),
            "priority": random.choice(priorities),
            "summary": f"Sample ticket {i+1}",
            "description": f"Description for ticket {i+1}...",
            "company": f"Company-{random.randint(1, 10)}",
            "owner": f"tech{random.randint(1, 5)}@msp.com",
            "created_at_remote": created.isoformat() + "Z",
            "updated_at_remote": (created + timedelta(hours=random.randint(1, 48))).isoformat() + "Z"
        })
    return tickets
```

## Activation/Désactivation

### Pour le Développement Local
```bash
# .env.local
MOCK_MODE=true
MOCK_DATA_PATH=./mock-data
```

### Pour les Tests
```python
# conftest.py
@pytest.fixture
def mock_mode():
    os.environ["MOCK_MODE"] = "true"
    yield
    os.environ["MOCK_MODE"] = "false"
```

### Pour la Production
```bash
# .env.production
MOCK_MODE=false
# (pas besoin de MOCK_DATA_PATH)
```

## Checklist Mock Data

Pour un MVP fonctionnel, générer:
- [ ] 2 tenants (tenant_demo_cca, tenant_demo_client2)
- [ ] 50-100 tickets par tenant (mix de statuts/priorités)
- [ ] 100 time entries par tenant
- [ ] 30 surveys CSAT par tenant
- [ ] 40 alertes sécurité par tenant (mix S1/Defender)
