# Trade.PositionTbl

> The central positions table holding all currently open and recently closed trading positions on the eToro platform. Every CFD, real stock, copy-trade, and manual position is stored here.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID (BIGINT), PartitionCol (computed) - composite PK |
| **Partition** | Yes - PS_PositionTbl_BIGINT on PartitionCol = PositionID % 50 |
| **Indexes** | 14 active + 2 disabled (CLU on CID, NC PK, IDX_TB_*, IX_*) |

---

## 1. Business Meaning

Trade.PositionTbl is the **most important table** in the Trade schema and the core of eToro's trading engine. Each row represents a single trading position - whether open (actively held, accumulating PnL) or closed (terminated, PnL realized). This includes manual trades placed directly by customers, copy-trade positions created when a leader opens a trade, CFD positions at leverage, real stock ownership positions, and positions opened by corporate actions (dividends, splits).

This table exists because every trading operation on the platform ultimately creates or modifies a position. Without it, the system could not track exposure, calculate margin, compute PnL, route hedges to liquidity providers, or support CopyTrader. Hundreds of procedures and views read from or write to PositionTbl. The table is partitioned by PositionID % 50 for scalability; the clustered index on CID optimizes customer-centric queries.

Data flows: `Trade.PositionOpen` INSERTs new rows when customers open positions (or CopyTrader creates mirrored positions). `Trade.PositionClose` UPDATEs StatusID to 2, sets end timestamps and close rates, then copies the row to History.Position. Open positions are read by GetPositionData, GetOpenPositionData, PnL views, hedge exposure queries, and fee/dividend processes. Closed positions remain in this table until moved to history.

---

## 2. Business Logic

### 2.1 Position Lifecycle: Open -> Closed -> History

**What**: Positions are created open, closed in-place, then moved to history.

**Columns/Parameters Involved**: `StatusID`, `PositionID`, `InitDateTime`, `EndDateTime`, `CloseOccurred`, `ActionType`

**Rules**:
- StatusID = 1 (Open): Position is live. Trade.PositionOpen INSERTs with StatusID=1. Trade.PositionTblOnlyOpen view filters WHERE StatusID=1.
- StatusID = 2 (Closed): Position terminated. Trade.PositionClose UPDATEs StatusID=2, EndDateTime, CloseOccurred, ActionType, EndForexRate, CommissionOnClose, NetProfit. Row remains in PositionTbl until moved to History.Position.
- History move: Trade.PositionClose copies the full row to History.Position_Active (partitioned) then DELETEs from PositionTbl. PostClosePositionActions may also delete when mirror closes.

**Diagram**:
```
[PositionOpen] --> INSERT Trade.PositionTbl (StatusID=1)
        |
        v
  [Open - live PnL, margin, fees]
        |
        v
[PositionClose] --> UPDATE StatusID=2, EndDateTime, ActionType, NetProfit
        |
        v
  [History.Position_Active INSERT] --> [DELETE from PositionTbl]
```

### 2.2 IsSettled and SettlementTypeID - Settlement Classification

**What**: Distinguishes real asset ownership from derivative contracts. CRITICAL: IsSettled is a LEGACY flag, NOT "settlement complete."

**Columns/Parameters Involved**: `IsSettled`, `SettlementTypeID`

**Rules**:
- IsSettled: LEGACY BIT. 1 = real stock position (customer owns actual shares), 0 = CFD (contract for difference). Code uses `Trade.FnIsRealPosition(IsSettled, InstrumentID)` and `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))`.
- SettlementTypeID: Modern replacement. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE (Dictionary.SettlementTypes).
- When SettlementTypeID is NULL, IsSettled is used as fallback. New positions have both populated.

### 2.3 Copy-Trade Hierarchy: TreeID, MirrorID, ParentPositionID

**What**: Positions can form a tree for CopyTrader. Root positions have TreeID=PositionID; children share the root's TreeID.

**Columns/Parameters Involved**: `TreeID`, `MirrorID`, `ParentPositionID`, `OrigParentPositionID`, `PositionRatio`

