---
name: domain-trading
description: "Per-order hedge-execution forensics. TWO PARALLEL SURFACES: (1) Synapse-mirror stack — Hedge.ExecutionLog (~2.4M rows, append-only state-transition log, 8 OrderStates None/Sent/New/Partial/Fill/Reject/Fail/Cancelled — Sent and Fail NOT observed), Hedge.HBCExecutionLog + Hedge.HBCOrderLog (parent/child HBC stack, 51.7K + 53.7K rows, ARCHIVE since Nov 2023), Hedge.ManualOrderExecutionLog (~397 rows total, ExposureBalancer auto vs dealing-desk human distinguished by RequestTypeID), Hedge.Netting (live 60-min), BI_DB_ABook_Exposure_NOPHedged (stale since 2024-02-15). (2) Event-hub stack — what powers the production 'Dealing Investigation Tool' Genie: ~2.4B rows on v_..._execution_result_evh + 1.45B on calculation_step + 773M hedge_request + 472M fix_message + 154M order_execution + 90M routed_execution. Four lenses: VeS (Visual Execution Summary, hedge_request ⨝ execution_result), VoE (Visual Orders Executions, order_execution ⨝ calculation_step on EventPayloadRowData_OrderID, filter CalculationSourceType='HedgingProviderHost'), ManualVeS (routed_execution ⨝ execution_result — but IsManual=true returns ZERO rows in live data!), TTT (fix_message FIX-tag lookup). HedgeExecutionModeID dictionary: 1=HBC (Hedge Before Confirm), 2=CBH (Confirm Before Hedge — DOMINANT 26.3M/mo), 3=DMA (Direct Market Access), 4=observed but undocumented (~72K/mo, HedgeServer 500/501/503). Crypto = HedgeServerID 81/83; DLT (Crypto Germany fully-disclosed) = HedgeServerID 86 (ARCHIVE 2024-09→2025-10). CalculationSourceType: ERM | ProviderExecutor | HedgingProviderHost. Dual order-identity: Legacy/HedgeServer (OrderID>0) vs EMS/HBC (OrderID=-1, EMSOrderID='{ExternalID}_{seq}'). Hedge-server reroute audit (parent SummaryLog + child ChangeLog). The Synapse-mirror stack is for HBC archive + ManualOrderExecutionLog forensics; the event-hub stack is for current production EMS investigation — DO NOT conflate them."
triggers:
  - hedge execution
  - hedge order
  - ExecutionLog
  - Hedge.ExecutionLog
  - HBCExecutionLog
  - HBCOrderLog
  - Hedge Before Confirm
  - HBC
  - HBC flow
  - HBC parent
  - HBC child
  - CBH
  - Confirm Before Hedge
  - DMA
  - Direct Market Access
  - DLT
  - HedgeExecutionModeID
  - EMS
  - EMSOrderID
  - Execution Management System
  - dealing investigation tool
  - investigation tool
  - Dealing Investigation Tool Genie
  - VeS
  - Visual Execution Summary
  - ExecSumm
  - VoE
  - Visual Orders Executions
  - OrderExecSumm
  - ManualVeS
  - ManualExecSumm
  - TTT
  - FIX message
  - FIXData
  - RawFIXMessage
  - calculation_step
  - hedge_request_evh
  - order_execution_evh
  - routed_execution_evh
  - execution_result_evh
  - fix_message_evh
  - HedgingProviderHost
  - CalculationSourceType
  - ProviderExecutor
  - ERM
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
  - OMS
  - TOB
  - Top of Book
required_tables:
  - main.dealing.bronze_etoro_hedge_executionlog
  - main.dealing.bronze_etoro_hedge_hbcexecutionlog
  - main.dealing.bronze_etoro_hedge_hbcorderlog
  - main.dealing.bronze_etoro_hedge_manualorderexecutionlog
  - main.dealing.bronze_etoro_hedge_netting
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged
  - main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_hedge_request_evh
  - main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_order_execution_evh
  - main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_routed_execution_evh
  - main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_calculation_step_evh
  - main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_fix_message_evh
  - main.dealing.v_bronze_event_hub_prod_event_streaming_we_investigation_tool_execution_result_evh
version: 3
owner: "dataplatform"
last_validated_at: "2026-05-12"
---

# Dealing Investigation & Hedge-Execution Events

When a customer opens a trade, eToro routes a corresponding **hedge order** to a liquidity provider (LP) to neutralize firm exposure. The hedge can succeed, partially fill, get rejected, time out, or trigger a manual dealing-desk intervention. Every state transition is logged. This sub-skill is the analyst-facing map of those hedge-execution logs.

**Side classification**: **Dealer**. The broker-side counterpart (customer-position events) lives in [`position-state-and-grain.md`](position-state-and-grain.md); joins between the two ("did this customer's trade get hedged correctly?") are Bridge questions → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md).

## Two parallel investigation surfaces

There are **two distinct table families** to investigate hedge execution, with different keys, grains, volumes, and time horizons. Always know which one you're on.

| Surface | Tables | Volume | When to use | Anchor knowledge |
|---|---|---|---|---|
| **A) Synapse-mirror stack** | `Hedge.ExecutionLog`, `Hedge.HBCExecutionLog`/`HBCOrderLog`, `Hedge.ManualOrderExecutionLog`, `Hedge.Netting`, `ABook_Exposure_NOPHedged`, hedge-server reroute audit | ~2.4M `ExecutionLog`; HBC ~52K archive; ~397 manual | HBC archive (pre-Nov 2023), Manual / ExposureBalancer audit, hedge-server reroute, netting & ABook state | Synapse OLTP wikis (in `knowledge/ProdSchemas/`) |
| **B) Event-hub stack** | `bronze_event_hub_*_investigation_tool_*_evh` family (+ `v_...` views, + silver FIX-parsed) | **~2.4B `v_..._execution_result_evh`; 1.45B `calculation_step`; 773M `hedge_request`; 472M `fix_message`; 154M `order_execution`; 90M `routed_execution`** | Current-production EMS, per-`ExecutionID` end-to-end trace, FIX lookup, validation/calc step replay, spreaded-rate slippage | Dealing-team Genie "**Dealing Investigation Tool**" (`01eecfdc6e121d3a9c1551c473de87f5`) |

**Parallel, not redundant.** Surface A = HBC archive + Manual forensics. Surface B = deepest per-event detail on current production. They use **different `ExecutionID` values** — Surface-B `ExecutionID` (LONG, EMS-pipeline-generated) is NOT the same as Surface-A `Hedge.ExecutionLog.OrderID` or `HBCExecutionLog.ExecutionID`. Don't naively cross-join. Shared live-state layer: `Hedge.Netting`, `BI_DB_ABook_Exposure_NOPHedged` (stale — Warning #5), reroute audit (parent + child), and `risk_output_rm_tables_operational_risk_update_hedge_v1`.

