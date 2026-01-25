# 00 - Project Summary: MSP Analytics Platform

## Objectif
Plateforme d'analytics multi-tenant pour MSP (Managed Service Providers) qui:
- Ingère les données opérationnelles depuis ConnectWise, SmileBack, SentinelOne, Microsoft Defender
- Produit 12 KPIs quotidiens + rapports Power BI par client
- Génère des insights IA (résumés tickets, détection anomalies)
- Minimise l'overhead DevOps avec une architecture low-ops

## Stack MVP
- **Backend API**: FastAPI + Pydantic + SQLAlchemy
- **Base de données**: PostgreSQL avec RLS
- **Cache/Rate-limit**: Redis
- **Orchestration**: n8n (cron jobs, workflows)
- **Dashboard**: Metabase (MVP) ou React + Tailwind (V2)
- **LLM**: Claude API (Anthropic)
- **Conteneurisation**: Docker + Coolify

## État Actuel du Repo

### ✅ En Place
- VPS Hostinger KVM2 provisionné
- Coolify déployé
- n8n Community self-hosted
- PostgreSQL déployé
- Configuration Docker Compose avec 3 réseaux isolés
- Documentation (README, VALIDATION_V2.3.1.md)

### ❌ À Créer
- `analytics-api/` - Code FastAPI
- `mock-data/` - Fichiers JSON de simulation
- Schéma DB complet avec RLS
- Workflows n8n (WF-01 à WF-20)
- Dashboard web ou configuration Metabase

## Scope MVP (V1)

### In-Scope
- ConnectWise Manage: tickets, time entries, agreements
- SmileBack: CSAT/NPS
- SentinelOne: alerts/incidents
- Microsoft Defender: alerts/incidents
- Web Dashboard: KPIs quotidiens (lecture seule)
- Power BI: rapport par client (refresh quotidien)
- LLM: résumés tickets + insights (opt-in par tenant)

### Out-of-Scope (V1)
- Fortinet/SonicWall logs
- Rapid7
- Dashboards temps réel (V1 = daily)
- Ingestion complète des pièces jointes

## Critères de Succès MVP
1. Isolation multi-tenant vérifiée
2. KPIs quotidiens visibles dans dashboard
3. Exports Power BI générés quotidiennement par tenant
4. Ingestion stable avec retries + dead-letter
5. Audit logs produits pour actions clés
6. Rate limiting fonctionnel
