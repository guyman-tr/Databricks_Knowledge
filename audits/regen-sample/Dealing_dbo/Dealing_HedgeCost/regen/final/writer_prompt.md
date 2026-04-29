# Regen Harness — Writer Prompt

# Regen Harness — Writer (single-object mode)

You are running the DWH Semantic Documentation pipeline on **ONE OBJECT** in
isolated regen-harness mode. This is NOT the normal batch loop. You are NOT
reading `_index.md`, NOT updating any index file, NOT processing other
objects, NOT running cross-schema sync. You document one object end-to-end and
exit.

---

## ⛔ MCP PRE-FLIGHT — MANDATORY

Before reading any rule files or DDL:

1. Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`.
2. **If it fails or the tool does not exist**: print `REGEN ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. A wiki without live data sampling is INCOMPLETE and WILL FAIL the adversarial judge.
3. **If it succeeds**: print `MCP PRE-FLIGHT: PASS` and continue.

No exceptions. No "code-only documentation" fallback. No "I'll skip Phase 2 because the table looks dormant" — the judge sees the dormant footer too and will fail you for missing data evidence.

---

## ⛔ PRE-RESOLVED UPSTREAM CONTEXT — your Tier 1 inheritance source is below, USE IT

The block titled **"## PRE-RESOLVED UPSTREAM BUNDLE"** in this prompt was
assembled **deterministically by the harness, before you started**. It contains:

- The **DDL** for the object you are documenting (verbatim from SSDT).
- Every **upstream wiki** the harness could resolve from the existing
  `.lineage.md` plus DDL-derived references — both local Synapse wikis and
  remote production-DB wikis (DB_Schema, ExperianceDBs, etc.).
- For any stored procedure mentioned in the lineage, the **SP source code**
  pulled from `DataPlatform\SynapseSQLPool1\sql_dp_prod_we\...`.

**Treat this bundle as your AUTHORITATIVE source for Tier 1 inheritance.** You
are NOT permitted to claim "no upstream wiki could be found" if the bundle
contains one. You ARE permitted to read additional files via the `Read` tool
if you need more context.

### Tier rules — re-stated, NON-NEGOTIABLE

For every column in the object:

1. **Passthrough or rename WITH upstream wiki present in the bundle** →
   **Tier 1**. Description MUST be a verbatim quote from the upstream wiki.
   Do not paraphrase. Do not "improve". Do not generalize vendor names. Do not
   drop NULL semantics. The judge will run a character-by-character
   comparison.
2. **ETL-computed** (CASE / arithmetic / aggregation visible in the SP source) →
   **Tier 2** with the transform stated.
3. **Dim-lookup passthrough** (`SELECT dim.X` with no transform AND `Dim_X`
   has its own Tier 1 origin documented in the bundle) → **Tier 1 with the
   dim's origin** (e.g. `Dictionary.Country`), NOT `Tier 2 via SP_X` and NOT
   `Tier 1 via Dim_X` (Dim_X is a relay, not a root). Quote the dim's wiki
   verbatim.
4. **No source traceable from bundle, DDL, JOINs, or SP source** →
   **Tier 3** with explicit reason. Be specific: "PII column, no upstream wiki
   located, name suggests …".
5. **`Tier 4 — inferred from name`** is BANNED unless the bundle explicitly
   shows the column has no upstream and no SP code touches it. Lazy Tier 4 is
   the #1 reason wikis fail the judge. If you are tempted to write Tier 4
   with no other evidence, you have skipped Phase 9 — go back and read the
   SP source in the bundle.

### Footer rules

- If the bundle contains AT LEAST ONE upstream wiki: the footer MUST identify
  the production source(s). Writing `Production Source: Unknown (dormant)`
  when the bundle proves an upstream exists is an automatic fail.
- If `_no_upstream_found.txt` exists in the regen folder: it is OK to mark
  the table as dormant in the footer, but you MUST still ground every column
  description in the DDL + SP code rather than `Tier 4 — inferred`.

---

## Output paths — write here, NOT into the main wiki tree

Write all THREE output files into:

```
audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/
  {Object}.md
  {Object}.lineage.md
  {Object}.review-needed.md
```

`{Schema}`, `{Object}`, and `{N}` are passed in via the prompt header below.

**DO NOT** write into `knowledge/synapse/Wiki/` under any circumstances. The
main tree is read-only for this run. **DO NOT** modify `_index.md` or any
`_batch_context.json`. **DO NOT** generate `.alter.sql`. **DO NOT** run Phase
16 — the adversarial judge runs as a separate, fresh claude process AFTER you
exit. Pretending to evaluate yourself wastes tokens.

---

## Pipeline scope for this single object

Run phases 1 through 11 inclusive. Skip Phase 16. Skip Phase 11W (no ALTER).
Skip cross-object index updates. Skip `_batch_context.json` writes.

Required phase gates (you must print them as you complete each):

```
PHASE GATE — {Schema}.{Object}:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

If a phase truly cannot run (e.g. no SPs reference the table), mark it `[-]`
with a one-line reason. Skipping P2 or P3 because "the table is small" is
NOT a valid reason — sample it.

---

## Outputs — three files, exact shape

Follow the GOLDEN-REFERENCE in
`.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`.

1. **`{Object}.lineage.md`** — written FIRST (Phase 10B). Source Objects
   table + Column Lineage table. Every Tier 1 row must point to a file in the
   pre-resolved bundle (or to a wiki you read independently).
2. **`{Object}.md`** — the main wiki, 8 sections, every column in
   Section 4's Elements table, every description ending with
   `(Tier N — source)`.
3. **`{Object}.review-needed.md`** — items needing human review. MUST NOT
   contain a `## 4. Elements` section.

---

## Final checklist before exiting

Print, verbatim:

```
OUTPUT CHECK — {Schema}.{Object}:
  [x] .lineage.md    written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.lineage.md
  [x] .md            written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.md
  [x] .review-needed.md written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: N    Tier2: N    Tier3: N    Tier4: N
  Bundle inheritance used: YES/NO  (NO is only valid if `_no_upstream_found.txt` exists)
```

Then EXIT. Do not run a self-evaluation. Do not "double-check by re-reading
the wiki you just wrote". Do not append a verdict block. The judge runs in a
separate process with its own context.


---

# Object Header

- **Schema**: `Dealing_dbo`
- **Object**: `Dealing_HedgeCost`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_HedgeCost/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_HedgeCost\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_HedgeCost\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_HedgeCost.sql`

---

# build-wiki-dwh-batch

You are running the DWH Semantic Documentation pipeline for a Synapse DWH schema.
**Wiki-only mode** — generate documentation files only. ALTER scripts are generated separately later via `/generate-alter-dwh`.

## ⛔ MCP PRE-FLIGHT — NON-NEGOTIABLE, CHECK BEFORE ANYTHING ELSE

Before loading rules, before reading the index, before planning anything:

1. **Test Synapse MCP**: Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`
2. **If it fails or the tool does not exist**: Print `BATCH ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. Do NOT proceed. Do NOT fall back to "prior batch context data". Do NOT use a "schema practice" of skipping MCP. A wiki without live data sampling is INCOMPLETE and WILL NOT PASS the adversarial evaluator. STOP HERE.
3. **If it succeeds**: Print `MCP PRE-FLIGHT: PASS` and continue to Instructions.

There is NO exception to this rule. No "prior context", no "code-only documentation", no "graceful degradation". MCP down = batch aborted. Period.

---

## Instructions (regen-harness, single object)

1. **Load rules** — read these in order before anything else:
   - `.cursor/rules/semantic-layer-core/repo-first-access.mdc`
   - `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc`
   - `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`
   - `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`
   - `.cursor/rules/dwh-semantic-doc/10.5b-tier1-enforcement.mdc`

2. **Skip batch planning** — do NOT read `_index.md`, do NOT touch
   `_batch_context.json`, do NOT scan the blacklist. The harness
   already chose this object.

3. **Run the pipeline for THIS object only**: phases 1 through 11
   inclusive. Use the pre-resolved upstream bundle (provided below)
   as your authoritative Tier 1 source. Generate three files in
   `audits/regen-sample/{schema}/{object}/regen/attempt_{N}/`:
   `.lineage.md`, `.md`, `.review-needed.md`. Do NOT generate
   `.alter.sql`. Do NOT modify any file under `knowledge/synapse/Wiki/`.

4. **Skip Phase 16** — the adversarial judge runs in a separate,
   fresh claude process after you exit. Self-evaluation here wastes
   tokens and pollutes the comparison.

5. **Exit cleanly** after printing the OUTPUT CHECK block defined in
   the Regen Harness preamble.

## Key resources

- **SSDT DDL files**: `C:\Users\guyman\Documents\github\DataPlatform\` (repo-first for structure)
- **Upstream wikis (dynamic)**: Load `knowledge/synapse/Wiki/_upstream_wiki_routing.json` for Tier 1 repo locations. Includes DB_Schema, ExperianceDBs, CryptoDBs, BankingDBs, ComplianceDBs, PaymentsDBs and more.
- **DWH upstream wikis**: `knowledge/synapse/Wiki/DWH_dbo/` (for cross-schema references)
- **Dependency graph**: `knowledge/synapse/Wiki/_dependency_order.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

## Batch size reference

| Schema | Batch Size |
|--------|-----------|
| DWH_dbo | 4 |
| BI_DB_dbo | 3 |
| Dealing_dbo | 4 |
| EXW_dbo | 3 |
| eMoney_dbo | 4 |
| Default | 3 |

---

# PRE-RESOLVED UPSTREAM BUNDLE

Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_HedgeCost`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_HedgeCost.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_HedgeCost]
(
	[Date] [date] NULL,
	[InstrumentID] [int] NULL,
	[Name] [varchar](50) NULL,
	[IsSettled] [varchar](20) NULL,
	[Clients_Units] [decimal](16, 6) NULL,
	[AvgRateClientsNoSpread] [decimal](16, 6) NULL,
	[VolumeMarket] [decimal](16, 6) NULL,
	[LP_Executed_Units] [decimal](16, 6) NULL,
	[LP_Avg_Rate] [decimal](16, 6) NULL,
	[LP_Volume] [decimal](16, 6) NULL,
	[HC] [decimal](16, 6) NULL,
	[UpdateDate] [datetime] NULL,
	[HedgeServerID] [int] NULL,
	[FullCommission] [decimal](16, 6) NULL,
	[VariableSpread] [decimal](16, 6) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Date] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 8 upstream wiki(s). Read EACH one in full.


### Upstream `etoro.Hedge.ExecutionLog` — production
- **Resolved as**: `etoro.Hedge.ExecutionLog`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Hedge\Tables\Hedge.ExecutionLog.md`

# Hedge.ExecutionLog

> High-volume append-only log of every hedge order execution event - each row captures a single state transition (sent, partial fill, fill, reject, cancel) from a liquidity provider, enabling fill rate analysis, latency measurement, and execution discrepancy detection.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | No PK. CLUSTERED index on LogTime (time-ordered append log) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED on LogTime + NC on LiquidityAccountID, LogTime DESC, Success, OrderID) - both FILLFACTOR=95 |

---

## 1. Business Meaning

Hedge.ExecutionLog is the central execution audit trail for the eToro hedge system. Every time a hedge order changes state - when it is sent to the liquidity provider, when it receives a partial fill, when it is fully filled, rejected, or cancelled - a row is written to this table. Each row is a snapshot of the order's state at a specific moment in time; multiple rows can exist for the same order as it progresses through its lifecycle.

The table holds 2,374,781 rows spanning 2023-01-04 to 2026-03-19 and is actively written. 69% of rows are successful executions; 31% are rejections or failures - typical for a high-frequency hedge execution environment where partial fills and re-routing are common.

Unlike most log tables, Hedge.ExecutionLog has **no primary key constraint** - it relies solely on a clustered index on LogTime for physical ordering. This is an intentional design for a high-write append-only table where uniqueness is not enforced at the DB level. The hedge server generates unique identifiers (OrderID/EMSOrderID) that serve as logical identifiers.

The table supports two execution flows:
- **Legacy/HedgeServer flow**: OrderID is the internal hedge order ID (bigint > 0), ParentOrderID is a GUID
- **EMS (Execution Management System) / HBC flow**: OrderID = -1, EMSOrderID is the key identifier in format `{ExternalID}_{sequence}` (e.g., "35564138_1")

---

## 2. Business Logic

### 2.1 Order State Lifecycle

**What**: Each row represents one state transition in an order's lifecycle. An order may generate multiple rows.

**Columns/Parameters Involved**: `OrderID`, `OrderState`, `Success`, `FailID`, `FailReason`

**Rules**:
- OrderState FK to Dictionary.HedgeOrderState (WITH NOCHECK - existing rows not re-validated):

| ID | Name | Count | Success |
|---|---|---|---|
| 0 | None | - | - |
| 1 | Sent | 0 (not observed) | - |
| 2 | New | 150,367 | mixed |
| 3 | Partial | 1,040,923 | mixed |
| 4 | Fill | 455,368 | 1 |
| 5 | Reject | 727,763 | 0 |
| 6 | Fail | 0 (not observed) | 0 |
| 7 | Cancelled | 360 | - |

- A typical fill sequence: OrderState=2 (New - order acknowledged), then one or more OrderState=3 (Partial fill), then OrderState=4 (Full fill) OR OrderState=5 (Reject).
- Success=1 for fills (OrderState=4); Success=0 for rejects (OrderState=5).
- FailID and FailReason are populated for failed/rejected orders: FailID is a numeric error code; FailReason is a varchar description from the provider.
- **No PK**: Multiple rows per order are expected and intentional. The table is a timeline of state transitions, not a current-state snapshot.

### 2.2 EMS vs Legacy Order Identification

**What**: Two different order identification schemes coexist in the table depending on which execution pathway generated the order.

**Columns/Parameters Involved**: `OrderID`, `ParentOrderID`, `EMSOrderID`, `OMSProviderOrderID`, `OMSProviderExecID`

**Rules**:
- **Legacy/HedgeServer path**: `OrderID` > 0 (e.g., the internal hedge order ID from Trade.HedgeOrders); `ParentOrderID` is the parent hedge order GUID; `EMSOrderID` is NULL.
- **EMS/HBC path**: `OrderID` = -1; `ParentOrderID` = GUID(0) (00000000-...); `EMSOrderID` = "{ExternalID}_{sequence}" string key; `OMSProviderOrderID` and `OMSProviderExecID` are present for OMS-routed orders (NULL for direct EMS).
- The SSRS_Latency_Report joins this table to EMS orders via `EMSOrderID COLLATE Latin1_General_BIN` (binary collation match needed for case-sensitive comparison).
- GetExecutionLogData queries by `EMSOrderID` to get aggregated partial fills for an EMS order.

### 2.3 Execution Latency Chain

**What**: Multiple timestamps capture each phase of the execution latency, enabling end-to-end measurement.

**Columns/Parameters Involved**: `LogTime`, `SendTime`, `ReceivedTime`, `ExecutionTime`

**Rules**:
- `LogTime` = GETUTCDATE() at DB insert (set by LogExecution and ExecutionLogInsertBulk procedures). DB server time; measures logging lag.
- `SendTime` = datetime2(7) when the order was sent to the liquidity provider. Set by the calling application.
- `ReceivedTime` = datetime2(7) when the execution response was received from the provider.
- `ExecutionTime` = datetime2(7) from the provider's own timestamp confirming the execution.
- Latency calculations used in SSRS_Latency_Report:
  - Metric 1: `DATEDIFF(ms, RequestTime, SendTime)` = Request processing time (CES/HBS to first order send)
  - Metric 2: `DATEDIFF(ms, SendTime, ReceivedTime)` = Provider round-trip latency (market response time)
  - Metric 3: `DATEDIFF(ms, ReceivedTime, StatusUpdateTime)` = Response processing time (received to status update)
  - Metric 4: Metric1 + Metric3 = Total internal latency (excluding provider market time)
  - Metric 5: Execution throughput (orders per second per LiquidityAccount)

### 2.4 Partial Fill Aggregation

**What**: GetExecutionLogData aggregates partial fills for an EMS order to compute total executed units and average rate.

**Columns/Parameters Involved**: `EMSOrderID`, `OrderState`, `Units`, `ExecutionRate`, `LogTime`

**Rules**:
- Filter: `OrderState = 3` (Partial fills only) + `EMSOrderID` match + time window
- Returns: `SUM(Units)` as TotalExecutedUnits; `SUM(Units * ExecutionRate) / SUM(Units)` as volume-weighted average execution rate
- `LogTime BETWEEN @FromDate AND DATEADD(SECOND, -5, @ToDate)` - 5-second trailing buffer prevents reading race-condition rows from concurrent inserts
- This pattern is used by the EMS system to reconcile partial fill sequences against the expected total.

### 2.5 Provider Identifiers

**What**: The table tracks both eToro-side and provider-side identifiers for cross-system reconciliation.

**Columns/Parameters Involved**: `ProviderOrderID`, `ProviderExecID`, `ProviderPartyIds`, `RateIDAtSent`

**Rules**:
- `ProviderOrderID` (varchar 50): The order ID assigned by the liquidity provider (GUID format for FIX-based providers like ZBFX).
- `ProviderExecID` (varchar 50): The execution confirmation ID from the provider. Populated on fill/partial fill.
- `ProviderPartyIds` (varchar 50): FIX party identifiers (e.g., clearing firm, broker IDs) from the execution report.
- `RateIDAtSent` (bigint): The ID of the price rate snapshot that was active when the order was sent. Used for slippage analysis: comparing the rate sent vs. the rate received.

---

## 3. Data Overview

2,374,781 rows | Active table (2023-01-04 to 2026-03-19 in this environment)

| LogTime | HedgeServerID | LiquidityAccountID | InstrumentID | OrderID | IsBuy | OrderState | Success | Units | ProviderUnits | EMSOrderID | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-03-19 00:04:47 | 2 | 8 | 1008 | -1 | false | 4 (Fill) | true | 6 | 6 | "35564138_1" | EMS order fully filled - 6 units of InstrumentID 1008 sold via LiquidityAccount 8. |
| Recent typical | 2 | 8 | varies | -1 | false | 3 (Partial) | true | N | N | "{ID}_{seq}" | Partial fill in a multi-fill sequence. SUM'd by GetExecutionLogData for weighted avg rate. |
| Historical | varies | varies | varies | >0 | varies | 5 (Reject) | false | N | null | null | Legacy HedgeServer order rejected. FailReason explains the provider's reason. |

