# Trade.GetInstrumentTradingData

> Single-table view exposing per-instrument trading configuration from ProviderToInstrument (AllowBuy, AllowSell, SL/TP limits, precision, market range, etc.) for UI and order validation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentTradingData is a flattened view over Trade.ProviderToInstrument that exposes **trading configuration** for each instrument. It provides a single row per instrument with all the Allow* flags, stop-loss/take-profit constraints, position size limits, precision, and execution settings needed by the trading UI and order validation logic. The view aggregates across providers (or uses a default provider row) - callers use it to answer "what can a user do with instrument X?" without joining multiple provider-instrument rows.

This view exists because trading clients need a compact, read-optimized surface for instrument configuration. Position sizing, order type availability, SL/TP rules, and market range checks all depend on these values. Without it, every client would need to join ProviderToInstrument and resolve provider precedence. The view centralizes that logic and exposes ~35 columns for consumption by Trade.GetInstrument, position views, and order-entry procedures.

Data flows from Trade.ProviderToInstrument (base table). The view has no filter - it returns one row per ProviderToInstrument row, so instruments offered through multiple providers may appear multiple times. Callers typically filter by ProviderID or take the first match per InstrumentID. Procedures such as Trade.CheckValidInstruments, Trade.GetInstrumentSlippage, and order/close flows reference ProviderToInstrument directly; this view serves UI and config-resolution use cases.

---

## 2. Business Logic

### 2.1 Trading Capability Flags (Allow* Columns)

**What**: Each Allow* column controls whether a specific trading operation is permitted for the instrument-provider pair.

**Columns/Parameters Involved**: `AllowBuy`, `AllowSell`, `AllowPendingOrders`, `AllowEntryOrders`, `AllowClosePosition`, `AllowExitOrder`, `AllowEditSLTP`, `AllowEditTakeProfit`, `AllowEditStopLoss`, `AllowTrailingStopLoss`, `AllowLeveragedLongSL`, `AllowNonLeveragedLongSL`, `AllowLeveragedShortSL`, `AllowNonLeveragedShortSL`, `AllowLeveragedLongTP`, `AllowNonLeveragedLongTP`, `AllowLeveragedShortTP`, `AllowNonLeveragedShortTP`, `AllowEditTakeProfitLeveraged`, `AllowEditStopLossLeveraged`

**Rules**:
- AllowBuy=1 / AllowSell=1: User can open long/short positions. When 0, that direction is disabled (e.g., buy-only instruments).
- AllowPendingOrders / AllowEntryOrders: Pending and entry limit orders. When 0, market-only.
- AllowClosePosition / AllowExitOrder: User can close or place exit orders.
- AllowEditSLTP / AllowEditTakeProfit / AllowEditStopLoss: User can modify SL/TP after open.
- AllowLeveraged* / AllowNonLeveraged*: Fine-grained control for leveraged vs non-leveraged positions by direction (Long/Short).

**Diagram**:
```
Instrument 1 (EUR/USD): AllowBuy=1, AllowSell=1, AllowPendingOrders=0 -> full buy/sell, market only
Instrument 2 (GBP):     AllowBuy=1, AllowSell=0 -> buy-only, internally visible
Instrument 3 (NZD/USD): AllowBuy=0, AllowSell=1 -> sell-only
```

### 2.2 Stop-Loss and Take-Profit Constraints

**What**: Min/max and default SL/TP percentages constrain user-configured values.

**Columns/Parameters Involved**: `MinStopLossPercentage`, `MaxStopLossPercentage`, `DefaultStopLossPercentage`, `MinTakeProfitPercentage`, `MaxTakeProfitPercentage`, `DefaultTakeProfitPercentage`, `DefaultStopLossPercentageLeveraged`, `DefaultStopLossPercentageNonLeveraged`

**Rules**:
- User-configured SL/TP must lie within [Min*, Max*].
- Default* values apply when opening without explicit SL/TP.

---

## 3. Data Overview

