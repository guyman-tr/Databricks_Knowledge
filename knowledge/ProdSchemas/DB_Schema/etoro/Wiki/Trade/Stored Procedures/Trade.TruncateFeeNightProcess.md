# Trade.TruncateFeeNightProcess

> Nightly maintenance procedure that truncates Trade.FeeNightProcess and deletes processed (Status=1) records from dbo.FeeQueueInMem. Runs WITH EXECUTE AS Owner for elevated permissions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - nightly fee processing cleanup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the nightly fee calculation process. It cleans up two tables used in fee processing:

1. **Trade.FeeNightProcess**: A staging/work table used during nightly fee calculations (e.g., rollover fees, overnight fees). TRUNCATE removes all rows, resetting it for the next night's run.
2. **dbo.FeeQueueInMem**: An in-memory fee queue. Deletes only rows with `Status = 1` (processed/completed), preserving any pending (unprocessed) fees.

The `WITH EXECUTE AS Owner` clause means the procedure runs under the database owner's permissions rather than the caller's, allowing truncation even if the caller has limited rights.

This procedure is typically called at the start or end of a nightly fee batch job to ensure a clean state before or after processing.

---

## 2. Business Logic

```sql
TRUNCATE TABLE Trade.FeeNightProcess;
DELETE dbo.FeeQueueInMem WHERE Status = 1;
```

- **TRUNCATE** (not DELETE) on FeeNightProcess: full reset, minimal logging, faster than row-by-row
- **DELETE WHERE Status=1**: selective cleanup of FeeQueueInMem - only removes completed queue entries, leaving any unprocessed entries intact

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

No parameters.

### Output

No result sets returned. Side effects: Trade.FeeNightProcess truncated; dbo.FeeQueueInMem Status=1 rows deleted.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all rows) | Trade.FeeNightProcess | WRITE (TRUNCATE) | Fee processing staging table reset entirely each run. |
| Status | dbo.FeeQueueInMem | WRITE (DELETE) | In-memory fee queue; removes completed entries (Status=1) only. |

### 5.2 Referenced By

Not analyzed. Called by the nightly fee calculation batch job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TruncateFeeNightProcess (procedure)
+-- Trade.FeeNightProcess (table) - TRUNCATED
+-- dbo.FeeQueueInMem (table) - Status=1 rows DELETED
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeNightProcess | Table | Truncated entirely each run to reset fee processing staging. |
| dbo.FeeQueueInMem | Table | Completed queue entries (Status=1) deleted. |

### 6.2 Objects That Depend On This

Not analyzed. Upstream caller is the nightly fee batch.

---

## 7. Technical Details

### 7.1 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS Owner | Security | Elevated permissions allow truncation regardless of caller rights. Caller must have EXECUTE permission on this procedure. |
| Status=1 filter | Business Rule | FeeQueueInMem Status=1 = processed. Unprocessed entries (Status != 1) are preserved. |
| TRUNCATE vs DELETE | Performance | TRUNCATE on FeeNightProcess is non-logged (minimal log impact) and resets identity if applicable. Cannot be used with filtered cleanup, so entire table is reset. |

---

## 8. Sample Queries

### 8.1 Check table sizes before running

```sql
SELECT 'FeeNightProcess' AS TableName, COUNT(*) AS RowCount FROM Trade.FeeNightProcess WITH (NOLOCK)
UNION ALL
SELECT 'FeeQueueInMem_Status1', COUNT(*) FROM dbo.FeeQueueInMem WITH (NOLOCK) WHERE Status = 1
```

### 8.2 Execute the cleanup

```sql
EXEC Trade.TruncateFeeNightProcess
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TruncateFeeNightProcess | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TruncateFeeNightProcess.sql*
