# Hedge.DeleteRecordsFromHedgingTables

> Data retention maintenance procedure that purges records older than 1 month from hedging position and status tables, with per-table error isolation.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - runs on fixed 1-month retention window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure enforces a rolling 1-month data retention policy across the active hedging snapshot tables. Hedging position and account status tables store point-in-time snapshots of the hedge system state; beyond one month, these records are no longer needed for reconciliation or operational purposes and are purged to control table size.

The procedure exists to prevent unbounded growth of high-volume hedging snapshot tables. Without regular purging, tables like `Hedge.AccountClosedPositions` and `Hedge.AccountStatus` would accumulate indefinitely, degrading query performance for the hedge engine which reads these tables frequently during live hedging operations.

The procedure is designed to be called by a scheduled SQL Agent job (no application callers detected). It computes the cutoff as midnight UTC 1 month prior to the current date, ensuring consistent retention regardless of the time of day it runs. Error handling is isolate per table - if one delete fails, the remaining tables are still attempted, and errors are surfaced together at the end.

---

## 2. Business Logic

### 2.1 Retention Window Calculation

**What**: The cutoff date is the start of the day 1 calendar month before today (UTC), ensuring full days are retained.

**Columns/Parameters Involved**: Computed internally as `@DeleteDate`

**Rules**:
- Cutoff = `DATEADD(month, -1, DATEADD(dd, 0, DATEDIFF(dd, 0, GETUTCDATE())))` - midnight UTC 1 month ago
- All records with `OccurredAt < @DeleteDate` are deleted
- Records from exactly 1 month ago (same day) are RETAINED (strict less-than)
- All tables use the same `@DeleteDate` cutoff for consistency

**Diagram**:
```
Today (UTC midnight)
|--- [keep] -----|-- 1 month ago --|- [delete] ------> past
                 ^
             @DeleteDate
```

### 2.2 Per-Table Error Isolation

**What**: Each table delete runs in its own TRY/CATCH block so a failure on one table does not abort the others.

**Columns/Parameters Involved**: `@ErrorMessage` accumulator

**Rules**:
- Each of the 5 DELETE statements is wrapped independently in BEGIN TRY/BEGIN CATCH
- On failure, a descriptive message is appended to `@ErrorMessage` (newline-separated)
- After all 5 deletes have been attempted, if `@ErrorMessage <> ''`, a single `RAISERROR` is raised at severity 16
- This ensures maximum data cleanup even if some tables have issues

**Diagram**:
```
[Table 1 TRY]--CATCH--> append error
[Table 2 TRY]--CATCH--> append error
[Table 3 TRY]--CATCH--> append error
[Table 4 TRY]--CATCH--> append error
[Table 5 TRY]--CATCH--> append error
IF @ErrorMessage <> '' --> RAISERROR(all messages)
```

### 2.3 Orphaned Table References (Legacy Code)

**What**: Three of the five target tables no longer exist in the database or SSDT project, indicating partial decommissioning.

**Columns/Parameters Involved**: Dynamic SQL DELETE targets

**Rules**:
- `Hedge.AccountClosedPositions` - EXISTS and is documented
- `Hedge.AccountOpenPositions` - DOES NOT EXIST (neither in SSDT nor live DB)
- `Hedge.AccountStatus` - EXISTS and is documented
- `Hedge.CustomerClosedPositions` - DOES NOT EXIST (neither in SSDT nor live DB)
- `Hedge.CustomerOpenPositions` - DOES NOT EXIST (neither in SSDT nor live DB)
- The TRY/CATCH blocks for the 3 non-existent tables will always trigger CATCH (table not found), appending error messages but not blocking completion
- This procedure should be updated to remove the orphaned table references

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no input parameters. The retention window is hardcoded as 1 calendar month before the current UTC date. |

**Internal Variables** (not parameters - for documentation completeness):

