# 40 - Catalogue des 12 KPIs

## Vue d'Ensemble

| # | KPI | Phase MVP | Source Principale |
|---|-----|-----------|-------------------|
| 01 | Sales Opportunities | Phase 2 | Tickets + Agreements |
| 02 | Client Training Needs | Phase 2 | Tickets |
| 03 | Tech Training Needs | Phase 2 | Tickets |
| 04 | Time Consumption | **Phase 1 (MVP)** | Time Entries |
| 05 | Agreement Mismatch | Phase 2 | Tickets + Agreements |
| 06 | Improvement Projects | Phase 2 | Tickets + LLM |
| 07 | Tech Efficiency | **Phase 1 (MVP)** | Tickets + Time Entries |
| 08 | Tech Profile | Phase 2 | Tickets + Time Entries |
| 09 | Tech Comparison | Phase 2 | Tickets + Time Entries |
| 10 | Project Impact | Phase 3 | Tickets (before/after) |
| 11 | Ticket Trends | **Phase 1 (MVP)** | Tickets |
| 12 | SOC Metrics | Phase 3 | Security Alerts |

---

## Détail des KPIs

### 01. Sales Opportunities
**Description**: Identifie les opportunités de vente récurrentes basées sur les patterns de tickets.

**Signaux**:
- Tickets fréquents sur le même sujet → formation ou projet d'amélioration
- Tickets hors périmètre d'accord → extension de contrat

**Calcul**:
```sql
SELECT 
    company,
    board,
    COUNT(*) as ticket_count,
    CASE WHEN COUNT(*) > 5 THEN 'HIGH' ELSE 'MEDIUM' END as opportunity_level
FROM raw_tickets
WHERE created_at_remote > NOW() - INTERVAL '30 days'
GROUP BY company, board
HAVING COUNT(*) > 3
```

---

### 02. Client Training Needs
**Description**: Détecte les besoins de formation côté client (tickets user error, how-to).

**Signaux**:
- Mots-clés: "how to", "training", "doesn't know", "user error"
- Tickets répétitifs du même type

**Calcul**:
```sql
SELECT 
    company,
    COUNT(*) as training_tickets,
    ARRAY_AGG(DISTINCT summary) as topics
FROM raw_tickets
WHERE (summary ILIKE '%how to%' OR summary ILIKE '%training%')
GROUP BY company
```

---

### 03. Tech Training Needs
**Description**: Identifie les domaines où les techniciens ont besoin de formation.

**Signaux**:
- Temps de résolution anormalement long par tech/domaine
- Tickets escaladés fréquemment
- Tickets rouverts

**Calcul**:
```sql
SELECT 
    owner,
    board,
    AVG(resolution_minutes) as avg_resolution,
    COUNT(*) FILTER (WHERE status = 'Reopened') as reopened_count
FROM raw_tickets
GROUP BY owner, board
HAVING AVG(resolution_minutes) > (SELECT AVG(resolution_minutes) * 1.5 FROM raw_tickets)
```

---

### 04. Time Consumption ⭐ MVP
**Description**: Répartition du temps par client, domaine, type de travail.

**Métriques**:
- Minutes billable vs non-billable par client
- Répartition par work_type
- Tendance sur 7/30 jours

**Calcul**:
```sql
SELECT 
    company,
    work_type,
    SUM(minutes) FILTER (WHERE billable = true) as billable_minutes,
    SUM(minutes) FILTER (WHERE billable = false) as non_billable_minutes,
    SUM(minutes) as total_minutes
FROM raw_time_entries te
JOIN raw_tickets t ON t.cw_ticket_id = te.cw_ticket_id AND t.tenant_id = te.tenant_id
WHERE date_worked >= CURRENT_DATE - 7
GROUP BY company, work_type
```

---

### 05. Agreement Mismatch
**Description**: Tickets travaillés hors du périmètre de l'accord client.

**Signaux**:
- Ticket sans agreement associé
- Board/type non couvert par l'agreement actif

**Calcul**:
```sql
SELECT 
    t.company,
    t.cw_ticket_id,
    t.summary,
    a.name as agreement_name,
    CASE WHEN a.id IS NULL THEN 'NO_AGREEMENT' ELSE 'MISMATCH' END as issue
FROM raw_tickets t
LEFT JOIN raw_agreements a ON t.company = a.company AND t.tenant_id = a.tenant_id
WHERE t.board NOT IN (/* covered boards from agreement */)
```

