# Trade.BulkUpdatePositionTreeInfo

> Bulk-processes queued Trailing Stop Loss (TSL) updates from Trade.SyncTSL and propagates validated stop-loss and threshold changes into Trade.PositionTreeInfo.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous batch processor |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.BulkUpdatePositionTreeInfo is the batch consumer of the Trailing Stop Loss (TSL) synchronization queue. When TSL is active on a position and the market moves favorably, the TSL engine writes new stop-loss levels into Trade.SyncTSL. This procedure reads those queued rows and applies the validated updates to Trade.PositionTreeInfo, which is the single source of truth for SL/TP/TSL settings across all positions in a copy-trade tree.

This procedure exists because TSL updates arrive at high frequency and must be batched for performance. Directly updating PositionTreeInfo row-by-row would cause excessive lock contention on the partitioned table. Instead, SyncTSL acts as a write-ahead queue, and this procedure consumes up to 3,333 rows per invocation, applies deduplication and conflict resolution, and writes only the winning update per position.

The procedure runs continuously in a SQL Agent job loop (`EXEC Trade.BulkUpdatePositionTreeInfo; WAITFOR DELAY '00:00:02'`). It reads Status=0 (New) and Status=1 (In-Progress) rows from Trade.SyncTSL, filters out stale entries using SLManualVer (manual override version) and directional validation (buy positions only trail upward, sell positions only trail downward), then updates StopRate and NextThresHold in PositionTreeInfo. After processing, it marks SyncTSL rows as Status=2 (Processed).

---

## 2. Business Logic

### 2.1 Batch Dequeue with Status Transition

**What**: The procedure uses a two-phase dequeue pattern - first claiming rows, then processing them.

**Columns/Parameters Involved**: `Trade.SyncTSL.Status`, `Trade.SyncTSL.ID`

**Rules**:
- Phase 1: Selects up to 3,333 rows with Status=1 (already claimed in a prior run but not yet processed)
- Phase 2: Claims additional rows (up to remaining capacity) by atomically updating Status from 0 (New) to 1 (Claimed) using an UPDATE with OUTPUT clause
- Total batch size is capped at 3,333 rows per invocation
- The two-phase approach handles crash recovery: Status=1 rows from a failed prior run are re-processed

**Diagram**:
```
SyncTSL Status Flow:
  0 (New) --[BulkUpdate claims]--> 1 (Claimed) --[processed]--> 2 (Processed)
            \                                                     ^
             \--[already claimed from prior run]------------------/
```

### 2.2 SLManualVer Conflict Resolution

**What**: When multiple TSL updates exist for the same position, only the one with the highest manual version is applied.

**Columns/Parameters Involved**: `SLManualVer`, `PositionID`, `#T.Status`

**Rules**:
- For each PositionID, find the MAX(SLManualVer) among queued updates
- Mark all rows with a lower SLManualVer as Status=1 (skipped) in the temp table
- This ensures that if a user manually adjusted their stop-loss after a TSL update was queued, the manual adjustment takes precedence
- The same SLManualVer check is repeated when joining to PositionTreeInfo: `PTI.SLManualVer <= T.SLManualVer`

### 2.3 Directional Validation

**What**: TSL only moves the stop loss in the favorable direction - it never loosens the stop.

**Columns/Parameters Involved**: `IsBuy`, `StopLoss`, `Trade.PositionTreeInfo.StopRate`

**Rules**:
- For BUY positions (IsBuy=1): New StopLoss must be GREATER than current StopRate (trailing upward)
- For SELL positions (IsBuy=0): New StopLoss must be LESS than current StopRate (trailing downward)
- When multiple rows exist for the same position with different StopLoss values, for BUY: keep only the MAX StopLoss; for SELL: keep only the MIN StopLoss
- Updates that would move the stop in the wrong direction are silently discarded

### 2.4 PositionTreeInfo Update with Partition Elimination

**What**: The final UPDATE targets PositionTreeInfo using partition-aligned join conditions.

**Columns/Parameters Involved**: `Trade.PositionTreeInfo.TreeID`, `Trade.PositionTreeInfo.PartitionCol`, `Trade.PositionTreeInfo.IsTslEnabled`

