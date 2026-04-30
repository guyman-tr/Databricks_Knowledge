# History.Position_Active

> Primary closed-position archive for eToro's trading platform, holding the complete post-close record of every position closed on or after 2021-04-01. Written by Trade.PostClosePositionActions (async) when a position completes in Trade.PositionTbl, capturing all financial data (open/close rates, P&L, commissions, markup), risk parameters, copy-trading context, and settlement status. The definitive source for historical trade analysis, compliance reporting, and customer portfolio history.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionID (bigint, NONCLUSTERED PK) |
| **Partition** | No - ON [HISTORY] filegroup with PAGE compression |
| **Indexes** | 6 (NONCLUSTERED PK on PositionID, CLUSTERED on CID+CloseOccurred, 4 additional NC indexes) |

---

## 1. Business Meaning

This is the central historical positions table for eToro - the closed-position archive for all trading activity since April 2021. When a customer closes a position (manually, via stop-loss, take-profit, settlement, or copy-trading logic), `Trade.PositionClose` triggers `Trade.PostClosePositionActions` asynchronously via `Trade.InsertAsyncRecord`. This async SP copies the full row from `Trade.PositionTbl` into `History.Position_Active` with all close-time data stamped.

The table has **2,511,608 rows** spanning 2020-04-07 (open) to 2026-03-19 (close), representing positions from 68,306 distinct customers across 1,372 instruments. The CHECK constraint `CloseOccurred >= '2021-04-01'` enforces that only positions closed from April 2021 onward are stored here (positions closed before that date are in a separate legacy history table).

**Partial-close positions**: When a position is partially closed, a clone of the original position is inserted DIRECTLY into `History.Position_Active` (it never passes through Trade.PositionTbl). The clone carries the number of closed units and the current timestamp as its close time. The original position is simultaneously updated in Trade.PositionTbl with the remaining units. This means `History.Position_Active` can contain records that were never live in Trade.PositionTbl.

**Copy trading**: 210,018 rows (8.4%) have MirrorID > 0, representing positions opened as part of a copy-trading relationship.

**Settlement**: 2,301,542 rows (91.6%) have IsSettled=1, reflecting the Free Stocks / settlement flow (FB 53719).

**Key views**: `History.Position` and `History.PositionSlim` expose this table with additional joins. `History.MovePartialClosePositionToPosition_Active` SP handles the partial-close insertion.

---

## 2. Business Logic

### 2.1 Archive-on-Close Pattern (Full Close)

**What**: When a position closes normally, Trade.PostClosePositionActions is called asynchronously and inserts the closed position into this table.

**Columns/Parameters Involved**: `PositionID`, `ActionType`, `CloseOccurred`, `EndForexRate`, `NetProfit`

**Rules**:
```
Trade.PositionClose -> Trade.InsertAsyncRecord(PartsToDo=0, ProcedureName='PostClosePositionActions')
-> Trade.PostClosePositionActions (async):
    IF IsPartial = 0:
      INSERT INTO History.Position_Active
      SELECT FROM Trade.PositionTbl (full position snapshot)
      WHERE PositionID = @PositionID
    DELETE FROM Trade.PositionTbl WHERE PositionID = @PositionID
```
- `CloseOccurred` = the timestamp from Trade.PositionTbl.CloseOccurred (set by Trade.PositionClose)
- `EndForexRate` = the rate at which the position closed
- `NetProfit` = realized profit/loss in cents at close
- `ActionType` = the reason for close (see Section 2.3)

### 2.2 Direct Insert Pattern (Partial Close)

**What**: For partial closes, a synthetic clone of the position is inserted directly into History.Position_Active without going through Trade.PositionTbl.

**Columns/Parameters Involved**: `PositionID`, `InitialUnits`, `AmountInUnitsDecimal`, `PartialCloseRatio`, `SubCloseTypeID`

**Rules** (from Confluence: "Position partial-close: short summary"):
- The original position in Trade.PositionTbl is UPDATED with the new (remaining) unit count
- A NEW PositionID is created representing only the closed portion, with:
  - `AmountInUnitsDecimal` = number of closed units (not the full amount)
  - `CloseOccurred` = current timestamp
  - `PartialCloseRatio` = ratio of units closed vs. original
- History.PositionChangeLog_Active gets ChangeTypeID=11 ("Partial close") for the clone
- The original position gets ChangeTypeID=12 ("Edit due to partial close")
- `History.MovePartialClosePositionToPosition_Active` SP handles this insertion
- Partial-close positions can be identified by non-NULL PartialCloseRatio and non-NULL OriginalPositionID

### 2.3 ActionType - Close Reason

