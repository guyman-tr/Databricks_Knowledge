# Trade.DemoTreeToSplitFromReal

> Work queue for demo copy-trade trees that need their limit/stop rates synced from real environment during stock split operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | NtileTreeID, ID, TreePartitionCol, TreeID (composite PK) |
| **Partition** | Yes (PS_splitT on NtileTreeID) |
| **Indexes** | 3 |

---

## 1. Business Meaning

**WHAT**: Trade.DemoTreeToSplitFromReal is a staging table used exclusively during stock-split operations in the **demo** environment. When eToro runs a stock split (e.g., 1:4) on a real instrument, open positions and their copy-trade trees must be adjusted: units are multiplied by the split ratio, and limit/stop/take-profit rates are recalculated. For demo, the tree-level metadata (LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp) must be copied from the **real** database (`dbo.RealPositionTreeInfo`) into `Trade.PositionTreeInfo`. This table queues those tree updates for parallel processing by SQL Agent jobs.

**WHY**: Stock splits require both position-level adjustments and tree-level adjustments. Demo and real environments run in separate databases. The split process in real populates `Trade.PositionToSplitByJob` and splits positions. For demo trees, the system must read tree info from the real DB, then update the demo DB's `Trade.PositionTreeInfo` in parallel. Without this queue, the split process could not coordinate multiple SQL Agent jobs (NtileTreeID 1–3 for parallel work, 4 for retries) or track success/failure per tree.

**HOW**: `Trade.SplitOpenPositions` (when @IsReal=0) truncates this table, selects distinct trees from `History.PositionSplit` × `Trade.PositionToSplitByJob` for the current SplitID, JOINs to `dbo.RealPositionTreeInfo` for limit/stop data, and inserts rows with TreeWasSplit=0. It starts three jobs (`tradonomi - Split DemoTreeToSplitFromReal 1/2/3`) that run `Trade.UpdateTreeFromRealForSplit`. Each job processes trees for its NtileTreeID, updates `Trade.PositionTreeInfo`, and sets TreeWasSplit=1 on success or TreeWasSplit=-1/-2 on error. Failed trees are retried via job 4. On completion, failures are copied to `History.TreeSplitError`, the table is truncated, and the split is marked complete.

---

## 2. Business Logic

### 2.1 Tree Split Status (TreeWasSplit)

**What**: TreeWasSplit indicates the processing state of a queued tree.

**Columns/Parameters Involved**: `TreeWasSplit`

**Rules**:
- 0 = Not yet processed (initial insert)
- 1 = Successfully updated (limit/stop synced to PositionTreeInfo)
- -1 = First failure (error during UpdateTreeFromRealForSplit)
- -2 = Second failure (retry via NtileTreeID=4 job)
- Trees with TreeWasSplit in (0,-1,-2) prevent split completion; failures go to History.TreeSplitError

### 2.2 Parallel Partitioning (NtileTreeID)

**What**: NtileTreeID distributes trees across parallel SQL Agent jobs.

**Columns/Parameters Involved**: `NtileTreeID`, `TreePartitionCol`

**Rules**:
- NtileTreeID = TreePartitionCol % 3 + 1 (values 1, 2, 3) for initial processing
- Failed trees (TreeWasSplit=-1) are reassigned to NtileTreeID=4 for retry
- Jobs: `tradonomi - Split DemoTreeToSplitFromReal 1`, `2`, `3`, and `tradonomi - Split DemoTreeToSplitFromReal with Errors`

### 2.3 Limit/Stop Sync from Real

**What**: LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp are read from `dbo.RealPositionTreeInfo` and written to `Trade.PositionTreeInfo`.

**Columns/Parameters Involved**: `LimitRate`, `StopRate`, `NextThresHold`, `SLManualVer`, `SLManualVerTimestamp`

**Rules**:
- `Trade.UpdateTreeFromRealForSplit` JOINs `History.PositionSplit` to this table on PositionID, then updates PositionTreeInfo for matching TreeID/PartitionCol
- ErrorMessage captures ERROR_MESSAGE() when update fails

---

## 3. Data Overview

| NtileTreeID | ID | TreeID | TreePartitionCol | TreeWasSplit | PositionID | LimitRate | StopRate | Meaning |
|-------------|-----|--------|------------------|--------------|------------|-----------|----------|---------|
| (No rows in current environment) | | | | | | | | This table is populated only during demo stock-split runs; typically empty between splits. |

