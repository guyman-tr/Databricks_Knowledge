# fiktivo.viewFirstTimeRun

> View that filters first-time application run events (status=3) from etoro_Install, producing deduplicated daily first-run events with affiliate attribution for the conversion funnel union.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date + AffiliateID + SerialID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

viewFirstTimeRun extracts first-time application run events (status=3) from the etoro_Install table. This represents the moment a user launches the eToro platform for the first time after installation - a stronger conversion signal than just completing the install. This is the third stage of the affiliate funnel: Download -> Install -> **First Time Run** -> Lead -> Sale.

First-time run is a key quality metric for affiliates because it proves the user not only installed the software but actually opened it. This distinguishes genuine installs from abandoned ones. The view feeds into viewUnion as one of five funnel stages.

The view uses the same deduplication pattern as viewDownloads and viewInstalls: an inner DISTINCT subquery on (date, status, ip, rid, serial) followed by an outer DISTINCT on the three output columns.

---

## 2. Business Logic

### 2.1 First-Run Deduplication

**What**: Filters to status=3 (first-time run) events and deduplicates per day/affiliate/serial.

**Columns/Parameters Involved**: `date`, `status`, `ip`, `rid`, `serial`

**Rules**:
- Only status='3' events pass through (first-time application runs)
- Inner DISTINCT removes duplicate reports from the same IP/affiliate/serial per day
- ISNULL patterns ensure NULL values don't create false duplicates
- One row per unique (Date, AffiliateID, SerialID) combination

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|---|---|---|---|
| 2012-01-13 | 3 | (empty) | First-time run attributed to house affiliate (ID=3), no sub-affiliate tracking. Organic or direct traffic that successfully installed and launched the platform. |
| 2012-01-16 | 3 | (empty) | Another first-time run for house affiliate on a different day. |
| 2012-01-17 | 3 | (empty) | Continued pattern of house-affiliate first-time runs in January 2012. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | NO | - | CODE-BACKED | Date of the first-time run event, truncated to day level. Source: etoro_Install.date via CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME). |
| 2 | AffiliateID | bigint | YES | - | CODE-BACKED | Affiliate attributed with the first-time run. Mapped from etoro_Install.rid. Inherited: see [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md) for full description. |
| 3 | SerialID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code. Mapped from etoro_Install.serial. Inherited: see [fiktivo.etoro_Install](../Tables/fiktivo.etoro_Install.md) for full description. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | fiktivo.etoro_Install | Base table | Reads and filters first-time run events (status=3) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | All columns | UNION | Combined into the unified funnel view |

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
| fiktivo.etoro_Install | Table | SELECT with WHERE status=3, DISTINCT deduplication |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member - contributes first-time-run funnel stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Daily first-time runs
```sql
SELECT Date, COUNT(*) AS FirstTimeRuns
FROM fiktivo.viewFirstTimeRun WITH (NOLOCK)
GROUP BY Date
ORDER BY Date DESC
```

### 8.2 First-time run counts by affiliate
```sql
SELECT AffiliateID, COUNT(*) AS FirstRuns
FROM fiktivo.viewFirstTimeRun WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Install-to-first-run conversion by affiliate
```sql
SELECT i.AffiliateID,
       COUNT(DISTINCT i.Date) AS InstallDays,
       COUNT(DISTINCT f.Date) AS FirstRunDays
FROM fiktivo.viewInstalls i WITH (NOLOCK)
LEFT JOIN fiktivo.viewFirstTimeRun f WITH (NOLOCK)
  ON i.AffiliateID = f.AffiliateID AND i.Date = f.Date
GROUP BY i.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewFirstTimeRun | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewFirstTimeRun.sql*
