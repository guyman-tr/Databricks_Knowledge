# fiktivo.report_summary

> Daily aggregate dashboard view combining download, install, impression, registration, lead, first-time deposit, and sales metrics across the entire affiliate funnel into a single daily summary row.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base tables: fiktivo.etoro_Download, fiktivo.etoro_Install, dbo.tblaff_Registrations, dbo.tblaff_Leads, dbo.tblaff_Deposits, dbo.tblaff_Sales |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view produces a comprehensive daily funnel summary for the affiliate platform. Each row represents one day and contains aggregate counts for every stage of the affiliate conversion funnel: downloads (started/finished/cancelled), installs (started/finished/first-time-run), impressions, clicks, registrations, leads, first-time deposits (FTD), and sales.

This is the primary reporting view for affiliate performance dashboards. It answers the question "What happened today across all affiliates?" by combining data from six different source tables via FULL OUTER JOINs on date. The FULL OUTER JOIN pattern ensures that days with activity in only some metrics still appear (e.g., a day with registrations but no downloads).

Note: Impressions and Clicks are hardcoded to 0 - the original implementation referenced tblaff_Impressions/tblaff_ClickCounts tables, but this was commented out (removed by Noga Rozen, 22/7/22).

---

## 2. Business Logic

### 2.1 Full Funnel Daily Aggregation

**What**: Combines all affiliate conversion metrics into a single daily view using FULL OUTER JOINs.

**Columns/Parameters Involved**: All 13 output columns

**Rules**:
- Downloads from fiktivo.etoro_Download: three subqueries for status 0/1/2, each with DISTINCT dedup on (date, status, ip, rid, raf, serial)
- Installs from fiktivo.etoro_Install: three subqueries for status 1/2/3 with same dedup logic
- Registrations from dbo.tblaff_Registrations + dbo.tblaff_Registrations_Commissions WHERE Tier=1
- Leads from dbo.tblaff_Leads + dbo.tblaff_Leads_Commissions WHERE Tier=1
- FTD from dbo.tblaff_Deposits WHERE isFirstDeposit=1
- Sales from dbo.tblaff_Sales + dbo.tblaff_Sales_Commissions WHERE Tier=1
- All date values truncated to midnight for daily grouping
- ISNULL(..., 0) on all counts to produce 0 instead of NULL for missing metrics
- Impressions and Clicks always return 0 (legacy - original code commented out)

**Diagram**:
```
Affiliate Funnel (top to bottom):

[Impressions] --> [Clicks] --> [Downloads Started] --> [Downloads Finished]
                                                              |
                                                              v
                                                     [Installs Started]
                                                              |
                                                     [Installs Finished]
                                                              |
                                                     [First Time Run]
                                                              |
                                             [Registrations] + [Leads]
                                                              |
                                                           [FTD]
                                                              |
                                                          [Sales]

All aggregated per day into one report_summary row
```

---

## 3. Data Overview

