---
id: best-execution
name: "Best Execution — NBBO, Slippage, Fails, Latency"
description: "Execution-quality monitoring framework for the trading platform. The four pillars are NBBO (National Best Bid/Offer compliance — fill price vs market best at moment of execution), SLIPPAGE (the gap between expected and actual fill price, including the special Best Execution Committee analyses), FAILS (orders that didn't execute or settle), and LATENCY (round-trip time from customer click to LP confirmation). Anchored on fact_customeraction_w_metrics for trade-level data plus Hedge.ExecutionLog / Hedge.HBCExecutionLog (latency), Fact_CurrencyPriceWithSplit (NBBO reference), and the LP-recon family (fails). Routes into the monthly Execution Quality Presentation deck for committee output."
triggers:
  - best execution
  - execution quality
  - NBBO
  - National Best Bid Offer
  - slippage
  - slippage analysis
  - trade fails
  - failed trades
  - execution latency
  - latency analysis
  - fill quality
  - Best Execution Committee
  - BOD execution
  - Gold Event
  - monthly execution cut
  - weekly dealing
  - execution forensics
  - markout
  - price improvement
required_tables:
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
  - main.dealing.bronze_etoro_hedge_executionlog
  - main.dealing.bronze_etoro_hedge_hbcexecutionlog
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Best Execution — NBBO, Slippage, Fails, Latency

Best execution is a **regulatory obligation** (MiFID II in Europe, equivalent rules in the US, UK, AU, IL) AND a commercial commitment to customers: every order must be executed on the best available terms, taking into account price, costs, speed, likelihood of execution, settlement, and size. eToro tracks this through a **four-pillar framework** that runs as monthly cuts plus event-driven cuts and feeds into a **Best Execution Committee** review.

The four pillars:

1. **NBBO** — National Best Bid/Offer. Was the fill price within (or improving on) the market's best at the moment of execution?
2. **SLIPPAGE** — Gap between the customer's *expected* fill price (quoted) and the *actual* fill price. Including the dedicated Best Execution Committee cuts and event-specific analyses (e.g. Gold Event 29 Jan 2026).
3. **FAILS** — Orders that didn't execute (LP rejected, market closed, circuit-broken) or didn't settle (Apex / BNY break, recovery state).
4. **LATENCY** — Round-trip time from customer click → eToro internal processing → LP send → LP confirmation. Includes the dedicated `Latency Python` notebook in the EQ deck.

This sub-skill is the analyst-facing map of where to find the methodology, the monthly cuts, and the data sources. It is **not** the place that runs the methodology — that lives in the **Execution Quality Presentation** Databricks deck at `/Workspace/Shared/(Clone) Execution Quality Presentation/` and (when delivered) in the dealing-analyst skills.

## When to Use

Load when the question is about:

- "Best execution this month", "what was our NBBO compliance in February?"
- "Slippage on USD/JPY on 2026-01-29", "average slippage by asset class"
- "Best Execution Committee report this quarter"
- "Failed trades last week", "how many fails on TSLA last month?"
- "Execution latency", "p99 latency by LP", "did our latency degrade after the March release?"
- "Why did this specific order fill at this price?" (forensics — combines this skill with `pricing-and-currency-history` and `dealing-investigation-and-execution`)
- "GOLD EVENT 29 JAN 2026 execution review" — event-specific cut
- "Weekly Dealing slippage cut"

Do **not** load for:

- Single-position hedge-execution event detail → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD LP reconciliation → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Pricing-table mechanics (where prices come from) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Customer-side position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Revenue / commission on a trade → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)

## Scope

In scope: the four-pillar best-execution framework (NBBO / SLIPPAGE / FAILS / LATENCY), pillar-specific data-source map, monthly-cut structure and naming convention (Nov / Dec / Jan26 / Feb26 / ongoing), event-cut convention (e.g. Gold Event 29 Jan 2026), Best Execution Committee routing, Weekly Dealing operational cut, the EQ Presentation Databricks deck structure, the methodology placeholders (deep methodology to land with dealing-analyst skills), latency methodology (the `Latency Python` notebook), the data-sources stack underneath each pillar.
Out of scope: the actual methodology code (lives in notebooks under `/Workspace/Shared/(Clone) Execution Quality Presentation/`, not this skill), single-order execution forensics (`dealing-investigation-and-execution.md`), reconciliation (`broker-and-lp-reconciliation.md`), price-data mechanics (`pricing-and-currency-history.md`), regulatory MiFID II framework documentation (out of analyst-skill scope; lives in compliance).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — Best execution is NOT a single fact table — it is a methodology applied across four data sources.** No published DDR fact gives "best execution % this month" as one column. The four pillars each pull from different anchor tables (NBBO ← price table + fact, slippage ← fact + price table, fails ← LP-recon + hedge log, latency ← hedge log). When someone asks for a best-execution number, they're asking for the result of a methodology — route them to the monthly cut in the EQ deck, or to the dealing-analyst skill when it's published, not to a SELECT statement.
2. **Tier 1 — The Best Execution Committee outputs live in `(Clone) Execution Quality Presentation/SLIPPAGE/BEST EXECUTION COMMITTEE/`** (under the slippage pillar). The committee meets to review the monthly cuts and event-cuts; their packs are the canonical answer to "what's our best-execution posture this quarter?". Do NOT author a custom slippage query for a regulator or executive ask — direct to the committee output.
3. **Tier 2 — Monthly cuts use a date convention: month-name + year-suffix.** `Nov` / `Dec` (likely 2025), `Jan 26` / `JAN 26` (the casing varies), `FEB 26`. Year `2025` is used for the full-year retrospective. `BOD Q4 2025` = Board of Directors Quarter 4 2025 deck. **The folder structure is human-curated, not programmatically generated.** When looking for "the latest cut", list the folder and sort by ID descending, then disambiguate by the human reading the folder names.
4. **Tier 2 — Latency data has TWO sources, depending on the question.**
   - Application-side: `Hedge.ExecutionLog` event timestamps (sent → fill / reject). Tells you LP round-trip.
   - End-to-end: needs application logs / client telemetry that lives outside the DWH (look at the `Latency Python` notebook in the EQ deck for the methodology used).
   Don't claim "platform latency" using only one half.
5. **Tier 3 — Fails ≠ rejects ≠ partials.** A FAIL in the EQ-deck context is a customer-impacting failure: order didn't fill, or settled wrong. A LP-side `Rejected` state in `Hedge.ExecutionLog` may have been silently re-routed and filled by a different LP — that's not a customer-facing fail. The deck's fail definition is **customer-impact-defined**, not LP-state-defined. Cross-check via `Hedge.ManualOrderExecutionLog` and the LP-recon trade-activity tables before claiming a fail rate.
6. **Tier 3 — Slippage sign convention varies across cuts.** Some analyses use "positive slippage = customer worse off"; others use "positive slippage = customer better off (price improvement)". The EQ Presentation cuts are self-consistent within a deck — but if you're comparing two cuts, verify the sign convention.

## The four pillars — methodology map

