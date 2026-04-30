# Customer.ExportDetailsForMailStocks

> Exports customer data to CSV files for the SilverPop email marketing system using BCP and xp_cmdshell; functionally identical to Customer.ExportDetailsForMail but without the Always On primary-replica guard, used specifically for stocks-related customer export views.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ViewName (view to export from), @CID scope via Internal.CIDToMail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ExportDetailsForMailStocks is the stocks-specific variant of Customer.ExportDetailsForMail. It generates CSV export files for the SilverPop email marketing platform from a parameterized view, writing the output to the database server's filesystem using BCP for high-performance bulk export and xp_cmdshell for file operations.

The "Stocks" name indicates this variant is intended for use with stocks-focused customer views (e.g., views filtering for customers with stock positions). The core purpose is identical to ExportDetailsForMail: create a timestamped CSV file of customer data for SilverPop to consume.

The key architectural difference from ExportDetailsForMail is the absence of the Always On primary replica guard (`fn_hadr_database_is_primary`). This means Internal.CIDToMail status updates will execute on any replica, making it unsuitable for Always On AG environments without care. It was likely created before the HA guard was introduced and retained for legacy compatibility.

---

## 2. Business Logic

### 2.1 Internal.CIDToMail Status Lifecycle

**What**: Tracks which customers need email delivery and prevents duplicate sends.

**Columns/Parameters Involved**: `Internal.CIDToMail.Status`, `Internal.CIDToMail.ImmediateSend`, `@ImmediateSend`

**Rules**:
- Status 4 cleanup: deletes processed rows in batches of 3000 at start of each run (prevents table bloat)
- Immediate mode (@ImmediateSend=1):
  - Status 0 or 1 AND ImmediateSend=1 -> set to Status=1 (mark for export)
  - After export: Status=1, ImmediateSend=1 -> set to Status=2 (sent)
- Daily mode (@ImmediateSend=0):
  - All Status < 3 -> set to Status=3 in batches of 3000 (mark for daily export)
  - After export: Status=3 -> set to Status=4 in batches of 3000 (sent)
- No rows to process + @ExportAll=0: returns 0 immediately (no file created)

**Diagram**:
```
Immediate mode:
  0/1 (pending, ImmediateSend=1) -> [export] -> 2 (sent immediate)

Daily mode:
  0-2 (any pending) -> 3 (queued for daily) -> [export] -> 4 (sent daily)
  4 (sent daily) -> deleted at next run start
```

### 2.2 Two-File BCP Export with Merge

**What**: BCP cannot include column headers natively, so the procedure creates two separate files and merges them.

**Columns/Parameters Involved**: `@Path`, `@FileName`, `@ViewName`, `@DBName`

**Rules**:
- File 1: BCP exports a single row of column names (SELECT 'col1,col2,...') to TmpColNames.csv
- File 2: BCP exports actual data rows to Tmp{filename}.csv
- Merge: COPY {file1} + {file2} -> {yyyyMMddHHmmss}_{filename}.csv (final output)
- Cleanup: DEL Tmp*.* removes both temporary files
- Column names extracted from INFORMATION_SCHEMA.COLUMNS for the given @ViewName
- Known debug artifact: `select @OSString` on the BCP data command is left in the production code (outputs the BCP command string as a result set)

### 2.3 @ExportAll vs CIDToMail-Filtered Export

**What**: Controls whether to export all customers or only those flagged in Internal.CIDToMail.

