---
id: pricing-and-currency-history
name: "Pricing & Currency History"
description: "Historical and real-time instrument pricing across the trading platform. Anchored on Fact_CurrencyPriceWithSplit (DWH authoritative daily price with split-adjustment switching), History.CurrencyPrice (the complete tick-level archive in the Bronze data lake), History.CurrencyPriceMaxDateWithSplitView (the fast last-price cache for 9,339 instruments), and Trade.CurrencyPrice (real-time price cache, overwritten on every tick). Covers split-adjustment switching at corporate-action dates, bid/ask vs spread-adjusted prices, USD conversion rates, the IsValid end-of-day flag, and BSL audit snapshots."
triggers:
  - currency price
  - instrument price
  - price history
  - Fact_CurrencyPriceWithSplit
  - History.CurrencyPrice
  - PriceLog
  - PriceLog_Candles
  - bid ask
  - spread adjusted
  - AskSpreaded
  - BidSpreaded
  - RateLastEx
  - split adjustment
  - SplitRatio
  - corporate action price
  - mark to market
  - USD conversion rate
  - FX rate
  - real-time price
  - Trade.CurrencyPrice
  - BSL snapshot
  - BSL price
  - price tick
  - end of day price
  - IsValid price
required_tables:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  - main.dealing.bronze_pricelog_history_currencyprice
  - main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview
  - main.trading.bronze_etoro_trade_currencyprice
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Pricing & Currency History

eToro's price stack is a **four-table tier** spanning real-time, cached, daily, and tick-archive grains. Each tier has a different refresh cadence, a different consumer, and a different split-adjustment behaviour:

- **Real-time** (`Trade.CurrencyPrice`) — overwritten on every tick by the price-feed engine. One row per `ProviderID × InstrumentID`. Used by order placement and position valuation.
- **Latest-cache** (`History.CurrencyPriceMaxDateWithSplitView`) — fast lookup of the most-recent split-adjusted bid/ask price per instrument. 9,339 rows.
- **Daily authoritative** (`Fact_CurrencyPriceWithSplit`) — DWH's source of truth for daily prices, with `IsValid = 1` marking the end-of-day price. Switches sources at corporate-action dates to deliver historically-adjusted prices.
- **Tick-archive** (`History.CurrencyPrice` in Bronze) — every tick ever received by the price-feed system. The data-lake archive that backfills all of the above.

This sub-skill is the analyst-facing map of which table to ask which price question.

## When to Use

Load when the question is about:

- "What was the EOD price of TSLA on 2026-03-15?", "historical price lookup"
- "What's the current bid/ask on BTC?", "live price"
- "Mark-to-market price for position X at open"
- "Bid/ask spread on instrument Y over time"
- "USD conversion rate at point Z"
- "How does the system handle TSLA's stock split on 2022-08-25?"
- "BSL snapshot price for an equity audit"
- "Why does the price look different in two tables?" → likely a split-adjustment vs raw discrepancy

Do **not** load for:

- Position state at an event-time price → [`position-state-and-grain.md`](position-state-and-grain.md) (which embeds the rate at the event)
- LP fill rate / execution events at LP-confirmed prices → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- AUM / PnL valuation (which uses these prices but lives downstream) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Customer's portfolio dashboard price display (consumed from these tables but the display sits in product) — out of scope here

## Scope

