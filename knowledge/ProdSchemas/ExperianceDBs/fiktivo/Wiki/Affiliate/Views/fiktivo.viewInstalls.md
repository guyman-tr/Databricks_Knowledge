# fiktivo.viewInstalls

> View that filters completed installation events (status=1) from etoro_Install, producing deduplicated daily install events with affiliate attribution for the conversion funnel union.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date + AffiliateID + SerialID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

viewInstalls extracts completed installation events (status=1) from the etoro_Install table. This represents successful software installations - the second stage of the affiliate conversion funnel: Download -> **Install** -> First Time Run -> Lead -> Sale.

This view feeds into viewUnion as one of five funnel stages. It uses the same deduplication and normalization pattern as the other funnel views, producing the standard (Date, AffiliateID, SerialID) output format.

The inner subquery deduplicates by date+status+ip+rid+serial with ISNULL handling for NULL values, and the outer SELECT applies a final DISTINCT on the three output columns.

---

## 2. Business Logic

### 2.1 Install Deduplication

**What**: Filters to status=1 (completed installs) and deduplicates per day/affiliate/serial.

**Columns/Parameters Involved**: `date`, `status`, `ip`, `rid`, `serial`

**Rules**:
- Only status='1' events pass through (completed installations)
- Same deduplication pattern as viewDownloads and viewFirstTimeRun
- One row per unique (Date, AffiliateID, SerialID) combination per day

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|---|---|---|---|
| 2012-01-13 | 4802 | http://www.etoro.it/why-etoro/trade-registration.aspx | Completed installation from Italian eToro site, attributed to affiliate 4802. The SerialID is a full URL showing the referral source page. |
| 2012-01-13 | 3 | (empty) | House affiliate installation with no sub-affiliate tracking. |
| 2012-01-13 | 24722 | (empty) | Installation attributed to affiliate 24722 on the same day. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | NO | - | CODE-BACKED | Date of the completed installation, truncated to day level. Source: etoro_Install.date via CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME). |
| 2 | AffiliateID | bigint | YES | - | CODE-BACKED | Affiliate attributed with the installation. Mapped from etoro_Install.rid. Inherited: see [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md). |
| 3 | SerialID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code. Mapped from etoro_Install.serial. Can contain full URLs as referral sources. Inherited: see [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | fiktivo.etoro_Install | Base table | Reads and filters completed installs (status=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | All columns | UNION | Combined into the unified funnel view |

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
| fiktivo.etoro_Install | Table | SELECT with WHERE status=1, DISTINCT deduplication |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member - contributes install funnel stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Daily install counts
```sql
SELECT Date, COUNT(*) AS Installs
FROM fiktivo.viewInstalls WITH (NOLOCK)
GROUP BY Date
ORDER BY Date DESC
```

### 8.2 Top affiliates by install count
```sql
SELECT AffiliateID, COUNT(*) AS TotalInstalls
FROM fiktivo.viewInstalls WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Installs with URL-based serial tracking
```sql
SELECT Date, AffiliateID, SerialID
FROM fiktivo.viewInstalls WITH (NOLOCK)
WHERE SerialID LIKE 'http%'
ORDER BY Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewInstalls | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewInstalls.sql*
