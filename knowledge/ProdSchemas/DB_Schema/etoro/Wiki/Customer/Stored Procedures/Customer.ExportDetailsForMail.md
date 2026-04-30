# Customer.ExportDetailsForMail

> Exports customer data to CSV files for the SilverPop email marketing system using BCP and xp_cmdshell, with Always On primary-replica awareness, Internal.CIDToMail status lifecycle management, and two delivery modes: immediate (15-minute cycle) and daily (all pending).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ViewName (view to export from), @CID scope via Internal.CIDToMail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ExportDetailsForMail is the CSV file generation procedure for the SilverPop email marketing platform. It exports customer data from a specified view to a timestamped CSV file on the database server's filesystem, using BCP for high-performance bulk export and xp_cmdshell for file operations.

The procedure exists because SilverPop (an email marketing platform) requires customer data as a CSV feed - not a live database connection. eToro pushes data rather than letting SilverPop pull. Two views feed two export types: `Customer.GetRealCustomersForSilverPopMail` for real customer emails and `Customer.GetDemoCustomersForSilverPopMail` for demo customer emails. The generic design (view name as parameter) means a single procedure handles both cases.

The procedure has two operational modes: @ImmediateSend=1 (near-real-time, 15-minute cycle for customers flagged for urgent email delivery) and @ImmediateSend=0 (daily batch for all pending customers). Internal.CIDToMail tracks which customers need email and their delivery status, with a status lifecycle (0->1 or 3 -> 2 or 4) that ensures customers are not emailed twice.

The Always On replica check (`fn_hadr_database_is_primary`) prevents secondary replicas from executing write operations (CIDToMail status updates) while still allowing file exports from read-only replicas.

---

## 2. Business Logic

### 2.1 Internal.CIDToMail Status Lifecycle

**What**: The procedure manages a status machine in Internal.CIDToMail to track which customers have been emailed.

**Columns/Parameters Involved**: `Internal.CIDToMail.Status`, `Internal.CIDToMail.ImmediateSend`, `@ImmediateSend`

**Rules**:
- Status 4: already sent (daily mode) - cleaned up in batches of 3000 at procedure start
- Immediate mode (@ImmediateSend=1):
  - Status 0 or 1 AND ImmediateSend=1 -> set to Status=1 (mark for export)
  - After successful export: Status=1, ImmediateSend=1 -> set to Status=2 (sent)
- Daily mode (@ImmediateSend=0):
  - Status < 3 -> set to Status=3 in batches of 3000 (mark all pending for export)
  - After successful export: Status=3 -> set to Status=4 in batches of 3000 (sent)
- Only runs status management on the primary replica

**Diagram**:
```
Immediate mode:
  0/1 (pending, ImmediateSend=1) -> [export] -> 2 (sent)

Daily mode:
  0/1/2/3 (any pending status) -> 3 (queued for daily) -> [export] -> 4 (sent daily)
  4 (sent daily) -> cleaned up at next run
```

### 2.2 Two-File BCP Export with Merge

**What**: BCP cannot add column headers, so the procedure creates two files then merges them.

**Columns/Parameters Involved**: `@Path`, `@FileName`, `@ViewName`, `@DBName`, `@FileDatePart`

**Rules**:
- File 1: BCP export of column names only (SELECT 'col1,col2,...') to Tmp{filename}ColNames{timestamp}.csv
- File 2: BCP export of actual data rows to Tmp{filename}{timestamp}.csv
- Merge: COPY {file1} + {file2} -> {timestamp}_{filename}.csv (final output)
- Delete temp files: DEL Tmp*{timestamp}.*
- Column names extracted from INFORMATION_SCHEMA.COLUMNS for the specified view
- Final filename format: {path}{yyyyMMddHHmmss}_{filename}.csv

### 2.3 @ExportAll vs CIDToMail-Filtered Export

**What**: Two export scopes: all customers or only those flagged in Internal.CIDToMail.

**Rules**:
- @ExportAll=1: SELECT DISTINCT v.* FROM {DBName}.{ViewName} (optionally filtered by @ExtraWhereClause)
- @ExportAll=0: Complex UNION ALL query joining to Internal.CIDToMail by GCID (first), then by RealCID (for GCID=0), then by DemoCID (for GCID=0, demo-only customers)
- The triple UNION ALL handles three identity lookup strategies for CIDToMail matching

### 2.4 Always On Primary Replica Guard

**What**: Only the primary replica executes status management writes; all replicas can do file exports.