In scope: `Fact_CurrencyPriceWithSplit` (DWH daily authoritative — bid/ask, spread-adjusted, RateLastEx, IsValid EOD flag, split-aware source switching via `DWH_staging.etoro_History_SplitRatio`), `History.CurrencyPrice` in Bronze (the complete tick archive — bid/ask, spread adjustments, USD conversion rates, market rate IDs, skew, persisted from `Trade.CurrencyPrice` via PriceLog), `History.CurrencyPriceMaxDateWithSplitView` (last-price cache for 9,339 instruments, override 1440-min), `Trade.CurrencyPrice` (real-time price cache per provider × instrument, override 60-min), `History.BSLCurrencyPriceSnapShots` (BSL execution audit snapshots — Bid/Ask per instrument at each BSL invocation), the split-handling pattern, the price-source-switching at corporate-action dates, the staging views (`PriceLog_Candles_CurrencyPriceMaxDateWithSplitView`, `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, `PriceLog_History_CurrencyPrice_Active`).
Out of scope: position-state with embedded rate (`position-state-and-grain.md`), execution-event LP price (`dealing-investigation-and-execution.md`), portfolio valuation downstream (`portfolio-value-aum-pnl.md`), instrument metadata (`instruments-and-asset-classes.md`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Fact_CurrencyPriceWithSplit` may have MORE than one row per `InstrumentID × Date`. Only the row with `IsValid = 1` is the active end-of-day price.** The ETL writes multiple candle snapshots per day (intraday); the `IsValid` flag marks which row is the official EOD active price. **Always filter `WHERE IsValid = 1`** for daily P&L look-ups. Forgetting this returns duplicate intraday rows and over-counts in joins.
2. **Tier 1 — On stock-split dates, the ETL switches its source view.** Normal days: `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView`. Split days (instrument appears in `DWH_staging.etoro_History_SplitRatio`): `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which provides historically-adjusted prices for affected instruments. **This means the same `(InstrumentID, Date)` row can show different absolute prices** depending on whether you read pre-split or post-split snapshots — the split-aware view always returns the post-split-adjusted value retroactively. Plan accordingly when comparing historical price series across a split.
3. **Tier 2 — `Trade.CurrencyPrice` is OVERWRITTEN per-tick.** It is NOT a history table. To get the price at any past timestamp, use `History.CurrencyPrice` (Bronze tick archive) or `Fact_CurrencyPriceWithSplit` (DWH daily). The real-time table tells you "the last price" — nothing else.
4. **Tier 2 — `History.CurrencyPrice` in Bronze is the production-side `DWH_dbo.History_CurrencyPrice` external table — NOT the OLTP `etoro.History.CurrencyPrice`.** The naming is confusing. The data path: `Trade.CurrencyPrice` (live cache) → ticks also written to `History.CurrencyPrice` (production archive) → land in Bronze via the PriceLog pipeline → `DWH_dbo.History_CurrencyPrice` reads from Bronze. The DWH external table in UC is `main.dealing.bronze_pricelog_history_currencyprice`. Don't confuse it with the History.CurrencyPriceMaxDateWithSplitView cache (a different OLTP table).
5. **Tier 3 — Spread-adjusted vs raw prices.** Every price row in `Fact_CurrencyPriceWithSplit` exposes both `Bid`/`Ask` (raw market price) and `BidSpreaded`/`AskSpreaded` (eToro-spread-adjusted price). Use the spread-adjusted column for customer-facing P&L valuation (matches what customers see); use the raw column for slippage / LP-execution comparisons. Don't average across columns — they answer different questions.
6. **Tier 3 — `RateLastEx` is the last execution rate, not a quote.** It records the rate at which the last hedge order actually executed against this instrument. Useful for hedge-side P&L; misleading if you treat it as a market quote.

## Tables — the four-tier price stack

| Tier | Table | Grain | Refresh | Use For |
|---|---|---|---|---|
| Real-time | `main.trading.bronze_etoro_trade_currencyprice` | `ProviderID × InstrumentID` (overwritten) | Override, 60-min | Current bid/ask "right now" |
| Latest cache | `main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview` | `InstrumentID` (9,339 rows, one per instrument) | Override, 1440-min | Fast lookup of the most recent split-adjusted bid/ask |
| Daily authoritative | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | `InstrumentID × Date × snapshot` (filter `IsValid = 1` for EOD) | Daily SP (`SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse`) | Historical EOD price, P&L valuation |
| Tick archive | `main.dealing.bronze_pricelog_history_currencyprice` | Every tick | Continuous (via PriceLog pipeline) | Sub-daily / arbitrary timestamp price |

### Auxiliary

| Table | Use For |
|---|---|
| `main.general.bronze_etoro_history_bslcurrencypricesnapshots` | BSL (Brokerage Service Layer) execution audit snapshots — Bid/Ask per instrument at each BSL invocation. Used by `Trade.CheckBSL` for equity audit recalculation. |
| `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` *(staging)* | Daily candlestick prices for all instruments — the ETL source for `Fact_CurrencyPriceWithSplit` on non-split dates. |
| `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory` *(staging)* | Historically-adjusted prices for split-affected instruments — used on split dates. |
| `DWH_staging.PriceLog_History_CurrencyPrice_Active` *(staging)* | Derivative used by `SP_Dim_Position_DL_To_Synapse` to enrich open/close market prices and USD conversion rates per position. |
| `DWH_staging.etoro_History_SplitRatio` *(staging)* | Per-instrument-per-date split ratio — triggers the source-view switch in `Fact_CurrencyPriceWithSplit` ETL. |

---

## Query Patterns

### Pattern 1 — EOD price for an instrument on a date
```sql
SELECT InstrumentID, Date,
       Bid, Ask, BidSpreaded, AskSpreaded, RateLastEx
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE InstrumentID = 1111
  AND Date = '2026-05-09'
  AND IsValid = 1;
```
**Use when:** "EOD price of Tesla on May 9", "what was the closing bid/ask?". **The `IsValid = 1` filter is mandatory** — see Critical Warning #1.

### Pattern 2 — Price time series for an instrument
```sql
SELECT Date, BidSpreaded, AskSpreaded
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE InstrumentID = 1111
  AND Date BETWEEN '2026-01-01' AND '2026-03-31'
  AND IsValid = 1
ORDER BY Date;
```
**Use when:** "Tesla price chart this quarter", "BTC bid trend"

### Pattern 3 — Latest price across all instruments (fast — single-row-per-instrument cache)
```sql
SELECT InstrumentID, Bid, Ask, BidSpreaded, AskSpreaded
FROM main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview
WHERE InstrumentID IN (1111, 14259, 15200);
```
**Use when:** "current price for these instruments", "snapshot lookup for a watch-list"

### Pattern 4 — Current real-time price per provider
```sql
SELECT ProviderID, InstrumentID, Bid, Ask, LastUpdated
FROM main.trading.bronze_etoro_trade_currencyprice
WHERE InstrumentID = 1111;
```
**Use when:** "live price right now", "what's each provider quoting on TSLA"

### Pattern 5 — Tick-level history (slow, deep archive)
```sql
SELECT EventTime, ProviderID, InstrumentID,
       Bid, Ask, BidSpreaded, AskSpreaded, USDConversionRate
FROM main.dealing.bronze_pricelog_history_currencyprice
WHERE InstrumentID = 1111
  AND EventTime BETWEEN '2026-05-09 09:30:00' AND '2026-05-09 09:35:00'
ORDER BY EventTime;
```
**Use when:** "price at exactly 09:32:15 on May 9", "tick replay for slippage analysis", forensics. Slow — partition / filter aggressively.

### Pattern 6 — Spread analysis across a date range
```sql
SELECT Date, InstrumentID,
       (AskSpreaded - BidSpreaded) AS etoro_spread,
       (Ask - Bid) AS raw_spread,
       (AskSpreaded - BidSpreaded) - (Ask - Bid) AS etoro_markup
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE InstrumentID = 1111
  AND Date BETWEEN '2026-05-01' AND '2026-05-09'
  AND IsValid = 1
ORDER BY Date;
```
**Use when:** "eToro spread on TSLA this month", "spread markup analysis", best-execution input.

### Pattern 7 — Detect a stock-split date by source-view discrepancy
```sql
WITH split_dates AS (
  SELECT DISTINCT InstrumentID, EffectiveDate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_etoro_history_splitratio
  WHERE EffectiveDate >= '2025-01-01'
)
SELECT InstrumentID, EffectiveDate
FROM split_dates
ORDER BY EffectiveDate DESC;
```
**Use when:** "which instruments split this year?", validating historical price series consistency. Note: the staging schema name and FQN should be verified against the current UC layout; the conceptual table is `DWH_staging.etoro_History_SplitRatio`.

---

## Cross-references

- Position-event price (open / close rate captured at event-time) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Hedge-side execution price (LP-confirmed) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- LP-side reconciliation against eToro-side prices → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- AUM / PnL downstream of these prices → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Instrument metadata (Symbol, TypeID, Exchange) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- NBBO / best-execution analysis (uses these prices as the reference quote) → [`best-execution.md`](best-execution.md)

## Provenance

Authored from Unity Catalog table-level comments harvested 2026-05-11 on `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (full 1,024-char authored description), `main.dealing.bronze_pricelog_history_currencyprice`, `main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview`, `main.general.bronze_etoro_history_bslcurrencypricesnapshots`, `main.trading.bronze_etoro_trade_currencyprice`. Source-of-truth wikis live under `knowledge/synapse/Wiki/DWH/Tables/Fact_CurrencyPriceWithSplit.md` and `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/`.
