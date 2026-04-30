# Trade.GetRealEditSLMMRecovery

> MM recovery view that finds child positions where StopRate (SL) differs from parent, with 3-hour recency and weekend exclusion—stop-loss recovery for copy-trade alignment.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.GetPositionData) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetRealEditSLMMRecovery identifies **copy-trade child positions whose StopRate (SL) is out of sync** with the leader's parent position, with additional safeguards: only positions whose parent had a recent StopRate change (within 3 hours) and only when the market is not in weekend state. When a leader updates their stop-loss, the change should propagate to all copier positions. If propagation fails, the child retains the old StopRate while the parent has the new one—requiring MM recovery to align them.

This view exists to feed the SL (Stop-Loss) recovery pipeline. It JOINs Trade.GetPositionData (child TGP) to Trade.Position (parent tg2) where TGP.StopRate <> tg2.StopRate. The INNER JOIN to a CTE over History.PositionChangeLog restricts results to parents with StopRate <> PreviousStopRate and Occurred > dateadd(hour,-3, getutcdate()). The CROSS JOIN to Maintenance.Feature (FeatureID=1) provides WeekEndState.IsWeekend; only rows where IsWeekend=0 are returned, avoiding recovery during weekends. The view excludes positions that have logged an SL failure (FailTypeID=9) in History.MMLog.

The output schema is identical to Trade.GetPositionData (47 columns). Each row represents a copy-trade position needing an SL edit to match the parent.

---

## 2. Business Logic

### 2.1 SL Mismatch Detection with Recency and Weekend Exclusion

**What**: Child StopRate <> parent StopRate, with 3-hour recency window and weekend exclusion.

**Columns/Parameters Involved**: `StopRate`, `ParentPositionID`, `PositionID`, `MirrorID`, `IsActive`, `FailTypeID`, `PreviousStopRate`, `Occurred`, `IsWeekend`

**Rules**:
- Child (TGP): TGP.IsOpened=1, TGP.ParentPositionID>0
- Parent (tg2): tg2.PositionID = TGP.ParentPositionID AND TGP.StopRate <> tg2.StopRate
- CTE (MyCTE): History.PositionChangeLog WHERE StopRate<>PreviousStopRate AND Occurred > dateadd(hour,-3, getutcdate())
- INNER JOIN MyCTE ON MyCTE.PositionID = tg2.PositionID (parent had recent SL change)
- CROSS JOIN Maintenance.Feature (FeatureID=1) → WeekEndState.IsWeekend=0
- Mirror filter: (TGP.MirrorID=0) OR (TGP.MirrorID>0 AND Trade.Mirror.IsActive=1)
- NOT EXISTS History.MMLog WHERE PositionID=TGP.PositionID AND FailTypeID=9
- All 47 output columns come from TGP (child)

---

## 3. Data Overview

