# Trade.SetIsNoStopLossIsNoTakeProfitInit

> Performs the initial population of IsNoStopLoss and IsNoTakeProfit flags on Trade.PositionTreeInfo rows that have never been set (both NULL), by scanning root positions within a specified partition range.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromPartition / @ToPartition (partition range of trees to initialize) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure initializes the `IsNoStopLoss` and `IsNoTakeProfit` flags on `Trade.PositionTreeInfo` rows that have never had these values set (i.e., both are NULL). It is the "Init" (initial seed) companion to `Trade.SetIsNoStopLossIsNoTakeProfitDelta`, which handles ongoing corrections and inconsistencies.

The flags indicate whether a copy-trade position tree has no effective stop-loss or take-profit configured. When these values are NULL, the risk monitoring system cannot determine the tree's risk state. This procedure is typically run once after a migration or after a bulk of new trees are created, to bootstrap all NULL rows with their correct initial values.

Compared to the Delta variant, Init is simpler: it only processes trees where BOTH flags are NULL, and it performs a single update type (setting both IsNoStopLoss and IsNoTakeProfit simultaneously, plus resetting IsTslEnabled when IsNoStopLoss becomes 1). The Delta variant handles three update types and handles stale/inconsistent values as well.

Processing uses batches of 1000 rows (by IndexID) within a WHILE loop to avoid lock escalation, and accepts a partition range for parallelization.

---

## 2. Business Logic

### 2.1 IsNoStopLoss and IsNoTakeProfit Calculation Rules

**What**: Determines the initial IsNoStopLoss and IsNoTakeProfit values based on the root position's rates and leverage.

**Columns/Parameters Involved**: `Trade.Position.StopRate`, `Trade.Position.LimitRate`, `Trade.Position.Leverage`, `Trade.ProviderToInstrument.Precision`, `Trade.PositionTreeInfo.IsNoStopLoss`, `Trade.PositionTreeInfo.IsNoTakeProfit`

**Rules**:
- `IsNoStopLoss = 1` when: `StopRate <= 10^(-Precision)` AND `Leverage = 1` (unleveraged position with effectively zero stop rate = no stop loss)
- `IsNoStopLoss = 0` otherwise
- `IsNoTakeProfit = 1` when: `LimitRate = 0` AND `Leverage = 1` (unleveraged position with no take profit rate)
- `IsNoTakeProfit = 0` otherwise
- When `IsNoStopLoss` is being set to 1, `IsTslEnabled` is also forced to 0 (trailing stop-loss is irrelevant without a stop-loss)
- Only processes root positions: `p.TreeID = p.PositionID` (the tree head, not child copy positions)

**Diagram**:
```
Root Position (WHERE p.TreeID = p.PositionID, both flags NULL):
  |
  +-- Precision from ProviderToInstrument
  |
  IsNoStopLoss:
    StopRate <= 10^(-Precision) AND Leverage=1 --> 1
    otherwise                                  --> 0

  IsNoTakeProfit:
    LimitRate = 0 AND Leverage=1               --> 1
    otherwise                                  --> 0

  IsTslEnabled:
    IsNoStopLoss=1 --> 0 (reset; no SL means no TSL)
    IsNoStopLoss=0 --> unchanged (keep existing IsTslEnabled)
```

### 2.2 Batch Processing via IndexID

**What**: Processes updates in chunks of 1000 to minimize locking impact on heavily-used PositionTreeInfo.

**Columns/Parameters Involved**: `IndexID` (computed rownum), `@MinID`, `@MaxID`

**Rules**:
- A temp table `#PositionTreeInfoToUpdate` is created with a clustered index on (IndexID, TreeID, TreePartitionCol)
- The WHILE loop iterates from @MinID to @MaxID in steps of 1000
- Each iteration updates only 1000 rows: `B.IndexID BETWEEN @MinID AND @MinID + 999`
- The `OPTION (RECOMPILE)` hint is used to get optimal plans per batch variable values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromPartition | int | NO | - | CODE-BACKED | Start of the partition range to initialize. Filters Trade.Position.TreePartitionCol BETWEEN @FromPartition AND @ToPartition. Used to parallelize the initialization across partition bands. |
| 2 | @ToPartition | int | NO | - | CODE-BACKED | End of the partition range to initialize. Combined with @FromPartition defines the work slice. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TreeID / TreePartitionCol | Trade.PositionTreeInfo | Modifier | Sets IsNoStopLoss, IsNoTakeProfit, IsTslEnabled for trees where both flags are NULL |
| TreeID / PositionID | Trade.Position | Reader | Reads root position (TreeID = PositionID) rates: StopRate, LimitRate, Leverage |
| InstrumentID | Trade.ProviderToInstrument | Reader | Reads Precision to compute minimum pip threshold for IsNoStopLoss calculation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetIsNoStopLossIsNoTakeProfitInit (procedure)
├── Trade.Position (view) [reads root positions in partition range]
├── Trade.ProviderToInstrument (table) [reads Precision per InstrumentID]
└── Trade.PositionTreeInfo (table) [sets NULL flags to calculated values]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Reads root positions (TreeID = PositionID) to calculate IsNoStopLoss and IsNoTakeProfit values |
| Trade.ProviderToInstrument | Table | Reads Precision for each InstrumentID to compute the minimum pip threshold |
| Trade.PositionTreeInfo | Table | Updated with initial IsNoStopLoss, IsNoTakeProfit, IsTslEnabled values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Typically run as a one-time maintenance or migration script |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL-only filter | Business rule | Only processes trees where BOTH IsNoStopLoss IS NULL AND IsNoTakeProfit IS NULL |
| Root position filter | Business rule | Only processes tree head positions: p.TreeID = p.PositionID |
| Batch size | Performance | 1000 rows per iteration via WHILE loop to reduce lock contention |

---

## 8. Sample Queries

### 8.1 Initialize flags for partition range 0-49

```sql
EXEC Trade.SetIsNoStopLossIsNoTakeProfitInit
    @FromPartition = 0,
    @ToPartition = 49;
```

### 8.2 Check how many trees still have NULL flags (before running Init)

```sql
SELECT COUNT(*)
FROM Trade.PositionTreeInfo WITH (NOLOCK)
WHERE IsNoStopLoss IS NULL
AND IsNoTakeProfit IS NULL;
```

### 8.3 Verify result for a partition range after Init

```sql
SELECT TPTI.TreeID, TPTI.PartitionCol, TPTI.IsNoStopLoss, TPTI.IsNoTakeProfit, TPTI.IsTslEnabled
FROM Trade.PositionTreeInfo TPTI WITH (NOLOCK)
WHERE TPTI.PartitionCol BETWEEN 0 AND 49
AND (TPTI.IsNoStopLoss IS NULL OR TPTI.IsNoTakeProfit IS NULL);
-- Should return 0 rows after successful init
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetIsNoStopLossIsNoTakeProfitInit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetIsNoStopLossIsNoTakeProfitInit.sql*
