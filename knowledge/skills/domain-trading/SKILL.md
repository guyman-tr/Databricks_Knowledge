---
id: domain-trading
name: "Trading & Markets Super-Domain"
description: "Routes inside the Trading & Markets super-domain. Covers the position lifecycle, the instrument catalogue, trading volumes & invested amounts, end-of-day portfolio value (AUM, NOP, equity, PnL), copy trading and mirror relationships, broker / liquidity-provider reconciliation, dealing investigation & execution events, pricing & currency history, liquidity-provider contracts and cost-of-goods-sold, crypto trading operations (Nixar / Fireblocks), and best-execution analytics (NBBO, slippage, fails, latency). Anchored on the new granular fact `fact_customeraction_w_metrics` plus the DDR fact family (volumes, AUM, PnL, revenue-generating actions) and `Dim_Position` / `Dim_Instrument` for metadata enrichment. Load this hub for any question about WHAT customers traded and HOW the trade was executed."
triggers:
  - position
  - trade
  - position open
  - position close
  - position state
  - PositionID
  - Dim_Position
  - fact_customeraction
  - fact_customeraction_w_metrics
  - PositionChangeLog
  - instrument
  - InstrumentID
  - InstrumentTypeID
  - Dim_Instrument
  - trading volume
  - notional volume
  - invested amount
  - real vs CFD
  - IsSettled
  - SettlementTypeID
  - AUM
  - portfolio value
  - total equity
  - NOP
  - net open position
  - unrealized PnL
  - realized PnL
  - paper gains
  - copy trade
  - mirror
  - MirrorID
  - MirrorTypeID
  - smart portfolio
  - copy fund
  - Popular Investor
  - PI trade
  - broker reconciliation
  - LP reconciliation
  - liquidity provider
  - Duco
  - Apex recon
  - BNY Mellon
  - Virtu
  - Saxo
  - Marex
  - JPM
  - IG
  - Vision
  - dealing investigation
  - execution log
  - HBCExecutionLog
  - EMSOrders
  - manual order
  - currency price
  - FX rate
  - History.CurrencyPrice
  - pricing log
  - LP contract
  - LiquidityProviderContracts
  - cost of goods
  - COGS
  - hedge
  - Nixar
  - Fireblocks
  - crypto trading ops
  - best execution
  - NBBO
  - slippage
  - fails
  - latency
  - Best Execution Committee
  - by instrument
  - by ticker
  - TSLA
  - BTC
  - ETH
required_tables:
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position
  - main.etoro_kpi_prep.v_dim_instrument_enriched
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
sample_questions:
  - "What was the state of position X when it opened?"
  - "How much was traded in real stocks this quarter?"
  - "What's our AUM today?"
  - "Tesla revenue this month"
  - "Crypto unrealized PnL trend"
  - "What's NOP exposure right now?"
  - "Which positions were opened as copies?"
  - "Show me Apex EOD recon for last week"
  - "What was the slippage on USD/JPY on January 29?"
  - "How many trades failed in February?"
  - "Recreate position 12345's state on 2026-03-15"
  - "Show me the LP fees we paid for crypto last month"
domain_tags:
  - trading
  - positions
  - instruments
  - volumes
  - portfolio
  - aum
  - pnl
  - copy-trading
  - dealing
  - liquidity-providers
  - reconciliation
  - best-execution
  - pricing
  - crypto-ops
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Trading & Markets Super-Domain

A trade on eToro is **not one row in one table** — it is a lifecycle. A customer clicks Buy on Tesla, that triggers an opening `Fact_CustomerAction` row, which creates a `Dim_Position` master record, which gets enriched into `fact_customeraction_w_metrics`, which routes through one or more liquidity providers (Apex for US equity, BNY/Virtu for non-US equity, Marex / JPM / IG / Vision for CFDs, Fireblocks / Nixar for crypto settlement), gets reconciled end-of-day in `Dealing.DealingDuco_EODRecon`, contributes to volume in `bi_db_ddr_fact_trading_volumes_and_amounts`, accrues PnL in `bi_db_ddr_fact_pnl`, sits in the customer's end-of-day equity in `bi_db_ddr_fact_aum`, and finally throws off a fee row in `bi_db_ddr_fact_revenue_generating_actions`. Different questions live at different points in that lifecycle — and the **same position has different "states" at each point**.

This super-domain is about **WHAT customers traded and HOW the trade was executed**. It is **not** about:

