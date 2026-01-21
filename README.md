# MSP Analytics Platform

A production-ready analytics platform for Managed Service Providers (MSPs) to track KPIs, detect anomalies, and generate AI-powered insights from ConnectWise, SmileBack, and SOC data sources.

## Architecture Overview

This platform uses a **hybrid pragmatic architecture**: n8n for orchestration, FastAPI for business logic, PostgreSQL for multi-tenant data storage, and Claude for targeted AI summaries.

```
┌─────────────────────────────────────────────────────────────────┐
│                        MSP Analytics Platform                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────┐     ┌──────────────────┐     ┌─────────────────┐ │
│   │   n8n   │────►│  analytics-api   │────►│   PostgreSQL    │ │
│   │ (cron)  │     │    (FastAPI)     │     │  (multi-tenant) │ │
│   └─────────┘     └────────┬─────────┘     └─────────────────┘ │
│                            │                                    │
│                            ▼                                    │
│                   ┌─────────────────┐                          │
│                   │  External APIs  │                          │
│                   │  • ConnectWise  │                          │
│                   │  • SmileBack    │                          │
│                   │  • SentinelOne  │                          │
│                   │  • MS Defender  │                          │
│                   │  • Claude API   │                          │
│                   └─────────────────┘                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### 12 KPIs Tracked

| KPI | Name | Description |
|-----|------|-------------|
| 01 | Sales Opportunities | Recurring issues indicating upsell potential |
| 02 | Client Training Needs | User ticket patterns suggesting training gaps |
| 03 | Tech Training Needs | Performance gaps and skill development areas |
| 04 | Time Consumption | Hours by client/domain/type with trend detection |
| 05 | Agreement Mismatch | Tickets outside agreement scope for billing recovery |
| 06 | Improvement Projects | High-recurrence issues with ROI-positive solutions |
| 07 | Tech Efficiency | Resolution time, FCR, and satisfaction metrics |
| 08 | Tech Profile | Specialization analysis by domain/client |
| 09 | Tech Comparison | Normalized performance benchmarking |
| 10 | Project Impact | Before/after ticket volume analysis |
| 11 | Ticket Trends | Anomaly detection with Z-score analysis |
| 12 | SOC Metrics | Security event stats and SLA compliance |

### Security Features

The platform implements enterprise-grade security with multi-tenant isolation enforced at the API level (tenant derived from JWT/API-key, never from request body), network segmentation (backend services isolated from internet), rate limiting per tenant/endpoint stored in Redis, and encrypted credentials using Fernet or AES-256-GCM.

## Quick Start

### Prerequisites

You'll need Docker and Docker Compose v2+ installed on your system.

### Installation

Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/YOUR_USERNAME/msp-analytics.git
cd msp-analytics
```

Copy the environment template and configure your credentials:

```bash
cp .env.example .env
# Edit .env with your credentials
```

Start the services:

```bash
docker compose -p msp up -d --build
```

Seed the database with a test tenant and API key:

```bash
docker exec msp-analytics-api python /app/seed.py
```

### Validation

Run the validation script to verify all components are working correctly:

```bash
chmod +x validate.sh
./validate.sh
```

This script validates Docker Compose configuration, service health including Redis with CMD-SHELL expansion, network isolation (backend has no internet, egress does), API key authentication against the database, and rate limiting behavior (60 requests OK, then 429 with Retry-After).

## Configuration

### Environment Variables

The following environment variables must be configured in your `.env` file:

**Database**: `DB_USER` and `DB_PASSWORD` for PostgreSQL authentication.

**Redis**: `REDIS_PASSWORD` for Redis authentication.

**n8n**: `N8N_ENCRYPTION_KEY` (32+ characters), `N8N_ADMIN_USER`, and `N8N_ADMIN_PASSWORD`.

**JWT**: `JWT_SECRET_KEY` (64+ characters) for API authentication.

**Secrets Encryption**: `SECRETS_MASTER_KEY` (32+ characters) and `SECRETS_SALT` (16+ characters).

