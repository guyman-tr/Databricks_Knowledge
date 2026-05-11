---
id: dealing-investigation-and-execution
name: "Dealing Investigation & Hedge-Execution Events"
description: "Per-order hedge-execution audit trail for the dealing desk — the dealer-side counterpart to the broker-side position log. Anchored on Hedge.ExecutionLog (append-only state-transition log with 8 OrderStates: None/Sent/New/Partial/Fill/Reject/Fail/Cancelled — Sent and Fail NOT observed in data; 24 columns; ~2.4M rows in Synapse 2023-01→present), plus the HBC two-table parent/child stack (HBCExecutionLog parent with ExecutionID PK + RequestAmountInLots vs ExecutionAmountInLots rounding semantics + 3 rate snapshots InitialRate/ExecutionRate/LPExecutionRate; HBCOrderLog child with GUID OrderID PK + HedgeID cross-reference to ExecutionLog.OrderID — HBC archive since Nov 2023!), plus Hedge.ManualOrderExecutionLog (397 rows total — RequestTypeID=-1 = ExposureBalancer auto-corrections vs RequestTypeID>=0 = dealing-desk human operator interventions; 8 manual request types from Custom Request through Move Netting). Live state in Hedge.Netting; operational ABook monitoring in BI_DB_ABook_Exposure_NOPHedged (last updated 2024-02-15 despite active pipeline — stale!); 5 SSRS latency metrics (Request Process / Provider RTT / Response Process / Total Internal / Throughput). Legacy/HedgeServer (OrderID>0) vs EMS/HBC (OrderID=-1, EMSOrderID='{ExternalID}_{seq}') dual-path identification. Hedge-server reroute audit (parent SummaryLog + child ChangeLog)."
triggers:
  - hedge execution
  - hedge order
  - ExecutionLog
  - Hedge.ExecutionLog
  - HBCExecutionLog
  - HBCOrderLog
  - Hedge By Customer
  - HBC
  - HBC flow
  - HBC parent
  - HBC child
  - CBH
  - Customer Based Hedging
  - EMS
  - EMSOrderID
  - Execution Management System
  - manual order
  - ManualOrderExecutionLog
  - ExposureBalancer
  - dealing desk operator
  - HedgeClient
  - hedge netting
  - Hedge.Netting
  - ABook
  - ABook exposure
  - NOP hedged
  - fill rate
  - fill latency
  - rejection rate
  - hedge failure
  - hedge fail reason
  - hedge server change
  - position reroute
  - operational risk hedge
  - dealing investigation
  - slippage
  - allowed rate difference exceeded
  - liquidity provider not available
  - execution time exceeded
  - RateIDAtSent
  - SSRS latency report
  - SendTime
  - ReceivedTime
required_tables:
  - main.dealing.bronze_etoro_hedge_executionlog
  - main.dealing.bronze_etoro_hedge_hbcexecutionlog
  - main.dealing.bronze_etoro_hedge_hbcorderlog
  - main.dealing.bronze_etoro_hedge_manualorderexecutionlog
  - main.dealing.bronze_etoro_hedge_netting
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Dealing Investigation & Hedge-Execution Events

When a customer opens a trade, eToro doesn't just record the customer position — it routes a corresponding **hedge order** to a liquidity provider (LP) to neutralize the firm's net market exposure. That hedge order can succeed, partially fill, get rejected, time out, or trigger a manual intervention by the dealing desk. Every state transition is logged. This sub-skill is the analyst-facing map of those hedge-execution logs.

**Side classification**: **Dealer**. Everything here is the dealer-side execution stack — orders sent to LPs, fills received, slippage measured, latency tracked. The broker-side counterpart (customer-position events) is owned by [`position-state-and-grain.md`](position-state-and-grain.md). When the customer-side and dealer-side are joined to ask "did this customer's trade get hedged correctly?", that's a Bridge question → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md).

The execution stack has **three layers**:

1. **Standard execution** — `Hedge.ExecutionLog` (per-order append-only state transitions) for the dominant `EMS/HBC` flow (OrderID = -1 / EMSOrderID = `{ExternalID}_{seq}`) and the legacy `HedgeServer` flow (OrderID > 0).
2. **HBC two-table stack** — `Hedge.HBCExecutionLog` (parent, ExecutionID PK) + `Hedge.HBCOrderLog` (child, GUID OrderID PK). HBC = Hedge By Customer, the order-based hedging path (distinct from CBH = Customer Based Hedging / exposure-based). **The HBC tables are an ARCHIVE — last activity Nov 2023** (Warning #7). Use them for historical analysis of the HBC era; for current execution, go to `Hedge.ExecutionLog` directly.
3. **Manual + automated correction** — `Hedge.ManualOrderExecutionLog` for ExposureBalancer auto-corrections AND dealing-desk operator interventions, in the same table, distinguished by `RequestTypeID` (Warning #4).

Plus the live-state + monitoring layer: `Hedge.Netting` (live net position per LiquidityAccount × Instrument × ValueDate, 60-min overwrite), `BI_DB_ABook_Exposure_NOPHedged` (operational monitoring snapshot — but possibly stale, Warning #5), `Trade.PositionsHedgeServerChangeSummaryLog` + `Trade.PositionsHedgeServerChangeLog` (hedge-server reroute audit), `risk.risk_output_rm_tables_operational_risk_update_hedge_v1` (operational risk).

## When to Use

Load when the question is about:

- "Why did this hedge fail?", "ExecutionLog for hedge X", "trace this EMS order's fill sequence"
- "Fill rate this week", "rejection rate by LP", "execution latency by provider"
- "What was the slippage on order Y?" (Warning #6 — compute via `RateIDAtSent` join)
- "HBC execution detail for date X" (historical — HBC tables archive only)
- "Manual hedge interventions today", "who placed manual hedges today?"
- "ExposureBalancer corrections last 24h", "ExposureBalancer activity"
- "Current hedge netting position on instrument Z"
- "ABook hedging NOP exposure right now"
- "Hedge server reroutes this week", "which positions moved hedge server?"
- "Operational risk events on hedges" (risk_output table)
- "SSRS latency report numbers", "latency P90/P99 by LP"

Do **not** load for:

- EOD broker / LP reconciliation (against custodian files) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md) — Bridge side
- LP contract terms / fees / COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md) — also Dealer side
- Customer-side position state / lifecycle / ActionTypeID → [`position-state-and-grain.md`](position-state-and-grain.md) — Broker side
- Pricing inputs to execution → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Execution-quality monthly reports (NBBO / slippage at portfolio level) → [`best-execution.md`](best-execution.md) — TCA, also Dealer side

## Scope

In scope: `Hedge.ExecutionLog` (24 cols append-only state transitions, dual-path Legacy/EMS identity, 5 latency metrics, `RateIDAtSent` slippage hook, the `ViewExecutionLog_isnull` view wrapper, 5-second trailing buffer rule, `EMSOrderID COLLATE Latin1_General_BIN` case-sensitive match); `Hedge.HBCExecutionLog` parent + `Hedge.HBCOrderLog` child (HBC requested-vs-executed lots, 3 rate snapshots, IsCancelExecution flow, 5 FailReasons, HBC OrderState dictionary — DIFFERENT from HedgeOrderState — and the HedgeID = ExecutionLog.OrderID cross-reference); `Hedge.ManualOrderExecutionLog` (ExposureBalancer vs dealing-desk distinguishers, 8-value `HedgeManualRequestType` dictionary, the FIX-protocol params for manual orders, the RequestedIsBuy/RequestedAmountInUnits null-design-intent); `Hedge.Netting` live aggregate state; `BI_DB_ABook_Exposure_NOPHedged` operational snapshot; hedge-server reroute parent/child audit; `risk_output_rm_tables_operational_risk_update_hedge_v1`; the 8 dictionary tables (HedgeOrderState, HedgePositionFailReason, HedgePositionFailSeverity, HedgeEventType, HedgeBreakdownType, HedgeRecoveryState, HedgeStrategyMode, HedgeManualRequestType, StockHedgeSource).

Out of scope: EOD recon against LP custodian files (`broker-and-lp-reconciliation.md`), LP contracts and fees (`lp-contracts-and-cogs.md`), customer-side position state (`position-state-and-grain.md`), pricing data (`pricing-and-currency-history.md`), portfolio-level execution-quality / TCA (`best-execution.md`).

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Hedge.ExecutionLog` is APPEND-ONLY with one row per STATE TRANSITION.** A single hedge order produces multiple rows: 1× `OrderState=2 (New)` ack, 1+× `OrderState=3 (Partial)` fills, terminal row `OrderState=4 (Fill)` OR `5 (Reject)` OR `7 (Cancelled)`. To get the **final state** of an order, take the most recent row by `LogTime` for that order's identity. To compute fill rate, count distinct order-identity tuples with terminal `Success=1` over total distinct sent. **OrderState=1 (Sent) and 6 (Fail) are NOT observed in current data** — they're defined in the dictionary but unused in practice. **OrderState=3 (Partial) is 44% of rows; OrderState=5 (Reject) is 31% of rows** — partials and rejects are common, not exceptional. The table has **no PK** — intentional for a high-write append log; uniqueness is enforced by the application-level `OrderID` / `EMSOrderID`.

2. **Tier 1 — Dual order-identity paths: Legacy vs EMS/HBC.** Two execution flows write to `Hedge.ExecutionLog` with different identity columns:
   - **Legacy / HedgeServer path**: `OrderID` > 0 (internal hedge order ID), `ParentOrderID` = real GUID, `EMSOrderID` = NULL.
   - **EMS / HBC path**: `OrderID` = **-1** (sentinel), `ParentOrderID` = `GUID(0)` (all zeros), `EMSOrderID` = `{ExternalID}_{seq}` string (e.g., `"35564138_1"`) — **this is the actual key for current production data**.
   
   When tracing an order, you MUST know which path it came from. Recent EMS data also uses `OMSProviderOrderID` / `OMSProviderExecID` for OMS-routed orders (NULL for direct EMS).

3. **Tier 1 — HBC is a two-table parent/child stack — and it's an archive.** `Hedge.HBCExecutionLog` is the parent (`ExecutionID` PK, one row per HBC attempt — `RequestAmountInLots`, `ExecutionAmountInLots`, `InitialRate`, `ExecutionRate`, `LPExecutionRate`, `IsSuccess`, `FailReason`). `Hedge.HBCOrderLog` is the child (GUID `OrderID` PK, one row per FIX order within that attempt). Join the child to the parent via `ExecutionID`; join the child to the main `Hedge.ExecutionLog` via `HBCOrderLog.HedgeID = ExecutionLog.OrderID`. **If execution creation fails before an order is placed (validation / rate check failure), only `HBCExecutionLog` gets a row (`IsSuccess=0`) — `HBCOrderLog` stays empty.** ~2,001 of 51,747 executions have 2+ child orders (multi-order executions due to partial fills when `IsHBCFillOrKill=false`).

4. **Tier 1 — `Hedge.ManualOrderExecutionLog` is BOTH humans AND machines.** Two populations share this table — never confuse them:
   - **ExposureBalancer (automated)**: `RequestTypeID = -1` (sentinel — NOT in `Dictionary.HedgeManualRequestType`!), `Sender = 'ExposureBalancer'`, `IP = NULL`, `TradeDescription = 'Exposure Balancer Saga'`, `UpdateNetting = true`, `Rate = actual market price`, `OrderType` & `TimeInForce` = NULL.
   - **Dealing-desk operator (manual)**: `RequestTypeID` >= 0 (maps to dictionary: 0=Custom Request, 1=Set Hedge Exposure, 2=Settle Requested Exposure, 3=SetTradeExposure, 4=Manual Exposure, 5=Custom Update Queued, 6=Clear Queued, 7=Move Netting), `Sender = 'HedgeClientN (by <username>)'`, `IP = internal 10.x.x.x`, `Rate = 0` (market order), `OrderType = 'Market'`, `TimeInForce = 'Day'`.
   
   Filter on `RequestTypeID` (or `Sender`) before attributing actions to a human. **The table holds only ~397 rows total** — it's a low-frequency exception log, not a high-throughput operational table.

5. **Tier 1 — `BI_DB_ABook_Exposure_NOPHedged` may be stale.** The table comment notes *"last updated 2024-02-15 despite active pipeline #471 hourly Override"* — the pipeline is configured but updates have stopped. **Always check the most recent `_etl_load_date` (or equivalent freshness column) before relying on it for current-state answers.** For current ABook exposure, prefer `Hedge.Netting` (60-min overwrite) or the streaming dealing tables (`bronze_dealingstreaming_exposures_*` family). The dormant sibling tables `BI_DB_ABook_Exposure` and `BI_DB_ABook_Exposure_History` are NOT to be used.

6. **Tier 2 — Slippage computation requires a `RateIDAtSent` join.** `RateIDAtSent` (`bigint`) is the ID of the price-rate snapshot that was active when the order was sent — meant for slippage analysis (rate at send vs `ExecutionRate` returned by LP). For HBC rows on `ExecutionLog`, `RateIDAtSent` is `NULL` (HBC uses a different rate-tracking mechanism — see HBC's own `InitialRate`/`ExecutionRate`/`LPExecutionRate` triple on `HBCExecutionLog`). For legacy/HedgeServer rows, join `RateIDAtSent` to the historical price-rate table (via `Fact_CurrencyPriceWithSplit` or instrument-specific price-snapshot tables — see [`pricing-and-currency-history.md`](pricing-and-currency-history.md)).

7. **Tier 2 — HBC tables are archived (last data Nov 2023).** `Hedge.HBCExecutionLog` data spans **2023-03-08 to 2023-11-07** (51,747 rows on LiquidityAccountID=10 ZBFX, HedgeServerID=1, success rate ~94%). The HBC flow has been superseded by the current EMS path on `Hedge.ExecutionLog`. **For pre-Nov-2023 historical investigations only.** Recent hedging questions should go to `Hedge.ExecutionLog` directly.

8. **Tier 2 — HBC OrderState dictionary ≠ HedgeOrderState dictionary.** `HBCOrderLog.OrderState` uses `Dictionary.HBCOrderState`: 0=New, 1=Pending, 2=Filled (91%), 3=Rejected (5%), 4=Cancelled, 5=UnRecoverable (3%). `Hedge.ExecutionLog.OrderState` uses `Dictionary.HedgeOrderState`: 0=None, 1=Sent, 2=New, 3=Partial, 4=Fill, 5=Reject, 6=Fail, 7=Cancelled. **Don't reuse a state-to-name map across the two tables.** Note that HBC `Filled=2` collides numerically with ExecutionLog `New=2` — easy mistake.

9. **Tier 2 — `HBCExecutionLog`: `RequestAmountInLots ≠ ExecutionAmountInLots` is EXPECTED, not a failure.** HBC rounds the requested float lot amount to whole lots before sending to the LP. Default rounding = over-hedge (ceiling). With `IsUsingSmartRounding=true`, rounds up only if `(units % lot_size) / lot_size >= 0.5`; otherwise always ceilings. The discrepancy monitoring proc `Hedge.GetHBCEstimationsDiscrepencies` validates that `ExecutionAmountInLots` matches the sum of customer position lot counts — that's the actual recon check, not the request-vs-execution delta.

10. **Tier 2 — `Hedge.Netting` is LIVE state, not history.** Overwrite-strategy ingestion (60-min). It tells you the current net hedge per (`LiquidityAccount × InstrumentID × ValueDate`) and the running hedge-book unrealized PnL. For point-in-time reconstruction, use the `History.*` tables (`History.HedgeServer`, `History.HedgeServerInstrumentConfiguration` — but note these are *configuration* history, not netting history — `Hedge.NettingDaily` and `Hedge.NettingOld` are the historical netting variants).

11. **Tier 3 — Use `Hedge.ViewExecutionLog_isnull` for queries that need to coalesce nullable identity columns.** Available in UC as `main.general.bronze_etoro_hedge_viewexecutionlog_isnull`. The view applies `ISNULL` to `EMSOrderID`, `OMSProviderOrderID`, `OMSProviderExecID`, etc., so you don't have to coalesce inline.

12. **Tier 3 — `EMSOrderID` join needs binary-collation match.** In Synapse, `EMSOrderID COLLATE Latin1_General_BIN` is the required join expression for case-sensitive matches in `SSRS_Latency_Report`. In UC / Spark, `EMSOrderID` is a `STRING` and is case-sensitive by default — direct equality works. Worth knowing when porting Synapse queries.

13. **Tier 3 — 5-second trailing buffer for partial-fill aggregation.** `GetExecutionLogData` filters `LogTime BETWEEN @FromDate AND DATEADD(SECOND, -5, @ToDate)` to avoid reading rows that may still be in flight from concurrent inserts. Apply the same pattern when computing weighted-average rates from partial fills.

14. **Tier 3 — Some `Hedge.*` tables are EMPTY (designed but not yet activated).** `Hedge.ProviderInstrumentConfiguration` and `Hedge.HedgeServerInstrumentConfiguration` are documented in the Synapse wiki but contain zero rows in production — feature is wired in code but not yet populated. **Don't treat an empty result as "no overrides configured" — treat it as "feature not yet wired".**

## Tables — the execution audit stack

### Standard execution (primary)

| Table | Strategy | Rows | Use For |
|---|---|---|---|
| `main.dealing.bronze_etoro_hedge_executionlog` ★ | Append, 60-min | ~2.4M (Synapse 2023-01→) | **Primary** per-order audit log — every state transition at every LP. Both legacy (OrderID>0) and EMS/HBC (OrderID=-1) paths. |
| `main.dealing.bronze_etoro_hedge_executionlog_v` | View | — | View alias of above |
| `main.general.bronze_etoro_hedge_viewexecutionlog_isnull` | View | — | ISNULL-coalesced view (Warning #11) |

★ = canonical entry point. 24 columns include: `LogTime` (CLUSTERED index key), `HedgeServerID`, `LiquidityAccountID`, `InstrumentID`, `OrderID` (>0 legacy / =-1 EMS), `ParentOrderID` (GUID — zero-GUID for EMS), `IsBuy`, `OrderState`, `Success`, `EMSOrderID` (the real EMS key), `Units`, `ProviderUnits` (actually executed), `ExecutionRate`, `SendTime`, `ReceivedTime`, `ExecutionTime`, `RateIDAtSent`, `FailID`, `FailReason`, `ProviderOrderID`, `ProviderExecID`, `ProviderPartyIds`, `OMSProviderOrderID`, `OMSProviderExecID`.

### HBC stack (ARCHIVE — last data Nov 2023)

| Table | Strategy | Rows | Use For |
|---|---|---|---|
| `main.dealing.bronze_etoro_hedge_hbcexecutionlog` | Append, 1440-min | ~51.7K | HBC **parent**: per-attempt summary — requested vs executed lots, 3 rates, IsSuccess, FailReason, IsCancelExecution. PK = `ExecutionID`. |
| `main.dealing.bronze_etoro_hedge_hbcorderlog` | Append, 1440-min | ~53.7K | HBC **child**: individual FIX orders inside an attempt. PK = GUID `OrderID`. Join: `HedgeID = ExecutionLog.OrderID`. |

### Manual + automated correction

| Table | Strategy | Rows | Use For |
|---|---|---|---|
| `main.dealing.bronze_etoro_hedge_manualorderexecutionlog` | Override, 60-min | ~397 | Two populations: `RequestTypeID=-1` ExposureBalancer + `RequestTypeID>=0` dealing-desk human operators (Warning #4). |

### Live state + monitoring

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_netting` | Override, 60-min | Live aggregate net hedge per `LiquidityAccount × InstrumentID × ValueDate`. Drives hedge-book unrealized PnL. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged` | Hourly Override (#471) | Operational ABook hedging exposure snapshot. **Check `_etl_load_date` before trusting** (Warning #5). |
| `main.risk.risk_output_rm_tables_operational_risk_update_hedge_v1` | — | Operational-risk events on hedge transactions: order details, sender, send/start timestamps, rates, instrument, IsBuy, units, netting updates, reasons. |
| `main.dealing.bronze_dealingstreaming_exposures_instrument_per_hedgeserver_exposures` | Streaming | Real-time instrument-per-hedge-server exposure feed. |
| `main.dealing.bronze_dealingstreaming_exposures_asset_class_by_hedgeserver_exposures` | Streaming | Real-time asset-class exposure by hedge server. |
| `main.dealing.bronze_dealingstreaming_omshedgerstatus_dealing_oms_hedger_status` | Streaming | Real-time OMS hedger status. |

### Hedge-server reroute audit

| Table | Strategy | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | Append, 1440-min | **Parent** — one row per hedge-server reroute batch with start/end window. |
| `main.trading.bronze_etoro_trade_positionshedgeserverchangelog` | Append, 1440-min | **Child** — one row per individual position moved, with from/to hedge server IDs and the rule that triggered. |

### Dictionary / lookup tables

| Table | What it defines | Distinct values |
|---|---|---|
| `main.general.bronze_etoro_dictionary_hedgeorderstate` | Lifecycle states for `Hedge.ExecutionLog.OrderState` | 8 (None, Sent, New, Partial, Fill, Reject, Fail, Cancelled) |
| `main.general.bronze_etoro_dictionary_hedgepositionfailreason` | Fail reasons (market / liquidity / technical / recovery) | 24 |
| `main.general.bronze_etoro_dictionary_hedgepositionfailseverity` | Severity tiers (drives alerting) | 6 (no-problem → critical → unknown) |
| `main.general.bronze_etoro_dictionary_hedgeeventtype` | Infra event types (connection, recovery, zeroing, volume anomaly) | 8 |
| `main.general.bronze_etoro_dictionary_hedgebreakdowntype` | Stages of the hedge execution pipeline | 6 |
| `main.general.bronze_etoro_dictionary_hedgerecoverystate` | Disaster-recovery flow states | 5 |
| `main.general.bronze_etoro_dictionary_hedgestrategymode` | Internal risk-management strategy modes | 3 |
| `main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype` | Manual-request types — for `ManualOrderExecutionLog` | 8 (Custom Request, Set Hedge Exposure, Settle Requested Exposure, SetTradeExposure, Manual Exposure, Custom Update Queued, Clear Queued, Move Netting) |
| `main.general.bronze_etoro_dictionary_stockhedgesource` | Stock hedge source categorization | — |

---

## Query Patterns

### Pattern 1 — Final state of every hedge order today (dedupe transitions)
```sql
WITH ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY COALESCE(EMSOrderID, CAST(OrderID AS STRING))
           ORDER BY LogTime DESC
         ) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE LogTime >= CURRENT_DATE() - INTERVAL 1 DAY
)
SELECT COALESCE(EMSOrderID, CAST(OrderID AS STRING)) AS order_identity,
       InstrumentID, LiquidityAccountID,
       OrderState AS final_state, Success, Units, ProviderUnits, LogTime
