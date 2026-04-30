# fiktivo.viewDownloads

> View that filters completed software downloads (status=1) from etoro_Download, producing deduplicated daily download events with affiliate attribution for the conversion funnel union.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date + AffiliateID + SerialID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

viewDownloads extracts completed download events (status=1) from the etoro_Download table and normalizes them into the standard funnel output format (Date, AffiliateID, SerialID). This view is one of five funnel-stage views that feed into viewUnion, which combines all stages of the affiliate conversion funnel into a single unified dataset.

This view represents the "Download Completed" stage of the affiliate funnel: Download -> Install -> First Time Run -> Lead -> Sale. It filters to only successfully completed downloads and deduplicates by the combination of date (day-level), IP, affiliate ID, and serial.

The view reads from etoro_Download (using the unqualified table name, resolved within the fiktivo schema). The inner subquery deduplicates by date+status+ip+rid+serial, and the outer SELECT produces the standard three-column output. Currently returns no data because etoro_Download is empty in this environment.

---

## 2. Business Logic

### 2.1 Download Deduplication

**What**: Removes duplicate download records to count one completed download per unique combination per day.

**Columns/Parameters Involved**: `date`, `status`, `ip`, `rid`, `serial`

**Rules**:
- Inner subquery applies DISTINCT on (date-truncated-to-day, status, ip, rid, serial)
- ISNULL(ip, 'Unknown') ensures NULL IPs don't create false duplicates
- ISNULL(rid, 0) ensures NULL affiliate IDs are treated as '0' (house/organic)
- ISNULL(serial, '') ensures NULL serials are treated as empty string
- Only status='1' (completed downloads) pass through
- Outer SELECT applies another DISTINCT on the final (Date, AffiliateID, SerialID) output

---

## 3. Data Overview

View currently returns no data (base table etoro_Download is empty in this environment).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | NO | - | CODE-BACKED | Date of the completed download, truncated to day level using CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME). Strips the time component for daily aggregation. Source: etoro_Download.date. |
| 2 | AffiliateID | bigint | YES | - | CODE-BACKED | Affiliate who drove the download. Mapped from etoro_Download.rid. NULL values coalesced to 0 in the inner subquery for deduplication. |
| 3 | SerialID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code. Mapped from etoro_Download.serial. NULL values coalesced to empty string in the inner subquery. Allows affiliates to track specific campaigns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | fiktivo.etoro_Download | Base table | Reads and filters completed downloads (status=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | All columns | UNION | Combined into the unified funnel view |

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
| fiktivo.etoro_Download | Table | SELECT with WHERE status=1, DISTINCT deduplication |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member - contributes download funnel stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Daily completed downloads by affiliate
```sql
SELECT Date, AffiliateID, COUNT(*) AS Downloads
FROM fiktivo.viewDownloads WITH (NOLOCK)
GROUP BY Date, AffiliateID
ORDER BY Date DESC
```

### 8.2 Top affiliates by download count
```sql
SELECT AffiliateID, COUNT(*) AS TotalDownloads
FROM fiktivo.viewDownloads WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Downloads with specific sub-affiliate tracking
```sql
SELECT Date, AffiliateID, SerialID
FROM fiktivo.viewDownloads WITH (NOLOCK)
WHERE SerialID <> ''
ORDER BY Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewDownloads | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewDownloads.sql*
