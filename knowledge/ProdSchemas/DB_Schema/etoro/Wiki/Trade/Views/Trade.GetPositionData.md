# Trade.GetPositionData

> Unified view that combines open positions (Trade.PositionTbl) with closed/historical positions (History.Position) into a single resultset, enriched with instrument forex pairs, provider instrument settings, tree risk levels, and mirror status - the primary "all positions" abstraction layer for the trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionTbl / History.Position) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPositionData is the **primary comprehensive position view** in the Trade schema. It provides a unified interface to query both currently open positions and historically closed positions in a single SELECT. Each row represents a trading position - open or closed - with complete data for display, reporting, dividend calculations, position hierarchy traversal, and recovery workflows.

This view exists because position data is split across two physical stores: open positions live in `Trade.PositionTbl` (the hot transactional table), while closed positions are archived to `History.Position` after close. Consumers that need the full lifecycle of a position (e.g., trade blotter, dividend payment, position hierarchy queries, market-maker recovery) would otherwise need to UNION these sources in every query. GetPositionData centralizes this pattern and enriches each row with instrument forex currency pairs (from Trade.Instrument), unit/precision settings (from Trade.ProviderToInstrument), tree-level SL/TP settings (from Trade.PositionTreeInfo), and mirror activity status (from Trade.Mirror).

The open-position branch filters `WHERE StatusID = 1` (open only) and JOINs PositionTreeInfo using the partition-aligned condition `abs(TPOS.TreeID%50) = TPTI.PartitionCol` for optimal partition elimination. Closed-position columns like EndForexRate, EndDateTime, NetProfit, ActionType, and CommissionOnClose are returned as NULL for open rows and populated from History.Position for closed rows. The `IsOpened` column (1=open, 0=closed) distinguishes the source branch.

---

## 2. Business Logic

### 2.1 Open vs Closed Position Unification

**What**: The UNION ALL merges two disjoint datasets into one schema, with sentinel values distinguishing open from closed.

**Columns/Parameters Involved**: `IsOpened`, `EndForexRate`, `EndDateTime`, `ActionType`, `NetProfit`, `CommissionOnClose`, `ExitOrderID`, `CloseOccurred`, `EndExecutionID`, `IsMirrorActive`, `SLManualVer`

**Rules**:
- IsOpened = 1 (open branch): EndForexRate, EndDateTime, ActionType, NetProfit, CommissionOnClose, ExitOrderID, CloseOccurred are NULL. EndExecutionID = 0. IsMirrorActive is live-checked from Trade.Mirror. SLManualVer from PositionTreeInfo.
- IsOpened = 0 (closed branch): All close-related columns populated from History.Position. IsMirrorActive hardcoded to 0 (performance optimization - mirror status irrelevant for closed positions). SLManualVer hardcoded to -1 (only needed for open positions).
- AdditionalParam: NULL for closed positions (not stored in History.Position).

**Diagram**:
```
Trade.PositionTbl (StatusID=1)  -->  [Open Branch: IsOpened=1]
  + Trade.Instrument (ForexBuy/Sell)         |
  + Trade.ProviderToInstrument (Units/Prec)  |-- UNION ALL --> GetPositionData
  + Trade.PositionTreeInfo (SL/TP/TSL)       |
  + Trade.Mirror (IsMirrorActive)            |
                                             |
History.Position (all closed)   -->  [Closed Branch: IsOpened=0]
  + Trade.Instrument (ForexBuy/Sell)         |
  + Trade.ProviderToInstrument (Units/Prec)  |
```

### 2.2 Settlement Type Fallback Pattern

**What**: SettlementTypeID uses a fallback from the legacy IsSettled BIT when the modern column is NULL.

**Columns/Parameters Involved**: `IsSettled`, `SettlementTypeID`

