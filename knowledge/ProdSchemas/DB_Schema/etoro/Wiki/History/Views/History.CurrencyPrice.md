# History.CurrencyPrice

> Thin SELECT wrapper over History.CurrencyPrice_Active (the Price server synonym) - the recommended access path for price tick data in the History schema, exposing all 28 columns with an explicit column list rather than SELECT *.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CurrencyPriceID (bigint, from Price server) |
| **Partition** | N/A (view - remote target on Price server) |
| **Indexes** | N/A (view - Price server indexes used) |

---

## 1. Business Meaning

`History.CurrencyPrice` is the standard access path for historical and current currency price tick data in the etoro database. The view is a thin SELECT wrapper that explicitly names all 28 columns from `History.CurrencyPrice_Active` (which is itself a synonym for `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice_Active]` on the dedicated Price server).

The view exists as a stable named interface because:
1. **Explicit column list**: By listing all 28 columns explicitly rather than `SELECT *`, the view is insulated from column additions to the underlying synonym target. Consumers always get the same 28 columns regardless of what the Price server adds.
2. **Abstraction layer**: Consumers reference `History.CurrencyPrice` rather than the four-part linked-server name, keeping code portable.
3. **Parallel access path**: There is also `dbo.HistoryCurrencyPrice` (synonym directly to the same Price server table) and `History.CurrencyPrice_Active` (synonym). The view is the preferred access point for stored procedures and views in the History and Trade schemas.

The view change on 2019-06-23 (Yitzchak) updated `BidSpreaded` and `AskSpreaded` column types to `dtPrice` in the view definition, standardizing the price type across both spreaded columns.

Consumers span multiple schemas: Trade views for open position P&L, History stored procedures for price queue management, Hedge SSRS reports, dbo SSRS price monitoring reports, and ad-hoc price data queries.

---

## 2. Business Logic

### 2.1 Passthrough Column Selection

**What**: A direct SELECT of all 28 columns from History.CurrencyPrice_Active.

**Rules**:
- No WHERE clause, no JOIN, no aggregation - pure column projection
- Exposes exactly 28 columns, explicitly named (not `SELECT *`)
- BidSpreaded and AskSpreaded cast to `dtPrice` per 2019 change
- All filtering, ordering, and joining is the caller's responsibility
- Inherits all data characteristics of `History.CurrencyPrice_Active` (Price server linked-server table)

### 2.2 Price Tick Data Model

**What**: Each row represents one price tick - a Bid/Ask price snapshot for an instrument received from a liquidity provider, valid for a specific time window.

**Rules**:
- One tick = one CurrencyPriceID for one InstrumentID at one ProviderID
- `ValidFrom` to `ValidTo` defines when this tick was the prevailing price
- `Occurred` = when the Price server processed it; `OccurredOnProvider` = provider's own timestamp; `ReceivedOnPriceServer` = receipt time
- `BidSpreaded`/`AskSpreaded` = client-facing prices after MarkupPips applied; `Bid`/`Ask` = raw provider prices
- `USDConversionRate` = FX multiplier to USD at the time of this tick

---

## 3. Data Overview

Direct MCP query blocked (Price server linked-server access restricted for McpUserRO). Based on `History.CurrencyPrice_Active.md` documentation:

| Column | Typical Value | Meaning |
|--------|--------------|---------|
| CurrencyPriceID | 8,000,000,000+ | Very high - reflects volume of ticks since 2007 |
| InstrumentID | 1-8000+ | Instrument being priced |
| Bid/Ask | 1.08520/1.08530 (EUR/USD) | Raw provider prices |
| ValidFrom/ValidTo | UTC timestamps | Price validity window |
| MarkupPips | 0.5 | Spread markup |

---

## 4. Elements