| InstrumentID | AllowBuy | AllowSell | MinPositionAmount | MaxStopLossPercentage | Precision | Meaning |
|--------------|----------|-----------|-------------------|------------------------|-----------|---------|
| 1 | 1 | 1 | 1000 | 53 | 3 | EUR/USD - full buy/sell, 3 decimal precision, max SL 53%. |
| 2 | 1 | 0 | 1000 | 40 | 5 | GBP - buy-only, internally visible. |
| 3 | 0 | 1 | 1000 | 30 | 5 | NZD/USD - sell-only instrument. |
| 4 | 1 | 0 | 1000 | 20 | 5 | CAD - buy-only with entry orders allowed. |
| 5 | 1 | 1 | 1000 | 89 | 3 | USD/JPY - full trading, pending and entry orders allowed. |

**Selection criteria**: First 5 rows by InstrumentID show variety of AllowBuy/AllowSell, Precision, and MaxStopLossPercentage.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. From Trade.ProviderToInstrument. |
| 2 | MaxStopLossPercentage | decimal(5,2) | NO | 100 | CODE-BACKED | Maximum allowed stop-loss percentage. From ProviderToInstrument. |
| 3 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Max position size in units. CHECK <= 2147483647. From ProviderToInstrument. |
| 4 | MinPositionAmount | money | NO | - | CODE-BACKED | Minimum position size in currency. From ProviderToInstrument. |
| 5 | MaxRateDiffPercentage | decimal(5,2) | NO | 90 | CODE-BACKED | Aliased from AllowedRateDiffPercentage. Max allowed rate difference for order execution validation. From ProviderToInstrument. |
| 6 | AllowBuy | bit | NO | 1 | CODE-BACKED | 1=buy allowed, 0=buy disabled for this instrument-provider pair. |
| 7 | AllowSell | bit | NO | 1 | CODE-BACKED | 1=sell allowed, 0=sell disabled. |
| 8 | AllowPendingOrders | bit | NO | 1 | CODE-BACKED | 1=pending orders allowed, 0=market only. |
| 9 | AllowEntryOrders | bit | NO | 1 | CODE-BACKED | 1=entry orders allowed, 0=no entry orders. |
| 10 | VisibleInternallyOnly | bit | NO | 0 | CODE-BACKED | 1=hidden from external clients (internal/ops only), 0=visible to all. |
| 11 | AllowClosePosition | bit | NO | 1 | CODE-BACKED | 1=user can close position, 0=close disabled. |
| 12 | AllowExitOrder | bit | NO | 1 | CODE-BACKED | 1=exit orders allowed, 0=no exit orders. |
| 13 | GuaranteeSLTP | bit | NO | 0 | CODE-BACKED | 1=broker guarantees SL/TP execution, 0=no guarantee. |
| 14 | AllowEditSLTP | bit | NO | 1 | CODE-BACKED | 1=user can edit SL/TP after open, 0=no edit. |
| 15 | MaxTakeProfitPercentage | decimal(7,2) | NO | 1000 | CODE-BACKED | Maximum allowed take-profit percentage. |
| 16 | AllowRedeem | tinyint | NO | 0 | CODE-BACKED | Redeem/withdrawal allowance. 0=no redeem, 1+=allowed. |
| 17 | MinPositionUnitsForRedeem | decimal(16,8) | YES | 0.1 | CODE-BACKED | Min units for redeem when AllowRedeem > 0. |
| 18 | MaxPositionUnitsForRedeem | decimal(16,8) | YES | 100000 | CODE-BACKED | Max units for redeem. |
| 19 | AllowEditTakeProfit | bit | NO | 1 | CODE-BACKED | 1=user can edit TP, 0=no edit. |
| 20 | AllowEditStopLoss | bit | NO | 1 | CODE-BACKED | 1=user can edit SL, 0=no edit. |
| 21 | DefaultTrailingStopLoss | bit | NO | 0 | CODE-BACKED | 1=trailing SL on by default, 0=off by default. |
| 22 | AllowTrailingStopLoss | bit | NO | 1 | CODE-BACKED | 1=trailing SL allowed, 0=not allowed. |
| 23 | MinStopLossPercentage | decimal(5,2) | NO | 0 | CODE-BACKED | Minimum allowed stop-loss percentage. |
| 24 | MinTakeProfitPercentage | decimal(7,2) | NO | 0 | CODE-BACKED | Minimum allowed take-profit percentage. |
| 25 | DefaultStopLossPercentage | decimal(5,2) | NO | 50 | CODE-BACKED | Default SL when opening without explicit SL. |
| 26 | DefaultTakeProfitPercentage | decimal(7,2) | NO | 50 | CODE-BACKED | Default TP when opening without explicit TP. |
| 27 | AllowLeveragedLongSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for leveraged long, 0=not allowed. |
| 28 | AllowNonLeveragedLongSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for non-leveraged long, 0=not allowed. |
| 29 | AllowLeveragedShortSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for leveraged short, 0=not allowed. |
| 30 | AllowNonLeveragedShortSL | bit | NO | 1 | CODE-BACKED | 1=SL allowed for non-leveraged short, 0=not allowed. |
| 31 | AllowLeveragedLongTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for leveraged long, 0=not allowed. |
| 32 | AllowNonLeveragedLongTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for non-leveraged long, 0=not allowed. |
| 33 | AllowLeveragedShortTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for leveraged short, 0=not allowed. |
| 34 | AllowNonLeveragedShortTP | bit | NO | 1 | CODE-BACKED | 1=TP allowed for non-leveraged short, 0=not allowed. |
| 35 | AllowEditTakeProfitLeveraged | bit | NO | 1 | CODE-BACKED | 1=edit TP allowed for leveraged positions, 0=no edit. |
| 36 | AllowEditStopLossLeveraged | bit | NO | 1 | CODE-BACKED | 1=edit SL allowed for leveraged positions, 0=no edit. |
| 37 | DefaultStopLossPercentageLeveraged | decimal(7,2) | NO | 50 | CODE-BACKED | Default SL for leveraged positions. |
| 38 | DefaultStopLossPercentageNonLeveraged | decimal(7,2) | NO | 50 | CODE-BACKED | Default SL for non-leveraged positions. |
| 39 | Precision | tinyint | NO | - | CODE-BACKED | Decimal places for price display and rounding. |
| 40 | MarketRange | int | YES | - | CODE-BACKED | Market range validation limit. |
| 41 | DesignatedExecutionSystem | tinyint | NO | 1 | CODE-BACKED | Execution system routing. 1=default. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | Each row identifies one tradeable instrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrument | - | JOIN | Instrument view may reference trading data. |
| Trade.GetPositionData, Trade.GetPositionDataSlim | TP2I | JOIN | Position views JOIN ProviderToInstrument for config. |
| Trade.GetInstrumentDataDealing | PTI | JOIN | Dealing instrument data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentTradingData (view)
└── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - single base table, no JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | May JOIN for config. |
| Trade.GetPositionData, Trade.GetPositionDataSlim | View | JOIN ProviderToInstrument for Unit, config. |
| Trade.GetInstrumentDataDealing | View | JOIN ProviderToInstrument. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get trading config for a specific instrument
```sql
SELECT *
  FROM Trade.GetInstrumentTradingData WITH (NOLOCK)
 WHERE InstrumentID = 1
```

### 8.2 List instruments with sell disabled (buy-only)
```sql
SELECT InstrumentID, AllowBuy, AllowSell, MinPositionAmount, MaxStopLossPercentage
  FROM Trade.GetInstrumentTradingData WITH (NOLOCK)
 WHERE AllowBuy = 1 AND AllowSell = 0
 ORDER BY InstrumentID
```

### 8.3 Resolve InstrumentID to instrument names with trading config
```sql
SELECT GIB.InstrumentID, GIB.Abbreviation, GTD.AllowBuy, GTD.AllowSell,
       GTD.Precision, GTD.MinPositionAmount
  FROM Trade.GetInstrumentsBuyNames GIB WITH (NOLOCK)
  JOIN Trade.GetInstrumentTradingData GTD WITH (NOLOCK) ON GTD.InstrumentID = GIB.InstrumentID
 WHERE GIB.InstrumentID IN (1, 2, 5, 10029)
 ORDER BY GIB.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 41 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: N/A | App Code: N/A | Corrections: 0 applied*
*Object: Trade.GetInstrumentTradingData | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentTradingData.sql*