**Distribution summary**:
- OrderState=3 (Partial) = 44% of rows - dominant state in partial-fill heavy execution model
- OrderState=5 (Reject) = 31% of rows - typical for institutional execution (rejects trigger re-routing)
- Success=true: 69% | Success=false: 31%
- All recent active rows use HedgeServerID=2, LiquidityAccountID=8 (EMS path with OrderID=-1)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogTime | datetime2(7) | NO | - | CODE-BACKED | DB server UTC timestamp at row insert, set to GETUTCDATE() by LogExecution and ExecutionLogInsertBulk. Clustered index key - rows are physically ordered by log insert time. Used as the primary range filter for all time-window queries. |
| 2 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). The hedge server that generated and sent this execution order to the provider. |
| 3 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity provider account on which this order was executed. Used as a grouping key in the NC index and latency reports. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. |
| 5 | OrderID | bigint | NO | - | CODE-BACKED | Internal hedge order identifier. Legacy path: positive bigint matching the hedge order system. EMS/HBC path: -1 (not applicable - EMSOrderID is the key instead). Not the OrderID from Trade.OpenedPositions - this is the hedge system's own order tracking ID. |
| 6 | ParentOrderID | uniqueidentifier | NO | - | CODE-BACKED | GUID identifying the parent hedge order that spawned this execution. EMS path: GUID(0) (all zeros = no parent). Legacy path: the parent hedge order GUID. |
| 7 | IsBuy | bit | NO | - | CODE-BACKED | Direction of the hedge order from eToro's perspective: 1=Buy, 0=Sell. A hedge order direction is typically the opposite of the customer net position. |
| 8 | OrderState | smallint | NO | - | CODE-BACKED | FK to Dictionary.HedgeOrderState (WITH NOCHECK). Current state of this order row: 0=None, 1=Sent, 2=New, 3=Partial, 4=Fill, 5=Reject, 6=Fail, 7=Cancelled. One order generates multiple rows as it transitions through states. |
| 9 | ProviderOrderID | varchar(50) | YES | - | CODE-BACKED | The order ID assigned by the liquidity provider (typically a GUID from FIX protocol). Populated when the provider acknowledges the order (OrderState >= 2). Used for reconciliation with provider statements. |
| 10 | SendTime | datetime2(7) | YES | - | CODE-BACKED | Precision timestamp when the order was dispatched to the liquidity provider. Used for Metric 1 (Request_Process_Time = RequestTime to SendTime) in latency analysis. |
| 11 | ProviderExecID | varchar(50) | YES | - | CODE-BACKED | Execution confirmation ID from the liquidity provider (GUID format). Populated on fill or partial fill (OrderState 3/4). Used for trade reconciliation and dispute resolution with the provider. |
| 12 | ExecutionTime | datetime2(7) | YES | - | CODE-BACKED | The provider's own timestamp for when the execution occurred. May differ from ReceivedTime due to network latency. Used as the authoritative trade timestamp for P&L calculations. |
| 13 | ExecutionRate | dbo.dtPrice | YES | - | CODE-BACKED | The actual execution price returned by the liquidity provider. Used in weighted average rate calculation: SUM(Units * ExecutionRate) / SUM(Units) by GetExecutionLogData. |
| 14 | FailID | int | YES | - | CODE-BACKED | Numeric error/failure code from the provider or internal routing system. Populated when Success=0. Used for categorizing reject reasons in monitoring. |
| 15 | FailReason | varchar(250) | YES | - | CODE-BACKED | Free-text rejection reason from the provider. Populated when Success=0. Typical reasons include price stale, no liquidity, size exceeded, connection failure. |
| 16 | Success | bit | NO | - | CODE-BACKED | Indicates whether this execution event represents a successful outcome: 1=successful fill or partial fill; 0=rejection or failure. Used as a filter key in the NC index and fill rate calculations. |
| 17 | ProviderPartyIds | varchar(50) | YES | - | CODE-BACKED | FIX protocol party identifiers from the execution report (e.g., clearing firm, broker, settlement IDs). Populated for providers using FIX party tags. |
| 18 | ReceivedTime | datetime2(7) | YES | - | CODE-BACKED | Precision timestamp when the hedge server received the execution response from the provider. Metric 2 = DATEDIFF(ms, SendTime, ReceivedTime) = Provider round-trip latency. |
| 19 | RateIDAtSent | bigint | YES | - | CODE-BACKED | ID of the price rate snapshot that was active when the order was sent. Used for slippage analysis by comparing execution rate vs. rate at send time. NULL for EMS orders where rate tracking uses a different mechanism. |
| 20 | OMSProviderExecID | varchar(50) | YES | - | CODE-BACKED | OMS (Order Management System) execution confirmation ID. Populated for OMS-routed orders. NULL for direct EMS orders (OrderID=-1 in recent data). |
| 21 | OMSProviderOrderID | varchar(50) | YES | - | CODE-BACKED | OMS order ID for orders routed through the OMS layer. NULL for direct EMS orders. Enables reconciliation with OMS-side execution records. |
| 22 | Units | decimal(22,8) | YES | - | CODE-BACKED | The quantity of units requested in the hedge order. High precision (22,8) to support both large quantities and fractional instruments (crypto). |
| 23 | ProviderUnits | decimal(22,8) | YES | - | CODE-BACKED | The quantity actually executed by the provider in this event. For partial fills, ProviderUnits < Units. Sum of ProviderUnits across all OrderState=3 rows for an order gives total filled. |
| 24 | EMSOrderID | varchar(50) | YES | - | CODE-BACKED | EMS (Execution Management System) order identifier. Format: "{ExternalID}_{sequence}" (e.g., "35564138_1"). The primary key for EMS/HBC flow orders (when OrderID=-1). Used as the join key in SSRS_Latency_Report and by GetExecutionLogData for partial fill aggregation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (WITH NOCHECK) | FK_ExecutionLog_HedgeServer |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (WITH NOCHECK) | FK_ExecutionLog_LiquidityAccounts |
| OrderState | Dictionary.HedgeOrderState | FK (WITH NOCHECK) | FK_ExecutionLog_HedgeOrderState - state classification |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being hedged |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.LogExecution | - | Writer | Single-row insert for one execution event |
| Hedge.ExecutionLogInsertBulk | @ExecutionLogData TVP | Writer | Bulk insert via Hedge.ExecutionLogTableType TVP |
| Hedge.GetExecutionLogData | EMSOrderID | Reader | Aggregates partial fills (OrderState=3) for EMS order reconciliation |
| Hedge.SSRS_Latency_Report | OrderID / EMSOrderID | Reader | Computes 5 latency metrics (P90/P99) per LiquidityAccount for SSRS reporting |
| Hedge.GetHBCEstimationsDiscrepencies* | OrderID | Reader | HBC discrepancy analysis (4 variants) |
| Hedge.GetLastOrderID | OrderID | Reader | Returns the most recent OrderID for a hedge server |
| Hedge.InsertKPIData | EventType=8 check | Reader | Dedup check using EventLog (not ExecutionLog directly, but referenced in same proc) |
| Hedge.ViewExecutionLog_isnull | - | Reader | View over this table |
| Hedge.ListUnsupportedInstruments | - | Reader | Identifies instruments with recent failures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionLog (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - FK: Trade.LiquidityAccounts (LiquidityAccountID)
  - FK: Dictionary.HedgeOrderState (OrderState)
  - Implicit: Trade.Instrument (InstrumentID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |
| Dictionary.HedgeOrderState | Table | FK target for OrderState (8 states: None through Cancelled) |
| dbo.dtPrice | User Defined Type | ExecutionRate column type |
| Hedge.ExecutionLogTableType | User Defined Type | TVP type for ExecutionLogInsertBulk |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.LogExecution | Procedure | Primary single-row writer |
| Hedge.ExecutionLogInsertBulk | Procedure | Bulk writer via TVP |
| Hedge.GetExecutionLogData | Procedure | Aggregates partial fills by EMSOrderID |
| Hedge.SSRS_Latency_Report | Procedure | End-to-end latency reporting (P90/P99 per liquidity account) |
| Hedge.GetHBCEstimationsDiscrepencies | Procedure (x4) | HBC execution discrepancy analysis |
| Hedge.GetLastOrderID | Procedure | Returns max OrderID |
| Hedge.ViewExecutionLog_isnull | View | View wrapper with ISNULL handling |
| Hedge.ListUnsupportedInstruments | Procedure | Failed execution instrument analysis |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX_LogTime | CLUSTERED | LogTime ASC | - | - | Active (FILLFACTOR=95, PAGE compression) |
| IDX_HedgeExecutionLog_LogTime | NONCLUSTERED | LiquidityAccountID ASC, LogTime DESC, Success ASC, OrderID ASC | - | - | Active (FILLFACTOR=95, MAIN filegroup) |

**Design notes**:
- No PK constraint - the table is intentionally heap-like (append-only log). The clustered index on LogTime provides time-ordered physical storage for range queries.
- NC index on (LiquidityAccountID, LogTime DESC, Success, OrderID) supports per-account fill rate queries and the account-scoped portions of latency reports.
- Both indexes use FILLFACTOR=95 (95% page fill) to accommodate appends without excessive page splits.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_ExecutionLog_HedgeOrderState | FOREIGN KEY (WITH NOCHECK) | OrderState -> Dictionary.HedgeOrderState(ID) |
| FK_ExecutionLog_HedgeServer | FOREIGN KEY (WITH NOCHECK) | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_ExecutionLog_LiquidityAccounts | FOREIGN KEY (WITH NOCHECK) | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |

**WITH NOCHECK**: All three FKs are defined WITH NOCHECK, meaning existing rows are not validated against the FK targets. This was likely done for performance when the FKs were added to an already-populated table.

---

## 8. Sample Queries

### 8.1 Fill rate by liquidity account (last 24 hours)
```sql
SELECT LiquidityAccountID,
       COUNT(1) AS TotalEvents,
       SUM(CASE WHEN OrderState = 4 THEN 1 ELSE 0 END) AS Fills,
       SUM(CASE WHEN OrderState = 5 THEN 1 ELSE 0 END) AS Rejects,
       CAST(SUM(CASE WHEN OrderState = 4 THEN 1.0 ELSE 0 END) / NULLIF(COUNT(1),0) AS decimal(5,2)) AS FillRate
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE LogTime > DATEADD(day, -1, GETUTCDATE())
GROUP BY LiquidityAccountID
ORDER BY LiquidityAccountID;
```

### 8.2 Trace a single EMS order's fill sequence
```sql
SELECT LogTime, OrderState, Success, Units, ProviderUnits, ExecutionRate,
       FailReason, ReceivedTime, SendTime
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE EMSOrderID = '35564138_1'
ORDER BY LogTime;
```

### 8.3 Provider round-trip latency (SendTime to ReceivedTime) - last hour fills
```sql
SELECT LiquidityAccountID,
       AVG(DATEDIFF(MILLISECOND, SendTime, ReceivedTime)) AS AvgLatencyMs,
       MAX(DATEDIFF(MILLISECOND, SendTime, ReceivedTime)) AS MaxLatencyMs,
       COUNT(1) AS FillCount
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE LogTime > DATEADD(hour, -1, GETUTCDATE())
  AND OrderState = 4
  AND SendTime IS NOT NULL AND ReceivedTime IS NOT NULL
GROUP BY LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for Hedge.ExecutionLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionLog.sql*


### Upstream `DWH_dbo.Dim_Instrument` — synapse
- **Resolved as**: `DWH_dbo.Dim_Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`

# DWH_dbo.Dim_Instrument

> Comprehensive instrument dimension table covering all 15,700+ tradeable assets on the eToro platform -- combining core trade pair definitions (buy/sell currencies), display metadata, financial fundamentals, futures configuration, and platform classification into a single analytics-ready reference.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.GetInstrument (view) + Trade.InstrumentMetaData + Trade.ProviderToInstrument + StockInfo + FuturesMetaData |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **UC Format** | delta |
| **UC Partitioned By** | None (15K rows; suggest Z-ORDER on InstrumentID) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Instrument` is the DWH's master reference for all tradeable instruments on the eToro platform. It extends the foundational trade pair definition from `Trade.Instrument` (which specifies the buy/sell currency pairing for each instrument) with rich analytics metadata: display names and company info from `Trade.InstrumentMetaData`, trading configuration from `Trade.ProviderToInstrument`, financial market data (market cap, ADV, shares outstanding) from the Rankings/StockInfo system, Bloomberg-style asset classification, and futures-specific parameters. The result is a 47-column analytics hub that serves as the primary instrument lookup for fact table enrichment across DWH analytics.

The production source is `etoro.Trade.GetInstrument` (a view on the production etoroDB-REAL server), which combines `Trade.Instrument` with multiple related tables. The Generic Pipeline exports this view daily to `Bronze/etoro/Trade/GetInstrument/` (UC: `trading.bronze_etoro_trade_getinstrument`). The DWH ETL SP (`SP_Dim_Instrument`) then joins this staging data with six additional staging tables to produce the full 47-column Dim_Instrument. Post-load UPDATE statements enrich price-server tracking, asset classification, and financial fundamentals. Source: upstream wiki available at `Trade/Tables/Trade.Instrument.md` (quality 9.1/10).

The ETL is a full TRUNCATE + INSERT + multiple UPDATEs, running daily with a `@dt` date parameter. `UpdateDate` and `InsertDate` are both set to `GETDATE()` at load time and do NOT reflect production modification times. The SP ends by calling `SP_Dim_Instrument_Snapshot @dt` to update the `Dim_Instrument_Snapshot` table (daily snapshot of futures configuration columns). As of 2026-03-19, the table contains 15,707 rows: 82% Stocks, 8% ETFs, 4% Crypto, 3% Commodities, 2% Indices, 1% Currencies.

---

## 2. Business Logic

### 2.1 Buy/Sell Currency Pairing

**What**: Every instrument is defined as a pair of assets from `Dictionary.Currency`/`Dim_Currency`. The pairing determines how prices are quoted, how positions are settled, and how P&L is converted to account currency.

**Columns Involved**: `BuyCurrencyID`, `SellCurrencyID`, `BuyCurrency`, `SellCurrency`

**Rules**:
- For **forex pairs**: BuyCurrencyID is the base currency, SellCurrencyID is the quote currency (e.g., InstrumentID=1: EUR/USD = BuyCurrencyID=2/EUR, SellCurrencyID=1/USD)
- For **stocks/ETFs/crypto**: BuyCurrencyID equals the asset's own InstrumentID in Dim_Currency, and SellCurrencyID is the denomination currency (USD for US stocks, EUR for European stocks, GBX for UK pence-quoted stocks)
- `BuyCurrency` and `SellCurrency` are DWH-added text abbreviations (denormalized from Dictionary.Currency via SP JOIN)
- InstrumentID=0: system/ETL null-sentinel record with all zero/NA values

**Diagram**:
```
Forex:  ID=1  -> Buy=EUR(2)  / Sell=USD(1)   = EUR/USD pair
Stock:  ID=1001 -> Buy=AAPL(1001) / Sell=USD(1) = Apple in USD
EuroSt: ID=1203 -> Buy=Bayer(1203) / Sell=EUR(2) = Bayer AG in EUR
Crypto: ID=XXXX -> Buy=BTC(?) / Sell=USD(1)     = Bitcoin in USD
```

### 2.2 InstrumentType and IsMajor Dual Representation

**What**: Two DWH-specific computed/reformatted columns encode enum values as human-readable text.

**Columns Involved**: `InstrumentTypeID`, `InstrumentType`, `IsMajorID`, `IsMajor`

**Rules**:
- `InstrumentType` is CASE-computed in the SP from `InstrumentTypeID`: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Note: type IDs 3, 7, 8, 9 are not defined (gap exists for historical reasons)
- `IsMajorID` = production `IsMajor` bit value (0 or 1). `IsMajor` = text version ('Yes' or 'No'). Analysts should use `IsMajorID` for filtering, `IsMajor` for display
- IsMajor=Yes: 6,963 instruments (major forex + popular stocks/ETFs). IsMajor=No: 8,743 instruments
- DWHInstrumentID always equals InstrumentID (redundant copy, same as the DWHXxxID pattern across all DWH Dim tables)
- StatusID is hardcoded to 1 for all real rows (ETL artifact; NULL only for ID=0 placeholder)

### 2.3 IsFuture Derivation and Futures Columns

**What**: Futures instruments are identified by membership in InstrumentGroups(GroupID=25), and carry additional configuration columns not present for non-futures instruments.

**Columns Involved**: `IsFuture`, `Multiplier`, `ProviderMarginPerLot`, `eToroMarginPerLot`, `SettlementTime`

**Rules**:
- `IsFuture = 1` when the instrument is a member of `DWH_staging.etoro_Trade_InstrumentGroups` with `GroupID=25`. Computed via CASE in SP_Dim_Instrument.
- `Multiplier`: contract size multiplier from `Trade.FuturesMetaData`. NULL for non-futures.
- `ProviderMarginPerLot`: initial margin requirement from the liquidity provider, from `Trade.FuturesInstrumentsInitialMarginByProviderMapping`. NULL for non-futures.
- `eToroMarginPerLot`: eToro's own margin per lot (in asset currency) from `Trade.ProviderToInstrument.InitialMarginInAssetCurrency`. NULL for non-futures.
- `SettlementTime`: daily/weekly settlement time from `Trade.ProviderToInstrument`, formatted as TIME(0) by the SP.

### 2.4 Financial Fundamentals (Post-Load Updates)

**What**: Market data columns are populated via post-load UPDATE statements joining to the Rankings/StockInfo data lake.

**Columns Involved**: `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `AssetClass`, `IndustryGroup`, `PlatformSector`, `PlatformIndustry`

**Rules**:
- `ADV_Last3Months`: Average Daily Volume over last 3 months (MetadataID=8557). NULL for non-stock instruments or instruments without Rankings data.
- `MKTcap`: Market Capitalization in USD (MetadataID=8735 for stocks, fallback to MetadataID=9315 CryptoMarketCap for crypto). NULL if not covered by Rankings.
- `SharesOutStanding`: Total shares outstanding in units (MetadataID=8444). Stocks only.
- `AssetClass` / `IndustryGroup`: Bloomberg-style classification from `Ext_Dim_Instrument_Classification_Static`. More granular than InstrumentType.
- `PlatformSector` / `PlatformIndustry`: eToro platform taxonomy (MetadataID=8436/8280), may differ from Bloomberg AssetClass/IndustryGroup.
- `ReceivedOnPriceServer`: First date/time an instrument was seen on the price server. POST-LOAD from `Ext_Dim_Instrument_ReceivedOnPriceServerStatic`. NULL for instruments not yet priced.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (all 15,707 rows available on every compute node) with a CLUSTERED INDEX on `InstrumentID`. Since virtually every fact table JOINs to `Dim_Instrument` on `InstrumentID`, replication eliminates shuffle overhead. The clustered index supports range scans and direct lookups efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export is pending write-objects configuration. At 15,707 rows, partitioning is not beneficial -- suggest Z-ORDER on `InstrumentID` for join performance, and `InstrumentTypeID` for type-filtered analytics.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get instrument name and type by ID | `JOIN Dim_Instrument ON InstrumentID; SELECT Name, InstrumentType` |
| Find all major instruments by asset class | `WHERE IsMajorID = 1 AND AssetClass = 'Technology'` |
| Find instruments eligible for long/short | `WHERE AllowBuy = 1 AND AllowSell = 1 AND Tradable = 1` |
| Get market cap for a position | `JOIN Dim_Instrument ON InstrumentID; SELECT MKTcap` |
| Find futures instruments with settlement | `WHERE IsFuture = 1 AND SettlementTime IS NOT NULL` |
| Find US stocks with ISIN | `WHERE InstrumentTypeID = 5 AND ISINCountryCode = 'US' AND ISINCode IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.BuyCurrencyID` | Resolve buy-side currency/asset details |
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.SellCurrencyID` | Resolve sell-side denomination currency |
| DWH_dbo.Dim_HistorySplitRatio | `ON InstrumentID + date range` | Get split adjustment ratios for historical price normalization |
| DWH_dbo.Dim_Instrument_Snapshot | `ON InstrumentID + DateID` | Get point-in-time futures config for historical analysis |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `ON InstrumentID` | Join to price history |

### 3.4 Gotchas

- **InstrumentID=0 is the null-sentinel placeholder**: All fields are 0/NA/NULL. Always filter `WHERE InstrumentID > 0` for analytics.
- **DWHInstrumentID always equals InstrumentID**: This is a redundant copy column -- do not use it as a distinct identifier.
- **StatusID is hardcoded 1**: This column conveys no information (all rows = 1 except the ID=0 placeholder). Do not filter on it.
- **UpdateDate and InsertDate are both ETL timestamps**: Neither reflects when the instrument was created or last modified in production. They reflect the last ETL run (daily, ~midnight).
- **InstrumentType gaps**: TypeIDs 3, 7, 8, 9 are not used. The CASE expression returns 'Other' for any unmapped typeID.
- **IsMajorID vs IsMajor**: Use `IsMajorID` (int 0/1) for WHERE/GROUP BY. Use `IsMajor` ('Yes'/'No') for display only.
- **NULL fundamentals**: ADV_Last3Months, MKTcap, SharesOutStanding are NULL for non-stock instruments and for instruments not covered by Rankings data. Always use LEFT JOIN or ISNULL() when using these for aggregations.
- **AllowBuy/AllowSell = 0 means trading disabled**: Instruments with AllowBuy=0 cannot be opened in the specified direction. This changes dynamically in production but is updated daily in DWH.
- **Dim_Instrument vs Dim_Currency**: Dim_Currency (from Dictionary.Currency) is the master asset registry with type and currency info. Dim_Instrument (from Trade.Instrument) is the trading pair definition with full analytics enrichment. For basic instrument lookups, Dim_Currency suffices. For trading parameters, fundamentals, or pair analysis, use Dim_Instrument.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, Trade.Instrument)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dim_Instrument)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 2 | InstrumentTypeID | int | NO | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%. (Tier 2 -- SP_Dim_Instrument) |
| 3 | InstrumentType | varchar(50) | NO | Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 -- SP_Dim_Instrument) |
| 4 | Name | varchar(50) | NO | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 5 | DWHInstrumentID | int | NO | Always equal to InstrumentID -- redundant copy following the DWH DWH{X}ID pattern. Use InstrumentID for all JOINs. (Tier 2 -- SP_Dim_Instrument) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all real rows by SP_Dim_Instrument. NULL only for ID=0 placeholder. Conveys no business information. (Tier 2 -- SP_Dim_Instrument) |
| 7 | BuyCurrencyID | int | NO | The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks). (Tier 1 -- upstream wiki, Trade.Instrument) |
| 8 | SellCurrencyID | int | NO | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 9 | BuyCurrency | varchar(50) | NO | Text abbreviation of BuyCurrencyID -- denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: EUR, AAPL, BTC. DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 10 | SellCurrency | varchar(50) | NO | Text abbreviation of SellCurrencyID -- denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 11 | TradeRange | int | NO | Allowed trade range in pips for pending orders. Determines how far from market price a limit/stop order can be placed. Set during instrument creation. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 12 | DollarRatio | numeric(18,0) | NO | Price scaling factor for USD normalization. Most instruments = 1. JPY pairs = 100 (because JPY is quoted at 100x the numeric value of other currencies). Used in P&L and conversion rate calculations across the platform. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 13 | PipDifferenceThreshold | bigint | YES | Maximum allowed pip difference threshold for price validation. If a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. NULL for some instruments. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 14 | IsMajorID | int | NO | Integer representation of the production IsMajor flag (0 or 1). 1=major instrument (6,963 instruments -- all major forex pairs and many popular stocks). 0=non-major (8,743 instruments). Renamed from production IsMajor to distinguish from the text version. Use for filtering. (Tier 2 -- SP_Dim_Instrument) |
| 15 | IsMajor | varchar(3) | NO | Text version of IsMajorID -- DWH CASE computed: IsMajorID=1->'Yes', 0->'No'. Use for display. Affects spread calculations and regulatory leverage caps (ESMA allows higher leverage for major forex). (Tier 2 -- SP_Dim_Instrument) |
| 16 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument on each daily reload. Does NOT reflect production modification date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 17 | InsertDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument, same as UpdateDate. Both reflect the daily load time. Does NOT reflect production insertion date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 18 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 19 | Industry | varchar(max) | YES | Industry classification string from Trade.InstrumentMetaData. Text description (e.g., 'Internet', 'Software'). Similar to but may differ from IndustryGroup (Bloomberg). NULL for non-stock instruments or instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 20 | CompanyInfo | varchar(max) | YES | Free-text company description from Trade.InstrumentMetaData. May contain multi-sentence business descriptions of the company. NULL for non-company instruments (forex, commodities, indices). (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 21 | Exchange | varchar(max) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 22 | ISINCode | varchar(30) | YES | International Securities Identification Number -- 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 23 | ISINCountryCode | varchar(15) | YES | Country code prefix from the ISIN (first 2 characters). Indicates the country of registration (e.g., US, DE, GB). NULL when ISINCode is NULL. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 24 | Tradable | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. CAST from production bit. NULL for ID=0 placeholder. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 25 | Symbol | varchar(100) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. NULL for ID=0 placeholder and some instruments without formal ticker. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 26 | ReceivedOnPriceServer | datetime | YES | First timestamp when the instrument was observed on the price server (from Ext_Dim_Instrument_ReceivedOnPriceServerStatic). Set once and never updated (static history). NULL for instruments not yet priced or newly added instruments that have not yet appeared in price feeds. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 27 | BonusCreditUsePercent | int | YES | Percentage of bonus credit that can be applied to trading this instrument, from Trade.ProviderToInstrument. Lower values restrict bonus usage for high-risk/volatile instruments. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 28 | SymbolFull | varchar(100) | YES | Full ticker symbol (may be longer than Symbol), from Trade.InstrumentMetaData. Used for data provider integrations that require fully qualified symbols. NULL for instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 29 | CUSIP | varchar(500) | YES | Committee on Uniform Securities Identification Procedures number -- 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments and instruments without CUSIP. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentCusip) |
| 30 | Precision | int | YES | Decimal precision for price display and trading (number of decimal places), from Trade.ProviderToInstrument. Determines how many decimals are shown in the UI and used in calculations. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 31 | AllowBuy | int | YES | Flag indicating if long (buy) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Instruments may be buy-disabled due to regulatory restrictions, risk management, or market conditions. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 32 | AllowSell | int | YES | Flag indicating if short (sell) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Many regulated markets prohibit short selling for retail clients. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 33 | AssetClass | nvarchar(400) | YES | Bloomberg-style asset class classification from Ext_Dim_Instrument_Classification_Static (e.g., Technology, Consumer Services, Finance). More granular than InstrumentType. NULL for non-stock instruments or instruments not in the classification static table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 34 | IndustryGroup | nvarchar(400) | YES | Bloomberg-style industry group within AssetClass (e.g., Computers, Internet, Banks). Sub-classification of AssetClass. NULL for non-stock instruments or instruments not in the classification table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 35 | ADV_Last3Months | numeric(20,4) | YES | Average Daily Trading Volume over the trailing 3 months (TTM), from Rankings StockInfo MetadataID=8557. In shares/units. NULL for non-stock instruments or instruments without Rankings coverage. Example: Apple ~48M shares/day. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 36 | MKTcap | numeric(20,4) | YES | Market capitalization in USD from Rankings StockInfo (MetadataID=8735 for equities; fallback MetadataID=9315 CryptoMarketCap for crypto). NULL for forex, commodities, and indices. Example: Apple ~3.8T USD. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 37 | SharesOutStanding | numeric(20,4) | YES | Total shares outstanding in units from Rankings StockInfo MetadataID=8444. Annual figure. NULL for non-equity instruments. Example: Apple ~14.7B shares. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 38 | VisibleInternallyOnly | int | YES | Flag (0/1) indicating if the instrument is visible only to internal eToro users (not shown to retail customers). Cast from bit. Used for instruments under development, testing, or institutional-only. NULL for ID=0 placeholder. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 39 | PlatformSector | varchar(max) | YES | eToro platform sector classification from Rankings StockInfo MetadataID=8436. May differ from Bloomberg AssetClass. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 40 | PlatformIndustry | varchar(max) | YES | eToro platform industry classification from Rankings StockInfo MetadataID=8280. More granular than PlatformSector. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 41 | IsFuture | int | YES | Derived flag indicating if the instrument is a futures contract: 1=futures, 0=not futures. Computed in SP as CASE WHEN InstrumentID IN (SELECT InstrumentID FROM InstrumentGroups WHERE GroupID=25) THEN 1 ELSE 0. NULL for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 42 | Multiplier | decimal(38,18) | YES | Futures contract size multiplier from Trade.FuturesMetaData. Determines how many units of the underlying asset one contract represents. NULL for non-futures instruments. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_FuturesMetaData) |
| 43 | ProviderID | int | YES | Liquidity provider identifier from Trade.ProviderToInstrument. Identifies which external market maker or broker provides pricing/liquidity for this instrument. NULL for instruments without a provider mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 44 | ProviderMarginPerLot | decimal(38,18) | YES | Initial margin requirement per lot in the provider's terms, from Trade.FuturesInstrumentsInitialMarginByProviderMapping. Primarily relevant for futures instruments. NULL for non-futures or instruments without provider margin data. (Tier 3 -- live data, FuturesInstrumentsInitialMarginByProviderMapping) |
| 45 | eToroMarginPerLot | decimal(38,18) | YES | eToro's own margin requirement per lot in asset currency (InitialMarginInAssetCurrency from Trade.ProviderToInstrument). eToro's internal margin may differ from the provider's margin. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 46 | SettlementTime | time(7) | YES | Daily or periodic settlement time for the instrument, from Trade.ProviderToInstrument, formatted as TIME via SP DATEPART conversion. Primarily relevant for futures and CFD instruments with defined settlement windows. NULL for instruments without settlement time defined. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 47 | OperationMode | int | YES | Trading operation mode: 0=Standard mode (default, ~15,600 instruments), 1=Alternate mode (~83 instruments, primarily European stock CFDs traded in non-USD denomination currencies). Controls how the trading engine processes orders. (Tier 1 -- upstream wiki, Trade.Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.GetInstrument | InstrumentID | Passthrough |
| InstrumentTypeID | etoro.Trade.GetInstrument | InstrumentTypeID | Passthrough |
| InstrumentType | etoro.Trade.GetInstrument | InstrumentTypeID | CASE to text label |
| Name | etoro.Trade.GetInstrument | Name | Passthrough |
| DWHInstrumentID | etoro.Trade.GetInstrument | InstrumentID | rename (= InstrumentID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| BuyCurrencyID | etoro.Trade.GetInstrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | etoro.Trade.GetInstrument | SellCurrencyID | Passthrough |
| BuyCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via BuyCurrencyID) |
| SellCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via SellCurrencyID) |
| TradeRange | etoro.Trade.GetInstrument | TradeRange | Passthrough |
| DollarRatio | etoro.Trade.GetInstrument | DollarRatio | Passthrough |
| PipDifferenceThreshold | etoro.Trade.GetInstrument | PipDifferenceThreshold | Passthrough |
| IsMajorID | etoro.Trade.GetInstrument | IsMajor | rename (bit to int) |
| IsMajor | etoro.Trade.GetInstrument | IsMajor | CASE to 'Yes'/'No' text |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | join-enriched |
| Industry | etoro.Trade.InstrumentMetaData | Industry | join-enriched |
| CompanyInfo | etoro.Trade.InstrumentMetaData | CompanyInfo | join-enriched |
| Exchange | etoro.Trade.InstrumentMetaData | Exchange | join-enriched |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | join-enriched |
| ISINCountryCode | etoro.Trade.InstrumentMetaData | ISINCountryCode | join-enriched |
| Tradable | etoro.Trade.GetInstrument | Tradable | CAST to int |
| Symbol | etoro.Trade.GetInstrument | Symbol | Passthrough |
| ReceivedOnPriceServer | PriceLog (via PriceLog_History_CurrencyPrice_Active) | ReceivedOnPriceServer | join-enriched, post-load UPDATE |
| BonusCreditUsePercent | etoro.Trade.ProviderToInstrument | BonusCreditUsePercent | join-enriched |
| SymbolFull | etoro.Trade.InstrumentMetaData | SymbolFull | join-enriched |
| CUSIP | etoro.Trade.InstrumentCusip | CUSIP | join-enriched |
| Precision | etoro.Trade.ProviderToInstrument | Precision | join-enriched |
| AllowBuy | etoro.Trade.GetInstrument | AllowBuy | CAST to int |
| AllowSell | etoro.Trade.GetInstrument | AllowSell | CAST to int |
| AssetClass | External classification static | AssetClass | join-enriched, post-load UPDATE |
| IndustryGroup | External classification static | IndustryGroup | join-enriched, post-load UPDATE |
| ADV_Last3Months | Rankings.StockInfo (MetadataID=8557) | NumVal | join-enriched, post-load UPDATE |
| MKTcap | Rankings.StockInfo (MetadataID=8735/9315) | NumVal | join-enriched with fallback, post-load UPDATE |
| SharesOutStanding | Rankings.StockInfo (MetadataID=8444) | NumVal | join-enriched, post-load UPDATE |
| VisibleInternallyOnly | etoro.Trade.GetInstrument | VisibleInternallyOnly | CAST to int |
| PlatformSector | Rankings.StockInfo (MetadataID=8436) | StrVal | join-enriched, post-load UPDATE |
| PlatformIndustry | Rankings.StockInfo (MetadataID=8280) | StrVal | join-enriched, post-load UPDATE |
| IsFuture | etoro.Trade.InstrumentGroups (GroupID=25) | InstrumentID membership | CASE derived, post-load |
| Multiplier | etoro.Trade.FuturesMetaData | Multiplier | join-enriched |
| ProviderID | etoro.Trade.ProviderToInstrument | ProviderID | join-enriched |
| ProviderMarginPerLot | etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | join-enriched |
| eToroMarginPerLot | etoro.Trade.ProviderToInstrument | InitialMarginInAssetCurrency | join-enriched |
| SettlementTime | etoro.Trade.ProviderToInstrument | SettlementTime | cast/convert (TIME formatting) |
| OperationMode | etoro.Trade.Instrument | OperationMode | join-enriched (via etoro_Trade_Instrument) |