| Variable | Type | Description |
|----------|------|-------------|
| `@DeleteDate` | datetime | Computed cutoff: midnight UTC 1 month ago. Records with `OccurredAt < @DeleteDate` are deleted across all target tables. |
| `@SQL` | nvarchar(2000) | Dynamic SQL string for each DELETE statement. Dynamic SQL is used to avoid recompilation of the execution plan per table. |
| `@ParamDef` | nvarchar(200) | Parameter definition string for sp_executesql: `'@DeleteDate datetime'`. |
| `@ErrorMessage` | varchar(500) | Accumulates error messages from failed per-table DELETE operations. If non-empty after all attempts, raised as a single RAISERROR at severity 16. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE target | Hedge.AccountClosedPositions | Direct DML | Purges closed position snapshot records older than 1 month. See `Hedge.AccountClosedPositions` for OccurredAt column definition. |
| DELETE target | Hedge.AccountStatus | Direct DML | Purges account status snapshot records older than 1 month. |
| DELETE target | Hedge.AccountOpenPositions | Orphaned reference | Table does not exist in DB or SSDT - DELETE always fails silently via TRY/CATCH. |
| DELETE target | Hedge.CustomerClosedPositions | Orphaned reference | Table does not exist in DB or SSDT - DELETE always fails silently via TRY/CATCH. |
| DELETE target | Hedge.CustomerOpenPositions | Orphaned reference | Table does not exist in DB or SSDT - DELETE always fails silently via TRY/CATCH. |

### 5.2 Referenced By (other objects point to this)

No application code callers detected. Procedure is referenced only in `PROD_BIadmins.sql` as a VIEW DEFINITION permission grant. Likely invoked by a SQL Server Agent job on a scheduled basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DeleteRecordsFromHedgingTables (procedure)
├── Hedge.AccountClosedPositions (table) - active target
├── Hedge.AccountStatus (table) - active target
├── Hedge.AccountOpenPositions (table) - ORPHANED: does not exist
├── Hedge.CustomerClosedPositions (table) - ORPHANED: does not exist
└── Hedge.CustomerOpenPositions (table) - ORPHANED: does not exist
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountClosedPositions | Table | DELETE WHERE OccurredAt < 1 month ago (active) |
| Hedge.AccountStatus | Table | DELETE WHERE OccurredAt < 1 month ago (active) |
| Hedge.AccountOpenPositions | Table | DELETE target - table does not exist (orphaned reference) |
| Hedge.CustomerClosedPositions | Table | DELETE target - table does not exist (orphaned reference) |
| Hedge.CustomerOpenPositions | Table | DELETE target - table does not exist (orphaned reference) |

### 6.2 Objects That Depend On This

No dependents found. This procedure is a leaf maintenance operation.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Retention window | Business Rule | Hard-coded 1-month retention: `DATEADD(month,-1, DATEADD(dd,0, DATEDIFF(dd,0, GETUTCDATE())))` - midnight UTC 1 month ago |
| Error isolation | Design Pattern | TRY/CATCH per table ensures all tables are attempted regardless of individual failures |
| Dynamic SQL | Implementation Detail | Uses sp_executesql with parameterized `@DeleteDate` to prevent SQL injection and enable plan reuse |

---

## 8. Sample Queries

### 8.1 Check how many records would be deleted before running

```sql
DECLARE @DeleteDate datetime = DATEADD(month,-1, DATEADD(dd,0, DATEDIFF(dd,0, GETUTCDATE())))

SELECT 'Hedge.AccountClosedPositions' AS TableName, COUNT(*) AS RecordsToDelete
FROM Hedge.AccountClosedPositions WITH (NOLOCK) WHERE OccurredAt < @DeleteDate
UNION ALL
SELECT 'Hedge.AccountStatus', COUNT(*)
FROM Hedge.AccountStatus WITH (NOLOCK) WHERE OccurredAt < @DeleteDate
```

### 8.2 Check the oldest records in each active target table

```sql
SELECT 'AccountClosedPositions' AS TableName, MIN(OccurredAt) AS OldestRecord, MAX(OccurredAt) AS NewestRecord, COUNT(*) AS TotalRecords
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
UNION ALL
SELECT 'AccountStatus', MIN(OccurredAt), MAX(OccurredAt), COUNT(*)
FROM Hedge.AccountStatus WITH (NOLOCK)
```

### 8.3 Verify current retention cutoff date

```sql
SELECT
    GETUTCDATE() AS CurrentUTCTime,
    DATEADD(month,-1, DATEADD(dd,0, DATEDIFF(dd,0, GETUTCDATE()))) AS RetentionCutoff,
    DATEDIFF(day, DATEADD(month,-1, DATEADD(dd,0, DATEDIFF(dd,0, GETUTCDATE()))), GETUTCDATE()) AS RetentionDays
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DeleteRecordsFromHedgingTables | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DeleteRecordsFromHedgingTables.sql*