FROM ranked
WHERE rn = 1;
```
**Use when:** "final state of every hedge order today", "fill / reject / partial breakdown". Note the dual-path coalesce (Warning #2).

### Pattern 2 — Fill rate by LP this week
```sql
WITH final AS (
  SELECT COALESCE(EMSOrderID, CAST(OrderID AS STRING)) AS order_identity,
         LiquidityAccountID,
         OrderState AS final_state,
         ROW_NUMBER() OVER (
           PARTITION BY COALESCE(EMSOrderID, CAST(OrderID AS STRING))
           ORDER BY LogTime DESC
         ) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE LogTime BETWEEN DATE_SUB(CURRENT_DATE(), 7) AND CURRENT_DATE()
)
SELECT LiquidityAccountID,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN final_state = 4 THEN 1 ELSE 0 END) AS filled,
       SUM(CASE WHEN final_state = 5 THEN 1 ELSE 0 END) AS rejected,
       SUM(CASE WHEN final_state = 4 THEN 1.0 ELSE 0 END) / COUNT(*) AS fill_rate
FROM final
WHERE rn = 1
GROUP BY LiquidityAccountID
ORDER BY fill_rate;
```
**Use when:** "fill rate by LP this week", "which LP is rejecting most?". State codes per Warning #1: 4=Fill, 5=Reject.

### Pattern 3 — Trace a single order's fill sequence (EMS path)
```sql
SELECT LogTime, OrderState, Success, Units, ProviderUnits, ExecutionRate,
       FailReason, ReceivedTime, SendTime,
       DATEDIFF(MILLISECOND, SendTime, ReceivedTime) AS provider_rtt_ms