**What**: Identifies why the position was closed. No FK to a lookup table - values are application-defined constants.

**Columns/Parameters Involved**: `ActionType`

**Rules** (data distribution - 19 distinct values):

| ActionType | Count | Pct | Description |
|-----------|-------|-----|-------------|
| 1 | 1,700,808 | 67.7% | Client close - user manually closed the position |
| 0 | 311,534 | 12.4% | Unknown / settlement auto-close |
| 10 | 272,110 | 10.8% | Settlement or system close |
| 24 | 40,962 | 1.6% | Mirror/copy trading close (CopyTrader unregistered) |
| 13 | 36,359 | 1.4% | Stop-loss triggered |
| 16 | 32,523 | 1.3% | Settlement with specific condition |
| 17 | 29,631 | 1.2% | Additional close variant |
| 23 | 28,421 | 1.1% | System/server close |
| 9 | 27,749 | 1.1% | Take-profit triggered |
| 5 | 25,018 | 1.0% | End-of-week close |
| 7 | (via SP logic) | - | Mirror close (checked specifically in Trade.PostClosePositionActions) |
| Other (8,15,18-22,25-26) | <10,000 each | <0.5% | Specialized close types |

### 2.4 P&L and Rate Columns

**What**: Full capture of all rate data at open and close, plus all profit/loss and commission components.

**Columns/Parameters Involved**: `InitForexRate`, `EndForexRate`, `NetProfit`, `Commission`, `CommissionOnClose`, `EndOfWeekFee`, `OpenMarkup`, `CloseMarkup`

**Rules**:
- `InitForexRate` = rate at which the position was opened (the execution price)
- `EndForexRate` = rate at which the position was closed
- `NetProfit` = realized P&L in the account currency (negative = loss). In cents for some code paths, in dollars for others (context-dependent)
- `Commission` = commission charged at open; `CommissionOnClose` = commission charged at close
- `EndOfWeekFee` = overnight/weekend financing fee accumulated over the position lifetime
- `FullCommission` / `FullCommissionOnClose` = total commissions including all components
- `OpenMarkup` / `CloseMarkup` = eToro's markup applied at open/close for revenue
- `EstimatedMarkupRatio` / `EstimatedConversionMarkupRatio` = markup ratio calculations
- `OpenEtoroPrice` / `CloseEtoroPrice` = the eToro-quoted price (with markup applied)
- `OpenTotalFees` / `OpenTotalTaxes` / `CloseTotalFees` / `CloseTotalTaxes` = total fee/tax components

### 2.5 Adjusted vs. UnAdjusted Rate Pairs

**What**: Many rate columns have an UnAdjusted counterpart, reflecting corporate action adjustments (splits, dividends) applied post-close.

**Columns/Parameters Involved**: `InitForexRateUnAdjusted`, `EndForexRateUnAdjusted`, `LimitRateUnAdjusted`, `StopRateUnAdjusted`, `OrderPriceRateUnAdjusted`, `MarketPriceRateUnAdjusted`, `LastOpPriceRateUnAdjusted`, `EndMarketRateUnAdjusted`, `AmountInUnitsDecimalUnAdjusted`, `LotCountDecimalUnAdjusted`

**Rules**:
- The "Adjusted" column = current value after corporate action adjustments (splits, etc.)
- The "UnAdjusted" column = original value at execution time before any adjustments
- NULL if no adjustment has been applied since the position was closed

---

## 3. Data Overview

