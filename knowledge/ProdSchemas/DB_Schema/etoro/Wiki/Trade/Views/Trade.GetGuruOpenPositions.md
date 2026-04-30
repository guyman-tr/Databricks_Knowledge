# Trade.GetGuruOpenPositions

> Filters leader (guru) open positions to those available for copying - excludes positions with pending close orders, active redeem operations, or terminal execution states.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.GetOpenPositionDataForGuro) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetGuruOpenPositions returns the set of **guru/leader open positions that are currently available for copy-trading**. Not every open leader position qualifies - positions in the process of being closed, redeemed, or with terminal execution status must be excluded to prevent new copiers from opening positions that will immediately close.

This view exists because the CopyTrader system needs a reliable set of "copyable" positions. When a new copier starts following a leader, only positions from this view should be copied. Including positions mid-close would create race conditions and failed trades. The view applies multiple exclusion filters to ensure only truly active, stable positions are returned.

The view reads from Trade.GetOpenPositionDataForGuro (the guru-specific open position data view) and LEFT JOINs to four close-related tables: OrdersExit (pending exit orders), DelayedOrderForClose (delayed close orders), CloseExecutionPlan (close execution plans), and OrderForClose/Dictionary.OrderForExecutionStatus (order-for-close with terminal status check). A position passes if: no close operations are pending, OR only a partial close is in progress (UnitsToDeduct > 0).

---

## 2. Business Logic

### 2.1 Copyability Filter

**What**: Multi-table exclusion filter ensuring only truly available positions are returned.

**Columns/Parameters Involved**: `RedeemStatus`, `OrdersExit.PositionID`, `DelayedOrderForClose.PositionID`, `CloseExecutionPlan.PositionID`, `OrderForExecutionStatus.IsTerminal`, `OrdersExit.UnitsToDeduct`

**Rules**:
- RedeemStatus must be 0 or NULL (no active redeem operation)
- Order execution status must be non-terminal (IsTerminal = 0 or NULL)
- Position passes the close-check filter if EITHER:
  - No close operations exist: OE.PositionID IS NULL AND DOFC.PositionID IS NULL AND CEP.PositionID IS NULL
  - OR a partial close is in progress: OE.PositionID IS NOT NULL AND OE.UnitsToDeduct > 0 (partial close means some units remain - position is still active)

**Diagram**:
```
Trade.GetOpenPositionDataForGuro (all guru open positions)
    |
    +-- LEFT JOIN OrdersExit (pending exit orders)
    +-- LEFT JOIN DelayedOrderForClose (delayed closes)
    +-- LEFT JOIN CloseExecutionPlan --> OrderForClose --> OrderForExecutionStatus
    |
    WHERE:
      RedeemStatus = 0
      AND IsTerminal = 0
      AND (
        no close ops pending
        OR partial close in progress (UnitsToDeduct > 0)
      )
    |
    = Positions safe for new copiers to copy
```

---

## 3. Data Overview

