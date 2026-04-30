# dbo.SUMMARY_DownloadsRegistrations

> Pre-aggregated daily summary of downloads, installs, registrations, leads, and FTDs per affiliate, used as a materialized cache for the DailySummaryReport view.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Composite (Date, AffiliateID) via clustered index |
| **Partition** | No |
| **Indexes** | 2 active (clustered + AffiliateID) |

---

## 1. Business Meaning

dbo.SUMMARY_DownloadsRegistrations stores pre-computed daily totals of key affiliate metrics: started downloads, started installs, finished installs, first-time runs, registrations, leads, and FTDs (first-time deposits). Each row summarizes one day's activity for one affiliate.

This table serves as a materialized summary cache, likely populated by an ETL job that aggregates data from the individual event tables (tblaff_Registrations, tblaff_Leads, tblaff_Deposits, etc.) and external download/install tracking. The DailySummaryReport view provides similar data computed on-the-fly; this table provides the pre-computed equivalent for faster dashboard queries.

Contains ~515K rows spanning the historical affiliate activity period.

---

## 2. Business Logic

### 2.1 Daily Affiliate Funnel Metrics

**What**: Tracks the full customer acquisition funnel per affiliate per day.

**Columns/Parameters Involved**: `Started_Downloads`, `Started_Installs`, `Finished_Installs`, `First_Time_Run`, `Registrations`, `Leads`, `FTDs`

**Rules**:
- Funnel progression: Downloads -> Installs -> First Run -> Registration -> Lead -> FTD
- Each metric is a daily count for the given affiliate
- FTDs (first-time deposits) are the most valuable conversion event for CPA-based affiliates
- NULL values indicate no activity for that metric on that day

---

## 3. Data Overview

Table contains 515,016 rows of daily aggregate records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | YES | - | VERIFIED | The date for this daily summary. Part of the clustered index key. |
| 2 | AffiliateID | bigint | YES | - | VERIFIED | The affiliate this summary belongs to. Maps to tblaff_Affiliates. Part of the clustered index key. Indexed separately for affiliate-specific lookups. |
| 3 | Started_Downloads | int | YES | - | CODE-BACKED | Count of unique app/software download starts for this affiliate on this date. |
| 4 | Started_Installs | int | YES | - | CODE-BACKED | Count of unique installation starts. |
| 5 | Finished_Installs | int | YES | - | CODE-BACKED | Count of completed installations. |
| 6 | First_Time_Run | int | YES | - | CODE-BACKED | Count of first app launches after installation. |
| 7 | Registrations | int | YES | - | CODE-BACKED | Count of customer registrations attributed to this affiliate. |
| 8 | Leads | int | YES | - | CODE-BACKED | Count of qualified leads (typically started-but-not-completed registrations). |
| 9 | FTDs | int | YES | - | VERIFIED | Count of first-time deposits. The key CPA conversion metric. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate for this summary |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CLU_IDX_SUMMARY_DownloadsRegistrations | CLUSTERED | Date, AffiliateID | - | - | Active (fill 95%, PAGE) |
| IDX_SUMMARY_DownloadsRegistrations_AffiliateID | NC | AffiliateID | - | - | Active (fill 95%, PAGE) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Daily funnel for an affiliate
```sql
SELECT Date, Started_Downloads, Started_Installs, Finished_Installs,
       First_Time_Run, Registrations, Leads, FTDs
FROM dbo.SUMMARY_DownloadsRegistrations WITH (NOLOCK)
WHERE AffiliateID = @AffiliateID
ORDER BY Date DESC
```

### 8.2 Top affiliates by FTDs in a date range
```sql
SELECT AffiliateID, SUM(FTDs) AS TotalFTDs, SUM(Registrations) AS TotalRegistrations
FROM dbo.SUMMARY_DownloadsRegistrations WITH (NOLOCK)
WHERE Date BETWEEN @StartDate AND @EndDate
GROUP BY AffiliateID
ORDER BY TotalFTDs DESC
```

### 8.3 Conversion funnel analysis
```sql
SELECT AffiliateID,
       SUM(Started_Downloads) AS Downloads,
       SUM(Registrations) AS Registrations,
       SUM(FTDs) AS FTDs,
       CASE WHEN SUM(Registrations) > 0
            THEN CAST(SUM(FTDs) AS FLOAT) / SUM(Registrations) * 100
            ELSE 0 END AS FTDConversionPct
FROM dbo.SUMMARY_DownloadsRegistrations WITH (NOLOCK)
GROUP BY AffiliateID
HAVING SUM(Registrations) > 10
ORDER BY FTDConversionPct DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 8.9/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.SUMMARY_DownloadsRegistrations | Type: Table | Source: fiktivo/dbo/Tables/dbo.SUMMARY_DownloadsRegistrations.sql*