FROM main.dealing.bronze_etoro_hedge_executionlog
WHERE EMSOrderID = '35564138_1'         -- or '35564138_%' for the parent family
ORDER BY LogTime;
```
**Use when:** "trace this EMS order's lifecycle", "what happened on order X?". For legacy orders, filter on `OrderID` instead.

### Pattern 4 — Provider round-trip latency (Metric 2 of SSRS report)
```sql
SELECT LiquidityAccountID,
       PERCENTILE(DATEDIFF(MILLISECOND, SendTime, ReceivedTime), 0.5) AS p50_ms,
       PERCENTILE(DATEDIFF(MILLISECOND, SendTime, ReceivedTime), 0.9) AS p90_ms,
       PERCENTILE(DATEDIFF(MILLISECOND, SendTime, ReceivedTime), 0.99) AS p99_ms,
       MAX(DATEDIFF(MILLISECOND, SendTime, ReceivedTime)) AS max_ms,
       COUNT(*) AS fill_count
FROM main.dealing.bronze_etoro_hedge_executionlog
WHERE LogTime >= CURRENT_DATE() - INTERVAL 1 HOUR
  AND OrderState = 4                    -- Fill only
  AND SendTime IS NOT NULL
  AND ReceivedTime IS NOT NULL
GROUP BY LiquidityAccountID;
```
**Use when:** "provider latency by LP", "SSRS latency Metric 2", "RTT P90/P99". For the other 4 SSRS metrics you need the upstream `RequestTime` / `StatusUpdateTime` columns which are NOT on this table — they live on the calling app's tables (HAPI/LAPI logs).

### Pattern 5 — Slippage (`RateIDAtSent` join)
```sql
SELECT e.LogTime, e.EMSOrderID, e.InstrumentID,
       e.RateIDAtSent, e.ExecutionRate,
       p.PriceAtRateID AS rate_at_send,
       (e.ExecutionRate - p.PriceAtRateID) AS slippage_abs,
       (e.ExecutionRate / p.PriceAtRateID - 1) * 10000 AS slippage_bps
FROM main.dealing.bronze_etoro_hedge_executionlog e
LEFT JOIN <price_snapshot_table_via_pricing_skill> p ON p.RateID = e.RateIDAtSent
WHERE e.LogTime >= CURRENT_DATE() - INTERVAL 1 DAY
  AND e.OrderState = 4
  AND e.RateIDAtSent IS NOT NULL;      -- Legacy path only; EMS rows have RateIDAtSent=NULL
```
**Use when:** "slippage analysis", "did we get a worse price than what we sent?". Route to [`pricing-and-currency-history.md`](pricing-and-currency-history.md) for the price-snapshot table to join against. EMS rows have `RateIDAtSent=NULL` — for EMS slippage use `HBCExecutionLog.LPExecutionRate - HBCExecutionLog.ExecutionRate` (Warning #6).

### Pattern 6 — HBC parent + child join (ARCHIVE: pre-Nov-2023 only)
```sql
SELECT p.ExecutionID, p.HedgeID,
       p.RequestAmountInLots, p.ExecutionAmountInLots,
       p.InitialRate, p.ExecutionRate, p.LPExecutionRate,
       (p.LPExecutionRate - p.ExecutionRate) AS slippage,
       p.IsSuccess, p.FailReason,
       COUNT(c.OrderID) AS fix_orders,
       MIN(c.OrderState) AS min_child_state,
       MAX(c.OrderState) AS max_child_state
FROM main.dealing.bronze_etoro_hedge_hbcexecutionlog p
LEFT JOIN main.dealing.bronze_etoro_hedge_hbcorderlog c ON c.ExecutionID = p.ExecutionID
WHERE p.StartTime BETWEEN '2023-08-01' AND '2023-11-07'
GROUP BY p.ExecutionID, p.HedgeID, p.RequestAmountInLots, p.ExecutionAmountInLots,
         p.InitialRate, p.ExecutionRate, p.LPExecutionRate, p.IsSuccess, p.FailReason;
```
**Use when:** historical investigation of HBC-era hedging only (Warning #7).

### Pattern 7 — Separate ExposureBalancer from dealing-desk operators
```sql
SELECT
  CASE WHEN RequestTypeID = -1 THEN 'ExposureBalancer (auto)'
       ELSE 'Dealing desk operator'
  END AS author,
  RequestTypeID,
  Sender,
  COUNT(*) AS orders,
  SUM(CASE WHEN IsBuy THEN AmountInUnits ELSE 0 END) AS buy_units,
  SUM(CASE WHEN NOT IsBuy THEN AmountInUnits ELSE 0 END) AS sell_units
FROM main.dealing.bronze_etoro_hedge_manualorderexecutionlog
WHERE ClientSendTime >= CURRENT_DATE() - INTERVAL 30 DAY
GROUP BY 1, RequestTypeID, Sender
ORDER BY orders DESC;
```
**Use when:** "manual interventions this month", "who placed manual hedges?", "ExposureBalancer activity". Warning #4 — the table mixes humans and machines.

### Pattern 8 — Hedge failures with severity ranking
```sql
SELECT e.LogTime, e.EMSOrderID, e.OrderID, e.InstrumentID,
       e.FailID, e.FailReason,
       fr.Name AS fail_reason_canonical,
       fs.Name AS severity
FROM main.dealing.bronze_etoro_hedge_executionlog e
LEFT JOIN main.general.bronze_etoro_dictionary_hedgepositionfailreason fr
  ON e.FailID = fr.ID
LEFT JOIN main.general.bronze_etoro_dictionary_hedgepositionfailseverity fs
  ON fr.SeverityID = fs.ID                  -- verify col names against the live dict
WHERE e.LogTime >= CURRENT_DATE() - INTERVAL 1 DAY
  AND e.Success = false
ORDER BY e.LogTime DESC;
```
**Use when:** "today's hedge failures", "which failures need escalation?". Join through the dictionary tables for canonical reason + severity.

### Pattern 9 — Live netting position for an instrument
```sql
SELECT LiquidityAccountID, InstrumentID, ValueDate,
       NetUnits, AvgRate, UnrealizedPnL
FROM main.dealing.bronze_etoro_hedge_netting
WHERE InstrumentID = 1111                   -- e.g. Tesla
ORDER BY LiquidityAccountID, ValueDate;
```
**Use when:** "current hedge position on Tesla", "where are we long/short net on instrument X". Live state (60-min overwrite).

### Pattern 10 — Hedge-server reroutes (parent + child)
```sql
SELECT s.SummaryID, s.StartTime, s.EndTime, s.Comments,
       COUNT(d.PositionID) AS positions_moved,
       collect_set(d.RuleName) AS reroute_rules,
       collect_set(d.ToHedgeServerID) AS to_servers
FROM main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog s
LEFT JOIN main.trading.bronze_etoro_trade_positionshedgeserverchangelog d
  ON d.SummaryID = s.SummaryID
