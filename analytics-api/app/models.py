"""SQLAlchemy models for the database."""
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Numeric, Text, Date, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database import Base
import uuid


class Tenant(Base):
    """Tenant model."""
    __tablename__ = "tenants"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    llm_enabled = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class APIKey(Base):
    """API Key model."""
    __tablename__ = "api_keys"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id"), nullable=False)
    key_hash = Column(String(64), unique=True, nullable=False)  # SHA-256 hash
    name = Column(String(255))
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_used_at = Column(DateTime(timezone=True))
    
    __table_args__ = (
        Index("idx_api_keys_tenant_id", "tenant_id"),
        Index("idx_api_keys_key_hash", "key_hash"),
    )


class RawTicket(Base):
    """Raw ticket data from ConnectWise."""
    __tablename__ = "raw_tickets"
    
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id"), nullable=False, primary_key=True)
    cw_ticket_id = Column(String(100), nullable=False, primary_key=True)
    board = Column(String(100))
    status = Column(String(100))
    priority = Column(String(50))
    summary = Column(Text)
    description = Column(Text)
    company = Column(String(255))
    owner = Column(String(255))
    created_at_remote = Column(DateTime(timezone=True))
    updated_at_remote = Column(DateTime(timezone=True))
    sla_status = Column(String(50))
    estimated_hours = Column(Numeric(10, 2))
    ingested_at = Column(DateTime(timezone=True), server_default=func.now())
    
    __table_args__ = (
        Index("idx_raw_tickets_tenant_company", "tenant_id", "company"),
        Index("idx_raw_tickets_tenant_status", "tenant_id", "status"),
        Index("idx_raw_tickets_tenant_created", "tenant_id", "created_at_remote"),
    )


class RawTimeEntry(Base):
    """Raw time entry data from ConnectWise."""
    __tablename__ = "raw_time_entries"
    
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id"), nullable=False, primary_key=True)
    cw_time_entry_id = Column(String(100), nullable=False, primary_key=True)
    cw_ticket_id = Column(String(100))
    member = Column(String(255))
    work_type = Column(String(100))
    billable = Column(Boolean, default=True)
    minutes = Column(Integer)
    notes = Column(Text)
    date_worked = Column(Date)
    ingested_at = Column(DateTime(timezone=True), server_default=func.now())
    
    __table_args__ = (
        Index("idx_raw_time_entries_tenant_ticket", "tenant_id", "cw_ticket_id"),
        Index("idx_raw_time_entries_tenant_date", "tenant_id", "date_worked"),
    )


class KPIDaily(Base):
    """Daily KPI metrics per tenant."""
    __tablename__ = "kpi_daily"
    
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id"), nullable=False, primary_key=True)
    kpi_date = Column(Date, nullable=False, primary_key=True)
    
    # KPI 04: Time Consumption
    total_minutes = Column(Integer, default=0)
    billable_minutes = Column(Integer, default=0)
    non_billable_minutes = Column(Integer, default=0)
    
    # KPI 07: Tech Efficiency
    avg_resolution_minutes = Column(Numeric(10, 2))
    first_call_resolution_rate = Column(Numeric(5, 2))  # Percentage
    avg_satisfaction_score = Column(Numeric(3, 2))
    
    # KPI 11: Ticket Trends
    tickets_created = Column(Integer, default=0)
    tickets_closed = Column(Integer, default=0)
    tickets_open = Column(Integer, default=0)
    tickets_high_priority = Column(Integer, default=0)
    anomaly_detected = Column(Boolean, default=False)
    z_score = Column(Numeric(10, 4))
    
    computed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    __table_args__ = (
        Index("idx_kpi_daily_tenant_date", "tenant_id", "kpi_date"),
    )
