# fiktivo.etoro_Download

> Tracks desktop application download events from the affiliate marketing platform, recording each download attempt's status, affiliate attribution, and visitor metadata.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | id (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

This table records every desktop application download event initiated by visitors arriving through affiliate marketing channels. Each row represents a single download attempt, capturing the download lifecycle status (started, completed, cancelled), the affiliate who referred the visitor, the visitor's IP and browser metadata, and the tracking serial used for attribution.

Without this table, the affiliate platform could not track which downloads were initiated through which affiliates, making it impossible to calculate download-based metrics for affiliate reporting. The table feeds the report_summary view for daily download statistics and the viewDownloads view for affiliate-level download attribution.

Download events are created when a visitor initiates a download (status=0), updated when the download completes (status=1) or is cancelled (status=2). Three views consume this data: `fiktivo.viewDownloads` (completed downloads per affiliate), `fiktivo.UniqueDownLoadIPWithStatus1` (deduplicated completed downloads by IP per day), and `fiktivo.report_summary` (daily aggregate download/install/lead/sale metrics). No stored procedures reference this table directly. The table is currently empty in this environment, suggesting download data may be purged or stored elsewhere in production.

---

## 2. Business Logic

### 2.1 Download Lifecycle Status

**What**: Tracks the progression of a download from initiation through completion or cancellation.

**Columns/Parameters Involved**: `status`, `date`, `end_date`

**Rules**:
- status='0': Download started - visitor initiated the download
- status='1': Download finished - file was fully downloaded (used by viewDownloads for affiliate attribution)
- status='2': Download cancelled - visitor aborted before completion
- The report_summary view counts each status separately: Started_DL (status=0), Finished_DL (status=1), Canceled_DL (status=2)
- Deduplication in views uses the combination of date (truncated to day), ip, rid, raf, and serial

**Diagram**:
```
Visitor clicks affiliate link
       |
       v
[status=0] Download Started (date = getdate())
       |
  +----+----+
  |         |
  v         v
[status=1] [status=2]
Finished    Cancelled
```

### 2.2 Affiliate Attribution Triple

**What**: Three columns together identify which affiliate referred the download.

**Columns/Parameters Involved**: `rid`, `raf`, `serial`

**Rules**:
- `rid` = Affiliate ID (confirmed by viewDownloads alias: `rid As AffiliateID`)
- `serial` = Sub-affiliate tracking serial (confirmed by viewDownloads alias: `serial as SerialID`)
- `raf` = Referring affiliate ID, used alongside rid for deduplication in report_summary
- ISNULL(rid, 0) applied in views - NULL rid treated as 0 (no affiliate)
- These three columns, combined with date and ip, form the deduplication key in the report_summary view

---

## 3. Data Overview