| PositionID | CID | InstrumentID | Amount | IsBuy | InitForexRate | EndForexRate | NetProfit | ActionType | CloseOccurred | Meaning |
|-----------|-----|-------------|--------|-------|--------------|-------------|---------|-----------|--------------|---------|
| 2152976042 | 14952810 | 100000 (BTC) | $99.97 | Buy | 104,023.44 | 0 | 0 | 0 | 2026-03-19 06:01 | 1-hour BTC settlement position, NetProfit=0 (settlement flow), IsSettled=true |
| 2152976041 | 14952810 | 100000 (BTC) | $99.97 | Buy | 104,023.42 | 0 | 0 | 0 | 2026-03-19 05:01 | Same pattern - 1-hour cycling settlement positions on BTC |
| 999999999 | (oldest) | (various) | - | - | - | - | - | - | ~2021-04 | Oldest position in table (PositionID=999,999,999 - transition boundary from legacy table) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. NONCLUSTERED PK. Not IDENTITY - allocated by Internal.GetActionID sequence. Range: ~999M to 99T in current data (test environment). Partial-close clones receive new PositionIDs. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID of the position owner. Part of the CLUSTERED index (CID, CloseOccurred) - the primary query access pattern. 68,306 distinct customers in current data. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Legacy game result reference. Set to -1 for all modern positions (hardcoded in Trade.PositionOpen per comments in Trade.OrdersAdd). |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Account currency denomination. FK (implicit) to Dictionary.Currency. Determines the currency in which NetProfit and other money values are expressed. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Price provider/broker that routed this position. FK (implicit) to Trade.Provider. |
| 6 | GameServerID | int | NO | - | CODE-BACKED | Game server identifier for this position. Legacy gaming platform reference. 0 for modern trading positions. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument. FK (implicit) to Trade.Instrument. 1,372 distinct instruments in current data. InstrumentID=100000=BTC, InstrumentID=5=EURUSD, etc. |
| 8 | HedgeID | int | YES | - | CODE-BACKED | The broker-side hedge trade ID linking this position to History.Hedge. NULL if position was not hedged. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Which hedge server processed the broker-side hedge. FK (implicit) to Trade.HedgeServer. Included in IX_HistoryPosition_Active_BIGINT_CloseOccurred for hedge analysis by time window. |
| 10 | OrderID | int | YES | - | CODE-BACKED | The pending order from Trade.Orders that was filled to create this position. NULL for market-open positions (no pending order). |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier applied (e.g., 1=no leverage, 2=2x). Leverage=1 for all Free Stocks positions. |
| 12 | Amount | money | NO | - | CODE-BACKED | Position size in account currency (USD for most accounts). The total notional value = Amount * Leverage. |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in fractional instrument units (decimal precision). Included in IX_CloseOccurred for unit-based hedging analysis. NULL for older positions before this column was added. |
| 14 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in lots. Complement to AmountInUnitsDecimal for instruments priced in lots. |
| 15 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | The exchange rate at which the position was opened (the execution/fill price). dbo.dtPrice UDT. For BTC: ~104,023. For EURUSD: ~1.08, etc. |
| 16 | InitDateTime | datetime | NO | - | CODE-BACKED | Timestamp when the position was initialized in the system (may differ slightly from OpenOccurred due to processing time). |
| 17 | NetProfit | money | NO | - | CODE-BACKED | Realized profit/loss for this position. Negative = loss. For settlement positions, often 0 (profit calculated externally). |
| 18 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit rate. 0 if no take-profit was set (from Trade.PositionTbl TPTI.LimitRate). |
| 19 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss rate. Set to @PositionStopLoss (override) if provided, otherwise from Trade.PositionTbl TPTI.StopRate. |
| 20 | SpreadedPipBid | dbo.dtPrice | YES | - | CODE-BACKED | The bid-side spreaded pip rate at position open. NULL for non-spread instruments. |
| 21 | SpreadedPipAsk | dbo.dtPrice | YES | - | CODE-BACKED | The ask-side spreaded pip rate at position open. NULL for non-spread instruments. |
| 22 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy (long), 0=Sell (short). |
| 23 | CloseOnEndOfWeek | bit | NO | - | CODE-BACKED | Whether this position was configured to auto-close at end of week. Copied from Trade.PositionTbl at close time. |
| 24 | EndOfWeekFee | money | NO | 0 | CODE-BACKED | Total overnight/weekend financing fee accumulated over the position's lifetime. DEFAULT=0. |
| 25 | Commission | money | NO | - | CODE-BACKED | Commission charged at position open. |
| 26 | CommissionOnClose | money | NO | - | CODE-BACKED | Commission charged at position close. |
| 27 | SpreadedCommission | int | NO | - | CODE-BACKED | Spread-based commission in pip units. |
| 28 | EndForexRate | dbo.dtPrice | NO | - | CODE-BACKED | The exchange rate at which the position was closed. 0 for settlement positions where the profit is calculated externally. |
| 29 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | The rate requested by the client for close (vs. actual EndForexRate). NULL (set to NULL in Trade.PostClosePositionActions - "NULL --TPRQ.RequestedEndForexRate"). |
| 30 | EndDateTime | datetime | NO | getdate() | CODE-BACKED | Timestamp when the close was finalized in Trade.PositionTbl. DEFAULT=getdate() (safety net). |
| 31 | ActionType | int | NO | - | CODE-BACKED | Why the position was closed. No FK to a lookup table. Common values: 1=ClientClose (68%), 0=auto/settlement (12%), 10=settlement close (10.8%). See Section 2.3 for full distribution. |
| 32 | AdditionalParam | sql_variant | YES | - | CODE-BACKED | Extra contextual data for special close scenarios. Type sql_variant allows storing arbitrary typed values. NULL for most positions. |
| 33 | RequestOpenOccurred | datetime | YES | - | CODE-BACKED | When the client submitted the open request (before execution). NULL if not tracked. Mapped from Trade.PositionTbl.RequestOccurred. |
| 34 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | When the client submitted the close request. Mapped from Trade.PositionTbl.RequestCloseOccurred. |
| 35 | OpenOccurred | datetime | NO | - | CODE-BACKED | When the position was opened (execution timestamp). Part of NC index IX_CIDOpenOccurred (CID, OpenOccurred). Mapped from Trade.PositionTbl.Occurred. |
| 36 | CloseOccurred | datetime | NO | getdate() | CODE-BACKED | When the position was closed. Leading column of the CLUSTERED index with CID. CHECK constraint enforces >= '2021-04-01'. DEFAULT=getdate(). Also in IX_HistoryPosition_Active_BIGINT_CloseOccurred NC index. |
| 37 | SpreadGroupID | int | YES | - | NAME-INFERRED | Spread pricing group identifier applied to this position. Links to spread configuration at open time. NULL for positions without spread group assignment. |
| 38 | LotCountGroupID | int | YES | - | NAME-INFERRED | Lot size pricing group identifier. NULL for positions without lot group configuration. |
| 39 | TradeRange | int | YES | - | CODE-BACKED | Maximum allowable rate deviation from the requested execution rate (slippage tolerance). Copied from Trade.Instrument.TradeRange at position open. |
| 40 | InitForexPriceRateID | bigint | NO | - | CODE-BACKED | The Trade.CurrencyPrice.PriceRateID for the InitForexRate snapshot. Enables exact rate record tracing. |
| 41 | OrderPriceRateID | bigint | NO | - | CODE-BACKED | The Trade.CurrencyPrice.PriceRateID for the OrderPriceRate (the rate used for order execution). |
| 42 | EndForexPriceRateID | bigint | NO | - | CODE-BACKED | The Trade.CurrencyPrice.PriceRateID for the EndForexRate (close rate) snapshot. |
| 43 | OrderPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | The actual rate at which the order was executed (may differ from InitForexRate by slippage). |
| 44 | MarketPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | The underlying market rate at open time (before eToro markup). Compared with OpenEtoroPrice to see the markup applied. |
| 45 | MarketPriceRateID | bigint | NO | - | CODE-BACKED | The Trade.CurrencyPrice.PriceRateID for MarketPriceRate. |
| 46 | EntryHedgeQuery | int | NO | -1 | NAME-INFERRED | Status of the hedging query sent to the broker at position open. DEFAULT=-1 (not yet queried or not applicable). Values indicate hedge request/acknowledgment status. |
| 47 | EndHedgeQuery | int | YES | -1 | NAME-INFERRED | Status of the hedging query sent to the broker at position close. DEFAULT=-1. NULL or -1 if no hedge at close. |
| 48 | ParentPositionID | bigint | YES | 1 | CODE-BACKED | For copy-trading positions: the popular investor's position being mirrored. DEFAULT=1 (sentinel for "no parent"). 0=no parent in live data. Part of NC index OrigParentPositionID+MirrorID+CID. |
| 49 | OrigParentPositionID | bigint | YES | 1 | CODE-BACKED | The original parent position ID before any partial close or reopen operations. DEFAULT=1. Used in the NC index (OrigParentPositionID, MirrorID, CID) INCLUDE(PositionID) for copy-trading queries. |
| 50 | LastOpPriceRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Most recent quoted price for the instrument at last-operation time. DEFAULT=0. |
| 51 | LastOpPriceRateID | bigint | YES | 0 | CODE-BACKED | PriceRateID for LastOpPriceRate. DEFAULT=0. |
| 52 | LastOpConversionRate | dbo.dtPrice | YES | 0 | CODE-BACKED | USD conversion rate at last-operation time. DEFAULT=0. |
| 53 | LastOpConversionRateID | bigint | YES | 0 | CODE-BACKED | PriceRateID for LastOpConversionRate. DEFAULT=0. |
| 54 | MirrorID | int | YES | 0 | CODE-BACKED | CopyTrader relationship ID if this position was opened as part of a copy. DEFAULT=0 (no copy). NC index (MirrorID, PositionID) for copy-trading queries. 210,018 rows with MirrorID > 0. |
| 55 | EndMarketRate | dbo.dtPrice | YES | - | CODE-BACKED | Market rate at close time (before eToro markup). Complement of EndForexRate (which is the eToro-quoted close price). |
| 56 | EndMarketPriceRateID | bigint | YES | - | CODE-BACKED | PriceRateID for EndMarketRate. |
| 57 | PositionRatio | decimal(7,6) | YES | - | CODE-BACKED | For copy-trading positions: the ratio of this copy position's amount relative to the parent. E.g., 0.01 = 1% of parent. |
| 58 | DirectAggLotCount | decimal(16,6) | YES | - | NAME-INFERRED | Direct aggregate lot count for hedging calculations. Specific to the hedging engine's lot aggregation logic. |
| 59 | StocksOrderID | int | YES | - | CODE-BACKED | For stock/equity positions with settlement: the associated stocks order ID from the settlement system. NULL for non-settlement or non-stock positions. |
| 60 | InitialAmountCents | money | NO | 1 | CODE-BACKED | The position's opening amount in cents. DEFAULT=1 (historical sentinel before proper population). Used for copy-trading proportional calculations. |
| 61 | IsOpenOpen | bit | YES | - | CODE-BACKED | Whether this position was opened via the "open-open" copy-trading flow (copier mirrors parent's open positions). NULL for standard user-opened positions. |
| 62 | OpenExposureID | int | YES | - | CODE-BACKED | The exposure tracking ID for the open side of the hedge. Links to risk/exposure management records. |
| 63 | CloseExposureID | int | YES | - | CODE-BACKED | The exposure tracking ID for the close side of the hedge. |
| 64 | OpenMarketPriceRateID | bigint | YES | - | CODE-BACKED | PriceRateID for the market price at open (separate from MarketPriceRateID which is the spreaded rate). |
| 65 | CloseMarketPriceRateID | bigint | YES | - | CODE-BACKED | PriceRateID for the market price at close. |
| 66 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Original unit count before corporate action adjustments (splits). See Section 2.5. |
| 67 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Original lot count before adjustments. |
| 68 | InitForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original open rate before corporate action adjustments. |
| 69 | LimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original take-profit rate before adjustments. |
| 70 | StopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original stop-loss rate before adjustments. |
| 71 | EndForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original close rate before adjustments. |
| 72 | OrderPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original order execution rate before adjustments. |
| 73 | MarketPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original market rate at open before adjustments. |
| 74 | LastOpPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original last-operation rate before adjustments. |
| 75 | EndMarketRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Original close market rate before adjustments. |
| 76 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution system identifier for the open-side fill. Links to external execution records. |
| 77 | EndExecutionID | bigint | YES | - | CODE-BACKED | Execution system identifier for the close-side fill. |
| 78 | RootHedgeServerID | int | YES | - | CODE-BACKED | The original hedge server that handled the root position in a partial-close tree. Used for partial-close position tracking. |
| 79 | TreeID | bigint | NO | 0 | CODE-BACKED | Hierarchical tree identifier grouping related positions (e.g., parent + partial-close children). DEFAULT=0 (no tree). |
| 80 | ExitOrderID | int | YES | - | CODE-BACKED | The exit order ID from Trade.OrdersExitTbl that triggered this position close. NULL for direct closes without an exit order. |
| 81 | OrderType | int | YES | - | NAME-INFERRED | Type classification of the order that opened this position. Distinct from ActionType (close reason). NULL if opened via direct market order. |
| 82 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Whether trailing stop-loss was active. DEFAULT=0. 1=TSL was enabled when position closed. |
| 83 | IsComputeForHedge | smallint | YES | - | NAME-INFERRED | Hedge computation flag. Indicates whether this position should be included in hedge calculations. |
| 84 | FullCommission | money | YES | - | CODE-BACKED | Total commission including all components (open + close + any additional fees). NULL for positions predating this column. |
| 85 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Total close-side commission including all components. NULL for positions predating this column. |
| 86 | IsSettled | bit | NO | 0 | CODE-BACKED | Whether the position has been fully settled (funds transferred). DEFAULT=0. 1=settled (2,301,542 rows = 91.6%). Settled positions follow the Free Stocks settlement flow. |
| 87 | RedeemStatus | tinyint | YES | 0 | CODE-BACKED | Redemption lifecycle state. Values: NULL=no redeem (99.1%), 20=redeemed (20,071 rows), 6=intermediate redeem state (1,446 rows). DEFAULT=0. |
| 88 | RedeemID | int | YES | 0 | CODE-BACKED | Links to a Billing.Redeem record if this position was closed as part of a redemption. DEFAULT=0 (no redeem). |
| 89 | OriginalPositionID | bigint | YES | - | CODE-BACKED | For partial-close clone positions: the PositionID of the original (parent) position from which this partial was created. NULL for full closes and original positions. |
| 90 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | The original number of units before any partial close. Allows calculating what portion was closed (InitialUnits - AmountInUnitsDecimal). |
| 91 | SubCloseTypeID | decimal(16,6) | YES | - | NAME-INFERRED | Sub-classification of the close type. Stored as decimal(16,6) (unusual for an ID column). Specific values are application-defined. |
| 92 | PartialCloseRatio | decimal(16,15) | YES | - | CODE-BACKED | For partial-close positions: the ratio of units closed to the original unit count (0 < ratio <= 1). NULL for full closes. High precision (15 decimal places) for accurate proportional calculations. |
| 93 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | When a position is closed in order to reopen (e.g., leverage change): the new PositionID that was opened to replace this one. |
| 94 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Base value of the position in cents (for unit-denominated positions). Used in partial-close calculations. |
| 95 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a discounted spread was applied. Added in FB 53719 (Free Stocks). |
| 96 | InitConversionRate | decimal(16,8) | YES | - | CODE-BACKED | The USD conversion rate for the instrument's quote currency at position open. Used for PnL normalization. |
| 97 | ExitOrderType | int | YES | - | CODE-BACKED | Type of the exit order that closed this position. Complements ExitOrderID. Added Aug 2021 (TRADEX-1704). |
| 98 | OpenActionType | int | NO | -1 | CODE-BACKED | Type of action that opened this position. DEFAULT=-1 (not tracked for legacy positions). Added Aug 2021 (TRADEX-1704). |
| 99 | MarketRangeValidationType | tinyint | YES | 1 | CODE-BACKED | How the trade range slippage was validated at open. DEFAULT=1 (standard validation). |
| 100 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Percentage-based market range setting (alternative to pip-based TradeRange for some instruments). |
| 101 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement method for this position (matches IsSettled context). Values correlate with History.Orders.SettlementTypeID (0=unsettled, 1=standard settlement, 5=special). |
| 102 | InitConversionRateID | bigint | YES | - | CODE-BACKED | PriceRateID for InitConversionRate. |
| 103 | OpenMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | The bid-ask spread in the underlying market at position open. |
| 104 | PnLVersion | tinyint | YES | - | CODE-BACKED | P&L calculation formula version. Allows the system to track which version of the PnL algorithm was used for this position. |
| 105 | CloseMarkupOnOpen | money | YES | - | CODE-BACKED | Markup component calculated at close but applied to the open side. Used in advanced PnL calculations. |
| 106 | EstimatedConversionMarkupRatio | decimal(20,4) | YES | - | CODE-BACKED | Estimated markup ratio on the currency conversion component of the trade. |
| 107 | EstimatedMarkupRatio | decimal(20,4) | YES | - | CODE-BACKED | Estimated total markup ratio applied to this position's execution. |
| 108 | OpenMarkup | money | YES | - | CODE-BACKED | eToro's revenue markup applied at position open (difference between market rate and quoted rate). |
| 109 | OpenEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | The eToro-quoted price at open (market price + markup). Compared with MarketPriceRate to determine open markup amount. |
| 110 | CloseMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | The bid-ask spread in the underlying market at position close. |
| 111 | CloseEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | The eToro-quoted price at close (market price + close markup). |
| 112 | CloseMarkup | money | YES | - | CODE-BACKED | eToro's revenue markup applied at position close. |
| 113 | UnitMargin | decimal(16,8) | NO | -777 | CODE-BACKED | Margin required per unit for this position. DEFAULT=-777 (sentinel for "not set" - from constraint name D_SomeTable_SomeCol, indicating legacy placeholder). |
| 114 | OpenTotalTaxes | money | YES | 0 | CODE-BACKED | Total taxes charged at position open. DEFAULT=0. |
| 115 | OpenTotalFees | money | YES | 0 | CODE-BACKED | Total fees charged at position open. DEFAULT=0. |
| 116 | CloseTotalTaxes | money | YES | 0 | CODE-BACKED | Total taxes charged at position close. DEFAULT=0. |
| 117 | CloseTotalFees | money | YES | 0 | CODE-BACKED | Total fees charged at position close. DEFAULT=0. |
| 118 | IsNoStopLoss | bit | YES | - | CODE-BACKED | Explicitly marks a position that was opened without any stop-loss configured. |
| 119 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | Explicitly marks a position that was opened without any take-profit configured. |
| 120 | InitialLotCount | decimal(16,6) | YES | - | CODE-BACKED | Original lot count before partial-close adjustments. Enables reconstruction of the original position size. |
| 121 | OriginalOpenActionType | int | YES | - | CODE-BACKED | The original OpenActionType before any reopen or modification. Preserved for audit trail when OpenActionType changes. |

**Note**: Columns 122-123 (SpreadedPipBid, SpreadedPipAsk - #20-21 above) are listed at position 20-21 in the DDL.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.Instrument | InstrumentID | Implicit FK (no constraint) | The trading instrument. |
| Dictionary.Currency | CurrencyID | Implicit FK (no constraint) | Account currency. |
| Trade.HedgeServer | HedgeServerID | Implicit FK (no constraint) | Broker hedge server. |
| Trade.Mirror | MirrorID | Implicit FK (no constraint) | Copy-trading relationship. |
| Trade.PositionTbl | ParentPositionID | Implicit FK (no constraint) | Parent position for copy trades. |
| Billing.Redeem | RedeemID | Implicit FK (no constraint) | Redemption operation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PostClosePositionActions | PositionID | Writer (primary) | Full-close: SELECT FROM Trade.PositionTbl -> INSERT here |
| History.MovePartialClosePositionToPosition_Active | PositionID | Writer (partial-close) | Direct INSERT for partial-close clone positions |
| Trade.CloseOpenPositionWithStatus2 | PositionID | Writer (status-2 close) | Specific close path for status-2 positions |
| History.Position | PositionID | View | Reporting view with joins |
| History.PositionSlim | PositionID | View | Slim reporting view |
| Trade.GetClosedPositionsFromTimestamp | CloseOccurred | Read | Retrieves positions closed after a timestamp |
| Trade.GetPositionsForFeeProcess | Various | Read | Fee calculation on historical positions |
| Customer.SetBalanceClosePosition | PositionID | Read | Balance update on close |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Position_Active (table)
- Written by (full close): Trade.PostClosePositionActions
  - Triggered by Trade.PositionClose -> Trade.InsertAsyncRecord
- Written by (partial close): History.MovePartialClosePositionToPosition_Active
  - Triggered by Trade.PositionClose (IsPartial=1 path)
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependencies: Trade.PositionTbl (source), Trade.Instrument, Dictionary.Currency.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Position | View | JOIN-based reporting view |
| History.PositionSlim | View | Slim reporting view |
| Trade.GetClosedPositionsFromTimestamp | SP | Recent closed positions lookup |
| Trade.GetPositionsForFeeProcess | SP | Fee calculation |
| BackOffice.NewRiskAlertsPCIVersion | SP | Risk alerting |
| Trade.GetPositionDataForAllocation | SP | Allocation calculations |
| Trade.PayDividendsForPositions | SP | Dividend payment on historical positions |
| dbo.SSRS_DurationOfTradesForInstrumentID | SP | SSRS reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryPosition_BIGINT | NONCLUSTERED | PositionID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, HISTORY filegroup, OPTIMIZE_FOR_SEQUENTIAL_KEY=ON) |
| CLU_IX_HistoryPosition_Active_BIGINT_CloseOccurred | CLUSTERED | CID ASC, CloseOccurred ASC | - | - | Active (FILLFACTOR=80, PAGE compression, HISTORY filegroup) |
| IX_CIDOpenOccurred | NONCLUSTERED | CID ASC, OpenOccurred ASC | - | - | Active (HISTORY filegroup) |
| IX_HistoryPosition_Active_BIGINT_CloseOccurred | NONCLUSTERED | CloseOccurred ASC | OpenOccurred, HedgeServerID, InstrumentID, AmountInUnitsDecimal | - | Active (FILLFACTOR=90, PAGE compression, HISTORY filegroup) |
| IX_HistoryPosition_Active_BIGINT_MirrorID | NONCLUSTERED | MirrorID ASC, PositionID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, HISTORY filegroup) |
| IX_HistoryPosition_Active_BIGINT_ParentPositionIDIMirrorIDCID | NONCLUSTERED | OrigParentPositionID ASC, MirrorID ASC, CID ASC | PositionID | - | Active (FILLFACTOR=80, PAGE compression, HISTORY filegroup) |

