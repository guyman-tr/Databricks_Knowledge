# BackOffice.GetHedgePositionSummary

> Real-time hedge position P&L summary view aggregating open hedge positions by provider and instrument, computing current P&L using live bid/ask prices and the pip value function.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (Provider, Instrument, BUY/SELL) - GROUP BY composite |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetHedgePositionSummary` provides a real-time risk management dashboard for the eToro trading desk, showing the current net hedge exposure and unrealized P&L for every open hedge position aggregated by provider, instrument, and direction (Buy/Sell).

eToro's trading model involves hedging customer positions with external liquidity providers. `Trade.Hedge` stores these open hedge positions. This view aggregates them to give the risk team a single summary row per (provider, instrument, direction) with:

- **Total Lot**: Sum of all open hedge lots in that direction
- **Current Price**: Live bid (for BUY) or ask (for SELL) from `Trade.CurrencyPrice`
- **Average Price**: Volume-weighted average of the hedge open rates (InitForexRate * LotCountDecimal / total lots)
- **P&L**: Current mark-to-market P&L, computed as: `Total Lot * 10000 * OnePipValue * (CurrentPrice - AvgPrice) * direction_sign`

The P&L formula uses `Internal.GetOnePipValueDollar()` to convert pip movements to USD, accounting for instrument precision and the provider's current bid/ask.

---

## 2. Business Logic

### 2.1 Aggregated Hedge P&L Calculation

**What**: Aggregates open hedge lots per (ProviderID, InstrumentID, IsBuy) and computes real-time unrealized P&L.

**Columns Involved**: Trade.Hedge.LotCountDecimal, InitForexRate, IsBuy, InstrumentID, ProviderID; Trade.CurrencyPrice.Bid/Ask; Trade.ProviderToInstrument.Precision

**Rules**:
- INNER JOINs require matching rows in Trade.CurrencyPrice, Trade.Provider, Trade.GetInstrument, and Trade.ProviderToInstrument. Hedge positions with no live price, unknown provider, unknown instrument, or no provider-instrument mapping will be excluded from results.
- `Current Price` = `Bid` for BUY positions, `Ask` for SELL positions (ISNULL defaulting to 0 if no price).
- `Avg Price` = volume-weighted average of open prices: `SUM(InitForexRate * LotCountDecimal) / SUM(LotCountDecimal)`.
- `P&L` formula:
  ```
  SUM(LotCountDecimal) * 10000
  * GetOnePipValueDollar(NULL, InstrumentID, ProviderID, IsBuy, Bid, Ask, Precision)
  * (CurrentPrice - AvgPrice)
  * (1 if BUY, -1 if SELL)
  ```
  A positive P&L means the hedge is profitable (open price < current for BUY, current < open price for SELL).
- GROUP BY: (ProviderID, Provider.Name, InstrumentID, Instrument.Name, IsBuy, CurrentPrice, Bid, Ask, Precision).

---

## 3. Data Overview

Row count = number of distinct (ProviderID, InstrumentID, IsBuy) combinations in Trade.Hedge with matching live prices. Small result set (~dozens to hundreds of rows) representing the active hedge book.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Provider | nvarchar | CODE-BACKED | Name of the liquidity provider (e.g., "Saxo Bank", "IB", "LMAX"). From Trade.Provider.Name (LTRIM/RTRIM trimmed). |
| 2 | Instrument | nvarchar | CODE-BACKED | Name of the hedged instrument (e.g., "EUR/USD", "AAPL", "BTCUSD"). From Trade.GetInstrument.Name via InstrumentID. |
| 3 | BUY/SELL | varchar(4) | CODE-BACKED | Direction of the hedge position. "BUY" if Trade.Hedge.IsBuy=1, "SELL" otherwise. |
| 4 | Total Lot | decimal | CODE-BACKED | Sum of LotCountDecimal for all open hedge positions in this (Provider, Instrument, Direction) group. |
| 5 | Current Price | decimal | CODE-BACKED | Live market price from Trade.CurrencyPrice. Bid for BUY positions, Ask for SELL positions. ISNULL to 0 if no price available. |
| 6 | Avg Price | decimal | CODE-BACKED | Volume-weighted average open price across all aggregated hedge positions. SUM(InitForexRate*LotCountDecimal)/SUM(LotCountDecimal). |
| 7 | P&L | decimal | CODE-BACKED | Unrealized mark-to-market P&L in USD for this aggregate position. Positive=profitable. Computed using lot count, pip value, and price difference from average open to current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Hedge positions | Trade.Hedge | Base Table | Open hedge positions - aggregated |
| Current Price | Trade.CurrencyPrice | INNER JOIN | Live bid/ask prices per (ProviderID, InstrumentID) |
| Provider | Trade.Provider | INNER JOIN | Provider name lookup |
| Instrument | Trade.GetInstrument | INNER JOIN | Instrument name lookup (view or table) |
| Precision | Trade.ProviderToInstrument | INNER JOIN | Instrument precision for pip value calculation |
| P&L | Internal.GetOnePipValueDollar | Scalar Function | Converts one pip movement to USD value for a given instrument, provider, direction, and price |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Consumed by risk management tooling and trading desk dashboards |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetHedgePositionSummary (view)
+-- Trade.Hedge (cross-schema)
+-- Trade.CurrencyPrice (cross-schema)
+-- Trade.Provider (cross-schema)
+-- Trade.GetInstrument (cross-schema, view or table)
+-- Trade.ProviderToInstrument (cross-schema)
+-- Internal.GetOnePipValueDollar (cross-schema scalar function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table (cross-schema) | Open hedge positions - aggregated by (ProviderID, InstrumentID, IsBuy) |
| Trade.CurrencyPrice | Table (cross-schema) | Live bid/ask prices for current price and P&L calculation |
| Trade.Provider | Table (cross-schema) | Provider name display |
| Trade.GetInstrument | View/Table (cross-schema) | Instrument name display |
| Trade.ProviderToInstrument | Table (cross-schema) | Instrument Precision for pip value function |
| Internal.GetOnePipValueDollar | Scalar Function (cross-schema) | Dollar value of one pip for P&L computation |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on:
- `Trade.Hedge` index on (ProviderID, InstrumentID, IsBuy)
- `Trade.CurrencyPrice` index on (ProviderID, InstrumentID)

### 7.2 Constraints

N/A for View.

### 7.3 Performance Note

The scalar function `Internal.GetOnePipValueDollar()` is called once per GROUP BY row (not per raw row), which is efficient for the small aggregated result set this view produces.

---

## 8. Sample Queries

### 8.1 Get current hedge P&L summary

```sql
SELECT Provider, Instrument, [BUY/SELL],
       [Total Lot], [Current Price], [Avg Price], [P&L]
FROM BackOffice.GetHedgePositionSummary WITH (NOLOCK)
ORDER BY ABS([P&L]) DESC;
```

### 8.2 Get total P&L by provider

```sql
SELECT Provider, SUM([P&L]) AS TotalPL, SUM([Total Lot]) AS TotalLots
FROM BackOffice.GetHedgePositionSummary WITH (NOLOCK)
GROUP BY Provider
ORDER BY TotalPL;
```

### 8.3 Show underwater positions (negative P&L)

```sql
SELECT Provider, Instrument, [BUY/SELL], [Total Lot], [P&L]
FROM BackOffice.GetHedgePositionSummary WITH (NOLOCK)
WHERE [P&L] < 0
ORDER BY [P&L] ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetHedgePositionSummary | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetHedgePositionSummary.sql*