Table is currently empty (0 rows) in this environment. Data may be purged periodically or stored in a different environment. The table structure and consuming views indicate it was designed to track high-volume download telemetry.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | INT IDENTITY | NO | auto-increment | CODE-BACKED | Unique download event identifier. Primary key. Identity column, NOT FOR REPLICATION. |
| 2 | date | DATETIME | NO | getdate() | CODE-BACKED | Timestamp when the download event was recorded. Truncated to day in views via CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) for daily reporting. |
| 3 | status | VARCHAR(1) | NO | - | CODE-BACKED | Download lifecycle status: '0'=Started (download initiated), '1'=Finished (download completed), '2'=Cancelled (download aborted). Used as primary filter in viewDownloads (status=1) and report_summary (0/1/2). |
| 4 | rid | BIGINT | YES | - | CODE-BACKED | Affiliate ID who referred the visitor. Aliased as AffiliateID in viewDownloads/viewInstalls. NULL or 0 means no affiliate attribution (organic). |
| 5 | raf | BIGINT | YES | - | CODE-BACKED | Referring affiliate ID. Used alongside rid and serial for download event deduplication in report_summary. Part of the affiliate attribution triple. |
| 6 | lang | VARCHAR(2) | YES | - | NAME-INFERRED | Two-character language code of the visitor's locale (likely ISO 639-1 format, e.g., 'en', 'de'). |
| 7 | ip | NCHAR(16) | YES | - | CODE-BACKED | Visitor's IP address in dotted-quad string format. Used for deduplication in UniqueDownLoadIPWithStatus1 (one download per IP per day). ISNULL(ip, 'Unknown') applied in views. |
| 8 | serial | NVARCHAR(1024) | YES | - | CODE-BACKED | Affiliate tracking serial/sub-affiliate identifier. Aliased as SerialID in viewDownloads. Used for sub-affiliate-level attribution and deduplication. |
| 9 | end_date | DATETIME | YES | - | NAME-INFERRED | Timestamp when the download completed or was cancelled. NULL for in-progress or status=0 downloads. |
| 10 | chunks | BIGINT | YES | - | NAME-INFERRED | Number of download chunks/segments transferred. Likely used for monitoring download progress in chunked file transfers. |
| 11 | new_installer | BIT | YES | 0 | NAME-INFERRED | Whether this download is for a new installer version. Default 0 indicates an existing/standard installer. |
| 12 | dl_param | BIGINT | YES | - | NAME-INFERRED | Download parameter identifier. Likely references a download configuration or campaign parameter. |
| 13 | banner | BIGINT | YES | - | NAME-INFERRED | Banner/creative ID that the visitor clicked to initiate the download. References the affiliate marketing banner that drove this conversion. |
| 14 | referrer | NVARCHAR(200) | YES | - | NAME-INFERRED | HTTP referrer URL of the page that linked to the download. Used for traffic source analysis. |
| 15 | browser | NVARCHAR(50) | YES | - | NAME-INFERRED | Visitor's web browser identification string (e.g., 'Chrome', 'Firefox'). |
| 16 | os | NVARCHAR(50) | YES | - | NAME-INFERRED | Visitor's operating system (e.g., 'Windows 10', 'macOS'). |
| 17 | cookies | BIT | YES | - | NAME-INFERRED | Whether the visitor's browser had cookies enabled at download time. Important for affiliate cookie-based tracking. |
| 18 | FID | BIGINT | YES | - | NAME-INFERRED | File or feed identifier associated with the download. May reference the specific installer file or distribution feed. |
| 19 | RealProviderID | INT | YES | - | CODE-BACKED | Platform provider identifier. Also appears as parameter in sp_UpdateCopyTraders, sp_UpdateFirstPositions, sp_UpdateSales with default value 1. Identifies the real provider/broker context. |
| 20 | WhiteLabelID | INT | YES | - | NAME-INFERRED | White-label partner identifier. Tracks which white-label branded version of the application was downloaded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| rid | dbo.tblaff_Affiliates | Implicit | Affiliate who referred the download visitor. |
| banner | dbo.tblaff_Banners | Implicit | Marketing banner creative that drove the download. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewDownloads | (FROM) | View base table | Filters for status=1 (finished downloads), outputs Date, AffiliateID, SerialID per affiliate. |
| fiktivo.UniqueDownLoadIPWithStatus1 | (FROM) | View base table | Deduplicates completed downloads by IP per day for unique download counting. |
| fiktivo.report_summary | (FROM) | View base table | Aggregates daily download counts by status (started/finished/cancelled). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewDownloads | View | SELECT from etoro_Download WHERE status=1 for completed downloads |
| fiktivo.UniqueDownLoadIPWithStatus1 | View | SELECT from etoro_Download WHERE status=1 with IP deduplication |
| fiktivo.report_summary | View | SELECT from etoro_Download with status filters (0/1/2) for daily metrics |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_etoro_Download | CLUSTERED PK | id ASC | - | - | Active (PAGE compression) |
| Download_Report | NC | id ASC, date ASC, status ASC | - | - | Active (PAGE compression) |
| IDX_fiktivo_etoro_Download_date_Ince | NC | date ASC | ip, status | - | Active (PAGE compression) |
| IX__etoro_Download__date | NC | date ASC | status | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_etoro_Download_date | DEFAULT | getdate() for [date] - auto-timestamps download events |
| DF_etoro_Download_new_installer | DEFAULT | 0 for [new_installer] - defaults to existing/standard installer |

---

## 8. Sample Queries

### 8.1 Daily completed downloads by affiliate
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS DownloadDate,
       rid AS AffiliateID,
       COUNT(*) AS CompletedDownloads
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = '1'
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME), rid
ORDER BY DownloadDate DESC
```

### 8.2 Download funnel analysis (started vs completed vs cancelled)
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS DownloadDate,
       SUM(CASE WHEN status = '0' THEN 1 ELSE 0 END) AS Started,
       SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) AS Completed,
       SUM(CASE WHEN status = '2' THEN 1 ELSE 0 END) AS Cancelled
FROM fiktivo.etoro_Download WITH (NOLOCK)
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME)
ORDER BY DownloadDate DESC
```

### 8.3 Unique download IPs per day with affiliate name
```sql
SELECT CAST(FLOOR(CAST(d.date AS FLOAT)) AS DATETIME) AS DownloadDate,
       d.rid AS AffiliateID,
       a.Username AS AffiliateName,
       COUNT(DISTINCT d.ip) AS UniqueIPs
FROM fiktivo.etoro_Download d WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON d.rid = a.AffiliateID
WHERE d.status = '1'
GROUP BY CAST(FLOOR(CAST(d.date AS FLOAT)) AS DATETIME), d.rid, a.Username
ORDER BY DownloadDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.4/10 (Elements: 6/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 12 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_Download | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_Download.sql*
