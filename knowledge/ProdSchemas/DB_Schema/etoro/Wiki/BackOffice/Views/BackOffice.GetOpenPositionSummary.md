# BackOffice.GetOpenPositionSummary

> Aggregates open trading positions per customer/instrument/direction, computing weighted average entry price and real-time P&L using the current market bid/ask prices.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, InstrumentID, ProviderID, IsBuy) - implicit grain from GROUP BY |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetOpenPositionSummary` is a real-time P&L monitoring view for BackOffice staff. For each customer/instrument/provider/direction combination in `Trade.Position`, it aggregates total lot exposure, computes a weighted average entry price, looks up the current market price from `Trade.CurrencyPrice`, and calculates the unrealized P&L using `Internal.GetOnePipValueDollar`.

This view enables risk and operations teams to see the current state of open positions across the platform - total lots committed per instrument, the average price at which customers entered, where the market is now, and the resulting P&L exposure. It is the data source for `BackOffice.GetPositionSummaryDifference`, which compares this summary against the hedge position summary to detect discrepancies.

Data flows read-only from five cross-schema Trade objects at query time. The view is computationally expensive (scalar function per GROUP BY row, large base table join) - it is intended for targeted queries, not full scans. CID is in the GROUP BY but not in the SELECT, so each row represents one customer's aggregate position per instrument/direction without exposing the customer identity directly.

---

## 2. Business Logic

### 2.1 Weighted Average Entry Price

**What**: For positions grouped by (customer, instrument, provider, direction), computes the lot-weighted average of the initial forex rate to show the true average entry price of all open positions.

**Columns/Parameters Involved**: `Avg Price`, `Total Lot`

**Rules**:
- Formula: `SUM(InitForexRate * LotCountDecimal) / SUM(LotCountDecimal)`
- Weights each position's entry rate by its lot size - larger positions have more influence on the average
- This is the standard VWAP (Volume Weighted Average Price) calculation applied to lot counts

**Diagram**:
```
Position A: InitForexRate=1.1000, LotCountDecimal=2.0
Position B: InitForexRate=1.1200, LotCountDecimal=1.0
Weighted Avg = (1.1000*2 + 1.1200*1) / (2+1) = 3.3200/3 = 1.1067
```

### 2.2 Directional P&L Calculation

**What**: Computes unrealized P&L in USD for each grouped position, using the current market price vs. the weighted average entry price, scaled by lot count and pip value.

**Columns/Parameters Involved**: `P&L`, `BUY/SELL`, `Current Price`, `Avg Price`, `Total Lot`

**Rules**:
- For BUY positions: P&L = TotalLot * 10000 * PipValue * (CurrentBid - AvgEntryPrice)
- For SELL positions: P&L = TotalLot * 10000 * PipValue * (AvgEntryPrice - CurrentAsk) * -1
- Current Price: BUY positions use `CurrencyPrice.Bid`, SELL positions use `CurrencyPrice.Ask` (standard close-out pricing)
- `Internal.GetOnePipValueDollar(CID, InstrumentID, ProviderID, IsBuy, SpreadedPipBid, SpreadedPipAsk, Precision)` converts pip movement to dollar value, accounting for instrument-specific pip scaling and currency conversion

**Diagram**:
```
BUY: TotalLot * 10000 * PipValueUSD * (Bid - AvgPrice)
SELL: TotalLot * 10000 * PipValueUSD * (AvgPrice - Ask) * -1

