# History.Orders

> Archive table for closed pending orders on eToro's trading platform. When a pending order in Trade.Orders is removed (cancelled by client, cancelled by server, or filled/converted to a position), it is moved here atomically: inserted into History.Orders then deleted from Trade.Orders. Provides a complete historical record of all pending orders and their outcome (cancel reason or conversion type).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrderID (int, PK - not IDENTITY, allocated by Internal.GetOrderID sequence) |
| **Partition** | No - ON [HISTORY] filegroup |
| **Indexes** | 1 (CLUSTERED PK on OrderID) |

---

## 1. Business Meaning

This table holds the complete history of closed pending orders. On eToro, customers can place pending orders (limit orders, market orders, stop orders) that sit in `Trade.Orders` waiting for execution conditions to be met. When an order is closed - whether by the client cancelling it, the server removing it, or it being filled and converted to a live position - `Trade.OrdersClose` (or the client/server remove variants) atomically moves the row from `Trade.Orders` to `History.Orders`, stamping `CloseOcurred` = GETDATE() and `ActionTypeID` = the close reason.

The table has 7,359 rows active from 2010 to March 2026. `ActionTypeID`=1 (ClientRemove / cancelled by client) accounts for 90% of records. `ActionTypeID`=5 (ConvertedToOrderForOpen) accounts for 7%, and `ActionTypeID`=2 (ConvertedToPosition / order filled) for 2%.

`ForexResultID` is hardcoded to -1 in `Trade.OrdersAdd` - per the SP comment, the column "is not being used anymore." All recent rows confirm ForexResultID=-1.

`History.GetOrders` is a simple pass-through view exposing this table to downstream consumers. `History.OrdersEntry` and `History.OrdersExit` join the companion detail tables (`History.OrdersEntryTbl`, `History.OrdersExitTbl`) with records from this table to provide full order snapshots.

**Note**: The column naming in Trade.Orders vs History.Orders differs slightly: Trade.Orders uses `OccurredTime` for the open timestamp; History.Orders uses `OpenOccurred`. This mapping is visible in Trade.OrdersClose: `OccurredTime, --> OpenOccurred`.

---

## 2. Business Logic

### 2.1 Archive-on-Close Pattern

**What**: Trade.Orders is the live pending orders table. History.Orders is its closed-order archive. All closures go through the same atomic pattern.

**Columns/Parameters Involved**: `OrderID`, `ActionTypeID`, `OpenOccurred`, `CloseOcurred`

**Rules**:
```
Trade.OrdersClose (or ClientRemove / ServerRemove):
  BEGIN TRANSACTION
    INSERT INTO History.Orders SELECT * FROM Trade.Orders WHERE OrderID = @OrderID
    -- Set CloseOcurred = GETDATE(), ActionTypeID = @ActionTypeID
    DELETE FROM Trade.Orders WHERE OrderID = @OrderID
  COMMIT
```
- OrderID is preserved from the source row (not re-generated)
- `CloseOcurred` is set to GETDATE() at archive time
- `OpenOccurred` is copied from Trade.Orders.OccurredTime (the original insert timestamp)
- ActionTypeID identifies WHY the order was closed

### 2.2 ActionTypeID - Close Reason (FK to Dictionary.OrdersActionType)

**What**: Records the business reason why the order left Trade.Orders.

**Columns/Parameters Involved**: `ActionTypeID`

**Rules** (Dictionary.OrdersActionType):

| ActionTypeID | ActionName | Description | Count |
|-------------|-----------|-------------|-------|
| 1 | ClientRemove | Client cancelled the pending order before execution | 6,654 |
| 2 | ConvertedToPosition | Order was filled - execution converted it to a live position in Trade.PositionTbl | 173 |
| 3 | ManualBackOffice | Back-office manual removal (not seen in current data) | 0 |
| 4 | ClientCreated | (Not applicable to History.Orders - this is the creation action, not archival) | 0 |
| 5 | ConvertedToOrderForOpen | Order converted to an "order for open" type (pre-execution state change) | 532 |

