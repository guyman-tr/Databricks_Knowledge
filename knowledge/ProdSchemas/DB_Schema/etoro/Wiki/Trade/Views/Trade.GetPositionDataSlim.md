# Trade.GetPositionDataSlim

> Optimized unified position view combining open (PositionTbl) and closed (History.PositionSlim) positions with extra columns InitConversionRate and PnLVersion, using partition-aligned PositionTreeInfo JOINs - the preferred lightweight alternative to GetPositionData for hedge exposure, execution reports, and dividend queries.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionTbl / History.PositionSlim) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPositionDataSlim is the **preferred lightweight position view** for performance-sensitive queries. Like Trade.GetPositionData, it UNION ALLs open positions (from `Trade.PositionTbl WHERE StatusID = 1`) and closed positions, but sources closed data from `History.PositionSlim` (a more compact archive table) instead of `History.Position`. This makes it significantly faster for queries spanning large date ranges.

This view adds two columns not present in the base GetPositionData: `InitConversionRate` (the initial forex conversion rate stored separately from InitForexRate) and `PnLVersion` (version flag for the PnL calculation formula). These columns are needed by hedge exposure calculations (Hedge.GetCurrentOpenExposure) and execution report drilldowns. Otherwise, the column set is very similar to GetPositionData, including all fee/tax, reopen, settlement, and IsNoStopLoss/IsNoTakeProfit columns.

The open branch uses the same partition-aligned JOIN to Trade.PositionTreeInfo (`abs(TPOS.TreeID%50) = TPTI.PartitionCol`) as the base GetPositionData, ensuring efficient partition elimination. Key consumers include Hedge.GetCurrentOpenExposure, Hedge.GetHedgeEstimationsDiscrepencies, Trade.GetOrdersForExecutionReportDrillDown, Trade.GetHistoryAndLivePrivatePositionsByCid, Trade.GetPayedDividendsAndPositions, and Trade.OmeCheck.

---

## 2. Business Logic

### 2.1 Open vs Closed Unification (Same as GetPositionData)

**What**: UNION ALL merges open and closed positions with sentinel values.

**Columns/Parameters Involved**: `IsOpened`, `EndForexRate`, `EndDateTime`, `ActionType`, `NetProfit`, `IsMirrorActive`, `SLManualVer`

**Rules**:
- IsOpened = 1 (open): close-related columns NULL/0. IsMirrorActive live from Trade.Mirror. SLManualVer from PositionTreeInfo.
- IsOpened = 0 (closed): close columns from History.PositionSlim. IsMirrorActive = 0, SLManualVer = -1 (hardcoded).

### 2.2 InitConversionRate and PnLVersion

**What**: Extra columns for PnL formula versioning and initial conversion rate tracking.

**Columns/Parameters Involved**: `InitConversionRate`, `PnLVersion`

**Rules**:
- InitConversionRate: The forex conversion rate at position open, stored independently. Used by hedge exposure calculations alongside InitForexRate.
- PnLVersion: Version flag indicating which PnL calculation formula applies to this position. Different versions may use different rounding, fee inclusion, or conversion logic.

### 2.3 Settlement Type Fallback

**What**: Same ISNULL pattern as GetPositionData.

**Columns/Parameters Involved**: `IsSettled`, `SettlementTypeID`

**Rules**:
- Open branch: `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))`.
- Closed branch: direct pass-through from History.PositionSlim.

---

## 3. Data Overview

