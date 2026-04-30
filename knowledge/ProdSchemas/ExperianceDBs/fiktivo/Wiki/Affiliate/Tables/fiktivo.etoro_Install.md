# fiktivo.etoro_Install

> Tracks software installation events for the eToro trading platform, recording installation status progression, affiliate attribution, and error diagnostics for the download-to-install conversion step.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | id (INT IDENTITY) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered on status+date, 1 nonclustered on date) |

---

## 1. Business Meaning

etoro_Install tracks individual software installation events for the eToro trading platform. Each row represents a step in the installation lifecycle - from initiation through completion to first-time run. This is the second stage of the affiliate conversion funnel: Download -> **Install** -> First Time Run -> Registration -> Lead -> Sale.

This table is critical for measuring the download-to-install conversion rate and diagnosing installation failures. It captures error codes, exception details, and completion percentages, enabling the affiliate team to identify technical barriers that prevent successful installations and first-time runs.

Data enters this table as the installer reports progress back to the server. The `status` column tracks the installation lifecycle: '0' = started, '1' = install completed, '2' = installation in progress, '3' = first time run. Three views consume this table: `report_summary` aggregates daily counts by status, `viewInstalls` filters to completed installs (status=1), and `viewFirstTimeRun` filters to first-time runs (status=3). The table contains 178K+ records from the 2007-2012 era.

---

## 2. Business Logic

### 2.1 Installation Status Lifecycle

**What**: Each installation event transitions through status values representing the installation and first-run lifecycle.

**Columns/Parameters Involved**: `status`, `date`

**Rules**:
- Status '0' = Installation started (default on INSERT)
- Status '1' = Installation completed successfully
- Status '2' = Installation in progress (intermediate state)
- Status '3' = First Time Run - the application was launched for the first time after installation
- The `report_summary` view counts status=1 as "Finished_Install", status=2 as "Started_Install", and status=3 as "First_Time_Run"
- The clustered index is on (status, date DESC), optimized for the view queries that filter by status

**Diagram**:
```
[Started (0)] --> [In Progress (2)] --> [Completed (1)] --> [First Time Run (3)]
```

### 2.2 Error Tracking

**What**: Failed or incomplete installations capture diagnostic information for troubleshooting.

**Columns/Parameters Involved**: `Exception`, `PercentComplete`, `ErrorCode`, `Action`, `UpdateModule`, `Try`

**Rules**:
- `PercentComplete` tracks how far the installation got before failure
- `ErrorCode` and `Exception` capture the technical failure reason
- `Action` records what the installer was doing when the error occurred
- `UpdateModule` identifies which component of the installer was active
- `Try` counts the installation attempt number for retries

---

## 3. Data Overview

