# Trade.PositionsReopen

> Batch reopen orchestrator that iterates over all positions in a Trade.PositionToReopen queue for a given ReopenOperationID, calls Trade.PositionReopen for each one (with per-position error suppression), marks the operation as executed, and sends an email result summary.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReopenOperationID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionsReopen is the batch orchestrator for the position reopen workflow. It is the entry point for operations that need to reopen a set of positions (e.g., GSL misalignment corrections, mirror repair operations). Given a ReopenOperationID, it fetches all positions queued in Trade.PositionToReopen (joined to Trade.ReopenOperation for ordering), then calls Trade.PositionReopen for each one serially via a CURSOR.

Key design decisions:
1. **CURSOR with per-position error isolation**: Each Trade.PositionReopen call is wrapped in TRY/CATCH. A failure on one position does not stop the batch - the next position proceeds. This ensures partial success is possible for large reopen operations.
2. **LevelID-ordered processing**: Positions are processed in ascending LevelID order (then by ClosedPositionID). LevelID represents the hierarchy depth - parent positions must be reopened before their children (mirrors reopen after their originating positions).
3. **Operation completion signaling**: After all positions are processed, Trade.ReopenOperation.IsExecuted is set to 1 and Trade.ReopenOperationSendResult is called to email the results summary.

This SP is the thin orchestration wrapper over Trade.PositionReopen (documented separately). All the actual position-level logic (P&L refund, new position creation, mirror/manual path branching) lives in Trade.PositionReopen.

---

## 2. Business Logic

### 2.1 Position Queue Read (CURSOR)

**What**: Fetches all positions for the given ReopenOperationID in processing order.

**Rules**:
- SELECT ClosedPositionID, CID, ValidateUserBalance, RequestedStopRate, RequestedLimitRate, CompensateOnStopLossDelta
- FROM Trade.PositionToReopen ptr JOIN Trade.ReopenOperation tro ON ptr.ReopenOperationID = tro.ReopenOperationID
- WHERE ptr.ReopenOperationID = @ReopenOperationID
- ORDER BY LevelID ASC, ClosedPositionID ASC
- CURSOR type: LOCAL (not global - lifecycle scoped to this SP execution)
- Ordering ensures parent positions are reopened before dependent/child positions

### 2.2 Per-Position Reopen Loop

**What**: Calls Trade.PositionReopen for each position with error isolation.

**Rules**:
- WHILE @@FETCH_STATUS = 0: iterate CURSOR rows
- For each row: EXEC Trade.PositionReopen with @ReopenOperationID, @CID, @ClosedPositionID, @ValidateUserBalance, @RequestedStopRate, @RequestedLimitRate, @CompensateOnStopLossDelta
- TRY/CATCH: CATCH block body is empty (comment: "select position data") - errors are silently swallowed
- Silent failure is intentional: the operation result summary (sent via ReopenOperationSendResult) captures per-position outcomes
- FETCH NEXT after each iteration (whether success or failure)

### 2.3 Operation Completion and Email

**What**: Marks the reopen operation as completed and notifies stakeholders.

**Rules**:
- UPDATE Trade.ReopenOperation SET IsExecuted=1 WHERE ReopenOperationID=@ReopenOperationID
- EXEC Trade.ReopenOperationSendResult @ReopenOperationID
- These two steps always execute even if all individual reopens failed (they run after CLOSE/DEALLOCATE cur)
- ReopenOperationSendResult generates and emails a summary of the reopen operation results (added 25-02-2019, FB 53631)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReopenOperationID | INT | NO | - | CODE-BACKED | Identifies the reopen batch. Foreign key to Trade.ReopenOperation and Trade.PositionToReopen. All positions with this ReopenOperationID are processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (CURSOR) | Trade.PositionToReopen | DML read | Queue of positions to reopen for this operation |
| JOIN (CURSOR) | Trade.ReopenOperation | DML read | Operation metadata (join for LevelID ordering) |
| UPDATE | Trade.ReopenOperation | DML write | Marks IsExecuted=1 after all positions processed |
| EXEC (per row) | Trade.PositionReopen | Procedure call | Reopens each individual position (P&L refund + new position creation) |
| EXEC (final) | Trade.ReopenOperationSendResult | Procedure call | Sends email summary of the reopen operation results |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by operations/risk tooling when initiating a batch reopen.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsReopen (procedure)
+-- Trade.PositionToReopen (table) - position queue
+-- Trade.ReopenOperation (table) - operation metadata + IsExecuted update
+-- Trade.PositionReopen (procedure) - single-position reopen logic [#14 in batch]
+-- Trade.ReopenOperationSendResult (procedure) - email result summary
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionToReopen | Table | CURSOR source: ClosedPositionID, CID, ValidateUserBalance, RequestedStopRate, RequestedLimitRate, CompensateOnStopLossDelta, LevelID |
| Trade.ReopenOperation | Table | JOIN for LevelID ordering; UPDATE IsExecuted=1 after completion |
| Trade.PositionReopen | Stored Procedure | Called per-position with all position-specific parameters |
| Trade.ReopenOperationSendResult | Stored Procedure | Sends email result summary for the completed reopen operation |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Empty CATCH block is intentional: per-position failures are silently skipped to allow batch partial success
- LevelID ordering is critical: ensures parent positions (LevelID=0) are reopened before mirror/child positions (LevelID>0) that depend on them
- The CURSOR is LOCAL - prevents namespace collision in nested call scenarios
- IsExecuted=1 is always set regardless of individual position success/failure - the email summary captures the actual per-position results
- Change log (header): created 18/10/2018 (FB 52839), email added 25/02/2019 (FB 53631), BIGINT PositionID 16/11/2021

---

## 8. Sample Queries

### 8.1 Execute a batch reopen operation

```sql
EXEC Trade.PositionsReopen @ReopenOperationID = 42;
```

### 8.2 Check pending reopen operations

```sql
SELECT ro.ReopenOperationID, ro.IsExecuted, COUNT(ptr.ClosedPositionID) AS PositionCount,
       MIN(ptr.LevelID) AS MinLevel, MAX(ptr.LevelID) AS MaxLevel
FROM Trade.ReopenOperation ro WITH (NOLOCK)
JOIN Trade.PositionToReopen ptr WITH (NOLOCK) ON ro.ReopenOperationID = ptr.ReopenOperationID
WHERE ro.IsExecuted = 0
GROUP BY ro.ReopenOperationID, ro.IsExecuted
ORDER BY ro.ReopenOperationID;
```

### 8.3 Verify positions queued for a specific operation

```sql
SELECT ptr.ClosedPositionID, ptr.CID, ptr.LevelID, ptr.ValidateUserBalance,
       ptr.RequestedStopRate, ptr.RequestedLimitRate, ptr.CompensateOnStopLossDelta
FROM Trade.PositionToReopen ptr WITH (NOLOCK)
WHERE ptr.ReopenOperationID = 42
ORDER BY ptr.LevelID ASC, ptr.ClosedPositionID ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsReopen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionsReopen.sql*