N/A - recovery/operational view. Each row represents a copy-trade position requiring MM recovery action.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID who owns this position. FK to Customer.Customer. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. PK for the position record. |
| 3 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position whose StopRate differs. |
| 4 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy forex result tracking. |
| 5 | IsOpened | bit/int | NO | - | CODE-BACKED | Always 1 (open) for rows in this view. |
| 6 | Currency | int | YES | - | CODE-BACKED | Denomination currency. FK to Dictionary.Currency. |
| 7 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. FK to Trade.Provider. |
| 8 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 9 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this position. |
| 10 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. |
| 11 | ForexBuy | int | YES | - | CODE-BACKED | Buy currency ID from instrument. |
| 12 | ForexSell | int | YES | - | CODE-BACKED | Sell currency ID from instrument. |
| 13 | InitForexRate | float | YES | - | CODE-BACKED | Forex conversion rate at position open. |
| 14 | EndForexRate | float | YES | - | CODE-BACKED | Forex rate at close; typically NULL for open positions. |
| 15 | InitDateTime | datetime | YES | - | CODE-BACKED | Timestamp when position was opened. |
| 16 | EndDateTime | datetime | YES | - | CODE-BACKED | Timestamp when position closed; NULL for open. |
| 17 | ActionType | int | YES | - | CODE-BACKED | Close action type; NULL for open positions. |
| 18 | NetProfit | money | YES | - | CODE-BACKED | Unrealized PnL. |
| 19 | LimitRate | float | YES | - | CODE-BACKED | Take-profit price level. |
| 20 | StopRate | float | YES | - | CODE-BACKED | Child's SL level—differs from parent (mismatch). |
| 21 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. |
| 22 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 23 | Commission | money | YES | - | CODE-BACKED | Commission charged at open. |
| 24 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 25 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=buy/long, 0=sell/short. |
| 26 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Weekend-close preference. |
| 27 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. |
| 28 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 29 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. |
| 30 | OpenOccurred | datetime | YES | - | CODE-BACKED | When position was executed. |
| 31 | CloseOccurred | datetime | YES | - | CODE-BACKED | When position closed; NULL for open. |
| 32 | OrderID | int | YES | - | CODE-BACKED | Originating order ID. |
| 33 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance at open. |
| 34 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID at open. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits/merges. |
| 36 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Price rate from last operation. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for last op price rate. |
| 38 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Conversion rate from last operation. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for last op conversion rate. |
| 40 | UnitMargin | money | YES | - | CODE-BACKED | Margin per unit for hedge calculations. |
| 41 | Units | decimal | YES | - | CODE-BACKED | Unit count from provider. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | Decimal precision for instrument. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0=manual trade. |
| 44 | PositionRatio | decimal | YES | - | CODE-BACKED | Copy ratio relative to leader. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assignment. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Initial position amount in cents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | Trade.GetPositionData | View dependency | Child position data |
| ParentPositionID | Trade.Position | JOIN | Parent position (StopRate comparison) |
| ParentPositionID | History.PositionChangeLog | INNER JOIN via CTE | Recent SL change filter |
| (base) | Maintenance.Feature | CROSS JOIN | WeekEndState (FeatureID=1) |
| MirrorID | Trade.Mirror | LEFT JOIN | Mirror activity filter |
| PositionID | History.MMLog | NOT EXISTS | Exclude SL fail (FailTypeID=9) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRealEditSLMMRecovery (view)
+-- Trade.GetPositionData (view)
+-- Trade.Position (view)
+-- History.PositionChangeLog (table) [x-schema, CTE]
+-- Maintenance.Feature (table) [x-schema]
+-- Trade.Mirror (table)
+-- History.MMLog (table) [x-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|-----------|
| Trade.GetPositionData | View | Base data for child positions |
| Trade.Position | View | Parent position for StopRate comparison |
| History.PositionChangeLog | Table | CTE: recent StopRate changes (3-hour window) |
| Maintenance.Feature | Table | CROSS JOIN for WeekEndState.IsWeekend (FeatureID=1) |
| Trade.Mirror | Table | LEFT JOIN for active-mirror / manual filter |
| History.MMLog | Table | NOT EXISTS to exclude FailTypeID=9 (SL fail) |

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

### 8.1 Count SL recovery items (weekday, recent changes only)

```sql
SELECT COUNT(*) AS RecoveryCount
FROM   Trade.GetRealEditSLMMRecovery WITH (NOLOCK);
```

### 8.2 SL recovery by instrument

```sql
SELECT InstrumentID, COUNT(*) AS Cnt
FROM   Trade.GetRealEditSLMMRecovery WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY Cnt DESC;
```

### 8.3 Recovery payload for a specific position

```sql
SELECT PositionID, ParentPositionID, StopRate, LimitRate, CID, Amount
FROM   Trade.GetRealEditSLMMRecovery WITH (NOLOCK)
WHERE  PositionID = 2150123456;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 47 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRealEditSLMMRecovery | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetRealEditSLMMRecovery.sql*
