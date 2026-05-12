---
id: best-execution
name: "Best Execution — NBBO, Slippage, Fails, Latency, TCA"
description: "DEALER-SIDE execution-quality framework for the trading platform. eToro is a Broker-Dealer: the broker side is customer-facing (positions, fees, P&L) and the dealer side is market-facing (LP routing, hedge servers, execution, recons, shortfalls) — best execution lives entirely on the dealer side. Four operational pillars: NBBO (fill price vs market best at execution), SLIPPAGE (quoted vs actual fill), FAILS (orders that didn't execute or settle), LATENCY (click→confirm round-trip). Plus the canonical TCA cost decomposition (Transaction Cost Analysis = SpreadCost + Slippage + InternalCost + ExternalCost = TotalTransactionCost). PRIMARY ANCHOR: dealing-team-curated `main.dealing.bestexecution_results` (per-execution table with pre-computed Slippage_Percent, Slippage_Dollar_Value, Latency_In_HBC_In_Seconds, Latency_In_CBH_In_Seconds, and the full request→route→send→fill timing chain). SECONDARY: `bi_output_dealing_bestexecution_report` (BI cut with Kusto integration), `bi_output_dealing_latency_compensation` (customers paid back for slow execution), and bronze hedge logs (`Hedge.ExecutionLog`, now 100% EMS-path with OrderID=-1 and EMSOrderID as the join key). Broker-side tables (`fact_customeraction_w_metrics`, `Dim_Position`) deliberately do NOT carry execution-quality columns — routing a slippage question there is a broker/dealer category error. Routes into the monthly Execution Quality Presentation deck for the Best Execution Committee."
triggers:
  - best execution
  - execution quality
  - NBBO
  - National Best Bid Offer
  - TCA
  - transaction cost analysis
  - slippage
  - slippage analysis
  - slippage dollar
  - slippage percent
  - trade fails
  - failed trades
  - execution latency
  - latency analysis
  - latency compensation
  - latency-impacted customers
  - HBC latency
  - CBH latency
  - fill quality
  - Best Execution Committee
  - BOD execution
  - Gold Event
  - monthly execution cut
  - weekly dealing
  - execution forensics
  - markout
  - price improvement
  - EMS order
  - EMSOrderID
  - HBC vs CBH
  - bestexecution_results
  - dealing bestexecution
required_tables:
  - main.dealing.bestexecution_results
  - main.dealing.bi_output_dealing_bestexecution_report
  - main.dealing.bi_output_dealing_latency_compensation
  - main.dealing.rnd_output_dealing_bestexecution_dim_position
  - main.dealing.rnd_output_dealing_bestexecution_currencyprice
  - main.dealing.rnd_output_dealing_bestexecution_ems_investigation_tool
  - main.dealing.rnd_output_dealing_bestexecution_position_change_log
  - main.dealing.bronze_etoro_hedge_executionlog
  - main.dealing.bronze_etoro_hedge_hbcexecutionlog
  - main.dealing.bronze_etoro_hedge_manualorderexecutionlog
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Best Execution — NBBO, Slippage, Fails, Latency, TCA

> **eToro is a Broker-Dealer.** This skill lives on the **DEALER** side of that boundary. The dealer is everything market-facing: LP routing, hedge servers, execution, shortfalls, recons. The broker is everything customer-facing: positions, trades, fees, P&L. Best execution is a property of how the dealer executes against LPs on the customer's behalf — so all its data lives in dealer-side artifacts (`main.dealing.*` in UC, `Hedge.*` / `Dealing_*` in Synapse). Broker-side tables (`Dim_Position`, `Fact_CustomerAction`, `fact_customeraction_w_metrics`) DO NOT carry execution-quality columns — and that is by design, not an omission. If you find yourself routing a slippage / NBBO / latency / TCA question to a broker-side table, you've crossed the boundary in the wrong direction.

Best execution is a **regulatory obligation** (MiFID II in Europe, equivalent rules in US/UK/AU/IL) AND a commercial commitment: every customer order must be executed on the best available terms across price, costs, speed, likelihood of execution, settlement, and size. eToro tracks this through a **four-pillar operational framework** (NBBO / SLIPPAGE / FAILS / LATENCY) plus the canonical **TCA cost decomposition** (Transaction Cost Analysis from `Hedge.Report_TCA`), feeding into a **Best Execution Committee** review cadence and into the **Execution Quality Presentation** deck.

The four operational pillars:

1. **NBBO** — National Best Bid/Offer. Was the customer's fill price within (or improving on) the market's best at the moment of execution?
2. **SLIPPAGE** — Gap between the customer's quoted price and the actual fill. Reported in `bestexecution_results.Slippage_Percent` and `Slippage_Dollar_Value` per execution. Includes the dedicated Best Execution Committee cuts and event-specific analyses (e.g. Gold Event 29 Jan 2026).
3. **FAILS** — Orders that didn't execute (LP rejected, market closed, circuit-broken) or didn't settle (Apex / BNY break, recovery state).
4. **LATENCY** — End-to-end click→confirm timing. Reported as `Latency_In_HBC_In_Seconds` / `Latency_In_CBH_In_Seconds` in `bestexecution_results`, with the full timing chain (ClientClickArrivalToBETime → OrderSentToDealingTime → eToroSendingTimeToLP → LPExecutionSendingTime → eToroReceiveTimeFromLP → SentTimeToClient). Customers paid back for latency-impacted trades land in `bi_output_dealing_latency_compensation`.

The canonical cost view:

