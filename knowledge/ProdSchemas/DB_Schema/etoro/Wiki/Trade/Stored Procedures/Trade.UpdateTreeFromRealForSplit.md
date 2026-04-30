# Trade.UpdateTreeFromRealForSplit

> Propagates stock split rate adjustments from real-account positions to demo copy trees, processing in batches of 3000 for a given parallel partition ID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParallelID INT; modifies Trade.PositionTreeInfo, Trade.DemoTreeToSplitFromReal |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a stock split occurs for real-account positions, the rate data stored in demo copy trees (Trade.PositionTreeInfo) must be updated to reflect the post-split prices. A stock split changes the price per share, which means all derived rate fields - stop loss rates, take profit rates, threshold levels, and manual SL versions - that were set relative to the pre-split price must be recalculated and written to the tree.

This procedure handles that propagation for a single parallel partition. The work is divided across multiple parallel workers (identified by NtileTreeID), with each worker calling this procedure with its assigned @ParallelID. This allows the potentially large number of affected demo trees to be processed concurrently across parallel SQL jobs.

The procedure reads from Trade.DemoTreeToSplitFromReal which acts as a work queue: it holds the trees that need to be updated for the current split, pre-partitioned into NtileTreeID buckets. The source split data (new rates) comes from History.PositionSplit. After processing each batch, the DemoTreeToSplitFromReal row is marked with TreeWasSplit=1 (success) or -1/-2 (error), providing a persistent audit trail of which trees were updated and which failed.

---

## 2. Business Logic

### 2.1 Work Queue Loading and Early Exit

**What**: Identifies the current split and loads only the trees assigned to this parallel worker.

**Columns/Parameters Involved**: `@SplitID`, `@ParallelID`, `NtileTreeID`, `Trade.DemoTreeToSplitFromReal`, `History.PositionSplit`

**Rules**:
- @SplitID is derived as TOP 1 SplitID from Trade.DemoTreeToSplitFromReal (assumes a single active split at a time)
- Only rows matching BOTH SplitID = @SplitID AND NtileTreeID = @ParallelID are loaded
- The JOIN to History.PositionSplit on PositionID filters to positions that actually have split data
- DISTINCT prevents duplicate tree updates if a tree has multiple matching positions
- If no rows match (@@ROWCOUNT = 0) -> RETURN 1 immediately (no work for this partition)

**Diagram**:
```
Trade.DemoTreeToSplitFromReal + History.PositionSplit
        |
        WHERE SplitID = @SplitID AND NtileTreeID = @ParallelID
        |
        @@ROWCOUNT = 0? -> RETURN 1 (nothing to do)
        |
        -> #TreesToUpdate (with CIX on ID)
```

### 2.2 Batch Processing Loop

**What**: Updates are applied in batches of 3000 rows to avoid locking and transaction log pressure.

**Columns/Parameters Involved**: `@BatchSize = 3000`, `@Minid`, `@Maxid`, `TreeID`, `PartitionCol`

**Rules**:
- Clustered index on #TreesToUpdate.ID for efficient batch range access
- Each batch: UPDATE Trade.PositionTreeInfo (LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp) matched by TreeID + PartitionCol (composite key)
- Then UPDATE Trade.DemoTreeToSplitFromReal SET TreeWasSplit=1 for completed rows
- Each batch is its own transaction - a failed batch does not roll back completed batches
- @Minid advances by @BatchSize after each iteration (whether success or failure)

**Diagram**:
```
WHILE @Minid <= @Maxid:
  BEGIN TRAN
    UPDATE PositionTreeInfo (LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp)
      WHERE ID BETWEEN @Minid AND @Minid+2999
    UPDATE DemoTreeToSplitFromReal SET TreeWasSplit=1
      WHERE ID BETWEEN @Minid AND @Minid+2999 AND NtileTreeID = @ParallelID
  COMMIT
  @Minid += 3000
```

### 2.3 Per-Batch Error Handling and @ParallelID=4 Special Code

**What**: Each batch failure is caught, logged, and marked with a special error code - with @ParallelID=4 receiving a distinct error code (-2) to distinguish it from other workers.

**Columns/Parameters Involved**: `@ErrorMessge`, `@TreeWasSplit`, `TreeWasSplit`, `ErrorMessage`, `@ParallelID`

**Rules**:
- On CATCH: ROLLBACK, capture ERROR_MESSAGE() into ErrorMessage column
- TreeWasSplit = -2 if @ParallelID = 4; -1 for all other parallel IDs
- Execution CONTINUES to next batch even after failure - partial success is possible within a parallel worker
- The -2 code for @ParallelID=4 suggests a convention where a specific monitoring/alerting process distinguishes this partition's failures

