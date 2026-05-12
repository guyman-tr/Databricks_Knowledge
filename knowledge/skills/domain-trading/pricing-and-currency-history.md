---
id: pricing-and-currency-history
name: "Pricing & Currency History"
description: "Historical and real-time instrument pricing across the trading platform. Four-table price stack: Fact_CurrencyPriceWithSplit (DWH daily authoritative — 14 cols + 3 partition cols, ~17.2M rows since 2009-06-15, 15,400+ instruments, with split-aware source switching at corporate-action dates, the isvalid lowercase EOD flag, raw Bid/Ask + spread-adjusted BidSpreaded/AskSpreaded, RateLastEx as last-execution price, and the ConvertRateIsBuy_1 / ConvertRateIsBuy_0 pre-computed USD conversion rates added 2023-02-26 with 4-case derivation rule); History.CurrencyPrice in the Bronze data lake (the complete tick-level archive); History.CurrencyPriceMaxDateWithSplitView (the fast last-price cache for 9,339 instruments — 1440-min override); Trade.CurrencyPrice (real-time per-provider tick cache — 60-min override). Plus BSL audit snapshots, staging views, and the etoro_History_SplitRatio split-calendar. Covers the split-adjustment mechanic, the per-date DELETE+INSERT refresh (and gap-if-missed risk), spread-adjusted vs raw price semantics, the 3 vs 1 ProviderID provenance question, and ConvertRate NULL gaps (~7.5% lifetime)."
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
  - last execution rate
  - ConvertRateIsBuy_1
  - ConvertRateIsBuy_0
  - USD conversion rate
  - cross rate
  - split adjustment
  - SplitRatio
  - corporate action price
  - stock split
  - mark to market
  - FX rate
  - real-time price
  - Trade.CurrencyPrice
  - BSL snapshot
  - BSL price
  - BSLCurrencyPriceSnapShots
  - price tick
  - end of day price
  - isvalid price
  - IsValid price
  - OccurredDateID
  - etoro_History_SplitRatio
required_tables:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  - main.dealing.bronze_pricelog_history_currencyprice
  - main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview
  - main.trading.bronze_etoro_trade_currencyprice
  - main.general.bronze_etoro_history_bslcurrencypricesnapshots
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Pricing & Currency History

eToro's price stack is a **four-tier system** spanning real-time, cached, daily, and tick-archive grains. Each tier has a different refresh cadence, a different consumer, and a different split-adjustment behaviour:

- **Real-time** (`Trade.CurrencyPrice`) — overwritten on every tick by the price-feed engine. One row per `ProviderID × InstrumentID`. Used by order placement and position valuation. NOT a history table.
- **Latest-cache** (`History.CurrencyPriceMaxDateWithSplitView`) — fast lookup of the most-recent split-adjusted bid/ask price per instrument. 9,339 rows. 1440-min override.
- **Daily authoritative** (`Fact_CurrencyPriceWithSplit`) — DWH's source of truth for daily prices, with `isvalid = 1` marking the end-of-day price. Switches sources at corporate-action dates to deliver historically-adjusted prices. **~17.2M rows since 2009-06-15.**
- **Tick-archive** (`History.CurrencyPrice` in Bronze data lake) — every tick ever received by the price-feed system. The data-lake archive that backfills all of the above.

**Side classification**: **Cross-cutting** — pricing data is consumed by both broker-side (customer P&L valuation, position open/close prices) and dealer-side (LP-rate joins, slippage analysis, hedge-book valuation). The skill is anchored on the broker-side DWH publication (`Fact_CurrencyPriceWithSplit`) and the dealer-side tick archive (`History.CurrencyPrice` via Bronze). Routing rule: customer-P&L pricing → DWH daily; LP slippage / `RateIDAtSent` join → Bronze tick archive (see Warning #7 cross-ref).

This sub-skill is the analyst-facing map of which table to ask which price question.

## When to Use

Load when the question is about:

- "What was the EOD price of TSLA on 2026-03-15?", "historical price lookup"
- "What's the current bid/ask on BTC?", "live price right now"
- "Mark-to-market price for position X at open"
- "Bid/ask spread on instrument Y over time", "eToro markup vs market"
- "USD conversion rate for an instrument on a date" (`ConvertRateIsBuy_1` / `_0`)
- "How does the system handle TSLA's stock split on 2022-08-25?", "split-adjusted history"
- "Tick-level price at exactly 09:32:15"
- "BSL snapshot price for an equity audit" (`Trade.CheckBSL` recalculation)
- "Why does the price look different in two tables?" → likely a split-adjustment vs raw discrepancy, OR the `isvalid` filter is missing
- "Slippage join target for `RateIDAtSent`" (see [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md) Pattern 5)

Do **not** load for:

- Position state at an event-time price → [`position-state-and-grain.md`](position-state-and-grain.md) — the position-event tables embed the rate AT the event (open-rate / close-rate columns)
- LP fill rate / execution events at LP-confirmed prices → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md) — `ExecutionLog.ExecutionRate` is the LP price
- AUM / PnL valuation (which uses these prices but lives downstream) → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Customer's portfolio dashboard price display (consumed from these tables but the display sits in product) — out of scope
- Instrument metadata (Symbol, TypeID, Exchange, MKTcap) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)

## Scope

In scope: `Fact_CurrencyPriceWithSplit` (DWH daily authoritative, 14 cols + 3 partition cols, `isvalid` lowercase EOD flag, `OccurredDateID` int YYYYMMDD vs `OccurredDate` timestamp vs `Occurred` sub-day timestamp, raw Bid/Ask + AskSpreaded/BidSpreaded + RateLastEx, `ConvertRateIsBuy_1`/`_0` 4-case derivation rule for USD conversion, the split-aware source switching via `DWH_staging.etoro_History_SplitRatio`, the per-date DELETE+INSERT refresh with gap-if-missed risk, the `Ext_FCPWS_Instrument` currency-pair staging table); `History.CurrencyPrice` Bronze tick archive (every tick ever — bid/ask, spread adjustments, USD conversion rates, market rate IDs, skew, persisted from `Trade.CurrencyPrice` via PriceLog pipeline; the join target for `RateIDAtSent` slippage analysis); `History.CurrencyPriceMaxDateWithSplitView` last-price cache (9,339 rows, 1440-min override); `Trade.CurrencyPrice` real-time price cache (per provider × instrument, 60-min override); `History.BSLCurrencyPriceSnapShots` (BSL execution audit snapshots — Bid/Ask per instrument at each BSL invocation); the staging views; `Fact_Settlement_Prices` (related — settlement-specific price fact); the ProviderID consolidation observation (wiki=3, live=1 currently — Warning #5).

Out of scope: position-state with embedded rate (`position-state-and-grain.md`), execution-event LP price (`dealing-investigation-and-execution.md`), portfolio valuation downstream (`portfolio-value-aum-pnl.md`), instrument metadata (`instruments-and-asset-classes.md`).

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `isvalid` is LOWERCASE and the filter is mandatory.** Column name is `isvalid` (not `IsValid` — Synapse `varchar(MAX)` casing has been preserved in UC). The fact table writes multiple intraday candle snapshots per `(InstrumentID, OccurredDateID)`; only the row with `isvalid = 1` is the active end-of-day price. **~46% of all rows are `isvalid = 0`** (recent April-May 2026 sample: ~50%). **Always filter `WHERE isvalid = 1`** for daily P&L lookups, or you'll get duplicates and over-count in joins. The PRIMARY analyst error on this table.

2. **Tier 1 — On stock-split dates, the ETL switches its source view.** Normal days: `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView`. Split days (instrument appears in `DWH_staging.etoro_History_SplitRatio`): `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which provides historically-adjusted prices for affected instruments. **The same `(InstrumentID, OccurredDateID)` row can return different absolute prices** depending on whether you read pre-split (raw historical) or post-split (split-aware) data — the split-aware view always returns the post-split-adjusted value retroactively. ConvertRates from the pre-split date are preserved via a `#ConvertRateIsBuy` temp table join.

3. **Tier 1 — `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` are NULL for ~7.5% of rows.** Per the wiki, ~1.3M rows lifetime have NULL ConvertRate values where no cross-rate could be computed. The 4-case derivation rule:
   - `SellCurrencyID = 1` (USD as quote/sell): `ConvertRate = 1.00` (already in USD).
   - `BuyCurrencyID = 1` (USD as base/buy): `ConvertRateIsBuy_1 = 1/Bid`, `ConvertRateIsBuy_0 = 1/Ask`.
   - Neither currency is USD: cross-rate via a bridging instrument with USD as base/quote.
   - No cross-rate available: NULL (callee should `ISNULL(..., 1.0)` or investigate via `Ext_FCPWS_Instrument`).
   
   `ConvertRateIsBuy_1` is for buy-side positions (`IsBuy = 1`); `ConvertRateIsBuy_0` for sell-side. Both columns added 2023-02-26 — older data is NULL for both regardless of currency.

4. **Tier 1 — `OccurredDateID` is INT YYYYMMDD, NOT a date.** For date-range filters use `OccurredDateID BETWEEN 20260101 AND 20260331`, not `OccurredDate >= '2026-01-01'`. The Synapse NCI was on `OccurredDateID`; in UC the convention is the same (and the table is also partitioned by `etr_ymd` for parquet-pruning — use both filters when authoring large queries).

5. **Tier 1 — `Trade.CurrencyPrice` is OVERWRITTEN per-tick — NOT a history table.** It tells you "the last price right now". For any past timestamp, use either `History.CurrencyPrice` (Bronze tick archive — sub-day) or `Fact_CurrencyPriceWithSplit` (DWH daily — EOD). Querying `Trade.CurrencyPrice` for historical data returns whatever the latest tick happened to be, NOT what the price was at the time of interest.

6. **Tier 2 — `Bronze.CurrencyPrice` (the production-side archive) ≠ OLTP `etoro.History.CurrencyPrice`.** Naming clash. The data path: `Trade.CurrencyPrice` (live cache) → ticks also written to `History.CurrencyPrice` (production archive) → land in Bronze data lake via the PriceLog pipeline → exposed in UC as `main.dealing.bronze_pricelog_history_currencyprice`. The `History.CurrencyPriceMaxDateWithSplitView` cache is a DIFFERENT OLTP table (the 9,339-row last-price cache, exposed in UC as `main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview`). Same word "History"; different tables.

7. **Tier 2 — Spread-adjusted vs raw prices answer different questions.** Every price row in `Fact_CurrencyPriceWithSplit` exposes both raw (`Bid`/`Ask`) and eToro-spread-adjusted (`BidSpreaded`/`AskSpreaded`). Use the **spread-adjusted column for customer-facing P&L valuation** (matches what customers see and what AUM/PnL facts use downstream). Use the **raw column for slippage / LP-execution comparisons** (matches what the LP quoted). Don't average across columns. The difference `AskSpreaded - Ask` and `Bid - BidSpreaded` is the eToro markup — useful for best-execution analysis (see [`best-execution.md`](best-execution.md)).

8. **Tier 2 — `RateLastEx` is the last execution rate, not a quote.** It records the rate at which the last hedge order actually executed against this instrument on the date. Useful for hedge-side P&L; misleading if you treat it as a market quote. For market-quote questions, use `Bid`/`Ask` or `BidSpreaded`/`AskSpreaded`.

9. **Tier 2 — DELETE+INSERT per-`@dt` refresh; gaps can appear if the SP misses a date.** `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)` is date-parameterized — it deletes and reloads ONE date at a time. If the SP didn't run for a date (incident, infra failure), there will be NO rows for that date until a manual backfill. Check `COUNT(DISTINCT OccurredDateID)` against expected business-day counts when you see suspicious gaps.

10. **Tier 3 — ProviderID provenance varies over time.** Wiki (2026-03) reports **3 distinct ProviderID values** in production. Live data (recent 6 weeks of 2026-04→05) shows **only 1 ProviderID** — the price-provider pipeline has consolidated since the wiki was authored. **Most analytical queries do NOT filter on ProviderID** — but if you do, verify the current state with `SELECT DISTINCT ProviderID` against your date range. Multiple providers can contribute prices for the same instrument on the same date, which is part of why `isvalid` matters.

11. **Tier 3 — `Occurred` is sub-day precision, separate from `OccurredDate` (DATE) and `OccurredDateID` (INT YYYYMMDD).** For intraday analysis from this DAILY table, use `Occurred`; for date-level, use the partitioned columns. Note that `OccurredDate` is exposed as `TIMESTAMP` in UC (not `DATE`) but typically has zero time component.

## Tables — the four-tier price stack

| Tier | Table | Grain | Refresh | Use For |
|---|---|---|---|---|
| **Real-time** | `main.trading.bronze_etoro_trade_currencyprice` | `ProviderID × InstrumentID` (overwritten) | Override, 60-min | Current bid/ask "right now" |
| **Latest cache** | `main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview` | `InstrumentID` (9,339 rows, one per instrument) | Override, 1440-min | Fast lookup of the most-recent split-adjusted bid/ask |
| **Daily authoritative ★** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | `InstrumentID × OccurredDateID × ProviderID × snapshot` (filter `isvalid = 1` for EOD) | Daily SP (`SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse`); partitioned by `etr_y/etr_ym/etr_ymd` in UC | Historical EOD price, P&L valuation, `ConvertRateIsBuy_*` USD conversion |
| **Tick archive** | `main.dealing.bronze_pricelog_history_currencyprice` | Every tick | Continuous (via PriceLog pipeline) | Sub-daily / arbitrary timestamp price; **slippage-join target** for `RateIDAtSent` |

★ = primary entry point. 14 data columns + 3 partition columns:

| Column | Type | Notes |
|---|---|---|
| `ProviderID` | INT | Price provider ID — wiki says 3 distinct, live shows 1 (Warning #10). |
| `InstrumentID` | INT | FK to Dim_Instrument. HASH distribution key in Synapse; main join key. 15,400+ distinct. |
| `Occurred` | TIMESTAMP | Sub-day-precision timestamp of the price candle. |
| `OccurredDate` | TIMESTAMP | Calendar date (time portion typically zero). |
| `OccurredDateID` | INT | YYYYMMDD format. Use for date-range filters (Warning #4). |
| `isvalid` | INT | **Lowercase, mandatory filter for EOD** (Warning #1). ~54% of rows are 1. |
| `AskSpreaded` | DECIMAL | Spread-adjusted ask — customer-facing buy cost. |
| `BidSpreaded` | DECIMAL | Spread-adjusted bid — customer-facing sell proceeds. |
| `RateLastEx` | DECIMAL | Last execution rate (NOT a quote — Warning #8). |
| `Ask` | DECIMAL | Raw market ask. |
| `Bid` | DECIMAL | Raw market bid. |
| `UpdateDate` | TIMESTAMP | DWH load timestamp (not price time). |
| `ConvertRateIsBuy_1` | DECIMAL | USD conversion for buy-side. Added 2023-02-26; NULL for ~7.5% (Warning #3). |
| `ConvertRateIsBuy_0` | DECIMAL | USD conversion for sell-side. Same NULL behaviour. |
| `etr_y`, `etr_ym`, `etr_ymd` | STRING | UC partition columns for parquet pruning. |

### Auxiliary tables

| Table | Use For |
|---|---|
| `main.general.bronze_etoro_history_bslcurrencypricesnapshots` | **BSL** (Brokerage Service Layer) execution audit snapshots — Bid/Ask per instrument at each BSL invocation. Used by `Trade.CheckBSL` for equity audit recalculation. |
| `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` *(staging)* | Daily candlestick prices for all instruments — the ETL source for `Fact_CurrencyPriceWithSplit` on non-split dates. |
| `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory` *(staging)* | Historically-adjusted prices for split-affected instruments — used on split dates. |
| `DWH_staging.PriceLog_History_CurrencyPrice_Active` *(staging)* | Derivative used by `SP_Dim_Position_DL_To_Synapse` to enrich open/close market prices and USD conversion rates per position. |
| `DWH_staging.etoro_History_SplitRatio` *(staging)* | Per-instrument-per-date split ratio — triggers the source-view switch in `Fact_CurrencyPriceWithSplit` ETL. |
| `DWH_dbo.Ext_FCPWS_Instrument` | External-references staging table for currency pairs (`BuyCurrencyID`/`SellCurrencyID`) used in ConvertRate computation. |
| `Fact_Settlement_Prices` | Sibling fact for settlement-specific prices (real-asset T+2 settlement, etc.). Out of scope here but cross-referenced. |

---

## Query Patterns

### Pattern 1 — EOD price for an instrument on a date
```sql
SELECT InstrumentID, OccurredDateID,
       Bid, Ask, BidSpreaded, AskSpreaded, RateLastEx,
       ConvertRateIsBuy_1, ConvertRateIsBuy_0
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE InstrumentID = 1111            -- e.g. Tesla
  AND OccurredDateID = 20260509
  AND isvalid = 1;                   -- LOWERCASE, MANDATORY
```
**Use when:** "EOD price of Tesla on May 9", "what was the closing bid/ask?". **The `isvalid = 1` filter is mandatory** (Warning #1).

### Pattern 2 — Price time series for an instrument
```sql
SELECT OccurredDate, BidSpreaded, AskSpreaded,
       (BidSpreaded + AskSpreaded) / 2.0 AS mid_spreaded
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE InstrumentID = 1111
  AND OccurredDateID BETWEEN 20260101 AND 20260331
  AND isvalid = 1
ORDER BY OccurredDateID;
```
**Use when:** "Tesla price chart this quarter", "BTC bid trend over time"

### Pattern 3 — Latest price across many instruments (fast cache)
```sql
SELECT InstrumentID, Bid, Ask, BidSpreaded, AskSpreaded
FROM main.bi_db.bronze_etoro_history_currencypricemaxdatewithsplitview
WHERE InstrumentID IN (1111, 14259, 15200);
```
**Use when:** "current price for these instruments", "watch-list snapshot". 1440-min cache — slightly stale but fast.

### Pattern 4 — Current real-time price per provider
```sql
SELECT ProviderID, InstrumentID, Bid, Ask
FROM main.trading.bronze_etoro_trade_currencyprice
WHERE InstrumentID = 1111;
```
**Use when:** "live price right now", "what's each provider quoting on TSLA?". Per-tick overwrite — true real-time.

### Pattern 5 — Tick-level history (slippage analysis, the `RateIDAtSent` join target)
```sql
SELECT EventTime, ProviderID, InstrumentID,
       Bid, Ask, BidSpreaded, AskSpreaded, USDConversionRate
FROM main.dealing.bronze_pricelog_history_currencyprice
WHERE InstrumentID = 1111
  AND EventTime BETWEEN '2026-05-09 09:30:00' AND '2026-05-09 09:35:00'
ORDER BY EventTime;
```
**Use when:** "price at exactly 09:32:15 on May 9", "tick replay for slippage", forensics. The slippage-join target for `Hedge.ExecutionLog.RateIDAtSent` — see [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md) Pattern 5. Slow — partition / filter aggressively.

### Pattern 6 — USD conversion rate with NULL fallback
```sql
SELECT InstrumentID, OccurredDateID,
       Bid, Ask,
       COALESCE(ConvertRateIsBuy_1, 1.0) AS rate_buy_with_fallback,
       COALESCE(ConvertRateIsBuy_0, 1.0) AS rate_sell_with_fallback,
       CASE WHEN ConvertRateIsBuy_1 IS NULL THEN 'NO_CROSS_RATE_FOUND' END AS warn
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE OccurredDateID = 20260509
  AND isvalid = 1
  AND InstrumentID IN (1111, 14259);
```
**Use when:** "convert this instrument's PnL to USD", "USD-equivalent value for a non-USD-quoted asset". Always COALESCE — 7.5% of rows have NULL ConvertRate (Warning #3).

### Pattern 7 — Spread / markup analysis across a date range
```sql
SELECT OccurredDateID,
       AVG(AskSpreaded - Ask)         AS avg_etoro_ask_markup,
       AVG(Bid - BidSpreaded)         AS avg_etoro_bid_markup,
       AVG((AskSpreaded - BidSpreaded) - (Ask - Bid)) AS avg_etoro_total_spread_addition
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE InstrumentID = 1111
  AND OccurredDateID BETWEEN 20260501 AND 20260509
  AND isvalid = 1
GROUP BY OccurredDateID
ORDER BY OccurredDateID;
```
**Use when:** "eToro spread on TSLA this month", "best-execution markup input". The `Spreaded - raw` difference IS the eToro markup.

### Pattern 8 — Gap detection (was the SP run for all expected dates?)
```sql
SELECT OccurredDateID,
       COUNT(*) AS total_rows,
       SUM(CASE WHEN isvalid = 1 THEN 1 ELSE 0 END) AS valid_rows,
       COUNT(DISTINCT InstrumentID) AS instruments
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
WHERE OccurredDateID BETWEEN 20260501 AND 20260509
GROUP BY OccurredDateID
ORDER BY OccurredDateID;
-- Expected: ~5 business days, ~15K instruments each, ~50% rows isvalid=1.
-- Missing dates or low instrument counts = SP gap (Warning #9).
```
**Use when:** validating data completeness before authoring a critical report.

### Pattern 9 — Stock-split detection
```sql
-- The split calendar lives in DWH_staging.etoro_History_SplitRatio.
-- Conceptual query (verify FQN in your environment — may not be exposed in UC):
SELECT DISTINCT InstrumentID, EffectiveDate, SplitRatio
FROM <DWH_staging.etoro_History_SplitRatio mirror>
WHERE EffectiveDate >= '2025-01-01'
ORDER BY EffectiveDate DESC;
```
**Use when:** "which instruments split this year?", validating historical price-series consistency. Note: the staging schema may not be exposed in UC directly — verify with information_schema.

---

## Cross-references

- Position-event price (open / close rate captured at event-time) → [`position-state-and-grain.md`](position-state-and-grain.md) — `fact_customeraction_w_metrics` embeds the rate
- Hedge-side execution price (LP-confirmed) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md) — `ExecutionLog.ExecutionRate`
- The `RateIDAtSent` slippage-join target → Pattern 5 above (Bronze tick archive)
- LP-side reconciliation against eToro-side prices → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- AUM / PnL downstream of these prices → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Instrument metadata (Symbol, TypeID, Exchange) → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- NBBO / best-execution analysis (uses these prices as the reference quote) → [`best-execution.md`](best-execution.md)
- Spread markup as a revenue input → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: S = Synapse-first (DWH publication). `Tier`: 1a wiki, 1b UC comment, 3 lineage, 4 live distincts.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| Fact_CurrencyPriceWithSplit | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CurrencyPriceWithSplit.{md,lineage.md} | Full 14-col reference; ETL semantics (DELETE+INSERT per @dt); split-aware source switching; 4-case ConvertRate derivation; `isvalid` lowercase convention; 15,400+ distinct instruments; ~17.2M rows since 2009-06-15; 3 distinct ProviderID per wiki |
| Fact_CurrencyPriceWithSplit | S | 1b + 4 | UC information_schema.columns + live SELECT (2026-05-11) | 14 data cols + 3 partition cols (etr_y/etr_ym/etr_ymd); UC column types confirmed (DECIMAL for prices, INT for OccurredDateID/isvalid); 16,079 instruments + 1 ProviderID in the April-May 2026 sample (vs 3 in wiki); 50% isvalid=1 rate matches wiki ~54%; ConvertRate NULL rate in recent data is 0.3% (vs 7.5% lifetime — wiki was right about the lifetime stat but recent data is cleaner) |
| History.CurrencyPrice (Bronze) | H | 1b | UC table-level comment for `main.dealing.bronze_pricelog_history_currencyprice` | Tick archive; the slippage-join target for `RateIDAtSent` (see dealing-investigation-and-execution skill) |
| History.CurrencyPriceMaxDateWithSplitView | S | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/ + UC comment | 9,339-row last-price cache, 1440-min override; the fast watch-list lookup |
| Trade.CurrencyPrice | S | 1b | UC table-level comment | Real-time per-provider cache, 60-min override; NOT a history table |
| History.BSLCurrencyPriceSnapShots | S | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/ | BSL audit snapshots; used by `Trade.CheckBSL` |

## Provenance

v2 rebuilt 2026-05-11 per `/speckit.skill` Phase 2.5. v1 was authored from UC table-level comments only; v2 adds the deep `Fact_CurrencyPriceWithSplit` Synapse wiki (24 documented columns including 14 schema cols + ETL semantics + 4-case ConvertRate derivation) and live UC SELECT verification.

**Key v2 additions vs v1**:
- **`isvalid` column name corrected to lowercase** (Warning #1) — v1 incorrectly used `IsValid`. Live UC confirms lowercase.
- **`OccurredDateID` (INT YYYYMMDD) vs `OccurredDate` (TIMESTAMP) vs `Occurred` (sub-day TIMESTAMP) explicit** (Warning #4 + Warning #11) — v1 had only "Date".
- **14-column full reference table** with UC types — v1 listed only 6 cols informally.
- **`ConvertRateIsBuy_1` / `_0` 4-case derivation rule documented** (Warning #3) — v1 didn't mention USD conversion at all.
- **~7.5% lifetime ConvertRate NULL gap** flagged (Warning #3) — v1 didn't mention.
- **Stock-split source switching mechanic** kept and expanded with the `#ConvertRateIsBuy` temp-table preservation note (Warning #2).
- **Per-date DELETE+INSERT gap risk** (Warning #9) — new in v2.
- **ProviderID provenance variation** (Warning #10) — wiki says 3, live shows 1, callout on the consolidation.
- **UC partition columns** (`etr_y`/`etr_ym`/`etr_ymd`) documented — v1 didn't mention.
- **`RateLastEx` is NOT a quote** (Warning #8) — clarified.
- **Cross-cutting side classification** explicit (broker-side P&L valuation + dealer-side slippage join).
- **3 new query patterns**: Pattern 6 (USD conversion with NULL fallback), Pattern 7 (spread markup), Pattern 8 (gap detection).
- **`Fact_Settlement_Prices` sibling** acknowledged as out-of-scope but cross-referenced.
- **`Ext_FCPWS_Instrument` staging table** documented for ConvertRate provenance.