All columns are passed through unchanged from `History.CurrencyPrice_Active`. See `History.CurrencyPrice_Active.md` for full column descriptions.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyPriceID | bigint | NO | - | CODE-BACKED | Primary key / unique identifier for this price tick on the Price server. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | The liquidity provider that sent this price tick. FK to provider configuration on the Price server. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument this price applies to. Corresponds to Trade.Instrument.InstrumentID. Used in JOINs by Trade procedures to retrieve current instrument prices. |
| 4 | Bid | dtPrice | YES | - | CODE-BACKED | The provider's raw buy price for this tick. Used in position PnL and close-at-price logic. |
| 5 | Ask | dtPrice | YES | - | CODE-BACKED | The provider's raw sell price for this tick. Spread = Ask - Bid. |
| 6 | ValidFrom | datetime | YES | - | CODE-BACKED | UTC timestamp when this tick became the active price for the instrument. |
| 7 | ValidTo | datetime | YES | - | CODE-BACKED | UTC timestamp when this tick was superseded. NULL or far-future for the current active price. |
| 8 | OccurredOnProvider | datetime | YES | - | NAME-INFERRED | Timestamp of when the price event occurred on the provider's side (provider-reported time). |
| 9 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the price was processed/recorded on the Price server. Used in time-range filters. |
| 10 | PriceRateID | bigint | YES | - | CODE-BACKED | References the price rate entry. Used by Trade.ClosePositionAtPriceRateID to close positions at a specific historical price. |
| 11 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | UTC timestamp when the Price server received the tick. Monitored for missing price feed detection. |
| 12 | LiquidityAccountID | int | YES | - | NAME-INFERRED | The liquidity account (sub-account within a provider) this price tick originated from. |
| 13 | USDConversionRate | decimal | YES | - | CODE-BACKED | Exchange rate to convert the instrument's native currency to USD at the time of this tick. |
| 14 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | References the raw market price record before spread/markup was applied. |
| 15 | RateLastEx | decimal | YES | - | NAME-INFERRED | Last execution rate - the rate at which the last execution occurred for this instrument/provider. |
| 16 | BidSpreaded | dtPrice | YES | - | CODE-BACKED | The Bid price after applying markup spread - the client-facing sell price. Changed to dtPrice in 2019-06-23 (Yitzchak). |
| 17 | AskSpreaded | dtPrice | YES | - | CODE-BACKED | The Ask price after applying markup spread - the client-facing buy price. Changed to dtPrice in 2019-06-23. |
| 18 | BidMarketPriceRateID | bigint | YES | - | NAME-INFERRED | References the market price rate corresponding to the spreaded Bid. |
| 19 | AskMarketPriceRateID | bigint | YES | - | NAME-INFERRED | References the market price rate corresponding to the spreaded Ask. |
| 20 | MarkupPips | decimal | YES | - | CODE-BACKED | Spread markup applied in pips on top of the raw provider price to arrive at BidSpreaded/AskSpreaded. |
| 21 | MarketReceivedTime | datetime | YES | - | NAME-INFERRED | Timestamp when the market data was received. May differ from ReceivedOnPriceServer for latency analysis. |
| 22 | SkewValueBid | decimal | YES | - | CODE-BACKED | Skew adjustment applied to the Bid side. Used in SSRS_Price_Algo reports for asymmetric spread analysis. |
| 23 | SkewValueAsk | decimal | YES | - | CODE-BACKED | Skew adjustment applied to the Ask side. Counterpart to SkewValueBid. |
| 24 | PriceRateInsertTime | datetime | YES | - | NAME-INFERRED | Timestamp when the price rate record was inserted into the price table on the Price server. |
| 25 | Volume | decimal | YES | - | CODE-BACKED | Trading volume associated with this price tick. Used in SSRS_Price_Algo reports. |
| 26 | USDConversionRateBidSpreaded | decimal | YES | - | NAME-INFERRED | USD conversion rate based on the spreaded Bid price. For PnL using client-facing Bid. |
| 27 | USDConversionRateAskSpreaded | decimal | YES | - | NAME-INFERRED | USD conversion rate based on the spreaded Ask price. Counterpart to USDConversionRateBidSpreaded. |
| 28 | USDConversionPriceRateID | bigint | YES | - | NAME-INFERRED | References the price rate record used to derive the USD conversion rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.CurrencyPrice_Active | View dependency (direct SELECT) | Synonym for [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice_Active] - all 28 columns passed through |
| InstrumentID | Trade.Instrument | Implicit (cross-schema) | InstrumentID values correspond to Trade.Instrument.InstrumentID |

