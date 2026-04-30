# Trade.Orders

> Active (currently open or pending) trading orders awaiting execution or closure on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID (INT, CLUSTERED PK) |
| **Partition** | No (filegroup: MAIN) |
| **Indexes** | 3 nonclustered + 1 clustered PK |

---

## 1. Business Meaning

Trade.Orders is the **hot transactional table** for all currently active trading orders. Each row represents a single order that has been placed by a customer but has not yet been closed or fulfilled. This includes market orders that are currently open, pending entry orders waiting for a price trigger, and exit orders scheduled for execution.

This table is essential for the real-time trading engine. Every open order must be tracked here so the matching engine, risk management, and copy-trade systems can reference it. Without it, the platform would have no record of pending or active orders, and no mechanism for order execution or closure.

Data flows through Trade.Orders as a **write-then-delete** pattern. The `Trade.OrdersAdd` procedure creates rows when a customer places a new order (generating the OrderID via `Internal.GetOrderID` and capturing the current price rates from `Trade.CurrencyPrice`). While the order is active, it is read by views (`Trade.GetOrders`, `Trade.GetOpenOrders`) and matching procedures. When the order is fulfilled or cancelled, `Trade.OrdersClose` moves the row to `History.Orders` (preserving the open and close timestamps) and deletes it from this table. Failed orders are separately logged to `History.OrdersFail`.

---

## 2. Business Logic

### 2.1 Order Lifecycle (Write-Then-Delete)

**What**: Orders exist in this table only while active - once closed, they move to history.

**Columns/Parameters Involved**: `OrderID`, `OccurredTime`

**Rules**:
- A new order is inserted by `Trade.OrdersAdd` with `OccurredTime = GETDATE()`
- While active, the order can be queried, matched, and processed
- On closure, `Trade.OrdersClose` copies the full row to `History.Orders` (adding `CloseOcurred = GETDATE()`) then DELETEs the row from Trade.Orders
- If closure fails, the row is copied to `History.OrdersFail1001` for investigation

**Diagram**:
```
Customer places order
        |
        v
[Trade.OrdersAdd] --> INSERT into Trade.Orders
        |                   |
        |          (active/pending)
        |                   |
        v                   v
  [OrdersClose] --> INSERT into History.Orders
                 --> DELETE from Trade.Orders
```

### 2.2 Copy-Trade Order Hierarchy

**What**: Orders can be linked in a parent-child hierarchy for copy-trading.

**Columns/Parameters Involved**: `ParentOrderID`, `OrderID`

**Rules**:
- A `ParentOrderID` of 0 or NULL means the order is independent (manual trade)
- A non-zero `ParentOrderID` references another order in Trade.Orders (the parent/leader order)
- In copy-trade (CopyTrader), when a leader opens an order, child orders are created for each copier with `ParentOrderID` pointing to the leader's OrderID
- On closure in Demo environments, if `ParentOrderID > 0`, the system calls `Trade.DetachFromParentOrder` to unlink the copy relationship before deletion
- The parent order's InstrumentID must match the child's InstrumentID (validated in OrdersAdd)

### 2.3 Settlement Type Classification

**What**: Orders are classified by their settlement model (CFD vs real stock ownership).

**Columns/Parameters Involved**: `IsSettled`, `SettlementTypeID`

**Rules**:
- `IsSettled` is a legacy BIT flag: 1 = real stock position, 0 = CFD
- `SettlementTypeID` is the modern replacement with finer granularity: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE
- When `SettlementTypeID` is NULL, the system falls back to `IsSettled` (legacy behavior)
- Settlement type affects fee calculations, regulatory treatment, and custody handling

### 2.4 Price Rate Capture at Order Time

**What**: The system captures the prevailing market rate and conversion rate at order creation time.

**Columns/Parameters Involved**: `LastOpPriceRateID`, `LastOpPriceRate`, `LastOpConversionRateID`, `LastOpConversionRate`

**Rules**:
- If price rate is not provided by the caller, `Trade.OrdersAdd` looks up the current price from `Trade.CurrencyPrice` using `ProviderID + InstrumentID`
- The conversion rate is calculated based on the instrument's currency pair: for major instruments (`IsMajor=1`), conversion rate is 1; otherwise, it is derived from `Trade.CurrencyPrice` via the instrument's `SellCurrencyID`/`BuyCurrencyID`
- If the conversion rate is 1 or NULL, both `LastOpConversionRate` and `LastOpConversionRateID` are stored as 0

