# fiktivo.viewInstalls

> Returns completed installation events (status=1) from etoro_Install with affiliate attribution, providing the install component of the unified affiliate activity report.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base table: fiktivo.etoro_Install |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view extracts completed installation events (status=1) from `fiktivo.etoro_Install` and outputs a standardized (Date, AffiliateID, SerialID) tuple. A completed install indicates the application was successfully installed on the visitor's machine - one step deeper in the funnel than a completed download.

The view feeds into `fiktivo.viewUnion` alongside viewDownloads, viewFirstTimeRun, viewLeads, and viewSales. It also feeds into `fiktivo.report_summary` as the Finished_Install metric.

---

## 2. Business Logic

### 2.1 Completed Install Extraction

**What**: Filters install events to only successful completions.

**Columns/Parameters Involved**: `Date`, `AffiliateID`, `SerialID`

**Rules**:
- Inner subquery: SELECT DISTINCT on date (truncated), status, ISNULL(ip, 'Unknown'), ISNULL(rid, 0), ISNULL(serial, '') WHERE status='1'
- Outer query: SELECT DISTINCT Date, AffiliateID, SerialID
- Status 1 = Install Finished (application installation completed successfully)

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|------|-------------|----------|---------|
| 2012-01-13 | 4802 | http://www.etoro.it/why-etoro/trade-registration.aspx | Completed install attributed to affiliate 4802. SerialID shows the referrer was an Italian eToro registration page. |
| 2012-01-13 | 3 | (empty) | Completed install for the house affiliate with no sub-affiliate tracking. |
| 2012-01-13 | 24722 | (empty) | Completed install for affiliate 24722. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | NO | - | CODE-BACKED | Install completion date truncated to midnight. Computed from fiktivo.etoro_Install.date. Inherited from [etoro_Install](../Tables/fiktivo.etoro_Install.md). |
| 2 | AffiliateID | BIGINT | YES | - | CODE-BACKED | Affiliate who referred the installer. Sourced from fiktivo.etoro_Install.rid (aliased as AffiliateID). ISNULL(rid, 0) - NULL means organic. |
| 3 | SerialID | NVARCHAR(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking serial. Sourced from fiktivo.etoro_Install.serial (aliased as SerialID). May contain referrer URLs or campaign identifiers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md) | View base table | Source of install events, filtered to status='1' (completed). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | (UNION) | View composition | UNION member in the unified activity dataset. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewInstalls (view)
    └── fiktivo.etoro_Install (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Install | Table | SELECT DISTINCT WHERE status='1' |

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

### 8.1 Daily install count by affiliate
```sql
SELECT Date, AffiliateID, COUNT(*) AS Installs
FROM fiktivo.viewInstalls WITH (NOLOCK)
GROUP BY Date, AffiliateID
ORDER BY Date DESC
```

### 8.2 Installs with affiliate name
```sql
SELECT v.Date, v.AffiliateID, a.Username, v.SerialID
FROM fiktivo.viewInstalls v WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON v.AffiliateID = a.AffiliateID
ORDER BY v.Date DESC
```

### 8.3 Top campaigns by install count
```sql
SELECT TOP 20 AffiliateID, SerialID, COUNT(*) AS Installs
FROM fiktivo.viewInstalls WITH (NOLOCK)
WHERE SerialID <> ''
GROUP BY AffiliateID, SerialID
ORDER BY Installs DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewInstalls | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewInstalls.sql*