**Rules**:
- Open branch: `ISNULL(TPOS.SettlementTypeID, CAST(IsSettled AS tinyint))` - if SettlementTypeID is NULL (legacy positions), fall back to IsSettled (0=CFD, 1=REAL).
- Closed branch: SettlementTypeID passes through directly from History.Position (already resolved at close time).
- See [Settlement Type](_glossary.md#settlement-type) for full value definitions.

### 2.3 UnitsBaseValueCents Fallback

**What**: The original investment value in cents uses a fallback for older positions.

**Columns/Parameters Involved**: `UnitsBaseValueCents`, `InitialAmountCents`

**Rules**:
- Open branch: `ISNULL(TPOS.UnitsBaseValueCents, CONVERT(INT, InitialAmountCents))` - falls back to InitialAmountCents for positions opened before UnitsBaseValueCents was added.
- Closed branch: UnitsBaseValueCents passes through directly from History.Position.

---

## 3. Data Overview

| PositionID | CID | InstrumentID | IsOpened | Currency | Leverage | IsBuy | Amount | MirrorID | SettlementTypeID | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 2152077450 | 9707089 | 100017 | 1 | 1 | 1 | true | 0.93 | 0 | 1 | Open manual buy of a real stock (SettlementTypeID=1). Leverage 1x, USD denomination. TreeID=PositionID (root position, no copy-trade). |
| 2152077750 | 9743732 | 100017 | 1 | 1 | 1 | true | 1.35 | 0 | 1 | Open manual buy of same real stock. Small fractional amount typical of retail stock purchases. |
| 2152077700 | 9755280 | 100017 | 1 | 1 | 1 | true | 5.98 | 0 | 1 | Open manual buy. Larger amount. All three samples show IsComputeForHedge=1 (included in hedge exposure). |
| (historical) | (varies) | (varies) | 0 | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | Closed position from History.Position. EndDateTime, NetProfit, ActionType populated. IsMirrorActive=0, SLManualVer=-1 (hardcoded for closed). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID. From Trade.PositionTbl (open) or History.Position (closed). References Customer.Customer. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. Primary key in base tables. Identifies the trade across its full lifecycle. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Deprecated. Set to -1 for new positions. Retained for backward compatibility with legacy forex result tracking. |
| 4 | IsOpened | int | NO | - | CODE-BACKED | Computed in view: 1 = open position (from PositionTbl WHERE StatusID=1), 0 = closed position (from History.Position). Distinguishes the UNION ALL branch. |
| 5 | Currency | int | NO | - | CODE-BACKED | Alias for CurrencyID. Denomination currency for Amount/NetProfit. FK to Dictionary.Currency (1=USD, 2=EUR, etc.). |
| 6 | ProviderID | int | NO | - | CODE-BACKED | Execution provider. FK to Trade.Provider (1=TRADONOMI default). |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument being traded. FK to Trade.Instrument. JOIN key for ForexBuy/ForexSell and Units/Precision. |
| 8 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Alias for HedgeServerID. Which hedge server manages this position. FK to Trade.HedgeServer. |
| 9 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1, 2, 5, 10, etc.). 1x = real stock or unleveraged CFD. Higher = amplified exposure. |
| 10 | ForexBuy | int | YES | - | CODE-BACKED | From Trade.Instrument.BuyCurrencyID via InstrumentID JOIN. The buy-side currency of the instrument's forex pair. FK to Dictionary.Currency. |
| 11 | ForexSell | int | YES | - | CODE-BACKED | From Trade.Instrument.SellCurrencyID via InstrumentID JOIN. The sell-side currency of the instrument's forex pair. FK to Dictionary.Currency. |
| 12 | InitForexRate | float | YES | - | CODE-BACKED | Forex conversion rate at position open. Used to convert PnL between instrument currency and position currency. |
| 13 | EndForexRate | float | YES | - | CODE-BACKED | Forex conversion rate at position close. NULL for open positions (IsOpened=1). Populated from History.Position for closed. |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | When the position was opened. Set by Trade.PositionOpen. |
| 15 | EndDateTime | datetime | YES | - | CODE-BACKED | When the position was closed. NULL for open positions. Populated from History.Position for closed. |
| 16 | ActionType | tinyint | YES | - | CODE-BACKED | Close action type. NULL for open positions. For closed: FK to Dictionary.ClosePositionActionType (1=Manual, 2=StopLoss, 3=TakeProfit, etc.). |
| 17 | NetProfit | money | YES | - | CODE-BACKED | Realized PnL. NULL for open positions. For closed: final profit/loss in position currency. |
| 18 | LimitRate | float | YES | - | CODE-BACKED | Take-profit price. From Trade.PositionTreeInfo (open) or History.Position (closed). Position closes when market hits this rate. |
| 19 | StopRate | float | YES | - | CODE-BACKED | Stop-loss price. From Trade.PositionTreeInfo (open) or History.Position (closed). Position closes when market hits this rate to limit loss. |
| 20 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. Must be >= 0. |
| 21 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. Fractional lots supported. |
| 22 | Commission | money | YES | - | CODE-BACKED | Commission charged at open. Spread-based commission in position currency. |
| 23 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. May differ from Commission when spread markup applies. |
| 24 | IsBuy | varchar | NO | - | CODE-BACKED | Computed in view: CASE converting BIT to string. 'true' = buy/long, 'false' = sell/short. String format for API/client consumption. |
| 25 | CloseOnEndOfWeek | varchar | NO | - | CODE-BACKED | Computed in view: CASE converting BIT to string. 'true' = close before weekend (avoid overnight fees), 'false' = stay open. From PositionTreeInfo (open) or History.Position (closed). |
| 26 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee charged. From Trade.PositionTbl.EndOfWeekFee. |
| 27 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. Used for hedge aggregation and unit-based sizing. |
| 28 | AdditionalParam | nvarchar(max) | YES | - | CODE-BACKED | Free-form additional parameters (JSON/XML). From PositionTbl for open. NULL for closed (not stored in History). |
| 29 | OpenOccurred | datetime | YES | - | CODE-BACKED | Alias for Occurred (open) / OpenOccurred (closed). Timestamp when the open order was executed. |
| 30 | CloseOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the close order was executed. NULL for open positions. |
| 31 | OrderID | int | YES | - | CODE-BACKED | FK to Trade.Orders. The originating order that opened this position. NULL for corporate action/dividend positions. |
| 32 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance at open. Used for slippage control. |
| 33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID at open. References the exact price used to open the position. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Copy-trade parent. 0 or 1 = root/manual. Positive = this position was opened as a copy of the referenced position. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before any re-parenting. Preserved when copy-trade trees are restructured. |
| 36 | LastOpPriceRate | float | YES | - | CODE-BACKED | Last operation's price rate. Updated on each position modification (SL/TP edit, partial close). |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID for the last operation. |
| 38 | LastOpConversionRate | float | YES | - | CODE-BACKED | Last operation's forex conversion rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Conversion rate snapshot ID for the last operation. |
| 40 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Per-unit margin requirement. Used for margin calculations with futures and leveraged positions. |
| 41 | Units | decimal(18,8) | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Unit via ProviderID+InstrumentID JOIN. Instrument's standard lot size in units. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Precision via JOIN. Number of decimal places for price display. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror relationship. 0 = manual trade. Positive = FK to Trade.Mirror (copier-leader link). |
| 44 | PositionRatio | decimal(16,8) | YES | - | CODE-BACKED | Copier's allocation fraction of leader's equity. Used for proportional copy sizing. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count for direct (non-copy) positions. Used in hedge exposure calculations. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | FK to Trade.SpreadGroup. Determines which spread tier applies to this position. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Original investment amount in cents. Immutable after open. Used for UnitsBaseValueCents fallback. |
| 48 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID (same as PositionHedgeServerID, included for backward compatibility). |
| 49 | InitExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID for the open execution. Links to Trade.OpenExecutionPlan. |
| 50 | EndExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID for the close execution. 0 (empty GUID) for open positions. From History.Position for closed. |
| 51 | RootHedgeServerID | int | YES | - | CODE-BACKED | For copy-trade: the root position's hedge server. Determines where the parent hedge is routed. |
| 52 | IsOpenOpen | bit | YES | - | CODE-BACKED | 1 = position opened via Open-Open flow (async order). 0 = synchronous open. |
| 53 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree identifier. Equals root position's PositionID. Links to Trade.PositionTreeInfo for shared SL/TP/TSL. |
| 54 | IsComputeForHedge | bit | YES | - | CODE-BACKED | 1 = include in hedge exposure aggregation, 0 = exclude (demo/dummy). Used by hedge exposure queries. |
| 55 | ExitOrderID | int | YES | - | CODE-BACKED | FK to Trade.Orders for the close order. NULL for open positions. Populated from History.Position. |
| 56 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | From PositionTreeInfo (open) or History.Position (closed). 1 = trailing stop-loss active, 0 = fixed stop. |
| 57 | IsMirrorActive | bit | NO | - | CODE-BACKED | Computed in view. Open: ISNULL(Trade.Mirror.IsActive, 0) - live check. Closed: hardcoded 0 (performance optimization). |
| 58 | SLManualVer | smallint | NO | - | CODE-BACKED | Stop-loss manual edit version. Open: from PositionTreeInfo. Closed: hardcoded -1 (irrelevant for closed). |
| 59 | FullCommission | money | YES | - | CODE-BACKED | Total commission including all components. From Trade.PositionTbl or History.Position. |
| 60 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Commission charged at close. NULL for open positions. From History.Position for closed. |
| 61 | IsSettled | bit | YES | - | CODE-BACKED | Legacy flag: 1 = real stock (owns shares), 0 = CFD. Predates SettlementTypeID. Used as fallback when SettlementTypeID is NULL. |
| 62 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement classification. Open: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)). 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. See [Settlement Type](_glossary.md#settlement-type). (Dictionary.SettlementTypes) |
| 63 | RedeemStatus | tinyint | YES | - | CODE-BACKED | For real stock: redemption state. 0=NotRedeemed, 1=RedeemPending, 2=Redeemed. (Dictionary.RedeemStatus) |
| 64 | RedeemID | bigint | YES | - | CODE-BACKED | Redemption operation ID. NULL for open positions (or not redeemed). From History.Position for closed. |
| 65 | CommissionOnClose | money | YES | - | CODE-BACKED | Close commission. NULL for open positions. From History.Position for closed. |
| 66 | EndForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID at close. NULL for open positions. From History.Position for closed. |
| 67 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Original units at open. Immutable. From Trade.PositionTbl (open) or History.Position (closed). |
| 68 | OriginalPositionID | bigint | YES | - | CODE-BACKED | For reopened positions: ID of the position this was reopened from. NULL for open positions. From History.Position for closed. |
| 69 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Computed in view (open): ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). Original investment in cents with fallback. Passes through for closed. |
| 70 | IsDiscounted | bit | YES | - | CODE-BACKED | From PositionTreeInfo (open) or History.Position (closed). 1 = discounted spread/fee tier, 0 = standard. |
| 71 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | If this position was created by reopening another, references the original. From Trade.PositionTbl or History.Position. |
| 72 | CloseTotalFees | money | YES | - | CODE-BACKED | Total fees charged at close. From Trade.PositionTbl or History.Position. |
| 73 | CloseTotalTaxes | money | YES | - | CODE-BACKED | Total taxes charged at close. From Trade.PositionTbl or History.Position. |
| 74 | OpenTotalFees | money | YES | - | CODE-BACKED | Total fees charged at open. From Trade.PositionTbl or History.Position. |
| 75 | OpenTotalTaxes | money | YES | - | CODE-BACKED | Total taxes charged at open. From Trade.PositionTbl or History.Position. |
| 76 | IsNoStopLoss | bit | YES | - | CODE-BACKED | From PositionTreeInfo (open) or History.Position (closed). 1 = no stop-loss allowed (e.g., certain crypto). NULL = standard SL applies. |
| 77 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | From PositionTreeInfo (open) or History.Position (closed). 1 = no take-profit allowed. NULL = standard TP applies. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open branch) | Trade.PositionTbl | Base Table | Open positions source. Filtered WHERE StatusID = 1. |
| (closed branch) | History.Position | Base Table | Closed/archived positions source. Cross-database reference to EtoroArchive. |
| InstrumentID | Trade.Instrument | JOIN | Provides BuyCurrencyID (ForexBuy) and SellCurrencyID (ForexSell) for the traded instrument. |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | JOIN | Provides Unit (Units) and Precision (InstrumentPrecision) for the instrument at this provider. |
| TreeID | Trade.PositionTreeInfo | JOIN | Provides LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, SLManualVer, IsDiscounted, IsNoStopLoss, IsNoTakeProfit for open positions. Partition-aligned JOIN. |
| MirrorID | Trade.Mirror | LEFT JOIN | Provides IsActive (IsMirrorActive) for open positions. LEFT JOIN because MirrorID=0 for manual trades. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOpenPositionsForMMRecovery | FROM | View | Market-maker recovery view for open positions. |
| Trade.GetRealEditSLMMRecovery | FROM | View | MM recovery for real SL edit operations. |
| Trade.GetDemoOpenPositionsForMMRecovery | FROM | View | MM recovery for demo open positions. |
| Trade.ClosePositionsGetRecoveryItemsDemo | FROM | View | Recovery items for demo close operations. |
| Trade.GetRealEditOWMMRecovery | FROM | View | MM recovery for real OW edit operations. |
| Trade.GetRealEditTPMMRecovery | FROM | View | MM recovery for real TP edit operations. |
| Trade.GetRecoveryItemsDemo | FROM | View | Demo recovery items view. |
| Trade.GetRealClosePositionMMRecovery | FROM | View | MM recovery for real close operations. |
| Trade.CheckListOfManuallPositions | FROM | Procedure | Checks a list of manual positions for validation. |
| Trade.GetPositionHierarchy_Rollback | FROM | Procedure | Rollback version of position hierarchy retrieval. |
| Trade.GetPositionsTree | FROM | Procedure | Retrieves copy-trade position tree structure. |
| Trade.GetPayedDividendsAndPositions | FROM | Procedure | Dividend payment reconciliation with position data. |
| Trade.InsertMostPopularInstruments | FROM | Procedure | Calculates most popular instruments from position data. |
| Trade.ForkByDB | FROM | Procedure | Database fork utility for position data. |
| Trade.GetTradingDATAforCopyFund | FROM | Procedure | Trading data retrieval for copy fund analysis. |
| Trade.SI_GetPositionDataBy_CO | FROM | Procedure | Service integration - position data by close order. |
| Trade.GetMirrorHierarchyExcludeOpenedPositions | FROM | Procedure | Mirror hierarchy excluding currently open positions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionData (view)
+-- Trade.PositionTbl (table)
+-- History.Position (table, cross-database)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | INNER JOIN - open positions source (WHERE StatusID=1) |
| History.Position | Table | INNER JOIN - closed positions source (cross-database) |
| Trade.Instrument | Table | INNER JOIN on InstrumentID - provides BuyCurrencyID, SellCurrencyID |
| Trade.ProviderToInstrument | Table | INNER JOIN on ProviderID + InstrumentID - provides Unit, Precision |
| Trade.PositionTreeInfo | Table | INNER JOIN on TreeID + PartitionCol - provides SL/TP/TSL (open branch only) |
| Trade.Mirror | Table | LEFT JOIN on MirrorID - provides IsActive (open branch only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOpenPositionsForMMRecovery | View | Reads from this view for market-maker recovery |
| Trade.GetRealEditSLMMRecovery | View | Reads for SL edit recovery |
| Trade.GetDemoOpenPositionsForMMRecovery | View | Reads for demo recovery |
| Trade.ClosePositionsGetRecoveryItemsDemo | View | Reads for demo close recovery |
| Trade.GetRealEditOWMMRecovery | View | Reads for OW edit recovery |
| Trade.GetRealEditTPMMRecovery | View | Reads for TP edit recovery |
| Trade.GetRecoveryItemsDemo | View | Reads for demo recovery items |
| Trade.GetRealClosePositionMMRecovery | View | Reads for real close recovery |
| Trade.CheckListOfManuallPositions | Procedure | READER - validates manual positions |
| Trade.GetPositionsTree | Procedure | READER - position tree traversal |
| Trade.GetPayedDividendsAndPositions | Procedure | READER - dividend payment reconciliation |
| Trade.InsertMostPopularInstruments | Procedure | READER - popularity calculation |
| Trade.ForkByDB | Procedure | READER - database fork utility |
| Trade.GetTradingDATAforCopyFund | Procedure | READER - copy fund analytics |
| Trade.SI_GetPositionDataBy_CO | Procedure | READER - service integration |
| Trade.GetMirrorHierarchyExcludeOpenedPositions | Procedure | READER - mirror hierarchy |
| Trade.GetPositionHierarchy_Rollback | Procedure | READER - hierarchy rollback |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. (View - no constraints.)

---

## 8. Sample Queries

### 8.1 Get all open positions for a customer

```sql
SELECT PositionID, InstrumentID, Amount, IsBuy, Leverage, LimitRate, StopRate, IsMirrorActive
FROM Trade.GetPositionData WITH (NOLOCK)
WHERE CID = @CID AND IsOpened = 1
```

### 8.2 Get full position lifecycle (open and closed) for an instrument

```sql
SELECT PositionID, CID, IsOpened, InitDateTime, EndDateTime, NetProfit, ActionType, SettlementTypeID
FROM Trade.GetPositionData WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY InitDateTime DESC
```

### 8.3 Get copy-trade tree positions with resolved instrument names

```sql
SELECT gpd.PositionID, gpd.CID, gpd.TreeID, gpd.ParentPositionID, gpd.MirrorID,
       gpd.Amount, gpd.IsBuy, i.SymbolFull, gpd.SettlementTypeID
FROM Trade.GetPositionData gpd WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON gpd.InstrumentID = i.InstrumentID
WHERE gpd.TreeID = @TreeID
ORDER BY gpd.ParentPositionID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trade Blotter Requirements | Confluence | Confirmed GetPositionData as the primary data source for the trade blotter UI, providing unified open+closed position data. |

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 77 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionData | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionData.sql*
