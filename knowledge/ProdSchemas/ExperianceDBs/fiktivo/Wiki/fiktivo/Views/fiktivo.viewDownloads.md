# fiktivo.viewDownloads

> Returns completed downloads (status=1) with affiliate attribution, providing the download component of the unified affiliate activity report.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base table: fiktivo.etoro_Download |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view extracts completed download events (status=1) from `fiktivo.etoro_Download` and outputs a standardized (Date, AffiliateID, SerialID) tuple for each. It deduplicates by the combination of date, status, ip, rid, and serial before outputting, ensuring each unique download attempt per affiliate per day is counted once.

The view is a component of the unified affiliate activity report - it feeds into `fiktivo.viewUnion` alongside viewInstalls, viewFirstTimeRun, viewLeads, and viewSales. All five views share the same output schema (Date, AffiliateID, SerialID), enabling UNION across different event types.

Currently empty because the base table has 0 rows in this environment.

---

## 2. Business Logic

### 2.1 Completed Download Extraction

**What**: Filters and deduplicates completed downloads for affiliate reporting.

**Columns/Parameters Involved**: `Date`, `AffiliateID`, `SerialID`

**Rules**:
- Inner subquery: SELECT DISTINCT on date (truncated to day), status, ISNULL(ip, 'Unknown'), ISNULL(rid, 0), ISNULL(serial, '') WHERE status=1
- Outer query: SELECT DISTINCT on Date, AffiliateID, SerialID
- Two-layer DISTINCT ensures no duplicate events
- NULL rid treated as 0 (organic/unattributed); NULL serial treated as empty string

---

## 3. Data Overview

View is currently empty (base table has 0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | NO | - | CODE-BACKED | Download date truncated to midnight. Computed from fiktivo.etoro_Download.date. Inherited from [etoro_Download](../Tables/fiktivo.etoro_Download.md). |
| 2 | AffiliateID | BIGINT | YES | - | CODE-BACKED | Affiliate who referred the download visitor. Sourced from fiktivo.etoro_Download.rid (aliased as AffiliateID). ISNULL(rid, 0) - NULL means organic. |
| 3 | SerialID | NVARCHAR(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking serial. Sourced from fiktivo.etoro_Download.serial (aliased as SerialID). Campaign/traffic source identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | [fiktivo.etoro_Download](../Tables/fiktivo.etoro_Download.md) | View base table | Source of download events, filtered to status='1' (completed). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | (UNION) | View composition | First UNION member in the unified activity dataset. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewDownloads (view)
    └── fiktivo.etoro_Download (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Table | SELECT DISTINCT WHERE status='1' |

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

### 8.1 Daily completed downloads by affiliate
```sql
SELECT Date, AffiliateID, COUNT(*) AS Downloads
FROM fiktivo.viewDownloads WITH (NOLOCK)
GROUP BY Date, AffiliateID
ORDER BY Date DESC
```

### 8.2 Top sub-affiliate campaigns by download count
```sql
SELECT TOP 20 AffiliateID, SerialID, COUNT(*) AS Downloads
FROM fiktivo.viewDownloads WITH (NOLOCK)
WHERE SerialID <> ''
GROUP BY AffiliateID, SerialID
ORDER BY Downloads DESC
```

### 8.3 Downloads with affiliate name
```sql
SELECT v.Date, v.AffiliateID, a.Username, v.SerialID
FROM fiktivo.viewDownloads v WITH (NOLOCK)
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
*Object: fiktivo.viewDownloads | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewDownloads.sql*
