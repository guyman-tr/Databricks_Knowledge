# Dictionary.SalesForceImprtProcess

## 1. Business Meaning

**What it is**: A watermark/checkpoint table that tracks Salesforce data import processes. Each row represents a distinct Salesforce import pipeline, recording the last successfully imported batch ID and timestamp to enable incremental synchronization.

**Why it exists**: eToro syncs customer data from Salesforce into the `BackOffice.Customer` table (specifically `SalesForceAccountID` and `SalesForceContactID`). This table acts as a cursor/bookmark so the sync process can resume from where it left off rather than re-importing all data. Without it, every sync would need to scan the entire Salesforce dataset.

**How it works**: The procedure `Internal.SyncAccountAndContactIDsFromSalesForce` reads `LastImportDate` for process ID 1 (AccountAndContactIDs), queries Salesforce for records created after that date, batch-updates `BackOffice.Customer` with the new Salesforce IDs, then writes the newest record's date back as the new `LastImportDate`. This creates a rolling incremental sync window.

---

## 2. Business Logic

### Import Processes
| ID | Process | Purpose |
|----|---------|---------|
| 1 | AccountAndContactIDs | Syncs Salesforce Account ID and Contact ID to BackOffice.Customer — actively used |
| 2 | AccountManager | Intended for manager assignment sync — never activated (LastImportDate is NULL) |

### Sync Flow
```
1. Read LastImportDate from process ID 1
2. Query SYN_SalesForce_DB_IdMapTopology WHERE SF_CreatedDate > LastImportDate
3. Batch update BackOffice.Customer (3000 rows per iteration)
4. Update LastImportDate = MAX(LastUpdate) from imported batch
```

### Incremental Window
If `LastImportDate` is NULL (first run or reset), the procedure defaults to `DATEADD(day, -3, GETDATE())` — a 3-day lookback window as a safety net.

---

## 3. Data Overview

| SalesForceImprtProcessID | SalesForceImprtProcessName | LastImportID | LastImportDate | Business Meaning |
|--------------------------|---------------------------|--------------|----------------|------------------|
| 1 | AccountAndContactIDs | NULL | 2020-08-02 | Active sync — last ran Aug 2020 |
| 2 | AccountManager | NULL | NULL | Never executed — placeholder |

*2 rows — one active import pipeline, one reserved*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SalesForceImprtProcessID** | int | NOT NULL | — | Primary key. Import process identifier. Currently 1=AccountAndContactIDs, 2=AccountManager. | `MCP` |
| **SalesForceImprtProcessName** | varchar(255) | NOT NULL | — | Human-readable name of the Salesforce import process. Used for identification in monitoring. | `MCP` |
| **LastImportID** | bigint | NULL | — | Last imported record's Salesforce ID. Currently NULL for both processes — the sync uses date-based windowing instead. | `MCP` |
| **LastImportDate** | datetime | NULL | — | Timestamp of the most recent successfully imported record. Used by `Internal.SyncAccountAndContactIDsFromSalesForce` as the incremental sync cursor. Falls back to GETDATE()-3 days if NULL. | `CODE+MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — standalone configuration table.*

### Referenced By (other objects point to this table)
| Referencing Object | Column | Relationship | Business Meaning |
|-------------------|--------|--------------|------------------|
| Internal.SyncAccountAndContactIDsFromSalesForce | SalesForceImprtProcessID | WHERE clause | Reads/updates the sync watermark for incremental Salesforce import |

---

## 6. Dependencies

### Depends On
*None.*

### Depended On By
- `Internal.SyncAccountAndContactIDsFromSalesForce` — incremental Salesforce sync procedure

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SalesForceImprtProcessID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Fill Factor | 95% |
| Row Count | 2 |

---

## 8. Sample Queries

```sql
-- Check current sync status
SELECT  SalesForceImprtProcessID, SalesForceImprtProcessName,
        LastImportID, LastImportDate
FROM    Dictionary.SalesForceImprtProcess WITH (NOLOCK)
ORDER BY SalesForceImprtProcessID;

-- Check how stale the Salesforce sync is
SELECT  SalesForceImprtProcessName,
        LastImportDate,
        DATEDIFF(DAY, LastImportDate, GETDATE()) AS DaysSinceLastSync
FROM    Dictionary.SalesForceImprtProcess WITH (NOLOCK)
WHERE   LastImportDate IS NOT NULL;

-- Verify which processes have never run
SELECT  SalesForceImprtProcessID, SalesForceImprtProcessName
FROM    Dictionary.SalesForceImprtProcess WITH (NOLOCK)
WHERE   LastImportDate IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. The Salesforce integration is managed through the `Internal.SyncAccountAndContactIDsFromSalesForce` procedure which queries the linked server `SYN_SalesForce_DB_IdMapTopology`.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (2 rows), codebase traced (1 procedure consumer with full logic extraction)*
