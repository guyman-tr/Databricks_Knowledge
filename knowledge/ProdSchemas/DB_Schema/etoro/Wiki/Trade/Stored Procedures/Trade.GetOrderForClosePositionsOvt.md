# Trade.GetOrderForClosePositionsOvt

> Returns comprehensive close-order and position data for a time window from both History and active Trade tables - a large OVT reporting SP used for position close reconciliation and execution analysis.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @start DATETIME + @end DATETIME |
| **Partition** | OccurredAsDate date partitions; #HistoryPosition clustered index on (CloseOccurred, PositionID, OriginalPositionID, ExitOrderID) |
| **Indexes** | Creates clustered index CIX on #HistoryPosition temp table |

---

## 1. Business Meaning

**WHAT:** `GetOrderForClosePositionsOvt` is a large operational reporting SP that joins closed positions with their close execution plan and executed close orders for a time window. It sources positions from both `History.Position_Active` (fully closed, historical) and `Trade.PositionTbl` (positions with StatusID=2, recently closed but still in Trade). It also incorporates stock split data and computes unit-weighted commission metrics.

**WHY:** Operations and risk teams need full position-level close details including execution plan data, actual fills, split adjustments, and commission breakdown. This is the primary data source for close-order reconciliation reports.

**HOW:**
1. Load `History.PositionSplit` into temp table `#HistoryPositionSplit` (filtered to splits since @start)
2. Build `#HistoryPosition` CTE via UNION ALL of `History.Position_Active` + `Trade.PositionTbl` (StatusID=2, closed in window), creating a clustered index for join performance
3. Final SELECT: `History.CloseExecutionPlan` LEFT JOIN `History.ExecutedCloseOrders` LEFT JOIN `#HistoryPosition` LEFT JOIN `#HistoryPositionSplit`

---

## 2. Business Logic

### 2.1 Dual Position Source - History + Active Trade

**What:** Positions can be in History (fully processed) or still in Trade.PositionTbl with StatusID=2 (recently closed, not yet archived). The UNION ALL captures both.

**Columns/Parameters Involved:** `StatusID`, `CloseOccurred`, `Occurred`

**Rules:**
- `History.Position_Active WHERE CloseOccurred BETWEEN @start AND @end` -> fully processed closed positions
- `Trade.PositionTbl WHERE StatusID=2 AND Occurred BETWEEN @start AND @end` -> recently closed (Occurred = close timestamp for StatusID=2)
- UNION ALL normalizes both sources with identical column list
- Several columns are NULL for Trade.PositionTbl rows (RequestedEndForexRate, RequestCloseOccurred, EndHedgeQuery, EndForexRateUnAdjusted, EndMarketRateUnAdjusted) as they only exist in History

### 2.2 Settlement Type Fallback

**What:** `ISNULL(SettlementTypeID, cast(IsSettled as tinyint))` -> same pattern as elsewhere: use SettlementTypeID if set, otherwise cast IsSettled boolean to tinyint.

### 2.3 Unit-Weighted Commission Calculation

**What:** The UNION ALL sources both compute commission proportionally based on current units vs initial units.

**Columns/Parameters Involved:** `CommissionByUnit`, `FullCommissionByUnit`, `InitialUnits`, `AmountInUnitsDecimal`

**Rules:**
- `CommissionByUnit = CASE WHEN InitialUnits <> 0 THEN (AmountInUnitsDecimal / InitialUnits) * Commission ELSE 0 END`
- For History: uses `InitialUnits` directly
- For Trade: uses `ISNULL(InitialUnits, AmountInUnitsDecimal)` as denominator
- Purpose: proportional commission allocation for partial-close scenarios

### 2.4 OriginalPositionID Normalization

**What:** History source uses `ISNULL(OriginalPositionID, PositionID)` - falls back to PositionID if not set (for non-split positions). Trade source uses `PositionID AS OriginalPositionID` - new positions haven't been split yet.

### 2.5 Temp Table Index for Join Performance

**What:** A clustered index is created on `#HistoryPosition (CloseOccurred, PositionID, OriginalPositionID, ExitOrderID)` before the final SELECT.

### 2.6 Final JOIN Structure

**What:** `History.CloseExecutionPlan` is the spine. LEFT JOINs to filled orders and position data.

**Rules:**
- `hcep.PositionID = heco.PositionID AND heco.OrderID = hcep.OrderID` -> match fill to plan entry
- `(heco.PositionID = hp.PositionID OR heco.PositionID = hp.OriginalPositionID) AND hp.CID = hcep.CID AND hcep.OrderID = hp.ExitOrderID` -> position join handles both original and split positions
- `hp.PositionID = ps.PositionID` -> link split records

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @start | datetime | NO | - | CODE-BACKED | Start of the reporting window. Filters Position_Active.CloseOccurred and PositionTbl.Occurred (as close timestamp). |
| 2 | @end | datetime | NO | - | CODE-BACKED | End of the reporting window. |

**Return Columns:** All columns from `History.CloseExecutionPlan` (hcep.*) plus:

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R+ | OrderID1 | bigint | CODE-BACKED | OrderID from History.ExecutedCloseOrders. |
| R+ | PositionID1 | bigint | CODE-BACKED | PositionID from ExecutedCloseOrders. |
| R+ | ExecutionID | bigint | CODE-BACKED | Execution batch ID from fill record. |
| R+ | Units1 | decimal | CODE-BACKED | Units from ExecutedCloseOrders. |
| R+ | NetProfit | money | CODE-BACKED | Net P&L from ExecutedCloseOrders. |
| R+ | PartialClosePositionID | bigint | CODE-BACKED | Source position for a partial close. |
| R+ | PartialClosedPositionAmount | money | CODE-BACKED | Amount of the source position that was closed. |
| R+ | OpenPositionAmount | money | CODE-BACKED | Remaining open amount after partial close. |
| R+ | OpenUnits | decimal | CODE-BACKED | Remaining open units. |
| R+ | PartialCloseRatio | decimal | CODE-BACKED | Ratio of partial close. |
| R+ | OpenUnitsBaseValueInCents | int | CODE-BACKED | Base value of remaining open units in cents. |
| R+ | Amount | money | CODE-BACKED | Amount from ExecutedCloseOrders. |
| R+ | PositionID2 | bigint | CODE-BACKED | PositionID from #HistoryPosition. |
| R+ | CID1 | int | CODE-BACKED | CID from #HistoryPosition. |
| R+ | ... (all position fields) | various | CODE-BACKED | All columns from #HistoryPosition UNION ALL. Includes P&L, rates, commission metrics, split data. |
| R+ | SplitPositionID | bigint | CODE-BACKED | PositionID from History.PositionSplit if a split occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @start date | History.PositionSplit | Direct query (temp table) | Splits since @start for split detection |
| @start/@end range | History.Position_Active | CTE source 1 | Historically closed positions |
| @start/@end range | Trade.PositionTbl | CTE source 2 | Recently closed (StatusID=2) positions |
| Trade.PositionTbl.TreeID | Trade.PositionTreeInfo | JOIN (CTE source 2) | IsDiscounted flag for closed positions |
| @start/@end | History.CloseExecutionPlan | Main query spine | Close plan entries in date range |
| CloseExecutionPlan | History.ExecutedCloseOrders | LEFT JOIN | Fill data per plan entry |
| ExecutedCloseOrders.PositionID | #HistoryPosition | LEFT JOIN | Full position data enrichment |
| #HistoryPosition.PositionID | #HistoryPositionSplit | LEFT JOIN | Split position cross-reference |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations reporting / OVT | N/A | CALLER | Close position reconciliation and execution analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForClosePositionsOvt (procedure)
├── History.PositionSplit (table)
├── History.Position_Active (table)
├── Trade.PositionTbl (table)
├── Trade.PositionTreeInfo (table)
├── History.CloseExecutionPlan (table)
├── History.ExecutedCloseOrders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSplit | Table | Split detection for OriginalPositionID matching |
| History.Position_Active | Table | Historical closed positions |
| Trade.PositionTbl | Table | Recently closed positions (StatusID=2) |
| Trade.PositionTreeInfo | Table | IsDiscounted flag for Trade source positions |
| History.CloseExecutionPlan | Table | Close plan spine for the join |
| History.ExecutedCloseOrders | Table | Fill execution data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations reporting tools | External | Large-scale close order reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

Creates `CREATE CLUSTERED INDEX CIX ON #HistoryPosition (CloseOccurred, PositionID, OriginalPositionID, ExitOrderID)` for join performance.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** `OPTION (RECOMPILE)` on the CTE/temp table population. `QUOTED_IDENTIFIER OFF`. Uses `DROP TABLE IF EXISTS` for idempotent temp table cleanup.

**Warning:** This SP can return a very large result set for wide date ranges (all position columns x all close plan entries). Should be called with narrow date windows.

---

## 8. Sample Queries

### 8.1 Get OVT close positions data for a day
```sql
EXEC Trade.GetOrderForClosePositionsOvt
    @start = '2026-03-15 00:00:00',
    @end   = '2026-03-15 23:59:59'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForClosePositionsOvt | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForClosePositionsOvt.sql*
