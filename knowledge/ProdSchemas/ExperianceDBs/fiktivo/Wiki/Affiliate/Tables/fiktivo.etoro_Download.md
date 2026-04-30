# fiktivo.etoro_Download

> Tracks software download events from the eToro trading platform installer, recording download status, affiliate attribution, and client metadata for affiliate commission attribution.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | id (INT IDENTITY, clustered PK) |
| **Partition** | No |
| **Indexes** | 4 active (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

etoro_Download records individual software download events from the eToro trading platform. Each row represents a single download attempt by a potential customer, capturing whether the download was started, completed, or cancelled. This is the first step in the affiliate conversion funnel: Download -> Install -> First Time Run -> Registration -> Lead -> Sale.

This table is fundamental to the affiliate commission system because it links a download event to an affiliate (via `rid`) and a sub-affiliate serial (via `serial`). Without this table, the platform could not attribute software downloads to the affiliate who drove the traffic, breaking the top of the conversion funnel.

Data enters this table when a user initiates a download of the eToro platform installer. The `status` column tracks the download lifecycle (0=started, 1=completed, 2=cancelled). Three views consume this table: `report_summary` (aggregates daily download counts by status), `UniqueDownLoadIPWithStatus1` (deduplicates completed downloads by IP per day), and `viewDownloads` (filters to completed downloads for the union funnel view). The table is currently empty in this environment.

---

## 2. Business Logic

### 2.1 Download Status Lifecycle

**What**: Each download event transitions through status values representing the download lifecycle.

**Columns/Parameters Involved**: `status`, `date`, `end_date`

**Rules**:
- Status 0 = Download started (initial state)
- Status 1 = Download completed successfully
- Status 2 = Download cancelled or failed
- The `date` column records when the download started (defaults to GETDATE())
- The `end_date` column presumably records when the download finished or was cancelled
- Views filter on status to produce different reports: status=0 for started, status=1 for finished, status=2 for cancelled

**Diagram**:
```
[Started (0)] --success--> [Completed (1)]
     |
     +--failure/cancel--> [Cancelled (2)]
```

### 2.2 Affiliate Attribution Chain

**What**: Downloads are attributed to affiliates through a referral ID and serial tracking chain.

**Columns/Parameters Involved**: `rid`, `raf`, `serial`, `banner`, `dl_param`, `FID`

**Rules**:
- `rid` = Affiliate ID (the affiliate who drove the traffic)
- `serial` = Sub-affiliate serial/tracking code (up to 1024 chars)
- `banner` = Banner/creative ID that the user clicked
- `dl_param` = Download parameter for additional tracking
- `FID` = Funnel ID linking to the traffic source
- `RealProviderID` and `WhiteLabelID` identify the provider and white-label brand

---

## 3. Data Overview

Table is currently empty in this environment (0 rows). Based on DDL structure and view usage, rows would represent individual download events with affiliate attribution data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | int (IDENTITY) | NO | Auto-increment | CODE-BACKED | Unique identifier for each download event. Auto-generated, NOT FOR REPLICATION (excluded from replication identity seeding). |
| 2 | date | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when the download was initiated. Defaults to current time. Used by all three consuming views for daily aggregation via CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) pattern to strip time component. |
| 3 | status | varchar(1) | NO | - | CODE-BACKED | Download lifecycle status: '0' = started, '1' = completed successfully, '2' = cancelled/failed. Used by report_summary to produce three separate download count columns (Started_DL, Finished_DL, Canceled_DL). viewDownloads filters to status='1' only. |
| 4 | rid | bigint | YES | - | CODE-BACKED | Referral/Affiliate ID - identifies which affiliate drove this download. Mapped to AffiliateID in viewDownloads. Used for commission attribution. |
| 5 | raf | bigint | YES | - | NAME-INFERRED | Referral affiliate parameter - likely a secondary affiliate tracking identifier or referral source code. |
| 6 | lang | varchar(2) | YES | - | NAME-INFERRED | Two-character language code indicating the user's language preference or the localized version of the installer downloaded. |
| 7 | ip | nchar(16) | YES | - | CODE-BACKED | IP address of the downloading user, stored as a fixed-width 16-character string. Used by UniqueDownLoadIPWithStatus1 view to deduplicate downloads by unique IP per day. Also used with ISNULL(ip, 'Unknown') pattern in report aggregation. |
| 8 | serial | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate serial/tracking code. Mapped to SerialID in viewDownloads. Allows affiliates to track which specific campaign or link generated the download. Large 1024-char field accommodates complex tracking parameters. |
| 9 | end_date | datetime | YES | - | NAME-INFERRED | Timestamp when the download completed or was cancelled. NULL while download is still in progress (status=0). |
| 10 | chunks | bigint | YES | - | NAME-INFERRED | Number of data chunks transferred during the download. Likely used for tracking download progress and diagnosing incomplete downloads. |
| 11 | new_installer | bit | YES | 0 | NAME-INFERRED | Flag indicating whether this download used a new version of the installer. Default 0 = standard/legacy installer. 1 = new installer version. |
| 12 | dl_param | bigint | YES | - | NAME-INFERRED | Download parameter - additional numeric tracking value associated with the download event, possibly linking to a specific campaign or landing page configuration. |
| 13 | banner | bigint | YES | - | NAME-INFERRED | Banner/creative identifier - tracks which marketing banner or advertisement the user clicked to initiate the download. Links to affiliate marketing materials. |
| 14 | referrer | nvarchar(200) | YES | - | NAME-INFERRED | HTTP referrer URL captured at download time. Records the webpage the user was on when they clicked the download link. Used for traffic source analysis. |
| 15 | browser | nvarchar(50) | YES | - | NAME-INFERRED | Browser user-agent string or browser name of the downloading client. Used for compatibility tracking and analytics. |
| 16 | os | nvarchar(50) | YES | - | NAME-INFERRED | Operating system of the downloading client. Used for platform compatibility tracking and installer version targeting. |
| 17 | cookies | bit | YES | - | NAME-INFERRED | Flag indicating whether the user's browser had cookies enabled at download time. Important for affiliate tracking cookie persistence. |
| 18 | FID | bigint | YES | - | NAME-INFERRED | Funnel ID - identifies which marketing funnel or conversion path led to this download. Used for funnel analysis and optimization. |
| 19 | RealProviderID | int | YES | - | NAME-INFERRED | Identifies the actual provider/broker entity under which this download occurred. Relevant in multi-provider or white-label configurations. |
| 20 | WhiteLabelID | int | YES | - | NAME-INFERRED | Identifies the white-label brand under which the download was initiated. Allows tracking downloads across different branded versions of the platform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| rid | External affiliate table (dbo.tblaff_Affiliates) | Implicit | References the affiliate who drove the download traffic |
| RealProviderID | External provider lookup | Implicit | References the provider/broker entity |
| WhiteLabelID | External white-label lookup | Implicit | References the white-label brand configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.report_summary | date, status, ip, rid, raf, serial | View (READER) | Aggregates daily download counts by status (started/finished/cancelled) |
| fiktivo.UniqueDownLoadIPWithStatus1 | date, ip, id, status | View (READER) | Deduplicates completed downloads by unique IP per day |
| fiktivo.viewDownloads | date, rid, serial, status, ip | View (READER) | Filters to completed downloads (status=1) for the funnel union view |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.report_summary | View | Reads download data aggregated by date and status |
| fiktivo.UniqueDownLoadIPWithStatus1 | View | Deduplicates completed downloads by IP |
| fiktivo.viewDownloads | View | Filters to completed downloads for funnel reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_etoro_Download | CLUSTERED PK | id ASC | - | - | Active |
| Download_Report | NONCLUSTERED | id ASC, date ASC, status ASC | - | - | Active |
| IDX_fiktivo_etoro_Download_date_Ince | NONCLUSTERED | date ASC | ip, status | - | Active |
| IX__etoro_Download__date | NONCLUSTERED | date ASC | status | - | Active |