WHERE s.StartTime >= CURRENT_DATE() - INTERVAL 7 DAY
GROUP BY s.SummaryID, s.StartTime, s.EndTime, s.Comments
ORDER BY s.StartTime DESC;
```
**Use when:** "hedge-server moves this week", "what rules triggered position reroutes?"

---

## Cross-references

- EOD recon against LP custodian files (downstream of these execution events) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- LP contracts, what we pay LPs, COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Pricing inputs to hedge execution (the `RateIDAtSent` join target) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Position state on the customer side (every customer-action event) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Portfolio-level execution quality (NBBO, slippage at the report level, market impact) → [`best-execution.md`](best-execution.md)
- Operational reference for hedge production code → `/Workspace/Repos/dealing/BI-Dealing/databricks/` (production notebooks live there; not a skill but the source of truth for current ETL behaviour)

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: H = Hybrid (Synapse + Lake). `Tier`: 1a wiki, 1b UC comment, 2 procs/SP source, 3 lineage, 4 live distincts.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| Hedge.ExecutionLog | H | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExecutionLog.md | 24 cols, 2.4M Synapse rows, dual-path identity (Legacy vs EMS/HBC), 8 OrderStates with live distribution, 5 SSRS latency metrics, NOLOCK + 5-second trailing buffer, FK_WITH_NOCHECK design, `Hedge.LogExecution` + `Hedge.ExecutionLogInsertBulk` writer procs |
| Hedge.HBCExecutionLog | H | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCExecutionLog.md | Parent, ExecutionID PK, 51,747 archive rows 2023-03-08→2023-11-07, requested-vs-executed-lots rounding semantics, 3 rate snapshots, slippage formula, 5 FailReasons, IsCancelExecution flow, IsHBCFillOrKill config |
| Hedge.HBCOrderLog | H | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HBCOrderLog.md | Child, GUID OrderID PK, 53,746 rows, HBC OrderState dictionary (6 values, DIFFERENT from HedgeOrderState), `HedgeID = ExecutionLog.OrderID` cross-reference |
| Hedge.ManualOrderExecutionLog | H | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ManualOrderExecutionLog.md | 397-row exception log, dual population (ExposureBalancer auto vs dealing-desk human), 8-value HedgeManualRequestType dictionary, RequestedIsBuy/RequestedAmountInUnits design-intent-but-not-implemented |
| Hedge.Netting + ABook | H | 1a | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.Netting.md + UC comment for BI_DB_ABook_Exposure_NOPHedged | Live state semantics; ABook last-updated 2024-02-15 staleness (Warning #5) |
| Hedge-server reroute tables | S | 1b | UC table-level comments (live, 2026-05-11) | parent SummaryLog + child ChangeLog audit |
| Dictionary family | H | 1a + 4 | knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/ + live UC distincts | 9 dictionary tables documented with their distinct-value counts |
| UC live inventory | H | 4 | UC information_schema.tables (live, 2026-05-11) | 74 hedge-related tables across 5 schemas (dealing, bi_db, general, trading, risk) discovered; 3 streaming dealing-exposure feeds surfaced; ViewExecutionLog_isnull view confirmed in main.general |

## Provenance

v2 rebuilt 2026-05-11 per `/speckit.skill` Phase 2.5. v1 was authored from UC table-level comments only; v2 adds the deep `Hedge.ExecutionLog` / `Hedge.HBCExecutionLog` / `Hedge.HBCOrderLog` / `Hedge.ManualOrderExecutionLog` source wikis (in `knowledge/ProdSchemas/`, NOT in the `knowledge/synapse/Wiki/` tree), the live UC table inventory of 74 hedge-related tables, and explicit Dealer-side classification.

**Key v2 additions vs v1**:
- **Dual order-identity paths explicitly documented** (Warning #2 — Legacy vs EMS/HBC) — v1 silently assumed a single path. Live data confirms `OrderID = -1` is the modern default; `EMSOrderID` is the actual key.
- **HBC tables flagged as ARCHIVE** (Warning #7 — last data Nov 2023). v1 implied they were live.
- **HBC OrderState ≠ HedgeOrderState** (Warning #8 — different dictionaries) — v1 conflated them.
- **HBC requested-vs-executed lot rounding** (Warning #9 — `IsUsingSmartRounding` semantics).
- **ManualOrderExecutionLog dual population** (Warning #4) — Sender, IP, RequestTypeID, OrderType decoders fully specified — v1 had just a one-line hint.
- **ABook_Exposure_NOPHedged staleness** (Warning #5) — explicit "last updated 2024-02-15 despite active pipeline" callout.
- **24-column `Hedge.ExecutionLog` reference** — v1 had no column-level detail.
- **5 SSRS latency metrics with formulas** (Pattern 4 + Warning #6) — v1 mentioned "fill latency" without formulas.
- **`RateIDAtSent` slippage join pattern** (Pattern 5 + Warning #6) — v1 didn't mention slippage methodology.
- **5-second trailing buffer rule** for partial-fill aggregation (Warning #13).
- **`EMSOrderID COLLATE Latin1_General_BIN`** binary-collation join quirk (Warning #12).
- **9 dictionary tables documented with distinct-value counts** — v1 had 8 with no counts.
- **3 streaming dealing-exposure feeds surfaced** (real-time alternatives to the stale ABook table).
- **`Hedge.ViewExecutionLog_isnull`** documented (Warning #11).
- **Dealer-side classification explicit**; cross-references to Broker/Bridge sub-skills clarified.