- **Who the customer is, their identifiers, jurisdiction, club tier, segment** → Customer & Identity super-domain (`../domain-customer-and-identity/SKILL.md`).
- **Money flow into / out of the customer wallet** (deposits, withdrawals, MIMO, IBAN flows, FTDs) → Payments super-domain (`../domain-payments/SKILL.md`). Trading IS the destination of those funds — but the deposit-side question routes there.
- **Fee revenue or fee composition on a trade** → Revenue & Fees super-domain (`../domain-revenue-and-fees/SKILL.md`). The trade VOLUME stays here; the COMMISSION/ROLLOVER/TICKET_FEE revenue lives there. The two are linked by `PositionID` / `ActionID`.
- **AML risk classification, sanctions, PEP, watchlist alerts on a trade** → Compliance super-domain (planned).

When a question is about **the trade itself** (what instrument, what volume, what price, was it a copy, did it fill, what was the slippage), it stays here. When it is about **the fee that trade generated** ("how much commission did Tesla trades produce?"), route to Revenue & Fees and use `PositionID` to link back.

## When to Use

Load when the question concerns position state, instrument selection, trade volume, end-of-day portfolio value, copy trading, dealing operations, liquidity-provider flow, or execution quality:

- "What's position 12345's state right now?", "what was it at open?"
- "Total notional trading volume this quarter", "real vs CFD breakdown", "volume by asset class"
- "Platform AUM today", "NOP trend this month", "unrealized PnL by instrument"
- "Tesla revenue / volume / PnL" — anything filtered by a specific instrument
- "How many trades were copies?", "Smart Portfolio AUM", "Popular Investor trade share"
- "Apex / Saxo / BNY-Virtu / Marex / JPM / IG / Vision EOD recon", "broker break", "LP discrepancy"
- "ExecutionLog for position X", "manual order audit", "HBC execution trail"
- "USD/JPY rate at 14:00 yesterday", "spot price for ETH on March 1"
- "Crypto hedge cost", "LP contract fee", "what did we pay liquidity providers"
- "Slippage report", "NBBO compliance", "trade fails report", "execution latency", "Best Execution Committee output"

Do **not** load for:

- Customer master attributes (jurisdiction, club, PI status) → Customer & Identity
- Deposit / withdrawal / MIMO → Payments
- Fee revenue composition / `Total Net Revenue` math → Revenue & Fees
- Spaceship / MoneyFarm AUM (those are acquired-platform owned products) → Revenue & Fees per-product sub-skills

## Scope