5. **TCA (Transaction Cost Analysis)** — `Hedge.Report_TCA` decomposes total hedge cost into four components:
   - **SpreadCost** = LP bid/ask spread
   - **Slippage** = adverse price movement during execution lifetime (ExecToRequestDelay)
   - **InternalCost** = eToro markup over the LP mid (eToro's earned spread)
   - **ExternalCost** = response-side slippage (pure LP execution quality, ExecToResponseDelay)
   - **TotalTransactionCost** = eToro price at request vs actual execution = SpreadCost + Slippage + InternalCost

## When to Use

Load when the question is about:

- "Best execution this month", "what was our NBBO compliance in February?"
- "Slippage on USD/JPY on 2026-01-29", "average slippage by asset class", "Slippage_Dollar_Value distribution"
- "Best Execution Committee report this quarter"
- "Failed trades last week", "how many fails on TSLA last month?"
- "Execution latency", "p99 latency by LP", "did our latency degrade after the March release?", "client-to-execution latency"
- "Latency compensation — how much did we pay back to customers this month?"
- "TCA / Transaction Cost Analysis", "SpreadCost vs InternalCost by LP", "what's the hedge cost on EURUSD this week?"
- "Why did this specific order fill at this price?" (forensics — combines with `pricing-and-currency-history` + `dealing-investigation-and-execution`)
- "GOLD EVENT 29 JAN 2026 execution review" — event-specific cut
- "Weekly Dealing slippage cut"

Do **not** load for:

- Single-position hedge-execution event detail → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD LP reconciliation → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Pricing-table mechanics (where prices come from) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Customer-side position state (Dim_Position gotchas, partial-close grain) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Revenue / commission on a trade → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)

## Scope

In scope: the four-pillar best-execution framework (NBBO / SLIPPAGE / FAILS / LATENCY), the TCA cost decomposition, the **dealing-curated UC stack** (`bestexecution_results` + `bi_output_dealing_*` + `rnd_output_dealing_*`), the bronze hedge log family (`Hedge.ExecutionLog`, `Hedge.HBCExecutionLog`, `Hedge.ManualOrderExecutionLog`), the cross-DB synonyms underpinning `SSRS_Latency_Report` (`SynHedgeEMSOrders`, `SyneToroLogsHedgeOrderLog`), monthly-cut structure and naming convention (Nov / Dec / Jan26 / Feb26 / ongoing), event-cut convention (Gold Event 29 Jan 2026), Best Execution Committee routing, Weekly Dealing operational cut, the EQ Presentation deck structure, the latency methodology (the `Latency Python` notebook), Kusto integration for client-side timing, the data-sources stack underneath each pillar.

Out of scope: single-order execution forensics (`dealing-investigation-and-execution.md`), broker EOD reconciliation (`broker-and-lp-reconciliation.md`), price-data mechanics (`pricing-and-currency-history.md`), regulatory MiFID II framework documentation (out of analyst-skill scope; lives in compliance), customer-side P&L derivation (`portfolio-value-aum-pnl.md`).

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — Broker ≠ Dealer. `fact_customeraction_w_metrics` is a BROKER-side table; best-execution is a DEALER-side concern.** w_metrics carries customer-trade events (position opens/closes, commissions, fees, tickets, dividends, etc.) — that's the broker's job (customer-facing). It deliberately does NOT carry OpenRate/CloseRate/Bid/Ask/Spread/Slippage/NBBO/ExecutionID — those are the dealer's job (LP-facing). The split is by design, not an omission. The prior version of this skill routed slippage/NBBO questions to w_metrics: that was a category error. The correct dealer-side anchor is `main.dealing.bestexecution_results` (per-execution, with pre-computed `Slippage_Percent`, `Slippage_Dollar_Value`, `Latency_In_HBC_In_Seconds`, `Latency_In_CBH_In_Seconds`, and the full timing chain). **General rule:** any execution-quality / hedge-cost / LP-routing / market-microstructure question routes to `main.dealing.*` or to the `Hedge.*` / `Dealing_*` Synapse schemas. Customer-positions / fees / P&L questions stay on the broker side. [Sources Consulted #8 & #19.]

2. **Tier 1 — `Hedge.ExecutionLog` recent data is 100% EMS-path (`OrderID = -1`).** In the last 7 days observed (2026-05-04 → 2026-05-11), all 1,215,268 rows had `OrderID = -1` and used `EMSOrderID` as the join key. Zero legacy/HedgeServer-path rows. Any dedup or join MUST use `EMSOrderID` (with `COLLATE Latin1_General_BIN` in cross-system joins) — joining on `OrderID` will collapse the entire dataset to a single bucket. The legacy `OrderID > 0` path still has historical rows but is no longer active.

3. **Tier 1 — `Hedge.HBCExecutionLog` is archive-only (last data 2024-02-29).** 26.8M rows but nothing new since Feb 2024. HBC (Hedge By Customer, order-based path) was the active path through 2023; today's executions flow through the EMS/Fully-Async path and appear in `Hedge.ExecutionLog` (now bronze in UC). Do not assume HBCExecutionLog has current data. Use it only for historical HBC studies or for the `InitExecutionID`/`EndExecutionID` linkage from Dim_Position.

4. **Tier 1 — Best execution is NOT a single fact column — it is a methodology applied across a curated data stack.** No published view gives "best execution % this month" as one column. The dealing team's `bestexecution_results` is the closest thing to a unified per-execution table (82 columns including pre-computed slippage and latency), but the **methodology cuts** (monthly NBBO, monthly Slippage, Weekly Dealing, BEC reviews, Gold Event) live as **notebooks** under `/Workspace/Shared/(Clone) Execution Quality Presentation/`. When someone asks for a best-execution number, route them to the relevant monthly notebook or to `bestexecution_results` aggregated by their cut — not to a custom ad-hoc query against the bronze hedge logs.

5. **Tier 1 — UC column comments on `bi_output_dealing_bestexecution_report` are PARTIALLY WRONG.** The comment-merge pipeline mis-propagated split-ratio descriptions onto `Markup`, `SlippageInDollar`, `History_Price_Rate`, `ForexRate`, and `AmountInUnitsDecimal` in this table — they all incorrectly read "Same as AmountRatio: Cumulative amount/quantity adjustment multiplier" from `Dim_HistorySplitRatio`. The actual semantics: `SlippageInDollar` = dollar slippage value, `Markup` = eToro spread markup, `ForexRate` = instrument FX rate, `AmountInUnitsDecimal` = position size. Treat UC comments on this table as **unreliable**; read column meaning from the dealing analyst code (`/Workspace/Repos/dealing/BI-Dealing/`) or from the dealing best-exec methodology notebooks. (Same class of bug as the `w_metrics.PositionID` / `IsCopyFund` mis-comments documented in `position-state-and-grain.md`.) Worth a follow-up ticket against the column-comment merge pipeline.