Upstream wiki: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.Instrument.md` (quality 9.1/10)

### 5.2 ETL Pipeline

```
etoro.Trade.GetInstrument (view, etoroDB-REAL)
  -> Generic Pipeline (Override, 1440min, Bronze/etoro/Trade/GetInstrument/)
  -> trading.bronze_etoro_trade_getinstrument (UC Bronze)
  -> DWH_staging.etoro_Trade_GetInstrument
  +-> DWH_staging.etoro_Dictionary_Currency (buy/sell currency names)
  +-> DWH_staging.etoro_Trade_InstrumentMetaData (display name, ISIN, exchange, company)
  +-> DWH_staging.etoro_Trade_ProviderToInstrument (provider config, margins, precision)
  +-> DWH_staging.etoro_Trade_InstrumentCusip (CUSIP)
  +-> DWH_staging.etoro_Trade_FuturesMetaData (multiplier)
  +-> DWH_staging.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping
  +-> DWH_staging.etoro_Trade_Instrument (OperationMode, AllowBuy/Sell, Tradable)
  -> SP_Dim_Instrument (TRUNCATE + JOIN INSERT + multiple post-load UPDATEs, daily)
  -> DWH_dbo.Dim_Instrument (15,707 rows)
  -- SP also call

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Position` — synapse
- **Resolved as**: `DWH_dbo.Dim_Position`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md`

# DWH_dbo.Dim_Position