Data compression: PK uses PAGE compression. Multiple date-based indexes support the view queries that aggregate by date.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_etoro_Download | PRIMARY KEY | IDENTITY column id - auto-increment, NOT FOR REPLICATION |
| DF_etoro_Download_date | DEFAULT | GETDATE() for date - automatically timestamps download initiation |
| DF_etoro_Download_new_installer | DEFAULT | 0 for new_installer - assumes standard installer unless specified |

---

## 8. Sample Queries

### 8.1 Daily download counts by status
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS DownloadDate,
       status,
       COUNT(*) AS DownloadCount
FROM fiktivo.etoro_Download WITH (NOLOCK)
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME), status
ORDER BY DownloadDate DESC
```

### 8.2 Top affiliates by completed downloads
```sql
SELECT rid AS AffiliateID, COUNT(*) AS CompletedDownloads
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = '1'
GROUP BY rid
ORDER BY COUNT(*) DESC
```

### 8.3 Unique IPs per day for completed downloads
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS DownloadDate,
       COUNT(DISTINCT ip) AS UniqueIPs
FROM fiktivo.etoro_Download WITH (NOLOCK)
WHERE status = '1'
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME)
ORDER BY DownloadDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.8/10 (Elements: 5.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 13 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_Download | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_Download.sql*