| PositionID | CID | InstrumentID | IsOpened | Currency | Leverage | IsBuy | Amount | SettlementTypeID | PnLVersion | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 2152077450 | 9707089 | 100017 | 1 | 1 | 1 | true | 0.93 | 1 | (varies) | Open real stock buy. PnLVersion indicates active calculation formula. |
| 2152077750 | 9743732 | 100017 | 1 | 1 | 1 | true | 1.35 | 1 | (varies) | Open real stock buy. Used by hedge exposure queries via IsComputeForHedge=1. |
| (historical) | (varies) | (varies) | 0 | (varies) | (varies) | (varies) | (varies) | (varies) | (varies) | Closed from History.PositionSlim. Includes EndDateTime, NetProfit, ActionType. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID. References Customer.Customer. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Deprecated. Set to -1 for new positions. |
| 4 | IsOpened | int | NO | - | CODE-BACKED | Computed: 1 = open (PositionTbl, StatusID=1), 0 = closed (History.PositionSlim). |
| 5 | Currency | int | NO | - | CODE-BACKED | Alias for CurrencyID. FK to Dictionary.Currency (1=USD, 2=EUR, etc.). |
| 6 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. |
| 8 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Alias for HedgeServerID. FK to Trade.HedgeServer. |
| 9 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier. |
| 10 | ForexBuy | int | YES | - | CODE-BACKED | From Trade.Instrument.BuyCurrencyID. |
| 11 | ForexSell | int | YES | - | CODE-BACKED | From Trade.Instrument.SellCurrencyID. |
| 12 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 13 | EndForexRate | float | YES | - | CODE-BACKED | Forex rate at close. NULL for open. |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | Position open timestamp. |
| 15 | EndDateTime | datetime | YES | - | CODE-BACKED | Position close timestamp. NULL for open. |
| 16 | ActionType | tinyint | YES | - | CODE-BACKED | Close action type. NULL for open. FK to Dictionary.ClosePositionActionType. |
| 17 | NetProfit | money | YES | - | CODE-BACKED | Realized PnL. NULL for open. |
| 18 | LimitRate | float | YES | - | CODE-BACKED | Take-profit from PositionTreeInfo (open) or History.PositionSlim (closed). |
| 19 | StopRate | float | YES | - | CODE-BACKED | Stop-loss from PositionTreeInfo (open) or History.PositionSlim (closed). |
| 20 | Amount | money | NO | - | CODE-BACKED | Position size in currency. |
| 21 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 22 | Commission | money | YES | - | CODE-BACKED | Open commission. |
| 23 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 24 | IsBuy | varchar | NO | - | CODE-BACKED | Computed: 'true' = buy/long, 'false' = sell/short. |
| 25 | CloseOnEndOfWeek | varchar | NO | - | CODE-BACKED | Computed: 'true' = weekend close, 'false' = stay open. |
| 26 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. |
| 27 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 28 | AdditionalParam | nvarchar(max) | YES | - | CODE-BACKED | Free-form parameters. NULL for closed. |
| 29 | OpenOccurred | datetime | YES | - | CODE-BACKED | Open order execution timestamp. |
| 30 | CloseOccurred | datetime | YES | - | CODE-BACKED | Close order execution timestamp. NULL for open. |
| 31 | OrderID | int | YES | - | CODE-BACKED | FK to Trade.Orders. |
| 32 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance. |
| 33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Copy-trade parent. 0/1 = root. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before re-parenting. |
| 36 | LastOpPriceRate | float | YES | - | CODE-BACKED | Last operation price rate. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last operation price rate snapshot. |
| 38 | LastOpConversionRate | float | YES | - | CODE-BACKED | Last operation conversion rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last operation conversion rate snapshot. |
| 40 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Per-unit margin requirement. |
| 41 | Units | decimal(18,8) | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Unit. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Precision. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror. 0 = manual. FK to Trade.Mirror. |
| 44 | PositionRatio | decimal(16,8) | YES | - | CODE-BACKED | Copier allocation fraction. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count for direct positions. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | FK to Trade.SpreadGroup. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Original investment in cents. |
| 48 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID. |
| 49 | InitExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Open execution correlation ID. |
| 50 | EndExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Close execution correlation ID. 0 for open. |
| 51 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root position's hedge server. |
| 52 | IsOpenOpen | bit | YES | - | CODE-BACKED | 1 = async open-open flow. |
| 53 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree ID. |
| 54 | IsComputeForHedge | bit | YES | - | CODE-BACKED | 1 = include in hedge exposure, 0 = exclude. Both branches pass actual value. |
| 55 | ExitOrderID | int | YES | - | CODE-BACKED | Close order FK. NULL for open. |
| 56 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | 1 = trailing stop active, 0 = fixed. |
| 57 | IsMirrorActive | bit | NO | - | CODE-BACKED | Open: from Trade.Mirror. Closed: hardcoded 0. |
| 58 | SLManualVer | smallint | NO | - | CODE-BACKED | SL edit version. Open: from PositionTreeInfo. Closed: -1. |
| 59 | FullCommission | money | YES | - | CODE-BACKED | Total commission. |
| 60 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Close commission. NULL for open. |
| 61 | IsSettled | bit | YES | - | CODE-BACKED | Legacy: 1 = real stock, 0 = CFD. |
| 62 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Open: ISNULL fallback. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes) |
| 63 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redemption state. |
| 64 | RedeemID | bigint | YES | - | CODE-BACKED | Redemption operation ID. NULL for open. |
| 65 | CommissionOnClose | money | YES | - | CODE-BACKED | Close commission. NULL for open. |
| 66 | EndForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at close. NULL for open. |
| 67 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Original units at open. From PositionTbl (open) or History.PositionSlim (closed). |
| 68 | OriginalPositionID | bigint | YES | - | CODE-BACKED | For reopened positions. NULL for open. |
| 69 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Open: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). Closed: direct from History.PositionSlim. |
| 70 | IsDiscounted | bit | YES | - | CODE-BACKED | From PositionTreeInfo (open) or ISNULL(History, 0) (closed). 1 = discounted tier. |
| 71 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | References original position if reopened. |
| 72 | InitConversionRate | float | YES | - | CODE-BACKED | **Slim-exclusive**: Initial forex conversion rate at open. Stored separately from InitForexRate. Used by hedge exposure calculations. |
| 73 | PnLVersion | tinyint | YES | - | CODE-BACKED | **Slim-exclusive**: PnL calculation formula version. Determines rounding, fee inclusion, and conversion logic for this position. |
| 74 | CloseTotalFees | money | YES | - | CODE-BACKED | Total fees at close. |
| 75 | CloseTotalTaxes | money | YES | - | CODE-BACKED | Total taxes at close. |
| 76 | OpenTotalFees | money | YES | - | CODE-BACKED | Total fees at open. |
| 77 | OpenTotalTaxes | money | YES | - | CODE-BACKED | Total taxes at open. |
| 78 | IsNoStopLoss | bit | YES | - | CODE-BACKED | From PositionTreeInfo (open) or History.PositionSlim (closed). 1 = no SL allowed. |
| 79 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | From PositionTreeInfo (open) or History.PositionSlim (closed). 1 = no TP allowed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open branch) | Trade.PositionTbl | Base Table | Open positions (StatusID=1). |
| (closed branch) | History.PositionSlim | Base Table | Closed positions from slim archive. |
| InstrumentID | Trade.Instrument | JOIN | Provides ForexBuy, ForexSell. |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | JOIN | Provides Units, InstrumentPrecision. |
| TreeID | Trade.PositionTreeInfo | JOIN | Partition-aligned (abs(TreeID%50)=PartitionCol). Provides SL/TP/TSL/IsDiscounted/IsNoSL/IsNoTP. |
| MirrorID | Trade.Mirror | LEFT JOIN | Provides IsMirrorActive for open positions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetCurrentOpenExposure | FROM | Procedure | Reads open positions for current hedge exposure calculation. |
| Hedge.GetHedgeEstimationsDiscrepencies | FROM | Procedure | Checks hedge estimation discrepancies against actual positions. |
| Hedge.GetHBCEstimationsDiscrepencies_Flat | FROM | Procedure | Flat version of hedge discrepancy check. |
| Hedge.GetHBCEstimationsDiscrepencies | FROM | Procedure | HBC estimation discrepancy analysis. |
| Trade.GetOrdersForExecutionReportDrillDown | FROM | Procedure | Execution report detail drilldown. |
| Trade.GetHistoryAndLivePrivatePositionsByCid | FROM | Procedure | Full position history for a customer. |
| Trade.GetPayedDividendsAndPositions | FROM | Procedure | Dividend payment reconciliation. |
| Trade.OmeCheck | FROM | Procedure | Order matching engine validation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionDataSlim (view)
+-- Trade.PositionTbl (table)
+-- History.PositionSlim (table, cross-database)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Open positions (WHERE StatusID=1), partition-aligned TreeInfo JOIN |
| History.PositionSlim | Table | Closed positions (cross-database) |
| Trade.Instrument | Table | JOIN on InstrumentID |
| Trade.ProviderToInstrument | Table | JOIN on ProviderID + InstrumentID |
| Trade.PositionTreeInfo | Table | Partition-aligned JOIN on TreeID + PartitionCol |
| Trade.Mirror | Table | LEFT JOIN on MirrorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetCurrentOpenExposure | Procedure | READER - hedge exposure |
| Hedge.GetHedgeEstimationsDiscrepencies | Procedure | READER - hedge discrepancy |
| Hedge.GetHBCEstimationsDiscrepencies_Flat | Procedure | READER - HBC flat discrepancy |
| Hedge.GetHBCEstimationsDiscrepencies | Procedure | READER - HBC discrepancy |
| Trade.GetOrdersForExecutionReportDrillDown | Procedure | READER - execution report |
| Trade.GetHistoryAndLivePrivatePositionsByCid | Procedure | READER - customer history |
| Trade.GetPayedDividendsAndPositions | Procedure | READER - dividend payment |
| Trade.OmeCheck | Procedure | READER - OME validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Open positions for hedge exposure

