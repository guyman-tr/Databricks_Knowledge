# Trade.TradeOrphanedPositionsCloseByJob

> Job queue table for closing orphaned copy-trade positions that lost their parent in the copy-trade tree. A background job detects orphans, queues them here, and processes closes in parallel using modulo-based partitioning.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CIX_Position_ExecuteStatus (clustered on PositionID, ExecuteStatus) - no PK |
| **Partition** | No |
| **Indexes** | 3 active (1 clustered, 2 nonclustered) |

---

## 1. Business Meaning

Trade.TradeOrphanedPositionsCloseByJob is a job queue table that holds copy-trade positions that have become "orphaned" - their parent position in the copy-trade tree was closed (e.g., leader closed the position) but the child positions remain open. In the normal copy-trade flow, when a leader closes a position, the system propagates the close to all followers' mirrored positions. Sometimes propagation fails, leaves are detached, or the tree becomes inconsistent, leaving positions without a valid parent. These orphans must be closed to prevent customers from holding positions that no longer mirror any leader.

This table exists because orphan detection and closure cannot happen inline with every position close - it requires a periodic sweep by a background job. The job identifies orphaned positions, inserts them into this queue with a close command (Cmd), and processes them in batches. The ModoloID column (typo of ModuloID) enables parallel processing: multiple job workers partition work by modulo bucket so each worker processes a subset of rows without contention.

Data flows: The orphan detection logic (e.g., Trade.CloseOrphanedPositions, Trade.AlertForOrphanedPositions) identifies positions whose parent no longer exists or is closed, INSERTs rows with ExecuteStatus NULL or 0 (Pending). A job worker UPDATEs ExecuteStatus to 1 (Executing), performs the close, then UPDATEs to 2 (Completed) or -1 (Failed with FailReason). Live data is currently EMPTY - the table is consumed and cleared after processing.

---

## 2. Business Logic

### 2.1 ExecuteStatus Lifecycle: Pending -> Executing -> Completed/Failed

**What**: Each queued orphan progresses through execution states until the close is applied or fails.

**Columns/Parameters Involved**: `ExecuteStatus`, `ExecuteDate`, `FailReason`, `Cmd`, `PositionID`

**Rules**:
- NULL or 0 = Pending: Row queued, awaiting pickup by job worker
- 1 = Executing: Job worker has claimed the row, close in progress
- 2 = Completed: Close succeeded, row can be cleared or archived
- -1 = Failed: Close failed. FailReason populated with error message. May be retried or alerted

**Diagram**:
```
[Orphan Detection] -> INSERT (ExecuteStatus=NULL/0)
        |
        v
  [Pending - queued]
        |
        v
[Job Worker] -> UPDATE ExecuteStatus=1
        |
        v
  [Executing - close in progress]
        |
   +-----+-----+
   |           |
   v           v
[Success]   [Failure]
   |           |
   v           v
UPDATE=2    UPDATE=-1
ExecuteDate  FailReason
```

### 2.2 ModoloID Parallel Processing

**What**: Modulo bucket enables multiple job workers to partition the queue without locking.

**Columns/Parameters Involved**: `ModoloID`, `ExecuteStatus`, `PositionID`

**Rules**:
- ModoloID = modulo bucket (e.g., PositionID % N). Typo of "ModuloID"
- Workers filter by ModoloID = @WorkerBucket AND ExecuteStatus IN (NULL, 0) to claim only their slice
- Index ix_ModoloID on (ModoloID, ExecuteStatus) supports this partitioning
- Prevents multiple workers from processing the same row

---

## 3. Data Overview

| PositionID | ParentPositionID | EntryDate | Cmd | ExecuteStatus | ExecuteDate | FailReason | ModoloID | Meaning |
|------------|------------------|------------|-----|---------------|-------------|------------|----------|---------|
| (empty) | - | - | - | - | - | - | - | Table is EMPTY in live environment. Rows are inserted by orphan detection, processed by the job, and cleared. Representative state: PositionID/ParentPositionID identify the orphan; Cmd holds close command; ExecuteStatus cycles Pending->Executing->Completed/Failed. |

