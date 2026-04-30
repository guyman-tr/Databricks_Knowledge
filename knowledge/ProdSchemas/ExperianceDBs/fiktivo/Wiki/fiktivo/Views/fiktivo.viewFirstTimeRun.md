# fiktivo.viewFirstTimeRun

> Returns first-time application run events (status=3) from etoro_Install with affiliate attribution, providing the first-run component of the unified affiliate activity report.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base table: fiktivo.etoro_Install |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view extracts first-time application run events (status=3) from `fiktivo.etoro_Install` and outputs a standardized (Date, AffiliateID, SerialID) tuple. A first-time run indicates the visitor not only downloaded and installed the application but actually launched it for the first time - a strong conversion signal deeper in the funnel than download or install completion.

The view feeds into `fiktivo.viewUnion` alongside viewDownloads, viewInstalls, viewLeads, and viewSales. It also feeds into `fiktivo.report_summary` as the First_Time_Run metric.

---

## 2. Business Logic

### 2.1 First-Time Run Extraction

**What**: Filters install events to only those where the application was launched for the first time.

**Columns/Parameters Involved**: `Date`, `AffiliateID`, `SerialID`

**Rules**:
- Inner subquery: SELECT DISTINCT on date (truncated), status, ISNULL(ip, 'Unknown'), ISNULL(rid, 0), ISNULL(serial, '') WHERE status='3'
- Outer query: SELECT DISTINCT Date, AffiliateID, SerialID
- Status 3 = First Time Run (the app was launched for the first time after installation)

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|------|-------------|----------|---------|
| 2012-01-13 | 3 | (empty) | First-time run attributed to the house affiliate (ID=3). No sub-affiliate tracking. |
| 2012-01-16 | 3 | (empty) | Another first-time run for the house affiliate. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | NO | - | CODE-BACKED | First-time run date truncated to midnight. Computed from fiktivo.etoro_Install.date. Inherited from [etoro_Install](../Tables/fiktivo.etoro_Install.md). |
| 2 | AffiliateID | BIGINT | YES | - | CODE-BACKED | Affiliate who referred the visitor. Sourced from fiktivo.etoro_Install.rid (aliased as AffiliateID). ISNULL(rid, 0) - NULL means organic. |
| 3 | SerialID | NVARCHAR(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking serial. Sourced from fiktivo.etoro_Install.serial (aliased as SerialID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md) | View base table | Source of install events, filtered to status='3' (first-time run). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | (UNION) | View composition | UNION member in the unified activity dataset. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewFirstTimeRun (view)
    └── fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | SELECT DISTINCT WHERE status='3' |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member for unified affiliate activity |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Daily first-time run count
```sql
SELECT Date, COUNT(*) AS FirstTimeRuns
FROM fiktivo.viewFirstTimeRun WITH (NOLOCK)
GROUP BY Date
ORDER BY Date DESC
```

### 8.2 Top affiliates by first-time runs
```sql
SELECT TOP 20 AffiliateID, COUNT(*) AS FirstTimeRuns
FROM fiktivo.viewFirstTimeRun WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY FirstTimeRuns DESC
```

### 8.3 First-time runs with affiliate detail
```sql
SELECT v.Date, v.AffiliateID, a.Username, v.SerialID
FROM fiktivo.viewFirstTimeRun v WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON v.AffiliateID = a.AffiliateID
ORDER BY v.Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewFirstTimeRun | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewFirstTimeRun.sql*