| Date | Started_DL | Finished_DL | Finished_Install | First_Time_Run | Registrations | Leads | FTD | Sales | Meaning |
|------|-----------|-------------|------------------|----------------|---------------|-------|-----|-------|---------|
| (NULL) | 0 | 0 | 0 | 0 | 903 | 0 | 0 | 0 | Date is NULL because download/install tables are empty; only registration data exists for this time period. 903 registrations with no corresponding download or deposit data. |
| (NULL) | 0 | 0 | 0 | 0 | 10057 | 0 | 0 | 0 | Peak registration day with 10,057 registrations but no other funnel activity recorded. High registration volume suggests a marketing campaign or partner integration push. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | YES | - | CODE-BACKED | Calendar date (truncated to midnight) for this daily summary. Can be NULL when only some subqueries return data and the FULL OUTER JOIN produces unmatched rows. |
| 2 | Started_DL | INT | NO | - | CODE-BACKED | Count of downloads started (status=0) from fiktivo.etoro_Download. ISNULL default 0. Deduplicated by (date, status, ip, rid, raf, serial). |
| 3 | Canceled_DL | INT | NO | - | CODE-BACKED | Count of downloads cancelled (status=2) from fiktivo.etoro_Download. ISNULL default 0. |
| 4 | Finished_DL | INT | NO | - | CODE-BACKED | Count of downloads completed (status=1) from fiktivo.etoro_Download. ISNULL default 0. |
| 5 | Started_Install | INT | NO | - | CODE-BACKED | Count of installs started (status=2) from fiktivo.etoro_Install. ISNULL default 0. |
| 6 | Finished_Install | INT | NO | - | CODE-BACKED | Count of installs completed (status=1) from fiktivo.etoro_Install. ISNULL default 0. |
| 7 | First_Time_Run | INT | NO | - | CODE-BACKED | Count of first-time application runs (status=3) from fiktivo.etoro_Install. ISNULL default 0. |
| 8 | Impressions | INT | NO | - | CODE-BACKED | Always 0. Originally from tblaff_Impressions/tblaff_ImpressionCounts but commented out (removed 22/7/22 by Noga Rozen). |
| 9 | Clicks | INT | NO | - | CODE-BACKED | Always 0. Originally from tblaff_ClickCounts but commented out (removed 22/7/22). |
| 10 | Registrations | INT | NO | - | CODE-BACKED | Count of Tier 1 registrations from dbo.tblaff_Registrations + dbo.tblaff_Registrations_Commissions WHERE Tier=1. |
| 11 | Leads | INT | NO | - | CODE-BACKED | Count of Tier 1 leads from dbo.tblaff_Leads + dbo.tblaff_Leads_Commissions WHERE Tier=1. |
| 12 | FTD | INT | NO | - | CODE-BACKED | Count of first-time deposits from dbo.tblaff_Deposits WHERE isFirstDeposit=1. Key conversion metric. |
| 13 | Sales | INT | NO | - | CODE-BACKED | Count of Tier 1 sales from dbo.tblaff_Sales + dbo.tblaff_Sales_Commissions WHERE Tier=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | [fiktivo.etoro_Download](../Tables/fiktivo.etoro_Download.md) | View base table | Source for Started_DL, Finished_DL, Canceled_DL. |
| (FROM) | [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md) | View base table | Source for Started_Install, Finished_Install, First_Time_Run. |
| (FROM) | dbo.tblaff_Registrations | View base table | Source for Registrations (Tier 1). |
| (JOIN) | dbo.tblaff_Registrations_Commissions | View base table | Joined for Tier filter on registrations. |
| (FROM) | dbo.tblaff_Leads | View base table | Source for Leads (Tier 1). |
| (JOIN) | dbo.tblaff_Leads_Commissions | View base table | Joined for Tier filter on leads. |
| (FROM) | dbo.tblaff_Deposits | View base table | Source for FTD (isFirstDeposit=1). |
| (FROM) | dbo.tblaff_Sales | View base table | Source for Sales (Tier 1). |
| (JOIN) | dbo.tblaff_Sales_Commissions | View base table | Joined for Tier filter on sales. |

### 5.2 Referenced By (other objects point to this)

No objects in the fiktivo schema reference this view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.report_summary (view)
    ├── fiktivo.etoro_Download (table)
    ├── fiktivo.etoro_Install (table)
    ├── dbo.tblaff_Registrations (table)
    ├── dbo.tblaff_Registrations_Commissions (table)
    ├── dbo.tblaff_Leads (table)
    ├── dbo.tblaff_Leads_Commissions (table)
    ├── dbo.tblaff_Deposits (table)
    ├── dbo.tblaff_Sales (table)
    └── dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Table | Three subqueries for download status 0/1/2 |
| fiktivo.etoro_Install | Table | Three subqueries for install status 1/2/3 |
| dbo.tblaff_Registrations | Table | COUNT for Tier 1 registrations |
| dbo.tblaff_Registrations_Commissions | Table | JOIN for Tier filter |
| dbo.tblaff_Leads | Table | COUNT for Tier 1 leads |
| dbo.tblaff_Leads_Commissions | Table | JOIN for Tier filter |
| dbo.tblaff_Deposits | Table | COUNT WHERE isFirstDeposit=1 |
| dbo.tblaff_Sales | Table | COUNT for Tier 1 sales |
| dbo.tblaff_Sales_Commissions | Table | JOIN for Tier filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Full daily funnel report
```sql
SELECT Date, Started_DL, Finished_DL, Finished_Install, First_Time_Run,
       Registrations, Leads, FTD, Sales
FROM fiktivo.report_summary WITH (NOLOCK)
WHERE Date IS NOT NULL
ORDER BY Date DESC
```

### 8.2 Conversion rates by day
```sql
SELECT Date,
       Registrations,
       FTD,
       CASE WHEN Registrations > 0 THEN CAST(FTD * 100.0 / Registrations AS DECIMAL(5,1)) ELSE 0 END AS FTD_Rate_Pct
FROM fiktivo.report_summary WITH (NOLOCK)
WHERE Date IS NOT NULL AND Registrations > 0
ORDER BY Date DESC
```

### 8.3 Monthly summary rollup
```sql
SELECT YEAR(Date) AS Yr, MONTH(Date) AS Mo,
       SUM(Registrations) AS Registrations,
       SUM(Leads) AS Leads,
       SUM(FTD) AS FTD,
       SUM(Sales) AS Sales
FROM fiktivo.report_summary WITH (NOLOCK)
WHERE Date IS NOT NULL
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY Yr DESC, Mo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.report_summary | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.report_summary.sql*
