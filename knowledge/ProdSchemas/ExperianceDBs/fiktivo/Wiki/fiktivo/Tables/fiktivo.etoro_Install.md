# fiktivo.etoro_Install

> Tracks desktop application installation events from the affiliate marketing platform, recording each install attempt's lifecycle status, affiliate attribution, and error diagnostics.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | id (INT IDENTITY, no declared PK - clustered index on status + date) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered on status/date + 1 nonclustered on date) |

---

## 1. Business Meaning

This table records every desktop application installation event initiated by visitors arriving through affiliate marketing channels. Each row represents a single install attempt, capturing the install lifecycle status (started, finished, first-time run), the affiliate who referred the visitor, error diagnostics, and retry information. The table complements `fiktivo.etoro_Download` - downloads precede installs in the conversion funnel.

Without this table, the affiliate platform could not track installation success rates, identify installation errors, or attribute successful installs to affiliates. Installation metrics are a key intermediate conversion step between download and registration in the affiliate funnel.

Data spans the full year of 2012 with 178,394 rows. Three views consume this data: `fiktivo.viewInstalls` (finished installs, status=1), `fiktivo.viewFirstTimeRun` (first-time application runs, status=3), and `fiktivo.report_summary` (daily aggregate metrics for all statuses). No stored procedures reference this table directly.

---

## 2. Business Logic

### 2.1 Install Lifecycle Status

**What**: Tracks the progression of an application installation from start through completion and first run.

**Columns/Parameters Involved**: `status`, `date`, `PercentComplete`, `ErrorCode`, `Try`

**Rules**:
- status='1': Install finished successfully (45,888 rows, 26%)
- status='2': Install started but not yet completed (60,683 rows, 34%)
- status='3': Application first-time run after install (68,493 rows, 38%) - the most valuable conversion signal
- status='2000': Special status code (3,181 rows) - likely an error or non-standard completion
- status='998'/'999': Rare error states (92 rows combined)
- The clustered index is on (status, date DESC), optimizing for status-filtered queries with recent-first ordering

**Diagram**:
```
Download completes (etoro_Download status=1)
       |
       v
[status=2] Install Started
       |
  +----+----+
  |         |
  v         v
[status=1] [status=2000/998/999]
Finished    Error/Special
  |
  v
[status=3] First Time Run (app launched for first time)
```

### 2.2 Affiliate Attribution Triple

**What**: Same attribution model as etoro_Download - three columns identify the referring affiliate.

**Columns/Parameters Involved**: `rid`, `raf`, `serial`

**Rules**:
- `rid` = Affiliate ID (confirmed by viewInstalls alias: `rid As AffiliateID`)
- `serial` = Sub-affiliate tracking identifier (confirmed by viewInstalls alias: `serial as SerialID`). Contains free-form values like 'exget040', 'Italy' (market/campaign identifiers)
- `raf` = Referring affiliate ID. Largely NULL in sample data, used when a second-tier affiliate is involved
- ISNULL(rid, 0) and ISNULL(serial, '') applied in views for deduplication

---

## 3. Data Overview

