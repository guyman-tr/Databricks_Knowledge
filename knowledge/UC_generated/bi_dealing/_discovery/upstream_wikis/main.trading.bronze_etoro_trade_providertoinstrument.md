# Trade.ProviderToInstrument

> Per-provider, per-instrument trading configuration that defines fees, limits, allowed operations, and risk parameters for each instrument routed through each execution provider.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID, InstrumentID (composite PK) |
| **Partition** | No |
| **Indexes** | 4 active (PK + IX_ProviderToInstrument_AmountFormula, TPVI_INSTRUMENT, TPVI_PROVIDER) |

---

## 1. Business Meaning

Trade.ProviderToInstrument is the junction table that links each Trade.Provider (execution venue, e.g., Tradonomi) to each Trade.Instrument (tradeable asset, e.g., EUR/USD, Bayer AG) and holds the provider-specific trading configuration for that pair. While Trade.Instrument defines what can be traded and Trade.Provider defines who executes, ProviderToInstrument defines **how** each instrument is traded through each provider: precision, fees, min/max position size, spread parameters, and dozens of Allow* flags that control which trading operations are permitted.

This table exists because the same instrument can be offered through multiple providers with different terms (fees, leverage, order types), and a single provider may offer thousands of instruments with varying configurations. Without it, the system could not determine which operations are allowed for a given position, what fees to apply, or what risk limits (stop-loss, take-profit, max position) apply. Trade.GetProviderToInstrument, position views (GetPositionData, GetPositionDataSlim), and order/close procedures all JOIN here to resolve Unit, Precision, MinPositionAmount, and Allow* flags.

Data is created via `Trade.ProviderToInstrumentAdd` and edited by `Trade.ProviderToInstrumentEdit`. On INSERT, triggers populate `Trade.CurrencyPrice` with zero bid/ask and `History.ProviderToInstrument` with a new valid-from row. System versioning tracks all changes to `History.TradeProviderToInstrument`. ASM-generated audit triggers log key columns to `History.AuditHistory`.

---

## 2. Business Logic

### 2.1 Provider-Instrument Pair as Trading Configuration

