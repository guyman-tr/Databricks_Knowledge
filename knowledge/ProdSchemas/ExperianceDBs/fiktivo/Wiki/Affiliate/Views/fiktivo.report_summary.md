# fiktivo.report_summary

> Master reporting view that aggregates all stages of the affiliate conversion funnel into a single daily summary row, combining download counts, install counts, first-time runs, registrations, leads, FTDs (first-time deposits), and sales.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date (daily aggregate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

report_summary is the master funnel dashboard view for the affiliate system. It produces one row per day with counts for every stage of the affiliate conversion funnel: started downloads, finished downloads, cancelled downloads, started installs, finished installs, first-time runs, impressions (hardcoded to 0 - deprecated), clicks (hardcoded to 0 - deprecated), registrations, leads, first-time deposits (FTD), and sales.

This view is the primary data source for affiliate performance dashboards. It answers the question "how did the entire funnel perform today?" by aggregating all conversion stages into a single denormalized row per day.

The view uses a complex FULL OUTER JOIN chain across 8+ subqueries (one per funnel stage), each independently aggregating data by day. Downloads and installs come from fiktivo-schema tables (etoro_Download, etoro_Install); registrations, leads, deposits, and sales come from cross-schema dbo tables (tblaff_Registrations, tblaff_Leads, tblaff_Deposits, tblaff_Sales with their respective commission tables). Impressions and clicks were removed (by Noga Rozen, 22/7/22) and replaced with hardcoded 0 values.

---

## 2. Business Logic

### 2.1 Conversion Funnel Stages

**What**: Each column represents a stage of the affiliate conversion funnel, aggregated daily.

**Columns/Parameters Involved**: All output columns

**Rules**:
- **Downloads**: Deduplicated by (date, status, ip, rid, serial) per status value. Status 0=Started_DL, 1=Finished_DL, 2=Canceled_DL.
- **Installs**: Same deduplication pattern. Status 1=Finished_Install, 2=Started_Install, 3=First_Time_Run.
- **Registrations**: COUNT of tier-1 registrations from tblaff_Registrations JOIN tblaff_Registrations_Commissions.
- **Leads**: COUNT of tier-1 leads from tblaff_Leads JOIN tblaff_Leads_Commissions.
- **FTD**: COUNT of first deposits (isFirstDeposit=1) from tblaff_Deposits.
- **Sales**: COUNT of tier-1 sales from tblaff_Sales JOIN tblaff_Sales_Commissions.
- **Impressions/Clicks**: Hardcoded to 0 (deprecated, previously from tblaff_Impressions).

### 2.2 FULL OUTER JOIN Date Alignment

**What**: All funnel stages are aligned by date using FULL OUTER JOINs to ensure every date with activity in ANY stage appears in the output.

**Columns/Parameters Involved**: `Date`

**Rules**:
- The Date column is resolved via ISNULL chain across subquery dates (S0, S1, S2, I1, I2, I3, REGISTRATION, LEAD, DEPOSIT, SALE)
- FULL OUTER JOIN ensures a date with sales but no downloads still appears
- ISNULL wraps each metric to convert NULL (no activity) to 0

---

## 3. Data Overview

N/A - The view produces aggregate daily metrics. Most data sources span 2007-2012. etoro_Download is empty so download columns would return 0 for all dates.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | YES | - | CODE-BACKED | Calendar date for the funnel metrics. Derived from ISNULL chain across all subquery dates. Day-level granularity (time stripped). |
| 2 | Started_DL | int | NO | 0 | CODE-BACKED | Count of unique started downloads (status=0) from etoro_Download. Deduplicated by (date, status, ip, rid, serial). ISNULL to 0. |
| 3 | Canceled_DL | int | NO | 0 | CODE-BACKED | Count of unique cancelled downloads (status=2) from etoro_Download. ISNULL to 0. |
| 4 | Finished_DL | int | NO | 0 | CODE-BACKED | Count of unique completed downloads (status=1) from etoro_Download. ISNULL to 0. |
| 5 | Started_Install | int | NO | 0 | CODE-BACKED | Count of unique started installations (status=2) from etoro_Install. ISNULL to 0. |
| 6 | Finished_Install | int | NO | 0 | CODE-BACKED | Count of unique completed installations (status=1) from etoro_Install. ISNULL to 0. |
| 7 | First_Time_Run | int | NO | 0 | CODE-BACKED | Count of unique first-time application runs (status=3) from etoro_Install. ISNULL to 0. |
| 8 | Impressions | int | NO | 0 | CODE-BACKED | Hardcoded to 0. Previously counted ad impressions from tblaff_Impressions (removed by Noga Rozen, 22/7/22). |
| 9 | Clicks | int | NO | 0 | CODE-BACKED | Hardcoded to 0. Previously counted ad clicks from tblaff_ClickCounts (removed by Noga Rozen, 22/7/22). |
| 10 | Registrations | int | NO | 0 | CODE-BACKED | Count of tier-1 registrations per day. Source: dbo.tblaff_Registrations JOIN dbo.tblaff_Registrations_Commissions WHERE Tier=1. ISNULL to 0. |
| 11 | Leads | int | NO | 0 | CODE-BACKED | Count of tier-1 leads per day. Source: dbo.tblaff_Leads JOIN dbo.tblaff_Leads_Commissions WHERE Tier=1. ISNULL to 0. |
| 12 | FTD | int | NO | 0 | CODE-BACKED | Count of first-time deposits per day. Source: dbo.tblaff_Deposits WHERE isFirstDeposit=1. ISNULL to 0. |
| 13 | Sales | int | NO | 0 | CODE-BACKED | Count of tier-1 sales per day. Source: dbo.tblaff_Sales JOIN dbo.tblaff_Sales_Commissions WHERE Tier=1. ISNULL to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Started_DL, Finished_DL, Canceled_DL | fiktivo.etoro_Download | SELECT + GROUP BY | Download counts by status |
| Started_Install, Finished_Install, First_Time_Run | fiktivo.etoro_Install | SELECT + GROUP BY | Install counts by status |
| Registrations | dbo.tblaff_Registrations, dbo.tblaff_Registrations_Commissions | JOIN + GROUP BY | Tier-1 registration counts |
| Leads | dbo.tblaff_Leads, dbo.tblaff_Leads_Commissions | JOIN + GROUP BY | Tier-1 lead counts |
| FTD | dbo.tblaff_Deposits | SELECT + GROUP BY | First deposit counts |
| Sales | dbo.tblaff_Sales, dbo.tblaff_Sales_Commissions | JOIN + GROUP BY | Tier-1 sales counts |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.report_summary (view)
├── fiktivo.etoro_Download (table)
├── fiktivo.etoro_Install (table)
├── dbo.tblaff_Registrations (table, cross-schema)
├── dbo.tblaff_Registrations_Commissions (table, cross-schema)
├── dbo.tblaff_Leads (table, cross-schema)
├── dbo.tblaff_Leads_Commissions (table, cross-schema)
├── dbo.tblaff_Deposits (table, cross-schema)
├── dbo.tblaff_Sales (table, cross-schema)
└── dbo.tblaff_Sales_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Table | Download counts by status (0/1/2) |
| fiktivo.etoro_Install | Table | Install counts by status (1/2/3) |
| dbo.tblaff_Registrations | Table (cross-schema) | Registration event dates |
| dbo.tblaff_Registrations_Commissions | Table (cross-schema) | Tier-1 filter for registrations |
| dbo.tblaff_Leads | Table (cross-schema) | Lead event dates |
| dbo.tblaff_Leads_Commissions | Table (cross-schema) | Tier-1 filter for leads |
| dbo.tblaff_Deposits | Table (cross-schema) | First deposit events (isFirstDeposit=1) |
| dbo.tblaff_Sales | Table (cross-schema) | Sales event dates |
| dbo.tblaff_Sales_Commissions | Table (cross-schema) | Tier-1 filter for sales |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Last 30 days of funnel performance
```sql
SELECT TOP 30 Date, Started_DL, Finished_DL, Finished_Install, First_Time_Run,
       Registrations, Leads, FTD, Sales
FROM fiktivo.report_summary WITH (NOLOCK)
ORDER BY Date DESC
```

### 8.2 Monthly funnel aggregation
```sql
SELECT YEAR(Date) AS Yr, MONTH(Date) AS Mo,
       SUM(Finished_DL) AS Downloads,
       SUM(Finished_Install) AS Installs,
       SUM(Registrations) AS Regs,
       SUM(Leads) AS Leads,
       SUM(FTD) AS FTDs,
       SUM(Sales) AS Sales
FROM fiktivo.report_summary WITH (NOLOCK)
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY Yr DESC, Mo DESC
```

### 8.3 Download-to-sale conversion rate by day
```sql
SELECT Date,
       Finished_DL,
       Sales,
       CASE WHEN Finished_DL > 0
            THEN CAST(Sales AS FLOAT) / Finished_DL * 100
            ELSE 0 END AS ConversionPct
FROM fiktivo.report_summary WITH (NOLOCK)
WHERE Finished_DL > 0
ORDER BY Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.report_summary | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.report_summary.sql*