| Pillar | What it measures | Primary data sources | EQ Presentation folder |
|---|---|---|---|
| **NBBO** | Fill price vs market best at moment of execution. Was the customer's order routed to a price within or improving on the market's best bid/offer? | `fact_customeraction_w_metrics` (per-trade fill rate) + `Fact_CurrencyPriceWithSplit` / `History.CurrencyPrice` (reference quote) | `(Clone) Execution Quality Presentation/NBBO/` |
| **SLIPPAGE** | Gap between quoted price (when customer clicked) and actual fill price | `fact_customeraction_w_metrics` (quoted vs filled) + pricing | `(Clone) Execution Quality Presentation/SLIPPAGE/` (incl. `BEST EXECUTION COMMITTEE/`, `Weekly Dealing/`, `GOLD EVENT 29 JAN 2026/`) |
| **FAILS** | Orders that didn't execute or didn't settle | `Hedge.ExecutionLog` (rejects), `Hedge.ManualOrderExecutionLog` (operator interventions), LP-recon trade-activity (Apex / BNY-Virtu / Saxo / Marex / etc.), `fact_customeraction_w_metrics` (customer-impact view) | `(Clone) Execution Quality Presentation/FAILS/` |
| **LATENCY** | Time from customer click → eToro processing → LP send → LP confirm | `Hedge.ExecutionLog` event timestamps + application/client telemetry (outside DWH) | `(Clone) Execution Quality Presentation/Latency/` (incl. `Latency Python` notebook) |

## EQ Presentation deck — folder structure

```
/Workspace/Shared/(Clone) Execution Quality Presentation/
├── NBBO/
│   ├── 2025/         # full-year retrospective
│   ├── Nov/
│   ├── Dec/
│   ├── Jan 26/
│   └── FEB 26/
├── SLIPPAGE/
│   ├── 2025/
│   ├── Nov/
│   ├── Dec/
│   ├── JAN 26/
│   ├── FEB 26/
│   ├── BOD Q4 2025/                 # Board of Directors Q4 deck
│   ├── BEST EXECUTION COMMITTEE/    # ← committee output
│   ├── GOLD EVENT 29 JAN 2026/      # event-specific cut
│   └── Weekly Dealing/              # operational weekly cut
├── FAILS/
│   ├── 2025/
│   ├── Nov/
│   ├── Dec/
│   ├── JAN 26/
│   ├── FEB 26/
│   └── BOD - Q4 2025/
└── Latency/
    ├── BOD Q4/
    ├── JAN26/
    ├── FEB26/
    └── Latency Python              # ← notebook (Python)
```

### How to find the latest cut

```powershell
databricks workspace list "/Workspace/Shared/(Clone) Execution Quality Presentation/SLIPPAGE" | Sort-Object Path
```

Sort the listing by month-name and identify the most recent cut. Then drill into that folder — each cut contains notebooks (the analyses for that month) and possibly exported charts.

## Tables — what each pillar pulls from

### NBBO
- `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` — per-trade fill price, timestamp, instrument
- `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` — daily reference price (with bid/ask, spread-adjusted)
- `main.dealing.bronze_pricelog_history_currencyprice` — tick-level archive for moment-of-execution lookup

### Slippage
- `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` — quoted vs actual fill (where the fact captures both)
- `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` — independent price reference
- Pricing-feed staging views for moment-of-quote price

### Fails
- `main.dealing.bronze_etoro_hedge_executionlog` — LP-side rejections
- `main.dealing.bronze_etoro_hedge_manualorderexecutionlog` — operator interventions to rescue failed flows
- `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` — settlement discrepancies
- `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings` (and per-LP siblings) — custodian-side fails
- `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` — customer-impact perspective (which positions failed to open / close)