Positive P&L = profitable position group
Negative P&L = losing position group
```

---

## 3. Data Overview

*Live data not available - view timed out (crosses multiple large Trade schema tables including Trade.Position with scalar function per row).*

| Provider | Instrument | BUY/SELL | Total Lot | Current Price | Avg Price | P&L |
|----------|------------|----------|-----------|---------------|-----------|-----|
| (example) | EUR/USD | BUY | 5.0 | 1.0950 | 1.0920 | +150.00 |
| (example) | EUR/USD | SELL | 2.0 | 1.0960 | 1.0980 | +40.00 |
| (example) | BTC/USD | BUY | 0.5 | 42000 | 41500 | +250.00 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Provider | NVARCHAR (computed) | YES | - | CODE-BACKED | Trimmed name of the trading provider/broker. Derived from `LTRIM(RTRIM(Trade.Provider.Name))` joined on ProviderID. Identifies which liquidity provider/server the positions are on (e.g., "eToro", "ProReal"). |
| 2 | Instrument | NVARCHAR (from Trade.GetInstrument) | YES | - | CODE-BACKED | Name of the traded financial instrument (e.g., "EUR/USD", "BTC/USD", "AAPL"). Resolved from `Trade.GetInstrument.Name` joined on InstrumentID. |
| 3 | BUY/SELL | VARCHAR(4) (computed) | NO | - | VERIFIED | Trade direction label computed from `IsBuy`: `CASE WHEN IsBuy=1 THEN 'BUY' ELSE 'SELL' END`. BUY = long position (customer profits if price rises), SELL = short position (customer profits if price falls). |
| 4 | Total Lot | DECIMAL (computed) | YES | - | CODE-BACKED | Sum of lot sizes (`SUM(LotCountDecimal)`) for all open positions in this (Customer, Instrument, Provider, Direction) group. Represents total exposure in standard lots. |
| 5 | Current Price | DECIMAL (computed) | YES | - | CODE-BACKED | Current market close-out price for this instrument/direction from `Trade.CurrencyPrice`. BUY positions use `Bid` (the price at which a long position would be closed), SELL positions use `Ask` (the price at which a short position would be closed). Defaults to 0 if no price found (ISNULL). |
| 6 | Avg Price | DECIMAL (computed) | YES | - | VERIFIED | Lot-weighted average entry (initial forex) rate across all positions in the group. Formula: `SUM(InitForexRate * LotCountDecimal) / SUM(LotCountDecimal)`. This is the VWAP at which the customer effectively entered their total position in this instrument/direction. |
| 7 | P&L | DECIMAL (computed) | YES | - | CODE-BACKED | Unrealized profit/loss in USD for this position group. Formula: `TotalLot * 10000 * GetOnePipValueDollar(...) * (CurrentPrice - AvgPrice) * direction_multiplier`. Positive = profitable, negative = losing. Calls `Internal.GetOnePipValueDollar` to convert pip movement to dollar value, incorporating instrument precision and spreaded pip rates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsBuy, LotCountDecimal, InitForexRate, CID, InstrumentID, ProviderID | Trade.Position | Source (cross-schema) | Main position data source. Open positions from this view are aggregated. |
| Bid, Ask | Trade.CurrencyPrice | Lookup (cross-schema) | Provides current market bid/ask prices joined on (ProviderID, InstrumentID). |
| Name (Provider) | Trade.Provider | Lookup (cross-schema) | Resolves ProviderID to provider name. |
| Name (Instrument) | Trade.GetInstrument | Lookup (cross-schema view) | Resolves InstrumentID to instrument name. |
| Precision, SpreadedPipBid, SpreadedPipAsk | Trade.ProviderToInstrument | Lookup (cross-schema) | Provides instrument precision and spreaded pip rates used in P&L calculation. |
| P&L | Internal.GetOnePipValueDollar | Function call (cross-schema) | Computes dollar value of one pip for the given customer/instrument/direction. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetPositionSummaryDifference | BackOffice.GetOpenPositionSummary | JOIN | Compares this open position summary against the hedge position summary to detect discrepancies. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetOpenPositionSummary (view)
├── Trade.Position (cross-schema view)
├── Trade.CurrencyPrice (cross-schema table)
├── Trade.Provider (cross-schema table)
├── Trade.GetInstrument (cross-schema view)
├── Trade.ProviderToInstrument (cross-schema table)
└── Internal.GetOnePipValueDollar (cross-schema function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Cross-schema View | FROM clause (alias TPOS, NOLOCK) - main open positions data |
| Trade.CurrencyPrice | Cross-schema Table | FROM clause (alias TCRP, NOLOCK) - current bid/ask prices |
| Trade.Provider | Cross-schema Table | FROM clause (alias TPRV) - provider name resolution |
| Trade.GetInstrument | Cross-schema View | FROM clause (alias TISR) - instrument name resolution |
| Trade.ProviderToInstrument | Cross-schema Table | FROM clause (alias TPVI) - precision and pip rates |
| Internal.GetOnePipValueDollar | Cross-schema Function | Called in P&L SELECT expression - dollar pip value computation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetPositionSummaryDifference | View | READER - joins this view to compare against hedge summary |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: All five source joins are implicit INNER JOINs (old-style comma syntax + WHERE conditions). Positions with no matching CurrencyPrice, Provider, Instrument, or ProviderToInstrument record are silently excluded. `WITH (NOLOCK)` applied to Trade.Position and Trade.CurrencyPrice to reduce lock contention on high-activity tables.

---

## 8. Sample Queries

### 8.1 Get open position summary for a specific instrument

```sql
SELECT Provider, Instrument, [BUY/SELL], [Total Lot], [Current Price], [Avg Price], [P&L]
FROM BackOffice.GetOpenPositionSummary WITH (NOLOCK)
WHERE Instrument = 'EUR/USD'
ORDER BY [P&L] DESC
```

### 8.2 Find position groups with significant negative P&L

```sql
SELECT Provider, Instrument, [BUY/SELL], [Total Lot], [P&L]
FROM BackOffice.GetOpenPositionSummary WITH (NOLOCK)
WHERE [P&L] < -10000
ORDER BY [P&L] ASC
```

### 8.3 Summarize total exposure and P&L per instrument

```sql
SELECT Instrument, [BUY/SELL],
       SUM([Total Lot]) AS TotalLots,
       SUM([P&L]) AS TotalPnL
FROM BackOffice.GetOpenPositionSummary WITH (NOLOCK)
GROUP BY Instrument, [BUY/SELL]
ORDER BY TotalLots DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 timed out)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetOpenPositionSummary | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetOpenPositionSummary.sql*