**Rules**:
- MirrorID: 0 or NULL = manual trade. Positive = copy-trade position; references Trade.Mirror (copier-leader relationship).
- TreeID: Links to Trade.PositionTreeInfo for SL/TP/TSL settings. Root position: TreeID = PositionID. Children: TreeID = root's PositionID. Demo: negative TreeID (IsReal=-1).
- ParentPositionID: 0/1 = root. Positive = this position was opened as a copy of the referenced position.
- PositionRatio: Copier's allocation fraction of leader's equity (Amount / RealizedEquity). Used for copy sizing.

### 2.4 Hedge and Order Linkage

**What**: Positions link to the originating order and the broker's hedge.

**Columns/Parameters Involved**: `OrderID`, `HedgeID`, `HedgeServerID`, `RootHedgeServerID`, `EntryHedgeQuery`, `IsComputeForHedge`

**Rules**:
- OrderID: References Trade.Orders. The order that opened this position. NULL for positions opened without an order (corporate action, dividend).
- HedgeID: References Trade.Hedge. The executed hedge at the liquidity provider. NULL until hedge is executed.
- HedgeServerID: Which hedge server manages this position. RootHedgeServerID: for copy-trade, the root's hedge server.
- IsComputeForHedge: 1 = include in hedge exposure aggregation; 0 = exclude (e.g., dummy/demo). Filtered index IDX_TB_HedgeQueryCoverv uses this.

---

## 3. Data Overview

| PositionID | CID | InstrumentID | MirrorID | StatusID | IsBuy | Amount | IsSettled | SettlementTypeID | OpenActionType | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 2152972412 | 14952810 | 100000 | 0 | 1 | 1 | 99.97 | 1 | 1 | 0 | Manual buy of crypto (BTC?), real settlement. Customer-initiated (0=Customer). |
| 2152972405 | 24713264 | 100001 | 0 | 1 | 1 | 20.95 | 1 | 1 | 13 | Real stock via ACATS_IN (transfer). Same customer, multiple positions. |
| 2152972385 | 14820300 | 5 | 0 | 1 | 1 | 999.54 | 0 | 0 | 0 | CFD position (USD/JPY instrument 5). IsSettled=0, SettlementTypeID=0. |
| (sample) | (sample) | (sample) | >0 | 1 | 1 | (varies) | (varies) | (varies) | 1 | Copy-trade child: MirrorID>0, OpenActionType=1 (Hierarchical Open). |