**External APIs** (optional for Phase 1): ConnectWise credentials (`CW_BASE_URL`, `CW_COMPANY_ID`, `CW_PUBLIC_KEY`, `CW_PRIVATE_KEY`), `SMILEBACK_API_KEY`, SentinelOne credentials, Microsoft Graph credentials, and `ANTHROPIC_API_KEY`.

### Network Architecture

The platform uses three Docker networks for security isolation:

**backend** (internal: true): No internet access. Used by PostgreSQL, Redis, and n8n-worker.

**egress**: Internet access for external API calls. Used only by analytics-api.

**frontend**: For exposed UIs. Used by n8n and Metabase with localhost-only port bindings.

## API Documentation

### Authentication

All endpoints except `/health` require authentication via either an API Key header (`X-API-Key: msp_ak_...`) or a Bearer token (`Authorization: Bearer <jwt>`).

### Endpoints

**Health Check**: `GET /health` returns service status and version.

**Sync Endpoints**: `POST /sync/tickets`, `POST /sync/time-entries`, and `POST /sync/smileback` trigger data synchronization from external sources.

**Compute Endpoints**: `POST /compute/kpi/time-consumption` and `POST /compute/kpi/ticket-trends` calculate KPI metrics.

**LLM Endpoints**: `POST /llm/summarize` generates AI-powered summaries (requires `llm` permission).

### Rate Limits

Rate limits are enforced per tenant using a fixed-window counter: `/sync/*` allows 60 requests per minute, `/compute/*` allows 30 requests per minute, and `/llm/*` allows 10 requests per minute.

## Project Structure

```
msp-analytics/
├── docker-compose.yml          # Service orchestration
├── .env.example                 # Environment template
├── validate.sh                  # Validation script
├── VALIDATION_V2.3.1.md        # Detailed validation docs
└── analytics-api/
    ├── Dockerfile
    ├── requirements.txt
    ├── healthcheck.py           # Docker healthcheck script
    ├── seed.py                  # Database seeding script
    └── app/
        ├── main.py              # FastAPI application
        ├── config.py            # Settings management
        ├── auth/
        │   └── dependencies.py  # TenantContext injection
        ├── middleware/
        │   ├── auth.py          # JWT/API-key validation
        │   └── rate_limit.py    # Redis-based rate limiting
        └── routers/
            ├── health.py
            ├── sync.py
            ├── compute.py
            └── llm.py
```

## Implementation Roadmap

### Phase 1: MVP Core (Weeks 1-3)

The first phase focuses on infrastructure deployment with Docker Compose, database schema creation with multi-tenant support, implementing the /sync/tickets and /sync/time-entries endpoints, deploying KPI 04 (Time Consumption) and KPI 11 (Ticket Trends), creating Metabase dashboards, and setting up Slack alerts for anomalies.

### Phase 2: Pro (Weeks 4-7)

The second phase adds KPI 05 (Agreement Mismatch) and KPI 07 (Tech Efficiency), integrates SmileBack for satisfaction data, implements KPI 01 (Sales Opportunities) and KPI 06 (Projects) with LLM briefs, and automates weekly manager digest emails.

### Phase 3: SOC (Weeks 8-10)

The final phase integrates SentinelOne and Microsoft Defender APIs, normalizes security events, implements KPI 12 (SOC Metrics) with SLA tracking, adds KPI 10 (Project Impact), and completes the runbook and team training.

## Cost Estimate

**Monthly Infrastructure**: Approximately 165 CAD for VPS and managed database.

**Monthly LLM Tokens**: Approximately 21 CAD for Claude API usage.

**Total Monthly Cost**: Approximately 190 CAD.

**Estimated Monthly ROI**: Between 2,300 and 9,300 CAD from agreement mismatch recovery, sales opportunities, efficiency gains, and reduced escalations.

## Contributing

Contributions are welcome. Please ensure all changes pass the validation script before submitting a pull request.

## License

This project is proprietary software. All rights reserved.

## Support

For questions or issues, please open a GitHub issue or contact the development team.