> Core trading position table containing every opened and closed position on the eToro platform since 2007, with financial metrics (P&L, commissions, forex rates), lifecycle timestamps, social trading relationships (mirrors/copies/copy funds), regulatory context, and 20+ market price and spread columns added incrementally since 2022.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.Position (open) + etoro.History.ClosePosition (closed) |
| **Refresh** | Daily (incremental via SP_Dim_Position_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (CloseDateID ASC, PositionID ASC) |
| **Synapse Partitions** | Monthly by CloseDateID, 2007-01-01 through 2026-02-28 (230+ partitions) |
| **Synapse Indexes** | IX_Dim_Position_CID, IX_Dim_Position_CloseDateID, IX_Dim_Position_CloseDateIDOpenDateID, IX_Dim_Position_CloseOccurred_OpenOccurred, IX_Dim_Position_Instrument |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` |
| **UC Format** | Delta |
| **UC Partitioned By** | CloseDateID (monthly) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_Position is the central trading record table in DWH, containing every position (trade) ever opened on the eToro platform. Each row represents a single trading position lifecycle: opened by a customer (CID) on an instrument (InstrumentID), held for some duration, and either still open (CloseDateID=0) or closed with a final NetProfit. The data spans positions from 2007-08-27 to the most recent load date (2026-03-10 as of last ETL run 2026-03-11).

**Position types represented**:
- **Retail positions**: Opened by customers directly in the eToro web/mobile app
- **Mirror/CopyTrading positions**: Opened when a customer copies another trader (MirrorID links to Dim_Mirror); ParentPositionID links to the "master" position
- **Copy Fund positions**: IsCopyFundPosition=1 when the position's root (TreeID) belongs to a fund account (AccountTypeID=9)
- **AirDrop positions**: IsAirDrop=1 for positions created via airdrop events (crypto)
- **ReOpen positions**: IsReOpen=1 for positions reopened after a ReOpen event; ReopenForPositionID points to the original

**Open vs Closed state**:
- Open position: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00'
- Closed position: CloseDateID=YYYYMMDD (e.g., 20260310), CloseOccurred = actual close timestamp

**Data Sources (merged in ETL)**:
- Open positions: `etoro_Trade_OpenPositionEndOfDay` (today's snapshot of all open positions)
- Closed positions: `etoro_History_ClosePositionEndOfDay` (positions that closed on @dt)

**134 columns** covering financial amounts, forex rates at open/close, market prices (spread data), execution IDs, order IDs, hedge types, and fee calculations added through 2025.

---

## 2. Business Logic

### 2.1 Open vs Closed Position States

**What**: The same position row transitions from "open" to "closed" as its lifecycle progresses.

**Columns Involved**: `CloseDateID`, `CloseOccurred`, `NetProfit`, `EndForexRate`, `ClosePositionReasonID`

**Rules**:
- **Open state**: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00.000'. NetProfit holds unrealized P&L (updated daily). EndForexRate=NULL (position not yet closed).
- **Closed state**: CloseDateID=YYYYMMDD int (e.g., 20260310), CloseOccurred=actual datetime. NetProfit holds realized P&L. ClosePositionReasonID explains why it closed.
- **ETL daily cycle**: Each day, rows for positions that opened or closed that day are deleted/updated and re-inserted fresh from staging.
- **CloseDateID=19000101** is a transient internal state used during ETL processing (positions being "reset" before re-insertion); analysts should filter `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed closed positions.
- **OpenDateID and CloseDateID**: Both are YYYYMMDD integers, NOT dates. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.

**Diagram**:
```
Position lifecycle in Dim_Position:
  Day 1 (open):  CloseDateID=0,        CloseOccurred='1900-01-01'  <-- still open
  Day N (close): CloseDateID=YYYYMMDD, CloseOccurred=actual time   <-- closed
  During ETL:    CloseDateID=19000101  <-- transient, skip in queries
```

### 2.2 Social Trading Relationships

**What**: How copy-trading and mirror relationships are encoded.

**Columns Involved**: `MirrorID`, `ParentPositionID`, `OrigParentPositionID`, `TreeID`, `IsCopyFundPosition`

**Rules**:
- **MirrorID**: FK to Dim_Mirror. When a customer copies another trader, all positions generated share the same MirrorID.
- **ParentPositionID**: The position ID of the "master" position being copied. NULL for original/manual positions.
- **OrigParentPositionID**: The original parent (before any reopen/rebalance operations).
- **TreeID**: FK back to Dim_Position.PositionID -- points to the root position of the copy tree. Used to identify CopyFund positions.
- **IsCopyFundPosition=1**: The position belongs to a copy-fund tree (TreeID's CID has AccountTypeID=9).

### 2.3 Financial Metrics and Commissions

**What**: How P&L and commission amounts flow through a position lifecycle.

**Columns Involved**: `Amount`, `NetProfit`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `EndOfWeekFee`, `PnLInDollars`

**Rules**:
- **Amount**: Position notional value in USD at open.
- **NetProfit**: Realized P&L for closed positions; unrealized daily P&L for open positions (updated daily from EndOfDayPnLInDollars).
- **Commission**: Opening commission charged.
- **CommissionOnClose**: Closing commission. Set to 0 for open positions; filled when position closes.
- **FullCommission / FullCommissionOnClose**: Total commissions including all components.
- **EndOfWeekFee**: Overnight fee charged on weekends for leveraged positions. CloseOnEndOfWeek=1 means position auto-closes at weekend.
- **PnLInDollars**: Unrealized daily P&L for open positions (from EndOfDayPnLInDollars staging column); realized at close.

### 2.4 Position Segmentation and Regulation

**What**: Regulatory context and platform categorization at time of open.

**Columns Involved**: `RegulationIDOnOpen`, `PlatformTypeID`, `PositionSegment`

**Rules**:
- **RegulationIDOnOpen**: The regulatory jurisdiction (entity) the customer belonged to at the time of opening. Derived from a JOIN with etoro_History_BackOfficeCustomer at ETL time. 1=UK/FCA, 2=Cyprus/CySEC, etc.
- **PlatformTypeID**: FK to Dim_PlatformType. 1=Web, 2=iOS, 3=Android, 0=Undefined.
- **PositionSegment**: Internal segment classification (smallint).

### 2.5 Volume and Unit Calculations

**What**: ETL-computed unit and volume metrics.

**Columns Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, `Volume`, `VolumeOnClose`, `UnitMargin`, `InitialUnits`

**Rules**:
- **AmountInUnitsDecimal**: Position size in instrument units (e.g., shares, crypto coins).
- **LotCountDecimal**: Position size in lots.
- **Volume**: ETL-computed = ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion factor, 0) -- approximates USD equivalent at open.
- **VolumeOnClose**: Similar calculation using EndForexRate at close.
- **UnitMargin**: Margin per unit for leveraged positions.
- **InitialUnits**: Original units before any partial-close or partial-reopen adjustments.

### 2.6 Open/Close Rates and Market Prices

**What**: The forex rates, market prices, and spread data captured at open and close.

**Columns Involved**: `InitForexRate`, `EndForexRate`, `SpreadedPipBid`, `SpreadedPipAsk`, `InitForex_Ask/Bid/AskSpreaded/BidSpreaded/USDConversionRate`, `EndForex_*`, `OpenMarket_*`, `CloseMarket_*`

**Rules**:
- **InitForexRate / EndForexRate**: The execution rate at open and close respectively (in instrument's base currency per USD or USD per instrument).
- **InitForex_* columns**: Ask, Bid, spreaded variants, and USD conversion rate at the INIT price rate ID (raw price book). Populated from PriceLog_History_CurrencyPrice_Active.
- **EndForex_***: Same price book data at the END (close) rate.
- **OpenMarket_* / CloseMarket_***: Market prices at the time of market open/close events. Added 2023-03-07 (12 columns).
- **SpreadedPipBid / SpreadedPipAsk**: Bid/ask spread in pips at execution.

### 2.7 Fees and Taxes (Post-2025)

**What**: Tax and fee components added in 2025.

**Columns Involved**: `OpenTotalTaxes`, `CloseTotalTaxes`, `OpenTotalFees`, `CloseTotalFees`, `EstimateCloseFeeForCFD`, `EstimateCloseFeeOnOpenByUnits`, `EstimateCloseFeeOnOpen`, `Close_PnLInDollars`, `Close_CalculationRate`, `Close_ConversionRate`, `Close_PriceType`, `CurrentCalculationRate`, `CurrentConversionRate`

**Rules**:
- Added 2025-06-25 (Adi Ferber) and 2025-09-08 (Daniel Kaplan).
- These columns will be NULL for positions opened/closed before the ETL addition date.
- `EstimateCloseFeeForCFD/OnOpenByUnits/OnOpen`: Fee estimates for CFD instruments at open.
- `Close_PnLInDollars / Close_CalculationRate / Close_ConversionRate / Close_PriceType`: Close-side P&L metrics with explicit calculation chain.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Partitioning

**HASH (PositionID)**: Rows distributed by PositionID across nodes. Single-position lookups are efficient. JOINs between two HASH(PositionID) tables (e.g., Dim_Position JOIN Dim_PositionChangeLog by PositionID) are co-located and fast.

**Clustered Index (CloseDateID, PositionID)**: Clustered on close date -- date-range queries on closed positions are efficient. Open-position queries (CloseDateID=0) hit a single partition.

**Monthly partitioning**: Partitioned from 2007-01-01 to 2026-02-28 by CloseDateID. Always include a CloseDateID range filter in queries to enable partition elimination. Without it, all 230+ partitions are scanned.

**NOT ENFORCED PK**: The primary key on (PositionID, CloseDateID) is NOT ENFORCED. Synapse does not validate uniqueness. PositionID is logically unique per position, but be aware: duplicate PositionIDs can exist if ETL has a bug.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position`. Partitioned monthly by CloseDateID. Use `WHERE CloseDateID >= 20260101` style filters for partition pruning. Z-ORDER on PositionID within each partition is beneficial for position-lookup workloads.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get closed positions for a date range | WHERE CloseDateID BETWEEN 20260101 AND 20260310 |
| Get all open positions | WHERE CloseDateID = 0 |
| Get a customer's positions | WHERE CID = X AND CloseDateID BETWEEN ... (always include date range!) |
| P&L for closed positions | SUM(NetProfit) WHERE CloseDateID > 0 AND CloseDateID != 19000101 |
| CopyTrading positions only | WHERE MirrorID IS NOT NULL |
| Direct (non-copy) positions | WHERE MirrorID IS NULL AND ParentPositionID IS NULL |
| CopyFund positions only | WHERE IsCopyFundPosition = 1 |
| Long positions only | WHERE IsBuy = 1 |
| Short positions | WHERE IsBuy = 0 |
| By instrument | WHERE InstrumentID = X AND CloseDateID BETWEEN ... |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer info, tier, country |
| DWH_dbo.Dim_Currency | ON CurrencyID | Position base currency |
| DWH_dbo.Dim_Mirror | ON MirrorID | Copy-trading relationship details |
| DWH_dbo.Dim_ClosePositionReason | ON ClosePositionReasonID | Why position was closed |
| DWH_dbo.Dim_Platform | ON PlatformTypeID | Platform used to open |
| DWH_dbo.Dim_Date | ON OpenDateID / CloseDateID | Calendar dimensions |
| DWH_dbo.Dim_PositionChangeLog | ON PositionID | Position lifecycle changes (IsSettled, Amount changes) |

### 3.4 Gotchas

- **NEVER query without CloseDateID filter**: Without a date range filter, Synapse scans all 230+ monthly partitions. Always include `WHERE CloseDateID BETWEEN X AND Y` or `WHERE CloseDateID = 0`.
- **CloseDateID=0 for open, CloseDateID=19000101 during ETL**: Exclude 19000101 in most queries: `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed-closed positions.
- **OpenDateID and CloseDateID are int, not date**: They are in YYYYMMDD format. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.
- **HASH distribution on PositionID**: Very efficient for single-position or position-list queries. Less efficient for large customer-level scans (CID is not the distribution key).
- **NOT ENFORCED PK**: PositionID uniqueness is not enforced by the database. Check for duplicates if needed.
- **134 columns -- many nullable**: Most columns beyond the core set are NULL for older positions predating their addition (2022-2025). Don't assume non-null.
- **Volume = ETL-computed approximation**: Volume (int) is rounded to nearest integer. VolumeOnClose uses EndForexRate which may differ. Not always perfectly accurate.
- **UpdateDate = GETDATE() or GETUTCDATE()**: Mixed -- open positions use GETDATE(), UPDATE path for closing positions uses GETUTCDATE(). Not a reliable "modified since" field.
- **IsPartialCloseParent / IsPartialCloseChild**: 1 if this position was split via partial close. Use OriginalPositionID to trace the original. Generally filter ISNULL(IsPartialCloseChild,0)=0 on OPEN metrics only — NEVER on CLOSE. Some open metrics (e.g., volume) are already pro-rated, so excluding children would be wrong. Apply the filter case-by-case.
- **RegulationIDOnOpen is 0 for unmatched**: If the ETL JOIN with BackOfficeCustomer history finds no regulation at that date, ISNULL defaults to 0.
- **AmountInUnitsDecimal may change**: Position amount can be adjusted (e.g., partial close). Dim_PositionChangeLog tracks historical amount values.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| ** | Tier 3 - MCP live data | (Tier 3 - MCP live data) |
| * | Tier 4 - Inferred from name | (Tier 4 - [UNVERIFIED]) |

Note: Upstream production wikis available for Trade.PositionTbl and Trade.OpenPositionEndOfDay. Columns with direct passthrough or view-computed staging get Tier 1. ETL-computed and PriceLog-enriched columns get Tier 2.

**Column Groups** (134 total):

#### Group A: Core Identity (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 3 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 4 | CurrencyID | int | NO | FK to Dictionary.Currency. Denomination currency for Amount, NetProfit. Must be > 0. (Tier 1 — Trade.PositionTbl) |
| 5 | ProviderID | int | NO | References Trade.Provider. Execution provider (default 1 = TRADONOMI in PositionOpen). (Tier 1 — Trade.PositionTbl) |

#### Group B: Lifecycle Timestamps and Date IDs (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | OpenOccurred | datetime | NO | When position was persisted (mapped from Occurred in production). Default getutcdate(). (Tier 1 — Trade.PositionTbl) |
| 7 | CloseOccurred | datetime | NO | When close was persisted. (Tier 1 — Trade.PositionTbl) |
| 8 | OpenDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 9 | CloseDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 10 | RequestOpenOccurred | datetime2(7) | YES | When the open request arrived at Trading API. Distinct from OpenOccurred (DB insert time). (Tier 1 — Trade.PositionTbl) |
| 11 | RequestCloseOccurred | datetime2(7) | YES | When close request arrived at API. (Tier 1 — Trade.PositionTbl) |

#### Group C: Financial Metrics (13 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | Amount | money | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in units/shares. Fractional lots. (Tier 1 — Trade.PositionTbl) |
| 14 | InitialAmountCents | money | YES | Initial amount in cents. Used for ratio calculations. (Tier 1 — Trade.PositionTbl) |
| 15 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 16 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 17 | PnLInDollars | decimal(38,6) | YES | Max-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the max-date market rate. Represents unrealized profit/loss at the highest available price timestamp. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 18 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 19 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 20 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 21 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 22 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 23 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 24 | EndOfWeekFee | money | NO | Overnight/weekend carry fee. (Tier 1 — Trade.PositionTbl) |

#### Group D: ETL-Computed Volumes and Units (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | LotCountDecimal | decimal(16,6) | YES | Lot count from provider. Used for hedge aggregation and unit-based sizing. (Tier 1 — Trade.PositionTbl) |
| 26 | UnitMargin | decimal(15,8) | YES | Margin per unit. From Trade.ProviderToInstrument. (Tier 1 — Trade.PositionTbl) |
| 27 | Volume | int | YES | ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 28 | VolumeOnClose | int | YES | ETL-computed USD volume at close: ROUND(AmountInUnitsDecimal * EndForexRate * USD conversion, 0). 0 for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group E: Direction, Leverage, and Trade Settings (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | IsBuy | bit | NO | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 30 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 31 | CloseOnEndOfWeek | bit | NO | Weekend-close flag. 1 = position auto-closes at end of trading week. (Tier 1 — Trade.PositionTbl) |
| 32 | LimitRate | decimal(16,8) | YES | Take-profit rate set at open (or most recent update). (Tier 1 — Trade.PositionTbl) |
| 33 | StopRate | decimal(16,8) | YES | Stop-loss rate set at open (or most recent update). Can be updated via PositionChangeLog. (Tier 1 — Trade.PositionTbl) |

#### Group F: Forex Rates (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | InitForexRate | decimal(16,8) | NO | Opening price rate at position open. Used for PnL calculation. (Tier 1 — Trade.PositionTbl) |
| 35 | EndForexRate | decimal(16,8) | YES | Closing rate at position close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |
| 36 | LastOpConversionRate | decimal(16,8) | YES | Conversion rate for last operation. (Tier 1 — Trade.PositionTbl) |
| 37 | InitConversionRate | decimal(16,8) | YES | Currency conversion rate at open. (Tier 1 — Trade.PositionTbl) |
| 38 | SpreadedPipBid | decimal(16,8) | YES | Bid rate with spread at open. From Trade.CurrencyPrice/spread config. (Tier 1 — Trade.PositionTbl) |
| 39 | SpreadedPipAsk | decimal(16,8) | YES | Ask rate with spread at open. (Tier 1 — Trade.PositionTbl) |

#### Group G: Price Rate IDs and Execution IDs (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | InitForexPriceRateID | bigint | YES | FK to price log table -- the specific price rate record at open. (Tier 1 — Trade.PositionTbl) |
| 41 | EndForexPriceRateID | bigint | YES | Price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 42 | LastOpPriceRateID | bigint | YES | Last operation price rate ID. (Tier 1 — Trade.PositionTbl) |
| 43 | LastOpPriceRate | decimal(16,8) | YES | Last operation price. Updated on partial close, dividend, etc. (Tier 1 — Trade.PositionTbl) |
| 44 | OpenMarketPriceRateID | bigint | YES | Market price rate ID at open. (Tier 1 — Trade.PositionTbl) |
| 45 | CloseMarketPriceRateID | bigint | YES | Market price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 46 | InitConversionRateID | bigint | YES | Conversion rate record ID at open. (Tier 1 — Trade.PositionTbl) |

#### Group H: Execution IDs (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 47 | InitExecutionID | bigint | YES | Execution record ID at open. (Tier 1 — Trade.PositionTbl) |
| 48 | EndExecutionID | bigint | YES | Execution record ID at close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |

#### Group I: Market Price Data at Open (10 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 49 | InitForex_Ask | numeric(16,8) | YES | Raw ask price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | InitForex_Bid | numeric(16,8) | YES | Raw bid price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 51 | InitForex_AskSpreaded | numeric(16,8) | YES | Ask price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 52 | InitForex_BidSpreaded | numeric(16,8) | YES | Bid price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 53 | InitForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 54 | EndForex_Ask | numeric(16,8) | YES | Raw ask at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 55 | EndForex_Bid | numeric(16,8) | YES | Raw bid at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 56 | EndForex_AskSpreaded | numeric(16,8) | YES | Spreaded ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 57 | EndForex_BidSpreaded | numeric(16,8) | YES | Spreaded bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 58 | EndForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at close from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group J: Market Spread Data (8 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 59 | OpenMarket_Ask | numeric(16,8) | YES | Market ask at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 60 | OpenMarket_Bid | numeric(16,8) | YES | Market bid at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 61 | OpenMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 62 | OpenMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | OpenMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 64 | OpenMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 65 | CloseMarket_Ask | numeric(16,8) | YES | Market ask at close event. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 66 | CloseMarket_Bid | numeric(16,8) | YES | Market bid at close event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group K: Close Market Spread (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 67 | CloseMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | CloseMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 69 | CloseMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 70 | CloseMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group L: Markup and Spread Metrics (7 columns -- added 2024-01-15)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 71 | OpenMarketSpread | decimal(38,18) | YES | Spread at open. (Tier 1 — Trade.PositionTbl) |
| 72 | CloseMarketSpread | decimal(38,18) | YES | Spread at close. (Tier 1 — Trade.PositionTbl) |
| 73 | CloseMarkupOnOpen | decimal(38,18) | YES | Close markup projected at open. (Tier 1 — Trade.PositionTbl) |
| 74 | OpenMarkup | decimal(38,18) | YES | Markup at open. (Tier 1 — Trade.PositionTbl) |
| 75 | CloseMarkup | decimal(38,18) | YES | Markup at close. (Tier 1 — Trade.PositionTbl) |
| 76 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 77 | SpreadedCommission | int | YES | Spread-related commission component. (Tier 1 — Trade.PositionTbl) |

#### Group M: Social Trading and Hierarchy (8 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 79 | HedgeID | int | YES | FK to Trade.Hedge. Broker executed hedge. NULL until hedge is opened. (Tier 1 — Trade.PositionTbl) |
| 80 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) |
| 81 | ParentPositionID | bigint | YES | Copy-trade parent. 0/1 = root. Positive = child of referenced position. (Tier 1 — Trade.PositionTbl) |
| 82 | OrigParentPositionID | bigint | YES | Original parent before any detachment. (Tier 1 — Trade.PositionTbl) |
| 83 | TreeID | bigint | YES | Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root PositionID. Demo: negative. (Tier 1 — Trade.PositionTbl) |
| 84 | IsCopyFundPosition | int | YES | 1=position belongs to a copy fund tree (TreeID's CID has AccountTypeID=9). ETL-computed via JOIN chain. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 85 | IsOpenOpen | bit | YES | Open-on-open copy behavior. From Mirror. (Tier 1 — Trade.PositionTbl) |

#### Group N: Partial Close and ReOpen (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 86 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 87 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 88 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 89 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 90 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 91 | IsPartialCloseChildFromReOpen | int | YES | 1=partial close child that was created via a ReOpen flow. (Tier 4 - [UNVERIFIED]) |
| 92 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group O: Settlement and Redemption (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 93 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 94 | IsSettledOnOpen | int | YES | 1 = real asset, 0 = CFD asset. Value at position open (snapshot); same 0/1 encoding as IsSettled. (Tier 5 — Expert Review) |
| 95 | RedeemStatus | tinyint | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 96 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 97 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reo

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_DailyZeroPnL_Stocks.md`

# Dealing_dbo.Dealing_DailyZeroPnL_Stocks

## 1. Overview

**Daily eToro revenue (Zero P&L) aggregated by instrument** for stocks and ETFs. Each row represents one combination of date, hedge server, instrument, leverage tier, CFD flag, regulation, MiFID category, trading mode (IsManual), and stock index membership. Realized Zero comes from positions closed on the report date; Unrealized Zero reflects the mark-to-market P&L on open positions. The table is a foundational feed for downstream Dealing revenue analytics, Apex P&L reconciliation, credit risk, and hedge cost calculations.

**Row grain**: `Date` + `HedgeServerID` + `InstrumentID` + `Industry` + `InstrumentType` + `IsManual` + `Leverage` + `IsCFD` + `Regulation` + `MifID`.

---

## 2. Business Context

`SP_DailyZeroPnL_Stocks` (Author: Amir Gurewitz 2020-06-09, migrated to Synapse by Gal in Jan 2024) calculates the daily Zero P&L for `InstrumentTypeID IN (5, 6)` (Stocks and ETFs).

**Realized Zero** is computed for positions with `CloseDateID = @RepDate`: NetProfit + CommissionOnClose − PreviousDayPnL (standard eToro zero formula).

**Unrealized Zero** (ChangeInUnrealizedZero) is computed for open positions as DailyPnL + commission adjustment: captures intraday P&L movement for positions still open at EOD.

**NOP** (Net Open Position) is aggregated as `SUM(ABS(NOP_in_USD))` using the (2*IsBuy-1) sign convention, with FX conversion via `Fact_CurrencyPriceWithSplit`.

**StockIndex** mapping comes from `BI_DB_dbo.BI_DB_IndexesMapping_Static` to classify instruments into index groups (e.g., S&P500, NASDAQ).

**Key business rules**:

- **InstrumentTypeID filter**: Only Stocks (5) and ETFs (6) — FX/crypto excluded.
- **DELETE-INSERT by date**: Idempotent daily reload.
- **MifID and Regulation** from `Fact_SnapshotCustomer` for the report date — used by compliance/reporting consumers.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 26 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~275,000,000 |
| **Date range** | Active and current (daily refresh confirmed) |
| **Recent sample** | Rows for 2026-03-20 with mixed Regulation values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the zero P&L snapshot. (Tier 2 -- SP_DailyZeroPnL_Stocks, @RepDate) |
| 2 | HedgeServerID | int | YES | Hedge server identifier for the position set. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.HedgeServerID) |
| 3 | Industry | varchar(250) | YES | Industry classification of the instrument (from Dim_Instrument). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Industry) |
| 4 | InstrumentType | varchar(50) | YES | Instrument type string (Stock / ETF). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentType) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentID) |
| 6 | InstrumentDisplayName | varchar(250) | YES | Display name of the instrument. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 7 | StockIndex | varchar(50) | YES | Index membership (e.g., S&P500, NASDAQ) from the static mapping table; NULL if not in any index. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_IndexesMapping_Static.IndexName) |
| 8 | IsManual | tinyint | YES | Flag indicating manual (non-automated) trading positions. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsManual) |
| 9 | Leverage | int | YES | Position leverage tier. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.Leverage) |
| 10 | IsCFD | tinyint | YES | 1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.IsSettled / HedgeServerID) |
| 11 | Regulation | varchar(50) | YES | Regulatory jurisdiction of the customer (e.g., ASIC, FCA, CySEC). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Regulation.Name) |
| 12 | MifID | int | YES | MiFID categorization ID of the customer snapshot. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Fact_SnapshotCustomer.MifidCategorizationID) |
| 13 | RealizedCommission | money | YES | Aggregate commission charged on positions closed on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.CommissionOnClose) |
| 14 | RealizedZero | money | YES | Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL / NetProfit / CommissionOnClose) |
| 15 | ChangeInUnrealizedZero | money | YES | Change in unrealized eToro revenue for still-open positions: SUM(DailyPnL + commission adjustment). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.DailyPnL) |
| 16 | TotalZero | money | YES | RealizedZero + ChangeInUnrealizedZero for the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, computed) |
| 17 | NOP | money | YES | Net Open Position in USD for open positions in the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 18 | OpenPositions | money | YES | Count of open positions in the group (as money type). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL) |
| 19 | NOP_Units | numeric(38,6) | YES | Net open position in instrument units (signed: positive=long, negative=short). (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal with sign) |
| 20 | VolumeOnOpen | bigint | YES | Cumulative open-action volume for positions opened on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.VolumeOnOpen) |
| 21 | VolumeOnClose | bigint | YES | Cumulative close-action volume for positions closed on the report date. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Position.VolumeOnClose) |
| 22 | OpenPositionValue | money | YES | Aggregated USD value of open positions (units × price). (Tier 2 -- SP_DailyZeroPnL_Stocks, computed from NOP and FX rate) |
| 23 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE()) |
| 24 | InstrumentName | varchar(100) | YES | Short instrument name/ticker symbol. (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Name) |
| 25 | Units | decimal(16,6) | YES | Net units held across the group's open positions. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 26 | Currency | varchar(50) | YES | Trade currency of the instrument (SellCurrency). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.SellCurrency) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary position P&L fact (NOP, DailyPnL, CommissionOnClose, IsSettled) |
| Dim_Position | DWH_dbo | Position attributes (OpenDateID, CloseDateID, HedgeServerID, Leverage) |
| Fact_SnapshotCustomer | DWH_dbo | Customer regulation and MiFID snapshot for report date |
| Dim_Range | DWH_dbo | Snapshot date range lookup |
| Dim_Instrument | DWH_dbo | Instrument metadata (InstrumentType, Industry, SellCurrency) |
| Dim_Regulation | DWH_dbo | Regulation name lookup |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for NOP USD conversion |
| BI_DB_IndexesMapping_Static | BI_DB_dbo | Stock index membership mapping |

### Downstream Tables

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_Apex_PnL | Dealing_dbo | Apex P&L report — depends on this table |
| Dealing_Apex_PnL_Daily | Dealing_dbo | Daily Apex P&L |
| Dealing_Apex_PnL_EE / EE_Daily | Dealing_dbo | eToro Europe variant |
| Dealing_CFDs_Stocks_Credit_Risk | Dealing_dbo | CFD stock credit risk |
| Dealing_HedgeCost | Dealing_dbo | Hedge cost calculation |
| Dealing_Manual_Exec_Trade / Summary | Dealing_dbo | Manual execution trade analytics |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DailyZeroPnL_Stocks |
| **Author** | Amir Gurewitz (2020-06-09); Synapse migration by Gal (2024-01) |
| **ETL Pattern** | DELETE WHERE Date=@dd + INSERT |
| **Schedule** | Daily — SB_Daily (P0) |
| **Parameter** | @dd (DATE) — the report date |
| **Delete Scope** | `DELETE WHERE Date = @dd` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Clustered index** | Filter on `Date` first for optimal performance. |
| **CFD vs Real** | Use `IsCFD` flag to split; Real = `IsSettled=1` or `HedgeServerID IN (3,9,102,112,125,126,81)`. |
| **NOP sign** | `NOP_Units` is signed (positive=long, negative=short). `NOP` is absolute USD value. |
| **Zero formula** | RealizedZero = NetProfit + CommissionOnClose − PreviousDayPnL (standard eToro Zero definition). |
| **Downstream** | Several Dealing_dbo tables depend on this as a source — changes to filters here ripple broadly. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Revenue Analytics |
| **Sub-domain** | Daily Zero P&L — Stocks & ETFs |
| **Sensitivity** | Aggregated (no individual customer data exposed) |
| **Quality Score** | 8.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


### Upstream `BI_DB_dbo.BI_DB_VarCommission` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_VarCommission`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_VarCommission.md`

# BI_DB_dbo.BI_DB_VarCommission

## 1. Overview

Daily **variable commission** (spread-based) tracking by instrument. Compares the actual spread-based commission earned versus the fixed commission charged, broken down by openings and closings. Used by finance to analyze commission revenue composition and hedge server attribution.

**Row grain**: One InstrumentID + InstrumentType + IsSettled + HedgeServerID per DateID

---

## 2. Business Context

Commission revenue has two components: **FullCommission** (the fixed commission charged to the customer) and **VarCommission** (the actual spread revenue: `Units * (Ask - Bid) * USD conversion`). The difference between them represents the spread markup or deficit.

**Key business rules**:
- **VarCommission formula (openings)**: `AmountInUnitsDecimal * (InitForex_Ask - InitForex_Bid) * USDConversionRate`
- **VarCommission formula (closings)**: `AmountInUnitsDecimal * (EndForex_Ask - EndForex_Bid) * USDConversionRate`
- **Same-day open+close**: Position opened and closed on @DateID gets both FullCommissionOnClose and full spread calculation.
- **Customer filter**: `IsValidCustomer = 1` (via Dim_Customer, not Fact_SnapshotCustomer).
- **Position filter**: Only positions opened OR closed on @DateID with non-null forex rates.
- **HedgeServerID**: From `Dim_PositionHedgeServerChangeLog_Snapshot` (LEFT JOIN, fallback to Dim_Position.HedgeServerID). Identifies which hedge server executed the trade.
- **Calendar fields**: CalendarYearMonth and MonthName from Dim_Date via CROSS JOIN.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 16 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date. From SP @Date parameter. (Tier 2 -- SP_VarCommission, @Date) |
| 2 | DateID | int | YES | Date as integer YYYYMMDD. Clustered index. (Tier 2 -- SP_VarCommission, @Date) |
| 3 | InstrumentType | varchar(50) | YES | Instrument type from Dim_Instrument.InstrumentType. Values: "Stocks", "Currencies", "Indices", "Commodities", "Crypto", "ETFs". (Tier 2 -- SP_VarCommission, Dim_Instrument.InstrumentType) |
| 4 | CalendarYearMonth | char(7) | YES | Year-month from Dim_Date.CalendarYearMonth. Format: "2025-04". (Tier 2 -- SP_VarCommission, Dim_Date.CalendarYearMonth) |
| 5 | MonthName | varchar(10) | YES | Month name from Dim_Date.MonthName. Values: "January", "February", etc. (Tier 2 -- SP_VarCommission, Dim_Date.MonthName) |
| 6 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. From Dim_Position.IsSettled. (Tier 5 — Expert Review) |
| 7 | FullCommission | money | YES | Total fixed commission charged. Combines opening (FullCommissionByUnits) and closing (FullCommissionOnClose) commissions. (Tier 2 -- SP_VarCommission, Dim_Position) |
| 8 | VarCommission | money | YES | Total spread-based commission (variable). `Units * Spread * USDRate` for both openings and closings. (Tier 2 -- SP_VarCommission, computed from Dim_Position forex fields) |
| 9 | VarCommission_Openings | money | YES | Spread-based commission from positions opened on this date only. (Tier 2 -- SP_VarCommission, computed) |
| 10 | FullCommission_Openings | money | YES | Fixed commission from positions opened on this date only. FullCommissionByUnits. (Tier 2 -- SP_VarCommission, Dim_Position.FullCommissionByUnits) |
| 11 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -- SP_VarCommission, GETDATE()) |
| 12 | InstrumentID | int | YES | Instrument identifier from Dim_Position. (Tier 2 -- SP_VarCommission, Dim_Position.InstrumentID) |
| 13 | InstrumentName | varchar(50) | YES | Instrument name from Dim_Instrument.Name. (Tier 2 -- SP_VarCommission, Dim_Instrument.Name) |
| 14 | VarCommission_Closings | money | YES | Spread-based commission from positions closed on this date only. (Tier 2 -- SP_VarCommission, computed) |
| 15 | FullCommission_Closings | money | YES | Fixed commission from positions closed on this date only. FullCommissionOnClose. (Tier 2 -- SP_VarCommission, Dim_Position.FullCommissionOnClose) |
| 16 | HedgeServerID | int | YES | Hedge server that executed the trade. From Dim_PositionHedgeServerChangeLog_Snapshot (fallback: Dim_Position.HedgeServerID). (Tier 2 -- SP_VarCommission, ISNULL(Snapshot.HedgeServerID, Dim_Position.HedgeServerID)) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Dim_Position | DWH_dbo | Primary -- position commissions, forex rates, open/close dates |
| Dim_Instrument | DWH_dbo | Instrument metadata (type, name, SellCurrencyID) |
| Dim_Customer | DWH_dbo | Customer validity (IsValidCustomer=1) |
| Dim_PositionHedgeServerChangeLog_Snapshot | DWH_dbo | Hedge server assignment (LEFT JOIN) |
| Dim_Date | DWH_dbo | Calendar fields (CalendarYearMonth, MonthName) |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_VarCommission |
| **Author** | Jenia Simonovitch (2020-10-18) |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Grain** | InstrumentID + InstrumentType + IsSettled + HedgeServerID per DateID |
| **Schedule** | Daily (SB_Daily, Priority 99 -- FinanceReportSPS) |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE DateID = @DateID` |
| **Architecture** | #Month (calendar) CROSS JOIN with #Commissions (aggregated positions) -> INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on DateID** | Clustered index on DateID. |
| **VarCommission vs FullCommission** | VarCommission is spread-based (market dependent), FullCommission is fixed. Compare for spread analysis. |
| **Same-day positions** | Positions opened and closed on the same day appear in both _Openings and _Closings columns. |
| **HedgeServerID** | May change over a position's lifetime; this table captures the server at time of trade (via snapshot). |
| **SellCurrencyID=1** | USD-denominated instruments skip the USDConversionRate multiplication. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Commission Revenue |
| **Sub-domain** | Variable Commission Analysis |
| **Sensitivity** | Instrument-level aggregate -- low PII risk |
| **Owner** | Finance team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #8*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5*


### Upstream `DWH_dbo.Dim_Customer` — synapse
- **Resolved as**: `DWH_dbo.Dim_Customer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`

﻿# DWH_dbo.Dim_Customer

> Master customer dimension table for the DWH; consolidates identity, demographics, compliance status, acquisition tracking, and external integrations from 14+ staging sources into a single slowly-changing Type 1 dimension with explicit change detection, PII masking, and multi-phase post-load enrichment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | RealCID (PK NOT ENFORCED, CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(RealCID) |
| **Index** | CLUSTERED INDEX (RealCID ASC); PK NONCLUSTERED NOT ENFORCED |
| **Column Count** | 107 |
| **PII Masking** | 14 columns with Dynamic Data Masking |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Tables** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (masked), `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer` (unmasked PII) |
| **UC Copy Strategy** | Override |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | CDC-style: change detection → DELETE/INSERT → multi-phase UPDATE enrichment |

---

## 1. Business Meaning

`Dim_Customer` is the DWH's central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer.

The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle.

Two UC copies exist:
- **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics
- **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" JOINs `Dim_Customer` on CID=RealCID for country, regulation, and status filtering
- **BI Queries**: Nearly every DWH fact table JOINs to Dim_Customer (via CID=RealCID) for customer segmentation
- **Synapse Training**: Confluence "Temporary Tables in Synapse" uses Dim_Customer as a reference example for HASH distribution optimization

---

## 5. Lineage

### 2.1 Staging Sources (14+ tables)

| Staging Table | Production Source | Role |
|--------------|-------------------|------|
| `DWH_staging.etoro_Customer_Customer` | Customer.CustomerStatic | Core customer profile (identity, demographics, registration) |
| `DWH_staging.etoro_BackOffice_Customer` | BackOffice.Customer | Compliance/admin attributes (verification, risk, regulation, guru status) |
| `DWH_staging.etoro_History_Customer` | History.Customer | Latest version for change detection (SCD) |
| `DWH_staging.etoro_History_BackOfficeCustomer` | History.BackOfficeCustomer | Latest version for BO attribute change detection |
| `DWH_staging.STS_Audit_UserOperationsData` | STS_Audit.UserOperationsData | 2FA enable/disable tracking |
| `DWH_staging.ContactVerification_Phone_Customer` | ContactVerification.Phone.Customer | Phone number, verification status |
| `DWH_staging.UserApiDB_Customer_Avatars` | UserApiDB.Customer.Avatars | Avatar upload tracking |
| `DWH_staging.etoro_Billing_vDeposit` | Billing.vDeposit | Legacy FTD source (replaced by below) |
| `DWH_staging.CustomerFinanceDB_Customer_FirstTimeDeposits` | CustomerFinanceDB.Customer.FirstTimeDeposits | FTD date, amount, platform, recovery date |
| `DWH_staging.ScreeningService_Screening_UserScreening` | ScreeningService.Screening.UserScreening | Screening/compliance status |
| `DWH_staging.SalesForce_DB_Prod_dbo_IdMapTopology` | SalesForce_DB_Prod.dbo.IdMapTopology | SalesForce account ID mapping |
| `DWH_staging.etoro_BackOffice_CustomerDocument` + `etoro_BackOffice_CustomerDocumentToDocumentType` | BackOffice.CustomerDocument | Address proof & ID proof status |
| `DWH_staging.etoro_Customer_CustomerStatic` | Customer.CustomerStatic | ApexID only |
| `DWH_staging.UserApiDB_Customer_CustomerIdentification` | UserApiDB.Customer.CustomerIdentification | GCID, DemoCID, TanganyID, DltID |
| `DWH_staging.ComplianceStateDB_Compliance_StocksLending` | ComplianceStateDB.Compliance.StocksLending | EquiLendID, StocksLendingStatusID |
| `DWH_dbo.Ext_Dim_SubChannel_UnifyCode` | (DWH internal) | SubChannelID via AffiliateID mapping |

### 2.2 ETL Pipeline (SP_Dim_Customer_DL_To_Synapse → SP_Dim_Customer)

```
ORCHESTRATOR (SP_Dim_Customer_DL_To_Synapse):
  1. Load 14 staging/external tables:
     Ext_Dim_Customer_Affiliate, Ext_Dim_Customer_BOCustomer, Ext_Dim_Customer_2FA,
     Ext_Dim_Customer_PhoneCustomer, Ext_Dim_Customer_Customer, Ext_Dim_Customer_Avatars,
     Ext_etoro_Billing_vDeposit, Ext_CustomerFinanceDB_Customer_FirstTimeDeposits,
     Ext_Dim_Customer_ScreeningStatusID, Ext_Dim_Customer_SF_ID, Ext_Dim_Customer_Document,
     Ext_Dim_CustomerStatic, Ext_Dim_Customer_CustomerIdentification, Ext_Dim_Customer_StocksLending
  2. EXEC SP_Dim_Customer

CORE LOGIC (SP_Dim_Customer):
  Step 1: Build #customer — JOIN Ext_Customer_Customer + Ext_BOCustomer
          Compute: IsValidCustomer, IsCreditReportValidCB
          Rename: SerialID→AffiliateID, ManagerID→AccountManagerID, isEmployeeAccount→EmployeeAccount
  Step 2: Detect #new (CIDs not yet in Dim_Customer)
  Step 3: Detect #update (50+ column comparison using ISNULL + COLLATE)
  Step 4: Build #full_list (new OR updated CIDs) with 2FA from Ext_2FA
  Step 5: Preserve #CustomerInitalIndicaton (deposit, avatar, document, Tangany, DLT, phone, FTD fields)
  Step 6: BEGIN TRAN: DELETE matching CIDs → INSERT with preserved indicators
  Step 7: Post-transaction UPDATEs:
          Avatar → HasAvatar, AvatarUploadDate
          Deposit → IsDepositor, FirstDepositDate, FirstDepositAmount, FTD fields
          ScreeningStatusID → from screening service
          SalesForceAccountID → from SF ID map
          Document proofs → IsAddressProof, IsIDProof + expiry dates
          2FA → from audit log
          SubChannelID → from affiliate mapping
          ApexID → from CustomerStatic
          Phone → PhoneNumber, IsPhoneVerified, PhoneVerificationDate
          Tangany → TanganyID, TanganyStatusID
          DLT → DltID, DltStatusID
          StocksLending → EquiLendID, StocksLendingStatusID
  Step 8: Populate Ext_Dim_Customer_ExternalID_GCID, update UserName_Lower
```

### 2.3 Key Column Renames

| DWH Column | Source Column | Source Table | Why |
|-----------|-------------|-------------|-----|
| RealCID | CID | etoro_Customer_Customer | Disambiguate from other CID uses in DWH |
| AffiliateID | SerialID | etoro_Customer_Customer | Business-friendly name |
| AccountManagerID | ManagerID | etoro_BackOffice_Customer | Disambiguate from other ManagerID columns |
| EmployeeAccount | isEmployeeAccount | etoro_BackOffice_Customer | Normalize casing |
| RegisteredReal | Registered | etoro_Customer_Customer | Clarify real-account registration |

### 2.4 DWH-Computed Columns

| Column | Computation |
|--------|------------|
| IsValidCustomer | `1` when PlayerLevelID≠4 AND LabelID NOT IN (30,26) AND CountryID≠250; else `0` |
| IsCreditReportValidCB | Similar to IsValidCustomer but also excludes PlayerLevelID=4 when AccountTypeID≠2, and has specific CID exceptions for CountryID=250 |
| UpdateDate | `GETDATE()` — ETL timestamp |
| UserName_Lower | `LOWER(UserName)` — set in final UPDATE |

---

## 4. Elements

### 3.1 Customer Identity

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 1 | RealCID | int | NO | No | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | No | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | DemoCID | int | YES | No | Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer) |
| 4 | OriginalCID | int | YES | No | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 5 | ID | uniqueidentifier | NO | No | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic) |
| 6 | ExternalID | decimal(38,0) | YES | No | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic) |

### 3.2 Personal Information (PII — Masked)

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 7 | UserName | varchar(20) | YES | Yes | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 8 | UserName_Lower | varchar(20) | YES | Yes | Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 9 | FirstName | nvarchar(50) | YES | Yes | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 10 | LastName | nvarchar(50) | YES | Yes | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 11 | MiddleName | nvarchar(50) | YES | Yes | Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic) |
| 12 | Gender | char(1) | YES | Yes | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 13 | BirthDate | datetime | YES | Yes | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 14 | Email | varchar(50) | YES | Yes | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 15 | Phone | varchar(30) | YES | Yes | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 16 | IP | varchar(15) | YES | Yes | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 17 | Zip | nvarchar(50) | YES | Yes | Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 18 | City | nvarchar(50) | YES | Yes | City in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 19 | Address | nvarchar(100) | YES | Yes | Street address in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 20 | BuildingNumber | nvarchar(30) | YES | Yes | Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic) |