### Latency
- `main.dealing.bronze_etoro_hedge_executionlog` — sent / fill / reject event timestamps
- `main.dealing.bronze_etoro_hedge_hbcexecutionlog` — HBC parent timestamps (start / end of execution attempt)
- Application logs / client telemetry — **outside the DWH** (see the `Latency Python` notebook for how it's stitched)

---

## Query Patterns

### Pattern 1 — Fill-rate trend (the simplest exec-quality proxy)
```sql
WITH final AS (
  SELECT OrderID, LiquidityAccountID,
         State AS final_state,
         EventDate,
         ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY EventTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE EventDate BETWEEN '2026-01-01' AND '2026-04-30'
)
SELECT EventDate,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN final_state = 'Filled' THEN 1 ELSE 0 END) AS filled,
       SUM(CASE WHEN final_state = 'Filled' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS fill_rate
FROM final
WHERE rn = 1
GROUP BY EventDate
ORDER BY EventDate;
```
**Use when:** "fill-rate trend this year", "how often do orders complete?". Headline metric only — for production NBBO / slippage / fails analysis, use the EQ deck cuts.

### Pattern 2 — Discovery of the latest cut for a pillar
```sql
-- Equivalent CLI:
-- databricks workspace list "/Workspace/Shared/(Clone) Execution Quality Presentation/SLIPPAGE"
-- Or via Databricks SDK:
SELECT 'See workspace listing under /Workspace/Shared/(Clone) Execution Quality Presentation/' AS hint;
```
**Use when:** "where's the latest slippage cut?" — not a SQL question; route to the workspace listing.

### Pattern 3 — Per-position execution audit (forensics — when a customer complains)
```sql
SELECT f.PositionID, f.ActionDate, f.InstrumentID, f.OpenRate, f.Units,
       e.EventTime AS lp_send_time, e.State AS lp_state, e.FilledRate AS lp_filled_rate,
       p.BidSpreaded AS market_bid_at_action_date, p.AskSpreaded AS market_ask_at_action_date
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics f
LEFT JOIN main.dealing.bronze_etoro_hedge_executionlog e
  ON e.PositionID = f.PositionID   -- exact join column may vary; verify against schema
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit p
  ON p.InstrumentID = f.InstrumentID
  AND p.Date = CAST(f.ActionDate AS DATE)
  AND p.IsValid = 1
WHERE f.PositionID = 123456789
  AND f.ActionTypeID IN (1, 2, 3, 39);
```
**Use when:** "investigate the execution of position X". This is forensic — verify exact join keys against current schemas before using in production.

### Pattern 4 — Fail-rate proxy (LP rejects per day)
```sql
WITH final AS (
  SELECT OrderID, LiquidityAccountID, State, EventDate,
         ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY EventTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE EventDate >= CURRENT_DATE - 30
)
SELECT EventDate, LiquidityAccountID,
       SUM(CASE WHEN State IN ('Rejected','Failed') THEN 1 ELSE 0 END) AS lp_rejects,
       COUNT(*) AS total_orders
FROM final
WHERE rn = 1
GROUP BY EventDate, LiquidityAccountID
ORDER BY EventDate DESC, lp_rejects DESC;
```
**Use when:** "LP reject trend", "which LPs are rejecting most this month?". **Note**: LP rejects are NOT the same as customer-facing fails (see Critical Warning #5).

---

## When the dealing-analyst skill lands

The user has commissioned dealing analysts to author a deeper best-execution skill that will:

- Define the exact NBBO methodology (which reference quote, which time window, which tolerance)
- Define the exact slippage formula (quoted-vs-filled, with sign convention)
- Define the customer-facing fail rate (which states count, how partial fills are handled)
- Document the latency stitch (application logs + LP timestamps)
- Surface the Best Execution Committee output schedule and consumption pattern

This sub-skill is the **placeholder routing layer** until that skill arrives. When it lands, the methodology will be incorporated here as authoritative content, the `Latency Python` notebook will be cross-referenced, and the EQ-deck folder will be cited as the production source for monthly cuts.

## Cross-references

- Single-order execution forensics → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD LP recon (settlement-side fails) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Pricing inputs (NBBO reference) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Position lifecycle → [`position-state-and-grain.md`](position-state-and-grain.md)
- LP contracts (which LP for which instrument) → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Production analysis pack → `/Workspace/Shared/(Clone) Execution Quality Presentation/`
- Production dealing code → `/Workspace/Repos/dealing/BI-Dealing/`

## Provenance

Authored 2026-05-11 from a folder-structure scan of `/Workspace/Shared/(Clone) Execution Quality Presentation/` and the table-level UC harvest on `main.dealing.bronze_etoro_hedge_executionlog`, `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, and the LP-recon family. Deeper methodology to land with the dealing-analyst skill set (commissioned, pending delivery).