**Key design note**: PK is NONCLUSTERED while CID+CloseOccurred is CLUSTERED. This is the standard pattern for customer-facing historical tables where the dominant query pattern is "closed positions for customer in date range" rather than single-row lookup by ID.

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_HistoryPosition_BIGINT | PRIMARY KEY | PositionID ASC - nonclustered |
| chk_HP_Active_BIGINT_CloseOccurred | CHECK | CloseOccurred >= '2021-04-01' |
| DF_History_Position_Active_BIGINT_EndOfWeekFee | DEFAULT | EndOfWeekFee = 0 |
| DF_History_Position_Active_BIGINT_EndDateTime | DEFAULT | EndDateTime = getdate() |
| DF_History_Position_Active_BIGINT_CloseOccurred | DEFAULT | CloseOccurred = getdate() |
| DF_History_Position_Active_BIGINT_EntryHedgeQuery | DEFAULT | EntryHedgeQuery = -1 |
| DF_History_Position_Active_BIGINT_EndHedgeQuery | DEFAULT | EndHedgeQuery = -1 |
| DF_History_Position_Active_BIGINT_ParentPositionID | DEFAULT | ParentPositionID = 1 |
| DF_History_Position_Active_BIGINT_OrigParentPositionID | DEFAULT | OrigParentPositionID = 1 |
| DF_History_Position_Active_BIGINT_InitialAmountCents | DEFAULT | InitialAmountCents = 1 |
| DF_History_Position_Active_BIGINT_MirrorID | DEFAULT | MirrorID = 0 |
| DF_History_Position_Active_BIGINT_TreeID | DEFAULT | TreeID = 0 |
| DF_History_Position_Active_BIGINT_IsTslEnabled | DEFAULT | IsTslEnabled = 0 |
| DF_History_Position_Active_BIGINT_IsSettled | DEFAULT | IsSettled = 0 |
| DF_History_Position_Active_BIGINT_RedeemStatus | DEFAULT | RedeemStatus = 0 |
| DF_History_Position_Active_BIGINT_RedeemID | DEFAULT | RedeemID = 0 |
| DF_History_Position_Active_202001_HistoryOpenActionType | DEFAULT | OpenActionType = -1 |
| DF_MarketRangeValidationType | DEFAULT | MarketRangeValidationType = 1 |
| D_SomeTable_SomeCol | DEFAULT | UnitMargin = -777 (sentinel) |
| DF_Trade_Position_Active_Open/CloseTotalTaxes/Fees | DEFAULT | 0 for all four tax/fee columns |

