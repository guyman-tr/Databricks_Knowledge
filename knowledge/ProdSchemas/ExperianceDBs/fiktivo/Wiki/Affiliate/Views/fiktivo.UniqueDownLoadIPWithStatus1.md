# fiktivo.UniqueDownLoadIPWithStatus1

> View that deduplicates completed downloads (status=1) from etoro_Download by selecting only the latest download per unique IP address per day, used for accurate unique download counting.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | id (from etoro_Download) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UniqueDownLoadIPWithStatus1 answers the question "how many unique IPs completed a download each day?" It deduplicates the etoro_Download table by keeping only the record with the highest ID (latest entry) for each unique IP address per day, filtered to completed downloads (status=1).

This view exists because a single user may trigger multiple download events from the same IP on the same day (restarts, retries, multiple browsers). For accurate reporting of unique downloads, only one event per IP per day should be counted. The MAX(id) approach keeps the most recent event.

The view uses a correlated subquery pattern: for each row, it checks if its ID is the maximum for that IP+date+status combination. Currently returns no data because etoro_Download is empty in this environment.

---

## 2. Business Logic

### 2.1 IP-Based Download Deduplication

**What**: Keeps only the latest completed download per unique IP per day.

**Columns/Parameters Involved**: `id`, `date`, `ip`, `status`

**Rules**:
- Self-JOIN pattern: d1 row is kept only if d1.id = MAX(d2.id) for the same IP + date + status
- Both d1 and d2 must have status=1 (completed)
- Date comparison uses CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) for day-level matching
- GROUP BY includes id, ip, date (day-level), and status
- HAVING clause with correlated MAX subquery selects only the latest record per IP/day

---

## 3. Data Overview

View currently returns no data (base table etoro_Download is empty in this environment).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | date | datetime | NO | - | CODE-BACKED | Date of the download event, truncated to day level. Source: CAST(FLOOR(CAST(etoro_Download.date AS FLOAT)) AS DATETIME). |
| 2 | ip | nchar(16) | YES | - | CODE-BACKED | IP address of the downloading user. Used as the deduplication key alongside date. Source: etoro_Download.ip. |
| 3 | id | int | NO | - | CODE-BACKED | Download event ID - the highest (most recent) download ID for this IP+date combination. Source: etoro_Download.id. Selected via MAX(id) in the correlated subquery. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | fiktivo.etoro_Download | Base table + self-join | Reads completed downloads with correlated subquery for deduplication |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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
| fiktivo.etoro_Download | Table | Self-join with correlated MAX subquery for IP deduplication |

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

### 8.1 Unique download IPs per day
```sql
SELECT date, COUNT(*) AS UniqueIPs
FROM fiktivo.UniqueDownLoadIPWithStatus1 WITH (NOLOCK)
GROUP BY date
ORDER BY date DESC
```

### 8.2 Get full download details for unique IPs
```sql
SELECT u.date, u.ip, d.rid AS AffiliateID, d.serial
FROM fiktivo.UniqueDownLoadIPWithStatus1 u WITH (NOLOCK)
JOIN fiktivo.etoro_Download d WITH (NOLOCK) ON u.id = d.id
ORDER BY u.date DESC
```

### 8.3 Compare total vs unique downloads per day
```sql
SELECT CAST(FLOOR(CAST(d.date AS FLOAT)) AS DATETIME) AS Day,
       COUNT(*) AS TotalCompleted,
       (SELECT COUNT(*) FROM fiktivo.UniqueDownLoadIPWithStatus1 u WITH (NOLOCK)
        WHERE u.date = CAST(FLOOR(CAST(d.date AS FLOAT)) AS DATETIME)) AS UniqueIPs
FROM fiktivo.etoro_Download d WITH (NOLOCK)
WHERE d.status = '1'
GROUP BY CAST(FLOOR(CAST(d.date AS FLOAT)) AS DATETIME)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.UniqueDownLoadIPWithStatus1 | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.UniqueDownLoadIPWithStatus1.sql*