6. **Tier 1 — The Best Execution Committee outputs live in `(Clone) Execution Quality Presentation/SLIPPAGE/BEST EXECUTION COMMITTEE/`** (a sub-folder under the slippage pillar). The committee meets to review the monthly cuts and event-cuts; their packs are the canonical answer to "what's our best-execution posture this quarter?". Do NOT author a custom slippage query for a regulator or executive ask — direct to the committee output.

7. **Tier 2 — Monthly cuts use a date convention: month-name + year-suffix.** Verified live folder structure as of 2026-05-11: `Nov` / `Dec` (2025), `Jan 26` / `JAN 26` (casing varies by pillar), `FEB 26`. Year `2025` is the full-year retrospective. `BOD Q4 2025` = Board of Directors Quarter 4 2025 deck. **The folder structure is human-curated, not programmatically generated.** When looking for "the latest cut", list the folder and disambiguate by reading the folder names.

8. **Tier 2 — Latency data has THREE sources, depending on the timing chain segment.**
   - **Application/EMS side (`Hedge.ExecutionLog` + cross-DB synonyms)**: `SendTime`, `ReceivedTime`, `ExecutionTime` on the row. The cross-DB synonyms `SynHedgeEMSOrders` (→ `eToroLogs_Real.Hedge.EMSOrders`) and `SyneToroLogsHedgeOrderLog` (→ `eToroLogs_Real.Hedge.OrderLog`) supply `RequestTime` and `StatusUpdateTime` — these are NOT in the bronze hedge tables in UC. Used in `Hedge.SSRS_Latency_Report`'s five-metric framework (M1 Request_Process_Time, M2 Provider_Response_Latency, M3 Execution_Response_Process_Time, M4 Total Internal Latency = M1+M3, M5 Throughput).
   - **Pre-computed in `bestexecution_results`**: `Latency_In_HBC_In_Seconds`, `Latency_In_CBH_In_Seconds`, plus a full timing chain (`ClientClickArrivalToBETime`, `OrderSentToDealingTime`, `eToroSendingTimeToLP`, `LPExecutionSendingTime`, `eToroReceiveTimeFromLP`, `eToroTOBExecutionTime`, `SentTimeToClient`, `OccurredOnProvider`).
   - **Client-side via Kusto**: `bi_output_dealing_bestexecution_report` and `bi_output_dealing_latency_compensation` include `KustoTime` / `Kusto_Rate` / `RequestTimeFromEMS` — Kusto is the streaming/event store that supplies the client-side click time. Don't claim "platform latency" without acknowledging which segment you're measuring.

9. **Tier 2 — Slippage sign convention varies across cuts.** Some analyses use "positive slippage = customer worse off"; others use "positive slippage = customer better off (price improvement)". The `bestexecution_results.Slippage_Percent` and `Slippage_Dollar_Value` columns are self-consistent (verify which convention they use against a known reference trade before trusting cross-deck comparisons). The EQ Presentation cuts are self-consistent within a deck — but if you're comparing two cuts or comparing `bestexecution_results` to a notebook output, verify the sign convention explicitly.

10. **Tier 2 — Fails ≠ rejects ≠ partials.** An "LP reject" in `Hedge.ExecutionLog.OrderState = 5` (727,763 of ~2.4M historical rows = 31%) may have been silently re-routed and filled by a different LP — that's not a customer-facing fail. The EQ deck's fail definition is **customer-impact-defined**, not LP-state-defined. Cross-check via `Hedge.ManualOrderExecutionLog` (only ~397 rows since Feb 2023 — operator interventions + ExposureBalancer auto-corrections) and the customer-impact view in `bestexecution_results.OrderStatus` / `RejectionReason` before claiming a fail rate.

11. **Tier 2 — `Hedge.ExecutionErrorMapping` is empty.** The table designed to classify provider error strings into categories (Technical Failure / Order Validation / Market Reject / etc.) has 0 rows in both current and history. Error categorization happens in application code or downstream notebooks, NOT via a SQL lookup. If you need to bucket `FailReason` / `RejectionReason` strings into categories, ask the dealing team for the application-side classifier — don't try to invent a SQL mapping.

12. **Tier 3 — `Hedge.ExecutionLog` has multiple rows per order (state transitions).** A typical EMS order writes: `OrderState=2` (New) → one or more `OrderState=3` (Partial) → `OrderState=4` (Fill) OR `OrderState=5` (Reject). Distribution in the historical bronze: Partial 44%, Reject 31%, Fill 19%, New 6%. Any "final state per order" query must use `ROW_NUMBER() OVER (PARTITION BY EMSOrderID ORDER BY LogTime DESC)`. Aggregating partial fills (for weighted-average fill rate) uses `SUM(Units * ExecutionRate) / SUM(Units)` filtered on `OrderState = 3`, with a 5-second trailing buffer to avoid race-condition reads (per `Hedge.GetExecutionLogData`).

13. **Tier 3 — `Fact_CurrencyPriceWithSplit.isvalid` filter caveat for NBBO analysis.** For end-of-day P&L you filter `isvalid = 1`, but for NBBO ("was the fill price within the market best at the moment of execution?") you may need intra-day `isvalid = 0` snapshots that capture the market state AT EXECUTION TIME, not at EOD. Also: use raw `Ask` / `Bid` for the NBBO market reference, NOT `AskSpreaded` / `BidSpreaded` — the spreaded versions include eToro's markup and are not the market quote. ~46% of rows are `isvalid = 0`; ~7.5% have NULL `ConvertRateIsBuy_1/0`.

## The five pillars — methodology map

| Pillar | What it measures | Primary anchor | EQ Presentation folder |
|---|---|---|---|
| **NBBO** | Fill price vs market best at moment of execution. | `bestexecution_results` (joins fill rate + reference price) + `rnd_output_dealing_bestexecution_currencyprice` (price snapshot tuned for best-exec) + `Fact_CurrencyPriceWithSplit` (raw `Ask`/`Bid`, ignore spreaded versions) | `(Clone) Execution Quality Presentation/NBBO/` |
| **SLIPPAGE** | Quoted price (client view) vs actual fill price. | `bestexecution_results.Slippage_Percent` + `Slippage_Dollar_Value` + `ClientViewRate` (quoted) + `ExecutionRate` (filled). `bi_output_dealing_bestexecution_report` for BI cuts with Kusto/volatility-bucket enrichment. | `(Clone) Execution Quality Presentation/SLIPPAGE/` (incl. `BEST EXECUTION COMMITTEE/`, `Weekly Dealing/`, `GOLD EVENT 29 JAN 2026/`, `BOD Q4 2025/`) |
| **FAILS** | Orders that didn't execute or didn't settle. | `bestexecution_results.OrderStatus` + `RejectionReason` + `ErrorReason` / `ErrorCode` (customer-impact view), `Hedge.ExecutionLog.OrderState = 5` (LP-side rejects — careful: some are silently re-routed), `Hedge.ManualOrderExecutionLog` (operator rescues), `Dealing_Duco_EODRecon` (settlement-side discrepancies) | `(Clone) Execution Quality Presentation/FAILS/` |
| **LATENCY** | End-to-end click→confirm timing. | `bestexecution_results.Latency_In_HBC_In_Seconds` + `Latency_In_CBH_In_Seconds` + full timing chain (`ClientClickArrivalToBETime` → `OrderSentToDealingTime` → `eToroSendingTimeToLP` → `LPExecutionSendingTime` → `eToroReceiveTimeFromLP` → `SentTimeToClient`). `bi_output_dealing_latency_compensation` for customers paid back. `Hedge.SSRS_Latency_Report` for the production P90/P99 framework. | `(Clone) Execution Quality Presentation/Latency/` (incl. the `Latency Python` notebook) |
| **TCA (cost decomposition)** | Per-execution decomposition into SpreadCost / Slippage / InternalCost / ExternalCost / TotalTransactionCost. | `Hedge.Report_TCA` (Synapse SP that reads `Hedge.ExecutionRequestBreakdownLog` + `Hedge.ExecutionResponseBreakdownLog` joined by HedgeID). Not yet observed as a UC view. | (no dedicated EQ deck folder — produced on demand by Hedge.Report_TCA invocation) |

## Source stack — what each pillar pulls from

### NBBO

- `main.dealing.bestexecution_results` — per-execution: `TOBPrice` (Top-of-Book client rate), `ExecutionRate`, `ExecutionRateSpreaded`, `ClientViewRate`, instrument timing
- `main.dealing.rnd_output_dealing_bestexecution_currencyprice` — dealing-curated market price snapshot scoped to best-exec moments
- `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` — DWH daily price (use raw `Ask`/`Bid` for NBBO, NOT `AskSpreaded`/`BidSpreaded`; ~46% of rows are `isvalid = 0`)
- `main.dealing.bronze_pricelog_history_currencyprice` — tick-level price archive for moment-of-execution lookup

### Slippage

- `main.dealing.bestexecution_results.Slippage_Percent`, `Slippage_Dollar_Value` — per-execution pre-computed
- `main.dealing.bi_output_dealing_bestexecution_report` — BI cut with `Kusto_Rate` / `KustoTime` (client-side timing), `Volatility_Bucket`, `Threshold_BP`, `WithinFirst5Minutes_*` market-open flags. **Beware misattributed comments on `Markup`, `SlippageInDollar`, `History_Price_Rate`, `ForexRate`, `AmountInUnitsDecimal` (Critical Warning #5).**
- `main.dealing.bi_output_dealing_latency_compensation` — companion table: customers compensated for latency-impacted trades; includes `Price_Requested`, `Spread`, `SlippageInDollar`, `Kusto_Rate`, `RequestTimeFromEMS`
- `main.dealing.rnd_output_dealing_bestexecution_dim_position` — dealing-curated Dim_Position variant including `RequestOpenOccurred` / `RequestCloseOccurred` (request times — distinct from `OpenOccurred` / `CloseOccurred` write times)
- `Hedge.Report_TCA` (Synapse SP) — TCA decomposition: `SpreadCost`, `Slippage` (= ExecToRequestDelay), `InternalCost`, `ExternalCost` (= ExecToResponseDelay), `TotalTransactionCost`

### Fails

- `main.dealing.bestexecution_results.OrderStatus`, `RejectionReason`, `ErrorReason`, `ErrorCode` — **customer-impact view** (preferred for fail-rate questions)
- `main.dealing.bronze_etoro_hedge_executionlog` — LP-side `OrderState = 5` (Reject) and `Success = 0`. Distribution in historical bronze: 31% rejects (typical for institutional execution — many silently re-routed). **Today: 100% EMS-path; dedup by `EMSOrderID`.**
- `main.dealing.bronze_etoro_hedge_manualorderexecutionlog` — operator interventions (`RequestTypeID >= 0`, `Sender = HedgeClientN (by <user>)`) + ExposureBalancer auto-corrections (`RequestTypeID = -1`, `Sender = ExposureBalancer`). Only ~397 rows since Feb 2023 — this is an exception log.
- `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` — settlement-side discrepancies (weekends excluded; 11+ downstream LP-specific recon tables: Apex, GS, IB, IG, JPM, SAXO, VISION, BNY VIRTU, CloseOnly)
- `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings` (and per-LP siblings) — custodian-side fails
- `main.dealing.bronze_positionfailreal_history_positionfail_dwh` — position fail history

### Latency

- `main.dealing.bestexecution_results` — pre-computed: `Latency_In_HBC_In_Seconds`, `Latency_In_CBH_In_Seconds` + the full chain: `ClientClickArrivalToBETime`, `OrderSentToDealingTime`, `eToroSendingTimeToLP`, `LPExecutionSendingTime`, `eToroReceiveTimeFromLP`, `eToroTOBExecutionTime`, `SentTimeToClient`, `OccurredOnProvider`
- `main.dealing.bi_output_dealing_latency_compensation` — customers paid back: per-position record with `ClientToDbLatency`, `ClientToExecutionLatency`, `TradingToExecutionLatency`, `OpenMarketTime`, `WithinFirst5Minutes_MarketHours`
- `main.dealing.bi_output_dealing_bestexecution_report.ClientToRoutedLatency` + sibling latency columns — BI cut
- `main.dealing.bronze_etoro_hedge_executionlog` — `SendTime`, `ReceivedTime`, `ExecutionTime` per execution event (LP-segment only)
- **Cross-DB synonyms (not in UC bronze yet)**: `dbo.SynHedgeEMSOrders` → `eToroLogs_Real.Hedge.EMSOrders` (supplies `RequestTime`, `StatusUpdateTime`); `dbo.SyneToroLogsHedgeOrderLog` → `eToroLogs_Real.Hedge.OrderLog` (supplies `SendTime` per ExecutionID). These are the upstream source for `Hedge.SSRS_Latency_Report`.
- `Hedge.SSRS_Latency_Report` (Synapse SP, 24-hour max window) — P90/P99 framework: M1 Request_Process_Time, M2 Provider_Response_Latency, M3 Execution_Response_Process_Time, M4 Total_Latency = M1+M3, M5 Throughput, M6 Fill_Ratio, M7 by-HedgeServer fill ratio
- `Latency Python` notebook at `/Workspace/Shared/(Clone) Execution Quality Presentation/Latency/Latency Python` — production latency methodology

### TCA (Transaction Cost Analysis)

- `Hedge.Report_TCA` (Synapse SP) — primary; per (`HedgeServerID`, `LiquidityAccountName`) aggregation over a date range
- `Hedge.ExecutionRequestBreakdownLog` / `Hedge.ExecutionResponseBreakdownLog` — paired by `HedgeID`, contain `eToroPriceBid`/`Ask`, `ProviderPriceBid`/`Ask`, `ExecutionPriceBid`/`Ask`. Pre-loaded into `#Req` / `#Res` temp tables in the SP.
- Pip precision per instrument comes from `Trade.ProviderToInstrument.Precision`
- USD normalization: for `InstrumentID IN (4,5,6)` (JPY/CHF/CAD base pairs), cost is divided by `eToroPriceBid`; for `InstrumentID IN (17,18,19)` (JPY crosses) multiplied by 100 for pip adjustment

## EQ Presentation deck — folder structure

Verified live as of 2026-05-11 against `/Workspace/Shared/(Clone) Execution Quality Presentation/`:

```
/Workspace/Shared/(Clone) Execution Quality Presentation/
├── NBBO/
│   ├── 2025/                       # full-year retrospective
│   ├── Nov/                        # November 2025
│   ├── Dec/
│   ├── Jan 26/                     # casing: "Jan 26" (with space)
│   └── FEB 26/                     # casing: "FEB 26" (uppercase)
├── SLIPPAGE/
│   ├── 2025/
│   ├── Nov/  /  Dec/
│   ├── JAN 26/  /  FEB 26/
│   ├── BOD Q4 2025/                # Board of Directors Q4 deck
│   ├── BEST EXECUTION COMMITTEE/   # ← committee output (canonical for regulators/exec)
│   ├── GOLD EVENT 29 JAN 2026/     # event-specific cut
│   └── Weekly Dealing/             # operational weekly cut
├── FAILS/
│   ├── 2025/
│   ├── Nov/  /  Dec/
│   ├── JAN 26/  /  FEB 26/
│   └── BOD - Q4 2025/              # note dash variation
└── Latency/
    ├── BOD Q4/
    ├── JAN26/                      # no space variant
    ├── FEB26/
    └── Latency Python              # ← notebook (Python), the methodology
```

### How to find the latest cut

```powershell
databricks workspace list "/Workspace/Shared/(Clone) Execution Quality Presentation/SLIPPAGE" --profile guyman
```

The folder casing/format varies by pillar (NBBO uses "Jan 26" with space + mixed case; SLIPPAGE uses "JAN 26" uppercase; Latency uses "JAN26" no space). Read folder names visually rather than expecting a uniform pattern.

## Dealing analyst code repo

Production dealing notebooks live at `/Workspace/Repos/dealing/BI-Dealing/`:

- `databricks/Dealing_Tasks/` — the production task notebooks (likely producers of `bestexecution_results` / `bi_output_dealing_*` / `rnd_output_dealing_*`)
- `databricks/Broadridge/` — Broadridge integration for stocks recon
- `databricks/Nixar/` — Nixar (crypto LP) integration
- `databricks/Utils/`
- `Production - Daily Beta` — root notebook

For methodology questions ("how is Slippage_Dollar_Value computed?", "what's the definition of Latency_In_HBC_In_Seconds?") the answer lives in `Dealing_Tasks/` notebooks. UC column comments on the `bi_output_*` tables are partially polluted (Critical Warning #5) — prefer the producing notebook over the column comment when in doubt.

Standalone dealing notebooks in `/Workspace/Shared/`:

- `/Workspace/Shared/temp_optimize_slippage` (SQL) — slippage optimization scratch
- `/Workspace/Shared/temp_aapl_hedge_cost` (SQL) — single-instrument hedge cost study
- `/Workspace/Shared/hedge_strategy_247_analysis` (Python) — 24/7 hedge strategy analysis

## Query Patterns

### Pattern 1 — Per-execution slippage and latency from the dealing-curated table (PRIMARY)

```sql
SELECT etr_ymd,
       Regulation,
       AssetTypeName,
       Instrument_Name,
       Buy_OR_Sell,
       Copy_Or_Manual,
       Slippage_Percent,
       Slippage_Dollar_Value,
       Latency_In_HBC_In_Seconds,
       Latency_In_CBH_In_Seconds,
       OrderStatus,
       RejectionReason
FROM main.dealing.bestexecution_results
WHERE etr_ymd BETWEEN '2026-04-01' AND '2026-04-30'
  AND IsOpen = 1                                  -- opens only (use 0 for closes)
  AND OrderStatus IN ('Filled', 'PartiallyFilled')
ORDER BY ABS(Slippage_Dollar_Value) DESC
LIMIT 100;
```

**Use when:** "highest-slippage trades last month", "slippage distribution by asset class", "p99 latency by LP". `bestexecution_results` is partitioned on `etr_ymd` — always filter on it. **Replaces the prior version's incorrect Pattern 3** (which referenced non-existent w_metrics columns).

### Pattern 2 — Slippage cut for the BI / Best Execution Committee with Kusto enrichment

```sql
SELECT Date,
       Regulation,
       InstrumentType,
       Volatility_Bucket,
       Threshold_BP,
       WithinFirst5Minutes_MarketHours,
       PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY SlippageInDollar) AS p50_slippage_usd,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY SlippageInDollar) AS p95_slippage_usd,
       PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY SlippageInDollar) AS p99_slippage_usd,
       AVG(ClientToExecutionLatency) AS avg_client_to_exec_latency,
       COUNT(*) AS executions
FROM main.dealing.bi_output_dealing_bestexecution_report
WHERE Date BETWEEN '2026-04-01' AND '2026-04-30'
GROUP BY Date, Regulation, InstrumentType, Volatility_Bucket,
         Threshold_BP, WithinFirst5Minutes_MarketHours
ORDER BY Date, Regulation;
```

**Use when:** "monthly slippage cut by volatility bucket", "did market-open executions have worse slippage in February?", BEC-style monthly cuts. **Warning:** the column comments on `SlippageInDollar`, `Markup`, `ForexRate`, `History_Price_Rate`, `AmountInUnitsDecimal` are polluted by a wiki-merge bug (Critical Warning #5) — the semantics are correct but UC comments mislead. Confirm column meaning against the dealing producer notebook.

### Pattern 3 — Customers compensated for latency-impacted trades

```sql
SELECT Date,
       Regulation,
       HedgingType,
       COUNT(DISTINCT CID) AS customers_compensated,
       COUNT(DISTINCT PositionID) AS positions_compensated,
       SUM(SlippageInDollar) AS total_compensation_usd,
       AVG(ClientToExecutionLatency) AS avg_latency_ms_on_compensated
FROM main.dealing.bi_output_dealing_latency_compensation
WHERE Date BETWEEN '2026-04-01' AND '2026-04-30'
GROUP BY Date, Regulation, HedgingType
ORDER BY Date, total_compensation_usd DESC;
```

**Use when:** "how much did we pay back to customers for slow execution last month?", "which regulation footprint had the most latency compensation?". This is the audit-trail of "we owned the slow trade" — visible to compliance/regulators.

### Pattern 4 — Fill state per EMS order (LP-side, current path)

```sql
WITH ranked AS (
  SELECT EMSOrderID, OrderID, LiquidityAccountID, InstrumentID,
         OrderState, Success, ExecutionRate, Units, ProviderUnits,
         LogTime, SendTime, ReceivedTime, FailReason,
         ROW_NUMBER() OVER (PARTITION BY EMSOrderID ORDER BY LogTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE etr_ymd >= current_date - INTERVAL 30 DAYS
    AND OrderID = -1                              -- EMS path (= all recent data)
)
SELECT EMSOrderID, LiquidityAccountID, InstrumentID,
       OrderState, Success, ExecutionRate, Units, ProviderUnits,
       LogTime, datediff(MILLISECOND, SendTime, ReceivedTime) AS lp_round_trip_ms,
       FailReason
FROM ranked
WHERE rn = 1
  AND OrderState IN (4, 5, 7)                     -- final states: Fill, Reject, Cancelled
ORDER BY LogTime DESC
LIMIT 100;
```

**Use when:** "LP-side final state of recent orders", "which EMS orders rejected and why?". Note: dedup is by **EMSOrderID**, not OrderID (all current rows have `OrderID = -1`). For weighted-average partial-fill rate, filter `OrderState = 3` and use `SUM(Units * ExecutionRate) / SUM(Units)`.

### Pattern 5 — VWAP from partial fills (for one EMS order)

```sql
SELECT EMSOrderID,
       SUM(Units) AS total_requested_units,
       SUM(ProviderUnits) AS total_executed_units,
       SUM(Units * ExecutionRate) / NULLIF(SUM(Units), 0) AS vwap_rate,
       COUNT(*) AS partial_fill_count
FROM main.dealing.bronze_etoro_hedge_executionlog
WHERE EMSOrderID = '35564138_1'
  AND OrderState = 3                              -- partial fills only
  AND etr_ymd BETWEEN '2026-04-01' AND '2026-05-11'
GROUP BY EMSOrderID;
```

**Use when:** "what was the weighted-average fill rate on this multi-leg order?". Matches the production aggregation in `Hedge.GetExecutionLogData` (which adds a 5-second trailing buffer for race-condition protection).

### Pattern 6 — LP fail rate proxy (with the silent-rerouting caveat)

```sql
WITH final_state AS (
  SELECT EMSOrderID, LiquidityAccountID, OrderState, LogTime,
         ROW_NUMBER() OVER (PARTITION BY EMSOrderID ORDER BY LogTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE etr_ymd >= current_date - INTERVAL 30 DAYS
)
SELECT etr_ymd, LiquidityAccountID,
       SUM(CASE WHEN OrderState = 5 THEN 1 ELSE 0 END) AS lp_rejects,
       SUM(CASE WHEN OrderState = 4 THEN 1 ELSE 0 END) AS lp_fills,
       COUNT(*) AS total_final_states,
       SUM(CASE WHEN OrderState = 5 THEN 1.0 ELSE 0 END) / COUNT(*) AS lp_reject_rate
FROM final_state f
JOIN main.dealing.bronze_etoro_hedge_executionlog e
  ON f.EMSOrderID = e.EMSOrderID AND f.LogTime = e.LogTime
WHERE f.rn = 1
GROUP BY etr_ymd, LiquidityAccountID
ORDER BY etr_ymd DESC, lp_reject_rate DESC;
```

**Use when:** "LP reject trend", "which LPs are rejecting most this month?". **Warning:** LP rejects are NOT customer-facing fails — many rejected orders are silently re-routed to another LP and filled. For customer-facing fail rate, use `bestexecution_results.OrderStatus` (Critical Warning #10).

### Pattern 7 — Discovery of the latest cut for a pillar

```powershell
databricks workspace list "/Workspace/Shared/(Clone) Execution Quality Presentation/SLIPPAGE" --profile guyman | Sort-Object Path
```

```sql
-- Not a SQL question; the answer is the workspace listing.
SELECT 'See workspace listing under /Workspace/Shared/(Clone) Execution Quality Presentation/' AS hint;
```

**Use when:** "where's the latest slippage cut?" — route to the workspace listing or the dealing repo.

---

## TCA (Transaction Cost Analysis) — canonical methodology

eToro's canonical hedge-cost decomposition lives in `Hedge.Report_TCA` (Synapse SP) and breaks every execution into five (pips, cost) metric pairs. Each metric pair compares two prices at two points in the request→fill lifecycle:

| Metric | Component | Formula direction | Business meaning |
|---|---|---|---|
| **M1: ExecToRequestDelay** | **Slippage** | ProviderPrice@request → ExecutionPrice@response | Did the fill price differ from the LP-quoted price at request time? Adverse = market moved against eToro during fill delay. |
| **M2: ExecToResponseDelay** | **ExternalCost** | ProviderPrice@response → ExecutionPrice@response | Did the LP fill at the price they quoted at response? Pure LP execution quality, isolates from network delay. |
| **M3: eToroToRequest** | **InternalCost** (component) | eToroPrice → ProviderPrice@request | eToro's spread over the provider at request — the customer-facing markup. |
| **M4: eToroToExecution** | **TotalTransactionCost** | eToroPrice@request → ExecutionPrice@response | End-to-end cost: what customers see vs what eToro pays the LP. = SpreadCost + Slippage + InternalCost (algebraically). |
| **M5: MidToMid** | **(Spread surrogate)** | eToroBid → ceiling(midProvider * 10^Precision) / 10^Precision | eToro's mid-market markup. Uses ceiling rounding on provider mid. |

Plus: **SpreadCost** is computed directly from `Trade.Spread.SpreadGroupID = 0` (the default spread group), multiplied by units. **InternalCost** in the final SELECT is computed as `TotalTransactionCost - Slippage - SpreadCost` (residual).

Key exclusions baked into `Hedge.Report_TCA`:
- `LiquidityAccountID NOT IN (22, 23)` — excludes internal/test LP accounts
- `LiquidityAccountName NOT IN ('Currenex AUSRetailFX3 Execution', 'Currenex AUSRetailFX1 Execution')` — excludes Australia retail FX
- `IsManual <> 1` — excludes dealer-desk manual executions
- `Req.Occurred >= '20120417'` — historical cutoff
- `Res.AmountInUnits IS NOT NULL` — excludes failed executions

Window expansion: `@Start` / `@End` are widened by ±1-2 days for the breakdown-log joins to handle clock-skew at boundaries, then tightened back to `RequestTime BETWEEN @Start AND @End` in the final filter.

To invoke for a date range (Synapse-side):

```sql
EXEC [Hedge].[Report_TCA] @Start = '2026-03-01', @End = '2026-03-07';
-- Returns one row per (HedgeServerID, LiquidityAccountName):
--   SpreadCost | InternalCost | Slippage | TotalTransactionCost | ExternalCost
```

As of 2026-05-11 there is no published UC view materializing TCA output. For UC-side cost analysis, build from `bestexecution_results` + `Hedge.ExecutionRequestBreakdownLog` / `ResponseBreakdownLog` (when available in bronze) or run `Hedge.Report_TCA` in Synapse and ship the output.

## Latency methodology — the five SSRS metrics

`Hedge.SSRS_Latency_Report` (Synapse SP, 24-hour max window) is the production latency framework. It runs two parallel flows (`FullyAsync_*` for HBC/direct EMS, `HedgeServer_*` via the deeper HBC→HBCOrderLog→ExecutionLog chain) and produces five latency/throughput metrics per `LiquidityAccountID`:

| Metric | Window | Source |
|---|---|---|
| **M1: Request_Process_Time** | `RequestTime` → `SendTime` | EMS.RequestTime → OrderLog.SendTime |
| **M2: Provider_Response_Latency** | `SendTime` → `ReceivedTime` | Round-trip to LP |
| **M3: Execution_Response_Process_Time** | `ReceivedTime` → `StatusUpdateTime` | Internal response handling |
| **M4: Total_Latency** | M1 + M3 | Internal latency excluding LP market time |
| **M5: Throughput** | Executions/sec | Per LiquidityAccount |
| **M6: Fill Ratio** | Filled / Routed | Per LiquidityAccount |
| **M7: Overall Fill Ratio** | Filled / (Filled + Rejected) | By HedgeServerID × OperationalMode |

Reports max / avg / P90 / P99 per metric. The 24-hour validation (`DATEDIFF(HOUR, @Start, @End) > 24 → RETURN`) prevents full-history scans.

The two cross-DB synonyms (`SynHedgeEMSOrders` → `eToroLogs_Real.Hedge.EMSOrders` for RequestTime/StatusUpdateTime, `SyneToroLogsHedgeOrderLog` → `eToroLogs_Real.Hedge.OrderLog` for SendTime) carry the timing data that is NOT in the UC bronze tables — important if you're trying to replicate the methodology in UC without Synapse.

## Cross-references

- Single-order execution forensics → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD LP recon (settlement-side fails) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Pricing inputs (NBBO reference) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Position lifecycle (Dim_Position gotchas, partial-close grain) → [`position-state-and-grain.md`](position-state-and-grain.md)
- LP contracts (which LP for which instrument) → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Production analysis pack → `/Workspace/Shared/(Clone) Execution Quality Presentation/`
- Production dealing code → `/Workspace/Repos/dealing/BI-Dealing/databricks/Dealing_Tasks/`

## Provenance

Rebuilt 2026-05-11 under speckit Phase 2.5 (classify-then-reach). Hybrid anchor set: 2 Synapse-first anchors (`fact_currencypricewithsplit`, `dealing_duco_eodrecon`) + 9 Lake-first anchors (the dealing `bestexecution_*` family + bronze hedge logs). Replaces v1 which routed slippage queries to `fact_customeraction_w_metrics` (which has no execution-quality columns).

## Sources Consulted

Per-anchor reach record. `Class`: S = Synapse-first, L = Lake-first, H = Hybrid.

| # | Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|---|
| 1 | main.dealing.bestexecution_results | L | 1a | UC `information_schema.columns` (live, 82 columns) | THE per-execution master table: TOBPrice, ExecutionRate, ClientViewRate, Slippage_Percent, Slippage_Dollar_Value, Latency_In_HBC/CBH_In_Seconds, full timing chain, OrderStatus, RejectionReason. Replaces the wrong w_metrics anchor in v1. |
| 2 | main.dealing.bi_output_dealing_bestexecution_report | L | 1a | UC `information_schema.columns` (live, 54 columns) | BI cut with Kusto_Rate, KustoTime, ClientToDbLatency, Volatility_Bucket, Threshold_BP, WithinFirst5Minutes_*. **Comment pollution flagged** (Critical Warning #5). |
| 3 | main.dealing.bi_output_dealing_latency_compensation | L | 1a | UC `information_schema.columns` (live, 34 columns) | Customers paid back for latency-impacted trades. Kusto_Rate, RequestTimeFromEMS, ClientToExecutionLatency. |
| 4 | main.dealing.rnd_output_dealing_bestexecution_dim_position | L | 1a | UC `information_schema.columns` (live, 30+ columns) | Dealing-curated Dim_Position with RequestOpenOccurred / RequestCloseOccurred + InitExecutionID linkage. |
| 5 | main.dealing.rnd_output_dealing_bestexecution_currencyprice | L | 1a | UC table listing | Dealing-curated price snapshot scoped to best-exec moments. |
| 6 | main.dealing.rnd_output_dealing_bestexecution_ems_investigation_tool | L | 1a | UC `information_schema.columns` (live, 21 columns) | EMS investigation tool data with event hub payload extraction. |
| 7 | main.dealing.bronze_etoro_hedge_executionlog | L+S | 1a | UC + `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ExecutionLog.md` (300+ lines) | OLTP source wiki is authoritative. UC comments are cleanly wiki-derived (Tier 1 markers present). Captured: dual EMS/legacy paths, OrderState lookup (8 states), 5-second trailing buffer for partial-fill aggregation, RateIDAtSent semantics. |
| 8 | UC live query | L+S | 4 | UC `SELECT COUNT, MIN, MAX, SUM` on ExecutionLog last 7 days | Verified: 1.2M rows, ALL OrderID=-1 (100% EMS path), 522K distinct EMSOrderID. Confirms Critical Warning #2. |
| 9 | main.dealing.bronze_etoro_hedge_hbcexecutionlog | L+S | 1a + 4 | UC + `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.HBCExecutionLog.md` + live query | Wiki: HBC = order-based path, lot rounding (RequestAmountInLots vs ExecutionAmountInLots), FailReason taxonomy. Live: 26.8M rows but **last data 2024-02-29** → archive-only (Critical Warning #3). |
| 10 | main.dealing.bronze_etoro_hedge_manualorderexecutionlog | L+S | 1a | `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ManualOrderExecutionLog.md` | Two populations: dealing-desk (RequestTypeID ≥ 0, "HedgeClientN by user") + ExposureBalancer (RequestTypeID = -1). ~397 rows since Feb 2023 — exception log. |
| 11 | Hedge.Report_TCA | S | 2 | `knowledge/ProdSchemas/.../Hedge/Stored Procedures/Hedge.Report_TCA.md` (250 lines) | Canonical TCA: SpreadCost + Slippage + InternalCost + ExternalCost = TotalTransactionCost. Excludes LiquidityAccountID IN (22,23), AUSRetailFX, manual. Pip precision from Trade.ProviderToInstrument. |
| 12 | Hedge.SSRS_Latency_Report | S | 2 | `knowledge/ProdSchemas/.../Hedge/Stored Procedures/Hedge.SSRS_Latency_Report.md` (245 lines) | 5-metric latency framework. Cross-DB synonyms `SynHedgeEMSOrders` + `SyneToroLogsHedgeOrderLog` → eToroLogs_Real DB. 24h max range. COLLATE Latin1_General_BIN join. |
| 13 | Hedge.ExecutionErrorMapping | S | 2 | `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ExecutionErrorMapping.md` | Table is EMPTY (0 rows). Designed for error-category classification but never populated → Critical Warning #11. |
| 14 | main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit | S | 1a | `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CurrencyPriceWithSplit.md` (280 lines) + `.review-needed.md` | isvalid=1 ~54% (EOD), ~46% intra-day snapshots. AskSpreaded/BidSpreaded include eToro markup — use raw Ask/Bid for NBBO market reference. 3 ProviderIDs (semantics unverified). |
| 15 | main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon | S | 1a | `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Duco_EODRecon.md` + `.review-needed.md` | Weekends excluded. HedgingPercent = eToro_Units / ClientUnits. 11+ downstream LP-specific recon tables. FULL OUTER JOIN artifacts. |
| 16 | EQ Presentation deck | (n/a) | 1a | `databricks workspace list` live verification | NBBO (5 subfolders) + SLIPPAGE (9 incl. BEST EXECUTION COMMITTEE + Weekly Dealing + GOLD EVENT 29 JAN 2026) + FAILS (5) + Latency (3 + `Latency Python` notebook). Casing varies per pillar. |
| 17 | Dealing analyst repo `/Workspace/Repos/dealing/BI-Dealing/` | L | 5 | `databricks workspace list` | `databricks/Dealing_Tasks/`, `databricks/Broadridge/`, `databricks/Nixar/`, `databricks/Utils/`, `Production - Daily Beta` notebook. Source of methodology truth for the dealing-curated UC tables. |
| 18 | Dealing scratch notebooks | L | 5 | `databricks workspace get-status` | `/Workspace/Shared/temp_optimize_slippage` (SQL), `/Workspace/Shared/temp_aapl_hedge_cost` (SQL), `/Workspace/Shared/hedge_strategy_247_analysis` (Python). |
| 19 | w_metrics column-listing query | (proof) | 4 | UC `information_schema.columns` filtered for rate/price/spread/slippage/nbbo/lp/fill/quote columns | Returned only ActionTypeID, PositionID, OriginalPositionID, OpenMarkupByUnits, OpenDateID, CloseDateID — confirms Critical Warning #1 (w_metrics has no execution-quality columns). |