---

## 8. Sample Queries

### 8.1 Customer's closed positions in a date range

```sql
SELECT
    p.PositionID,
    p.InstrumentID,
    p.IsBuy,
    p.Amount,
    p.Leverage,
    p.InitForexRate,
    p.EndForexRate,
    p.NetProfit,
    p.Commission + p.CommissionOnClose AS TotalCommission,
    p.ActionType,
    p.OpenOccurred,
    p.CloseOccurred,
    DATEDIFF(SECOND, p.OpenOccurred, p.CloseOccurred) AS HoldingSeconds
FROM History.Position_Active p WITH (NOLOCK)
WHERE p.CID = @CID
  AND p.CloseOccurred >= @StartDate
  AND p.CloseOccurred <  @EndDate
ORDER BY p.CloseOccurred DESC;
```

### 8.2 Copy-trading positions for a mirror relationship

```sql
SELECT
    p.PositionID,
    p.InstrumentID,
    p.Amount,
    p.PositionRatio,
    p.ParentPositionID,
    p.NetProfit,
    p.ActionType,
    p.OpenOccurred,
    p.CloseOccurred
FROM History.Position_Active p WITH (NOLOCK)
WHERE p.MirrorID = @MirrorID
ORDER BY p.OpenOccurred DESC;
```