**Rules**:
- JOIN uses `PTI.TreeID = T.PositionID AND PTI.PartitionCol = T.PositionID % 50` for partition elimination on PS_PositionTreeInfo_BIGINT
- Only updates rows where `IsTslEnabled = 1` (TSL must still be active)
- Sets both StopRate (the actual stop level) and NextThresHold (the next trailing trigger point)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It operates autonomously on queued data.

### Temp Table #T

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | BIGINT | NO | - | CODE-BACKED | PK of the Trade.SyncTSL row being processed. Used for final status update back to SyncTSL. |
| 2 | PositionID | BIGINT | NO | - | VERIFIED | The TreeID of the position tree this TSL update applies to. Joins to Trade.PositionTreeInfo.TreeID. Originally INT, changed to BIGINT 17/11/2021. |
| 3 | StopLoss | MONEY | NO | - | VERIFIED | The new trailing stop-loss price. For buy: must be higher than current StopRate. For sell: must be lower. Applied to PositionTreeInfo.StopRate. |
| 4 | SLManualVer | SMALLINT | NO | - | VERIFIED | Stop-loss manual version counter. Higher values indicate more recent manual overrides. Used for conflict resolution: only the highest version per PositionID is applied, and the update is skipped if PositionTreeInfo already has a higher version. |
| 5 | NextThresHold | MONEY | NO | - | CODE-BACKED | The next trailing threshold price level. When market price crosses this threshold, the TSL engine will generate a new SyncTSL row with an adjusted StopLoss. Applied to PositionTreeInfo.NextThresHold. |
| 6 | IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Buy/Long, 0=Sell/Short. Determines the directional validation rule: buy positions trail upward (new StopLoss > current StopRate), sell positions trail downward (new StopLoss < current StopRate). |
| 7 | Status | TINYINT | NO | 0 | VERIFIED | Processing status within the temp table: 0=Active (will be applied to PositionTreeInfo), 1=Skipped (superseded by a newer SLManualVer or non-optimal StopLoss for the direction). Not the same as SyncTSL.Status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads/writes) | Trade.SyncTSL | Queue Source + Status Update | Reads TSL update queue rows (Status=0,1), marks them as processed (Status=2) after applying |
| (writes) | Trade.PositionTreeInfo | Target Table | Updates StopRate and NextThresHold for positions with active TSL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | (external) | Caller | Called in an infinite loop with 2-second delay between executions |
| PROD_BIadmins | (permission) | EXECUTE grant | BIadmins role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.BulkUpdatePositionTreeInfo (procedure)
+-- Trade.SyncTSL (table)
+-- Trade.PositionTreeInfo (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncTSL | Table | SELECT (dequeue), UPDATE Status |
| Trade.PositionTreeInfo | Table | UPDATE StopRate, NextThresHold |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job | External | Calls in continuous loop with 2-second delay |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error Handling | Re-throws any error encountered during processing; the outer job loop continues after 2 seconds |

---

## 8. Sample Queries

### 8.1 Check pending TSL updates in the queue

```sql
SELECT Status, COUNT(*) AS Cnt
FROM   Trade.SyncTSL WITH (NOLOCK)
GROUP BY Status
ORDER BY Status;
```

### 8.2 View current TSL settings for a specific position tree

```sql
SELECT PTI.TreeID,
       PTI.StopRate,
       PTI.NextThresHold,
       PTI.IsTslEnabled,
       PTI.SLManualVer
FROM   Trade.PositionTreeInfo PTI WITH (NOLOCK)
WHERE  PTI.TreeID = @TreeID
       AND PTI.PartitionCol = ABS(@TreeID) % 50;
```

### 8.3 Find queued TSL updates for a specific position

```sql
SELECT S.ID,
       S.PositionID,
       S.StopLoss,
       S.SLManualVer,
       S.NextThresHold,
       S.IsBuy,
       S.Status
FROM   Trade.SyncTSL S WITH (NOLOCK)
WHERE  S.PositionID = @PositionID
       AND S.Status IN (0, 1)
ORDER BY S.ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The procedure's change history comment references TRAD-4315 (31/03/2021) which added directional and IsTslEnabled validation conditions to the PositionTreeInfo update.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 6.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BulkUpdatePositionTreeInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.BulkUpdatePositionTreeInfo.sql*
