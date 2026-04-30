# dbo.DailySummaryReport

> UNION ALL view aggregating 7 funnel metrics per affiliate per day -- downloads, installs, first-time runs, registrations, leads, and FTDs -- for the affiliate admin dashboard.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Composite: Date + AffiliateID + MetricName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.DailySummaryReport is the primary data source for the affiliate admin dashboard's daily performance view. It unifies seven distinct funnel stages into a single row-per-metric output keyed on Date and AffiliateID, giving affiliate managers a single query point to answer "how did each affiliate perform across the entire acquisition funnel on each day?"

The seven metrics span the full acquisition funnel from first download through first-time deposit (FTD):

1. **Started_Downloads** -- users who downloaded the trading app
2. **Started_Installs** -- install processes initiated (status = 2)
3. **Finished_Installs** -- installs completed successfully (status = 1)
4. **First_Time_Run** -- users who launched the app for the first time (status = 3)
5. **Registrations** -- users who created an account (Tier 1 only)
6. **Leads** -- users who qualified as a lead (Tier 1 only)
7. **FTDs** -- users who made their first deposit (isFirstDeposit = 1)

The download and install metrics are sourced from a cross-database reference to the fiktivo platform database (fiktivo.etoro_Download, fiktivo.etoro_Install), while conversion metrics (registrations, leads, FTDs) come from the local affiliate tracking tables.

---

## 2. Business Logic

### 2.1 UNION ALL Structure

**What**: Seven SELECT branches are combined via UNION ALL, each emitting the same three columns (Date, AffiliateID, MetricName plus a Count column). The consumer aggregates or pivots as needed.

**Rules**:
- Each branch is independent; there is no deduplication between branches
- UNION ALL (not UNION) preserves all rows including any duplicates within a branch

### 2.2 Download Branch

**What**: Counts download events from the external fiktivo platform database.

**Source**: fiktivo.etoro_Download (cross-database reference)

**Rules**:
- No status filter; all download records are counted
- Grouped by Date and AffiliateID

### 2.3 Install Branches (3 metrics)

**What**: Three separate branches over fiktivo.etoro_Install, each filtering on a different status value.

**Source**: fiktivo.etoro_Install (cross-database reference)

**Rules**:
- `status = 2`: install process started (Started_Installs)
- `status = 1`: install completed (Finished_Installs)
- `status = 3`: app launched for the first time post-install (First_Time_Run)

### 2.4 Registrations Branch

**What**: Counts affiliate-attributed registrations for Tier 1 affiliates.

**Source**: dbo.tblaff_Registrations JOIN dbo.tblaff_Registrations_Commissions

**Rules**:
- JOIN on RegistrationID
- `Tier = 1`: only direct/referring affiliate tier
- No additional Valid or AffiliateSaleAccepted filter implied by the dashboard aggregation use case

### 2.5 Leads Branch

**What**: Counts affiliate-attributed lead events for Tier 1 affiliates.

**Source**: dbo.tblaff_Leads JOIN dbo.tblaff_Leads_Commissions

**Rules**:
- JOIN on LeadID
- `Tier = 1`: only direct/referring affiliate tier

### 2.6 FTD Branch

**What**: Counts first-time deposits attributed to affiliates.

**Source**: dbo.tblaff_Deposits

**Rules**:
- `isFirstDeposit = 1`: only the customer's first deposit qualifies as an FTD
- No commission table join needed; FTD presence is the metric

### 2.7 Grouping

**What**: All branches group by Date and AffiliateID.

**Rules**:
- Date is typically derived from the event timestamp (e.g., CAST to date or DATEADD floor)
- COUNT(*) or COUNT(DISTINCT ...) per branch per group
- Output column MetricName carries a string literal label per branch (e.g., 'Started_Downloads', 'FTDs')

---

## 3. Data Overview

Output volume is proportional to: (number of affiliates with activity) x (number of active days) x 7 metrics. For a large affiliate program this can produce millions of rows per year. Dashboard queries typically filter to a specific date range and affiliate(s).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | date / datetime | YES | - | VERIFIED | Calendar day of the metric. All 7 branches group by this field. Used as the primary time dimension in dashboard queries. |
| 2 | AffiliateID | int | YES | - | VERIFIED | Affiliate identifier. Joins to dbo.tblaff_Affiliates. The grouping key for affiliate-level performance. |
| 3 | MetricName | nvarchar | YES | - | VERIFIED | String label identifying which funnel metric this row represents. One of: 'Started_Downloads', 'Started_Installs', 'Finished_Installs', 'First_Time_Run', 'Registrations', 'Leads', 'FTDs'. |
| 4 | Count | int | YES | - | VERIFIED | Aggregate count of events for this affiliate on this date for this metric. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit reference | Affiliate identifier present in all branches |
| (download data) | fiktivo.etoro_Download | Cross-DB base table | Source of Started_Downloads metric |
| (install data) | fiktivo.etoro_Install | Cross-DB base table | Source of Started_Installs, Finished_Installs, First_Time_Run metrics |
| (registration data) | dbo.tblaff_Registrations | Local base table | Source of Registrations metric |
| (registration tier) | dbo.tblaff_Registrations_Commissions | JOIN on RegistrationID | Tier 1 filter for Registrations metric |
| (lead data) | dbo.tblaff_Leads | Local base table | Source of Leads metric |
| (lead tier) | dbo.tblaff_Leads_Commissions | JOIN on LeadID | Tier 1 filter for Leads metric |
| (deposit data) | dbo.tblaff_Deposits | Local base table | Source of FTDs metric |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate admin dashboard | FROM | Consumer (reporting) | Primary data source for the daily funnel performance view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DailySummaryReport (view)
  +-- fiktivo.etoro_Download (cross-DB table)          [Started_Downloads]
  +-- fiktivo.etoro_Install (cross-DB table)           [Started_Installs, Finished_Installs, First_Time_Run]
  +-- dbo.tblaff_Registrations (table)                 [Registrations]
  |     +-- dbo.tblaff_Registrations_Commissions (table, JOIN Tier=1)
  +-- dbo.tblaff_Leads (table)                         [Leads]
  |     +-- dbo.tblaff_Leads_Commissions (table, JOIN Tier=1)
  +-- dbo.tblaff_Deposits (table)                      [FTDs, isFirstDeposit=1]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Cross-DB Table | Started_Downloads branch: COUNT grouped by Date, AffiliateID |