```sql
SELECT PositionID, CID, InstrumentID, Amount, Leverage, IsComputeForHedge,
       InitConversionRate, PnLVersion
FROM Trade.GetPositionDataSlim WITH (NOLOCK)
WHERE IsOpened = 1 AND IsComputeForHedge = 1
```

### 8.2 Full position lifecycle for a customer

```sql
SELECT PositionID, InstrumentID, IsOpened, InitDateTime, EndDateTime,
       NetProfit, SettlementTypeID, PnLVersion
FROM Trade.GetPositionDataSlim WITH (NOLOCK)
WHERE CID = @CID
ORDER BY InitDateTime DESC
```

### 8.3 Dividend-eligible positions with settlement resolution

```sql
SELECT gpds.PositionID, gpds.CID, gpds.InstrumentID, gpds.Amount,
       gpds.SettlementTypeID, dst.Name AS SettlementName, gpds.IsDiscounted
FROM Trade.GetPositionDataSlim gpds WITH (NOLOCK)
LEFT JOIN Dictionary.SettlementTypes dst WITH (NOLOCK) ON gpds.SettlementTypeID = dst.SettlementTypeID
WHERE gpds.IsOpened = 1 AND gpds.SettlementTypeID IN (1, 4)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this view. Related context from Trade Blotter Requirements Confluence page confirms position data views are the primary trade blotter data layer.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 79 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionDataSlim | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionDataSlim.sql*
