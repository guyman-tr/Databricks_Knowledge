# fiktivo.UniqueDownLoadIPWithStatus1

> Deduplicates completed downloads (status=1) from etoro_Download by IP address per day, returning only the latest download ID for each unique IP on each date.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base table: fiktivo.etoro_Download |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a deduplicated count of completed downloads (status=1) by removing duplicate download events from the same IP address on the same day. When a visitor downloads the application multiple times from the same IP on the same day, only the latest download (MAX(id)) is retained. This gives a more accurate picture of unique download conversions versus raw download counts.

The deduplication logic uses a correlated subquery: for each combination of (ip, date, status=1), it keeps only the row with the highest id (most recent download). This is critical for accurate affiliate reporting - without deduplication, an affiliate could appear to have driven more downloads than actual unique visitors.

The view is currently empty because the base table (fiktivo.etoro_Download) contains no data in this environment.

---

## 2. Business Logic

### 2.1 IP-Based Download Deduplication

**What**: Ensures each unique IP address is counted only once per day for completed downloads.

**Columns/Parameters Involved**: `date`, `ip`, `id`

**Rules**:
- Filters to status=1 (completed downloads only)
- Groups by id, ip, date (truncated to day), status
- HAVING clause with correlated subquery: id = MAX(id) WHERE same ip AND same day AND status=1
- This produces one row per unique (ip, day) combination, keeping the most recent download

---

## 3. Data Overview

View is currently empty (base table fiktivo.etoro_Download has 0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | date | DATETIME | NO | - | CODE-BACKED | Download date truncated to midnight via CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME). Sourced from fiktivo.etoro_Download.date. |
| 2 | ip | NCHAR(16) | YES | - | CODE-BACKED | Visitor's IP address. Used as the deduplication key - only one download per IP per day is retained. Sourced from fiktivo.etoro_Download.ip. |
| 3 | id | INT | NO | - | CODE-BACKED | Download event ID. The MAX(id) for each (ip, day) combination, representing the most recent completed download. Sourced from fiktivo.etoro_Download.id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | [fiktivo.etoro_Download](../Tables/fiktivo.etoro_Download.md) | View base table | Source of download events, filtered to status=1 and deduplicated by IP per day. |

### 5.2 Referenced By (other objects point to this)

No objects reference this view directly in the fiktivo schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.UniqueDownLoadIPWithStatus1 (view)
    └── fiktivo.etoro_Download (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.etoro_Download | Table | SELECT with GROUP BY and correlated subquery for deduplication |

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

### 8.1 Count unique download IPs per day
```sql
SELECT date, COUNT(*) AS UniqueDownloadIPs
FROM fiktivo.UniqueDownLoadIPWithStatus1 WITH (NOLOCK)
GROUP BY date
ORDER BY date DESC
```

### 8.2 Compare raw downloads vs unique IPs
```sql
SELECT d.DownloadDate, d.RawCount, u.UniqueCount
FROM (SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS DownloadDate, COUNT(*) AS RawCount
      FROM fiktivo.etoro_Download WITH (NOLOCK) WHERE status = '1' GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME)) d
LEFT JOIN (SELECT date, COUNT(*) AS UniqueCount FROM fiktivo.UniqueDownLoadIPWithStatus1 WITH (NOLOCK) GROUP BY date) u
  ON d.DownloadDate = u.date
ORDER BY d.DownloadDate DESC
```

### 8.3 IPs that downloaded multiple times in a day
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS DayDate, ip, COUNT(*) AS Downloads
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = '1' AND ip IS NOT NULL
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME), ip
HAVING COUNT(*) > 1
ORDER BY Downloads DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.UniqueDownLoadIPWithStatus1 | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.UniqueDownLoadIPWithStatus1.sql*
