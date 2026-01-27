"""Internal endpoints for n8n workflows."""
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, date
from app.database import get_db
from app.models import Tenant, RawTicket, RawTimeEntry, KPIDaily
from app.auth.dependencies import verify_service_token, get_tenant_from_query
from app.config import settings
from pathlib import Path
import json

router = APIRouter()


@router.get("/tenants")
async def list_tenants(
    db: Session = Depends(get_db),
    _: bool = Depends(verify_service_token)
) -> List[dict]:
    """List all active tenants."""
    tenants = db.query(Tenant).filter(Tenant.is_active == True).all()
    return [
        {
            "id": str(t.id),
            "name": t.name,
            "is_active": t.is_active,
            "llm_enabled": t.llm_enabled
        }
        for t in tenants
    ]


@router.post("/ingest/tickets")
async def ingest_tickets(
    tenant_id: str = Query(..., description="Tenant ID"),
    db: Session = Depends(get_db),
    _: bool = Depends(verify_service_token)
):
    """Ingest tickets from mock data or real API."""
    # Verify tenant exists
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    
    if settings.MOCK_MODE:
        # Load from mock data
        # Map tenant UUID to folder name (for mock data structure)
        tenant_folder_map = {
            "550e8400-e29b-41d4-a716-446655440000": "tenant_demo_cca",
            "550e8400-e29b-41d4-a716-446655440001": "tenant_demo_client2"
        }
        tenant_folder = tenant_folder_map.get(str(tenant_id), str(tenant_id))
        
        mock_path = Path(settings.MOCK_DATA_PATH)
        tickets_file = mock_path / tenant_folder / "tickets.jsonl"
        
        if not tickets_file.exists():
            return {"message": f"No mock data found at {tickets_file}", "ingested": 0}
        
        tickets_data = []
        with open(tickets_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    tickets_data.append(json.loads(line))
    else:
        # TODO: Fetch from real ConnectWise API
        raise HTTPException(status_code=501, detail="Real API not implemented yet")
    
    # Upsert tickets
    ingested = 0
    for ticket_data in tickets_data:
        ticket = db.query(RawTicket).filter(
            RawTicket.tenant_id == tenant_id,
            RawTicket.cw_ticket_id == ticket_data.get("cw_ticket_id")
        ).first()
        
        if ticket:
            # Update existing
            for key, value in ticket_data.items():
                if hasattr(ticket, key):
                    setattr(ticket, key, value)
        else:
            # Create new
            ticket = RawTicket(tenant_id=tenant_id, **ticket_data)
            db.add(ticket)
        
        ingested += 1
    
    db.commit()
    return {"message": "Tickets ingested successfully", "ingested": ingested}


@router.post("/ingest/time_entries")
async def ingest_time_entries(
    tenant_id: str = Query(..., description="Tenant ID"),
    db: Session = Depends(get_db),
    _: bool = Depends(verify_service_token)
):
    """Ingest time entries from mock data or real API."""
    # Verify tenant exists
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    
    if settings.MOCK_MODE:
        # Load from mock data
        # Map tenant UUID to folder name (for mock data structure)
        tenant_folder_map = {
            "550e8400-e29b-41d4-a716-446655440000": "tenant_demo_cca",
            "550e8400-e29b-41d4-a716-446655440001": "tenant_demo_client2"
        }
        tenant_folder = tenant_folder_map.get(str(tenant_id), str(tenant_id))
        
        mock_path = Path(settings.MOCK_DATA_PATH)
        time_entries_file = mock_path / tenant_folder / "time_entries.jsonl"
        
        if not time_entries_file.exists():
            return {"message": f"No mock data found at {time_entries_file}", "ingested": 0}
        
        entries_data = []
        with open(time_entries_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    entries_data.append(json.loads(line))
    else:
        # TODO: Fetch from real ConnectWise API
        raise HTTPException(status_code=501, detail="Real API not implemented yet")
    
    # Upsert time entries
    ingested = 0
    for entry_data in entries_data:
        entry = db.query(RawTimeEntry).filter(
            RawTimeEntry.tenant_id == tenant_id,
            RawTimeEntry.cw_time_entry_id == entry_data.get("cw_time_entry_id")
        ).first()
        
        if entry:
            # Update existing
            for key, value in entry_data.items():
                if hasattr(entry, key):
                    setattr(entry, key, value)
        else:
            # Create new
            entry = RawTimeEntry(tenant_id=tenant_id, **entry_data)
            db.add(entry)
        
        ingested += 1
    
    db.commit()
    return {"message": "Time entries ingested successfully", "ingested": ingested}


@router.post("/kpi/compute-daily")
async def compute_daily_kpis(
    tenant_id: str = Query(..., description="Tenant ID"),
    date: str = Query(..., description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db),
    _: bool = Depends(verify_service_token)
):
    """Compute daily KPIs for a tenant."""
    # Verify tenant exists
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    
    try:
        kpi_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    # Calculate KPI 04: Time Consumption
    time_entries = db.query(RawTimeEntry).filter(
        RawTimeEntry.tenant_id == tenant_id,
        RawTimeEntry.date_worked == kpi_date
    ).all()
    
    total_minutes = sum(te.minutes or 0 for te in time_entries)
    billable_minutes = sum(te.minutes or 0 for te in time_entries if te.billable)
    non_billable_minutes = total_minutes - billable_minutes
    
    # Calculate KPI 11: Ticket Trends
    tickets = db.query(RawTicket).filter(
        RawTicket.tenant_id == tenant_id
    ).all()
    
    tickets_created = len([t for t in tickets if t.created_at_remote and t.created_at_remote.date() == kpi_date])
    tickets_closed = len([t for t in tickets if t.status == "Closed" and t.updated_at_remote and t.updated_at_remote.date() == kpi_date])
    tickets_open = len([t for t in tickets if t.status not in ["Closed", "Cancelled"]])
    tickets_high_priority = len([t for t in tickets if t.priority in ["High", "Critical"]])
    
    # Simple anomaly detection (Z-score calculation would be more complex)
    # For MVP, we'll use a simple threshold
    avg_tickets_per_day = len(tickets) / 30 if tickets else 0
    anomaly_detected = tickets_created > (avg_tickets_per_day * 2)
    z_score = (tickets_created - avg_tickets_per_day) / (avg_tickets_per_day + 1) if avg_tickets_per_day > 0 else 0
    
    # Upsert KPI record
    kpi = db.query(KPIDaily).filter(
        KPIDaily.tenant_id == tenant_id,
        KPIDaily.kpi_date == kpi_date
    ).first()
    
    if kpi:
        # Update existing
        kpi.total_minutes = total_minutes
        kpi.billable_minutes = billable_minutes
        kpi.non_billable_minutes = non_billable_minutes
        kpi.tickets_created = tickets_created
        kpi.tickets_closed = tickets_closed
        kpi.tickets_open = tickets_open
        kpi.tickets_high_priority = tickets_high_priority
        kpi.anomaly_detected = anomaly_detected
        kpi.z_score = z_score
    else:
        # Create new
        kpi = KPIDaily(
            tenant_id=tenant_id,
            kpi_date=kpi_date,
            total_minutes=total_minutes,
            billable_minutes=billable_minutes,
            non_billable_minutes=non_billable_minutes,
            tickets_created=tickets_created,
            tickets_closed=tickets_closed,
            tickets_open=tickets_open,
            tickets_high_priority=tickets_high_priority,
            anomaly_detected=anomaly_detected,
            z_score=z_score
        )
        db.add(kpi)
    
    db.commit()
    return {
        "message": "KPIs computed successfully",
        "tenant_id": tenant_id,
        "date": date,
        "metrics": {
            "total_minutes": total_minutes,
            "billable_minutes": billable_minutes,
            "tickets_created": tickets_created,
            "tickets_closed": tickets_closed,
            "anomaly_detected": anomaly_detected
        }
    }


@router.post("/exports/generate")
async def generate_exports(
    tenant_id: str = Query(..., description="Tenant ID"),
    date: str = Query(None, description="Date in YYYY-MM-DD format (optional)"),
    db: Session = Depends(get_db),
    _: bool = Depends(verify_service_token)
):
    """Generate Power BI exports for a tenant."""
    # Verify tenant exists
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    
    # Get KPIs for the date (or latest if not specified)
    if date:
        try:
            kpi_date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    else:
        # Get latest KPI date
        latest_kpi = db.query(KPIDaily).filter(
            KPIDaily.tenant_id == tenant_id
        ).order_by(KPIDaily.kpi_date.desc()).first()
        
        if not latest_kpi:
            raise HTTPException(status_code=404, detail="No KPIs found for tenant")
        
        kpi_date = latest_kpi.kpi_date
    
    kpi = db.query(KPIDaily).filter(
        KPIDaily.tenant_id == tenant_id,
        KPIDaily.kpi_date == kpi_date
    ).first()
    
    if not kpi:
        raise HTTPException(status_code=404, detail=f"No KPIs found for date {kpi_date}")
    
    # Generate export data (mock - in production, this would generate CSV/JSON files)
    export_data = {
        "tenant_id": tenant_id,
        "tenant_name": tenant.name,
        "date": str(kpi_date),
        "kpis": {
            "time_consumption": {
                "total_minutes": kpi.total_minutes,
                "billable_minutes": kpi.billable_minutes,
                "non_billable_minutes": kpi.non_billable_minutes
            },
            "ticket_trends": {
                "tickets_created": kpi.tickets_created,
                "tickets_closed": kpi.tickets_closed,
                "tickets_open": kpi.tickets_open,
                "tickets_high_priority": kpi.tickets_high_priority,
                "anomaly_detected": kpi.anomaly_detected
            }
        }
    }
    
    # In production, save to /exports directory
    # For now, just return the data
    return {
        "message": "Export generated successfully",
        "export_data": export_data
    }