### 5.2 Referenced By (other objects point to this)

| Object | Schema | How Used |
|--------|--------|----------|
| Trade.OpenPositionEndOfDay | Trade (view) | JOINs for end-of-day open position pricing |
| Trade.OpenPositionEndOfDayWith2Pnl | Trade (view) | JOINs for dual-PnL open position view |
| Trade.GetPayedDividendsAndPositions | Trade (SP) | Price lookup for dividend/position records |
| History.CurrencyPriceQueue_CleanUp | History (SP) | Price queue maintenance |
| History.CurrencyPriceQueue_Process | History (SP) | Price queue processing |
| History.CurrencyPriceQueue_Process_Wrapper | History (SP) | Price queue processing wrapper |
| Hedge.Report_PriceLatencyTickByTick | Hedge (SP) | Tick-by-tick price latency reporting |
| dbo.PR_NFA_TICKDATA | dbo (SP) | NFA tick data report |
| dbo.PR_Report_HistoryCurrencyPrice_Duplicate_Rows | dbo (SP) | Duplicate price row detection |
| dbo.SSRS_Price_Algo | dbo (SP) | Price algo SSRS report |
| Trade.SetCurrencyPriceFail | Trade (SP) | Sets price failure status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CurrencyPrice (view)
+--> History.CurrencyPrice_Active (synonym -> [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice_Active])
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CurrencyPrice_Active | Synonym (Price server) | Direct SELECT source - all 28 columns |

### 6.2 Objects That Depend On This

11 objects across Trade, History, Hedge, and dbo schemas (see Section 5.2).

---

## 7. Technical Details

### 7.1 Access Pattern

All queries against this view are forwarded to the Price server via the linked server. Performance depends on:
- Network latency to `AO-PRICE-LSN-ROR`
- Indexes on the remote `CurrencyPrice_Active` table (not visible in this SSDT repo)
- Query optimizer's ability to push predicates through the linked server

Filtering by InstrumentID or time ranges (ValidFrom/ValidTo, Occurred) is the most common access pattern. These columns likely have indexes on the Price server.

---

## 8. Sample Queries

### 8.1 Get the most recent price for an instrument

```sql
SELECT TOP 1
    cp.InstrumentID,
    cp.Bid,
    cp.Ask,
    cp.BidSpreaded,
    cp.AskSpreaded,
    cp.ValidFrom,
    cp.Occurred
FROM History.CurrencyPrice cp WITH(NOLOCK)
WHERE cp.InstrumentID = 1  -- EUR/USD
ORDER BY cp.ValidFrom DESC
```

### 8.2 Get price at a specific historical time

```sql
-- Price for instrument at a given datetime
SELECT TOP 1
    cp.CurrencyPriceID,
    cp.Bid,
    cp.Ask,
    cp.ValidFrom,
    cp.ValidTo
FROM History.CurrencyPrice cp WITH(NOLOCK)
WHERE cp.InstrumentID = 1
  AND '2024-06-01 10:30:00' BETWEEN cp.ValidFrom AND cp.ValidTo
```

### 8.3 Price latency analysis (as used by Hedge.Report_PriceLatencyTickByTick)

```sql
SELECT
    cp.InstrumentID,
    cp.OccurredOnProvider,
    cp.ReceivedOnPriceServer,
    DATEDIFF(MILLISECOND, cp.OccurredOnProvider, cp.ReceivedOnPriceServer) AS LatencyMs
FROM History.CurrencyPrice cp WITH(NOLOCK)
WHERE cp.InstrumentID = 1
  AND cp.Occurred >= DATEADD(HOUR, -1, GETDATE())
ORDER BY cp.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 8.8/10, Relationships: 9.2/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 11 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - Price server blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 11 consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CurrencyPrice | Type: View | Source: etoro/etoro/History/Views/History.CurrencyPrice.sql*
