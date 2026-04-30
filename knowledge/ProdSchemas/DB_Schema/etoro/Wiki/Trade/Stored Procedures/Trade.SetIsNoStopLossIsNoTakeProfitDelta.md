# Trade.SetIsNoStopLossIsNoTakeProfitDelta

> Repairs stale or missing IsNoStopLoss and IsNoTakeProfit flags on copy-trade position trees by incrementally recalculating and updating only the trees that are NULL or inconsistent with their root position's current rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromPartition / @ToPartition (partition range of trees to process) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure fixes the `IsNoStopLoss` and `IsNoTakeProfit` flags on `Trade.PositionTreeInfo` rows in a targeted, delta/incremental manner. These flags indicate whether a copy-trade position tree has no effective stop-loss or take-profit configured (meaning the root position has none, so the tree's risk settings default to "unlimited loss" or "no limit profit exit"). They are critical for risk monitoring, portfolio display, and the Mirror Reopen engine.

Without accurate IsNoStopLoss/IsNoTakeProfit values, the system would show incorrect risk indicators to users and the reopen engine might apply incorrect logic when copy positions are detached and re-attached. This procedure ensures the flags reflect the actual state of the root position's StopRate and LimitRate.

The "Delta" variant (as opposed to "Init") is designed to be called on an ongoing basis to fix trees where:
1. Both flags are still NULL (never initialized) for the given partition range
2. IsNoStopLoss is inconsistent with the root position's current StopRate
3. IsNoTakeProfit is inconsistent with the root position's current LimitRate

It processes trees in batches of 1000 (by IndexID) to avoid lock escalation on large datasets. It is called with a partition range (@FromPartition/@ToPartition) so it can be parallelized across partition groups.

---

## 2. Business Logic

### 2.1 IsNoStopLoss and IsNoTakeProfit Calculation Rules

**What**: Defines when a position tree is considered to have "no stop loss" or "no take profit" set.

**Columns/Parameters Involved**: `Trade.Position.StopRate`, `Trade.Position.LimitRate`, `Trade.Position.Leverage`, `Trade.ProviderToInstrument.Precision`, `Trade.PositionTreeInfo.IsNoStopLoss`, `Trade.PositionTreeInfo.IsNoTakeProfit`

**Rules**:
- `IsNoStopLoss = 1` when: `StopRate <= 10^(-Precision)` AND `Leverage = 1`
  - Meaning: StopRate is effectively zero (below minimum pip precision) AND position is unleveraged (real stock)
  - For leveraged positions, StopRate is always present (forced by the system), so IsNoStopLoss is always 0 for leveraged positions
- `IsNoTakeProfit = 1` when: `LimitRate = 0` AND `Leverage = 1`
  - Meaning: no take-profit rate is set AND position is unleveraged
- When `IsTslEnabled = 1` (trailing stop-loss active) and `IsNoStopLoss` is being set to 1, `IsTslEnabled` is also reset to 0 (TSL becomes irrelevant if there is no stop-loss)

**Diagram**:
```
Root Position (TreeID = PositionID):
  StopRate <= 10^(-Precision) AND Leverage = 1  --> IsNoStopLoss = 1
  StopRate >  10^(-Precision)  OR  Leverage > 1 --> IsNoStopLoss = 0

  LimitRate = 0 AND Leverage = 1                --> IsNoTakeProfit = 1
  LimitRate > 0  OR  Leverage > 1               --> IsNoTakeProfit = 0
```

### 2.2 Three-Category Delta Detection

**What**: Identifies three distinct inconsistency scenarios that each require a different UPDATE statement.

**Columns/Parameters Involved**: `TPTI.IsNoStopLoss`, `TPTI.IsNoTakeProfit`

**Rules**:
- **UpdateType 1** (NULL rows): Both IsNoStopLoss AND IsNoTakeProfit are NULL - never initialized
  - UPDATE sets both IsNoStopLoss and IsNoTakeProfit, and resets IsTslEnabled if needed
- **UpdateType 2** (Stale IsNoStopLoss): IsNoStopLoss is NOT NULL but inconsistent with current StopRate
  - Only updates IsNoStopLoss (and IsTslEnabled), leaving IsNoTakeProfit untouched
- **UpdateType 3** (Stale IsNoTakeProfit): IsNoTakeProfit is NOT NULL but inconsistent with current LimitRate
  - Only updates IsNoTakeProfit, leaving IsNoStopLoss untouched