**Selection criteria**: Mix of manual vs copy-trade, CFD vs REAL, different OpenActionTypes. Table holds ~2.1M rows (open + closed before history move).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. PartitionCol = PositionID % 50. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID. References Customer.Customer. Clustered index key. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Deprecated. Set to -1 in PositionOpen. Retained for backward compatibility. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Denomination currency for Amount, NetProfit. Must be > 0 (CHK_CurrencyID). |
| 5 | ProviderID | int | NO | - | CODE-BACKED | References Trade.Provider. Execution provider (default 1 = TRADONOMI in PositionOpen). |
| 6 | GameServerID | int | NO | - | CODE-BACKED | Legacy game server. Set to 0 in PositionOpen. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Financial instrument being traded. Indexed (IDX_TB_ForSplit, IX_CID_InstrumentIdNew1). |
| 8 | HedgeID | int | YES | - | CODE-BACKED | FK to Trade.Hedge. Broker's executed hedge. NULL until hedge is opened. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | FK to Trade.HedgeServer. Hedge server managing this position. |
| 10 | OrderID | int | YES | - | CODE-BACKED | FK to Trade.Orders. Originating order. NULL for corporate action/dividend positions. |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. |
| 12 | Amount | money | NO | - | CODE-BACKED | Position size in currency. Must be >= 0 (CHK_TB_Amount). Stored in dollars (PositionOpen divides by 100 from cents). |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. Fractional lots. Must be > 0 when set (CHK_TB_LotCountDecimal). |
| 14 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. Used for hedge aggregation and unit-based sizing. |
| 15 | NetProfit | money | NO | - | CODE-BACKED | Realized PnL. 0 when open; set on close. In position currency. |
| 16 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Opening price rate at position open. Used for PnL calculation. |
| 17 | InitDateTime | datetime | NO | - | CODE-BACKED | When position was opened. Set from @InitDateTime in PositionOpen. |
| 18 | LimitRateOld | dbo.dtPrice | YES | - | NAME-INFERRED | Legacy take-profit rate. Superseded by Trade.PositionTreeInfo.LimitRate. |
| 19 | StopRateOld | dbo.dtPrice | YES | - | NAME-INFERRED | Legacy stop-loss rate. Superseded by Trade.PositionTreeInfo.StopRate. |
| 20 | SpreadedPipBid | dbo.dtPrice | YES | - | CODE-BACKED | Bid rate with spread at open. From Trade.CurrencyPrice/spread config. |
| 21 | SpreadedPipAsk | dbo.dtPrice | YES | - | CODE-BACKED | Ask rate with spread at open. |
| 22 | IsBuy | bit | NO | - | CODE-BACKED | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. |
| 23 | CloseOnEndOfWeekOld | bit | YES | - | NAME-INFERRED | Legacy weekend-close flag. Superseded by PositionTreeInfo.CloseOnEndOfWeek. |
| 24 | EndOfWeekFee | money | NO | 0 | CODE-BACKED | Overnight/weekend carry fee. DF_TB_EndOfWeekFee. ClaimEndOfWeekFee updates. |
| 25 | Commission | money | NO | - | CODE-BACKED | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). |
| 26 | SpreadedCommission | int | NO | - | CODE-BACKED | Spread-related commission component. |
| 27 | AdditionalParam | sql_variant | YES | - | CODE-BACKED | Extensible payload. PositionOpen inserts ''. Used for trade metadata. |
| 28 | RequestOccurred | datetime | NO | - | CODE-BACKED | When the open request arrived at Trading API. Distinct from Occurred (DB insert time). |
| 29 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When position was persisted. Default getutcdate(). DF_TB_Occurred. |
| 30 | ClamedOnDay | int | YES | - | NAME-INFERRED | Day-of-week or epoch for fee claim tracking. |
| 31 | SpreadGroupID | int | YES | - | CODE-BACKED | FK to Trade.SpreadGroup. Spread tier at open. From Customer.Customer or instrument override. |
| 32 | LotCountGroupID | int | YES | - | CODE-BACKED | Lot count configuration group. From Customer at open. |
| 33 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance for execution. From Trade.ProviderToInstrument. |
| 34 | InitForexPriceRateID | bigint | NO | - | CODE-BACKED | Price rate record ID at open. References Trade.CurrencyPrice.PriceRateID. |
| 35 | OrderPriceRateID | bigint | NO | - | CODE-BACKED | Order's price rate ID. |
| 36 | OrderPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | Order execution rate. |
| 37 | MarketPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | Market rate at open (mid). |
| 38 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate record ID. |
| 39 | EntryHedgeQuery | int | NO | -1 | CODE-BACKED | Hedge request state. -1 = needs hedge/re-hedge. Updated when hedge executes. DF_TB_EntryHedgeQuery. |
| 40 | ParentPositionID | bigint | YES | 1 | CODE-BACKED | Copy-trade parent. 0/1 = root. Positive = child of referenced position. DF_TB_ParentPositionID. |
| 41 | OrigParentPositionID | bigint | YES | 1 | CODE-BACKED | Original parent before any detachment. DF_TB_OrigParentPositionID. |
| 42 | LastOpPriceRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Last operation price. Updated on partial close, dividend, etc. DF_TB_LastOpPriceRate. |
| 43 | LastOpPriceRateID | bigint | YES | 0 | CODE-BACKED | Last operation price rate ID. DF_TB_LastOpPriceRateID. |
| 44 | LastOpConversionRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Conversion rate for last op. DF_TB_LastOpConversionRate. |
| 45 | LastOpConversionRateID | bigint | YES | 0 | CODE-BACKED | Conversion rate record ID. DF_TB_LasOpConversionRateID. |
| 46 | MirrorID | int | YES | 0 | CODE-BACKED | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. DF_TB_MirrorID. Index IDX_TB_MirrorID. |
| 47 | IsComputeForHedge | smallint | YES | 1 | CODE-BACKED | 1 = include in hedge exposure, 0 = exclude. Filtered index IDX_TB_HedgeQueryCoverv. DF_TB_IsComputeForHedge. |
| 48 | PositionRatio | decimal(7,6) | YES | - | CODE-BACKED | Copy allocation ratio: Amount / RealizedEquity. 0-1. Used for copy sizing. |
| 49 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Lot count for direct aggregation (non-copy or PlayerLevelID check). PositionOpen sets from LotCountDecimal or 0. |
| 50 | StocksOrderID | int | YES | - | NAME-INFERRED | Stock-specific order reference. |
| 51 | InitialAmountCents | money | NO | 1 | CODE-BACKED | Initial amount in cents. DF_TB_InitialAmountCents. Used for ratio calculations. |
| 52 | LastEOWClameDate | datetime | YES | - | NAME-INFERRED | Last end-of-week fee claim date. |
| 53 | IsOpenOpen | bit | YES | - | CODE-BACKED | Open-on-open copy behavior. From Mirror. |
| 54 | OpenExposureID | int | YES | - | CODE-BACKED | Exposure ID at open. Set to 0 or from Trade.ExposureIDs in PositionOpen. |
| 55 | OpenMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate ID at open. From CurrencyPrice if not provided. |
| 56 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Units before corporate action adjustments. Used for split/reverse-split recovery. |
| 57 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Lot count before adjustments. |
| 58 | InitForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Init rate before split adjustment. |
| 59 | LimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Limit rate before adjustment. |
| 60 | StopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Stop rate before adjustment. |
| 61 | SpreadedPipBidUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Bid before adjustment. |
| 62 | SpreadedPipAskUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Ask before adjustment. |
| 63 | OrderPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Order rate before adjustment. |
| 64 | MarketPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Market rate before adjustment. |
| 65 | LastOpPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Last op rate before adjustment. |
| 66 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution record ID at open. |
| 67 | RootHedgeServerID | int | YES | - | CODE-BACKED | For copy-trade: root position's HedgeServerID. Used when root has DLT flow (86) for close compatibility. |
| 68 | PartitionCol | computed | NO | PositionID%50 | CODE-BACKED | Partition key. PERSISTED. PS_PositionTbl_BIGINT. |
| 69 | TreeID | bigint | NO | 0 | CODE-BACKED | Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root's PositionID. Demo: negative. DF_TB_TreeID. Index IDX_TB_TreeID_1. |
| 70 | LastOverNightClameDate | datetime | YES | - | NAME-INFERRED | Last overnight fee claim date. |
| 71 | OrderType | int | YES | - | CODE-BACKED | Dictionary.OrderType at open. 1=OpenTrade, 13=EntryOrder, 16=EntryOrderByUnits, etc. |
| 72 | FullCommission | money | YES | - | CODE-BACKED | Full commission including spread. PositionOpen stores @FullCommission/100. |
| 73 | IsSettled | bit | NO | 0 | VERIFIED | LEGACY: 1 = real stock, 0 = CFD. NOT "settlement complete." Predates SettlementTypeID. DF_TB_IsSettled. |
| 74 | RedeemStatus | tinyint | YES | 0 | CODE-BACKED | Redemption state. DF_TB_RedeemStatus. Billing.Redeem integration. |
| 75 | StatusID | int | NO | 1 | CODE-BACKED | 1=Open, 2=Closed (Dictionary.PositionStatus). DF_TB_StatusID. |
| 76 | EndForexRate | decimal(16,8) | YES | - | CODE-BACKED | Closing rate at position close. |
| 77 | CommissionOnClose | money | YES | - | CODE-BACKED | Commission charged on close. |
| 78 | EndDateTime | datetime | YES | - | CODE-BACKED | When position was closed. |
| 79 | ActionType | int | YES | - | CODE-BACKED | Close reason. Dictionary.ClosePositionActionType: 0=Customer, 1=Stop Loss, 5=Take Profit, 9=Hierarchical Close, etc. |
| 80 | CloseOccurred | datetime | YES | - | CODE-BACKED | When close was persisted. Index IDX_TB_Status_CloseOccurred. |
| 81 | EndForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate ID at close. |
| 82 | CloseExposureID | int | YES | - | CODE-BACKED | Exposure ID at close. |
| 83 | CloseMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate ID at close. |
| 84 | EndMarketRate | dbo.dtPrice | YES | - | CODE-BACKED | Market rate at close. |
| 85 | EndMarketPriceRateID | bigint | YES | - | CODE-BACKED | End market price rate ID. |
| 86 | EndExecutionID | bigint | YES | - | CODE-BACKED | Execution record ID at close. |
| 87 | ExitOrderID | int | YES | - | CODE-BACKED | Order that closed the position (exit order). References Trade.Orders or ExitOrder. |
| 88 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Full commission on close. |
| 89 | RedeemID | int | YES | - | CODE-BACKED | Billing.Redeem reference when position closed via redeem. |
| 90 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Original unit count at open. Used for partial close ratio. |
| 91 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | When position was reopened: references the erroneously closed PositionID. |
| 92 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Unit value in cents for PnL. |
| 93 | InitConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | Currency conversion rate at open. |
| 94 | InitConversionRateID | bigint | YES | - | CODE-BACKED | Conversion rate record ID at open. |
| 95 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | When close request arrived at API. |
| 96 | ExitOrderType | int | YES | - | CODE-BACKED | Order type of the exit order. Dictionary.OrderType. |
| 97 | OpenActionType | int | NO | -1 | CODE-BACKED | Open reason. Dictionary.OpenPositionActionType: 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 13=ACATS_IN, 17=Recurring Investment, etc. DF_TB_OpenActionType. |
| 98 | MarketRangeValidationType | tinyint | YES | 1 | CODE-BACKED | Market range validation mode. DF_MarketRangeValidationType1. |
| 99 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Allowed market range percentage for execution. |
| 100 | SettlementTypeID | tinyint | YES | - | VERIFIED | Modern settlement. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. |
| 101 | RowVersionPosition | timestamp | NO | - | CODE-BACKED | Row version for optimistic concurrency. Index IX_RowVersionPosition_New for change feed. |
| 102 | OpenMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | Spread at open. |
| 103 | PnLVersion | tinyint | YES | 0 | CODE-BACKED | PnL calculation version. DF_Trade_PositionTbl_PnLVersion. |
| 104 | CloseMarkupOnOpen | money | YES | - | CODE-BACKED | Close markup projected at open. |
| 105 | EstimatedConversionMarkupRatio | decimal(20,4) | YES | 1 | CODE-BACKED | Estimated conversion markup. DF_Trade_PositionTbl_EstimatedConversionMarkupRatio. |
| 106 | EstimatedMarkupRatio | decimal(20,4) | YES | 1 | CODE-BACKED | Estimated markup. DF_Trade_PositionTbl_EstimatedMarkupRatio. |
| 107 | OpenMarkup | money | YES | - | CODE-BACKED | Markup at open. |
| 108 | OpenEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | eToro display price at open. |
| 109 | CloseMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | Spread at close. |
| 110 | CloseEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | eToro display price at close. |
| 111 | CloseMarkup | money | YES | - | CODE-BACKED | Markup at close. |
| 112 | UnitMargin | decimal(16,8) | NO | - | CODE-BACKED | Margin per unit. From Trade.ProviderToInstrument. |
| 113 | OpenTotalTaxes | money | YES | 0 | CODE-BACKED | Taxes at open. DF_Trade_PositionTbl_OpenTotalTaxes. |
| 114 | OpenTotalFees | money | YES | 0 | CODE-BACKED | Fees at open. DF_Trade_PositionTbl_OpenTotalFees. |
| 115 | CloseTotalTaxes | money | YES | - | CODE-BACKED | Taxes at close. |
| 116 | CloseTotalFees | money | YES | - | CODE-BACKED | Fees at close. |
| 117 | InitialLotCount | decimal(16,6) | YES | - | CODE-BACKED | Lot count at open. For partial close calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer who holds the position. |
| CurrencyID | Dictionary.Currency | Implicit | Denomination currency. |
| ProviderID | Trade.Provider | Implicit | Execution provider. |
| InstrumentID | Trade.Instrument | Implicit | Traded instrument. |
| HedgeID | Trade.Hedge | Implicit | Broker's hedge position. |
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server. |
| OrderID | Trade.Orders | Implicit | Originating order. |
| SpreadGroupID | Trade.SpreadGroup | Implicit | Spread tier at open. |
| MirrorID | Trade.Mirror | Implicit | Copy-trade relationship. |
| TreeID | Trade.PositionTreeInfo | Implicit | SL/TP/TSL settings. |
| StatusID | Dictionary.PositionStatus | Lookup | Open/Closed. |
| SettlementTypeID | Dictionary.SettlementTypes | Lookup | CFD/REAL/TRS/etc. |
| OpenActionType | Dictionary.OpenPositionActionType | Lookup | Open reason. |
| ActionType | Dictionary.ClosePositionActionType | Lookup | Close reason. |
| ParentPositionID | Trade.PositionTbl | Self-Reference | Copy-trade parent. |
| ReopenForPositionID | Trade.PositionTbl | Self-Reference | Reopened from. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpen | INSERT | Writer | Creates positions. |
| Trade.PositionClose | UPDATE/DELETE | Modifier/Deleter | Closes and moves to history. |
| Trade.GetPositionData | FROM | Reader | Main position view. |
| Trade.GetOpenPositionData | FROM | Reader | Open positions. |
| Trade.Position | View | Base table | Legacy view. |
| Trade.PnL | FROM | Reader | PnL calculation. |
| Trade.PostClosePositionActions | FROM | Reader | Post-close mirror/refill. |
| Trade.DetachFromParentPosition | UPDATE | Modifier | Copy-trade detach. |
| Trade.PositionReopen | SELECT/UPDATE | Modifier | Reopen closed. |
| Trade.GetPositionsForFeeProcess | FROM | Reader | Fee processing. |
| Trade.GetPositionsForDividendSnapshot | FROM | Reader | Dividend. |
| Trade.HedgeExposureQuery | FROM | Reader | Hedge exposure. |
| Trade.GetPortfolioAggregates | FROM | Reader | Portfolio. |
| 100+ procedures/views | - | Reader/Writer | Heavily referenced. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionTbl (table)
```

Tables are leaf nodes. No code-level dependencies (CREATE TABLE has no FROM/JOIN). FK targets and implicit lookups are structural.

### 6.1 Objects This Depends On

No explicit FK targets in CREATE TABLE. Implicit: Dictionary.Currency (CurrencyID), Trade.Provider, Trade.Instrument, Trade.Hedge, Trade.HedgeServer, Trade.Orders, Trade.SpreadGroup, Trade.Mirror, Trade.PositionTreeInfo, Dictionary.PositionStatus, Dictionary.SettlementTypes, Dictionary.OpenPositionActionType, Dictionary.ClosePositionActionType.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpen | Procedure | INSERT |
| Trade.PositionClose | Procedure | UPDATE, DELETE (after copy to history) |
| Trade.PostClosePositionActions | Procedure | SELECT, DELETE |
| Trade.GetPositionData | View | FROM |
| Trade.GetOpenPositionData | View | FROM |
| Trade.Position | View | FROM |
| Trade.PnL | View | FROM |
| Trade.PositionTblOnlyOpen | View | FROM (StatusID=1) |
| Trade.GetPositionsForFeeProcess | Procedure | FROM |
| Trade.DetachFromParentPosition | Procedure | UPDATE |
| Trade.PositionReopen | Procedure | SELECT, UPDATE |
| Trade.HedgeExposureQuery | Procedure | FROM |
| Trade.GetPortfolioAggregates | Procedure | FROM |
| 100+ other procedures/views | - | Reader/Writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradePositionTbl | NC PK | PositionID, PartitionCol | - | - | Active |
| CLU_TradePositionTbl | CLUSTERED | CID | - | - | Active |
| IDX_TB_ForSplit | NC | InstrumentID, PositionID, InitDateTime, IsComputeForHedge, StatusID | AmountInUnitsDecimal, LotCountDecimal, InitForexRate, SpreadedPipBid, SpreadedPipAsk, OrderPriceRate, MarketPriceRate, LastOpPriceRate, PartitionCol, IsBuy, HedgeServerID, Commission | - | Active |
| IDX_TB_HedgeQueryCoverv | NC | InstrumentID, IsComputeForHedge, StatusID | HedgeServerID, AmountInUnitsDecimal, LotCountDecimal, InitForexRate, IsBuy, Commission | IsComputeForHedge=1 AND StatusID=1 | DISABLED |
| IDX_TB_InstrumentIDHedgeIsBuy | NC | InstrumentID, HedgeServerID, IsBuy | InitForexRate | - | Active |
| IDX_TB_IsComputeForHedge | NC | IsComputeForHedge, InstrumentID, ProviderID | HedgeServerID, AmountInUnitsDecimal, LotCountDecimal, InitForexRate, IsBuy, Commission | - | DISABLED |
| IDX_TB_MirrorID | NC | MirrorID, PositionID, StatusID | - | - | Active |
| IDX_TB_Occurred_INC | NC | Occurred | InstrumentID, HedgeServerID, AmountInUnitsDecimal | - | Active |
| IDX_TB_ParentPositionIDNewSlim | NC | ParentPositionID, StatusID, IsComputeForHedge | PositionID, CID, TreeID, MirrorID | - | Active |
| IDX_TB_Status_CloseOccurred | NC | StatusID, CloseOccurred DESC, CID | PositionID, InstrumentID, AmountInUnitsDecimal | - | Active |
| IDX_TB_TreeID_1 | NC | TreeID, StatusID, PositionID | Amount, AmountInUnitsDecimal, ParentPositionID, MirrorID, IsComputeForHedge, IsSettled, RootHedgeServerID, HedgeServerID | - | Active |
| IX_CID_InstrumentID_StatusID_Leverage_IsBuy | NC | CID, InstrumentID, Leverage, IsBuy | AmountInUnitsDecimal, StatusID | - | Active (MAIN) |
| IX_CID_InstrumentIdNew1 | NC | CID, MirrorID, InstrumentID, Leverage, IsBuy, StatusID | AmountInUnitsDecimal, PositionID, Amount | - | Active (MAIN) |
| IX_RowVersionPosition_New | NC | RowVersionPosition | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradePositionTbl | PK | PositionID, PartitionCol. Nonclustered on partition. |
| CHK_CurrencyID | CHECK | CurrencyID > 0 AND NOT NULL |
| CHK_TB_Amount | CHECK | Amount >= 0 |
| CHK_TB_LotCountDecimal | CHECK | LotCountDecimal > 0 (when set) |
| DF_TB_EndOfWeekFee | DEFAULT | EndOfWeekFee = 0 |
| DF_TB_Occurred | DEFAULT | Occurred = getutcdate() |
| DF_TB_EntryHedgeQuery | DEFAULT | EntryHedgeQuery = -1 |
| DF_TB_ParentPositionID | DEFAULT | ParentPositionID = 1 |
| DF_TB_OrigParentPositionID | DEFAULT | OrigParentPositionID = 1 |
| DF_TB_LastOpPriceRate | DEFAULT | LastOpPriceRate = 0 |
| DF_TB_LastOpPriceRateID | DEFAULT | LastOpPriceRateID = 0 |
| DF_TB_LastOpConversionRate | DEFAULT | LastOpConversionRate = 0 |
| DF_TB_LasOpConversionRateID | DEFAULT | LastOpConversionRateID = 0 |
| DF_TB_MirrorID | DEFAULT | MirrorID = 0 |
| DF_TB_IsComputeForHedge | DEFAULT | IsComputeForHedge = 1 |
| DF_TB_InitialAmountCents | DEFAULT | InitialAmountCents = 1 |
| DF_TB_TreeID | DEFAULT | TreeID = 0 |
| DF_TB_IsSettled | DEFAULT | IsSettled = 0 |
| DF_TB_RedeemStatus | DEFAULT | RedeemStatus = 0 |
| DF_TB_StatusID | DEFAULT | StatusID = 1 |
| DF_TB_OpenActionType | DEFAULT | OpenActionType = -1 |
| DF_MarketRangeValidationType1 | DEFAULT | MarketRangeValidationType = 1 |
| DF_Trade_PositionTbl_PnLVersion | DEFAULT | PnLVersion = 0 |
| DF_Trade_PositionTbl_EstimatedConversionMarkupRatio | DEFAULT | EstimatedConversionMarkupRatio = 1 |
| DF_Trade_PositionTbl_EstimatedMarkupRatio | DEFAULT | EstimatedMarkupRatio = 1 |
| DF_Trade_PositionTbl_OpenTotalTaxes | DEFAULT | OpenTotalTaxes = 0 |
| DF_Trade_PositionTbl_OpenTotalFees | DEFAULT | OpenTotalFees = 0 |

---

## 8. Sample Queries

### 8.1 Get open positions for a customer with instrument and status
```sql
SELECT p.PositionID, p.CID, p.InstrumentID, p.Amount, p.AmountInUnitsDecimal,
       p.IsBuy, p.InitForexRate, p.StatusID, ps.Status, p.InitDateTime