**Selection criteria**: Table has no rows in production. The Data Overview reflects the intended use: orphan positions queued for close, with status tracking. For auditing or reprocessing, rows would show various ExecuteStatus values across different ModoloID buckets.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | YES | - | CODE-BACKED | The orphaned position to close. References Trade.PositionTbl.PositionID. The position that lost its parent in the copy-trade tree. |
| 2 | ParentPositionID | bigint | YES | - | CODE-BACKED | The parent position reference. Used by orphan detection to identify which parent was closed or missing. References Trade.PositionTbl.PositionID. |
| 3 | EntryDate | datetime | YES | - | CODE-BACKED | When the orphan was detected and queued. Set at INSERT time. |
| 4 | Cmd | varchar(255) | YES | - | CODE-BACKED | Close command or instruction for the job. Describes the action to perform (e.g., close at market). |
| 5 | ExecuteStatus | int | YES | - | CODE-BACKED | Execution state: NULL/0=Pending, 1=Executing, 2=Completed, -1=Failed. Clustered index key. Indexed for job worker filtering. |
| 6 | ExecuteDate | datetime | YES | - | CODE-BACKED | When the close was executed (or attempted). Set when ExecuteStatus moves to 2 or -1. |
| 7 | FailReason | varchar(max) | YES | - | CODE-BACKED | Error message when ExecuteStatus=-1. Captures why the close failed for alerting and retry. |
| 8 | ModoloID | int | YES | - | CODE-BACKED | Modulo bucket for parallel processing (typo of ModuloID). PositionID % N. Job workers partition by this value. Index ix_ModoloID supports (ModoloID, ExecuteStatus). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | The orphaned position to be closed. |
| ParentPositionID | Trade.PositionTbl | Implicit | The parent position (closed or missing). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CloseOrphanedPositions | INSERT, UPDATE | Writer/Modifier | Detects orphans, queues rows, processes closes. |
| Trade.AlertForOrphanedPositions | INSERT, SELECT | Writer/Reader | Alerts on orphaned positions, may queue for close. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TradeOrphanedPositionsCloseByJob (table)
```

Tables are leaf nodes. No code-level dependencies. PositionID and ParentPositionID reference Trade.PositionTbl conceptually.

### 6.1 Objects This Depends On

No explicit FK targets. Implicit: Trade.PositionTbl (PositionID, ParentPositionID). Uses dbo types only.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseOrphanedPositions | Procedure | INSERTs orphans, UPDATEs status, processes closes |
| Trade.AlertForOrphanedPositions | Procedure | SELECTs/INSERTs orphans, triggers alerts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX_Position_ExecuteStatus | CLUSTERED | PositionID, ExecuteStatus | - | - | Active |
| IX_ExecuteStatus | NC | ExecuteStatus | - | - | Active |
| ix_ModoloID | NC | ModoloID, ExecuteStatus | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | No primary key. Table uses clustered index for access pattern. |

---

## 8. Sample Queries

### 8.1 Pending orphans by ModoloID for a worker
```sql
SELECT PositionID, ParentPositionID, EntryDate, Cmd, ModoloID
  FROM Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
 WHERE ModoloID = @WorkerBucket
   AND (ExecuteStatus IS NULL OR ExecuteStatus = 0)
 ORDER BY EntryDate;
```

### 8.2 Failed orphans with reasons
```sql
SELECT PositionID, ParentPositionID, ExecuteDate, FailReason
  FROM Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
 WHERE ExecuteStatus = -1
 ORDER BY ExecuteDate DESC;
```

### 8.3 Resolve PositionID to instrument for reporting
```sql
SELECT t.PositionID, t.ExecuteStatus, t.FailReason, p.InstrumentID, i.BuyCurrencyID
  FROM Trade.TradeOrphanedPositionsCloseByJob t WITH (NOLOCK)
  LEFT JOIN Trade.PositionTbl p WITH (NOLOCK) ON t.PositionID = p.PositionID
  LEFT JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
 WHERE t.ExecuteStatus IN (2, -1);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TradeOrphanedPositionsCloseByJob | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.TradeOrphanedPositionsCloseByJob.sql*