**Rules**:
- @ExportAll=1: SELECT DISTINCT v.* FROM {DBName}.{ViewName} (+ optional @ExtraWhereClause)
- @ExportAll=0: Triple UNION ALL joining to CIDToMail by GCID (for GCID > 0), by RealCID (for GCID=0, real customers), by DemoCID (for GCID=0, demo-only customers)
- If @ExportAll=1: @ImmediateSend is irrelevant (all customers exported regardless)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExportAll | INT | YES | 0 | CODE-BACKED | 0 = export only customers queued in Internal.CIDToMail; 1 = export all customers from the view (ignores @ImmediateSend and CIDToMail status). |
| 2 | @Path | varchar(100) | NO | - | CODE-BACKED | Filesystem path on the SQL Server host where CSV files are written (e.g., 'C:\' or 'E:\SilverPop\'). Trailing backslash is auto-appended if missing. REQUIRED - raises error if empty. |
| 3 | @DBName | varchar(30) | NO | - | CODE-BACKED | Database name to use in fully-qualified view references in dynamic SQL and BCP commands (e.g., 'etoro', 'etoro_rep'). REQUIRED - raises error if empty. |
| 4 | @ViewName | varchar(50) | NO | - | CODE-BACKED | Schema-qualified view name to export data from (e.g., 'Customer.GetRealCustomersShortVersionForMail'). Column names are extracted from INFORMATION_SCHEMA using this value. REQUIRED. |
| 5 | @FileName | varchar(50) | NO | - | CODE-BACKED | Base filename for the output CSV (e.g., 'RealStocksCust'). Final file is named {yyyyMMddHHmmss}_{FileName}.csv. REQUIRED. |
| 6 | @ImmediateSend | INT | YES | 1 | CODE-BACKED | 1 = immediate/near-real-time mode (exports CIDToMail rows with ImmediateSend=1 and Status 0 or 1); 0 = daily batch mode (exports all pending Status < 3 rows). Ignored when @ExportAll=1. |
| 7 | @ExtraWhereClause | varchar(500) | YES | NULL | CODE-BACKED | Optional additional WHERE clause fragment injected directly into the dynamic BCP query string (e.g., '(RealCID + DemoCID) % 5 = 0' for modulo sharding). WARNING: dynamic SQL injection risk if called by untrusted sources. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Status updates | Internal.CIDToMail | Read + UPDATE + DELETE | Status lifecycle: marks pending -> queued -> sent; cleans up processed rows |
| @ViewName (dynamic) | Customer.GetRealCustomersShortVersionForMail (example) | BCP export source | Customer data rows to write to CSV |
| INFORMATION_SCHEMA.COLUMNS | System metadata | Read | Extracts column names for CSV header row generation |
| xp_cmdshell | OS shell | Execute | BCP bulk export, COPY merge, DEL cleanup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (SQL role) | EXECUTE | Permission | BI admin role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ExportDetailsForMailStocks (procedure)
├── Internal.CIDToMail (table - cross-schema)
├── INFORMATION_SCHEMA.COLUMNS (system view)
└── {DBName}.{ViewName} (dynamic - caller-specified, e.g., Customer.GetRealCustomersShortVersionForMail)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.CIDToMail | Table | Status lifecycle management for pending email customers (DELETE, UPDATE, SELECT) |
| INFORMATION_SCHEMA.COLUMNS | System view | Column name extraction for CSV header row |
| {ViewName} (dynamic) | View | Customer data source for BCP export |
| xp_cmdshell | Extended procedure | File system operations (BCP export, COPY merge, DEL cleanup) |

### 6.2 Objects That Depend On This

No dependents found (called externally via SQL Agent jobs or direct execution by BI admin roles).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Required param validation | Input guard | RAISERROR if @DBName, @ViewName, @Path, or @FileName is NULL or empty |
| Batch DML (3000 rows) | Performance | DELETE and UPDATE on Internal.CIDToMail run in loops of 3000 to avoid long table locks |
| Dynamic SQL via @Query | Design | @ViewName and @ExtraWhereClause injected into BCP query string - SQL injection risk if caller is untrusted |
| No HA guard | Missing | Unlike ExportDetailsForMail, there is NO Always On replica check - status writes run on any replica |
| xp_cmdshell dependency | Infrastructure | Requires xp_cmdshell enabled on the SQL Server instance |
| Debug artifact | Code quality | `select @OSString` on line 164 outputs the BCP command string as a result set - known leftover |

---

## 8. Sample Queries

### 8.1 Export all stocks customers for daily SilverPop feed

```sql
EXEC Customer.ExportDetailsForMailStocks
    @ExportAll = 1,
    @Path = 'E:\SilverPop\',
    @DBName = 'etoro',
    @ViewName = 'Customer.GetRealCustomersShortVersionForMail',
    @FileName = 'RealStocksCust',
    @ImmediateSend = 0
```

### 8.2 Export pending immediate-send customers (stocks, 15-minute cycle)

```sql
EXEC Customer.ExportDetailsForMailStocks
    @ExportAll = 0,
    @Path = 'E:\SilverPop\',
    @DBName = 'etoro',
    @ViewName = 'Customer.GetRealCustomersShortVersionForMail',
    @FileName = 'StocksImmediate',
    @ImmediateSend = 1
```

### 8.3 Check CIDToMail queue status before running export

```sql
SELECT Status, ImmediateSend, COUNT(*) AS CustomerCount
FROM Internal.CIDToMail WITH (NOLOCK)
GROUP BY Status, ImmediateSend
ORDER BY Status
-- Status: 0=pending, 1=queued immediate, 2=sent immediate, 3=queued daily, 4=sent daily
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 inherited (ExportDetailsForMail) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ExportDetailsForMailStocks | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.ExportDetailsForMailStocks.sql*
