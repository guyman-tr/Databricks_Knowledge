# Trade.ProviderToInstrumentSafty

> SCHEMABINDING safety wrapper exposing nearly all columns from Trade.ProviderToInstrument for critical real-time trading components requiring schema stability guarantees.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID, InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.ProviderToInstrumentSafty is a SCHEMABINDING view that exposes nearly all columns from Trade.ProviderToInstrument. The "Safty" typo is retained for backward compatibility. SCHEMABINDING prevents the base table from being altered in ways that would break this view - adding or dropping columns, changing data types, or renaming - ensuring schema stability for consumers.

This view exists because critical real-time trading components need the full instrument-provider configuration (fees, spread settings, trading permissions, SL/TP limits) with schema stability guarantees. Direct queries against the base table risk breakage when schema changes are deployed; the view acts as a contract. The view includes system versioning columns (SysStartTime, SysEndTime) for temporal queries and audit columns (DbLoginName, AppLoginName).

The view is a simple pass-through SELECT with no filter or join. All 70+ columns from Trade.ProviderToInstrument are exposed. Key identifiers are ProviderID and InstrumentID (composite key for the provider-instrument pair).

---

## 2. Business Logic

**Pass-through**: No filter, no join, no computed columns. All columns map directly to Trade.ProviderToInstrument.

**SCHEMABINDING**: The view is created WITH SCHEMABINDING. This prevents schema changes to the base table that would invalidate the view. Any attempt to ALTER Trade.ProviderToInstrument in a breaking way will fail if this view exists.

---

## 3. Data Overview

N/A - output mirrors Trade.ProviderToInstrument. See [Trade.ProviderToInstrument](../Tables/Trade.ProviderToInstrument.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Provider identifier. FK to Trade.Provider. Part of composite key. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. Part of composite key. |
| 3 | **Pricing and Display** | - | - | - | CODE-BACKED | Precision, PaymentBid, PaymentAsk, PresentationCode, DisplayOrder, Unit, UnitMargin, Benchmark, AboveDollarPrecision |
| 4 | **Fee Settings** | - | - | - | CODE-BACKED | EndOfWeekFee, BuyEOWFee, SellEOWFee, BuyOverNightFee, SellOverNightFee, WeekendPips, BonusCreditUsePercent, ExchangeFeeMultiplier |
| 5 | **Spread and Market** | - | - | - | CODE-BACKED | MinimumSpread, OrdersSpread, OrdersSpreadMax, MarketRange, SpreadPct, LiquidityLotSize, LiquidityLotCost |
| 6 | **Trading Permissions** | - | - | - | CODE-BACKED | Enabled, AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders, AllowClosePosition, AllowExitOrder, AllowManualTrading, VisibleInternallyOnly |
| 7 | **Stop-Loss Settings** | - | - | - | CODE-BACKED | StopLossPercentage, MaxStopLossPercentage, MinStopLossPercentage, DefaultStopLossPercentage, AllowTrailingStopLoss, DefaultTrailingStopLoss, AllowEditStopLoss, AllowLeveragedLongSL, AllowNonLeveragedLongSL, AllowLeveragedShortSL, AllowNonLeveragedShortSL, AllowEditStopLossLeveraged, DefaultStopLossPercentageLeveraged, DefaultStopLossPercentageNonLeveraged |
| 8 | **Take-Profit Settings** | - | - | - | CODE-BACKED | MaxTakeProfitPercentage, MinTakeProfitPercentage, DefaultTakeProfitPercentage, AllowEditTakeProfit, AllowLeveragedLongTP, AllowNonLeveragedLongTP, AllowLeveragedShortTP, AllowNonLeveragedShortTP, AllowEditTakeProfitLeveraged |
| 9 | **Position Limits** | - | - | - | CODE-BACKED | MaxPositionUnits, MinPositionAmount, MinPositionUnitsForRedeem, MaxPositionUnitsForRedeem |
| 10 | **SL/TP and Close** | - | - | - | CODE-BACKED | GuaranteeSLTP, AllowEditSLTP, MaxClosingPriceDiffPercentage, AllowPartialClosePosition |
| 11 | **Leverage and Margin** | - | - | - | CODE-BACKED | SettledBuyMaxLeverage, SettledSellMaxLeverage, Leverage1MaintenanceMargin |
| 12 | **Validation** | - | - | - | CODE-BACKED | AllowedRateDiffPercentage, EtoroHoldingFeeSpreadFactor, RequiresW8Ben |
| 13 | **Redeem** | - | - | - | CODE-BACKED | AllowRedeem |
| 14 | **Default SL/TP (Leveraged)** | - | - | - | CODE-BACKED | DefaultStopLossPercentageLeveraged, DefaultTakeProfitPercentage (non-leveraged variants) |
| 15 | **System Versioning** | - | - | - | CODE-BACKED | SysStartTime, SysEndTime - temporal table valid-from/valid-to |
| 16 | **Audit** | - | - | - | CODE-BACKED | DbLoginName, AppLoginName - last modifier identifiers |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Trade.Provider | FK | Execution provider |
| InstrumentID | Trade.Instrument | FK | Financial instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrument
    ^
Trade.ProviderToInstrumentSafty
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Base table. Pass-through SELECT. |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

SCHEMABINDING. The view is created WITH SCHEMABINDING to prevent schema changes to Trade.ProviderToInstrument that would break dependent code.

---

## 8. Sample Queries

### 8.1 Provider-instrument config by composite key

```sql
SELECT ProviderID, InstrumentID, Precision, AllowBuy, AllowSell, MaxStopLossPercentage
FROM Trade.ProviderToInstrumentSafty WITH (NOLOCK)
WHERE ProviderID = 1 AND InstrumentID = 100017;
```

### 8.2 Enabled instruments for a provider

```sql
SELECT InstrumentID, AllowBuy, AllowSell, MinPositionAmount, MaxPositionUnits
FROM Trade.ProviderToInstrumentSafty WITH (NOLOCK)
WHERE ProviderID = 1 AND Enabled = 1;
```

### 8.3 Temporal config at a point in time

```sql
SELECT ProviderID, InstrumentID, StopLossPercentage, SysStartTime, SysEndTime
FROM Trade.ProviderToInstrumentSafty WITH (NOLOCK)
WHERE InstrumentID = 100017
  AND SysStartTime <= @AsOfDate AND (SysEndTime IS NULL OR SysEndTime > @AsOfDate);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 70 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrumentSafty | Type: View | Source: etoro/etoro/Trade/Views/Trade.ProviderToInstrumentSafty.sql*