### 2.3 OrderID Sequence Allocation

**What**: OrderIDs are not IDENTITY columns - they are allocated from a shared sequence.

**Columns/Parameters Involved**: `OrderID`

**Rules**:
- Trade.OrdersAdd calls `EXECUTE Internal.GetOrderID @OrderID OUTPUT` to allocate the ID
- The same OrderID is preserved when moving from Trade.Orders to History.Orders
- This means OrderIDs in History.Orders and Trade.PositionTbl (for ConvertedToPosition) may share a sequence space
- Observed range: 93 to 24,360,007 (orders placed over 15+ years)

### 2.4 Rate Capture Pattern

**What**: Both the order-open rate (RateFrom) and the last-observed rate at close time (RateTo) are captured. Conversion rate context is also stored.

**Columns/Parameters Involved**: `RateFrom`, `RateTo`, `LastOpPriceRate`, `LastOpPriceRateID`, `LastOpConversionRate`, `LastOpConversionRateID`

**Rules**:
- `RateFrom` = the rate at which the order was placed (the trigger rate, e.g., limit price)
- `RateTo` = the rate at which the order was closed (market rate at close time)
- `LastOpPriceRate` / `LastOpPriceRateID` = the most recent price quote from `Trade.CurrencyPrice` at order-open time, identified by provider+instrument
- `LastOpConversionRate` / `LastOpConversionRateID` = the USD conversion rate for the instrument's sell currency at order-open time. Set to 0 if the instrument is major (IsMajor=1) or if SellCurrencyID=1 (USD, no conversion needed)
- All rate columns use the `dbo.dtPrice` UDT (decimal precision type)

---

## 3. Data Overview

| OrderID | CID | InstrumentID | ActionTypeID | IsBuy | Amount | RateFrom | RateTo | OpenOccurred | CloseOcurred | Meaning |
|---------|-----|-------------|-------------|-------|--------|----------|--------|-------------|-------------|---------|
| 24360007 | 14866508 | 1144 | 1 (ClientRemove) | Buy | $12,463 | 124.63 | 125.38 | 2026-03-17 | 2026-03-17 | Order opened and cancelled within seconds (16s) on InstrumentID=1144 |
| 24338007 | 14952810 | 1144 | 1 (ClientRemove) | Sell | $12,463 | 124.63 | 125.38 | 2026-03-17 | 2026-03-17 | Sell-side counterpart cancelled on same day |
| 93 | (oldest) | (various) | (various) | (various) | - | - | - | 2010-06-06 | - | Oldest archived order, from the platform's early trading history |