**Selection criteria**: Table is truncated after each split run. Sample data would show TreeWasSplit=0 initially, then 1 (success) or -1/-2 (failure).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TreeID | bigint | NO | - | CODE-BACKED | Copy-trade tree identifier. FK context: Trade.PositionTreeInfo.TreeID. Used to update limit/stop in PositionTreeInfo during split. |
| 2 | TreePartitionCol | bigint | NO | - | CODE-BACKED | Partition column for tree. Used with TreeID to join to PositionTreeInfo (PartitionCol = TreeID%50). Drives NtileTreeID = TreePartitionCol % 3 + 1. |
| 3 | NtileTreeID | int | NO | - | CODE-BACKED | Parallel partition: 1–3 for initial jobs, 4 for retry. Determines which SQL Agent job processes the row. |
| 4 | TreeWasSplit | int | YES | - | CODE-BACKED | Status: 0=pending, 1=success, -1=first failure, -2=retry failure. UpdateTreeFromRealForSplit sets 1 on success, -1/-2 on error. |
| 5 | ID | int | NO | - | CODE-BACKED | Sequential ID within NtileTreeID. ROW_NUMBER() OVER (PARTITION BY NtileTreeID ORDER BY (SELECT NULL)) on insert. Batch processing uses ID BETWEEN @Minid AND @Minid+@BatchSize-1. |
| 6 | PositionID | bigint | YES | - | CODE-BACKED | Representative position for this tree. Used to JOIN History.PositionSplit to find completed splits. Index cixp on PositionID. |
| 7 | LimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate from real environment. Copied from dbo.RealPositionTreeInfo to Trade.PositionTreeInfo.LimitRate. |
| 8 | StopRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate from real environment. Copied to Trade.PositionTreeInfo.StopRate. |
| 9 | NextThresHold | dbo.dtPrice | YES | - | CODE-BACKED | Next threshold for trailing stop. Copied to Trade.PositionTreeInfo.NextThresHold. |
| 10 | SLManualVer | smallint | YES | - | CODE-BACKED | Manual stop-loss version. Copied to Trade.PositionTreeInfo.SLManualVer. |
| 11 | SLManualVerTimestamp | datetime | YES | - | CODE-BACKED | Timestamp of manual SL change. Copied to Trade.PositionTreeInfo.SLManualVerTimestamp. |
| 12 | SplitID | int | YES | - | CODE-BACKED | History.SplitRatio.ID for the current split. Used to filter History.PositionSplit. |
| 13 | ErrorMessage | varchar(8000) | YES | - | CODE-BACKED | Error message from CATCH block when update fails. Set by UpdateTreeFromRealForSplit; cleared when TreeWasSplit=1. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|------------------|-------------|
| TreeID, TreePartitionCol | Trade.PositionTreeInfo | Implicit | Target for limit/stop updates |
| PositionID | Trade.Position, History.PositionSplit | Implicit | Links to split-completed positions |
| SplitID | History.SplitRatio | Implicit | Current split run |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitOpenPositions | INSERT, TRUNCATE | Writer | Populates and truncates during demo split |
| Trade.UpdateTreeFromRealForSplit | SELECT, UPDATE | Modifier | Processes trees, sets TreeWasSplit and ErrorMessage |
| History.TreeSplitError | INSERT (from SELECT) | Consumer | Failed trees copied here before truncate |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SplitRatio → Trade.PositionToSplitByJob → History.PositionSplit
                                                      ↓
dbo.RealPositionTreeInfo ← Trade.DemoTreeToSplitFromReal → Trade.PositionTreeInfo
                                                      ↓
                                              History.TreeSplitError
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | SplitID, IsCompletedOpenPositions |
| Trade.PositionToSplitByJob | Table | Source of trees for current split |
| History.PositionSplit | Table | JOIN to find split positions |
| dbo.RealPositionTreeInfo | Table | Source of LimitRate, StopRate, etc. (real DB) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SplitOpenPositions | Procedure | INSERT, TRUNCATE, validation |
| Trade.UpdateTreeFromRealForSplit | Procedure | SELECT, UPDATE |
| History.TreeSplitError | Table | INSERT from failed rows |
| SQL Agent jobs (tradonomi - Split DemoTreeToSplitFromReal 1/2/3, with Errors) | Job | Invoke UpdateTreeFromRealForSplit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|------------------|--------|--------|
| PK_DemoTreeToSplitFromReal | CLUSTERED | NtileTreeID, ID, TreePartitionCol, TreeID | - | - | Active |
| cix | NC | TreeID | - | - | Active |
| cixp | NC | PositionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DemoTreeToSplitFromReal | PRIMARY KEY | (NtileTreeID, ID, TreePartitionCol, TreeID) |
| PS_splitT | Partition Scheme | Partitions on NtileTreeID |

---

## 8. Sample Queries

### 8.1 Pending trees by partition
```sql
SELECT NtileTreeID, COUNT(*) AS PendingCount
  FROM Trade.DemoTreeToSplitFromReal WITH (NOLOCK)
 WHERE TreeWasSplit = 0
 GROUP BY NtileTreeID
 ORDER BY NtileTreeID
```

### 8.2 Failed trees with error messages
```sql
SELECT TreeID, NtileTreeID, PositionID, TreeWasSplit, ErrorMessage, SplitID
  FROM Trade.DemoTreeToSplitFromReal WITH (NOLOCK)
 WHERE TreeWasSplit IN (-1, -2)
 ORDER BY NtileTreeID, ID
```

### 8.3 Trees processed successfully in current run
```sql
SELECT TreeID, TreePartitionCol, NtileTreeID, PositionID, LimitRate, StopRate
  FROM Trade.DemoTreeToSplitFromReal WITH (NOLOCK)
 WHERE TreeWasSplit = 1
 ORDER BY NtileTreeID, ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Object: Trade.DemoTreeToSplitFromReal | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.DemoTreeToSplitFromReal.sql*