**Rules**:
- `[master].[dbo].[fn_hadr_database_is_primary](DB_NAME())` -> 1 if primary
- Status updates to Internal.CIDToMail ONLY if @IsPrimaryReplica = 1
- File export (BCP) runs regardless of replica role
- Prevents dual-write on failover scenarios

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExportAll | INT | YES | 0 | CODE-BACKED | 0=export only customers in Internal.CIDToMail, 1=export all customers from the view. When 1, @ImmediateSend is ignored. |
| 2 | @Path | varchar(100) | NO | - | CODE-BACKED | Filesystem path for output files (e.g., 'C:\' or 'E:\'). Trailing backslash auto-added if missing. REQUIRED - raises error if empty. |
| 3 | @DBName | varchar(30) | NO | - | CODE-BACKED | Database name for BCP export and view queries (e.g., 'etoro_rep', 'RealDev'). Used to construct fully-qualified view names in dynamic SQL. REQUIRED. |
| 4 | @ViewName | varchar(50) | NO | - | CODE-BACKED | Full schema-qualified view name to export (e.g., 'Customer.GetRealCustomersForSilverPopMail'). Must exist in @DBName. Column names extracted from INFORMATION_SCHEMA. REQUIRED. |
| 5 | @FileName | varchar(50) | NO | - | CODE-BACKED | Base filename for the output CSV (e.g., 'cust', 'DemoCust'). Final file: {timestamp}_{filename}.csv. REQUIRED. |
| 6 | @ImmediateSend | INT | YES | 1 | CODE-BACKED | 1=immediate mode (15-minute cycle, ImmediateSend=1 rows in CIDToMail), 0=daily mode (all pending CIDToMail rows). Ignored when @ExportAll=1. |
| 7 | @ExtraWhereClause | varchar(500) | YES | NULL | CODE-BACKED | Additional WHERE clause fragment injected into the dynamic BCP query (e.g., '(RealCID + DemoCID) % 5 = 0' for modulo-based sharding). WARNING: potential SQL injection if not controlled by trusted callers only. |

**No result set (SELECT @OSString outputs the BCP command string as a side effect - debug artifact in production code).**

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Internal.CIDToMail | Internal.CIDToMail | Read + UPDATE | Status lifecycle management for pending email customers |
| @ViewName (dynamic) | Customer.GetRealCustomersForSilverPopMail etc. | BCP export source | Actual customer data to export |
| INFORMATION_SCHEMA.COLUMNS | System metadata | Read | Column name extraction for CSV header row |
| xp_cmdshell | OS command shell | Execute | BCP export, COPY merge, DEL cleanup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.ExportDetailsForMailStocks | EXEC (likely) | Caller | Stocks-specific variant calls this for core CSV export |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ExportDetailsForMail (procedure)
├── Internal.CIDToMail (table - cross-schema)
├── INFORMATION_SCHEMA.COLUMNS (system view)
└── {DBName}.{ViewName} (dynamic - e.g., Customer.GetRealCustomersForSilverPopMail)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.CIDToMail | Table | Status management for pending email delivery; DELETE, UPDATE, SELECT |
| INFORMATION_SCHEMA.COLUMNS | System view | Column name extraction for CSV header |
| {ViewName} (dynamic, via @ViewName param) | View | Customer data to export via BCP |
| xp_cmdshell | Extended procedure | OS-level file operations (BCP, COPY, DEL) |
| master.dbo.fn_hadr_database_is_primary | Function | Always On replica role check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExportDetailsForMailStocks | Procedure | Likely calls this for email export (batch plan note: "called by ExportDetailsForMailStocks L1") |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR if required params empty | Validation | @Path, @DBName, @ViewName, @FileName all required |
| Primary replica check | HA guard | Status writes only on primary; BCP export runs on any replica |
| Batch DELETE/UPDATE (3000 rows) | Performance | Prevents long table locks on Internal.CIDToMail |
| Dynamic SQL in @Query | Design | @ViewName and @ExtraWhereClause injected - SQL injection risk if callers are untrusted |
| xp_cmdshell required | Dependency | Requires xp_cmdshell enabled on the SQL Server instance |

---

## 8. Sample Queries

### 8.1 Export all real customers for daily SilverPop feed

```sql
EXEC Customer.ExportDetailsForMail
    @ExportAll = 1,
    @Path = 'E:\SilverPop\',
    @DBName = 'etoro',
    @ViewName = 'Customer.GetRealCustomersShortVersionForMail',
    @FileName = 'RealCust',
    @ImmediateSend = 0
```

### 8.2 Export pending immediate-send customers (15-minute cycle)

```sql
EXEC Customer.ExportDetailsForMail
    @ExportAll = 0,
    @Path = 'E:\SilverPop\',
    @DBName = 'etoro',
    @ViewName = 'Customer.GetRealCustomersShortVersionForMail',
    @FileName = 'RealCustImmediate',
    @ImmediateSend = 1
```

### 8.3 Check pending customers in CIDToMail by status

```sql
SELECT Status, ImmediateSend, COUNT(*) AS CustomerCount
FROM Internal.CIDToMail WITH (NOLOCK)
GROUP BY Status, ImmediateSend
ORDER BY Status
-- Status 0=pending, 1=queued immediate, 2=sent immediate, 3=queued daily, 4=sent daily
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ExportDetailsForMail | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.ExportDetailsForMail.sql*