**Distribution summary**: 7,359 total rows; 316 distinct copier CIDs; 189 distinct instruments; 1 provider (ProviderID consistent). SettlementTypeID=1 (settled, 37%), SettlementTypeID=0 (not settled, 35%), NULL (28%). All recent rows have Leverage=1 (unleveraged, Free Stocks / no-leverage instruments per FB 53719).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Pending order identifier, allocated by Internal.GetOrderID sequence (not IDENTITY). Preserved from Trade.Orders on archival. Primary key. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID of the order owner. FK (implicit) to Customer.Customer.CID. Nullable for legacy rows where the customer context was lost. |
| 3 | CurrencyID | int | YES | - | CODE-BACKED | Currency denomination of the order amount. FK (implicit) to Dictionary.Currency. Determines the account currency context for the order. |
| 4 | ProviderID | int | YES | - | CODE-BACKED | Price provider/broker that was routing rates for this order. FK (implicit) to Trade.Provider. Only 1 distinct ProviderID in current data. |
| 5 | OrderTypeID | int | YES | - | NAME-INFERRED | Type/subtype of the pending order. Observed values: 0 (83%, standard), 15 (15%, likely market order), 4 (1.2%), 6, 5, 7. No FK constraint to a lookup table in this schema. |
| 6 | InstrumentID | int | YES | - | CODE-BACKED | The trading instrument for the order. FK (implicit) to Trade.Instrument. 189 distinct instruments observed. |
| 7 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier applied to the order (e.g., 1=no leverage, 2=2x, etc.). All recent rows have Leverage=1, consistent with the Free Stocks / no-leverage instrument rollout (FB 53719). |
| 8 | Amount | money | YES | - | CODE-BACKED | Order size in the account currency (USD for most accounts). Validated > 0 in Trade.OrdersAdd (RAISERROR 60078 if Amount <= 0). Stored as SQL Server money type (4 decimal places). |
| 9 | Units | int | YES | - | CODE-BACKED | Number of instrument units in the order. Passed directly from Trade.OrdersAdd @Units parameter. |
| 10 | UnitMargin | int | YES | - | NAME-INFERRED | Margin required per unit for this order. Integer value likely in cents. Exact derivation is system-internal. |
| 11 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size expressed in lots (decimal precision). Added in FB 47233. Complement to Units for fractional lot handling. |
| 12 | RateFrom | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate at which the order was placed (the trigger/limit rate). Uses dbo.dtPrice UDT. For the most recent rows, RateFrom = 124.63 (InstrumentID=1144 price). |
| 13 | RateTo | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate at order close time. Uses dbo.dtPrice UDT. Compared against RateFrom to determine execution quality. |
| 14 | IsBuy | bit | YES | - | CODE-BACKED | Direction: 1=Buy (long), 0=Sell (short). Both directions observed in current data. |
| 15 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy link to History.ForexResult. Hardcoded to -1 in Trade.OrdersAdd per the comment "ForexResultID is not being used anymore." All recent rows have ForexResultID=-1. |
| 16 | GameID | int | YES | - | NAME-INFERRED | Legacy game/contest identifier. Linked to the eToro gaming platform (Game schema). 0 or NULL for all modern trading orders; historically non-zero for contest/game participation. |
| 17 | SpreadID | int | YES | - | NAME-INFERRED | Spread configuration identifier applied to this order at placement time. Links to spread pricing rules. 0 for most rows. |
| 18 | LoginID | int | YES | - | NAME-INFERRED | Login account identifier associated with the order. Distinct from CID (customer); LoginID represents the specific trading account login. 0 for most rows. |
| 19 | IsOverWeekend | bit | YES | - | CODE-BACKED | Whether the order was opened over a weekend (and thus subject to weekend financing charges). Set in Trade.OrdersAdd. |
| 20 | StopLosAmount | int | YES | - | CODE-BACKED | Stop-loss amount threshold in account currency units. Note the column name typo: "StopLos" vs "StopLoss" (consistent across Trade.Orders and History.Orders). 0 = no stop-loss amount set. |
| 21 | TakeProfitAmount | int | YES | - | CODE-BACKED | Take-profit amount threshold in account currency units. 0 = no take-profit amount set. |
| 22 | MarketSpreadPips | int | YES | - | NAME-INFERRED | The market spread at order placement, measured in pips. Used for spread cost calculation. 0 for most rows. |
| 23 | MarketSpreadCents | int | YES | - | NAME-INFERRED | The market spread at order placement, measured in cents. Alternative spread representation for non-pip instruments. 0 for most rows. |
| 24 | StopLosRate | dbo.dtPrice | YES | - | CODE-BACKED | The specific rate at which the stop-loss would trigger. Uses dbo.dtPrice UDT. NULL/0 if no stop-loss rate was set. |
| 25 | TakeProfitRate | dbo.dtPrice | YES | - | CODE-BACKED | The specific rate at which the take-profit would trigger. Uses dbo.dtPrice UDT. NULL/0 if no take-profit rate was set. |
| 26 | OpenOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the order was originally placed (copied from Trade.Orders.OccurredTime at archival). Maps to the creation time in the live order table. |
| 27 | CloseOcurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the order was closed/archived (set to GETDATE() by Trade.OrdersClose). Note: column name has typo - "CloseOcurred" is missing an 's' (consistent with Trade.Orders DDL). |
| 28 | TradeRange | int | YES | - | NAME-INFERRED | Maximum acceptable pip/tick deviation from the requested rate for order execution. Passed from Trade.OrdersAdd @TradeRange. |
| 29 | ActionTypeID | int | YES | - | CODE-BACKED | Why the order was archived. FK WITH CHECK to Dictionary.OrdersActionType. Values: 1=ClientRemove (dominant), 2=ConvertedToPosition, 3=ManualBackOffice, 5=ConvertedToOrderForOpen. |
| 30 | ParentOrderID | int | YES | - | CODE-BACKED | For copy-trading orders: the parent order in the REAL environment that this demo order was following. 0=no parent. ISNULL(@ParentOrderID,0) > 0 check in Trade.OrdersClose triggers Trade.DetachFromParentOrder logic for demo environments. |
| 31 | LastOpPriceRate | dbo.dtPrice | YES | - | CODE-BACKED | The mid-price (Bid+Ask)/2 from Trade.CurrencyPrice at order-open time, for the order's provider+instrument. Uses dbo.dtPrice UDT. Enables post-hoc reconstruction of the market price at order submission. |
| 32 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | The Trade.CurrencyPrice.PriceRateID for the LastOpPriceRate snapshot. Allows exact rate record to be traced if the price history is retained. |
| 33 | LastOpConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | The USD conversion rate for the instrument's quote currency at order-open time. 0 for major instruments (IsMajor=1) and USD-denominated instruments (SellCurrencyID=1). Enables PnL normalization to USD. |
| 34 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | The Trade.CurrencyPrice.PriceRateID for the LastOpConversionRate snapshot. |
| 35 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Whether trailing stop-loss (TSL) was enabled for this order. DEFAULT=0 (disabled). Added in FB 34563. Values: 0=disabled, 1=enabled. |
| 36 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | The order amount expressed in fractional units (decimal precision). Added in FB 47233 for instruments where amount/units conversion requires decimal precision. |
| 37 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a discounted spread was applied to this order. Added in FB 53719 (Free Stocks). Enables spread discount tracking for eligible customers. |
| 38 | IsSettled | bit | YES | - | CODE-BACKED | Whether the order has been settled (funds transferred/reconciled). true=settled (37%), false=not settled (35%), NULL=unknown/legacy (28%). Added in FB 53719. |
| 39 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | The settlement method used. Observed values: 0=unsettled/cash, 1=settled (regular), 5=special settlement type. NULL for legacy rows. Added in FB 53719. |
| 40 | IsNoStopLoss | bit | YES | - | CODE-BACKED | Explicitly marks the order as having no stop-loss configured (as opposed to StopLosAmount=0 which could be ambiguous). NULL for older rows predating this column. |
| 41 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | Explicitly marks the order as having no take-profit configured (as opposed to TakeProfitAmount=0 which could be ambiguous). NULL for older rows predating this column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Dictionary.OrdersActionType | ActionTypeID | FK WITH CHECK (FK_DOAT_HIOR) | Why this order was closed. 5 values: ClientRemove, ConvertedToPosition, ManualBackOffice, ClientCreated, ConvertedToOrderForOpen. |
| Trade.Instrument | InstrumentID | Implicit FK (no constraint) | The trading instrument for the order. |
| Dictionary.Currency | CurrencyID | Implicit FK (no constraint) | The account currency denomination. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrdersClose | OrderID | Writer (archive-on-close) | Primary writer: SELECT from Trade.Orders + INSERT here + DELETE from Trade.Orders, in a single transaction |
| Trade.OrdersClientRemove | OrderID | Writer (via OrdersClose) | Client-side cancel; calls OrdersClose with ActionTypeID=1 |
| Trade.OrdersServerRemove | OrderID | Writer (via OrdersClose) | Server-side cancel; calls OrdersClose with appropriate ActionTypeID |
| History.GetOrders | * | View | Pass-through view of this table (subset of columns, excludes settlement/TSL columns) |
| History.OrdersEntry | OrderID | View join | Joins History.Orders with History.OrdersEntryTbl for entry detail |
| History.OrdersExit | OrderID | View join | Joins History.Orders with History.OrdersExitTbl for exit detail |
| BackOffice.GetCustomerClosedOrders | OrderID | Read | Back-office lookup of closed orders by customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Orders (table)
- Written by: Trade.OrdersClose (primary)
  - SELECT FROM Trade.Orders -> INSERT History.Orders -> DELETE Trade.Orders