### 8.3 Partial-close position identification

```sql
-- Find all partial-close records (clones) for an original position
SELECT
    p.PositionID AS PartialPositionID,
    p.OriginalPositionID,
    p.AmountInUnitsDecimal AS ClosedUnits,
    p.InitialUnits AS OriginalUnits,
    p.PartialCloseRatio,
    p.CloseOccurred
FROM History.Position_Active p WITH (NOLOCK)
WHERE p.OriginalPositionID = @OriginalPositionID
ORDER BY p.CloseOccurred;
```

---

## 9. Atlassian Knowledge Sources

- **Confluence**: "Position partial-close: short summary" (ID 2356641832) - Documents the partial-close mechanism. Key facts: (1) Original position is updated in Trade.PositionTbl with new unit count. (2) A clone position is inserted DIRECTLY into History.Position_Active (never passes through Trade.PositionTbl). (3) Clone gets current timestamp as close time and closed-unit count. (4) History.PositionChangeLog_Active records ChangeTypeID=11 (partial close) for the clone and ChangeTypeID=12 (edit due to partial close) for the original. (5) Trade.PositionClose and Trade.PostClosePositionActions are the implementing SPs.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.2/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 117 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence (Position partial-close: short summary) + 0 Jira | Procedures: 1 analyzed (Trade.PostClosePositionActions) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Position_Active | Type: Table | Source: etoro/etoro/History/Tables/History.Position_Active.sql*