---

## 3. Data Overview

Table has 0 rows in the connected environment (staging). In production, this table holds all currently active/pending orders and is continuously written to and deleted from as orders are placed and closed. Rows are transient - they exist only for the lifetime of an active order.

Representative data patterns (from DDL and procedure analysis):

| OrderID | CID | InstrumentID | OrderTypeID | IsBuy | Amount | SettlementTypeID | Meaning |
|---|---|---|---|---|---|---|---|
| 10001 | 5432 | 1001 | 1 (OpenTrade) | 1 | 500 | 0 (CFD) | A customer opening a $500 buy/long CFD position on an instrument |
| 10002 | 5432 | 2010 | 4 (BuyStopOrder) | 1 | 1000 | 1 (REAL) | A pending buy-stop entry order for a real stock - triggers when price rises above RateFrom |
| 10003 | 8821 | 1001 | 3 (CloseTrade) | 0 | 200 | 0 (CFD) | A close order to exit part of a CFD position |
| 10004 | 9900 | 3050 | 9 (EditStopLoss) | 1 | 500 | 5 (MARGIN_TRADE) | A stop-loss modification order on a margin trade position |
| 10005 | 7711 | 1001 | 1 (OpenTrade) | 1 | 250 | 1 (REAL) | A copy-trade child order (ParentOrderID > 0) opening a real stock position |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Primary key identifying a unique order. Generated by `Internal.GetOrderID` during `Trade.OrdersAdd`. Moves to `History.Orders.OrderID` on closure. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID of the account that placed the order. References `Customer.Customer.CID`. Used to look up client version and restrictions. |
| 3 | CurrencyID | INT | YES | - | CODE-BACKED | Currency denomination of the order amount. References `Dictionary.Currency`. Typically the customer's account currency. |
| 4 | ProviderID | INT | YES | - | CODE-BACKED | Liquidity provider executing this order. References `Trade.Provider`. Used with `InstrumentID` to look up current price from `Trade.CurrencyPrice`. |
| 5 | OrderTypeID | INT | YES | - | VERIFIED | Type of trading operation. FK to `Dictionary.OrderType`: 0=PendingOrderByAmount, 1=OpenTrade, 2=OpenTradeFromOrder, 3=CloseTrade, 4=OpenEntryBuyStopOrder, 5=OpenEntryBuyLimitOrder, 6=OpenEntrySellStopOrder, 7=OpenEntrySellLimitOrder, 8=CloseTradeOrder, 9=EditStopLoss, 10=EditTakeProfit, 11=EditOverWeekend, 12=EditOverWeekendWithStopLossRate, 13=EntryOrderByAmount, 14=ExitOrder, 15=PendingOrderByUnits, 16=EntryOrderByUnits, 17=OrderForExecutionByAmount, 18=OrderForExecutionByUnits, 19=OrderForCloseByUnits, 20=OrderForCloseMultiple. |
| 6 | InstrumentID | INT | YES | - | CODE-BACKED | Financial instrument being traded. References `Trade.Instrument.InstrumentID`. Validated against parent order's instrument in copy-trade scenarios. |
| 7 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier applied to the order. Must be non-zero (validated by `Trade.OrdersAdd` with RAISERROR). Determines margin requirement. |
| 8 | Amount | MONEY | YES | - | CODE-BACKED | Order monetary amount in the customer's currency. Must be positive (enforced by CHECK constraint `CH_TradeOrders_Amount`). Validated in `OrdersAdd` to be > 0. |
| 9 | Units | INT | YES | - | CODE-BACKED | Number of discrete units (shares/lots) for the order. Used with `LotCountDecimal` for position sizing. |
| 10 | UnitMargin | INT | YES | - | NAME-INFERRED | Margin requirement per unit. Represents the collateral required for each unit of the position. |
| 11 | LotCountDecimal | DECIMAL(16,6) | YES | - | CODE-BACKED | Precise lot count for the order. Must be positive (CHECK constraint `CH_TradeOrders_LotCountDecimal`). Multiplied by `Units` to compute `AmountInUnitsDecimal` in `Trade.GetOpenOrders`. |
| 12 | RateFrom | dbo.dtPrice | YES | - | CODE-BACKED | Opening/trigger price rate for the order. For market orders, the execution rate; for entry orders, the price level that triggers execution. |
| 13 | RateTo | dbo.dtPrice | YES | - | NAME-INFERRED | Target/limit price rate for the order. Used as the upper bound in range-based orders. |
| 14 | IsBuy | BIT | YES | - | CODE-BACKED | Trade direction: 1 = Buy/Long (customer profits when price rises), 0 = Sell/Short (customer profits when price falls). Converted to INT in `Trade.GetOrders` view. |
| 15 | ForexResultID | BIGINT | YES | - | VERIFIED | Deprecated. Always set to -1 in `Trade.OrdersAdd` per code comment: "ForexResultID is not being used anymore and we got few errors about foreign key violation." Retained for backward compatibility. |
| 16 | GameID | INT | YES | - | NAME-INFERRED | Legacy identifier from eToro's social trading game era. Default = 0 in OrdersAdd. No longer actively used in current trading logic. |
| 17 | SpreadID | INT | YES | - | CODE-BACKED | Spread configuration applied to this order. References `Trade.Spread`. Default = 0 in OrdersAdd. Determines bid-ask spread pricing. |
| 18 | LoginID | INT | YES | - | NAME-INFERRED | Session login identifier of the user who placed the order. Default = 0. Links to the Customer.Login session that created this order. |
| 19 | IsOverWeekend | BIT | YES | - | CODE-BACKED | Whether the order can remain open over weekends. 1 = position stays open over the weekend (default), 0 = position is closed before weekend market closure. Converted to INT in `Trade.GetOrders`. |
| 20 | StopLosAmount | INT | YES | - | CODE-BACKED | Stop-loss protection amount in monetary terms. Amount of loss (in customer currency) at which the position auto-closes to prevent further loss. |
| 21 | TakeProfitAmount | INT | YES | - | CODE-BACKED | Take-profit target amount in monetary terms. Amount of profit at which the position auto-closes to lock in gains. |
| 22 | MarketSpreadPips | INT | YES | - | CODE-BACKED | Market spread at order time, expressed in pips (smallest price increment for forex instruments). Captured for execution quality tracking. |
| 23 | MarketSpreadCents | INT | YES | - | CODE-BACKED | Market spread at order time, expressed in cents (for equity/stock instruments). Captured for execution quality tracking. |
| 24 | StopLosRate | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss trigger price rate. When the market hits this rate, the position is automatically closed. Indexed via `IX_instrumentID` INCLUDE. |
| 25 | TakeProfitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit trigger price rate. When the market hits this rate, the position is automatically closed to lock in gains. |
| 26 | OccurredTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the order was created. Set to `GETDATE()` during `Trade.OrdersAdd`. Moved to `History.Orders.OpenOccurred` on closure. |
| 27 | TradeRange | INT | YES | - | NAME-INFERRED | Market range tolerance for order execution. Defines the acceptable price deviation from the requested rate during execution. |
| 28 | ParentOrderID | INT | YES | - | VERIFIED | Copy-trade parent order reference. 0 or NULL = independent/manual order. Positive value = this order was created as a copy of the referenced parent order (CopyTrader). Validated in OrdersAdd to ensure parent exists and has the same InstrumentID. Default = 1. |
| 29 | LastOpPriceRateID | BIGINT | YES | - | CODE-BACKED | Price rate record ID from `Trade.CurrencyPrice.PriceRateID` at the time of order creation. Auto-populated from CurrencyPrice if not provided by caller. |
| 30 | LastOpPriceRate | dbo.dtPrice | YES | - | CODE-BACKED | Mid-market price ((Bid+Ask)/2) from `Trade.CurrencyPrice` at order creation time. Used for reference pricing and PnL baseline. |
| 31 | LastOpConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | Currency conversion rate at order creation. For major instruments = 1. For others, derived from CurrencyPrice via the instrument's currency pair. Stored as 0 when conversion rate is 1. |
| 32 | LastOpConversionRateID | BIGINT | YES | - | CODE-BACKED | Conversion rate record ID from `Trade.CurrencyPrice.PriceRateID`. Stored as 0 when no conversion is needed (major instruments). |
| 33 | IsTslEnabled | TINYINT | NO | 0 | CODE-BACKED | Trailing Stop Loss flag: 1 = trailing stop-loss is active (stop-loss rate follows favorable price movement), 0 = fixed stop-loss. Stored as IIF(ISNULL(@IsTslEnabled,0)=0,0,1) in OrdersAdd. |
| 34 | AmountInUnitsDecimal | DECIMAL(16,6) | YES | - | CODE-BACKED | Precise position size in decimal units. Added in FB 47233 (Aug 2017) to support fractional share trading. When NULL, the `GetOpenOrders` view computes it as `LotCountDecimal * Units`. |
| 35 | IsDiscounted | BIT | YES | - | CODE-BACKED | Whether the order receives a discounted fee/spread rate. 1 = discounted pricing applies, NULL/0 = standard pricing. Added for promotional or loyalty-based fee reductions. |
| 36 | IsSettled | BIT | YES | - | VERIFIED | Legacy settlement flag predating SettlementTypeID: 1 = real stock position (customer owns actual shares), 0/NULL = CFD (contract for difference). When SettlementTypeID is NULL, this flag is used as fallback. See Section 2.3. |
| 37 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | Whether the order has no stop-loss protection. 1 = order was explicitly placed without stop-loss, NULL = standard stop-loss rules apply. |
| 38 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | Whether the order has no take-profit target. 1 = order was explicitly placed without take-profit, NULL = standard take-profit rules apply. |
| 39 | SettlementTypeID | TINYINT | YES | - | VERIFIED | Settlement model classification. References `Dictionary.SettlementTypes`: 0=CFD, 1=REAL (stock ownership), 2=TRS (total return swap), 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Modern replacement for legacy `IsSettled` flag. See Section 2.3. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderTypeID | Dictionary.OrderType | FK | Explicit FK (FK_DORT_TORD). Classifies the type of trading operation (open, close, entry, exit, edit). |
| CID | Customer.Customer | Implicit | Customer who placed this order. |
| CurrencyID | Dictionary.Currency | Implicit | Currency denomination of the order amount. |
| ProviderID | Trade.Provider | Implicit | Liquidity provider for order execution. Used to look up current prices. |
| InstrumentID | Trade.Instrument | Implicit | Financial instrument being traded. Core business reference. |
| SpreadID | Trade.Spread | Implicit | Spread configuration applied to order pricing. |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit | Settlement model (CFD/REAL/TRS/etc.) for regulatory and custody classification. |
| ParentOrderID | Trade.Orders | Self-Reference | Copy-trade parent order. When non-zero, this order is a copy of the referenced order. |
| LastOpPriceRateID | Trade.CurrencyPrice | Implicit | Price rate snapshot at order creation time. |
| LastOpConversionRateID | Trade.CurrencyPrice | Implicit | Conversion rate snapshot at order creation time. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrders | FROM | View base table | Exposes all order columns with BIT-to-INT conversions for IsBuy and IsOverWeekend |
| Trade.GetOpenOrders | FROM | View base table | Joins to Customer.Customer for UserName; computes AmountInUnitsDecimal |
| Trade.OrdersAdd | INSERT | Writer | Creates new orders with price rate capture and validation |
| Trade.OrdersClose | DELETE/SELECT | Deleter | Moves order to History.Orders then deletes from this table |
| Trade.OrdersClientRemove | - | Deleter | Client-initiated order removal |
| Trade.OrdersServerRemove | - | Deleter | Server-initiated order removal |
| Trade.DetachFromParentOrder | - | Modifier | Unlinks copy-trade parent-child relationship |
| Trade.GetOrderDetails | SELECT | Reader | Retrieves order details for display |
| Trade.GetPendingOrders | SELECT | Reader | Lists pending orders awaiting execution |
| Trade.OpenOrdersSplit | SELECT | Reader | Handles order splitting for stock splits |
| Trade.GetAccountAssets | SELECT | Reader | Includes orders in account asset calculations |
| Trade.GetAccountAssetsForLiquidation | SELECT | Reader | Includes orders in liquidation assessment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Orders (table)
```

Tables are leaf nodes - no code-level dependencies to recurse.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OrderType | Table | Explicit FK target for OrderTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrders | View | SELECT * (base table) |
| Trade.GetOpenOrders | View | JOIN with Customer.Customer |
| Trade.OrdersAdd | Stored Procedure | INSERT (writer) |
| Trade.OrdersClose | Stored Procedure | SELECT + DELETE (mover to History.Orders) |
| Trade.OrdersClientRemove | Stored Procedure | DELETE (client removal) |
| Trade.OrdersServerRemove | Stored Procedure | DELETE (server removal) |
| Trade.GetOrderDetails | Stored Procedure | SELECT (reader) |
| Trade.GetPendingOrders | Stored Procedure | SELECT (reader) |
| Trade.OpenOrdersSplit | Stored Procedure | SELECT (stock split) |
| Trade.GetAccountAssets | Stored Procedure | SELECT (asset calc) |
| Trade.GetAccountAssetsForLiquidation | Stored Procedure | SELECT (liquidation) |
| Trade.DetachFromParentOrder | Stored Procedure | UPDATE/DELETE (copy-trade detach) |
| Trade.GetOrdersDataWithCIDForAPI | Stored Procedure | SELECT (API) |
| Trade.GetPortfolioAggregates | Stored Procedure | SELECT (portfolio) |
| Trade.RolloutAboveDollarPrecisionForOrders | Stored Procedure | UPDATE (precision migration) |
| Trade.DelistStock | Stored Procedure | SELECT (delisting) |
| Trade.DeleteOldOrderOnlyDemo | Stored Procedure | DELETE (demo cleanup) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Order | CLUSTERED | OrderID ASC | - | - | Active (FILLFACTOR=90) |
| IX_TradeOrders_CID | NONCLUSTERED | CID ASC | InstrumentID, Amount | - | Active |
| IX_instrumentID | NONCLUSTERED | InstrumentID ASC | StopLosRate | - | Active (FILLFACTOR=95) |
| TORD_ForexResultID | NONCLUSTERED | ForexResultID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Order | PRIMARY KEY | Clustered on OrderID. Ensures every order has a unique identifier. |
| FK_DORT_TORD | FOREIGN KEY | OrderTypeID -> Dictionary.OrderType(OrderTypeID). Ensures every order has a valid operation type. |
| CH_TradeOrders_Amount | CHECK | Amount > 0. Prevents zero or negative order amounts. |
| CH_TradeOrders_LotCountDecimal | CHECK | LotCountDecimal > 0. Prevents zero or negative lot counts. |
| DF_TradeOrders_IsTslEnabled | DEFAULT | IsTslEnabled = 0. Trailing stop-loss is disabled by default. |

---

## 8. Sample Queries

### 8.1 Find all open orders for a specific customer
```sql
SELECT  o.OrderID, o.InstrumentID, o.OrderTypeID, o.Amount, o.IsBuy,
        o.StopLosRate, o.TakeProfitRate, o.OccurredTime