### 3.3 Acquisition & Marketing

| # | Column | Type | Description |
|---|--------|------|-------------|
| 21 | AffiliateID | int | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 22 | CampaignID | int | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 — Customer.CustomerStatic) |
| 23 | SubChannelID | int | Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 24 | LabelID | int | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 — Customer.CustomerStatic) |
| 25 | BannerID | int | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 26 | FunnelID | int | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 — Customer.CustomerStatic) |
| 27 | FunnelFromID | int | Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 — Customer.CustomerStatic) |
| 28 | DownloadID | int | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 — Customer.CustomerStatic) |
| 29 | ReferralID | int | Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 30 | SubSerialID | varchar(1024) | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — Customer.CustomerStatic) |

### 3.4 Registration & Account Lifecycle

| # | Column | Type | Description |
|---|--------|------|-------------|
| 31 | RegisteredReal | datetime | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 32 | RegisteredDemo | datetime | Demo account registration date. Source unclear — may be populated separately. (Tier 2 — SP_Dim_Customer) |
| 33 | AccountExpirationDate | datetime | Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 — Customer.CustomerStatic) |
| 34 | AccountStatusID | int | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — Customer.CustomerStatic) |
| 35 | PlayerStatusID | int | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 36 | PlayerStatusReasonID | int | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Customer.CustomerStatic) |
| 37 | PlayerStatusSubReasonID | int | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 — Customer.CustomerStatic) |
| 38 | PendingClosureStatusID | tinyint | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 — Customer.CustomerStatic) |
| 39 | PlayerLevelID | int | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 40 | AccountTypeID | int | Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 — BackOffice.Customer) |
| 41 | IsDepositor | bit | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 — SP_Dim_Customer) |
| 42 | FirstDepositDate | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 43 | FirstDepositAmount | money | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |

### 3.5 Compliance & Regulation

| # | Column | Type | Description |
|---|--------|------|-------------|
| 44 | RegulationID | tinyint | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 45 | DesignatedRegulationID | int | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — BackOffice.Customer) |
| 46 | RegulationChangeDate | datetime | Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 — BackOffice.Customer) |
| 47 | CountryID | int | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 48 | CountryIDByIP | int | Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 — Customer.CustomerStatic) |
| 49 | CitizenshipCountryID | int | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — Customer.CustomerStatic) |
| 50 | POBCountryID | int | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 — Customer.CustomerStatic) |
| 51 | RegionID | int | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 — Customer.CustomerStatic) |
| 52 | RegionByIP_ID | int | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 — Customer.CustomerStatic) |
| 53 | VerificationLevelID | int | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 — BackOffice.Customer) |
| 54 | DocsOK | tinyint | Whether required documents are verified. (Tier 2 — SP_Dim_Customer) |
| 55 | DocumentStatusID | int | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — BackOffice.Customer) |
| 56 | IsAddressProof | int | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 — SP_Dim_Customer) |
| 57 | IsAddressProofExpiryDate | datetime | Expiry date of address proof document. (Tier 2 — SP_Dim_Customer) |
| 58 | IsIDProof | int | Whether ID proof document is on file (1/0). (Tier 2 — SP_Dim_Customer) |
| 59 | IsIDProofExpiryDate | datetime | Expiry date of ID proof document. (Tier 2 — SP_Dim_Customer) |
| 60 | SuitabilityTestStatusID | int | MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 — BackOffice.Customer) |
| 61 | MifidCategorizationID | int | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 — BackOffice.Customer) |
| 62 | ScreeningStatusID | int | Compliance screening status. Updated from ScreeningService. (Tier 2 — SP_Dim_Customer) |
| 63 | WorldCheckID | int | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — BackOffice.Customer) |
| 64 | WorldCheckResultsUpdated | datetime | When World-Check results were last updated. Preserved from previous row. (Tier 2 — SP_Dim_Customer) |
| 65 | IsEDD | bit | Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 — BackOffice.Customer) |
| 66 | Bankruptcy | tinyint | Bankruptcy flag. (Tier 2 — SP_Dim_Customer) |
| 67 | IsValidCustomer | int | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 68 | IsCreditReportValidCB | int | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 — SP_Dim_Customer) |

### 3.6 Risk & Communication

| # | Column | Type | Description |
|---|--------|------|-------------|
| 69 | RiskStatusID | int | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 — BackOffice.Customer) |
| 70 | RiskClassificationID | int | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 — BackOffice.Customer) |
| 71 | EmployeeAccount | tinyint | 1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 — BackOffice.Customer) |
| 72 | LanguageID | int | Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 73 | CommunicationLanguageID | int | Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 — Customer.CustomerStatic) |
| 74 | IsEmailVerified | int | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 — Customer.CustomerStatic) |
| 75 | PrivacyPolicyID | int | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 — Customer.CustomerStatic) |
| 76 | IsCopyBlocked | bit | 1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 — BackOffice.Customer) |

### 3.7 Social & Trading Features

| # | Column | Type | Description |
|---|--------|------|-------------|
| 77 | GuruStatusID | smallint | eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 — BackOffice.Customer) |
| 78 | NumOfGurus | int | Number of Popular Investors this customer is copying. (Tier 2 — SP_Dim_Customer) |
| 79 | NumOfCopiers | int | Number of customers copying this customer's trades. (Tier 2 — SP_Dim_Customer) |
| 80 | NumOfRAF | int | Number of successful Refer-A-Friend referrals. (Tier 2 — SP_Dim_Customer) |
| 81 | SocialConnectID | int | Social media connection type. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 82 | PremiumAccount | tinyint | Whether this is a premium account. (Tier 2 — SP_Dim_Customer) |
| 83 | Evangelist | tinyint | Whether this customer is an evangelist/ambassador. (Tier 2 — SP_Dim_Customer) |
| 84 | HasAvatar | tinyint | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 — SP_Dim_Customer) |
| 85 | AvatarUploadDate | datetime | When the avatar was uploaded. (Tier 2 — SP_Dim_Customer) |
| 86 | EvMatchStatus | int | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |

### 3.8 Account Management

| # | Column | Type | Description |
|---|--------|------|-------------|
| 87 | AccountManagerID | int | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer) |
| 88 | UpdateDate | datetime | ETL load/update timestamp (GETDATE()). (Tier 2 — SP_Dim_Customer) |
| 89 | SalesForceAccountID | nvarchar(18) | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 — BackOffice.Customer) |

### 3.9 Authentication & Phone Verification

| # | Column | Type | Description |
|---|--------|------|-------------|
| 90 | 2FA | int | Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 — SP_Dim_Customer) |
| 91 | PhoneVerifiedID | int | Result code of phone number verification process. NULL if not yet attempted. (Tier 1 — BackOffice.Customer) |
| 92 | PhoneNumber | varchar(30) | Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 — SP_Dim_Customer) |
| 93 | IsPhoneVerified | bit | Whether phone is verified (VerificationStatusID IN (1,2) → 1). (Tier 2 — SP_Dim_Customer) |
| 94 | PhoneVerificationDate | smalldatetime | Date phone was verified. '1900-01-01' if not verified. (Tier 2 — SP_Dim_Customer) |

### 3.10 External Integrations

| # | Column | Type | Description |
|---|--------|------|-------------|
| 95 | ApexID | varchar(8) | APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 — Customer.CustomerStatic) |
| 96 | TanganyID | nvarchar(max) | Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 97 | TanganyStatusID | tinyint | Tangany integration status. (Tier 2 — SP_Dim_Customer) |
| 98 | EquiLendID | nvarchar(max) | EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 — SP_Dim_Customer) |
| 99 | StocksLendingStatusID | int | Stocks lending consent status. (Tier 2 — SP_Dim_Customer) |
| 100 | DltID | nvarchar(max) | Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 101 | DltStatusID | int | DLT integration status. (Tier 2 — SP_Dim_Customer) |
| 102 | HasWallet | int | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |

### 3.11 FTD (First Time Deposit) Tracking

| # | Column | Type | Description |
|---|--------|------|-------------|
| 103 | FTDPlatformID | nvarchar(4000) | Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 104 | FTDTransactionID | nvarchar(4000) | Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 105 | FTDRecoveryDate | datetime2(7) | Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |

### 3.12 Miscellaneous

| # | Column | Type | Description |
|---|--------|------|-------------|
| 106 | CashoutFeeGroupID | int | Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 — BackOffice.Customer) |
| 107 | WeekendFeePrecentage | int | Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 — Customer.CustomerStatic) |

---

## 2. Business Logic

### 4.1 Change Detection (CDC-Style)

The SP compares 50+ columns between `#customer` (staging) and existing `Dim_Customer` using `ISNULL(old,0) <> ISNULL(new,0)` with explicit `COLLATE Latin1_General_100_BIN` for string columns. Only customers with actual changes (or new customers) are processed. This prevents unnecessary row churn.

### 4.2 Indicator Preservation

When a customer row is updated (DELETE+INSERT), certain indicator fields are preserved from the old row via `#CustomerInitalIndicaton`: FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor, ScreeningStatusID, SalesForceAccountID, document proofs, WorldCheckID, Tangany, Phone, EquiLend, DLT, FTD fields. These are then refreshed in subsequent post-load UPDATEs if new data is available.

### 4.3 Multi-Source Identity Resolution

Customer attributes come from multiple microservices. The ETL uses `ISNULL(history_version, current_value)` patterns to prefer the latest History version (with temporal filtering: ValidFrom < @CurrentDate, ValidFrom >= @DelayDate, ValidTo >= @CurrentDate) over the current snapshot, ensuring the most up-to-date attribute values are captured.

### 4.4 FTD Recovery Date Logic

The `FirstDepositDate` is updated using: if the existing `FirstDepositDate` (as date) is earlier than `FTDRecoveryDate`, use `FTDRecoveryDate`; otherwise use the `FTDDate`. This handles cases where an FTD was reversed and re-deposited on a different day.

### 4.5 IsValidCustomer Business Rule

```
IsValidCustomer = 1 WHEN:
  PlayerLevelID ≠ 4 (not Popular Investor)
  AND LabelID NOT IN (30, 26) (not bonus-only or specific label)
  AND CountryID ≠ 250
```

This excludes demo-like, internal, and specific-jurisdiction accounts from standard reporting.

---

## 6. Relationships

### 5.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CountryID / CountryIDByIP / CitizenshipCountryID / POBCountryID | Dim_Country | CountryID = CountryID |
| AffiliateID | Dim_Affiliate | AffiliateID = AffiliateID |
| CampaignID | Dim_Campaign | CampaignID = CampaignID |
| AccountTypeID | Dim_AccountType | AccountTypeID = AccountTypeID |
| AccountStatusID | Dim_AccountStatus | AccountStatusID = AccountStatusID |
| PlayerLevelID | (Dictionary.PlayerLevel — no DWH dim) | — |
| GuruStatusID | Dim_GuruStatus | GuruStatusID = GuruStatusID |
| FunnelID | Dim_Funnel | FunnelID = FunnelID |
| DocumentStatusID | Dim_DocumentStatus | DocumentStatusID = DocumentStatusID |
| EvMatchStatus | Dim_EvMatchStatus | EvMatchStatus = EvMatchStatus |
| CashoutFeeGroupID | Dim_CashoutFeeGroup | CashoutFeeGroupID = CashoutFeeGroupID |