---

### 06. Improvement Projects
**Description**: Projets d'amélioration identifiés avec estimation du ROI.

**Approche**:
- Analyse LLM des tickets fréquents → suggestion de projet
- Calcul du temps économisé potentiel

**Output** (LLM):
```json
{
  "project": "Password Reset Self-Service",
  "trigger": "45 tickets 'password reset' in 30 days",
  "estimated_savings_hours_per_month": 15,
  "implementation_effort": "Medium"
}
```

---

### 07. Tech Efficiency ⭐ MVP
**Description**: Mesures d'efficacité par technicien.

**Métriques**:
- TTR (Time to Resolution) moyen
- FCR (First Call Resolution) %
- Tickets par jour
- Ratio billable

**Calcul**:
```sql
SELECT 
    owner,
    AVG(EXTRACT(EPOCH FROM (updated_at_remote - created_at_remote))/3600) as avg_ttr_hours,
    COUNT(*) FILTER (WHERE status = 'Closed' AND reopened_count = 0) * 100.0 / COUNT(*) as fcr_pct,
    COUNT(*) as tickets_handled
FROM raw_tickets
WHERE status = 'Closed'
GROUP BY owner
```

---

### 08. Tech Profile
**Description**: Profil de spécialisation par technicien.

**Métriques**:
- Répartition du temps par board/type
- Points forts (faible TTR)
- Points d'amélioration (haut TTR)

---

### 09. Tech Comparison
**Description**: Benchmarking normalisé entre techniciens.

**Métriques** (normalisées par difficulté):
- Score global
- Comparaison aux moyennes
- Tendance sur 30 jours

---

### 10. Project Impact
**Description**: Analyse avant/après pour les projets d'amélioration.

**Métriques**:
- Volume tickets avant vs après
- Temps moyen avant vs après
- ROI calculé

---

### 11. Ticket Trends ⭐ MVP
**Description**: Détection d'anomalies dans les volumes de tickets.

**Méthode**: Z-score sur rolling window

**Calcul**:
```sql
WITH daily_counts AS (
    SELECT 
        DATE(created_at_remote) as ticket_date,
        COUNT(*) as count
    FROM raw_tickets
    GROUP BY DATE(created_at_remote)
),
stats AS (
    SELECT 
        AVG(count) as mean,
        STDDEV(count) as stddev
    FROM daily_counts
    WHERE ticket_date >= CURRENT_DATE - 30
)
SELECT 
    ticket_date,
    count,
    (count - mean) / NULLIF(stddev, 0) as z_score,
    CASE 
        WHEN ABS((count - mean) / NULLIF(stddev, 0)) > 2 THEN 'ANOMALY'
        ELSE 'NORMAL'
    END as status
FROM daily_counts, stats
```

---

### 12. SOC Metrics
**Description**: Métriques de sécurité et conformité SLA.

**Sources**: SentinelOne, Microsoft Defender

**Métriques**:
- Alertes par severity
- MTTR (Mean Time to Resolution) par type
- SLA compliance %
- Devices avec alertes récurrentes

**Calcul**:
```sql
SELECT 
    source,
    severity,
    COUNT(*) as alert_count,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved_count,
    AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/3600) as avg_mttr_hours
FROM raw_security_alerts
WHERE detected_at >= CURRENT_DATE - 7
GROUP BY source, severity
```

---

## Table kpi_daily

```sql
CREATE TABLE kpi_daily (
    tenant_id UUID NOT NULL,
    kpi_date DATE NOT NULL,
    
    -- Volumes
    new_tickets INT,
    closed_tickets INT,
    backlog_open INT,
    
    -- Time
    billable_minutes INT,
    non_billable_minutes INT,
    
    -- Performance
    avg_ttr_minutes INT,
    avg_first_response_minutes INT,
    fcr_rate NUMERIC(5,2),
    
    -- Quality
    csat_avg NUMERIC(3,2),
    nps INT,
    sla_breach_count INT,
    
    -- Security
    security_alerts_high INT,
    security_alerts_medium INT,
    security_alerts_low INT,
    
    -- Anomalies
    ticket_zscore NUMERIC(5,2),
    anomaly_detected BOOLEAN,
    
    PRIMARY KEY (tenant_id, kpi_date)
);
```
