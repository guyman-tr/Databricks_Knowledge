# Hedge.DelAccountClosedPositions

> Rolling 30-day retention enforcer for Hedge.AccountClosedPositions: batch-deletes records older than 30 days in 50,000-row chunks using a GOTO loop until no rows remain.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch DELETE Hedge.AccountClosedPositions WHERE OccurredAt < getdate()-30 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.DelAccountClosedPositions` enforces the 30-day rolling retention policy on `Hedge.AccountClosedPositions`, the broker-side closed position log table. As new closed positions accumulate daily, this procedure prunes data older than 30 days, keeping the table focused on the recent rolling window needed for operational reporting and reconciliation.

This is one of five Del* procedures in the Hedge schema that implement identical retention logic for five different rolling tables:

| Procedure | Target Table |
|-----------|-------------|
| Hedge.DelAccountClosedPositions | Hedge.AccountClosedPositions |
| Hedge.DelAccountOpenPositions | Hedge.AccountOpenPositions |
| Hedge.DelAccountStatus | Hedge.AccountStatus |
| Hedge.DelCustomerClosedPositions | Hedge.CustomerClosedPositions |
| Hedge.DelCustomerOpenPositions | Hedge.CustomerOpenPositions |

All five use the same batch-delete GOTO pattern to avoid long-running single DELETE operations that would generate excessive transaction log activity and hold locks. By capping each batch at 50,000 rows, the procedure yields periodically, allowing other transactions to proceed.

The procedure is typically scheduled to run during off-peak hours to minimize interference with inbound position writes.

---

## 2. Business Logic

### 2.1 30-Day Rolling Retention Cutoff

**What**: Computes the cutoff date once at procedure start; all deletes use this fixed boundary.

**Columns/Parameters Involved**: `@DelFromDate`, `OccurredAt`

**Rules**:
- `@DelFromDate = getdate() - 30` (exactly 30 days ago from local server time, not UTC)
- All rows WHERE `OccurredAt < @DelFromDate` are eligible for deletion
- Cutoff is computed once - rows inserted during procedure execution are not affected
- `OccurredAt` is the timestamp column used as the retention boundary

### 2.2 Batch-Delete Loop (50,000 Rows Per Iteration)

**What**: Deletes at most 50,000 rows per iteration, looping until no more eligible rows remain.

**Rules**:
- `SET ROWCOUNT 50000` - caps each DELETE to 50,000 rows
- `delete_more:` label marks the GOTO target
- `DELETE WHERE OccurredAt < @DelFromDate` - no secondary filter
- `IF @@ROWCOUNT > 0 GOTO delete_more` - loop continues while rows were deleted
- `SET ROWCOUNT 0` - resets the row cap after completion (cleanup)
- Each 50,000-row batch auto-commits (no explicit transaction)

**Diagram**:
```
Hedge.DelAccountClosedPositions
      |
      @DelFromDate = getdate() - 30
      SET ROWCOUNT 50000
      |
      delete_more:
          DELETE Hedge.AccountClosedPositions WHERE OccurredAt < @DelFromDate
          IF @@ROWCOUNT > 0 -> GOTO delete_more
      |
      SET ROWCOUNT 0
      |
      Done - all rows older than 30 days removed
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters - the 30-day retention window is hardcoded.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (deletes from) | Hedge.AccountClosedPositions | DELETE | Rolling retention target - removes rows older than 30 days |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a scheduled SQL Agent job for periodic retention enforcement.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DelAccountClosedPositions (procedure)
+-- Hedge.AccountClosedPositions (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountClosedPositions | Table | DELETE rows WHERE OccurredAt < getdate()-30 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent retention job) | External | Scheduled execution to enforce 30-day rolling window |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Uses legacy `SET ROWCOUNT` syntax (deprecated in newer SQL Server versions; `TOP` in DELETE is the modern equivalent)
- No SET NOCOUNT ON - each DELETE iteration emits row count
- No TRY/CATCH - errors propagate and stop the loop
- No explicit transaction - each batch auto-commits, preventing full rollback if interrupted mid-run
- `getdate()` (not GETUTCDATE()) - cutoff is based on local server time; ensure consistent timezone usage
- If OccurredAt index does not exist, each DELETE iteration performs a full scan

---

## 8. Sample Queries

### 8.1 Execute: Run retention cleanup

```sql
EXEC Hedge.DelAccountClosedPositions
```

### 8.2 Preview: How many rows would be deleted?

```sql
DECLARE @DelFromDate DATETIME = GETDATE() - 30
SELECT COUNT(*) AS RowsToDelete FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt < @DelFromDate
```

### 8.3 Monitor: Check oldest remaining row after cleanup

```sql
SELECT MIN(OccurredAt) AS OldestRow, MAX(OccurredAt) AS NewestRow, COUNT(*) AS TotalRows
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DelAccountClosedPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DelAccountClosedPositions.sql*