## When to Use

Load when the question is about:

- "Why did this hedge fail?", "ExecutionLog for hedge X", "trace this EMS order's fill sequence"
- "Fill rate this week", "rejection rate by LP", "execution latency by provider"
- "What was the slippage on order Y?" (Warning #8 — compute via `RateIDAtSent` join on Surface A; `ExecutionRateSpreaded - ClientViewRate` on Surface B)
- "HBC execution detail for date X" (historical — Surface A HBC tables archive only)
- "Manual hedge interventions today", "who placed manual hedges today?" → Surface A `ManualOrderExecutionLog` (Warning #4) — NOT Surface B `IsManual=true` which returns zero rows (Warning #13)
- "ExposureBalancer corrections last 24h", "ExposureBalancer activity"
- "Current hedge netting position on instrument Z"
- "ABook hedging NOP exposure right now"
- "Hedge server reroutes this week", "which positions moved hedge server?"
- "Operational risk events on hedges" (risk_output table)
- "SSRS latency report numbers", "latency P90/P99 by LP"
- **Dealing Investigation Tool / Genie questions** — anything mentioning **VeS** (Visual Execution Summary), **VoE** (Visual Orders Executions), **ExecSumm**, **ManualVeS**, **TTT** / "FIX messages by ExecutionID", **HedgeExecutionModeID** (1=HBC, 2=CBH, 3=DMA), **HedgingProviderHost** filter, **OMS** (Order Management System), **TOB** (Top of Book), **DLT** (Crypto Germany fully-disclosed flow), or **REAL_Futures** → use Surface B event-hub tables
- "End-to-end trace of ExecutionID X" (every calculation step, FIX message, routing decision, fill) → Surface B (the 6 event-hub tables join on `ExecutionID`)

Do **not** load for:

- EOD broker / LP reconciliation (against custodian files) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md) — Bridge side
- LP contract terms / fees / COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md) — also Dealer side
- Customer-side position state / lifecycle / ActionTypeID → [`position-state-and-grain.md`](position-state-and-grain.md) — Broker side
- Pricing inputs to execution → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Execution-quality monthly reports (NBBO / slippage at portfolio level) → [`best-execution.md`](best-execution.md) — TCA, also Dealer side

## Scope

In scope: **Surface A (Synapse-mirror)** — `Hedge.ExecutionLog` (24 cols, dual-path Legacy/EMS identity, 5 latency metrics, `RateIDAtSent` slippage, `ViewExecutionLog_isnull` wrapper, 5-second trailing buffer, `EMSOrderID COLLATE Latin1_General_BIN`); `Hedge.HBCExecutionLog` + `HBCOrderLog` parent/child (HBC requested-vs-executed lots, 3 rate snapshots, IsCancelExecution, 5 FailReasons, HBC OrderState dict ≠ HedgeOrderState, `HedgeID = ExecutionLog.OrderID`); `Hedge.ManualOrderExecutionLog` (ExposureBalancer vs dealing-desk distinguishers, 8-value `HedgeManualRequestType` dict); `Hedge.Netting`; `BI_DB_ABook_Exposure_NOPHedged`; hedge-server reroute audit; `risk_output_rm_tables_operational_risk_update_hedge_v1`; 9 dictionary tables. **Surface B (Event-hub, Dealing Investigation Tool Genie)** — the six `bronze_event_hub_*_investigation_tool_*_evh` tables (`hedge_request`, `order_execution`, `routed_execution`, `calculation_step`, `fix_message`, plus the `v_..._execution_result_evh` view), the adjacent `order_log_evh` + `validation_step_evh`, the parsed `silver_..._fix_message_evh` (175 cols); the four lenses (**VeS** / **ManualVeS** / **VoE** / **TTT**) and their canonical join recipes; `HedgeExecutionModeID` dict (1=HBC, 2=CBH, 3=DMA, 4=undocumented); `HedgeServerID` markers (81/83=Crypto, 86=DLT archive, 500/501/503=mode-4 cluster); `CalculationSourceType` (ERM/ProviderExecutor/HedgingProviderHost); `OrderStatus` lifecycle; `FlowType`.

Out of scope: EOD recon against LP custodian files (`broker-and-lp-reconciliation.md`), LP contracts and fees (`lp-contracts-and-cogs.md`), customer-side position state (`position-state-and-grain.md`), pricing data (`pricing-and-currency-history.md`), portfolio-level execution-quality / TCA (`best-execution.md`).

Last verified: 2026-05-12

## Critical Warnings

1. **Tier 1 — `Hedge.ExecutionLog` is APPEND-ONLY with one row per STATE TRANSITION.** A single hedge order produces multiple rows: 1× `OrderState=2 (New)` ack, 1+× `OrderState=3 (Partial)` fills, terminal row `OrderState=4 (Fill)` OR `5 (Reject)` OR `7 (Cancelled)`. To get the **final state** of an order, take the most recent row by `LogTime` for that order's identity. To compute fill rate, count distinct order-identity tuples with terminal `Success=1` over total distinct sent. **OrderState=1 (Sent) and 6 (Fail) are NOT observed in current data** — they're defined in the dictionary but unused in practice. **OrderState=3 (Partial) is 44% of rows; OrderState=5 (Reject) is 31% of rows** — partials and rejects are common, not exceptional. The table has **no PK** — intentional for a high-write append log; uniqueness is enforced by the application-level `OrderID` / `EMSOrderID`.

2. **Tier 1 — Dual order-identity paths: Legacy vs EMS/HBC.** Two execution flows write to `Hedge.ExecutionLog` with different identity columns:
   - **Legacy / HedgeServer path**: `OrderID` > 0 (internal hedge order ID), `ParentOrderID` = real GUID, `EMSOrderID` = NULL.
   - **EMS / HBC path**: `OrderID` = **-1** (sentinel), `ParentOrderID` = `GUID(0)` (all zeros), `EMSOrderID` = `{ExternalID}_{seq}` string (e.g., `"35564138_1"`) — **this is the actual key for current production data**.
   
   When tracing an order, you MUST know which path it came from. Recent EMS data also uses `OMSProviderOrderID` / `OMSProviderExecID` for OMS-routed orders (NULL for direct EMS).

