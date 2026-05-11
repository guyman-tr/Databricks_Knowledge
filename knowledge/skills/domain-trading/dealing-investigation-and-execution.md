---
id: dealing-investigation-and-execution
name: "Dealing Investigation & Hedge-Execution Events"
description: "Per-order hedge-execution audit trail for the dealing desk. Anchored on Hedge.ExecutionLog (append-only state-transition log: sent, partial fill, fill, reject, cancel from every liquidity provider) and Hedge.HBCExecutionLog / HBCOrderLog (the Hedge-By-Customer two-level execution stack), plus Hedge.ManualOrderExecutionLog (dealing-operator interventions and ExposureBalancer auto-corrections), Hedge.Netting (live aggregate position), and BI_DB_ABook_Exposure_NOPHedged (operational ABook hedging exposure)."
triggers:
  - hedge execution
  - hedge order
  - ExecutionLog
  - Hedge.ExecutionLog
  - HBCExecutionLog
  - HBCOrderLog
  - Hedge By Customer
  - HBC
  - manual order
  - ManualOrderExecutionLog
  - ExposureBalancer
  - hedge netting
  - Hedge.Netting
  - ABook
  - ABook exposure
  - NOP hedged
  - fill rate
  - fill latency
  - rejection rate
  - hedge failure
  - hedge server change
  - position reroute
  - operational risk hedge
  - dealing investigation
required_tables:
  - main.dealing.bronze_etoro_hedge_executionlog
  - main.dealing.bronze_etoro_hedge_hbcexecutionlog
  - main.dealing.bronze_etoro_hedge_hbcorderlog
  - main.dealing.bronze_etoro_hedge_manualorderexecutionlog
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Dealing Investigation & Hedge-Execution Events

When a customer opens a trade, eToro doesn't just record the customer position — it routes a corresponding **hedge order** to a liquidity provider (LP) to neutralize the firm's net market exposure. That hedge order can succeed, partially fill, get rejected, time out, or trigger a manual intervention by the dealing desk. Every state transition is logged. This sub-skill is the analyst-facing map of those hedge-execution logs.

The execution stack has two routing modes:

- **Automated** — `Hedge.ExecutionLog` for the standard flow (per-LP FIX order send/fill/reject/cancel), with `Hedge.HBCExecutionLog` + `Hedge.HBCOrderLog` for the "Hedge By Customer" route (one parent execution attempt → many child FIX orders).
- **Manual** — `Hedge.ManualOrderExecutionLog` for dealing-desk operator interventions and ExposureBalancer auto-corrections.

State is held in `Hedge.Netting` (live aggregate per-account-per-instrument) and surfaced operationally in `BI_DB_ABook_Exposure_NOPHedged` for monitoring.

## When to Use

Load when the question is about:

- "Why did this hedge fail?", "ExecutionLog for hedge X"
- "Fill rate this week", "rejection rate by LP", "execution latency by provider"
- "HBC execution detail", "Hedge By Customer trail for position Y"
- "Manual hedge interventions today", "operator order audit"
- "ExposureBalancer corrections last 24h"
- "Current hedge netting position on instrument Z"
- "ABook hedging NOP exposure right now"
- "Hedge server reroutes this week", "which positions moved to a new hedge server?"
- "Operational risk events on hedges"

Do **not** load for:

- EOD broker / LP reconciliation (against custodian files) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- LP contract terms / fees → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Customer-side position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Pricing inputs to execution → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Execution-quality monthly reports (NBBO / slippage / fails / latency at portfolio level) → [`best-execution.md`](best-execution.md)

## Scope