FROM   Trade.PositionTbl p WITH (NOLOCK)
       INNER JOIN Dictionary.PositionStatus ps WITH (NOLOCK) ON p.StatusID = ps.StatusID
WHERE  p.CID = 14952810
       AND p.StatusID = 1
ORDER BY p.InitDateTime DESC;
```

### 8.2 Copy-trade positions with mirror and open action type
```sql
SELECT p.PositionID, p.CID, p.MirrorID, m.ParentCID, m.Amount AS MirrorAllocation,
       oat.OpenPositionActionName, p.InstrumentID, p.Amount, p.IsBuy
FROM   Trade.PositionTbl p WITH (NOLOCK)
       INNER JOIN Trade.Mirror m WITH (NOLOCK) ON p.MirrorID = m.MirrorID
       LEFT JOIN Dictionary.OpenPositionActionType oat WITH (NOLOCK) ON p.OpenActionType = oat.ID
WHERE  p.MirrorID > 0
       AND p.StatusID = 1
ORDER BY p.Occurred DESC;
```

### 8.3 Resolve position to instrument, settlement, and close reason
```sql
SELECT p.PositionID, p.CID, p.InstrumentID, st.SettlementType,
       cat.ClosePositionActionName AS CloseReason, p.NetProfit, p.EndDateTime
FROM   Trade.PositionTbl p WITH (NOLOCK)
       LEFT JOIN Dictionary.SettlementTypes st WITH (NOLOCK) ON p.SettlementTypeID = st.SettlementTypeID
       LEFT JOIN Dictionary.ClosePositionActionType cat WITH (NOLOCK) ON p.ActionType = cat.ID
WHERE  p.StatusID = 2
ORDER BY p.CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.6/10 (Elements: 8.8/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 100 CODE-BACKED, 0 ATLASSIAN-ONLY, 14 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionTbl | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionTbl.sql*