3. **Tier 1 — HBC is a two-table parent/child stack — and it's an archive.** `Hedge.HBCExecutionLog` is the parent (`ExecutionID` PK, one row per HBC attempt — `RequestAmountInLots`, `ExecutionAmountInLots`, `InitialRate`, `ExecutionRate`, `LPExecutionRate`, `IsSuccess`, `FailReason`). `Hedge.HBCOrderLog` is the child (GUID `OrderID` PK, one row per FIX order within that attempt). Join the child to the parent via `ExecutionID`; join the child to the main `Hedge.ExecutionLog` via `HBCOrderLog.HedgeID = ExecutionLog.OrderID`. **If execution creation fails before an order is placed (validation / rate check failure), only `HBCExecutionLog` gets a row (`IsSuccess=0`) — `HBCOrderLog` stays empty.** ~2,001 of 51,747 executions have 2+ child orders (multi-order executions due to partial fills when `IsHBCFillOrKill=false`). **Note on naming**: HBC = **"Hedge Before Confirm"** (a sequence-of-operations name — `HedgeExecutionModeID=1` in the event-hub stack), not "Hedge By Customer" as some Synapse-era wikis stated. Confirmed against the dealing team's own Dealing Investigation Tool Genie definitions (see Warning #6 for the full mode dictionary).

4. **Tier 1 — `Hedge.ManualOrderExecutionLog` is BOTH humans AND machines.** Two populations share this table — never confuse them:
   - **ExposureBalancer (automated)**: `RequestTypeID = -1` (sentinel — NOT in `Dictionary.HedgeManualRequestType`!), `Sender = 'ExposureBalancer'`, `IP = NULL`, `TradeDescription = 'Exposure Balancer Saga'`, `UpdateNetting = true`, `Rate = actual market price`, `OrderType` & `TimeInForce` = NULL.
   - **Dealing-desk operator (manual)**: `RequestTypeID` >= 0 (maps to dictionary: 0=Custom Request, 1=Set Hedge Exposure, 2=Settle Requested Exposure, 3=SetTradeExposure, 4=Manual Exposure, 5=Custom Update Queued, 6=Clear Queued, 7=Move Netting), `Sender = 'HedgeClientN (by <username>)'`, `IP = internal 10.x.x.x`, `Rate = 0` (market order), `OrderType = 'Market'`, `TimeInForce = 'Day'`.
   
   Filter on `RequestTypeID` (or `Sender`) before attributing actions to a human. **The table holds only ~397 rows total** — it's a low-frequency exception log, not a high-throughput operational table.

5. **Tier 1 — `BI_DB_ABook_Exposure_NOPHedged` may be stale.** The table comment notes *"last updated 2024-02-15 despite active pipeline #471 hourly Override"* — the pipeline is configured but updates have stopped. **Always check the most recent `_etl_load_date` (or equivalent freshness column) before relying on it for current-state answers.** For current ABook exposure, prefer `Hedge.Netting` (60-min overwrite) or the streaming dealing tables (`bronze_dealingstreaming_exposures_*` family). The dormant sibling tables `BI_DB_ABook_Exposure` and `BI_DB_ABook_Exposure_History` are NOT to be used.

6. **Tier 1 — `HedgeExecutionModeID` is the canonical execution-mode dictionary on Surface B**, and it supersedes the older Synapse-era HBC/CBH naming. Genie definitions: **`1`=HBC ("Hedge Before Confirm")** · **`2`=CBH ("Confirm Before Hedge" — DOMINANT, 26.3M rows/mo on the result view)** · **`3`=DMA ("Direct Market Access")** · **`4`=observed but undocumented in the Genie** (~72K/mo on HedgeServer 500/501/503, likely futures-specific — ask dealing team) · large `NULL` bucket = mode-not-yet-assigned at row time. **The names are sequence-of-operations: HBC sends the hedge BEFORE confirming to the customer; CBH confirms to the customer FIRST then hedges.** Live distribution + HedgeServerID routing markers in the Surface-B operational dictionary table below.

7. **Tier 1 — `HedgeServerID` carries flow-routing semantics on Surface B.** Markers: **81/83 = Crypto** (live, 80K rows/mo combined); **86 = DLT** (Crypto Germany fully-disclosed) — **archived 2024-09-26 → 2025-10-30, zero writes since Oct 2025**, historical-only; **500/501/503 = the `HedgeExecutionModeID=4` cluster** (unconfirmed semantics); **5000 = DMA**; mainline EMS for CFD/equity = 2/8/12/13/82/84/102/110/112/121/124/128/130/225/226/1776. Always pair `HedgeServerID` with `HedgeExecutionModeID` — one without the other is ambiguous.

8. **Tier 2 — Slippage computation requires a `RateIDAtSent` join.** `RateIDAtSent` (`bigint`) is the ID of the price-rate snapshot that was active when the order was sent — meant for slippage analysis (rate at send vs `ExecutionRate` returned by LP). For HBC rows on `ExecutionLog`, `RateIDAtSent` is `NULL` (HBC uses a different rate-tracking mechanism — see HBC's own `InitialRate`/`ExecutionRate`/`LPExecutionRate` triple on `HBCExecutionLog`). For legacy/HedgeServer rows, join `RateIDAtSent` to the historical price-rate table (via `Fact_CurrencyPriceWithSplit` or instrument-specific price-snapshot tables — see [`pricing-and-currency-history.md`](pricing-and-currency-history.md)). **On Surface B**, the simpler `(ExecutionRateSpreaded - ClientViewRate)` columns on `v_..._execution_result_evh` give you per-execution spreaded-rate slippage directly — no `RateID` join required.

9. **Tier 2 — HBC tables are archived (last data Nov 2023).** `Hedge.HBCExecutionLog` data spans **2023-03-08 to 2023-11-07** (51,747 rows on LiquidityAccountID=10 ZBFX, HedgeServerID=1, success rate ~94%). The HBC flow has been superseded by the current EMS path on `Hedge.ExecutionLog` AND by the event-hub `investigation_tool_*_evh` stack (Surface B). **For pre-Nov-2023 historical investigations only.** Recent hedging questions should go to `Hedge.ExecutionLog` (Surface A) or the event-hub stack (Surface B) directly.

10. **Tier 2 — HBC OrderState dictionary ≠ HedgeOrderState dictionary.** `HBCOrderLog.OrderState` uses `Dictionary.HBCOrderState`: 0=New, 1=Pending, 2=Filled (91%), 3=Rejected (5%), 4=Cancelled, 5=UnRecoverable (3%). `Hedge.ExecutionLog.OrderState` uses `Dictionary.HedgeOrderState`: 0=None, 1=Sent, 2=New, 3=Partial, 4=Fill, 5=Reject, 6=Fail, 7=Cancelled. **Don't reuse a state-to-name map across the two tables.** Note that HBC `Filled=2` collides numerically with ExecutionLog `New=2` — easy mistake.

11. **Tier 2 — `HBCExecutionLog`: `RequestAmountInLots ≠ ExecutionAmountInLots` is EXPECTED, not a failure.** HBC rounds the requested float lot amount to whole lots before sending to the LP. Default rounding = over-hedge (ceiling). With `IsUsingSmartRounding=true`, rounds up only if `(units % lot_size) / lot_size >= 0.5`; otherwise always ceilings. The discrepancy monitoring proc `Hedge.GetHBCEstimationsDiscrepencies` validates that `ExecutionAmountInLots` matches the sum of customer position lot counts — that's the actual recon check, not the request-vs-execution delta.

12. **Tier 2 — `Hedge.Netting` is LIVE state, not history.** Overwrite-strategy ingestion (60-min). It tells you the current net hedge per (`LiquidityAccount × InstrumentID × ValueDate`) and the running hedge-book unrealized PnL. For point-in-time reconstruction, use the `History.*` tables (`History.HedgeServer`, `History.HedgeServerInstrumentConfiguration` — but note these are *configuration* history, not netting history — `Hedge.NettingDaily` and `Hedge.NettingOld` are the historical netting variants).

13. **Tier 2 — Surface-B `IsManual=true` returns ZERO rows — the Genie's ManualVeS filter is dead.** Verified across 165M historical rows on `v_..._routed_execution_evh` (first row 0001-01-03 sentinel → latest 2026-05-12): all `IsManual=false`. For "who placed manual hedges" / "ExposureBalancer activity" / "dealing-desk operator interventions" → use **Surface A `Hedge.ManualOrderExecutionLog`** (Warning #4, ~397 rows, populated). The `IsManual` flag on the event-hub side is a reserved design column never set true in current production.

14. **Tier 2 — Surface-B `OrderStatus` is a per-event lifecycle status; terminal states are `Filled`/`Partial`/`Rejected`/`Cancelled`.** A healthy execution emits multiple rows (`Routed` → `New` → `Filled` — roughly equal counts at ~13.3M/mo each). To get the **final outcome**: `ROW_NUMBER() OVER (PARTITION BY ExecutionID ORDER BY StatusUpdateTime DESC) = 1` then filter to a terminal status — the Surface-B equivalent of Surface-A Warning #1's dedupe pattern.

15. **Tier 2 — Surface-B `CalculationSourceType` has three buckets; the Genie filters to `HedgingProviderHost` for VoE.** Live distribution on `calculation_step_evh`: `ERM` 76% (pre-decision exposure/risk noise — voluminous), `ProviderExecutor` 12% (LP-side compute), **`HedgingProviderHost` 8% (the analyst-facing slice, Genie filter for VoE)**. For pre-execution risk-decision questions (NOP impact, exposure deltas), `ERM` is the right filter — but that's beyond the Investigation Tool's scope.

16. **Tier 3 — Use `Hedge.ViewExecutionLog_isnull` for queries that need to coalesce nullable identity columns.** Available in UC as `main.general.bronze_etoro_hedge_viewexecutionlog_isnull`. The view applies `ISNULL` to `EMSOrderID`, `OMSProviderOrderID`, `OMSProviderExecID`, etc., so you don't have to coalesce inline.

17. **Tier 3 — `EMSOrderID` join needs binary-collation match.** In Synapse, `EMSOrderID COLLATE Latin1_General_BIN` is the required join expression for case-sensitive matches in `SSRS_Latency_Report`. In UC / Spark, `EMSOrderID` is a `STRING` and is case-sensitive by default — direct equality works. Worth knowing when porting Synapse queries.

18. **Tier 3 — 5-second trailing buffer for partial-fill aggregation.** `GetExecutionLogData` filters `LogTime BETWEEN @FromDate AND DATEADD(SECOND, -5, @ToDate)` to avoid reading rows that may still be in flight from concurrent inserts. Apply the same pattern when computing weighted-average rates from partial fills.

19. **Tier 3 — Some `Hedge.*` tables are EMPTY (designed but not yet activated).** `Hedge.ProviderInstrumentConfiguration` and `Hedge.HedgeServerInstrumentConfiguration` are documented in the Synapse wiki but contain zero rows in production — feature is wired in code but not yet populated. **Don't treat an empty result as "no overrides configured" — treat it as "feature not yet wired".**

20. **Tier 3 — Surface-B has two helpful tables NOT in the Genie's table list, plus a parsed-FIX silver layer.** The Genie space lists 6 tables; the catalog has more: **`bronze_event_hub_..._order_log_evh`** (an `ExecutionID`-keyed per-event log with `HedgeExecutionModeID`, `OrderState`, `TriggerRate`, `RateValidationThreshold`, `FailReason` — useful when `execution_result` view doesn't have enough detail), **`bronze_event_hub_..._validation_step_evh`** (`ValidationName`, `ValidationSourceType`, `IsValid`, `ValidationProperties` MAP — the pre-execution validation-gate audit log; use for "why was this execution rejected before reaching the LP?"), and **`silver_event_hub_..._fix_message_evh`** (175 cols, every FIX tag parsed into a named or numeric column — `Symbol`, `Side`, `OrderQty`, `LastPx`, `OrdStatus`, `ExecID`, `OrigClOrdID`, etc.). The Genie uses bronze `fix_message` for raw `RawFIXMessage` / `JsonFIXMessage` lookup; for analytical FIX queries (e.g., "Avg execution price by ExecBroker"), prefer the silver layer.

## Surface A — Synapse-mirror execution audit stack

| Table | Strategy | Rows | Use For |
|---|---|---|---|
| `main.dealing.bronze_etoro_hedge_executionlog` ★ | Append, 60-min | ~2.4M | **Primary** per-order audit log — every state transition at every LP. Both Legacy (OrderID>0) and EMS/HBC (OrderID=-1) paths. 24 cols: `LogTime`, `HedgeServerID`, `LiquidityAccountID`, `InstrumentID`, `OrderID`, `ParentOrderID`, `IsBuy`, `OrderState`, `Success`, `EMSOrderID`, `Units`, `ProviderUnits`, `ExecutionRate`, `SendTime`, `ReceivedTime`, `ExecutionTime`, `RateIDAtSent`, `FailID`, `FailReason`, `ProviderOrderID`, `ProviderExecID`, `ProviderPartyIds`, `OMSProviderOrderID`, `OMSProviderExecID`. |
| `main.general.bronze_etoro_hedge_viewexecutionlog_isnull` | View | — | ISNULL-coalesced view (Warning #16). |
| `main.dealing.bronze_etoro_hedge_hbcexecutionlog` (ARCHIVE Nov 2023) | Append, 1440-min | ~51.7K | HBC **parent**: per-attempt summary — requested/executed lots, 3 rates, IsSuccess, FailReason, IsCancelExecution. PK = `ExecutionID`. |
| `main.dealing.bronze_etoro_hedge_hbcorderlog` (ARCHIVE) | Append, 1440-min | ~53.7K | HBC **child**: FIX orders inside an attempt. PK = GUID `OrderID`. Join: `HedgeID = ExecutionLog.OrderID`. |
| `main.dealing.bronze_etoro_hedge_manualorderexecutionlog` | Override, 60-min | ~397 | Two populations: `RequestTypeID=-1` ExposureBalancer + `RequestTypeID>=0` dealing-desk humans (Warning #4). |
| `main.dealing.bronze_etoro_hedge_netting` | Override, 60-min | live | Live net hedge per `LiquidityAccount × InstrumentID × ValueDate`. Hedge-book unrealized PnL. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged` | Hourly Override #471 | stale | ABook hedging exposure snapshot. **Check `_etl_load_date`** (Warning #5). |
| `main.risk.risk_output_rm_tables_operational_risk_update_hedge_v1` | — | — | Operational-risk events on hedge transactions. |
| `main.dealing.bronze_dealingstreaming_exposures_*` (3 tables) | Streaming | live | Real-time exposure / OMS hedger status feeds. |
| `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` + `…changelog` | Append, 1440-min | — | Hedge-server reroute audit (parent + child). |

**Dictionaries** (all `main.general.bronze_etoro_dictionary_*` unless noted): `hedgeorderstate` (8: None/Sent/New/Partial/Fill/Reject/Fail/Cancelled) · `hedgepositionfailreason` (24) · `hedgepositionfailseverity` (6) · `hedgeeventtype` (8) · `hedgebreakdowntype` (6) · `hedgerecoverystate` (5) · `hedgestrategymode` (3) · `main.bi_db.bronze_etoro_dictionary_hedgemanualrequesttype` (8: Custom Request, Set Hedge Exposure, Settle Requested Exposure, SetTradeExposure, Manual Exposure, Custom Update Queued, Clear Queued, Move Netting) · `stockhedgesource`.

---

## Surface B — Event-hub investigation tool stack

This is the table family that backs the production **"Dealing Investigation Tool"** Genie. High-volume streaming event hub captures every step of every execution: the inbound request, every calculation step, every validation gate, every routed order, every FIX message in/out, and the final result. Every row joins to its ExecutionID; calculation/order children also carry `OrderID`.

### Core 6 tables (the Genie's data sources) ★ + adjacent ☆

All FQNs share the prefix `main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_` — abbreviated below as `…_`. Join key for everything: `ExecutionID` (LONG) — the EMS-pipeline-generated execution identity, **NOT** the same as Surface-A `Hedge.ExecutionLog.OrderID`.

| Table | Rows | Use For |
|---|---|---|
| `…_hedge_request_evh` ★ | ~773M | **VeS anchor** — inbound broker request. `ClientRequestID` is the broker→dealer bridge column. Cols: `ClientRequestID`, `InstrumentID`, `IsBuy`, `IsOpen`, `IsLimit`, `RequestedAmountInUnits/InUSD`, `ClientViewRate`, `RequestType` (Units/Notional), `FlowType` (string: Manual/Limit), `RoutingHeader`, `RequestTime`. |
| `v_…_execution_result_evh` ★ | ~2.4B | **The richest table on Surface B.** View adds OrderStatus, HedgeExecutionModeID, FailReason, TriggerRate, etc. to the bronze. Join target for VeS / ManualVeS. Cols: `ExecutionID`, `ClientRequestID`, `HedgeServerID`, `HedgeExecutionModeID`, `InstrumentID`, `IsBuy`, `IsOpen`, `ExecutedUnits`, `ExecutionRate`, `ExecutionRateSpreaded`, `ClientViewRate`, `OrderState`, `OrderStatus`, `FailReason`, `FlowType`, `TriggerRate`, `TriggerPriceRateID`, `RateValidationThreshold`, `RequestTime`, `StatusUpdateTime`, `ExecutionTime`, `OrderID`, `EntryID`. |
| `…_order_execution_evh` ★ | ~154M | **VoE anchor** — LP-bound order detail. Cols: `ExecutionID`, `AccountID`, `InstrumentID`, `IsBuy`, `ProviderUnits`, `OrderID`, `SendTime`, `AdditionalData` MAP. `v_…_order_execution_evh` view adds OrderStatus / HedgeServerID / HedgeExecutionModeID / ExecutionRate. |
| `…_calculation_step_evh` ★ | ~1.45B | **VoE join child** — every calc step. Join on `EventPayloadRowData_OrderID`. Cols: `ExecutionID`, `OrderID`, `CalculationName`, `CalculationSourceType` (Warning #15), `OriginalValue`, `CalculatedValue`, `CalculationProperties` MAP, `OccurredAt`. |
| `…_routed_execution_evh` ★ | ~90M | **ManualVeS anchor** — routing decision. Cols: `ExecutionID`, `HedgeServerID`, `InstrumentID`, `IsBuy`, `IsManual` (always FALSE — Warning #13), `Units`, `ClientOrderID`, `ExecutionStrategy`, `OrderExecutionType`, `StartTime`. View adds OrderStatus + ExecutionTime/Rate. |
| `…_fix_message_evh` ★ | ~472M | **TTT anchor** — raw FIX wire-protocol. Cols: `OrderID`, `AccountID`, `AccountName`, `MessageName`, `IsIncomingMessage`, `MessageTime`, `RawFIXMessage`, `JsonFIXMessage`, `LiquidityProviderTypeID`. |
| `…_order_log_evh` ☆ | — | Per-event log with `HedgeExecutionModeID`, `OrderState`, `TriggerRate`, `RateValidationThreshold`, `FailReason`. Use when `execution_result` is too thin. (Not in Genie.) |
| `…_validation_step_evh` ☆ | — | Pre-execution validation gates: `ValidationName`, `ValidationSourceType`, `IsValid`, `ValidationProperties` MAP. Use for "why rejected before reaching the LP?" (Not in Genie.) |
| `main.dealing.silver_event_hub_prod_event_streaming_we_investigation_tool_fix_message_evh` ☆ | — | **Parsed FIX silver layer** — 175 cols, every FIX tag resolved (`Symbol`, `Side`, `OrderQty`, `LastPx`, `OrdStatus`, `ExecID`, `OrigClOrdID`, `ExecBroker`, …). Prefer for analytical FIX queries. |

★ = in the Genie's data sources. ☆ = adjacent / not in Genie.

### The four investigation lenses (Genie-native vocabulary)

| Lens | Means | Join recipe (per Genie) | Notes |
|---|---|---|---|
| **VeS** (alias **ExecSumm**) | Visual Execution Summary | `hedge_request_evh ⨝ v_..._execution_result_evh` (default join on `ClientRequestID`), filter `OrderStatus IN ('Filled','Rejected','Cancelled')`, ORDER BY `RequestTime DESC`. Always SELECT `ExecutionID`. | HBC slice = also filter `HedgeExecutionModeID=1`; CBH slice = `=2`; DMA slice = `=3`; DLT slice = `HedgeServerID=86` (historical only). Crypto = `HedgeServerID IN (81,83)`. |
| **ManualVeS** (alias **ManualExecSumm**) | Manual Visual Execution Summary | `routed_execution_evh ⨝ v_..._execution_result_evh` (on `ExecutionID`), filter `OrderStatus IN ('Filled','Rejected','Cancelled') AND IsManual=true`, ORDER BY `StartTime DESC`. | **Returns ZERO rows in live data (Warning #13).** For real manual hedges use Surface A `Hedge.ManualOrderExecutionLog`. |
| **VoE** (alias **OrderExecSumm**) | Visual Orders Executions | `order_execution_evh ⨝ calculation_step_evh ON order_execution.EventPayloadRowData_OrderID = calculation_step.EventPayloadRowData_OrderID`, filter `calculation_step.CalculationSourceType='HedgingProviderHost'`. **Requires** `ExecutionID` OR `OrderID` to scope; without one, limit 50 rows and prompt the analyst. | Drill-down for ProviderOrder forensics inside a known `ExecutionID`. |
| **TTT** | FIX Messages — wire-protocol detail | `fix_message_evh` filtered by `OrderID` (the FIX-side order ID). | Retrieve `RawFIXMessage` / `JsonFIXMessage`. For parsed FIX-tag queries, prefer the `silver_...fix_message_evh` layer. |

### Surface-B operational dictionary (live-verified May 2026)

| Concept | Column | Values |
|---|---|---|
| Execution-mode dictionary (Warning #6) | `HedgeExecutionModeID` | **1=HBC** (Hedge Before Confirm, 1.15M/mo) · **2=CBH** (Confirm Before Hedge, 26.3M/mo — dominant) · **3=DMA** (Direct Market Access, 89K/mo) · **4=undocumented** (72K/mo on HedgeServer 500/501/503) · NULL (mode-not-yet-assigned, 13.7M/mo) |
| HedgeServerID flow markers (Warning #7) | `HedgeServerID` | 81/83 = Crypto · 86 = DLT (Crypto Germany fully-disclosed, **archived 2024-09→2025-10**) · 500/501/503 = mode-4 cluster · 5000 = DMA route · mainline EMS = 2/8/12/13/82/84/102/110/112/121/124/128/130/225/226/1776 |
| Calculation source (Warning #15) | `CalculationSourceType` | `ERM` (76% — pre-decision exposure & risk) · `ProviderExecutor` (12% — LP-side compute) · **`HedgingProviderHost` (8% — Genie filter for VoE)** |
| Lifecycle status | `OrderStatus` (on view) | Pre-terminal: `Routed`, `New`, `MarketPlaced`. Terminal: **`Filled`** (success), `Partial` (partial fill), **`Rejected`**, **`Cancelled`**. |
| Terminal state (on view subset) | `OrderState` | `Filled` / `Rejected` / `Cancelled` only |
| Request shape | `RequestType` (on hedge_request) | `Units` (lot-quantity request) · `Notional` (USD-amount request) |
| Flow type (on hedge_request, string) | `FlowType` | `Manual`, `Limit` |
| Flow type (on result/order_log views, integer) | `FlowType` | observed 0 (default/auto) and 1 (limit-style) — semantics not yet documented |
| Top FailReasons (live May 2026, rejected/cancelled) | `FailReason` | MarketReject-Expired Internally · ProviderNotConnected · Amount too low for the provider · Self Cross Prevention · ProviderUnkown-Number of orders exceeds 100/sec · Order request rejected — market execution unavailable · Execution did not pass max deal size validation · OrderValidation-Instrument not active for hedging · Symbol not allowed for fractional trading · Invalid ISIN · ProviderUnkown-Auction error · Algo: GATEWAY_FAILED · Rejected due to circuit breaker |
| Glossary (per Genie) | term | OMS = Order Management System · TOB = Top of Book (pricing method for client order request) · REAL_Futures = DMA execution flow into Marex provider · Business flow = the execution path used to execute the order |

---

## Query Patterns

### Pattern 1 — Final state of every hedge order today + fill rate by LP (Surface A dedupe)
```sql
WITH ranked AS (
  SELECT *, ROW_NUMBER() OVER (
           PARTITION BY COALESCE(EMSOrderID, CAST(OrderID AS STRING))
           ORDER BY LogTime DESC) AS rn
  FROM main.dealing.bronze_etoro_hedge_executionlog
  WHERE LogTime >= CURRENT_DATE() - INTERVAL 7 DAY
)
SELECT LiquidityAccountID, COUNT(*) AS total_orders,
       SUM(CASE WHEN OrderState = 4 THEN 1 ELSE 0 END) AS filled,
       SUM(CASE WHEN OrderState = 5 THEN 1 ELSE 0 END) AS rejected,
       SUM(CASE WHEN OrderState = 4 THEN 1.0 ELSE 0 END) / COUNT(*) AS fill_rate
FROM ranked WHERE rn = 1
GROUP BY LiquidityAccountID ORDER BY fill_rate;
```
**Use when:** "final state of every hedge order", "fill / reject breakdown by LP". Dual-path coalesce per Warning #2. State codes: 4=Fill, 5=Reject (Warning #1).

### Pattern 2 — Trace a single order's fill sequence (EMS path)
```sql
SELECT LogTime, OrderState, Success, Units, ProviderUnits, ExecutionRate,
       FailReason, ReceivedTime, SendTime,
       DATEDIFF(MILLISECOND, SendTime, ReceivedTime) AS provider_rtt_ms
FROM main.dealing.bronze_etoro_hedge_executionlog
WHERE EMSOrderID = '35564138_1'         -- or '35564138_%' for the parent family
ORDER BY LogTime;
```
**Use when:** "trace this EMS order's lifecycle", "what happened on order X?". For legacy orders, filter on `OrderID` instead.

### Pattern 3 — Provider RTT latency (SSRS Metric 2)
```sql
SELECT LiquidityAccountID,
       PERCENTILE(DATEDIFF(MILLISECOND, SendTime, ReceivedTime), 0.5)  AS p50_ms,
       PERCENTILE(DATEDIFF(MILLISECOND, SendTime, ReceivedTime), 0.9)  AS p90_ms,
       PERCENTILE(DATEDIFF(MILLISECOND, SendTime, ReceivedTime), 0.99) AS p99_ms,
       COUNT(*) AS fills
FROM main.dealing.bronze_etoro_hedge_executionlog
WHERE LogTime >= CURRENT_DATE() - INTERVAL 1 HOUR AND OrderState = 4
  AND SendTime IS NOT NULL AND ReceivedTime IS NOT NULL
GROUP BY LiquidityAccountID;
```
**Use when:** "provider latency by LP", "RTT P90/P99". The other 4 SSRS metrics need upstream `RequestTime`/`StatusUpdateTime` from HAPI/LAPI logs.

### Pattern 4 — Slippage via `RateIDAtSent` (Surface A, legacy path)
```sql
SELECT e.LogTime, e.EMSOrderID, e.InstrumentID, e.ExecutionRate,
       p.PriceAtRateID AS rate_at_send,
       (e.ExecutionRate / p.PriceAtRateID - 1) * 10000 AS slippage_bps
FROM main.dealing.bronze_etoro_hedge_executionlog e
LEFT JOIN <price_snapshot_table_via_pricing_skill> p ON p.RateID = e.RateIDAtSent
WHERE e.LogTime >= CURRENT_DATE() - INTERVAL 1 DAY AND e.OrderState = 4
  AND e.RateIDAtSent IS NOT NULL;  -- EMS rows are NULL; for EMS use Surface B Pattern 11
```
**Use when:** legacy/HedgeServer slippage. For current-production EMS, use Surface B Pattern 9 (`ExecutionRateSpreaded - ClientViewRate`) — no `RateID` join needed (Warning #8).

### Pattern 5 — HBC parent + child join (ARCHIVE only, Warning #9)
```sql
SELECT p.ExecutionID, p.HedgeID, p.RequestAmountInLots, p.ExecutionAmountInLots,
       (p.LPExecutionRate - p.ExecutionRate) AS slippage, p.IsSuccess, p.FailReason,
       COUNT(c.OrderID) AS fix_orders
FROM main.dealing.bronze_etoro_hedge_hbcexecutionlog p
LEFT JOIN main.dealing.bronze_etoro_hedge_hbcorderlog c ON c.ExecutionID = p.ExecutionID
WHERE p.StartTime BETWEEN '2023-08-01' AND '2023-11-07'
GROUP BY p.ExecutionID, p.HedgeID, p.RequestAmountInLots, p.ExecutionAmountInLots,
         p.ExecutionRate, p.LPExecutionRate, p.IsSuccess, p.FailReason;
```

### Pattern 6 — Separate ExposureBalancer from dealing-desk operators (Warning #4)
```sql
SELECT CASE WHEN RequestTypeID = -1 THEN 'ExposureBalancer (auto)' ELSE 'Dealing desk operator' END AS author,
       RequestTypeID, Sender, COUNT(*) AS orders,
       SUM(CASE WHEN IsBuy THEN AmountInUnits ELSE 0 END) AS buy_units,
       SUM(CASE WHEN NOT IsBuy THEN AmountInUnits ELSE 0 END) AS sell_units
FROM main.dealing.bronze_etoro_hedge_manualorderexecutionlog
WHERE ClientSendTime >= CURRENT_DATE() - INTERVAL 30 DAY
GROUP BY 1, RequestTypeID, Sender ORDER BY orders DESC;
```

### Pattern 7 — Hedge failures with severity ranking
```sql
SELECT e.LogTime, e.EMSOrderID, e.InstrumentID, e.FailID, e.FailReason,
       fr.Name AS fail_reason_canonical, fs.Name AS severity
FROM main.dealing.bronze_etoro_hedge_executionlog e
LEFT JOIN main.general.bronze_etoro_dictionary_hedgepositionfailreason fr ON e.FailID = fr.ID
LEFT JOIN main.general.bronze_etoro_dictionary_hedgepositionfailseverity fs ON fr.SeverityID = fs.ID
WHERE e.LogTime >= CURRENT_DATE() - INTERVAL 1 DAY AND e.Success = false
ORDER BY e.LogTime DESC;
```

### Pattern 8 — Live netting position + hedge-server reroutes
```sql
-- (a) Net hedge position for an instrument (live, 60-min)
SELECT LiquidityAccountID, InstrumentID, ValueDate, NetUnits, AvgRate, UnrealizedPnL
FROM main.dealing.bronze_etoro_hedge_netting
WHERE InstrumentID = :instrument_id ORDER BY LiquidityAccountID, ValueDate;

-- (b) Hedge-server reroutes this week (parent + child)
SELECT s.SummaryID, s.StartTime, s.EndTime, COUNT(d.PositionID) AS positions_moved,
       collect_set(d.RuleName) AS reroute_rules, collect_set(d.ToHedgeServerID) AS to_servers
FROM main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog s
LEFT JOIN main.trading.bronze_etoro_trade_positionshedgeserverchangelog d ON d.SummaryID = s.SummaryID
WHERE s.StartTime >= CURRENT_DATE() - INTERVAL 7 DAY
GROUP BY s.SummaryID, s.StartTime, s.EndTime ORDER BY s.StartTime DESC;
```

### Pattern 9 — VeS (Visual Execution Summary) — broker→dealer execution view [Surface B]
```sql
SELECT r.ClientRequestID, r.InstrumentID, r.IsBuy, r.IsOpen, r.RequestType, r.FlowType,
       r.RequestedAmountInUnits, r.RequestedAmountInUSD, r.ClientViewRate, r.RequestTime,
       e.ExecutionID, e.HedgeServerID, e.HedgeExecutionModeID,
       e.ExecutedUnits, e.ExecutionRate, e.ExecutionRateSpreaded,
       (e.ExecutionRateSpreaded - r.ClientViewRate) AS spread_slip_abs,
       e.OrderState, e.OrderStatus, e.FailReason, e.StatusUpdateTime
FROM main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_hedge_request_evh r
JOIN main.dealing.v_bronze_event_hub_prod_event_streaming_we_investigation_tool_execution_result_evh e
  ON e.ClientRequestID = r.EventPayloadRowData_ClientRequestID
WHERE r.EventPayloadRowData_RequestTime >= CURRENT_DATE() - INTERVAL 1 DAY
  AND e.OrderStatus IN ('Filled','Rejected','Cancelled')
  -- HBC slice:  AND e.HedgeExecutionModeID = 1
  -- CBH slice:  AND e.HedgeExecutionModeID = 2
  -- DMA slice:  AND e.HedgeExecutionModeID = 3
  -- Crypto slice: AND e.HedgeServerID IN (81,83)
ORDER BY r.EventPayloadRowData_RequestTime DESC
LIMIT 200;
```
**Use when:** "Show me VeS / ExecSumm for the last day", "HBC failures last hour", "CBH fill rate by LP", "Crypto execution detail for ETH today". This is the **Dealing Investigation Tool Genie's primary lens** — analyst-facing summary of broker request ⨝ dealer result with spreaded-rate slippage already computed. `ClientRequestID` is the broker→dealer bridge column.

### Pattern 10 — VoE (Visual Orders Executions) — drill into a specific ExecutionID [Surface B]
```sql
SELECT o.ExecutionID, o.AccountID, o.InstrumentID, o.IsBuy, o.ProviderUnits, o.OrderID, o.SendTime,
       c.EventPayloadRowData_CalculationName AS calc_name,
       c.EventPayloadRowData_OriginalValue   AS original_value,
       c.EventPayloadRowData_CalculatedValue AS calculated_value,
       c.EventPayloadRowData_OccurredAt      AS calc_at
FROM main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_order_execution_evh o
JOIN main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_calculation_step_evh c
  ON c.EventPayloadRowData_OrderID = o.EventPayloadRowData_OrderID
WHERE o.EventPayloadRowData_ExecutionID = :execution_id            -- ALWAYS scope by ExecutionID (or OrderID)
  AND c.EventPayloadRowData_CalculationSourceType = 'HedgingProviderHost'
ORDER BY c.EventPayloadRowData_OccurredAt;
```
**Use when:** "More ProviderOrder information about ExecutionID X", "What calculations happened inside execution Y?", "VoE / OrderExecSumm". Per the Genie: never run VoE without an `ExecutionID` or `OrderID` — too voluminous. Filter `CalculationSourceType='HedgingProviderHost'` (Warning #15) for the analyst-facing slice.

### Pattern 11 — TTT (FIX Messages) — wire-protocol trail [Surface B]
```sql
-- Bronze (raw) — quick look at the FIX trail by OrderID
SELECT EventPayloadRowData_OrderID  AS order_id,
       EventPayloadRowData_AccountID,
       EventPayloadRowData_AccountName,
       EventPayloadRowData_MessageName,
       EventPayloadRowData_IsIncomingMessage AS is_incoming,
       EventPayloadRowData_MessageTime       AS msg_at,
       EventPayloadRowData_RawFIXMessage     AS raw_fix,
       EventPayloadRowData_JsonFIXMessage    AS json_fix,
       EventPayloadRowData_LiquidityProviderTypeID AS lp_type
FROM main.dealing.bronze_event_hub_prod_event_streaming_we_investigation_tool_fix_message_evh
WHERE EventPayloadRowData_OrderID = :order_id
ORDER BY EventPayloadRowData_MessageTime;

-- Silver (parsed) — for analytical questions across many executions
SELECT EventPayloadRowData_OrderID AS order_id, SendTime, MsgType, ExecType, OrdStatus,
       Symbol, Side, OrderQty, LastQty, LastPx, AvgPx, ExecID, OrigClOrdID, ExecBroker,
       Text AS reject_text
FROM main.dealing.silver_event_hub_prod_event_streaming_we_investigation_tool_fix_message_evh
WHERE etr_ymd = '2026-05-12' AND OrdStatus IN ('8','4')   -- 8=Rejected, 4=Cancelled
ORDER BY SendTime DESC
LIMIT 200;
```
**Use when:** "Show me the FIX trail for this order", "What raw FIX did we send Marex?", "Rejected FIX messages today by ExecBroker". Bronze for forensics by `OrderID`; silver for analytics across many executions (Warning #20).

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
| **Dealing Investigation Tool Genie** | L | 1a + 4 | `knowledge/skills/_genie_cache/01eecfdc6e121d3a9c1551c473de87f5.json` (cached Genie space serialization) + live UC distincts | **Dealing-team-authored** definitions for VeS / ManualVeS / VoE / TTT lenses, `HedgeExecutionModeID` 1/2/3 dictionary, OMS/TOB/REAL_Futures/Business-flow glossary, HedgeServerID 86=DLT marker, `CalculationSourceType='HedgingProviderHost'` filter convention. **Authoritative for HBC/CBH/DMA naming — supersedes Synapse-era expansions.** |
| Surface-B columns (event-hub stack) | L | 4 | `main.information_schema.columns` (live, 2026-05-12) | Column-level detail for the 6 Genie tables + the 2 adjacent tables (`order_log_evh`, `validation_step_evh`) + the parsed `silver_..._fix_message_evh` (175 cols, every FIX tag resolved) + 4 `v_...` view variants. Row counts: 2.4B execution_result view / 1.45B calc_step / 773M hedge_request / 472M fix_message / 154M order_execution / 90M routed_execution. |
| Surface-B live distincts | L | 4 | DBSQL queries against `main.dealing.*` views (live, 2026-05-12) | `HedgeExecutionModeID` distribution (2=CBH 26.3M dominant, 1=HBC 1.15M, 3=DMA 89K, 4=undocumented 72K), HedgeServerID DLT-86 archive range 2024-09-26→2025-10-30, `IsManual` 100% false across 165M historical rows (Warning #13), `OrderStatus` lifecycle distribution, `CalculationSourceType` ERM/ProviderExecutor/HedgingProviderHost split, top FailReasons by volume. |

## Provenance

**v1 (UC table comments only) → v2 (2026-05-11)**: added deep Synapse wikis from `knowledge/ProdSchemas/` for `Hedge.ExecutionLog` / `HBCExecutionLog` / `HBCOrderLog` / `ManualOrderExecutionLog`, the 74-table UC live inventory, Dealer-side classification, dual order-identity paths (Warning #2), HBC archive flag (#9), HBC OrderState ≠ HedgeOrderState (#10), HBC lot rounding (#11), ManualOrderExecutionLog dual population (#4), ABook staleness (#5), 24-col `Hedge.ExecutionLog` reference, 5 SSRS latency metrics + `RateIDAtSent` slippage (#8 + Patterns 4-5), 5-second trailing buffer (#18), `EMSOrderID` collation (#17), 9 dictionary tables, 3 streaming dealing-exposure feeds, `ViewExecutionLog_isnull` view (#16).

**v3 (2026-05-12)** — overweighting the dealing team's **Dealing Investigation Tool Genie** as the authoritative source on current EMS investigation:
- **Two-surface model** introduced. Surface A = Synapse-mirror (Hedge.* schema, ~2.4M rows). Surface B = event-hub stack (`bronze_event_hub_*_investigation_tool_*_evh`, ~2.4B rows on `v_..._execution_result_evh` alone). v2 only covered Surface A; the event-hub stack was previously invisible to the skill.
- **HBC/CBH glossary corrected** (#3 + #6): HBC = "Hedge Before Confirm" (`HedgeExecutionModeID=1`), CBH = "Confirm Before Hedge" (`=2`, dominant 26.3M/mo), DMA = "Direct Market Access" (`=3`). v2 inherited Synapse-wiki "Hedge By Customer / Customer Based Hedging" naming which the Genie contradicts.
- **`HedgeExecutionModeID` + `HedgeServerID` dictionaries** (#6 + #7) — live-verified distributions. Mode 4 (~72K/mo on HedgeServer 500/501/503) is observed but undocumented in the Genie. DLT (HedgeServer 86) is archived 2024-09-26 → 2025-10-30.
- **Four investigation lenses** (VeS / ManualVeS / VoE / TTT) with Genie-canonical join recipes; 3 new Query Patterns (11-13) for VeS, VoE, TTT.
- **`IsManual=true` dead** (#13) — verified 100% false across 165M routed_execution rows. Genie's ManualVeS filter returns zero; route to Surface A `Hedge.ManualOrderExecutionLog`.
- **`OrderStatus` lifecycle dedupe** (#14), **`CalculationSourceType` Genie filter** (#15 — HedgingProviderHost for VoE), **adjacent tables + silver FIX layer surfaced** (#20).
- **Genie glossary baked in**: OMS = Order Management System · TOB = Top of Book · REAL_Futures = DMA into Marex · Business flow = the execution path.
