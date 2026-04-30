# apex.SodFiles

> Master registry of all SOD (Start-of-Day) files imported from Apex Clearing Corporation. Each row represents a single file ingested from Azure Blob Storage, tracking its source URL, processing status, extract format, and any errors.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (1 PK + 3 NC) |

---

## 1. Business Meaning

This is the central registry table for the Apex Clearing SOD file import pipeline. Every file received from Apex - whether successfully processed, failed, or invalid - gets a row here. The table serves as both the processing tracker and the parent reference for all extract data tables (every `apex.EXT*` table has a FK back to this table via `SodFileId`).

Without this table, there would be no way to track which files have been processed, correlate imported data back to its source file, or cascade-delete all data from a bad import.

Data flow: Every 2 hours, Azure Data Factory connects to Apex's SFTP server and downloads new CSV/TXT files into Azure Blob Storage (organized by date and extract number, e.g., `20260411/EXT871/EXT871_ETRO_20260411.CSV`). An Event Grid trigger fires the SOD Azure Function, which creates a SodFiles row (Status=0/Unknown), starts parsing (Status=1/InProgress), and either succeeds (Status=2) or fails (Status=3/4). The parsed data rows are inserted into the corresponding `apex.EXT{format}` table with the SodFileId FK.

Currently contains ~95K file records. After successful EXT871/EXT872 imports, the system triggers a reconciliation flow comparing Apex data against eToro's internal positions and trades.

---

## 2. Business Logic

### 2.1 File Processing Lifecycle

**What**: Each file progresses through processing statuses.

**Columns/Parameters Involved**: `Status`, `ImportStartDate`, `ImportEndDate`, `ErrorMessage`

**Rules**:
- Status=0 (Unknown): Record created, file detected but not parsed yet
- Status=1 (InProgress): Azure Function is actively parsing and importing the file
- Status=2 (Success): All data loaded into the corresponding EXT table
- Status=3 (Fail): Processing failed - ErrorMessage contains the exception details
- Status=4 (Invalid): File format unknown - extract number doesn't map to any known table
- ImportStartDate is set on record creation, ImportEndDate on completion (success or failure)

### 2.2 ApexFormat Routing

**What**: The ApexFormat integer determines which EXT table receives the parsed data.

**Columns/Parameters Involved**: `ApexFormat`

**Rules**:
- ApexFormat maps directly to the extract number: 871 -> EXT871_PositionActivity, 872 -> EXT872_TradeActivity, etc.
- ApexFormat=0 indicates unknown/unrecognized format (26K files with this value)
- ApexFormat=1 maps to EXT001_EasyToBorrowList
- The Azure Function uses this value to select the correct parser and target table

### 2.3 Cascade Delete

**What**: Deleting a SodFiles row cascades to all child EXT table rows.

**Rules**:
- All 29 EXT tables have ON DELETE CASCADE FK to SodFiles
- This enables clean removal of all data from a bad import by deleting the single SodFiles row

---

## 3. Data Overview