| id | date | status | rid | serial | ip | Meaning |
|---|---|---|---|---|---|---|
| 27135361 | 2012-12-30 | 1 | 13431 | exget040 | 84.39.232.50 | Completed installation by a user referred by affiliate 13431 with sub-affiliate code 'exget040'. Successful conversion from download to install. |
| 27135360 | 2012-12-30 | 2 | 13431 | exget040 | 84.39.232.50 | Same user/affiliate as above but in 'in progress' state - shows the installer reporting intermediate progress before the completion event. |
| 27135359 | 2012-12-30 | 1 | 3 | (empty) | 94.216.172.218 | Completed installation attributed to house affiliate (rid=3) with no sub-affiliate tracking - organic or direct traffic. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | int (IDENTITY) | NO | Auto-increment | CODE-BACKED | Unique identifier for each installation event. Note: table has no PK constraint, only a clustered index on status+date. |
| 2 | date | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when the installation event was recorded. Defaults to current time. Used by all consuming views for daily aggregation via the CAST(FLOOR(CAST(date AS FLOAT))) pattern. |
| 3 | status | varchar(5) | NO | '0' | CODE-BACKED | Installation lifecycle status: '0'=started, '1'=completed, '2'=in progress, '3'=first time run. Default '0'. report_summary uses status=1 for Finished_Install, status=2 for Started_Install, status=3 for First_Time_Run. viewInstalls filters to '1', viewFirstTimeRun filters to '3'. |
| 4 | rid | bigint | YES | - | CODE-BACKED | Referral/Affiliate ID. Identifies which affiliate drove this installation. Mapped to AffiliateID in viewInstalls and viewFirstTimeRun. |
| 5 | raf | bigint | YES | - | NAME-INFERRED | Secondary referral affiliate parameter, likely a referral source or parent affiliate identifier. |
| 6 | serial | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate serial/tracking code. Mapped to SerialID in consuming views. Allows affiliates to track specific campaigns. |
| 7 | lang | nchar(12) | YES | - | NAME-INFERRED | Language code of the installation. Wider than etoro_Download's 2-char lang field, possibly storing locale codes (e.g., 'en-US'). |
| 8 | ip | nchar(16) | YES | - | CODE-BACKED | IP address of the installing user. Used with ISNULL(ip, 'Unknown') pattern in report_summary for deduplication. |
| 9 | banner | bigint | YES | - | NAME-INFERRED | Banner/creative ID that the user originally clicked, carried forward from the download event. |
| 10 | dl_param | bigint | YES | - | NAME-INFERRED | Download parameter carried forward from the associated download event. |
| 11 | FID | bigint | YES | - | NAME-INFERRED | Funnel ID identifying the marketing funnel or conversion path. |
| 12 | RealProviderID | int | YES | - | CODE-BACKED | Actual provider/broker entity for this installation. Sample data shows value 1 (primary provider). |
| 13 | WhiteLabelID | int | YES | - | CODE-BACKED | White-label brand under which the installation occurred. Sample data shows value 1 (primary brand). |
| 14 | ReportID | int | YES | - | NAME-INFERRED | Report identifier, possibly linking this event to a specific reporting batch or campaign report. |
| 15 | Exception | varchar(max) | YES | - | NAME-INFERRED | Full exception text captured when the installation encounters an error. Used for diagnosing installation failures. |
| 16 | PercentComplete | int | YES | - | NAME-INFERRED | Installation progress percentage (0-100) at the time of the event. Useful for identifying where installations commonly fail. |
| 17 | Action | varchar(max) | YES | - | NAME-INFERRED | Description of the installer action being performed when the event was recorded or when an error occurred. |
| 18 | ErrorCode | varchar(50) | YES | - | NAME-INFERRED | Error code from the installer if the installation failed. Used alongside Exception for technical troubleshooting. |
| 19 | UpdateModule | varchar(50) | YES | - | NAME-INFERRED | Installer module or component that was active during this event (e.g., 'CoreInstaller', 'DataUpdater'). |
| 20 | DownloadID | bigint | YES | - | NAME-INFERRED | Links this installation event to the originating download event in etoro_Download. Enables tracking the full Download -> Install chain. |
| 21 | Try | int | YES | - | NAME-INFERRED | Installation attempt number. Increments with each retry, enabling analysis of how many attempts users need for successful installation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| rid | dbo.tblaff_Affiliates | Implicit | References the affiliate who drove the installation |
| DownloadID | fiktivo.etoro_Download | Implicit | Links back to the originating download event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.report_summary | date, status, ip, rid, raf, serial | View (READER) | Aggregates daily install counts: status=1 (finished), status=2 (started), status=3 (first time run) |
| fiktivo.viewInstalls | date, rid, serial, status, ip | View (READER) | Filters to completed installs (status=1) for funnel union |
| fiktivo.viewFirstTimeRun | date, rid, serial, status, ip | View (READER) | Filters to first-time runs (status=3) for funnel union |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.report_summary | View | Reads install data aggregated by date and status |
| fiktivo.viewInstalls | View | Filters to completed installations |
| fiktivo.viewFirstTimeRun | View | Filters to first-time run events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CLU_etoro_Install | CLUSTERED | status ASC, date DESC | - | - | Active |
| IX__etoro_Install__date | NONCLUSTERED | date ASC | status | - | Active |

Note: No primary key constraint exists. The clustered index on (status, date DESC) optimizes the view queries that filter by status and aggregate by date. FILLFACTOR=90, PAGE compression.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_etoro_Install_date | DEFAULT | GETDATE() for date - auto-timestamps installation events |
| DF_etoro_Install_status | DEFAULT | '0' for status - new events start as 'started' |

---

## 8. Sample Queries

### 8.1 Daily installation counts by status
```sql
SELECT CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME) AS InstallDate,
       status,
       COUNT(*) AS EventCount
FROM fiktivo.etoro_Install WITH (NOLOCK)
GROUP BY CAST(FLOOR(CAST(date AS FLOAT)) AS DATETIME), status
ORDER BY InstallDate DESC
```

### 8.2 Installation completion rate by affiliate
```sql
SELECT rid AS AffiliateID,
       COUNT(CASE WHEN status = '1' THEN 1 END) AS Completed,
       COUNT(CASE WHEN status = '3' THEN 1 END) AS FirstTimeRun,
       COUNT(*) AS Total
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE rid IS NOT NULL
GROUP BY rid
ORDER BY COUNT(*) DESC
```

### 8.3 Failed installations with error details
```sql
SELECT TOP 10 id, date, ErrorCode, PercentComplete, Action, UpdateModule, Exception
FROM fiktivo.etoro_Install WITH (NOLOCK)
WHERE ErrorCode IS NOT NULL
ORDER BY date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 6.8/10 (Elements: 5.2/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 13 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_Install | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_Install.sql*