| id | date | status | rid | serial | PercentComplete | Meaning |
|----|------|--------|-----|--------|-----------------|---------|
| 27135361 | 2012-12-30 | 1 | 13431 | exget040 | 0 | Successful install completion. Affiliate 13431 with sub-affiliate campaign 'exget040'. PercentComplete=0 is normal for finished installs. |
| 27135352 | 2012-12-30 | 1 | 85 | Italy | 0 | Successful install attributed to affiliate 85, campaign targeting Italian market. |
| (mid-range) | 2012-06-xx | 3 | varies | varies | 0 | First-time run event - the most valuable signal, showing the user actually launched the installed application. |
| (error) | 2012-xx-xx | 2000 | varies | varies | varies | Special/error status. These 3,181 rows represent installations that hit a non-standard completion path. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | INT IDENTITY | NO | auto-increment | CODE-BACKED | Unique install event identifier. Not the PK (table has no declared PK). |
| 2 | date | DATETIME | NO | getdate() | CODE-BACKED | Timestamp when the install event was recorded. Data spans 2012-01-01 to 2012-12-30. Truncated to day in views for daily reporting. |
| 3 | status | VARCHAR(5) | NO | '0' | CODE-BACKED | Install lifecycle status: '1'=Finished (26%), '2'=Started (34%), '3'=First Time Run (38%), '2000'=Special/error (2%), '998'/'999'=Rare error states. Used as primary filter in viewInstalls (1), viewFirstTimeRun (3), report_summary (1/2/3). |
| 4 | rid | BIGINT | YES | - | CODE-BACKED | Affiliate ID who referred the visitor. Aliased as AffiliateID in viewInstalls/viewFirstTimeRun. NULL or 0 means no affiliate attribution. |
| 5 | raf | BIGINT | YES | - | CODE-BACKED | Referring affiliate ID. Part of the attribution triple with rid and serial. Largely NULL in sample data - used for tier-2 affiliate relationships. |
| 6 | serial | NVARCHAR(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking serial/campaign identifier. Aliased as SerialID in views. Contains free-form values like 'exget040', 'Italy' identifying the campaign or market. |
| 7 | lang | NCHAR(12) | YES | - | NAME-INFERRED | Language/locale code of the installer. Wider than etoro_Download's VARCHAR(2), allowing longer locale strings. |
| 8 | ip | NCHAR(16) | YES | - | CODE-BACKED | Visitor's IP address. Used for deduplication in views: ISNULL(ip, 'Unknown'). |
| 9 | banner | BIGINT | YES | - | NAME-INFERRED | Banner/creative ID that drove the install. Sample shows values like 1916, 506, 0 (no banner). References affiliate marketing banners. |
| 10 | dl_param | BIGINT | YES | - | NAME-INFERRED | Download parameter identifier. Likely links to a download configuration or campaign. |
| 11 | FID | BIGINT | YES | - | NAME-INFERRED | File or feed identifier associated with the installation. |
| 12 | RealProviderID | INT | YES | - | CODE-BACKED | Platform provider identifier. Also used as parameter in sp_UpdateCopyTraders, sp_UpdateFirstPositions, sp_UpdateSales with default=1. Identifies the real provider/broker context. |
| 13 | WhiteLabelID | INT | YES | - | NAME-INFERRED | White-label partner identifier. Tracks which branded version of the application was installed. |
| 14 | ReportID | INT | YES | - | NAME-INFERRED | Report identifier. May link install events to a specific reporting batch or daily report run. |
| 15 | Exception | VARCHAR(MAX) | YES | - | NAME-INFERRED | Exception/error message text captured during install. NULL/empty for successful installs. Used for diagnosing installation failures. |
| 16 | PercentComplete | INT | YES | - | NAME-INFERRED | Installation progress percentage (0-100). Value 0 for completed installs (status=1) suggests this tracks in-progress state only. |
| 17 | Action | VARCHAR(MAX) | YES | - | NAME-INFERRED | Installer action being performed when the event was logged. Used for tracking which installation step was active. |
| 18 | ErrorCode | VARCHAR(50) | YES | - | NAME-INFERRED | Error code from the installer when an error occurs. Empty string for successful installs. |
| 19 | UpdateModule | VARCHAR(50) | YES | - | NAME-INFERRED | Module being updated during installation. Identifies which component of the application was being installed or updated. |
| 20 | DownloadID | BIGINT | YES | - | NAME-INFERRED | Links this install event to the originating download in fiktivo.etoro_Download. Value 0 in sample data suggests this linkage was not always populated. |
| 21 | Try | INT | YES | - | NAME-INFERRED | Retry attempt number for this installation. Value 0 indicates first attempt. Higher values indicate the user retried after a failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| rid | dbo.tblaff_Affiliates | Implicit | Affiliate who referred the installer. |
| DownloadID | fiktivo.etoro_Download | Implicit | Links install to its originating download event (when populated). |
| banner | dbo.tblaff_Banners | Implicit | Marketing banner that drove the installation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewInstalls | (FROM) | View base table | Filters for status='1' (finished installs), outputs Date, AffiliateID, SerialID. |
| fiktivo.viewFirstTimeRun | (FROM) | View base table | Filters for status='3' (first-time application runs), outputs Date, AffiliateID, SerialID. |
| fiktivo.report_summary | (FROM) | View base table | Aggregates daily install counts by status: Finished (1), Started (2), First Time Run (3). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewInstalls | View | SELECT WHERE status='1' for completed installations |
| fiktivo.viewFirstTimeRun | View | SELECT WHERE status='3' for first-time application runs |
| fiktivo.report_summary | View | SELECT with status filters (1/2/3) for daily aggregate metrics |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CLU_etoro_Install | CLUSTERED | status ASC, date DESC | - | - | Active (FILLFACTOR=90, PAGE compression) |
| IX__etoro_Install__date | NC | date ASC | status | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_etoro_Install_date | DEFAULT | getdate() for [date] - auto-timestamps install events |
| DF_etoro_Install_status | DEFAULT | '0' for [status] - new rows start as status 0 (not started/pending) |

---

## 8. Sample Queries

### 8.1 Daily install funnel by status
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS InstallDate,
       SUM(CASE WHEN status = '2' THEN 1 ELSE 0 END) AS Started,
       SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) AS Finished,
       SUM(CASE WHEN status = '3' THEN 1 ELSE 0 END) AS FirstTimeRun
FROM fiktivo.etoro_Install WITH (NOLOCK)
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME)
ORDER BY InstallDate DESC
```

### 8.2 Install success rate by affiliate
```sql
SELECT rid AS AffiliateID,
       COUNT(*) AS TotalEvents,
       SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) AS Finished,
       SUM(CASE WHEN status = '3' THEN 1 ELSE 0 END) AS FirstTimeRun
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE rid IS NOT NULL AND rid > 0
GROUP BY rid
ORDER BY TotalEvents DESC
```

### 8.3 Error analysis for non-standard statuses
```sql
SELECT TOP 20 status, ErrorCode, Exception, COUNT(*) AS Occurrences
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE status NOT IN ('1', '2', '3')
GROUP BY status, ErrorCode, Exception
ORDER BY Occurrences DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.5/10 (Elements: 5.7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 12 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_Install | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_Install.sql*