| Id | BlobUrl (truncated) | ProcessDate | ApexFormat | Status | Meaning |
|---|---|---|---|---|---|
| A6E1A384... | .../EXT1037/EXT1037_ETRO_20260411.CSV | 2026-04-11 | 0 | 4 (Invalid) | Unrecognized file format - EXT1037 not mapped to any table. Status=Invalid with error explaining unknown format. |
| 92B8CACA... | .../EXT1036/EXT1036_ETRO_20260410.CSV | 2026-04-10 | 1036 | 2 (Success) | W8 Recertification file successfully parsed and loaded into EXT1036_W8Recertification table. |
| A75D4256... | .../EXT1027/EXT1027_ETRO_20260410.CSV | 2026-04-10 | 1027 | 3 (Fail) | Tax Lot Detail file failed - Azure Function threw ArgumentOutOfRangeException (file too large for buffer). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | VERIFIED | Primary key. Auto-generated sequential GUID for each imported file. Referenced by all EXT tables via SodFileId FK. |
| 2 | BlobUrl | nvarchar(max) | YES | - | VERIFIED | Full URL to the source file in Azure Blob Storage. Format: `https://{account}.blob.core.windows.net/blob-container/{YYYYMMDD}/EXT{num}/EXT{num}_{correspondent}_{YYYYMMDD}.CSV`. Contains the date, extract number, and correspondent code in the path. |
| 3 | ImportStartDate | datetime2(7) | NO | getdate() | CODE-BACKED | Timestamp when the Azure Function started processing this file. Auto-set to current time on row creation. |
| 4 | ImportEndDate | datetime2(7) | YES | - | CODE-BACKED | Timestamp when processing completed (success, fail, or invalid). NULL while Status=InProgress. |
| 5 | ProcessDate | datetime2(7) | NO | - | VERIFIED | The business date this file belongs to (extracted from the file path date folder, e.g., 20260411 -> 2026-04-11). This is the date the data represents at Apex, not the import timestamp. |
| 6 | ApexFormat | int | NO | - | VERIFIED | Apex extract format number identifying the file type. Maps to the EXT table: 1=EXT001, 235=EXT235, 747=EXT747, 871=EXT871, etc. 0=Unknown/unrecognized format. Determines which parser and target table the Azure Function uses. |
| 7 | Status | int | NO | 0 | VERIFIED | File processing status. FK to dict.SodFileProcessingStatuses: 0=Unknown, 1=InProgress, 2=Success, 3=Fail, 4=Invalid. Default 0 (Unknown) on creation. |
| 8 | ErrorMessage | nvarchar(4000) | YES | - | CODE-BACKED | Error details when Status=3 (Fail) or Status=4 (Invalid). Contains exception stack traces for failures, or "Unknown file format" messages for invalid files. NULL on success. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Status | dict.SodFileProcessingStatuses | FK (ON DELETE CASCADE) | Processing status lookup: 0=Unknown, 1=InProgress, 2=Success, 3=Fail, 4=Invalid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| All 29 apex.EXT* tables | SodFileId | FK (ON DELETE CASCADE) | Every extract data row links back to its source file |
| apex.GetClosedAccounts | @SodFileId parameter | Parameter | SP filters EXT538 by SodFileId |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.SodFiles (table)
└── dict.SodFileProcessingStatuses (table) [Status FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dict.SodFileProcessingStatuses | Table | FK from Status column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| All 29 apex.EXT* tables | Tables | FK from SodFileId with CASCADE DELETE |
| apex.GetClosedAccounts | Stored Procedure | Filters by SodFileId parameter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SodFiles | CLUSTERED PK | Id | - | - | Active |
| IX_ProcessDate | NC | ProcessDate | - | - | Active |
| IX_SodFiles_ApexFormat_ProcessDate_ImportEndDate | NC | ApexFormat, ProcessDate, ImportEndDate | - | - | Active |
| IX_SodFiles_Status | NC | Status | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SodFiles | PRIMARY KEY | Unique Id per file |
| FK_SodFiles_SodFileProcessingStatuses_Status | FOREIGN KEY | Status -> dict.SodFileProcessingStatuses.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |
| (default) | DEFAULT | getdate() for ImportStartDate |
| (default) | DEFAULT | 0 for Status (Unknown) |

---

## 8. Sample Queries

### 8.1 Find recent successful imports by format

```sql
SELECT ApexFormat, ProcessDate, BlobUrl, ImportStartDate, ImportEndDate
FROM apex.SodFiles WITH (NOLOCK)
WHERE Status = 2 AND ProcessDate >= '2026-04-10'
ORDER BY ProcessDate DESC, ApexFormat;
```

### 8.2 Find failed imports with error details

```sql
SELECT Id, ApexFormat, ProcessDate, Status, ErrorMessage
FROM apex.SodFiles WITH (NOLOCK)
WHERE Status IN (3, 4)
ORDER BY ImportStartDate DESC;
```

### 8.3 Count files by format and status

```sql
SELECT ApexFormat, s.Value AS Status, COUNT(*) AS FileCount
FROM apex.SodFiles f WITH (NOLOCK)
JOIN dict.SodFileProcessingStatuses s WITH (NOLOCK) ON f.Status = s.Id
GROUP BY ApexFormat, s.Value
ORDER BY ApexFormat, s.Value;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Full data flow: Data Factory -> Blob Storage -> Event Grid -> Azure Function -> SodFiles + EXT tables. Each file gets unique ID, data saved to respective table based on format. EXT871/872 trigger reconciliation. Message sent to Service Bus on completion. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: apex.SodFiles | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.SodFiles.sql*
