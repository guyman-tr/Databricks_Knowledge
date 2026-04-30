# Trade.ReverseSplit

> Updates stop-loss rates for open leveraged-1 long positions during a reverse stock split, replacing the pre-split StopRate with the post-split adjusted rate using batch-safe TOP(100) loops.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RS Trade.ReverseSplitType (table-valued parameter with per-instrument split data) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A reverse stock split consolidates existing shares at a ratio (e.g., 10:1), which means stock prices rise proportionally. For real stock positions held by eToro customers (Leverage=1, IsBuy=1, StatusID=1 open), the stop-loss rate stored in `Trade.PositionTreeInfo.StopRate` must be adjusted from the pre-split price level to the post-split price level. If not adjusted, the stop-loss would trigger immediately when the price jumps after the split.

This procedure accepts a table-valued parameter containing one row per affected instrument, with the old stop rate (`SlBefore`) and the new adjusted stop rate (`SlAfter`). For each instrument, it updates all matching positions in batches of 100 using a `WHILE 1=1 / TOP(100)` loop pattern, breaking when `@@rowcount = 0`. This prevents single large transactions that could cause blocking or log growth.

Only real stock positions are affected (Leverage=1 ensures these are non-leveraged/real stock positions, IsBuy=1 since reverse splits only affect long holders, StatusID=1 means still open).

---

## 2. Business Logic

### 2.1 Batch Update Pattern

**What**: TOP(100) loop to update stop rates without holding long-running locks.

**Columns/Parameters Involved**: `Trade.PositionTreeInfo.StopRate`, `Trade.PositionTbl.StatusID`, `Trade.PositionTbl.InstrumentID`, `Trade.PositionTbl.IsBuy`, `Trade.PositionTbl.Leverage`

**Rules**:
- Only updates rows where StopRate = @SlBefore (the old pre-split SL level)
- Uses INNER JOIN to PositionTbl via TreeID to filter by position attributes
- Processes 100 rows at a time and loops until no rows remain
- Each instrument is processed sequentially (outer WHILE loop over #Instruments)
- After completing an instrument, sets #Instruments.StatusID=1 (mark as processed)

**Diagram**:
```
For each InstrumentID in @RS:
  WHILE rows remain:
    UPDATE TOP(100) PositionTreeInfo
    SET StopRate = @SlAfter
    WHERE PositionTbl.StatusID=1 (open)
      AND PositionTbl.InstrumentID = @InstrumentID
      AND PositionTbl.IsBuy = 1 (long only)
      AND PositionTbl.Leverage = 1 (real stock)
      AND PositionTreeInfo.StopRate = @SlBefore (old rate)
    IF @@rowcount = 0 -> BREAK
```

### 2.2 Position Targeting Rules

**What**: Defines which positions are eligible for reverse split stop rate adjustment.

**Rules**:
- StatusID=1: only OPEN positions (closed positions keep historical stop rates)
- IsBuy=1: only LONG positions (reverse split affects long holders only)
- Leverage=1: only real (non-leveraged) stock positions - these are actual share ownership
- StopRate = @SlBefore: only positions with the specific pre-split stop rate (not custom SLs)
- The JOIN uses `ABS(TPOS.TreeID%50) = TPTI.PartitionCol` for partition-aligned lookup

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RS | Trade.ReverseSplitType READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the set of instruments to process. Each row specifies InstrumentID, SlBefore (pre-split stop rate to match), and SlAfter (post-split stop rate to set). READONLY prevents modification of the TVP inside the proc. |

**Trade.ReverseSplitType columns (UDT - table type):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | The instrument undergoing the reverse split. |
| 3 | SlBefore | DECIMAL(8,4) | NO | - | CODE-BACKED | The stop-loss rate level to match in PositionTreeInfo.StopRate - the pre-split sentinel value that must be updated. |
| 4 | SlAfter | DECIMAL(8,4) | NO | - | CODE-BACKED | The replacement stop-loss rate after the reverse split - the new sentinel value adjusted for post-split pricing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RS | Trade.ReverseSplitType | UDT | Table-valued parameter type defining the split data structure |
| UPDATE target | Trade.PositionTreeInfo | Modifier | Sets StopRate from pre-split to post-split level |
| JOIN | Trade.PositionTbl | Lookup | Filters to qualifying open long real-stock positions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReverseSplit (procedure)
|- Trade.ReverseSplitType (UDT - table type parameter)
|- Trade.PositionTbl (table - filter source)
|- Trade.PositionTreeInfo (table - update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReverseSplitType | User Defined Type | Table-valued parameter type defining input structure |
| Trade.PositionTbl | Table | JOINed to filter positions by StatusID, InstrumentID, IsBuy, Leverage |
| Trade.PositionTreeInfo | Table | UPDATE target - StopRate is set from SlBefore to SlAfter |

### 6.2 Objects That Depend On This

No dependents found - called ad-hoc during corporate action processing.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Batch size | Logic | TOP(100) per iteration - limits lock duration and transaction log growth |
| Partition join | Logic | ABS(TreeID%50) = PartitionCol - partition-aligned join for PositionTreeInfo |

---

## 8. Sample Queries

### 8.1 Execute a reverse split stop rate update

```sql
DECLARE @SplitData Trade.ReverseSplitType
INSERT INTO @SplitData (InstrumentID, SlBefore, SlAfter)
VALUES (1234, 0.0100, 0.1000)  -- 10:1 reverse split example

EXEC Trade.ReverseSplit @RS = @SplitData
```

### 8.2 Preview which positions would be affected by a reverse split

```sql
SELECT TPOS.PositionID, TPOS.CID, TPOS.InstrumentID, TPTI.StopRate,
    TPOS.Amount, TPOS.IsBuy, TPOS.Leverage
FROM Trade.PositionTbl TPOS WITH (NOLOCK)
INNER JOIN Trade.PositionTreeInfo TPTI WITH (NOLOCK)
    ON TPOS.TreeID = TPTI.TreeID AND ABS(TPOS.TreeID%50) = TPTI.PartitionCol
WHERE TPOS.StatusID = 1
    AND TPOS.InstrumentID = 1234
    AND TPOS.IsBuy = 1
    AND TPOS.Leverage = 1
    AND TPTI.StopRate = 0.0100  -- SlBefore value
```

### 8.3 Verify post-split stop rate update completion

```sql
SELECT COUNT(*) AS RemainingOldRates
FROM Trade.PositionTbl TPOS WITH (NOLOCK)
INNER JOIN Trade.PositionTreeInfo TPTI WITH (NOLOCK)
    ON TPOS.TreeID = TPTI.TreeID AND ABS(TPOS.TreeID%50) = TPTI.PartitionCol
WHERE TPOS.StatusID = 1
    AND TPOS.InstrumentID = 1234
    AND TPOS.IsBuy = 1
    AND TPOS.Leverage = 1
    AND TPTI.StopRate = 0.0100  -- Should be 0 after successful execution
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReverseSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReverseSplit.sql*