- Read by: History.GetOrders (view), BackOffice.GetCustomerClosedOrders (SP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OrdersActionType | Table | FK WITH CHECK on ActionTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetOrders | View | Pass-through SELECT with NOLOCK |
| History.OrdersEntry | View | JOIN with History.OrdersEntryTbl for full entry snapshot |
| History.OrdersExit | View | JOIN with History.OrdersExitTbl for full exit snapshot |
| BackOffice.GetCustomerClosedOrders | SP | Customer closed-order lookup |
| dbo.SSRS_CS_History_OrdersEntry | SP | SSRS reporting query |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HIOR | CLUSTERED | OrderID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, HISTORY filegroup) |

No non-clustered indexes on this table. Lookup by CID requires a full scan (or use the views which may join with indexed tables).

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_HIOR | PRIMARY KEY | OrderID ASC - clustered |
| FK_DOAT_HIOR | FOREIGN KEY WITH CHECK | ActionTypeID -> Dictionary.OrdersActionType(ActionTypeID) |
| DF_HistoryOrders_IsTslEnabled | DEFAULT | IsTslEnabled = 0 |

---

## 8. Sample Queries

### 8.1 Closed orders for a customer with outcomes

```sql
SELECT
    h.OrderID,
    h.InstrumentID,
    h.IsBuy,
    h.Amount,
    h.Leverage,
    h.RateFrom,
    h.RateTo,
    oat.ActionName AS CloseReason,
    h.OpenOccurred,
    h.CloseOcurred,
    DATEDIFF(SECOND, h.OpenOccurred, h.CloseOcurred) AS LifetimeSeconds,
    h.IsSettled,
    h.SettlementTypeID
FROM History.Orders h WITH (NOLOCK)
JOIN Dictionary.OrdersActionType oat WITH (NOLOCK) ON oat.ActionTypeID = h.ActionTypeID
WHERE h.CID = @CID
ORDER BY h.CloseOcurred DESC;
```

### 8.2 Filled orders (converted to positions) in a time window

```sql
SELECT
    h.OrderID,
    h.CID,
    h.InstrumentID,
    h.Amount,
    h.RateFrom,
    h.RateTo,
    h.OpenOccurred,
    h.CloseOcurred
FROM History.Orders h WITH (NOLOCK)
WHERE h.ActionTypeID = 2  -- ConvertedToPosition
  AND h.CloseOcurred >= @StartDate
  AND h.CloseOcurred <  @EndDate
ORDER BY h.CloseOcurred DESC;
```

---

## 9. Atlassian Knowledge Sources

- **Confluence**: Page "History.Orders" (ID 2089320531) found in search but access is restricted (parent page view is restricted - cannot read content).
- **Confluence**: Page "Trade.OrdersClientRemove" (ID 13795229771) found in search - not read (access not verified).

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.8/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence (access restricted) + 0 Jira | Procedures: 2 analyzed (Trade.OrdersAdd, Trade.OrdersClose) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Orders | Type: Table | Source: etoro/etoro/History/Tables/History.Orders.sql*