| CID | PositionID | InstrumentID | IsBuy | Amount | Leverage | MirrorID | SettlementTypeID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 18 | 2152547500 | 4212 | true | 0.10 | 1 | 0 | 1 | Small real-stock position from 2019, no mirror (independent leader), available for copying |
| 742577 | 2152042350 | 100026 | true | 104.41 | 1 | 0 | 1 | Recent real-stock buy, independent leader position, copyable |
| 742577 | 2152074900 | 100026 | true | 104.43 | 1 | 0 | 1 | Another independent buy on same instrument, showing leader can have multiple copyable positions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Leader/guru customer ID. From Trade.GetOpenPositionDataForGuro. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Leader's open position ID, safe for copying. |
| 3 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in add-to-position hierarchy. From GetOpenPositionDataForGuro. |
| 4 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy forex result tracking. |
| 5 | IsOpened | bit | YES | - | CODE-BACKED | Whether position is open. Always true in this context. |
| 6 | Currency | int | YES | - | CODE-BACKED | Denomination currency ID. |
| 7 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. FK to Trade.Provider. |
| 8 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 9 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server for position routing. |
| 10 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier (1 = no leverage for real stocks). |
| 11 | ForexBuy | int | YES | - | CODE-BACKED | Buy-side currency ID. |
| 12 | ForexSell | int | YES | - | CODE-BACKED | Sell-side currency ID. |
| 13 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 14 | EndForexRate | float | YES | - | CODE-BACKED | End forex rate (NULL for open positions). |
| 15 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 16 | EndDateTime | datetime | YES | - | CODE-BACKED | End timestamp (NULL for open). |
| 17 | ActionType | int | YES | - | CODE-BACKED | Close action type (NULL for open). |
| 18 | NetProfit | money | YES | - | CODE-BACKED | Hardcoded NULL. PnL not included in this view. |
| 19 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate. |
| 20 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate. |
| 21 | Amount | money | YES | - | CODE-BACKED | Position amount in denomination currency. |
| 22 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position amount in units/shares. |
| 23 | Commission | money | YES | - | CODE-BACKED | Commission at open. |
| 24 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 25 | IsBuy | varchar | YES | - | CODE-BACKED | Direction: 'true' = buy/long, 'false' = sell/short. String format from GetOpenPositionDataForGuro. |
| 26 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Weekend close preference. |
| 27 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. |
| 28 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 29 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. |
| 30 | OpenOccurred | datetime | YES | - | CODE-BACKED | When open was executed. |
| 31 | CloseOccurred | datetime | YES | - | CODE-BACKED | When close was executed (NULL for open). |
| 32 | OrderID | int | YES | - | CODE-BACKED | Originating order. |
| 33 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance. |
| 34 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits. |
| 36 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last op price rate snapshot ID. |
| 38 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last op conversion rate snapshot ID. |
| 40 | UnitMargin | money | YES | - | CODE-BACKED | Unit margin. |
| 41 | Units | decimal | YES | - | CODE-BACKED | Unit count. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | Decimal precision for instrument. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID. 0 = independent leader position. |
| 44 | PositionRatio | decimal | YES | - | CODE-BACKED | Copy ratio. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assignment. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Initial amount in cents. |
| 48 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID. |
| 49 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution ID for initial open. |
| 50 | EndExecutionID | bigint | YES | - | CODE-BACKED | End execution ID (NULL for open). |
| 51 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server. |
| 52 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree ID. |
| 53 | IsTslEnabled | bit | YES | - | CODE-BACKED | Whether trailing stop-loss is enabled. |
| 54 | IsSettled | bit | YES | - | CODE-BACKED | Legacy settlement flag: 1 = real stock. |
| 55 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type: 1=Real, 2=CFD. See [Settlement Type](_glossary.md#settlement-type). |
| 56 | IsRootSettled | bit | YES | - | CODE-BACKED | Whether the root/leader position is a real stock position. |
| 57 | RootSettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type of the root position. |
| 58 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Base value in cents. |
| 59 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether position has discounted fees. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | Trade.GetOpenPositionDataForGuro | View dependency | Source of guru open positions |
| PositionID | Trade.OrdersExit | LEFT JOIN | Pending exit orders check |
| PositionID | Trade.DelayedOrderForClose | LEFT JOIN | Delayed close orders check |
| PositionID | Trade.CloseExecutionPlan | LEFT JOIN | Close execution plan check |
| CEP.OrderID | Trade.OrderForClose | LEFT JOIN | Order-for-close details |
| OFC.StatusID | Dictionary.OrderForExecutionStatus | LEFT JOIN | Terminal status check (IsTerminal) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetGuruOpenPositionsWithCustomerData | SELECT | Procedure reader | Enriches guru positions with customer data for copy-trade UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetGuruOpenPositions (view)
+-- Trade.GetOpenPositionDataForGuro (view)
+-- Trade.OrdersExit (table)
+-- Trade.DelayedOrderForClose (table)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.OrderForClose (table)
+-- Dictionary.OrderForExecutionStatus (x-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOpenPositionDataForGuro | View | Base guru position data |
| Trade.OrdersExit | Table | LEFT JOIN for pending exit orders |
| Trade.DelayedOrderForClose | Table | LEFT JOIN for delayed close orders |
| Trade.CloseExecutionPlan | Table | LEFT JOIN for close execution plans |
| Trade.OrderForClose | Table | LEFT JOIN for order-for-close details |
| Dictionary.OrderForExecutionStatus | Table | LEFT JOIN for terminal status flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetGuruOpenPositionsWithCustomerData | Procedure | Reads guru positions and adds customer info |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All copyable guru positions

```sql
SELECT CID, PositionID, InstrumentID, Amount, Leverage, SettlementTypeID
FROM   Trade.GetGuruOpenPositions WITH (NOLOCK)
ORDER BY CID, InstrumentID;
```

### 8.2 Guru positions by leader with counts

```sql
SELECT CID, COUNT(*) AS OpenPositionCount, SUM(Amount) AS TotalAmount
FROM   Trade.GetGuruOpenPositions WITH (NOLOCK)
GROUP BY CID
ORDER BY OpenPositionCount DESC;
```

### 8.3 Real stock guru positions (copyable)

```sql
SELECT CID, PositionID, InstrumentID, Amount, IsSettled, SettlementTypeID
FROM   Trade.GetGuruOpenPositions WITH (NOLOCK)
WHERE  SettlementTypeID = 1
ORDER BY Amount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 59 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetGuruOpenPositions | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetGuruOpenPositions.sql*