In scope: position lifecycle, `Dim_Position` metadata, `fact_customeraction_w_metrics` granular state, `PositionChangeLog` point-in-time reconstruction, `Dim_Instrument` and the enriched view (asset class, suffix, IsFuture, Tradeable, IsSQF), notional & invested trading volumes (`bi_db_ddr_fact_trading_volumes_and_amounts`), AUM / NOP / equity snapshots (`bi_db_ddr_fact_aum`), daily PnL changes (`bi_db_ddr_fact_pnl`), copy-trading semantics (MirrorID / MirrorTypeID / IsCopy / IsCopyFund), broker & liquidity-provider reconciliation (Duco EOD, Apex, BNY-Virtu, Saxo, Marex, JPM, IG, Vision), dealing investigation feeds (ExecutionLog, HBCExecutionLog, EMSOrders), pricing history (`History.CurrencyPrice`, market currency price logs), liquidity-provider contracts and the cost-of-goods-sold side of trading, crypto trading ops (Nixar pipelines, Fireblocks settlement), best-execution analytics (NBBO, slippage, fails, latency, Best Execution Committee output).
Out of scope: customer master record (Customer & Identity), deposit/withdrawal flows (Payments), fee revenue composition (Revenue & Fees), AML risk classification (Compliance), acquired-platform product AUM / fees (Revenue & Fees per-product sub-skills — `revenue-spaceship`, `revenue-moneyfarm`, `revenue-options`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `fact_customeraction_w_metrics` is the source of truth for transactional state; `Dim_Position` is metadata only.** `Dim_Position` stores the *current* value of metadata fields and overwrites on update — so asking it "was this position opened as a copy?" or "what mirror was it under at open?" returns the *current* `MirrorID` (often `0` if the position has since been detached from the mirror), NOT the value at open. The fact (`main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`) captures the value at each action event and is the only place to ask state-at-event-time questions. Use `Dim_Position` ONLY to enrich the fact with attributes that don't change over the position's lifetime (instrument-pinned metadata, fill prices at open, spread snapshot at open). Anything else: the fact wins.
2. **Tier 2 — `PositionChangeLog` is the only deterministic source for point-in-time position state.** When you need "what was position X's state on 2026-03-15?" the fact captures the events, but the change-log (`main.dwh.gold_sql_dp_prod_we_dwh_dbo_positionchangelog` or its equivalent in the trade schema) is the only place that records every mutation with a timestamp. Rarely needed for routine analytics, but it is the authoritative point-in-time replay table. Don't reach for it for "current state" questions — use the fact + dim instead.
3. **Tier 2 — Instrument filters require the two-part `Symbol`/`Name` + `InstrumentTypeID` pattern.** A filter on `Symbol LIKE 'ETH%'` alone matches an Italian stock (Eurotech SpA, `InstrumentTypeID = 5`), not Ethereum. A filter on `Symbol = 'TSLA'` alone misses 7 of Tesla's 8 InstrumentIDs (RTH session, 24-7 session, EUR-denominated, options chain). Always pair the ticker with `InstrumentTypeID` and (when filtering for tradeable assets) `IsFuture = 0` + `Tradeable = 1`. The full rule set lives in [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md).
4. **Tier 3 — AUM/NOP are snapshots; never `SUM` across `DateID`.** `bi_db_ddr_fact_aum` stores one row per customer per day = end-of-day state. `SUM(TotalEquityTP)` across a date range gives `N × actual AUM`. Use a single `DateID` or `AVG`. Same rule for `NOP`. The PnL fact is different — `UnrealizedPnLChange` and `NetProfit` are daily deltas and DO sum.
5. **Tier 3 — Volume, Invested, and Equity are three different units; never divide.** `TotalVolume` (notional, post-leverage) ÷ `InvestedAmountOpen` (capital pre-leverage) does NOT give you leverage — they aggregate at different grains. Same for `Equity` vs `TotalVolume`. If a question requires leverage, take it from `Dim_Position.Leverage` directly.

## Mental model — the position lifecycle

```mermaid
graph TB
    Click["Customer clicks Buy"]
    Action["Fact_CustomerAction<br/>raw event log"]
    Wmetrics["fact_customeraction_w_metrics<br/>granular state at event<br/>(✓ for transactional facts)"]
    Position["Dim_Position<br/>metadata master record<br/>(metadata only, never state)"]
    Changelog["PositionChangeLog<br/>point-in-time replay<br/>(rare, deterministic)"]
    LP["LP routing<br/>Apex / BNY-Virtu / Saxo /<br/>Marex / JPM / IG / Vision /<br/>Fireblocks-Nixar"]
    Recon["DealingDuco_EODRecon<br/>+ per-LP recon tables"]
    Volumes["ddr_fact_trading_volumes_and_amounts<br/>daily notional + invested"]
    PNL["ddr_fact_pnl<br/>daily PnL change"]
    AUM["ddr_fact_aum<br/>end-of-day equity / NOP"]
    Revenue["ddr_fact_revenue_generating_actions<br/>fee row<br/>(→ domain-revenue-and-fees)"]

    Click --> Action
    Action --> Wmetrics
    Action --> Position
    Wmetrics -.replay.-> Changelog
    Wmetrics --> LP
    LP --> Recon
    Wmetrics --> Volumes
    Wmetrics --> PNL
    Wmetrics --> AUM
    Wmetrics --> Revenue
```

**Routing rules**:

- "What did this position look like when opened?" → fact (`fact_customeraction_w_metrics`), filtered on the opening `ActionTypeID` (1/2/3/39).
- "What does this position look like right now?" → fact for state values, dim for fill price / spread snapshots / instrument metadata.
- "What did this position look like on date X (not now, not at open)?" → `PositionChangeLog` (rare, slow, but deterministic).
- "How much did we trade in stocks last quarter?" → DDR volumes fact, not the granular fact.
- "What's our AUM trend?" → DDR AUM fact.
- "Did this customer copy someone on this trade?" → fact (`MirrorID` at the open event), NOT dim.

## Sub-skill routing

| Sub-skill | Anchor (UC FQN) | When to load |
|---|---|---|
| [`position-state-and-grain.md`](position-state-and-grain.md) | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` | The fact-vs-dim rule, `ActionTypeID` map, position lifecycle, `IsActiveTrade` / `IsSettled` / `MirrorID` semantics, what to ask each table for, point-in-time replay via `PositionChangeLog`. **Read first** for any position-state question. |
| [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) | `main.etoro_kpi_prep.v_dim_instrument_enriched`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.bi_output.bi_ouput_v_dim_instrumenttype` | The two-part filter pattern, the `InstrumentTypeID` map (1=FX, 5=Stocks, 6=ETF, 10=Crypto, …), the ETH collision trap, suffix meanings (.RTH, .24-7, .EUR, .CALL/.PUT, .JAN26), enriched flags (`IsFuture`, `Tradeable`, `IsSQF`). Load for "by instrument" or "by ticker" anywhere. |
| [`trading-volumes.md`](trading-volumes.md) | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | Notional trading volume, invested amount, trade counts, position flags (`IsSettled`, `IsCopy`, `IsCopyFund`, `IsRecurring`, `IsOpenedFromIBAN`), real vs CFD, by asset class. The `IsOpenedFromIBAN` STRING gotcha. |
| [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md) | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | End-of-day equity, NOP, invested amount, daily PnL change (unrealized + realized), copy equity split. The two-fact split (AUM = snapshot, PnL = delta). |
| `copy-trading-and-mirror.md` *(pending — fills when dealing-analyst skill lands)* | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`, `main.trade.positiontbl` | Mirror types (Smart Portfolio = 4, copy-trade = others), Popular Investor (PI) economics, copy chain, MirrorID semantics over time. **Placeholder** — load `position-state-and-grain` for the MirrorID-at-open rule in the interim. |
| [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md) | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon`, plus per-LP recon tables | Duco end-of-day recon, Apex recon (US equity + Options), BNY-Mellon / Virtu (non-US equity), Saxo, Marex, JPM, IG, Vision. Broker breaks, position discrepancies, settlement state. |
| [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md) | `main.trade.executionlog`, `main.trade.hbcexecutionlog`, `main.bi_db.gold_*_emsorders` | Per-position execution audit, manual order log, EMS orders, fill-quality forensics. Operator drill-down. |
| [`pricing-and-currency-history.md`](pricing-and-currency-history.md) | `main.dwh.gold_sql_dp_prod_we_history_dbo_currencyprice`, market currency price logs | Spot FX rates over time, instrument price history, intraday pricing log, mark-to-market inputs. |
| [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md) | `main.trade.liquidityprovidercontracts`, plus LP cost-of-goods tables | LP contract terms, fees paid TO providers (cost-of-goods-sold side), `ProviderUnitConversionRatio`, hedge cost. **Cost-of-trading, NOT revenue.** |
| `crypto-trading-ops-nixar.md` *(pending — fills when dealing-analyst skill lands)* | `main.dealing.gold_*_nixar_*` family, plus Fireblocks settlement views | Crypto-settlement pipeline (Nixar), Fireblocks custody, hedge book, on-chain confirmation flow. **Placeholder** — see `/Workspace/Repos/dealing/BI-Dealing/databricks/Nixar/` for production code reference. |
| [`best-execution.md`](best-execution.md) | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`, plus the four EQ analyses | NBBO compliance, slippage, trade fails, execution latency. The four pillars of execution quality, the Best Execution Committee process, monthly cuts. Methodology and routing into `/Workspace/Shared/(Clone) Execution Quality Presentation/`. |

## Cross-domain skills

| Cross-domain | Connects | When to load |
|---|---|---|
| (none yet — Trading↔Revenue link via `PositionID` is mechanical, no cross-domain skill required) | — | A future B↔A cross-domain (customer-trading) is a likely candidate for "all trades by this customer with their attributes" patterns. Today the join is direct via `RealCID`. |

## Cross-cutting facts

These hold whether you load any sub-skill or not:

- **The grain hierarchy** (smallest → largest, all on the trading platform):
  - `fact_customeraction_w_metrics` — 1 row per customer action event (open, close, modify, fee, cashout, …). Asset-specific, transactional, ~billions of rows. **Most granular source.**
  - `Dim_Position` — 1 row per `PositionID` (lifetime master). Metadata only.
  - `bi_db_ddr_fact_revenue_generating_actions` — 1 row per (customer × date × metric) — fee aggregation.
  - `bi_db_ddr_fact_trading_volumes_and_amounts` — 1 row per (customer × date × flags) — volume aggregation.
  - `bi_db_ddr_fact_pnl` — 1 row per (customer × date × instrument × copy × settled) — PnL aggregation.
  - `bi_db_ddr_fact_aum` — 1 row per (customer × date) — end-of-day snapshot.

- **`fact_customeraction_w_metrics` > `Dim_Position` for transactional state, every time.** See Critical Warning #1. The fact captures the value at each event; the dim overwrites on update. The fact is also FAST — partitioned, narrow-row, no joins needed for the common "tickerwise" question. Reach for the dim ONLY when you need a metadata field that isn't in the fact (the dim has ~75 columns; the fact has the ~25 most-asked).

- **The instrument-filter rule is universal.** Symbol/Name + `InstrumentTypeID` — every time. `ETH` collides across 5 type-IDs including an Italian stock. `TSLA` has 8 InstrumentIDs across sessions. The discovery query lives in [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) — run it before authoring a filter.

- **AUM/NOP/equity are snapshot units; volume and invested are flow units; PnL changes are delta units.** Never divide across categories. Never `SUM` snapshots across dates. The unit-cheat-sheet:

  | Concept | Unit | Aggregation rule | Source |
  |---|---|---|---|
  | `TotalVolume` | notional, leveraged | `SUM` across rows + dates | volumes fact |
  | `InvestedAmountOpen` | capital, pre-leverage | `SUM` across rows + dates | volumes fact |
  | `TotalEquityTP` | end-of-day stock | `SUM` across customers (single date); `AVG` over dates | AUM fact |
  | `NOP` | end-of-day stock | `SUM` across customers (single date); `AVG` over dates | AUM fact |
  | `UnrealizedPnLChange` | daily mark-to-market delta | `SUM` across rows + dates | PnL fact |
  | `NetProfit` | daily realized delta | `SUM` across rows + dates | PnL fact |
  | `TotalPositionPNL` | cumulative unrealized | `SUM` across customers (single date) | AUM fact |
  | `Amount` (revenue) | per-event fee | `SUM` filtered by `IncludedInTotalRevenue=1` | revenue fact (→ domain-revenue-and-fees) |

- **Copy-trade identification is on the FACT, not the DIM.** `MirrorID > 0` at the **opening event** in `fact_customeraction_w_metrics` = it was opened as a copy. `Dim_Position.MirrorID` is the *current* mirror linkage and changes over the position's life. The dim and the fact will disagree the moment a customer stops a Smart Portfolio but keeps the position (the dim updates `MirrorTypeID` to detach; the fact preserves the open event).

- **The IBAN gotcha**: `IsOpenedFromIBAN` is STRING in the volumes fact — `WHERE IsOpenedFromIBAN = 1` returns zero rows. Use `WHERE IsOpenedFromIBAN = '1'`. See `trading-volumes.md`.

## What this skill is NOT

- It does not contain SQL — sub-skills do. The hub routes only.
- It does not own fee revenue composition — that's in `domain-revenue-and-fees`. Volume stays here; revenue lives there; link by `PositionID` / `ActionID`.
- It does not own customer master attributes (jurisdiction, club, PI status) — those route to `domain-customer-and-identity`. The PI economics that DO touch trading (copy mechanics, mirror types) stay here in `copy-trading-and-mirror.md`.
- It does not own deposit/withdrawal/MIMO — that's `domain-payments`. The `IsOpenedFromIBAN` flag on a TRADE stays here; the IBAN flow itself routes there.
- It is not a wiki — it routes to per-table wikis under `knowledge/synapse/Wiki/<schema>/Tables/<obj>.md` for full column-level detail.

## Skill provenance

- Cluster source: Louvain super-domain A in [`_CHECKPOINT_A.md`](../_CHECKPOINT_A.md). Local sub-skills derived from clusters 0, 4, 7, 8, 9, 11, 13, 14, 15 (per `_domain_candidates.md`).
- Anchor objects (per `_router.md` legacy + the 67-row UC harvest run on 2026-05-11): `fact_customeraction_w_metrics`, `Dim_Position`, `Dim_Instrument`, `PositionChangeLog`, the DDR fact family (`fact_aum`, `fact_pnl`, `fact_trading_volumes_and_amounts`), the dealing recon family (`DealingDuco_EODRecon`, Apex / BNY-Virtu / Saxo / Marex / JPM / IG / Vision per-LP recons), `Dim_Mirror`, `Trade.LiquidityProviderContracts`, `History.CurrencyPrice`.
- Three DE workspace-root skills are deeply incorporated and superseded by sub-skills here: `instruments` → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md); `trading-volumes` → [`trading-volumes.md`](trading-volumes.md); `portfolio-value` → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md). The originals at `/Workspace/.assistant/skills/{instruments,trading-volumes,portfolio-value}/` are scheduled for removal once these are validated.
- UC FQN resolution: queried against `main.system.information_schema.tables` on 2026-05-11 (67 trading-relevant rows verified). Tableau dashboard graph contributed dealing-side dashboard names that surface in the routing table (Best Execution Committee, Weekly Dealing).
- Pending content: two placeholder sub-skills (`copy-trading-and-mirror`, `crypto-trading-ops-nixar`) await dealing-analyst-authored content; one sub-skill (`best-execution`) will be enriched with notebook-level methodology when the dealing analysts deliver their skill.