**What**: Each row is a unique (ProviderID, InstrumentID) pair that defines trading parameters for that combination.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Enabled`, `AllowBuy`, `AllowSell`, `AllowPendingOrders`, `AllowEntryOrders`, `AllowClosePosition`, `AllowExitOrder`, etc.

**Rules**:
- One row per (ProviderID, InstrumentID). Enabled=1 means the instrument is tradeable through that provider; Enabled=0 disables trading.
- AllowBuy/AllowSell control direction. AllowPendingOrders/AllowEntryOrders control order types. AllowClosePosition/AllowExitOrder control close behavior.
- VisibleInternallyOnly=1 hides the instrument from external clients; used for internal/ops instruments.
- Trade.CheckValidInstruments, Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage raise error 60127 if InstrumentID is not found in ProviderToInstrument.

**Diagram**:
```
ProviderID=1 (Tradonomi) + InstrumentID=1 (EUR/USD) -> AllowBuy=1, AllowSell=1, Precision=3, Unit=1000
ProviderID=1 + InstrumentID=2 (GBP) -> AllowBuy=1, AllowSell=0 (sell disabled)
ProviderID=1 + InstrumentID=3 (NZD/USD) -> AllowBuy=0, AllowSell=1
```

### 2.2 Stop-Loss and Take-Profit Constraints

**What**: Min/max and default values for SL/TP percentages, with separate rules for leveraged vs non-leveraged positions.

**Columns/Parameters Involved**: `MinStopLossPercentage`, `MaxStopLossPercentage`, `DefaultStopLossPercentage`, `MinTakeProfitPercentage`, `MaxTakeProfitPercentage`, `DefaultTakeProfitPercentage`, `AllowLeveragedLongSL`, `AllowNonLeveragedLongSL`, `AllowLeveragedShortSL`, `AllowNonLeveragedShortSL`, `AllowLeveragedLongTP`, etc.

**Rules**:
- User-configured SL/TP must lie within [MinStopLossPercentage, MaxStopLossPercentage] and [MinTakeProfitPercentage, MaxTakeProfitPercentage].
- AllowLeveragedLongSL/AllowNonLeveragedLongSL (and Short equivalents) control whether SL is allowed for each direction and leverage type.
- DefaultStopLossPercentage/DefaultTakeProfitPercentage are used when opening positions without explicit SL/TP.
- GuaranteeSLTP=1 means broker guarantees execution at SL/TP levels; AllowEditSLTP controls whether user can change after open.

### 2.3 Fee and Margin Configuration

**What**: End-of-week, overnight, and holding fees plus margin requirements per instrument-provider pair.

**Columns/Parameters Involved**: `EndOfWeekFee`, `BuyEOWFee`, `SellEOWFee`, `BuyOverNightFee`, `SellOverNightFee`, `EtoroHoldingFeeSpreadFactor`, `Leverage1MaintenanceMargin`, `Unit`, `UnitMargin`, `LiquidityLotSize`, `LiquidityLotCost`.

**Rules**:
- EOW and overnight fees can differ by direction (Buy vs Sell). EtoroHoldingFeeSpreadFactor > 0 (CHECK constraint).
- Leverage1MaintenanceMargin is the margin percentage at 1x leverage.
- Unit and UnitMargin drive position size and pip-value calculations. HedgeExposureQuery uses PTI.Unit when resolving exposure.

---

## 3. Data Overview

| ProviderID | InstrumentID | PresentationCode | Enabled | AllowBuy | AllowSell | VisibleInternallyOnly | Meaning |
|------------|--------------|------------------|---------|----------|-----------|------------------------|---------|
| 1 | 1 | EURUSD= | 1 | 1 | 1 | 0 | EUR/USD forex pair. Full buy/sell, external. Standard forex configuration for major pair. |
| 1 | 2 | GBP= | 1 | 1 | 0 | 1 | GBP currency. Buy only, internally visible (likely ops/test). Sell disabled. |
| 1 | 3 | NZDUSD12= | 1 | 0 | 1 | 0 | NZD/USD pair. Sell only (no buy). Used when swap/funding favors one direction. |
| 1 | 5 | JPY= | 1 | 1 | 1 | 0 | JPY forex. Both directions, pending/entry orders allowed. High pip-value instrument (AboveDollarPrecision=3). |
| 1 | 10 | EURJPY= | 1 | 1 | 1 | 0 | EUR/JPY cross. Full trading. Leverage1MaintenanceMargin=0 indicates special margin treatment. |

**Selection criteria**: Picked from live TOP 10 by InstrumentID. EUR/USD (1), GBP (2), NZD/USD (3), CAD (4), JPY (5), CHF (6), AUD (7), EUR/GBP (8), EUR/CHF (9), EUR/JPY (10) show variety of AllowBuy/AllowSell combinations and VisibleInternallyOnly.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 0 | CODE-BACKED | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). Part of PK. |
| 2 | InstrumentID | int | NO | 0 | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. Part of PK. |
| 3 | Precision | tinyint | NO | - | CODE-BACKED | Decimal places for price display and rounding. Used by Trade.ChangeTreePropertiesPerInstrument, Trade.UpdatePositionsTakeProfitByInstrumentID. |
| 4 | PaymentBid | int | NO | - | CODE-BACKED | Bid-side payment adjustment (basis points or similar). Negative values observed (e.g., -250). |
| 5 | PaymentAsk | int | NO | - | CODE-BACKED | Ask-side payment adjustment. Positive values observed (e.g., 250). |
| 6 | PresentationCode | varchar(20) | NO | - | CODE-BACKED | Display code for the instrument (e.g., EURUSD=, GBP=, JPY=). Used in UI and reporting. |
| 7 | StopLossPercentage | int | NO | - | CODE-BACKED | Legacy or alternate SL percentage field. Sample data shows 0. |
| 8 | EndOfWeekFee | money | NO | - | CODE-BACKED | End-of-week holding fee. Used in ClaimEndOfWeekFee, fee calculations. |
| 9 | Unit | int | NO | - | CODE-BACKED | Base unit size for the instrument. HedgeExposureQuery uses PTI.Unit. Typically 1000 for forex. |
| 10 | UnitMargin | int | NO | - | CODE-BACKED | Margin factor per unit. Used in margin and exposure calculations. |
| 11 | Benchmark | int | NO | - | CODE-BACKED | Reference value for pricing (e.g., 10000 for forex). |
| 12 | LiquidityLotSize | int | NO | - | CODE-BACKED | Lot size for liquidity provider orders. |
| 13 | LiquidityLotCost | money | NO | - | CODE-BACKED | Cost per liquidity lot. |
| 14 | DisplayOrder | int | NO | - | CODE-BACKED | Sort order for UI display. |
| 15 | WeekendPips | int | YES | - | CODE-BACKED | Weekend spread or fee in pips. |
| 16 | MinimumSpread | dbo.dtPrice | YES | - | CODE-BACKED | Minimum spread allowed. |
| 17 | OrdersSpread | int | YES | - | CODE-BACKED | Spread applied to orders. Sample 200. |
| 18 | OrdersSpreadMax | int | YES | - | CODE-BACKED | Maximum spread for orders. Sample 10. |
| 19 | MarketRange | int | YES | - | CODE-BACKED | Market range validation limit. Sample 10000000. |
| 20 | SpreadPct | dbo.dtPrice | NO | 0 | CODE-BACKED | Spread as percentage. |
| 21 | BonusCreditUsePercent | int | NO | 0 | CODE-BACKED | Percentage of position that can use bonus credit. Trade.InstrumentNWADecreasePercentage view. |
| 22 | BuyEOWFee | money | NO | - | CODE-BACKED | End-of-week fee for buy positions. |
| 23 | SellEOWFee | money | NO | - | CODE-BACKED | End-of-week fee for sell positions. |
| 24 | BuyOverNightFee | money | YES | - | CODE-BACKED | Overnight fee for buy positions. |
| 25 | SellOverNightFee | money | YES | - | CODE-BACKED | Overnight fee for sell positions. |
| 26 | MaxStopLossPercentage | decimal(5,2) | NO | 100 | CODE-BACKED | Maximum allowed stop-loss percentage. Enforced on edit. |
| 27 | Enabled | tinyint | NO | 0 | CODE-BACKED | 1=instrument tradeable through this provider, 0=disabled. Trade.GetProviderToInstrument filters Enabled=1. |
| 28 | AllowedRateDiffPercentage | decimal(5,2) | NO | 90 | CODE-BACKED | Max allowed rate difference for order execution validation. |
| 29 | EtoroHoldingFeeSpreadFactor | money | NO | 1 | CODE-BACKED | Multiplier for eToro holding fee. CHECK > 0. |
| 30 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Max position size in units. CHECK <= 2147483647. |
| 31 | MinPositionAmount | money | NO | - | CODE-BACKED | Minimum position size in currency. Trade.InstrumentMinPositionAmount view. |
| 32 | AllowBuy | bit | NO | 1 | CODE-BACKED | 1=buy allowed, 0=buy disabled for this instrument-provider pair. |
| 33 | AllowSell | bit | NO | 1 | CODE-BACKED | 1=sell allowed, 0=sell disabled. |
| 34 | AllowPendingOrders | bit | NO | 1 | CODE-BACKED | 1=pending orders allowed, 0=market only. |
| 35 | AllowEntryOrders | bit | NO | 1 | CODE-BACKED | 1=entry orders allowed, 0=no entry orders. |
| 36 | VisibleInternallyOnly | bit | NO | 0 | CODE-BACKED | 1=hidden from external clients (internal/ops only), 0=visible to all. |
| 37 | AllowClosePosition | bit | NO | 1 | CODE-BACKED | 1=user can close position, 0=close disabled. |
| 38 | AllowExitOrder | bit | NO | 1 | CODE-BACKED | 1=exit orders allowed, 0=no exit orders. |
| 39 | GuaranteeSLTP | bit | NO | 0 | CODE-BACKED | 1=broker guarantees SL/TP execution, 0=no guarantee. |
| 40 | AllowEditSLTP | bit | NO | 1 | CODE-BACKED | 1=user can edit SL/TP after open, 0=no edit. |
| 41 | MaxTakeProfitPercentage | decimal(7,2) | NO | 1000 | CODE-BACKED | Maximum allowed take-profit percentage. |
| 42 | MaxClosingPriceDiffPercentage | decimal(5,2) | YES | - | CODE-BACKED | Max allowed closing price difference. Sample 5. |
| 43 | SettledBuyMaxLeverage | int | NO | 0 | CODE-BACKED | Max leverage for settled (real) buy positions. 0=not applicable. |
| 44 | SettledSellMaxLeverage | int | NO | 0 | CODE-BACKED | Max leverage for settled sell positions. |
| 45 | AllowManualTrading | bit | NO | 1 | CODE-BACKED | 1=manual trading allowed, 0=copy-only or disabled. |
| 46 | Leverage1MaintenanceMargin | decimal(5,2) | NO | 100 | CODE-BACKED | Maintenance margin percentage at 1x leverage. Sample 100 or 11.11. |
| 47 | RequiresW8Ben | bit | NO | 0 | CODE-BACKED | 1=US tax form W-8BEN required for this instrument, 0=not required. |
| 48 | MinStopLossPercentage | decimal(5,2) | NO | 0 | CODE-BACKED | Minimum allowed stop-loss percentage. |
| 49 | MinTakeProfitPercentage | decimal(7,2) | NO | 0 | CODE-BACKED | Minimum allowed take-profit percentage. |
| 50 | DefaultStopLossPercentage | decimal(5,2) | NO | 50 | CODE-BACKED | Default SL when opening without explicit SL. |
| 51 | DefaultTakeProfitPercentage | decimal(7,2) | NO | 50 | CODE-BACKED | Default TP when opening without explicit TP. |
| 52 | AllowTrailingStopLoss | bit | NO | 1 | CODE-BACKED | 1=trailing SL allowed, 0=not allowed. |
| 53 | DefaultTrailingStopLoss | bit | NO | 0 | CODE-BACKED | 1=trailing SL on by default, 0=off by default. |
| 54 | AllowEditStopLoss | bit | NO | 1 | CODE-BACKED | 1=user can edit SL, 0=no edit. |
| 55 | AllowEditTakeProfit | bit | NO | 1 | CODE-BACKED | 1=user can edit TP, 0=no edit. |
| 56 | AllowLeveragedLongSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for leveraged long positions, 0=not allowed. |
| 57 | AllowNonLeveragedLongSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for non-leveraged long, 0=not allowed. |
| 58 | AllowLeveragedShortSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for leveraged short, 0=not allowed. |
| 59 | AllowNonLeveragedShortSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for non-leveraged short, 0=not allowed. |
| 60 | AllowLeveragedLongTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for leveraged long, 0=not allowed. |
| 61 | AllowNonLeveragedLongTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for non-leveraged long, 0=not allowed. |
| 62 | AllowLeveragedShortTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for leveraged short, 0=not allowed. |
| 63 | AllowNonLeveragedShortTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for non-leveraged short, 0=not allowed. |
| 64 | AllowRedeem | tinyint | NO | 0 | CODE-BACKED | Redeem/withdrawal allowance. 0=no redeem, 1+=allowed with constraints. |
| 65 | MinPositionUnitsForRedeem | decimal(16,8) | YES | 0.1 | CODE-BACKED | Min units for redeem when AllowRedeem > 0. |
| 66 | MaxPositionUnitsForRedeem | decimal(16,8) | YES | 100000 | CODE-BACKED | Max units for redeem. |
| 67 | AllowEditStopLossLeveraged | bit | NO | 1 | CODE-BACKED | 1=edit SL allowed for leveraged positions, 0=no edit. |
| 68 | AllowEditTakeProfitLeveraged | bit | NO | 1 | CODE-BACKED | 1=edit TP allowed for leveraged positions, 0=no edit. |
| 69 | AllowPartialClosePosition | tinyint | NO | 1 | CODE-BACKED | 1=partial close allowed, 0=full close only. |
| 70 | DefaultStopLossPercentageLeveraged | decimal(7,2) | NO | 50 | CODE-BACKED | Default SL for leveraged positions. |
| 71 | DefaultStopLossPercentageNonLeveraged | decimal(7,2) | NO | 50 | CODE-BACKED | Default SL for non-leveraged positions. |
| 72 | ExchangeFeeMultiplier | tinyint | YES | - | CODE-BACKED | Multiplier for exchange fee. Sample 2 or 4. |
| 73 | DbLoginName | varchar(128) | NO | - | CODE-BACKED | Computed: suser_name(). Current DB login. |
| 74 | AppLoginName | varchar(500) | NO | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context. |
| 75 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start. GENERATED ALWAYS AS ROW START. |
| 76 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System versioning row end. GENERATED ALWAYS AS ROW END. |
| 77 | AboveDollarPrecision | tinyint | NO | - | CODE-BACKED | Precision for amounts above dollar threshold. Sample 3 or 5. |
| 78 | MarketRangeValidationType | tinyint | NO | 1 | CODE-BACKED | How market range is validated. 1=default, 2=percentage-based. |
| 79 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Market range as percentage when MarketRangeValidationType=2. Sample 0.2, 0.5. |
| 80 | DesignatedExecutionSystem | tinyint | NO | 1 | CODE-BACKED | Execution system routing. 1=default. Trade.UpdateDesignatedExecutionSystemBulk updates. |
| 81 | InitialMarginInAssetCurrency | decimal(16,8) | YES | - | CODE-BACKED | Initial margin in asset currency. Sample 90, 3, or NULL. |
| 82 | StopLossMarginInAssetCurrency | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss margin in asset currency. Sample 80, 3, or NULL. |
| 83 | AllowedOpenOrderType | tinyint | NO | 0 | CODE-BACKED | Allowed open order types. 0=default. |
| 84 | UnitsQuantityType | tinyint | NO | 0 | CODE-BACKED | How units/quantity are expressed. 0=default. |
| 85 | TradeUnitType | tinyint | NO | 0 | CODE-BACKED | Unit type for trading. 0=default. |
| 86 | OrderFillBehaviorType | tinyint | NO | 0 | CODE-BACKED | Order fill behavior. 0=default. |
| 87 | AmountFormula | tinyint | NO | 0 | CODE-BACKED | Formula for position amount calculation. Indexed for lookups. |
| 88 | Slippage | decimal(10,4) | YES | - | CODE-BACKED | Allowed slippage. Sample 0, 3, 8. Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage. |
| 89 | ExtendedMarginAllowed | bit | NO | 0 | CODE-BACKED | 1=extended margin allowed, 0=standard only. |
| 90 | AllowedRateDiffPercentageUpside | decimal(8,2) | NO | 999 | CODE-BACKED | Max rate diff on upside. Default 999 (effectively unlimited). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Trade.Provider | FK | Execution provider (e.g., Tradonomi). ProviderToInstrument rows exist per provider-instrument pair. |
| InstrumentID | Trade.Instrument | FK | Tradeable instrument. Each instrument can have multiple provider configs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetProviderToInstrument | FROM | JOIN | Primary view exposing provider-instrument config to clients. |
| Trade.GetInstrumentTradingData | FROM | JOIN | Instrument trading data. |
| Trade.GetPositionData, Trade.GetPositionDataSlim | TP2I | JOIN | Position data with Unit, Precision, config. |
| Trade.GetInstrumentDataDealing | PTI | JOIN | Dealing instrument data. |
| Trade.SplitOpenPositions | FROM | JOIN | Split positions by provider-instrument. |
| Trade.ProviderToInstrumentAdd | INSERT | Writer | Creates new rows. |
| Trade.ProviderToInstrumentEdit | UPDATE | Modifier | Updates config. |
| Trade.ProviderToInstrumentDelete | DELETE | Deleter | Removes provider-instrument link. |
| Trade.CheckValidInstruments | EXISTS | Lookup | Validates instrument exists in ProviderToInstrument. |
| Trade.HedgeExposureQuery | PTI | JOIN | Resolves Unit for hedge exposure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrument (table)
├── Trade.Provider (table)
└── Trade.Instrument (table)
      └── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | FK ProviderID. Provider must exist. |
| Trade.Instrument | Table | FK InstrumentID. Instrument must exist. |
| dbo.dtPrice | UDT | Used for MinimumSpread, SpreadPct columns. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetProviderToInstrument | View | Primary read path. |
| Trade.GetInstrumentTradingData | View | JOIN for config. |
| Trade.GetPositionData, Trade.GetPositionDataSlim | View | JOIN for Unit, config. |
| Trade.ProviderToInstrumentAdd | Procedure | INSERT. |
| Trade.ProviderToInstrumentEdit | Procedure | UPDATE. |
| Trade.ProviderToInstrumentDelete | Procedure | DELETE. |
| Trade.CheckValidInstruments | Procedure | EXISTS check. |
| Trade.HedgeExposureQuery | Procedure | JOIN for Unit. |
| Trade.GetInstrumentSlippage, Trade.SetInstrumentSlippage | Procedure | Read/update Slippage. |
| History.TradeProviderToInstrument | Table | System versioning history. |
| History.ProviderToInstrument | Table | Trigger-maintained history (ValidFrom/ValidTo). |
| Trade.CurrencyPrice | Table | InstrumentProviderInsert trigger seeds row on INSERT. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPVI | NC PK | ProviderID, InstrumentID | - | - | Active |
| IX_ProviderToInstrument_AmountFormula | NC | InstrumentID, ProviderID | AmountFormula | - | Active |
| TPVI_INSTRUMENT | NC | InstrumentID | - | - | Active |
| TPVI_PROVIDER | NC | ProviderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TSISR_TSPTI | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_TSPRV_TSPTI | FK | ProviderID -> Trade.Provider(ProviderID) |
| CH_TradeProviderToInstrument_EtoroHoldingFeeSpreadFactor | CHECK | EtoroHoldingFeeSpreadFactor > 0 |
| chk_MaxPositionUnits_max_value | CHECK | MaxPositionUnits <= 2147483647 |
| TPVI_NULLPROVIDER | DEFAULT | ProviderID = 0 |
| TPVI_NULLINSTRUMENT | DEFAULT | InstrumentID = 0 |
| (Multiple) | DEFAULT | Various columns have defaults per DDL |

---

## 8. Sample Queries

### 8.1 List enabled instruments for a provider
```sql
SELECT pti.InstrumentID, pti.PresentationCode, pti.Precision, pti.Unit, pti.MinPositionAmount,
       pti.AllowBuy, pti.AllowSell, pti.Enabled
  FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
 WHERE pti.ProviderID = 1 AND pti.Enabled = 1
 ORDER BY pti.InstrumentID;
