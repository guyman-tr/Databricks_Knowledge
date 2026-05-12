---
id: hedge-cost-recon
name: "Hedge Cost Reconstruction (Dealer-Side, Canonical)"
description: "Canonical hedge-cost (HC) source for the trading platform. Anchored on `main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1` — produced by the `HedgeCostAgent` daily pipeline and refreshed every morning (~1.65M rows across 9 asset classes, latest data t-1). Implements the formula **`Hedge_Cost = Client_Zero − Account_PnL − LP_Financing`** for every (asset class × instrument × day) combination. Covers all eToro trading asset classes: CFD Stocks, CFD FX (ICC), CFD Commodities (ICC), CFD Indices (ICC), CFD ETF/Futures, Real Stocks, Crypto CFD, Crypto Real, Crypto Nostro. The 26-column output carries hedge cost plus the underlying components used to compute it: client and LP holdings, commission, overnight fees, ticket fees, financing, dividends, rollover, FX hedging PnL, and EOD prices. **This is the definitive HC answer for ANY question about cost of hedging** — shallow questions (asset class totals, ICC monthly HC) go straight to this table in seconds; deep questions (why is HC so high on a specific instrument? was an anomaly auto-corrected?) require reading the `eToro/HedgeCostAgent` repo's `core/DECISION_TREE.md`, `core/AUTO_RULES.md`, and `core/ACCOUNT_PNL.md` for methodology. Complements `domain-revenue-and-fees` — together they answer **net** trading-revenue questions."
triggers:
  - hedge cost
  - HC
  - HedgeCost
  - HedgeCostAgent
  - hedge cost agent
  - hedge cost recon
  - bi_output_dealing_HC_auto_agent
  - HC auto agent
  - dealing HC
  - cost of hedging
  - Client_Zero
  - Account_PnL
  - LP_Financing
  - LP holding
  - customer holding
  - HC by asset class
  - HC by instrument
  - ICC hedge cost
  - crypto hedge cost
  - real stocks hedge cost
  - CFD hedge cost
  - net trading revenue
  - trading P&L
  - trading margin
  - net of hedge
  - revenue minus hedge cost
  - LP_TicketFees
  - LP_Financing
  - LP_Dividends
  - LP_Rollover
  - FX_Hedge_PnL
  - UBS FX hedge
  - decision tree HC
  - HC auto-rules
  - PHANTOM_AP
  - NO_LP_HEDGE_OUTLIER
  - POSITION_JUMP
  - WEEKEND_DOUBLE
  - DUAL_INSTRUMENT_PRICE_LEAK
  - phantom hedge cost
required_tables:
  - main.bi_dealing_stg.bi_output_dealing_hc_auto_agent_v1
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
  - main.bi_output.bi_ouput_v_dim_instrumenttype
version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-05-12"
---

# Hedge Cost Reconstruction — the Canonical HC Answer

**Dealer-side. Cost of hedging customer exposure.** This is the **definitive answer** for any hedge-cost question on the trading platform. eToro runs a Broker-Dealer model: every customer trade creates a customer-facing position (broker side, revenue lives in [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)) AND an opposite obligation that the dealer side must neutralise by hedging in the market. The cost of running that hedge — the difference between what eToro pays the market and what eToro books against the customer's notional zero-bound exposure — is HEDGE COST.

**The HedgeCostAgent pipeline (`github.com/eToro/HedgeCostAgent`)** runs every morning, ingests 18 UC `gold_*` sources + an Azure Blob fallback for late-arriving LP statements, applies 7 in-SQL anomaly-handling rules and 6 post-INSERT auto-correction rules, and writes the result to **`main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1`**. Treat this table as production-grade truth for HC analysis — it is currently in the `_stg` schema but is the only complete HC ledger.

## When to Use

Load when the question is about:

- "What was our hedge cost last month / quarter / YTD?" — by asset class, by instrument, by day
- **"ICC hedge cost"** — Currencies + Commodities + Indices CFD lines. Critical KPI; **ICC alongside Real Stocks are the structural HC drivers.**
- "What did crypto cost us to hedge?" — Crypto Real (the big one — over $137M YTD HC), Crypto CFD, Crypto Nostro
- "Real Stocks hedge cost trend" — important because Real Stocks HC is volatile day-to-day on borrow costs and dividend events
- "Hedge cost on instrument X" — per `ISINCode` / `InstrumentName`, single asset deep-dive
- "Net trading revenue" = customer revenue (from `domain-revenue-and-fees`) − HC from here, joined on `(AssetClass, date)` or `(InstrumentID, date)`
- "FX hedging PnL" — UBS spot-PnL leg, the `FX_Hedge_PnL` column
- "LP financing / LP rollover / LP dividends paid" — what eToro paid OUT to LPs (the cost legs of HC)
- "Why was HC so high on date X for instrument Y?" — anomaly investigation: which decision-tree rule fired, which auto-rule corrected
- "Was this anomaly auto-corrected?" — every row carries a status flag set by the post-INSERT rules
- Capacity / margin planning that needs HC by asset class

Do **not** load for:

- Customer-side revenue ("commission revenue YTD") — [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- LP configuration (which LP handles which instrument, contract terms) — [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- EOD position-level recon against LP custodian files (Apex, BNY-Virtu, Saxo, Marex, JPM, IG, Vision) — [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Per-execution forensic audit (LP fill rate, slippage at order time, manual order log) — [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- Customer-position state ("what was position X at open?") — [`position-state-and-grain.md`](position-state-and-grain.md)
- Best execution / NBBO / TCA / latency — [`best-execution.md`](best-execution.md)
- Future hedge cost simulation / forecast — out of scope; this skill is the EOD-realised HC ledger only

## Scope

In scope: the canonical HC output table `main.bi_dealing_stg.bi_output_dealing_hc_auto_agent_v1` (26 columns: `etr_ymd`, `AssetClass`, `ISINCode`, `InstrumentName`, `Currency`, `CustomerHolding`, `LPHolding`, `Commission`, `Client_Zero`, `Account_PnL`, `Hedge_Cost`, `Inserted_At`, EOD prices, conversion factors, ticket fees, financing, dividends, rollover, `FX_Hedge_PnL`); the 9 asset classes it covers (CFD Stocks / FX / Commodities / Indices / ETF-Futures, Real Stocks, Crypto Real / CFD / Nostro); the formula `HC = Client_Zero − Account_PnL − LP_Financing`; pointers to the `HedgeCostAgent` repo for decision-tree and auto-rule deep-dives; the cross-join to `domain-revenue-and-fees` for net-trading-revenue questions; ICC asset-class identification and prominence (ICC = CFD Indices + CFD Commodities + CFD FX).
Out of scope: per-execution LP fill logs ([`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)), LP contracts and unit conversion ([`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)), EOD broker recon files ([`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)), customer-side revenue ([`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)), customer position state ([`position-state-and-grain.md`](position-state-and-grain.md)), TCA / slippage / NBBO ([`best-execution.md`](best-execution.md)), future-HC simulation, the 18-source upstream `gold_*` raw ingest tables (analytically irrelevant — the agent has already done the heavy lifting).
Last verified: 2026-05-12

## Critical Warnings

1. **Tier 1 — `Hedge_Cost` column is the ONLY hedge-cost answer; do NOT reconstruct it from Client_Zero / Account_PnL / LP_Financing yourself.** The formula `HC = Client_Zero − Account_PnL − LP_Financing` is the conceptual definition, but the `Hedge_Cost` column has 6 post-INSERT auto-rules applied to it (MARKET_HOLIDAY, NULL_STARTPRICE, POSITION_JUMP v2, WEEKEND_DOUBLE, NO_LP_HEDGE_OUTLIER, DUAL_INSTRUMENT_PRICE_LEAK) that correct for known phantom-HC patterns. Hand-computed HC from components will diverge from the production-truth `Hedge_Cost` value on every day there's been an auto-correction. Always `SUM(Hedge_Cost)`, never `SUM(Client_Zero - Account_PnL - LP_Financing)`. Treat the component columns as audit trail, not as alternative HC.
2. **Tier 1 — Table is in `_stg`, but it IS the production HC source.** `main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1` is currently staged in the `bi_dealing_stg` schema. It is **NOT a draft** — it is the live, daily-refreshed, audit-corrected HC ledger that the dealing team uses for Q1/Q2/quarterly reporting. Treat it as production. (Eventual migration to a non-staging schema is on the roadmap but does not change authority.)
3. **Tier 1 — Asset Class names use HUMAN labels, NOT `InstrumentTypeID`.** The `AssetClass` column carries strings like `'CFD Indices'`, `'Crypto Real'`, `'Real Stocks'` — NOT integer IDs. Always filter on the string. ICC = `AssetClass IN ('CFD Indices', 'CFD Commodities', 'CFD FX')`. The full 9-value enum: `CFD Stocks`, `CFD FX`, `CFD Commodities`, `CFD Indices`, `CFD ETF/Futures`, `Real Stocks`, `Crypto Real`, `Crypto CFD`, `Crypto Nostro`. There is NO direct `InstrumentTypeID` join key on this table — the asset-class enum is the dimension.
4. **Tier 1 — Crypto Real dominates the HC ledger.** YTD 2026 (Jan 1 → May 11): Crypto Real HC = **-$137.2M** vs Real Stocks +$10.5M, CFD Indices -$9.0M, CFD Commodities -$6.3M, CFD Stocks -$5.0M, CFD FX -$4.5M, Crypto CFD -$2.9M, Crypto Nostro +$1.7M, CFD ETF/Futures -$0.15M. Don't be alarmed by a 30× larger absolute HC on Crypto Real than the next-biggest line — it is the structural reality of running a direct-settled crypto book at scale. **Always present HC totals alongside the commission/revenue total** for the same asset class to give context.
5. **Tier 1 — `Crypto Real` and `Crypto Nostro` go back to 2025-09-26 / 2025-10-01; everything else starts 2026-01-01.** The agent backfilled crypto pre-Jan to cover the Q4 2025 staking + on-chain settlement window. For year-over-year on non-crypto asset classes, this table does NOT have 2025 data — you need the legacy `BI_DB_Dealing.HCByClient*` Synapse family for prior-year HC.
6. **Tier 2 — `Hedge_Cost` is signed and the sign matters.** Negative `Hedge_Cost` = eToro PAID OUT to hedge (a true cost). Positive `Hedge_Cost` = eToro RECEIVED net financing/dividends on the hedge book (a structural rebate — happens on Real Stocks and Crypto Nostro under certain conditions). **Do NOT take `ABS(Hedge_Cost)`** unless explicitly asked for total HC magnitude — the sign is part of the answer. P&L impact = `-Hedge_Cost` (HC is a cost subtracted from revenue).
7. **Tier 2 — `FX_Hedge_PnL` is the UBS FX hedging spot leg (PnLVersion=0).** It is the ONLY column on this table that carries an inline comment in the live UC. It captures the spot-PnL leg of FX-hedging against UBS for legacy exposure. Treat it as a **separate income/cost line** that adjusts HC at the asset-class total but is NOT included in the row-level `Hedge_Cost` computation. For "true total HC after FX hedge", add `SUM(FX_Hedge_PnL)` at the asset-class level. Do not mix grain with row-level HC operations.
8. **Tier 2 — `Inserted_At` is the freshness signal; ALWAYS check it first.** The pipeline targets daily refresh by ~07:00 UTC. If `MAX(Inserted_At)` is more than 24 hours behind `current_timestamp()`, the agent has failed or is mid-run. Don't query for "yesterday's HC" if the latest `Inserted_At` is two days ago — you'll get stale data with `etr_ymd` showing the actual gap. Live verification on 2026-05-12: latest `Inserted_At = 2026-05-12 12:15 UTC`, latest `etr_ymd = 2026-05-11` (yesterday) — correct refresh cadence.
9. **Tier 2 — Component columns serve two distinct purposes per row.** The `Client_*` columns (`Client_StartPrice`, `Client_EndPrice`, `Client_ConversionToUSD`, `Client_OverNightFee`, `Client_TicketFees`, `Client_Dividends`) represent the customer-facing side of the position; the un-prefixed (`StartPrice`, `EndPrice`, `ConversionToUSD`) and `LP_*` columns (`LP_TicketFees`, `LP_Financing`, `LP_Dividends`, `LP_Rollover`) represent the market/LP side. The difference between client and LP legs is where hedge cost comes from. **Don't sum across the client/LP boundary** — they are different ledgers measured in the same row for join convenience.
10. **Tier 3 — Real Stocks has its own 7-rule decision tree applied IN-SQL (before the auto-rules).** Real Stocks goes through PHANTOM_AP, NO_LP, EXPOSURE_SCALE, and 4 other rules at compute time — Account_PnL for real-stock positions is constructed differently from CFD positions. See `eToro/HedgeCostAgent/core/DECISION_TREE.md` (7-rule list) and `core/ACCOUNT_PNL.md` (per-asset-class methodology). For most analytical questions you don't need this depth — but if a Real Stocks anomaly comes up, that's the diagnostic path.
11. **Tier 3 — The 6 post-INSERT auto-rules are idempotent and run nightly.** MARKET_HOLIDAY, NULL_STARTPRICE, POSITION_JUMP v2, WEEKEND_DOUBLE, NO_LP_HEDGE_OUTLIER, DUAL_INSTRUMENT_PRICE_LEAK — each corrects a known phantom-HC pattern by re-writing `Hedge_Cost` for the affected `(etr_ymd, ISINCode)` rows. They never `DELETE`; they only update. See `eToro/HedgeCostAgent/core/AUTO_RULES.md` for definitions and order-of-operations. Manual amendments by the dealing analyst also overlay on top of these — they appear with a different `Inserted_At` than the daily batch.
12. **Tier 3 — `CustomerHolding` and `LPHolding` are net-units snapshots at EOD, NOT volume flows.** Aggregating them across days is meaningless. For volume-flow questions ("how much did we trade in BTC last month?") use the trading-volumes fact (`bi_db_ddr_fact_trading_volumes_and_amounts`) in [`trading-volumes.md`](trading-volumes.md), NOT these holdings.

---

## Anchor table — `main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1`

**Source:** `eToro/HedgeCostAgent` daily pipeline. Live UC verified 2026-05-12: 1,651,803 rows, 9 asset classes, latest `etr_ymd = 2026-05-11`, latest `Inserted_At = 2026-05-12 12:15 UTC`.

### Column inventory (26 columns)

| Column | Type | What it is |
|---|---|---|
| `etr_ymd` | DATE | EOD date of the HC row. Primary partition. |
| `AssetClass` | STRING | The 9-value enum (see below). Primary slice dimension. |
| `ISINCode` | STRING | Instrument ISIN (where defined). Per-instrument identifier. |
| `InstrumentName` | STRING | Human label (e.g. `Bitcoin`, `EUR/USD`, `Tesla`). |
| `Currency` | STRING | Settlement currency (USD, EUR, GBP, JPY, …). |
| `CustomerHolding` | DOUBLE | Net client units at EOD (signed; long positive, short negative). |
| `LPHolding` | DOUBLE | Net hedge units at LPs at EOD (signed). |
| `Commission` | DOUBLE | Customer commission booked on this row's trades. ✅ same number lives in `domain-revenue-and-fees` per RevenueMetricID. |
| `Client_Zero` | DOUBLE | Customer's zero-bound notional exposure component of HC formula. |
| `Account_PnL` | DOUBLE | eToro's hedge-account PnL component. |
| **`Hedge_Cost`** | **DOUBLE** | **The answer column. `HC = Client_Zero − Account_PnL − LP_Financing`, post-auto-rules.** |
| `Inserted_At` | TIMESTAMP | Pipeline write timestamp. Freshness signal. |
| `StartPrice` / `EndPrice` | DOUBLE | LP-side EOD price range for the day. |
| `ConversionToUSD` | DOUBLE | LP-side FX-to-USD factor. |
| `Client_StartPrice` / `Client_EndPrice` | DOUBLE | Client-side EOD price (may differ from LP for spread reasons). |
| `Client_ConversionToUSD` | DOUBLE | Client-side FX-to-USD factor. |
| `Client_OverNightFee` | DOUBLE | Rollover charged to the customer. ✅ same number lives in `domain-revenue-and-fees.Metric=RollOverFee` (`RevenueMetricID=5`). |
| `Client_TicketFees` | DOUBLE | Ticket fees charged to customer. ✅ same as revenue Metric `TicketFee`/`TicketFeeByPercent`. |
| `LP_TicketFees` | DOUBLE | Ticket fees eToro paid to LP. NOT in revenue side. |
| `LP_Financing` | DOUBLE | Overnight financing eToro paid to LP. Component of HC formula. |
| `FX_Hedge_PnL` | DOUBLE | **UBS FX hedging spot PnL (PnLVersion=0 legacy exposure).** Adjusts asset-class HC at totals level. |
| `LP_Dividends` | DOUBLE | Dividends eToro paid to / received from LP. |
| `LP_Rollover` | DOUBLE | Rollover eToro received from LP (real-stock borrow rebates land here). |
| `Client_Dividends` | DOUBLE | Dividends paid through to customer. ✅ same as revenue Metric `Dividends` (`RevenueMetricID=16`, IncludedInTotalRevenue=0). |

### Asset Class enum + YTD 2026 HC (live)

| `AssetClass` value | YTD 2026 HC (USD) | YTD Commission (USD) | YTD Overnight (USD) | Member of ICC? | Notes |
|---|---|---|---|---|---|
| **`Crypto Real`** | **-$137.25M** | $45.31M | $0.03M | — | **#1 HC line.** Direct-settled crypto book. 234 distinct instruments, 36K rows, data from 2025-10-01. |
| `Real Stocks` | +$10.51M | $30.34M | $0.02M | — | Real-stock book. 9,942 instruments, 828K rows. Positive HC reflects borrow-rebate income on lent shares. |
| **`CFD Indices`** | -$9.04M | $15.30M | $8.60M | **✅ ICC** | 35 instruments, 3.3K rows. Big overnight fee revenue per dollar of notional. |
| **`CFD Commodities`** | -$6.27M | **$155.28M** | $7.13M | **✅ ICC** | **#1 commission line.** 44 instruments, 5K rows. Huge spread revenue relative to HC drag. |
| `CFD Stocks` | -$5.02M | $46.99M | $18.76M | — | 6,523 instruments, 725K rows. |
| **`CFD FX`** | -$4.53M | $4.54M | -$0.03M | **✅ ICC** | 61 instruments, 7.5K rows. Tight HC vs commission — heavily hedged. |
| `Crypto CFD` | -$2.88M | $21.67M | $8.96M | — | 241 instruments, 44K rows. |
| `Crypto Nostro` | +$1.70M | $0.00 | $0.00 | — | Single instrument, 312 rows from 2025-09-26. Long-side nostro book income. |
| `CFD ETF/Futures` | -$0.15M | $0.24M | $0.50M | — | 6 instruments, ~750 rows. Tiny line. |
| **TOTAL** | **-$152.93M** | **$319.67M** | **$44.01M** | — | YTD trading commission $319.67M vs YTD HC -$152.93M ⇒ rough net trading margin = $166.74M before customer overnight + other fees. |

**ICC = `AssetClass IN ('CFD Indices', 'CFD Commodities', 'CFD FX')`** in HC vocabulary. The dealing-team and the broker-side `InstrumentTypeID IN (1, 2, 4)` line up: Currencies (1) = `CFD FX`, Commodities (2) = `CFD Commodities`, Indices (4) = `CFD Indices`. The HC table doesn't carry `InstrumentTypeID` directly — use `AssetClass` here, use `InstrumentTypeID` on the revenue side, and trust they label the same trades.

### Formula

```
Hedge_Cost = Client_Zero − Account_PnL − LP_Financing
                                        (post-auto-rules)
```

Where:
- **`Client_Zero`** = the customer-facing notional zero-bound exposure component (what the customer "should owe" the broker side based on their own position direction × spread × end-of-day mark).
- **`Account_PnL`** = the eToro-internal PnL on the matched hedge position (constructed per-asset-class — Real Stocks uses a 7-rule decision tree, CFD uses a simpler LP-fill-aligned method, Crypto uses direct on-chain or B2C2/Wintermute settlement). See `eToro/HedgeCostAgent/core/ACCOUNT_PNL.md`.
- **`LP_Financing`** = overnight financing eToro paid (or received from) the LP for holding the hedge book overnight. The "carry" on the hedge.

Sign convention: **HC < 0 = COST (eToro paid out); HC > 0 = STRUCTURAL REBATE (eToro received).** P&L impact of HC = `−Hedge_Cost`.

---

## Query patterns

### Pattern 1 — ICC hedge cost YTD (the "Pareto" question)
```sql
SELECT AssetClass,
       ROUND(SUM(Hedge_Cost)/1e6, 2) AS hc_usd_m,
       ROUND(SUM(Commission)/1e6, 2) AS commission_usd_m,
       ROUND(SUM(Client_OverNightFee)/1e6, 2) AS client_overnight_usd_m
FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1
WHERE etr_ymd >= '2026-01-01'
  AND AssetClass IN ('CFD Indices', 'CFD Commodities', 'CFD FX')   -- ICC
GROUP BY AssetClass
ORDER BY hc_usd_m;
```
**Use when:** "how much hedge cost did we make in ICC YTD?", "ICC HC last quarter"

### Pattern 2 — Daily HC trend by asset class
```sql
SELECT etr_ymd, AssetClass,
       ROUND(SUM(Hedge_Cost), 2) AS daily_hc_usd
FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1
WHERE etr_ymd >= current_date() - INTERVAL 30 DAY
GROUP BY etr_ymd, AssetClass
ORDER BY etr_ymd DESC, daily_hc_usd;
```
**Use when:** time-series, "show me HC by day for the last month"

### Pattern 3 — Top HC instruments in an asset class
```sql
SELECT ISINCode, InstrumentName, Currency,
       ROUND(SUM(Hedge_Cost), 2) AS hc_usd,
       ROUND(SUM(Commission), 2) AS commission_usd,
       SUM(CASE WHEN ABS(CustomerHolding) > 0 THEN 1 ELSE 0 END) AS days_with_position
FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1
WHERE etr_ymd >= '2026-04-01' AND etr_ymd < '2026-05-01'
  AND AssetClass = 'Crypto Real'
GROUP BY ISINCode, InstrumentName, Currency
ORDER BY hc_usd ASC                              -- most-negative first (biggest cost)
LIMIT 20;
```
**Use when:** "what's driving our crypto HC?", per-instrument breakdown

### Pattern 4 — Net trading revenue (revenue − HC, joined to `domain-revenue-and-fees`)
```sql
WITH revenue AS (
    SELECT Date AS dt,
           CASE WHEN InstrumentTypeID = 1 THEN 'CFD FX'
                WHEN InstrumentTypeID = 2 THEN 'CFD Commodities'
                WHEN InstrumentTypeID = 4 THEN 'CFD Indices'
                WHEN InstrumentTypeID = 5 THEN 'CFD Stocks'
                WHEN InstrumentTypeID = 6 THEN 'CFD ETF/Futures'  -- approximate label-map
                WHEN InstrumentTypeID = 10 THEN 'Crypto CFD'
                ELSE 'Other' END AS asset_class,
           SUM(Amount) AS revenue_usd
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
    WHERE Date >= '2026-04-01' AND Date < '2026-05-01'
      AND IncludedInTotalRevenue = 1
    GROUP BY Date, InstrumentTypeID
),
hc AS (
    SELECT etr_ymd AS dt, AssetClass AS asset_class,
           SUM(Hedge_Cost) AS hc_usd
    FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1
    WHERE etr_ymd >= '2026-04-01' AND etr_ymd < '2026-05-01'
    GROUP BY etr_ymd, AssetClass
)
SELECT r.dt, r.asset_class,
       ROUND(r.revenue_usd, 2) AS revenue_usd,
       ROUND(COALESCE(h.hc_usd, 0), 2) AS hc_usd,
       ROUND(r.revenue_usd + COALESCE(h.hc_usd, 0), 2) AS net_trading_revenue_usd
FROM revenue r LEFT JOIN hc h ON r.dt = h.dt AND r.asset_class = h.asset_class
ORDER BY r.dt, r.asset_class;
```
**Use when:** "net trading revenue last month by asset class", "trading P&L after hedge cost"

**Caveat on the asset-class join:** the DDR-side `InstrumentTypeID` only roughly maps to the HC `AssetClass` (revenue side doesn't distinguish CFD vs Real for stocks/crypto in the same way HC does). For a perfectly clean join, use per-instrument `ISINCode` (when available on both sides via `Dim_Instrument`).

### Pattern 5 — Freshness / pipeline-health check
```sql
SELECT MAX(Inserted_At) AS latest_insert,
       MAX(etr_ymd) AS latest_etr_ymd,
       COUNT(DISTINCT AssetClass) AS asset_classes,
       COUNT(*) AS total_rows,
       DATEDIFF(MINUTE, MAX(Inserted_At), current_timestamp()) AS minutes_since_refresh
FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1;
```
**Use when:** verifying the agent has run today before quoting HC numbers

### Pattern 6 — Investigate a specific anomalous day (decision-tree drill-down precursor)
```sql
SELECT etr_ymd, AssetClass, ISINCode, InstrumentName,
       CustomerHolding, LPHolding,
       Client_Zero, Account_PnL, LP_Financing, Hedge_Cost,
       StartPrice, EndPrice, ConversionToUSD, FX_Hedge_PnL,
       Inserted_At
FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1
WHERE etr_ymd = '2026-04-15'
  AND AssetClass = 'Real Stocks'
  AND ABS(Hedge_Cost) > 100000
ORDER BY ABS(Hedge_Cost) DESC
LIMIT 20;
```
**Use when:** "why was Real Stocks HC so big on date X?" — start here, then go to the HedgeCostAgent repo to read which decision-tree rule fired.

---

## When to go deep — pointers into the HedgeCostAgent repo

For analytical questions, this skill + the canonical table is enough. For **methodology** / **anomaly forensics** / **rule audits**, the source-of-truth is the dealing team's `eToro/HedgeCostAgent` repo:

| Question class | Repo file | What it tells you |
|---|---|---|
| "Why does HC use `Client_Zero` not actual customer P&L?" | `core/FORMULA.md` | Core formula derivation; why Zero is used; where gaps come from; FX hedging details; 3-stage pipeline (Client PnL → Account PnL per LP → Aggregation). |
| "How is `Account_PnL` constructed for {asset class}?" | `core/ACCOUNT_PNL.md` | Per-asset-class methodology — eToro EOD prices, FX isolation, transfer-safe positions; CFD Stocks vs Real Stocks vs CFD ETF/Futures all differ. |
| "What's the 7-rule decision tree for Real Stocks anomalies?" | `core/DECISION_TREE.md` | The 7 in-SQL anomaly-handling rules (PHANTOM_AP, NO_LP, EXPOSURE_SCALE, …) applied at compute time, plus an investigation checklist. |
| "What auto-rules might have fired on row X?" | `core/AUTO_RULES.md` | The 6 post-INSERT idempotent auto-rules: MARKET_HOLIDAY, NULL_STARTPRICE, POSITION_JUMP v2, WEEKEND_DOUBLE, NO_LP_HEDGE_OUTLIER, DUAL_INSTRUMENT_PRICE_LEAK — order of operations and the phantom-HC pattern each one corrects. |
| "Where does the raw LP data come from when gold tables lag?" | `core/LP_BLOB_STORAGE.md` | Azure Blob storage fallback path structure (Bronze/Silver/Gold tiers), per-LP coverage map, known issues (e.g. JPM blob stalled, LPs not in blob storage). |
| "How is the pipeline orchestrated end-to-end?" | `PRD.md`, `GUIDE.md` | Product Requirements Document + non-technical user guide. PRD has the operational runbook, pipeline diagnostics, reconciliation framework, known limitations. |
| "What's currently broken / on the TODO list?" | `TODO.md` | Open issues by asset class (Equities, ICC Commodities, ICC Indices, ICC FX, Crypto, Main Report, Reconciliation, Infrastructure). |

The repo is the **methodology truth**; this table is the **analytical truth**. Most questions never need to leave the table.

---

## Cross-references

- **Revenue side of trading P&L** → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md). Join on `(AssetClass ↔ InstrumentTypeID, etr_ymd ↔ Date)` for net trading revenue. Note: HC subtracts from revenue (it's a cost).
- **LP configuration / which LP hedges what** → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md). This is the upstream — which LP type/instance/account is even routed to hedge a given instrument.
- **EOD broker recon** → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md). Position-level matches against LP custodian files (Apex, BNY-Virtu, Saxo, Marex, JPM, IG, Vision). HC reconstruction is downstream of recon.
- **Per-execution audit** → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md). Order-by-order LP fill log, manual order audit, EMS investigation tool.
- **Best execution / TCA / slippage** → [`best-execution.md`](best-execution.md). Cost-of-execution decomposition (SpreadCost + Slippage + InternalCost + ExternalCost = TotalTransactionCost). HC ≠ TCA — TCA is per-order, HC is per-day asset-class.

---

## Cross-cutting facts

- **HC is a daily EOD ledger.** No intraday HC; if a question needs intraday, route to `dealing-investigation-and-execution.md` for per-execution data.
- **Sign matters.** Negative `Hedge_Cost` = cost. P&L impact = `−Hedge_Cost`. Don't `ABS()`.
- **9 asset classes, 26 columns, ~1.65M rows.** Table is small enough that no-filter queries return in seconds. Still, always include an `etr_ymd` filter for query-cost discipline.
- **The `AssetClass` enum is dealing-team-authored**, not derived from `Dim_InstrumentType`. The values are stable but distinct from `InstrumentTypeID`. Use the cross-walk above to bridge.
- **ICC in HC vocabulary = CFD Indices + CFD Commodities + CFD FX.** In broker-side vocabulary, ICC = `InstrumentTypeID IN (1, 2, 4)`. Same instruments, different label sources.
- **Manual amendments overlay daily auto-corrections.** A row's `Hedge_Cost` may have been edited by the dealing analyst after the nightly batch — visible via a non-matching `Inserted_At` for one row vs its siblings. Don't be surprised by single-row updates.
- **No DDR fact equivalent.** There is no `BI_DB_DDR_Fact_HedgeCost` — only the staging table. Don't search for one; this IS the canonical source.

## Skill provenance

- v1 (2026-05-12): authored from analysis of the `eToro/HedgeCostAgent` repository (`README.md`, `PRD.md`, `GUIDE.md`, `CLAUDE.md`, `TODO.md`, `core/FORMULA.md`, `core/DECISION_TREE.md`, `core/ACCOUNT_PNL.md`, `core/AUTO_RULES.md`, `core/LP_BLOB_STORAGE.md`, `queries/hc_auto_agent_v1_ddl.sql`).
- Live UC verification on 2026-05-12: 1,651,803 rows, 9 asset classes, latest `etr_ymd = 2026-05-11`, latest `Inserted_At = 2026-05-12 12:15 UTC`. Asset-class YTD totals computed live.
- Authored at the user's direction: the HedgeCostAgent should be "the definitive hedge cost source — very shallow when someone asks about HC, goes straight to the table; if they ask WHY or HOW, dig deeper into the repo." This file implements that pattern: query-pattern-led for the 90% shallow case, repo-pointer-led for the 10% deep case.