| fiktivo.etoro_Install | Cross-DB Table | Three install-status branches (status 1, 2, 3) |
| dbo.tblaff_Registrations | Table | Registrations branch: source of dates and affiliate attribution |
| dbo.tblaff_Registrations_Commissions | Table | Registrations branch: JOIN to filter Tier = 1 |
| dbo.tblaff_Leads | Table | Leads branch: source of dates and affiliate attribution |
| dbo.tblaff_Leads_Commissions | Table | Leads branch: JOIN to filter Tier = 1 |
| dbo.tblaff_Deposits | Table | FTDs branch: isFirstDeposit = 1 filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate admin dashboard | Application layer | Queries this view for daily funnel metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Performance on wide date ranges depends on the indexes of the 8 underlying tables/views. The two cross-database references (fiktivo.etoro_Download, fiktivo.etoro_Install) add network overhead if the linked server connection is remote.

### 7.2 Constraints

N/A for view.

### 7.3 Cross-Database Notes

The fiktivo.etoro_Download and fiktivo.etoro_Install references assume the fiktivo database is accessible on the same SQL Server instance (or via a linked server). If the fiktivo database is unavailable, all 4 of the 7 UNION branches sourced from it will fail, returning an error rather than a partial result.

---

## 8. Sample Queries

### 8.1 Full daily summary for a single affiliate over the past 30 days
```sql
SELECT Date, MetricName, Count
FROM dbo.DailySummaryReport WITH (NOLOCK)
WHERE AffiliateID = @AffiliateID
  AND Date >= DATEADD(day, -30, CAST(GETDATE() AS date))
ORDER BY Date, MetricName
```

### 8.2 Pivot funnel metrics by day for a date range
```sql
SELECT Date, AffiliateID,
       MAX(CASE WHEN MetricName = 'Started_Downloads'  THEN Count ELSE 0 END) AS Downloads,
       MAX(CASE WHEN MetricName = 'Started_Installs'   THEN Count ELSE 0 END) AS StartedInstalls,
       MAX(CASE WHEN MetricName = 'Finished_Installs'  THEN Count ELSE 0 END) AS FinishedInstalls,
       MAX(CASE WHEN MetricName = 'First_Time_Run'     THEN Count ELSE 0 END) AS FirstTimeRun,
       MAX(CASE WHEN MetricName = 'Registrations'      THEN Count ELSE 0 END) AS Registrations,
       MAX(CASE WHEN MetricName = 'Leads'              THEN Count ELSE 0 END) AS Leads,
       MAX(CASE WHEN MetricName = 'FTDs'               THEN Count ELSE 0 END) AS FTDs
FROM dbo.DailySummaryReport WITH (NOLOCK)
WHERE Date BETWEEN @StartDate AND @EndDate
GROUP BY Date, AffiliateID
ORDER BY Date, AffiliateID
```

### 8.3 Funnel conversion rates across all affiliates for a given day
```sql
SELECT AffiliateID,
       MAX(CASE WHEN MetricName = 'Started_Downloads' THEN Count ELSE 0 END) AS Downloads,
       MAX(CASE WHEN MetricName = 'FTDs'              THEN Count ELSE 0 END) AS FTDs,
       CASE WHEN MAX(CASE WHEN MetricName = 'Started_Downloads' THEN Count ELSE 0 END) > 0
            THEN CAST(MAX(CASE WHEN MetricName = 'FTDs' THEN Count ELSE 0 END) AS float)
               / MAX(CASE WHEN MetricName = 'Started_Downloads' THEN Count ELSE 0 END)
            ELSE NULL END AS DownloadToFTDRate
FROM dbo.DailySummaryReport WITH (NOLOCK)
WHERE Date = @ReportDate
GROUP BY AffiliateID
ORDER BY FTDs DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailySummaryReport | Type: View | Source: fiktivo/dbo/Views/dbo.DailySummaryReport.sql*