### 5.2 Fact Table Relationships

Nearly every DWH fact table JOINs to Dim_Customer:
- `Fact_BillingWithdraw.CID = Dim_Customer.RealCID`
- `Fact_CustomerUnrealized_PnL.CID = Dim_Customer.RealCID`
- `Fact_SnapshotCustomer.RealCID = Dim_Customer.RealCID`
- `Fact_CustomerAction.CID = Dim_Customer.RealCID`
- `Dim_Position.CID = Dim_Customer.RealCID`

### 5.3 Source Chain

```
Production Microservices                    DWH Staging                         Synapse DWH
──────────────────────                    ──────────                         ───────────
Customer.CustomerStatic          →  etoro_Customer_Customer            ─┐
BackOffice.Customer              →  etoro_BackOffice_Customer          ─┤
History.Customer                 →  etoro_History_Customer             ─┤
History.BackOfficeCustomer       →  etoro_History_BackOfficeCustomer   ─┤  

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_PositionChangeLog` — synapse
- **Resolved as**: `DWH_dbo.Dim_PositionChangeLog`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PositionChangeLog.md`

# DWH_dbo.Dim_PositionChangeLog

> Position lifecycle change audit log recording every event that modifies a position's amount, stop-loss rate, settlement status, or lot count -- enabling reconstruction of position state at any point in time.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.History.PositionChangeLog |
| **Refresh** | Daily (incremental via SP_Dim_PositionChangeLog_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (OccurredDateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog` |
| **UC Format** | Delta |
| **UC Partitioned By** | OccurredDateID (daily or monthly range) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PositionChangeLog is the audit trail for position state changes. Every time a position's amount, stop-loss rate, settlement flag, or lot count is modified after the initial open, a change log entry is created. This allows analysts to reconstruct the exact state of a position at any historical point in time.

Key use cases:
- **IsSettled tracking**: When a stock position transitions to "settled" status, the log records PreviousIsSettled vs IsSettled. The SP_Dim_Position_DL_To_Synapse ETL reads this table to backfill the correct IsSettled value on Dim_Position.
- **Amount corrections**: When a position's Amount or StopRate changes (e.g., partial close, margin call adjustment), the log records PreviousAmount and AmountChanged. The Dim_Position ETL uses ChangeTypeID=12 entries to apply cumulative amount corrections.
- **Initial open event**: ChangeTypeID=0 records the initial position open event -- used to detect the first appearance of a position in the changelog (primarily for hedge server tracking in SP_Dim_Position_DL_To_Synapse).

Data source is `etoro_History_PositionChangeLog` loaded daily via DELETE (yesterday+) then INSERT (from yesterday). As of 2025-01-05, ALL ChangeTypeIDs are loaded (previously restricted to IDs 1, 5, 11, 12, 13 only).

---

## 2. Business Logic

### 2.1 Change Types

**What**: Classification of what kind of position modification occurred.

**Columns Involved**: `ChangeTypeID`

**Rules**:
- ChangeTypeID=0: Initial open event (position first appears in changelog). Used to find OpenDateID for new positions entering the hedge server snapshot.
- ChangeTypeID=1: Rate/SL-TP change (StopRate or LimitRate modification).
- ChangeTypeID=2: Unspecified change -- seen in live data (requires domain expert clarification).
- ChangeTypeID=5: Added 2024-04-30 -- purpose requires clarification.
- ChangeTypeID=11: Partial close related event.
- ChangeTypeID=12: Amount adjustment -- summed cumulatively to correct Dim_Position.Amount for same-day modifications.
- ChangeTypeID=13: Purpose requires clarification.
- Before 2025-01-05: Only IDs 1, 5, 11, 12, 13 were loaded. ChangeTypeID=0, 2, and others were excluded. Historical rows for these types before 2025-01-05 may be absent.

**Note**: No upstream wiki exists enumerating the official ChangeTypeID names. Values above are inferred from SP code. All should be treated as Tier 4 [UNVERIFIED] until confirmed by domain expert.

### 2.2 State Tracking (Before/After Columns)

**What**: Each row captures the before and after state for the changed metric.

**Columns Involved**: `PreviousAmount`, `AmountChanged`, `NewAmount`, `PreviousStopRate`, `StopRate`, `PreviousIsSettled`, `IsSettled`, `PreviousAmountInUnits`, `AmountInUnits`, `PreviousLotCountDecimal`, `LotCountDecimal`

**Rules**:
- Each change captures the previous value, the delta (AmountChanged), and the new value.
- `AmountChanged` = NewAmount - PreviousAmount (can be negative for reductions).
- Multiple rows can exist per PositionID on the same day (same OccurredDateID) -- particularly for ChangeTypeID=12 (amount adjustments), which are summed via SUM(AmountChanged) GROUP BY PositionID in the Dim_Position ETL.
- `PreviousIsSettled` / `IsSettled` are cast to int (0/1) from bit in staging. NULL is possible if the event didn't involve a settlement change.
- The **most recent** changelog event for a PositionID at ChangeTypeID=0 (ROW_NUMBER by Occurred ASC, rn=1) is used in the Dim_Position ETL to correct IsSettled for open positions.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)**: Co-located with Dim_Position for efficient JOINs on PositionID. Date-range queries should also include OccurredDateID.

**CLUSTERED INDEX (OccurredDateID)**: Efficient for date-range scans on when changes occurred. Always include an OccurredDateID range filter.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog`. Always filter on OccurredDateID for partition pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All changes for a specific position | WHERE PositionID = X ORDER BY Occurred |
| Settlement changes on a date | WHERE OccurredDateID = YYYYMMDD AND PreviousIsSettled IS NOT NULL |
| Amount-adjusted positions | WHERE ChangeTypeID = 12 AND OccurredDateID = YYYYMMDD |
| Initial open events | WHERE ChangeTypeID = 0 AND OccurredDateID = YYYYMMDD |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Enrich position with change history |
| DWH_dbo.Dim_Customer | ON CID | Customer-level change analysis |

### 3.4 Gotchas

- **Multiple rows per position per day**: A position can have many changelog entries on the same day. Do NOT assume one row per (PositionID, OccurredDateID).
- **Historical completeness gap**: Before 2025-01-05, only ChangeTypeIDs 1, 5, 11, 12, 13 were loaded. Earlier history for ChangeTypeIDs 0, 2, etc. is missing.
- **ChangeTypeID values are undocumented**: No official lookup table for ChangeTypeID exists in DWH. The meanings above are inferred from SP code patterns.
- **AmountChanged may be 0**: Seen in live data -- a row with AmountChanged=0 may represent a rate-only change (StopRate update) with no amount modification.
- **PreviousIsSettled can be NULL**: If the change event didn't involve settlement status, both IsSettled and PreviousIsSettled may be NULL.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| * | Tier 4 - Inferred from name/code | (Tier 4 - [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 2 | CID | int | YES | Customer ID who owns the position. Nullable (some system positions may not have CID). (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 3 | Occurred | datetime | NO | Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 4 | OccurredDateID | int | YES | ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 5 | ChangeTypeID | tinyint | YES | Type of change event. Known codes: 0=Initial open, 1=Rate change, 2=Unknown, 5=Unknown (added 2024), 11=Partial close event, 12=Amount adjustment, 13=Unknown. No official lookup table in DWH. (Tier 4 - [UNVERIFIED]) |
| 6 | PreviousAmount | money | NO | Position amount (USD) before this change. NOT NULL -- always captured. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 7 | AmountChanged | money | NO | Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 8 | NewAmount | numeric(16,8) | YES | Position amount after this change. Nullable -- may be absent for non-amount change types. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 9 | PreviousIsSettled | int | YES | Before the change: 1 = real asset, 0 = CFD asset. Cast from bit in staging. NULL if this event did not involve a settlement change. (Tier 5 — Expert Review) |
| 10 | IsSettled | int | YES | After the change: 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 11 | PreviousStopRate | numeric(16,8) | NO | Stop-loss rate before this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 12 | StopRate | numeric(16,8) | NO | Stop-loss rate after this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 13 | PreviousAmountInUnits | numeric(16,6) | YES | Unit count (shares/coins) before this change. Added for futures/unit-based positions. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 14 | AmountInUnits | numeric(16,6) | YES | Unit count after this change. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 15 | LotCountDecimal | decimal(38,18) | YES | New lot count after change. Added 2024-11-07 (Inbal BML) for futures project. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 16 | PreviousLotCountDecimal | decimal(38,18) | YES | Lot count before this change. Added 2024-11-07. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 17 | UpdateDate | datetime | NO | ETL load timestamp (GETDATE()). Not from production source. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| PositionID | etoro_History_PositionChangeLog | PositionID | passthrough |
| CID | etoro_History_PositionChangeLog | CID | passthrough |
| Occurred | etoro_History_PositionChangeLog | Occurred | passthrough |
| OccurredDateID | -- | Occurred | ETL-computed: CAST(CONVERT(VARCHAR(8), Occurred, 112) AS INT) |
| ChangeTypeID | etoro_History_PositionChangeLog | ChangeTypeID | passthrough |
| PreviousAmount | etoro_History_PositionChangeLog | PreviousAmount | passthrough |
| AmountChanged | etoro_History_PositionChangeLog | AmountChanged | passthrough |
| NewAmount | etoro_History_PositionChangeLog | NewAmount | passthrough |
| PreviousIsSettled | etoro_History_PositionChangeLog | PreviousIsSettled | ETL: CAST(PreviousIsSettled AS INT) |
| IsSettled | etoro_History_PositionChangeLog | IsSettled | ETL: CAST(IsSettled AS INT) |
| PreviousStopRate | etoro_History_PositionChangeLog | PreviousStopRate | passthrough |
| StopRate | etoro_History_PositionChangeLog | StopRate | passthrough |
| PreviousAmountInUnits | etoro_History_PositionChangeLog | PreviousAmountInUnits | passthrough |
| AmountInUnits | etoro_History_PositionChangeLog | AmountInUnits | passthrough |
| LotCountDecimal | etoro_History_PositionChangeLog | LotCountDecimal | passthrough |
| PreviousLotCountDecimal | etoro_History_PositionChangeLog | PreviousLotCountDecimal | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.History.PositionChangeLog
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/History/PositionChangeLog/
  -> DWH_staging.etoro_History_PositionChangeLog
  -> SP_Dim_PositionChangeLog_DL_To_Synapse (DELETE yesterday+ then INSERT)
  -> DWH_dbo.Dim_PositionChangeLog
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.History.PositionChangeLog | Production position change audit (etoroDB-REAL) |
| Lake | Bronze/etoro/History/PositionChangeLog/ | Daily full-load via Generic Pipeline |
| Staging | DWH_staging.etoro_History_PositionChangeLog | Raw staging import |
| ETL Step 1 | SP_Dim_PositionChangeLog_DL_To_Synapse | DELETE FROM Dim_PositionChangeLog WHERE OccurredDateID >= @YesterdayID |
| ETL Step 2 | SP_Dim_PositionChangeLog_DL_To_Synapse | INSERT from staging WHERE Occurred >= @Yesterday (all ChangeTypeIDs as of 2025-01-05) |
| Target | DWH_dbo.Dim_PositionChangeLog | 17 cols, HASH(PositionID) + CCI on OccurredDateID |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Position | PositionID | The position this log entry belongs to |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Dim_Position_DL_To_Synapse | PositionID | Reads IsSettled corrections and Amount adjustments to apply to Dim_Position |
| DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog | PositionID | Reads initial open events (ChangeTypeID=0) for hedge server snapshot initialization |

---

## 7. Sample Queries

### 7.1 All changes for a specific position

```sql
SELECT  PositionID, Occurred, ChangeTypeID,
        PreviousAmount, AmountChanged, NewAmount,
        PreviousIsSettled, IsSettled,
        PreviousStopRate, StopRate
FROM    [DWH_dbo].[Dim_PositionChangeLog]
WHERE   PositionID = 3358743021
  AND   OccurredDateID BETWEEN 20260101 AND 20260310
ORDER BY Occurred;
```

### 7.2 Settlement status changes on a specific date

```sql
SELECT  PositionID, CID, Occurred, PreviousIsSettled, IsSettled
FROM    [DWH_dbo].[Dim_PositionChangeLog]
WHERE   OccurredDateID = 20260310
  AND   PreviousIsSettled IS NOT NULL
  AND   PreviousIsSettled <> IsSettled
ORDER BY Occurred;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (***) | Phases: 14/14 (full pipeline)*
*Tiers: 0 T1, 16 T2, 0 T3, 1 T4 [UNVERIFIED] (ChangeTypeID mapping), 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: DWH_dbo.Dim_PositionChangeLog | Type: Table | Production Source: etoro.History.PositionChangeLog*


### Upstream `DWH_dbo.Fact_CurrencyPriceWithSplit` — synapse
- **Resolved as**: `DWH_dbo.Fact_CurrencyPriceWithSplit`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md`

# DWH_dbo.Fact_CurrencyPriceWithSplit

> Daily price snapshot fact table capturing bid/ask prices per financial instrument per day, with spread-adjusted values, split-adjusted history for corporate-action dates, and pre-computed USD conversion rates.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (Data Lake export) |
| **Refresh** | Daily (per-date incremental via @dt parameter) |
| | |
| **Synapse Distribution** | HASH(InstrumentID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + NONCLUSTERED(OccurredDateID) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit |
| **UC Format** | Delta (Merge strategy, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

Fact_CurrencyPriceWithSplit is the DWH's authoritative daily price reference table. It stores one or more price rows per instrument per calendar day, including the raw bid/ask prices, spread-adjusted prices (AskSpreaded/BidSpreaded), and the last execution rate (RateLastEx). The `isvalid` flag marks whether a given price row was the active price at end-of-day. This table is the primary source for historical price look-ups used in P&L calculations across the warehouse.

Data originates from the PriceLog Candles pipeline in the Data Lake. The staging view `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` delivers daily candlestick prices for all instruments. On dates when a stock split occurs (identified via `DWH_staging.etoro_History_SplitRatio`), the ETL switches to `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which provides historically-adjusted prices for the affected instruments.

Loaded daily by `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)`. The SP deletes all rows for the given date, reloads from staging, then applies a split-branch if split events exist. A final UPDATE pass computes `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` using cross-currency logic to normalize instrument prices to USD. Data covers 2009-06-15 to the present with approximately 17.2M rows across 15,400+ distinct instruments.

---

## 2. Business Logic

### 2.1 Stock Split Price Adjustment

**What**: When a corporate action (stock split) occurs on a given date, prices for the affected instrument must be reloaded using split-adjusted history rather than the standard daily candle.

**Columns Involved**: `InstrumentID`, `OccurredDateID`, `AskSpreaded`, `BidSpreaded`, `Ask`, `Bid`, `RateLastEx`

**Rules**:
- On each daily run, the SP checks `DWH_staging.etoro_History_SplitRatio` for splits on `@dt`
- If split records exist (`@CountRowsSplit > 0`), all rows for the affected `InstrumentID` values are deleted from Fact_CurrencyPriceWithSplit
- Replacement rows are loaded from `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which contains the retroactively adjusted price series
- `ConvertRateIsBuy_1/0` from the pre-split date are preserved via a `#ConvertRateIsBuy` temp table join

**Diagram**:
```
Daily run:
  DELETE WHERE OccurredDateID = @DateID
  INSERT FROM PriceLog_Candles_CurrencyPriceMaxDateWithSplitView

Split check:
  IF etoro_History_SplitRatio has rows for @dt:
    DELETE affected instruments
    INSERT FROM PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory
    PRESERVE ConvertRates from pre-split data via #ConvertRateIsBuy temp table
```

### 2.2 USD Conversion Rate Computation

**What**: After loading prices, the SP computes two pre-calculated USD conversion rates per instrument per day, one for buy-side positions and one for sell-side. These rates allow downstream consumers to convert instrument P&L to USD without re-deriving the currency cross-rate.

**Columns Involved**: `ConvertRateIsBuy_1`, `ConvertRateIsBuy_0`, `Ask`, `Bid`, `InstrumentID`

**Rules**:
- Instrument currency pairs are loaded from `DWH_staging.etoro_Trade_GetInstrument` into `Ext_FCPWS_Instrument`
- If `SellCurrencyID = 1` (USD is the sell/quote currency): rate = 1.00 (already in USD)
- If `BuyCurrencyID = 1` (USD is the base currency): IsBuy_1 = 1/Bid, IsBuy_0 = 1/Ask
- If neither currency is USD: find a bridging instrument with USD as base/quote and apply cross-rate
- `ConvertRateIsBuy_1` is for buy-side positions (IsBuy=1); `ConvertRateIsBuy_0` for sell-side

**Diagram**:
```
For each instrument on @DateID:
  If SellCurrencyID = 1 (USD quote):   ConvertRate = 1.00
  If BuyCurrencyID = 1 (USD base):     ConvertRate = 1/Bid (buy) or 1/Ask (sell)
  If no direct USD pair:               ConvertRate via cross-rate through a USD-paired instrument
  Null if no cross-rate found:         COALESCE(..., 1.00) fallback
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `InstrumentID` with a CLUSTERED COLUMNSTORE index. Always include `InstrumentID` in JOIN conditions for co-location with Dim_Instrument. A secondary NONCLUSTERED index on `OccurredDateID` supports date-range lookups. For date-range queries, filter on `OccurredDateID` (integer YYYYMMDD) rather than `OccurredDate` to leverage the NCI.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the table is registered as `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, stored as Delta with a Merge copy strategy (daily refresh). Partition and Z-ORDER columns are resolved during the write-objects deployment phase.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get USD conversion rate for an instrument on a specific date | `WHERE InstrumentID = @id AND OccurredDateID = @dateID AND isvalid = 1` |
| Full price history for an instrument | `WHERE InstrumentID = @id ORDER BY OccurredDate` |
| End-of-day price for all instruments on a date | `WHERE OccurredDateID = @dateID AND isvalid = 1` |
| Instruments with split events on a date | JOIN to `Ext_FCPWS_History_SplitRatio` on InstrumentID and date range |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON f.InstrumentID = di.InstrumentID | Resolve instrument name, symbol, type |
| DWH_dbo.Dim_Date | ON f.OccurredDateID = dd.DateID | Resolve date to year/month/quarter |
| DWH_dbo.Ext_FCPWS_Instrument | ON f.InstrumentID = ei.InstrumentID | Get buy/sell currency pair for the instrument |

