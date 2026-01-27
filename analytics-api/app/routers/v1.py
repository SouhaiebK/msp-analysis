"""Public API v1 endpoints."""
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
from app.database import get_db
from app.models import KPIDaily, RawTicket
from app.auth.dependencies import get_tenant_from_api_key

router = APIRouter()


@router.get("/kpis/daily")
async def get_daily_kpis(
    date: str = Query(..., description="Date in YYYY-MM-DD format"),
    db: Session = Depends(get_db),
    tenant_id: str = Depends(get_tenant_from_api_key)
):
    """Get daily KPIs for the authenticated tenant."""
    try:
        kpi_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    kpi = db.query(KPIDaily).filter(
        KPIDaily.tenant_id == tenant_id,
        KPIDaily.kpi_date == kpi_date
    ).first()
    
    if not kpi:
        raise HTTPException(status_code=404, detail=f"No KPIs found for date {date}")
    
    return {
        "tenant_id": tenant_id,
        "date": date,
        "kpis": {
            "time_consumption": {
                "total_minutes": kpi.total_minutes,
                "billable_minutes": kpi.billable_minutes,
                "non_billable_minutes": kpi.non_billable_minutes
            },
            "tech_efficiency": {
                "avg_resolution_minutes": float(kpi.avg_resolution_minutes) if kpi.avg_resolution_minutes else None,
                "first_call_resolution_rate": float(kpi.first_call_resolution_rate) if kpi.first_call_resolution_rate else None,
                "avg_satisfaction_score": float(kpi.avg_satisfaction_score) if kpi.avg_satisfaction_score else None
            },
            "ticket_trends": {
                "tickets_created": kpi.tickets_created,
                "tickets_closed": kpi.tickets_closed,
                "tickets_open": kpi.tickets_open,
                "tickets_high_priority": kpi.tickets_high_priority,
                "anomaly_detected": kpi.anomaly_detected,
                "z_score": float(kpi.z_score) if kpi.z_score else None
            }
        }
    }


@router.get("/tickets/{cw_ticket_id}/summary")
async def get_ticket_summary(
    cw_ticket_id: str,
    db: Session = Depends(get_db),
    tenant_id: str = Depends(get_tenant_from_api_key)
):
    """Get ticket summary (mock or LLM if enabled)."""
    ticket = db.query(RawTicket).filter(
        RawTicket.tenant_id == tenant_id,
        RawTicket.cw_ticket_id == cw_ticket_id
    ).first()
    
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    # For MVP, return mock summary
    # In production, check tenant.llm_enabled and call Claude API if enabled
    summary = {
        "ticket_id": cw_ticket_id,
        "summary": ticket.summary or "No summary available",
        "status": ticket.status,
        "priority": ticket.priority,
        "company": ticket.company,
        "owner": ticket.owner,
        "created_at": ticket.created_at_remote.isoformat() if ticket.created_at_remote else None,
        "ai_summary": f"Mock summary for ticket {cw_ticket_id}. This is a placeholder for LLM-generated summary."
    }
    
    return summary