In scope: `Hedge.ExecutionLog` (per-order append-only state transitions, high-volume), `Hedge.HBCExecutionLog` (HBC parent — requested vs executed lots, eToro vs LP rate, timing, success/failure), `Hedge.HBCOrderLog` (HBC child — individual FIX orders within an HBC attempt, GUID order identity, state, lots, rate), `Hedge.ManualOrderExecutionLog` (manual operator orders + ExposureBalancer auto-corrections), `Hedge.Netting` (live aggregate per `LiquidityAccount × InstrumentID × ValueDate`), `BI_DB_ABook_Exposure_NOPHedged` (operational ABook hedging exposure snapshot — per-instrument, per-hedge-server, per-liquidity-account), `Trade.PositionsHedgeServerChangeLog` + `Trade.PositionsHedgeServerChangeSummaryLog` (hedge-server reroute audit), `risk.risk_output_rm_tables_operational_risk_update_hedge_v1` (operational-risk events), dictionary tables for state / fail-reason / severity / order-state / event-type / strategy-mode / breakdown-type.
Out of scope: EOD recon against LP custodian files (`broker-and-lp-reconciliation.md`), LP contract / fee terms (`lp-contracts-and-cogs.md`), customer-side position state (`position-state-and-grain.md`), pricing data (`pricing-and-currency-history.md`), portfolio-level execution-quality reports (`best-execution.md`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Hedge.ExecutionLog` is APPEND-ONLY with one row per STATE TRANSITION.** A single hedge order produces multiple rows: one for "sent", one for "partial fill" (possibly several), one for "fill" or "reject" or "cancel". To get the final state of an order, take the most recent row by timestamp for that order's identity columns. To compute fill rate, count distinct order-identity tuples with state = `Filled` over total distinct sent.
2. **Tier 1 — HBC is a two-table parent/child stack.** `Hedge.HBCExecutionLog` is the **parent** (one row per HBC execution attempt — requested-vs-executed lots, rate, timing, outcome). `Hedge.HBCOrderLog` is the **child** (one row per FIX order placed *within* that HBC attempt — possibly several). Join via `HedgeID` (HBCOrderLog's `HedgeID` is the cross-reference to ExecutionLog's parent id; child rows are written **atomically** with the parent by `Hedge.LogHBCExecution`). Treating HBCOrderLog as the only source loses the parent's "requested vs executed" delta; treating HBCExecutionLog as the only source loses the FIX-order detail.
3. **Tier 2 — `Hedge.ManualOrderExecutionLog` mixes humans and machines.** Both dealing-desk operators manually intervening AND the automated `ExposureBalancer` service correcting residual exposure write here. Distinguish via the order-author / source columns before attributing actions to a human.
4. **Tier 2 — `Hedge.Netting` is the LIVE state, not history.** Overwrite-strategy ingestion (60-min). It tells you the current net hedge per (`LiquidityAccount × InstrumentID × ValueDate`) and the running hedge-book unrealized PnL. Use the History tables (`History.HedgeServer`, `History.HedgeServerInstrumentConfiguration`, `History.LiquidityProviderContracts`) for point-in-time reconstruction of the configuration state.
5. **Tier 3 — `BI_DB_ABook_Exposure_NOPHedged` may be stale.** It's the active operational ABook-exposure snapshot fed by Generic Pipeline #471 (hourly Override), but the comment notes the table was *"last updated 2024-02-15 despite active pipeline"*. Always check the most recent `_etl_load_date` (or equivalent) before relying on it for a current-state answer. The dormant sibling tables (`BI_DB_ABook_Exposure`, `BI_DB_ABook_Exposure_History`) are NOT to be used.
6. **Tier 3 — Several Hedge.* tables are EMPTY (designed but not yet activated).** `Hedge.ProviderInstrumentConfiguration` and `Hedge.HedgeServerInstrumentConfiguration` are empty per the source comment. Filtering against them returns zero rows. Don't treat the empty result as "no overrides configured" — treat it as "feature not yet wired".

## Tables — the execution audit stack

### Standard execution

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_executionlog` | Append, 60-min | **Primary** per-order audit log — every state transition at every LP. High-volume. |

### HBC (Hedge By Customer)

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_hbcexecutionlog` | Append, 1440-min | HBC parent: requested vs executed lots, eToro rate vs LP rate, timing, outcome. One row per HBC attempt. |
| `main.dealing.bronze_etoro_hedge_hbcorderlog` | Append, 1440-min | HBC child: individual FIX orders inside an HBC attempt. GUID identity, state, lots, rate. Join to parent via `HedgeID`. |

### Manual + automated correction

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_manualorderexecutionlog` | Override, 60-min | Every hedge order submitted manually by a dealing-desk operator OR auto-submitted by `ExposureBalancer`. |

### Live state + monitoring

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_netting` | Override, 60-min | Live aggregate net hedge per `LiquidityAccount × InstrumentID × ValueDate`. Drives hedge-book unrealized PnL. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged` | Hourly Override (#471) | Operational ABook hedging NOP exposure snapshot — per-instrument, per-hedge-server, per-liquidity-account. **Check `_etl_load_date` before trusting.** |
| `main.risk.risk_output_rm_tables_operational_risk_update_hedge_v1` | — | Operational-risk events on hedge transactions: order details, sender, send / start timestamps, rates, instrument, IsBuy, units, netting updates, reasons. |

### Hedge-server reroute audit

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | Append, 1440-min | **Parent** — one row per hedge-server reroute batch with start/end window and audit notes. |
| `main.trading.bronze_etoro_trade_positionshedgeserverchangelog` | Append, 1440-min | **Child** — one row per individual position moved, with from/to hedge server IDs and the rule that triggered. |

### Dictionary / lookup tables

| Table | What it defines |
|---|---|
| `main.general.bronze_etoro_dictionary_hedgeorderstate` | 8 lifecycle states of a hedge order: created → … → executed / partial / rejected / failed / cancelled |
| `main.general.bronze_etoro_dictionary_hedgepositionfailreason` | 24 fail reasons — market, liquidity, technical, recovery |
| `main.general.bronze_etoro_dictionary_hedgepositionfailseverity` | 6 severity tiers (no-problem → critical → unknown) drive alerting |
| `main.general.bronze_etoro_dictionary_hedgeeventtype` | 8 infra event types — connection, recovery, zeroing, volume anomaly |
| `main.general.bronze_etoro_dictionary_hedgebreakdowntype` | 6 stages of the hedge execution pipeline |
| `main.general.bronze_etoro_dictionary_hedgerecoverystate` | 5 hedge recovery states for the disaster-recovery flow |
| `main.general.bronze_etoro_dictionary_hedgestrategymode` | 3 hedging strategy modes for internal risk management |
| `main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype` | 8 manual-request types — custom orders, exposure adjust, netting moves, queue management |

---

## Query Patterns

### Pattern 1 — Final state of every hedge order (deduplicated transitions)
```sql
WITH ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY EventTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE EventDate = '2026-05-09'
)
SELECT OrderID, InstrumentID, LiquidityAccountID, FinalState = State, EventTime
FROM ranked
WHERE rn = 1;
```
**Use when:** "what was the final state of every hedge order today?", "fill / reject / partial breakdown"

### Pattern 2 — Fill rate by LP
```sql
WITH final AS (
  SELECT OrderID, LiquidityAccountID,
         State AS final_state,
         ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY EventTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE EventDate BETWEEN '2026-05-01' AND '2026-05-09'
)
SELECT LiquidityAccountID,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN final_state = 'Filled' THEN 1 ELSE 0 END) AS filled,
       SUM(CASE WHEN final_state = 'Filled' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS fill_rate
FROM final
WHERE rn = 1
GROUP BY LiquidityAccountID
ORDER BY fill_rate;
```
**Use when:** "fill rate by LP this week", "which LP is rejecting most?"

### Pattern 3 — HBC parent + child join
```sql
SELECT p.HBCExecutionID, p.HedgeID,
       p.RequestedLots, p.ExecutedLots, p.eToroRate, p.LPRate,
       p.Outcome,
       COUNT(c.OrderGUID) AS fix_orders,
       MIN(c.OrderState) AS min_child_state,
       MAX(c.OrderState) AS max_child_state
FROM main.dealing.bronze_etoro_hedge_hbcexecutionlog p
LEFT JOIN main.dealing.bronze_etoro_hedge_hbcorderlog c
  ON c.HedgeID = p.HedgeID
WHERE p.EventDate = '2026-05-09'
GROUP BY p.HBCExecutionID, p.HedgeID, p.RequestedLots, p.ExecutedLots, p.eToroRate, p.LPRate, p.Outcome;
```
**Use when:** "HBC execution detail today", "requested vs executed lots", "any HBC partials?"

### Pattern 4 — Manual hedge interventions today (separate operators from ExposureBalancer)
```sql
SELECT *,
       CASE WHEN OrderSource = 'ExposureBalancer' THEN 'auto' ELSE 'operator' END AS author
FROM main.dealing.bronze_etoro_hedge_manualorderexecutionlog
WHERE EventDate = '2026-05-09'
ORDER BY EventTime;
```
**Use when:** "operator interventions today", "ExposureBalancer activity"

### Pattern 5 — Live netting position for an instrument
```sql
SELECT LiquidityAccountID, InstrumentID, ValueDate,
       NetUnits, AvgRate, UnrealizedPnL
FROM main.dealing.bronze_etoro_hedge_netting
WHERE InstrumentID = 1111
ORDER BY LiquidityAccountID, ValueDate;
```
**Use when:** "current hedge position on Tesla", "where are we long/short net"

### Pattern 6 — Hedge-server reroutes this week (parent + child)
```sql
SELECT s.SummaryID, s.StartTime, s.EndTime, s.Comments,
       COUNT(d.PositionID) AS positions_moved,
       collect_set(d.RuleName) AS reroute_rules
FROM main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog s
LEFT JOIN main.trading.bronze_etoro_trade_positionshedgeserverchangelog d
  ON d.SummaryID = s.SummaryID
WHERE s.StartTime >= CURRENT_DATE - 7
GROUP BY s.SummaryID, s.StartTime, s.EndTime, s.Comments
ORDER BY s.StartTime DESC;
```
**Use when:** "hedge-server moves this week", "what rules triggered position reroutes"

### Pattern 7 — Hedge failures with severity classification
```sql
SELECT e.EventDate, e.OrderID, e.InstrumentID,
       fr.FailReason, fs.Severity
FROM main.dealing.bronze_etoro_hedge_executionlog e
LEFT JOIN main.general.bronze_etoro_dictionary_hedgepositionfailreason fr
  ON e.FailReasonID = fr.HedgePositionFailReasonID
LEFT JOIN main.general.bronze_etoro_dictionary_hedgepositionfailseverity fs
  ON fr.SeverityID = fs.HedgePositionFailSeverityID
WHERE e.State IN ('Failed', 'Rejected')
  AND e.EventDate = '2026-05-09'
ORDER BY fs.SeverityRank DESC;
```
**Use when:** "today's hedge failures by severity", "which failures need escalation?"

---

## Cross-references

- EOD recon against LP custodian files (downstream of these execution events) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- LP contracts, what we pay them, COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Pricing inputs to hedge execution → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Position state on the customer side (every customer-action event) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Portfolio-level execution quality (NBBO, slippage, fails, latency) → [`best-execution.md`](best-execution.md)
- Operational reference for hedge production code → `/Workspace/Repos/dealing/BI-Dealing/databricks/` (production notebooks live here; not a skill but the source of truth for ETL behaviour)

## Provenance

Authored from Unity Catalog table-level comments harvested 2026-05-11 on `main.dealing.bronze_etoro_hedge_executionlog`, `*_hbcexecutionlog`, `*_hbcorderlog`, `*_manualorderexecutionlog`, `*_netting`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged`, plus the eight dictionary tables in `main.general` / `main.bi_db`. Source-of-truth wikis live under `knowledge/synapse/Wiki/Hedge/Tables/`. Pending: query patterns from the dealing-analyst skill set when delivered.