### 3.4 Gotchas

- `isvalid = 0` rows (~46% of all rows) represent non-active price records for the day. Most P&L queries should filter `isvalid = 1` to get the effective end-of-day price.
- `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` are NULL for ~1.3M rows (7.5% of the table) where no cross-rate could be computed. Use `ISNULL(..., 1.0)` in downstream calculations or investigate via `Ext_FCPWS_Instrument`.
- The table has 3 distinct `ProviderID` values. Typical analytical queries do not filter on ProviderID, but be aware that multiple providers may contribute prices for the same instrument on the same date.
- `OccurredDateID` is in YYYYMMDD integer format (e.g., 20240113), not a DATE. The NCI is on this column - prefer it for range filters over `OccurredDate`.
- The ETL is date-parameterized (`@dt`). It does NOT do a full reload - it deletes and reloads one date at a time. Gaps can appear if the SP was not run for a date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProviderID | int | YES | Price provider identifier. 3 distinct values in production. Indicates which data provider sourced the price candle. Passed through from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 2 | InstrumentID | int | YES | Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. HASH distribution column - include in all JOINs for optimal Synapse performance. 15,416 distinct instruments in production. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 3 | Occurred | datetime | YES | Exact timestamp when the price was recorded. Sub-day precision. Use OccurredDate or OccurredDateID for date-level aggregations. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 4 | OccurredDate | date | YES | Calendar date of the price record. Date portion of Occurred. Use for date joins or display. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 5 | OccurredDateID | int | YES | Date as YYYYMMDD integer (e.g., 20240113). Secondary NCI index key. Use this column for date-range filters to leverage the NONCLUSTERED index. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 6 | isvalid | int | YES | Row validity flag. 1 = active/valid end-of-day price for this instrument on this date. 0 = non-active record (e.g., intraday snapshot or superseded row). Filter isvalid = 1 for end-of-day analytical queries. ~54% of rows are valid. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 7 | AskSpreaded | numeric(36,12) | YES | Spread-adjusted ask (offer) price for the instrument. The ask price with the broker spread applied. Used in P&L calculations for buy-side opening cost. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 8 | BidSpreaded | numeric(36,12) | YES | Spread-adjusted bid price for the instrument. The bid price with the broker spread applied. Used in P&L calculations for sell-side closing proceeds. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 9 | RateLastEx | numeric(36,12) | YES | Last execution rate for the instrument on this date. The price at which the most recent trade was executed. Reference rate for settlement. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 10 | Ask | numeric(36,12) | YES | Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 11 | Bid | numeric(36,12) | YES | Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 12 | UpdateDate | datetime | NO | DWH load timestamp. Set to GETDATE() at ETL execution time. Not the price timestamp - use Occurred for price time. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 13 | ConvertRateIsBuy_1 | numeric(18,4) | YES | Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 14 | ConvertRateIsBuy_0 | numeric(18,4) | YES | Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProviderID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | ProviderID | Passthrough |
| InstrumentID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | InstrumentID | Passthrough; on split dates from SplitInstHistory variant |
| Occurred | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Occurred | Passthrough |
| OccurredDate | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDate | Passthrough |
| OccurredDateID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDateID | Passthrough |
| isvalid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | isvalid | Passthrough |
| AskSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | AskSpreaded | Passthrough |
| BidSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | BidSpreaded | Passthrough |
| RateLastEx | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | RateLastEx | Passthrough |
| Ask | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Ask | Passthrough |
| Bid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Bid | Passthrough |
| UpdateDate | ETL-computed | N/A | GETDATE() at load time |
| ConvertRateIsBuy_1 | ETL-computed (UPDATE pass) | Bid/Ask cross-rate | CASE on BuyCurrencyID/SellCurrencyID via Ext_FCPWS_Instrument |
| ConvertRateIsBuy_0 | ETL-computed (UPDATE pass) | Bid/Ask cross-rate | CASE on BuyCurrencyID/SellCurrencyID via Ext_FCPWS_Instrument |

No upstream wiki available for DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (Data Lake intermediate staging layer, not documented in DB_Schema wiki).

### 5.2 ETL Pipeline

```
Data Lake (PriceLog/Candles) -> DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView
  -> SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)
    -> DWH_dbo.Fact_CurrencyPriceWithSplit [DELETE for @DateID + INSERT]

Split branch (when etoro_History_SplitRatio has rows for @dt):
  DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory
    -> re-INSERT split-affected instruments
  DWH_staging.etoro_Trade_GetInstrument -> Ext_FCPWS_Instrument
    -> UPDATE ConvertRateIsBuy_1/0 via cross-currency logic
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Daily price candles from Data Lake |
| Split source | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory | Split-adjusted historical prices |
| Split calendar | DWH_staging.etoro_History_SplitRatio | Identifies which instruments had splits on @dt |
| Instrument pairs | DWH_staging.etoro_Trade_GetInstrument | BuyCurrencyID/SellCurrencyID for ConvertRate |
| ETL | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Per-date delete+insert + split branch + ConvertRate UPDATE |
| Target | DWH_dbo.Fact_CurrencyPriceWithSplit | Final DWH daily price table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, symbol, type, asset class |
| OccurredDateID | DWH_dbo.Dim_Date (via Dim_Date.DateID) | Date dimension (year, month, quarter) |
| InstrumentID | DWH_dbo.Ext_FCPWS_Instrument | Currency pair lookup used during ConvertRate computation |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | self-JOIN | ConvertRate computation reads same table for cross-rate |
| DWH_dbo.Fact_CustomerUnrealized_PnL (probable) | InstrumentID + OccurredDateID | Currency conversion for unrealized P&L (verify via SP_Fact_CustomerUnrealized_PnL_* analysis) |

---

## 7. Sample Queries

### 7.1 End-of-day prices for a set of instruments on a date

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    f.OccurredDate,
    f.Ask,
    f.Bid,
    f.AskSpreaded,
    f.BidSpreaded,
    f.RateLastEx,
    f.ConvertRateIsBuy_1,
    f.ConvertRateIsBuy_0
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.OccurredDateID = 20240113
  AND f.isvalid = 1
ORDER BY di.InstrumentDisplayName;
```

### 7.2 Price history for a single instrument over a date range

```sql
SELECT
    f.OccurredDate,
    f.Ask,
    f.Bid,
    (f.Ask + f.Bid) / 2.0 AS MidPrice,
    f.ConvertRateIsBuy_1,
    f.isvalid
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
WHERE f.InstrumentID = 1     -- replace with target InstrumentID
  AND f.OccurredDateID BETWEEN 20240101 AND 20240131
  AND f.isvalid = 1
ORDER BY f.OccurredDate;
```

### 7.3 Instruments with NULL ConvertRate (USD-conversion gap check)

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    COUNT(*) AS rows_with_null_rate
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.ConvertRateIsBuy_1 IS NULL
  AND f.isvalid = 1
GROUP BY f.InstrumentID, di.InstrumentDisplayName
ORDER BY rows_with_null_rate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Fact_CurrencyPriceWithSplit | Type: Table | Production Source: DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_HedgeCost`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_HedgeCost.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_HedgeCost] @Date [DATE] AS
BEGIN

/******************************************************************************************************************************

Author: Sarah Benchitrit
Date: 2020-10-01
Description: HedgeCost
 
**************************
** Change History
**************************
Date                   	Author			SR			Description 
----                    ----------		----		---------------------------
2024-12-24				Sarah			SR-286858	Replace execution log with CopyFromLake
*******************************************************************************************************************************/

--DECLARE @Date DATE = '2023-06-30'
DECLARE @DateInt INT = CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)
--DECLARE @DayBeforeInt INT = CAST(CONVERT(VARCHAR(8), DATEADD(DAY,-1,@Date), 112) AS INT)

IF OBJECT_ID('tempdb..#LP') IS NOT NULL
DROP TABLE #LP

CREATE TABLE #LP
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT el.InstrumentID,
el.HedgeServerID,
CASE WHEN el.HedgeServerID IN (9,102,112,125,126) then 'Real' else 'CFD' END IsSettled,
SUM(Units*(IsBuy*2-1)) as Executed_Units,
SUM(Units*(IsBuy*2-1)*ExecutionRate)/NULLIF(SUM(Units*(IsBuy*2-1)),0) as AvgRate,
SUM(Units*ExecutionRate) AS Volume
FROM CopyFromLake.etoro_Hedge_ExecutionLog el  with (NOLOCK)
JOIN DWH_dbo.Dim_Instrument di  with (NOLOCK)
on el.InstrumentID=di.InstrumentID
WHERE SellCurrencyID = 1 AND InstrumentTypeID IN (5,6) AND CAST(ExecutionTime as Date) = @Date  and Success = 1
GROUP BY (CASE WHEN el.HedgeServerID IN (9,102,112,125,126) then 'Real' else 'CFD' END), el.InstrumentID, el.HedgeServerID

Create Clustered index #Final on #LP (InstrumentID,HedgeServerID,IsSettled)
--SELECT * FROM #LP


--DECLARE @DateInt INT = 20210128

IF OBJECT_ID('tempdb..#Position') IS NOT NULL
DROP TABLE #Position

CREATE TABLE #Position
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT dp.PositionID,
dp.InstrumentID,
dp.HedgeServerID,
IsSettled,
IsBuy,
AmountInUnitsDecimal,
Volume,
InitForexRate AS ForexRate,
FullCommissionByUnits FullCommissionOnClose
--FullCommissionOnClose
FROM DWH_dbo.Dim_Position dp   with (NOLOCK)
JOIN DWH_dbo.Dim_Instrument di  with (NOLOCK)
on dp.InstrumentID=di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc  with (NOLOCK)
ON dc.RealCID=dp.CID
WHERE SellCurrencyID = 1 AND InstrumentTypeID IN (5,6) AND OpenDateID=@DateInt AND dc.IsValidCustomer=1
UNION all
SELECT dp.PositionID,
dp.InstrumentID,
dp.HedgeServerID,
IsSettled,
CASE WHEN IsBuy=0 THEN 1 ELSE 0 END IsBuy,
AmountInUnitsDecimal,
Volume,
EndForexRate AS ForexRate,
FullCommissionOnClose
FROM DWH_dbo.Dim_Position dp   with (NOLOCK)
JOIN DWH_dbo.Dim_Instrument di  with (NOLOCK)
on dp.InstrumentID=di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc  with (NOLOCK)
ON dc.RealCID=dp.CID
WHERE SellCurrencyID = 1 AND InstrumentTypeID IN (5,6) AND CloseDateID=@DateInt AND dc.IsValidCustomer=1

Create Clustered index #Position on #Position (PositionID)
--DECLARE @DateInt INT = 20210128

IF OBJECT_ID('tempdb..#IsSettled_pcl') IS NOT NULL
DROP TABLE #IsSettled_pcl

CREATE TABLE #IsSettled_pcl
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT a.PositionID, 
  ISNULL(a.PreviousIsSettled,a.IsSettled) IsSettled
  FROM (SELECT DISTINCT p.PositionID,
				p.IsSettled,
				pcl.Occurred pcl_Occurred,
				pcl.OccurredDateID,
				pcl.PreviousIsSettled,
				pcl.IsSettled IsSettledAfterChange,
				ROW_NUMBER() OVER (PARTITION BY p.PositionID ORDER BY pcl.Occurred) RN_IsSettled
		FROM #Position p
		LEFT JOIN DWH_dbo.[Dim_PositionChangeLog]  pcl   with (NOLOCK)
		ON p.PositionID = pcl.PositionID AND pcl.ChangeTypeID=13 AND pcl.OccurredDateID> @DateInt
	) a
WHERE a.RN_IsSettled=1

Create Clustered index #IsSettled_pcl on #IsSettled_pcl (PositionID)


IF OBJECT_ID('tempdb..#Position_IsSettled') IS NOT NULL
DROP TABLE #Position_IsSettled

CREATE TABLE #Position_IsSettled
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT p.PositionID
	  ,p.InstrumentID
	  ,p.HedgeServerID
	  ,CASE WHEN isp.IsSettled=1 THEN 'Real' ELSE 'CFD' END IsSettled
	  ,p.IsBuy
	  ,p.AmountInUnitsDecimal
	  ,p.Volume
	  ,p.ForexRate
	  ,p.FullCommissionOnClose
FROM #Position p
LEFT JOIN #IsSettled_pcl isp
ON p.PositionID = isp.PositionID

Create Clustered index #Position_IsSettled on #Position_IsSettled (IsSettled, HedgeServerID, InstrumentID)

IF OBJECT_ID('tempdb..#Clients') IS NOT NULL
DROP TABLE #Clients

CREATE TABLE #Clients
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT InstrumentID
	,HedgeServerID
	,IsSettled
	,ISNULL(SUM((IsBuy*2-1)*AmountInUnitsDecimal),0) as NetUnits
	,SUM(Volume) as Volume
	,SUM((IsBuy*2-1)*AmountInUnitsDecimal*ForexRate)/NULLIF(SUM((IsBuy*2-1)*AmountInUnitsDecimal),0) AS AvgRate
	,SUM(FullCommissionOnClose)/2 AS FullCommissionOnClose
FROM #Position_IsSettled
--FROM #Position
GROUP BY IsSettled, InstrumentID, HedgeServerID

Create Clustered index #Clients on #Clients (IsSettled, InstrumentID, HedgeServerID)

IF OBJECT_ID('tempdb..#Final') IS NOT NULL
DROP TABLE #Final

CREATE TABLE #Final
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT c.InstrumentID
	,c.HedgeServerID
	,c.IsSettled
   ,c.NetUnits
   ,c.Volume
   ,SUM(c.AvgRate*c.NetUnits)/NULLIF(SUM(c.NetUnits),0) as AvgRate
   ,c.FullCommissionOnClose AS FullCommission
   ,lp.Executed_Units AS LP_Executed_Units
   ,lp.AvgRate AS LP_Avg_Rate
   ,lp.Volume AS LP_Volume
	,SUM(z.RealizedCommission) AS RealizedCommission
	,v.VarCommission AS VariableSpread
FROM #Clients c
LEFT JOIN #LP lp 
ON c.InstrumentID=lp.InstrumentID and c.IsSettled=lp.IsSettled AND c.HedgeServerID = lp.HedgeServerID
LEFT JOIN Dealing_dbo.Dealing_DailyZeroPnL_Stocks z 
ON z.Date = @Date AND c.InstrumentID = z.InstrumentID AND c.HedgeServerID = z.HedgeServerID AND z.IsCFD = (CASE WHEN c.IsSettled = 'CFD' THEN 1 ELSE 0 END)
LEFT JOIN BI_DB_dbo.BI_DB_VarCommission v
ON v.DateID = @DateInt AND c.InstrumentID = v.InstrumentID AND v.IsSettled = (CASE WHEN c.IsSettled = 'Real' THEN 1 ELSE 0 END) AND c.HedgeServerID = v.HedgeServerID
GROUP BY c.InstrumentID
	,c.HedgeServerID
	,c.IsSettled
   ,c.NetUnits
   ,c.Volume
   ,c.FullCommissionOnClose
   ,lp.Executed_Units
   ,lp.AvgRate
   ,lp.Volume
   ,v.VarCommission

Create Clustered index #Final on #Final (InstrumentID)
--   DECLARE @Date DATE = '2021-03-03'
--DECLARE @DateInt INT = CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)



DELETE FROM [Dealing_dbo].[Dealing_HedgeCost]
WHERE Date = @Date

INSERT INTO [Dealing_dbo].[Dealing_HedgeCost]
(Date
	,InstrumentID
	,Name 
	,IsSettled 
	,Clients_Units
	,AvgRateClientsNoSpread 
	,VolumeMarket
	,LP_Executed_Units
	,LP_Avg_Rate 
	,LP_Volume
	,HC 
	,UpdateDate
	,HedgeServerID
	,FullCommission
	,VariableSpread)

SELECT @Date
	,f.InstrumentID
	,Name
	,f.IsSettled
	,NetUnits AS Clients_Units
	,ISNULL((NetUnits*AvgRate-f.FullCommission)/NULLIF((NetUnits),0),0) as AvgRateClientsNoSpread
	,Volume as VolumeMarket
	,ISNULL(LP_Executed_Units,0) as LP_Executed_Units
	,ISNULL(LP_Avg_Rate,0) as LP_Avg_Rate
	,ISNULL(LP_Volume,0)  as LP_Volume
	,(p.AskSpreaded*(ISNULL(NetUnits,0))-(ISNULL(NetUnits,0)*ISNULL(AvgRate,0)-ISNULL(f.FullCommission,0)))-(p.AskSpreaded*(ISNULL(LP_Executed_Units,0))-(ISNULL(LP_Executed_Units,0)*ISNULL(LP_Avg_Rate,0))) as HC
	,GETDATE() UpdateDate
	,f.HedgeServerID
	,f.RealizedCommission AS FullCommission
	,f.VariableSpread
FROM #Final f
JOIN DWH_dbo.Dim_Instrument i with (NOLOCK)
ON f.InstrumentID=i.InstrumentID
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit p
on p.OccurredDateID = @DateInt and p.InstrumentID=f.InstrumentID


END;
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `etoro.Hedge.ExecutionLog` | production | Hedge | ExecutionLog | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Hedge\Tables\Hedge.ExecutionLog.md` |
| `Dealing_dbo.SP_HedgeCost` | synapse_sp | Dealing_dbo | SP_HedgeCost | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_HedgeCost.sql` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `CopyFromLake.etoro_Hedge_ExecutionLog` | unresolved | CopyFromLake | etoro_Hedge_ExecutionLog | `—` |
| `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` | synapse | Dealing_dbo | Dealing_DailyZeroPnL_Stocks | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_DailyZeroPnL_Stocks.md` |
| `BI_DB_dbo.BI_DB_VarCommission` | synapse | BI_DB_dbo | BI_DB_VarCommission | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_VarCommission.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_PositionChangeLog` | synapse | DWH_dbo | Dim_PositionChangeLog | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PositionChangeLog.md` |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | synapse | DWH_dbo | Fact_CurrencyPriceWithSplit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |

