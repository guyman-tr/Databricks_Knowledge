# Trade.GetRecoveryItemsDemo

> Combined edit recovery for demo positions—finds copier positions where SL, TP, or CloseOnEndOfWeek differs from the leader, with parent values for comparison and MaxSLReached flag.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.GetPositionData) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetRecoveryItemsDemo identifies **demo copy-trade positions whose SL (StopRate), TP (LimitRate), or CloseOnEndOfWeek setting is out of sync** with the leader's parent position. When a leader edits their stop-loss, take-profit, or weekend-close preference, those changes should propagate to all copier positions. If propagation fails, the child retains the old values while the parent has the new ones—requiring Market Maker (MM) recovery to align them.

This view feeds the **edit recovery pipeline** for demo accounts. It joins Trade.GetPositionData (child positions) to a subquery that finds parent positions from RealOpenPositions where the child's StopRate, LimitRate, or CloseOnEndOfWeek differs from the parent. The view excludes positions that have already failed a max-SL recovery (History.MMLog FailTypeID=8) and includes a MaxSLReached flag (FailTypeID=9) to indicate positions that have reached their stop-loss limit. Only active mirrors (MirrorID=0 or Trade.Mirror.IsActive=1) are considered.

The output enriches Trade.GetPositionData's 47 columns with 9 additional columns: ParentCID, ParentStopRate, ParentLimitRate, ParentCloseOnEndOfWeek, ParentLastOpPriceRate, ParentLastOpPriceRateID, ParentLastOpConversionRate, ParentLastOpConversionRateID, and MaxSLReached—providing full context for the recovery process to apply the parent's edited values to the child.

---

## 2. Business Logic

### 2.1 Edit Mismatch Detection (SL/TP/CloseOnEndOfWeek)

**What**: Identifies copier positions whose StopRate, LimitRate, or CloseOnEndOfWeek differs from the leader's current values.

**Columns/Parameters Involved**: `StopRate`, `LimitRate`, `CloseOnEndOfWeek`, `ParentPositionID`, `MirrorID`, `IsActive`, `FailTypeID`

**Rules**:
- Child (tp): tp.ParentPositionID > 0; tp joins to RealOpenPositions via rop.PositionID = tp.ParentPositionID
- Mismatch: rop.StopRate <> tp.StopRate OR rop.LimitRate <> tp.LimitRate OR rop.CloseOnEndOfWeek <> tp.CloseOnEndOfWeek
- Mirror filter: (tp.MirrorID = 0) OR (tp.MirrorID > 0 AND Trade.Mirror.IsActive = 1)
- Exclude positions with History.MMLog FailTypeID = 8 (already failed recovery)

### 2.2 MaxSLReached Flag

**What**: Flags positions that have recorded a max-SL event in MMLog (FailTypeID=9).

**Columns/Parameters Involved**: `MaxSLReached`, `PositionID`, `FailTypeID`

**Rules**:
- MaxSLReached = 1 when EXISTS (SELECT * FROM History.MMLog WHERE PositionID = tg.PositionID AND FailTypeID = 9)
- MaxSLReached = NULL when no such MMLog entry exists

---

## 3. Data Overview

Each row represents an open demo copy-trade position requiring edit recovery. The child's position data (from Trade.GetPositionData) is paired with the parent's CID, StopRate, LimitRate, CloseOnEndOfWeek, and last-op price/conversion rates for comparison and recovery.

---

## 4. Elements

| # | Column Name | Data Type | Source | Confidence | Description |
|---|-------------|-----------|--------|------------|-------------|
| 1-47 | (GetPositionData columns) | (inherited) | Trade.GetPositionData | CODE-BACKED | CID, PositionID, ForexResultID, IsOpened, Currency, ProviderID, InstrumentID, PositionHedgeServerID, Leverage, ForexBuy, ForexSell, InitForexRate, EndForexRate, InitDateTime, EndDateTime, ActionType, NetProfit, LimitRate, StopRate, Amount, AmountInUnitsDecimal, Commission, SpreadedCommission, IsBuy, CloseOnEndOfWeek, EndOfWeekFee, LotCountDecimal, AdditionalParam, OpenOccurred, CloseOccurred, OrderID, TradeRange, InitForexPriceRateID, OrigParentPositionID, LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID, UnitMargin, Units, InstrumentPrecision, MirrorID, PositionRatio, DirectAggLotCount, SpreadGroupID, ParentPositionID, InitialAmountCents. See Trade.GetPositionData documentation. |
| 48 | ParentCID | int | EditPositionsForMMRecovery | CODE-BACKED | Leader/customer ID from parent position. |
| 49 | ParentStopRate | float | EditPositionsForMMRecovery | CODE-BACKED | Parent's StopRate (SL)—target value for recovery. |
| 50 | ParentLimitRate | float | EditPositionsForMMRecovery | CODE-BACKED | Parent's LimitRate (TP)—target value for recovery. |
| 51 | ParentCloseOnEndOfWeek | bit | EditPositionsForMMRecovery | CODE-BACKED | Parent's weekend-close preference—target value for recovery. |
| 52 | ParentLastOpPriceRate | decimal(16,8) | EditPositionsForMMRecovery | CODE-BACKED | Parent's last operation price rate. |
| 53 | ParentLastOpPriceRateID | bigint | EditPositionsForMMRecovery | CODE-BACKED | Parent's last op price rate snapshot ID. |
| 54 | ParentLastOpConversionRate | decimal(16,8) | EditPositionsForMMRecovery | CODE-BACKED | Parent's last operation conversion rate. |
| 55 | ParentLastOpConversionRateID | bigint | EditPositionsForMMRecovery | CODE-BACKED | Parent's last op conversion rate snapshot ID. |
| 56 | MaxSLReached | bit | CASE/History.MMLog | CODE-BACKED | 1 if position has MMLog FailTypeID=9 (max SL reached); NULL otherwise. |

---

## 5. Relationships

### 5.1 References To

| Object | Relationship |
|--------|--------------|
| Trade.GetPositionData | INNER JOIN on PositionID, IsOpened=1 |
| RealOpenPositions (synonym/view) | Parent position data |
| Trade.Position | Child position data |
| Trade.Mirror | Mirror activity status |
| History.MMLog | FailTypeID exclusion (8) and MaxSLReached flag (9) |

### 5.2 Referenced By

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRecoveryItemsDemo (view)
+-- Trade.GetPositionData (view)
|     +-- Trade.PositionTbl (table)
|     +-- History.Position (table)
|     +-- Trade.Instrument, Trade.ProviderToInstrument, Trade.PositionTreeInfo, Trade.Mirror
+-- RealOpenPositions (synonym/view)
+-- Trade.Position (view)
+-- Trade.Mirror (table)
+-- History.MMLog (x-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionData | View | Base position data; 47 columns |
| RealOpenPositions | Synonym/View | Parent open positions |
| Trade.Position | View | Child positions, mirror filter |
| Trade.Mirror | Table | IsActive for mirror filter |
| History.MMLog | Table | FailTypeID 8 exclusion; FailTypeID 9 for MaxSLReached |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All demo recovery items requiring SL/TP/CloseOnEndOfWeek sync

```sql
SELECT PositionID, CID, ParentPositionID, StopRate, ParentStopRate, LimitRate, ParentLimitRate,
       CloseOnEndOfWeek, ParentCloseOnEndOfWeek, MaxSLReached
FROM   Trade.GetRecoveryItemsDemo WITH (NOLOCK);
```

### 8.2 Recovery items where MaxSLReached is set

```sql
SELECT PositionID, CID, ParentCID, ParentStopRate, StopRate
FROM   Trade.GetRecoveryItemsDemo WITH (NOLOCK)
WHERE  MaxSLReached = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Quality: 8.5/10*
*Object: Trade.GetRecoveryItemsDemo | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetRecoveryItemsDemo.sql*