```

### 8.2 Get provider-instrument config with instrument and provider names
```sql
SELECT pti.ProviderID, prov.Name AS ProviderName, pti.InstrumentID, ins.BuyCurrencyID, ins.SellCurrencyID,
       pti.PresentationCode, pti.Precision, pti.Unit, pti.MinPositionAmount, pti.MaxStopLossPercentage,
       pti.AllowBuy, pti.AllowSell
  FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
 INNER JOIN Trade.Provider prov WITH (NOLOCK) ON prov.ProviderID = pti.ProviderID
 INNER JOIN Trade.Instrument ins WITH (NOLOCK) ON ins.InstrumentID = pti.InstrumentID
 WHERE pti.Enabled = 1
 ORDER BY pti.InstrumentID, pti.ProviderID;
```

### 8.3 Find instruments with sell disabled (buy-only)
```sql
SELECT pti.InstrumentID, pti.PresentationCode, pti.ProviderID, pti.AllowBuy, pti.AllowSell,
       pti.VisibleInternallyOnly
  FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
 WHERE pti.Enabled = 1 AND pti.AllowBuy = 1 AND pti.AllowSell = 0
 ORDER BY pti.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Important DBs and DB Main | Confluence | Database architecture context |
| EtoroOps Flows - Screen List Documentation | Confluence | Ops workflow references |
| Routing Tool Mapping | Confluence | Provider/instrument routing context |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 90 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 20+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrument | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ProviderToInstrument.sql*