**Diagram**:
```
CATCH:
  ROLLBACK
  @TreeWasSplit = CASE WHEN @ParallelID = 4 THEN -2 ELSE -1 END
  UPDATE DemoTreeToSplitFromReal SET TreeWasSplit = @TreeWasSplit, ErrorMessage = @ErrorMessge
  @Minid += 3000  -- continue to next batch
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParallelID | INT | NO | - | CODE-BACKED | Parallel worker partition identifier. Matched against NtileTreeID in Trade.DemoTreeToSplitFromReal to load only this worker's slice of trees. Typical values 1-N (number of parallel workers). Special case: @ParallelID=4 causes error code -2 instead of -1 in DemoTreeToSplitFromReal.TreeWasSplit on failure, enabling distinct monitoring of that partition. |

**Return values:**
- RETURN 1: No trees found for this @ParallelID / SplitID combination (nothing to do - normal early exit)
- Implicit RETURN 0: Processing completed (some or all batches may have failed; check TreeWasSplit values in DemoTreeToSplitFromReal)

**Internal variables and temp tables (not parameters but documented for completeness):**

| # | Element | Type | Description |
|---|---------|------|-------------|
| - | @SplitID | INT | The current stock split ID. Derived as TOP 1 from Trade.DemoTreeToSplitFromReal. Assumes only one active split is queued at a time. |
| - | #TreesToUpdate | Temp Table | Holds the distinct set of tree rows to update for this @ParallelID. Columns mirror Trade.DemoTreeToSplitFromReal. CIX on ID enables batch range scans. |
| - | @BatchSize | INT | Fixed at 3000. Number of rows processed per transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Work queue source | Trade.DemoTreeToSplitFromReal | Reader + Updater | Reads the queued trees to update (filtered by NtileTreeID); writes back TreeWasSplit and ErrorMessage after each batch |
| Split rate source | History.PositionSplit | Reader | Joined on PositionID to confirm the split exists and to filter which DemoTreeToSplitFromReal rows belong to the active SplitID |
| UPDATE target | Trade.PositionTreeInfo | Modifier | Receives updated rate fields (LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp) matched by TreeID + PartitionCol |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Stock split job / parallel SQL Agent jobs | EXECUTE | Caller | Called by parallel SQL Agent jobs after a stock split is processed on real accounts; each job passes a different @ParallelID value |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateTreeFromRealForSplit (procedure)
├── Trade.DemoTreeToSplitFromReal (table - work queue, read + updated)
├── History.PositionSplit (table - split source, read only)
└── Trade.PositionTreeInfo (table - rate data target, updated)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DemoTreeToSplitFromReal | Table | Work queue - supplies trees to update (NtileTreeID partitioned); receives TreeWasSplit status and ErrorMessage after processing |
| History.PositionSplit | Table | Cross-schema - JOIN on PositionID to verify split association and filter rows for the current @SplitID |
| Trade.PositionTreeInfo | Table | UPDATE target - LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp updated post-split |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Stock split parallel job infrastructure | External process | Calls this procedure with different @ParallelID values for parallel processing of the split propagation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Batch isolation | Design | Each batch of 3000 is its own transaction - a single batch failure does not roll back previous batches. Partial progress is possible and visible via TreeWasSplit values. |
| NtileTreeID partitioning | Design | Only rows with NtileTreeID = @ParallelID are processed. Multiple callers with different @ParallelID values can run concurrently without row-level conflict. |
| TOP 1 SplitID assumption | Business logic | Assumes only one active split is in the work queue at a time. If multiple splits are queued simultaneously, all parallel workers would process the same (first) SplitID. |
| Composite key match | Business logic | Trade.PositionTreeInfo is updated on TreeID + PartitionCol - both columns required for the correct row. PartitionCol drives physical partitioning of the table. |

---

## 8. Sample Queries

### 8.1 Check the current state of the demo tree split work queue

```sql
SELECT
    SplitID,
    NtileTreeID,
    COUNT(*) AS TotalTrees,
    SUM(CASE WHEN TreeWasSplit = 1 THEN 1 ELSE 0 END) AS Completed,
    SUM(CASE WHEN TreeWasSplit = -1 THEN 1 ELSE 0 END) AS FailedWorker,
    SUM(CASE WHEN TreeWasSplit = -2 THEN 1 ELSE 0 END) AS FailedWorker4,
    SUM(CASE WHEN TreeWasSplit IS NULL OR TreeWasSplit = 0 THEN 1 ELSE 0 END) AS Pending
FROM Trade.DemoTreeToSplitFromReal WITH (NOLOCK)
GROUP BY SplitID, NtileTreeID
ORDER BY SplitID, NtileTreeID
```

### 8.2 Find trees that failed during a split with their error messages

```sql
SELECT TOP 100
    ID,
    SplitID,
    NtileTreeID,
    PositionID,
    TreeID,
    TreeWasSplit,
    ErrorMessage
FROM Trade.DemoTreeToSplitFromReal WITH (NOLOCK)
WHERE TreeWasSplit IN (-1, -2)
ORDER BY SplitID DESC, ID
```

### 8.3 Verify split rates were applied to PositionTreeInfo

```sql
-- Check PositionTreeInfo for a specific tree after split
SELECT
    TreeID,
    PartitionCol,
    LimitRate,
    StopRate,
    NextThresHold,
    SLManualVer,
    SLManualVerTimestamp
FROM Trade.PositionTreeInfo WITH (NOLOCK)
WHERE TreeID = 12345  -- replace with actual TreeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateTreeFromRealForSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateTreeFromRealForSplit.sql*