FROM    Trade.Orders o WITH (NOLOCK)
WHERE   o.CID = @CID
ORDER BY o.OccurredTime DESC;
```

### 8.2 List pending entry orders with instrument and order type names
```sql
SELECT  o.OrderID, o.CID, i.InstrumentDisplayName,
        ot.Name AS OrderTypeName, o.Amount, o.RateFrom,
        o.IsBuy, o.OccurredTime
FROM    Trade.Orders o WITH (NOLOCK)
        INNER JOIN Trade.Instrument i WITH (NOLOCK)
            ON o.InstrumentID = i.InstrumentID
        INNER JOIN Dictionary.OrderType ot WITH (NOLOCK)
            ON o.OrderTypeID = ot.OrderTypeID
WHERE   o.OrderTypeID IN (4, 5, 6, 7, 13, 16)
ORDER BY o.OccurredTime DESC;
```

### 8.3 Find copy-trade child orders with parent and settlement info
```sql
SELECT  o.OrderID, o.ParentOrderID, o.CID, o.InstrumentID,
        o.Amount, o.Leverage, o.IsBuy,
        st.SettlementType,
        o.LastOpPriceRate, o.OccurredTime
FROM    Trade.Orders o WITH (NOLOCK)
        LEFT JOIN Dictionary.SettlementTypes st WITH (NOLOCK)
            ON o.SettlementTypeID = st.SettlementTypeID
WHERE   o.ParentOrderID > 0
ORDER BY o.OccurredTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 8.7/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Orders | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Orders.sql*