**Diagram**:
```
UpdateType 1: IsNoStopLoss IS NULL AND IsNoTakeProfit IS NULL
  --> UPDATE both flags + IsTslEnabled

UpdateType 2: IsNoStopLoss NOT NULL AND
  (StopRate <= pip AND Leverage=1 AND IsNoStopLoss=0)  [should be 1 but is 0]
  OR
  (StopRate > pip AND IsNoStopLoss=1)                  [should be 0 but is 1]
  --> UPDATE IsNoStopLoss + IsTslEnabled only

UpdateType 3: IsNoTakeProfit NOT NULL AND
  (LimitRate=0 AND Leverage=1 AND IsNoTakeProfit=0)    [should be 1 but is 0]
  OR
  (LimitRate != 0 AND IsNoTakeProfit=1)                [should be 0 but is 1]
  --> UPDATE IsNoTakeProfit only
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromPartition | int | NO | - | CODE-BACKED | Start of the partition range to process. Filters on Trade.Position.TreePartitionCol BETWEEN @FromPartition AND @ToPartition. Allows parallel execution across partition bands (e.g., 0-9, 10-19, etc.). |
| 2 | @ToPartition | int | NO | - | CODE-BACKED | End of the partition range to process. Paired with @FromPartition to define the work slice for this execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TreeID / TreePartitionCol | Trade.PositionTreeInfo | Modifier | Updates IsNoStopLoss, IsNoTakeProfit, IsTslEnabled for qualifying tree roots |
| TreeID / PositionID | Trade.Position | Reader | Reads root position (TreeID = PositionID) rates: StopRate, LimitRate, Leverage, TreePartitionCol |
| InstrumentID | Trade.ProviderToInstrument | Reader | Reads Precision to compute the minimum pip threshold (10^(-Precision)) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetIsNoStopLossIsNoTakeProfitDelta (procedure)
├── Trade.Position (view) [reads root positions with rates]
├── Trade.ProviderToInstrument (table) [reads Precision per InstrumentID]
└── Trade.PositionTreeInfo (table) [updates IsNoStopLoss, IsNoTakeProfit, IsTslEnabled]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Reads root positions (TreeID = PositionID) to calculate target flag values and detect inconsistencies |
| Trade.ProviderToInstrument | Table | Reads Precision to compute the minimum pip threshold for IsNoStopLoss calculation |
| Trade.PositionTreeInfo | Table | Updated with corrected IsNoStopLoss, IsNoTakeProfit, IsTslEnabled values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Likely called by scheduled maintenance jobs or partition-parallel orchestration scripts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Batching | Performance | Processes 1000 rows at a time via WHILE loop on IndexID range to avoid lock escalation |
| OPTION (RECOMPILE) | Query hint | Each batch uses RECOMPILE to get optimal plan for variable partition values |
| Root position filter | Business rule | Only processes trees where p.TreeID = p.PositionID (the root copy-trade position) |

---

## 8. Sample Queries

### 8.1 Process a specific partition range

```sql
EXEC Trade.SetIsNoStopLossIsNoTakeProfitDelta
    @FromPartition = 0,
    @ToPartition = 9;
```

### 8.2 Find trees with stale IsNoStopLoss (should be fixed by this SP)

```sql
SELECT TOP 20
    TPTI.TreeID,
    TPTI.IsNoStopLoss,
    TPTI.IsNoTakeProfit,
    p.StopRate,
    p.LimitRate,
    p.Leverage,
    pti.Precision
FROM Trade.PositionTreeInfo TPTI WITH (NOLOCK)
INNER JOIN Trade.Position p WITH (NOLOCK) ON p.TreeID = TPTI.TreeID AND p.TreePartitionCol = TPTI.PartitionCol
INNER JOIN Trade.ProviderToInstrument pti WITH (NOLOCK) ON p.InstrumentID = pti.InstrumentID
WHERE p.TreeID = p.PositionID
AND TPTI.IsNoStopLoss IS NOT NULL
AND (
    (p.StopRate <= CAST(POWER(10.0, -pti.Precision) AS DECIMAL(16,8)) AND p.Leverage = 1 AND TPTI.IsNoStopLoss = 0)
    OR
    (p.StopRate > CAST(POWER(10.0, -pti.Precision) AS DECIMAL(16,8)) AND TPTI.IsNoStopLoss = 1)
);
```

### 8.3 Check trees still with NULL IsNoStopLoss/IsNoTakeProfit

```sql
SELECT TOP 20 TPTI.TreeID, TPTI.PartitionCol, TPTI.IsNoStopLoss, TPTI.IsNoTakeProfit
FROM Trade.PositionTreeInfo TPTI WITH (NOLOCK)
WHERE TPTI.IsNoStopLoss IS NULL
AND TPTI.IsNoTakeProfit IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetIsNoStopLossIsNoTakeProfitDelta | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetIsNoStopLossIsNoTakeProfitDelta.sql*
