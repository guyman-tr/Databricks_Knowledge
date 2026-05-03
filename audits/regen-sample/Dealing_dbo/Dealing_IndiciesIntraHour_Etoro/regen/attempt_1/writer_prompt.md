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

## ⛔ PHASE 3 DISTRIBUTION CAP

Phase 3 (distribution analysis) is capped at **at most 3 categorical columns**
per object. Pick those whose names match the regex
`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`.
Skip free-text columns entirely (Email, Description, Comment, Note, Address,
Name, Url, Subject, Body, Reason).

If fewer than 3 columns match the regex, run distribution queries on however
many DO match — running zero distribution queries is OK if the table has no
obviously-categorical columns.

---

## ⛔ OUTPUT DIRECTORY GUARANTEE

The directory listed under **Absolute output directory** in the Object Header
ALREADY EXISTS, was created by the harness, and is empty (apart from the
writer_prompt.md you are reading). DO NOT run `Bash ls` to check it. DO NOT
run `Bash mkdir`. Just call `Write` directly with the absolute paths from the
Object Header for the three required files.

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
   **Tier 2** with the transform stated. The source after `(Tier 2 — …)` MUST
   name the **upstream TABLE the transform reads from**, NOT the SP that
   performs the transform. The SP is the tool; the table is the data source.
   Examples:
   - `ABS(Fact_Deposit_State.Amount)` → `(Tier 2 — Fact_Deposit_State)`
   - `CASE WHEN x.IsSettled = 1 THEN 'Real' END` → `(Tier 2 — Fact_BillingDeposit)`
   - Pure passthrough from a DWH fact (no production wiki) →
     `(Tier 2 — Fact_X)`, NOT `(Tier 2 — SP_X)`.
   - Multi-source UNION → list both tables, slash-separated:
     `(Tier 2 — Fact_Deposit_State / Fact_Cashout_State)`.
   The ONLY case where an SP name belongs in the source is when the column is
   purely synthesized inside the SP with no input table column (e.g.
   `GETDATE()`, `@StartDateID`, fixed literal). Then write `(Tier 2 — SP_X)`.
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
- **Object**: `Dealing_IndiciesIntraHour_Etoro`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_IndiciesIntraHour_Etoro/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_IndiciesIntraHour_Etoro\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_IndiciesIntraHour_Etoro\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_IndiciesIntraHour_Etoro.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_IndiciesIntraHour_Etoro`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_IndiciesIntraHour_Etoro.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_IndiciesIntraHour_Etoro]
(
	[Date] [date] NULL,
	[InstrumentID] [int] NULL,
	[Minute_Start] [datetime] NULL,
	[Minute_End] [datetime] NULL,
	[LiquidityAccountName] [varchar](max) NULL,
	[LiquidityAccountID] [int] NULL,
	[VolumeBuy] [float] NULL,
	[VolumeSell] [float] NULL,
	[Units_NOP] [float] NULL,
	[NOP] [float] NULL,
	[ValueStart] [float] NULL,
	[ValueEnd] [float] NULL,
	[ValueRealized] [float] NULL,
	[UpdateDate] [datetime] NULL,
	[HedgeServerID] [int] NULL
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

Found 3 upstream wiki(s). Read EACH one in full.


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

### Upstream `Dealing_dbo.Dealing_IndiciesIntraHour_Clients` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_IndiciesIntraHour_Clients`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_IndiciesIntraHour_Clients.md`

# Dealing_dbo.Dealing_IndiciesIntraHour_Clients

> ~13.3M-row minute-level aggregation table capturing client-side intra-hour hedging activity for three index instruments (IDs 27, 28, 32) from 2022-05-22 to present — recording per-minute buy/sell volumes, open position values, unrealized and realized P&L, and bid/ask prices, sourced from Dim_Position + PriceLog via SP_IntraHourIndexReport daily.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice via SP_IntraHourIndexReport |
| **Refresh** | Daily (1440 min, Append via Generic Pipeline) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| | |
| **UC Target** | `general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients` |
| **UC Format** | Delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Append) |

---

## 1. Business Meaning

Dealing_IndiciesIntraHour_Clients is the client-side component of the intra-hour hedging activity report, tracking minute-by-minute trading metrics for three hardcoded index instruments: S&P 500 (InstrumentID=27), DJ30 (InstrumentID=28), and GER30 (InstrumentID=32). The table captures what eToro's clients are doing in aggregate at each minute of the trading day — how much they're buying, selling, holding in open positions, and realizing in P&L.

The companion table `Dealing_dbo.Dealing_IndiciesIntraHour_Etoro` records the eToro hedging side for the same instruments using execution log and netting data from liquidity providers.

**Data volume**: ~13.3M rows spanning 2022-05-22 to 2026-04-26. Each day produces ~8,638 rows (1,440 minutes × 3 instruments × active HedgeServerIDs). Annual volumes grew from ~907K (2022, partial year) to ~5.8M (2024).

**ETL pattern**: `SP_IntraHourIndexReport @Date` runs daily. It DELETEs existing rows for @Date, then INSERTs fresh aggregated data. The SP:
1. Resolves index instruments to their hedge-mapped counterparts via PortfolioConversionConfigurations
2. Generates a minute-by-minute grid for the day
3. Pulls prices from CopyFromLake.PriceLog_History_CurrencyPrice (with gap-filling via OUTER APPLY)
4. Aggregates client positions from Dim_Position (filtered to IsValidCustomer=1 via Dim_Customer)
5. Computes volumes, open position values, unrealized P&L, and realized P&L per minute per instrument per HedgeServerID

**HedgeServerID**: Added 2024-04-30 (SR-249626). Prior to this, hedge server filters were hardcoded; after, HedgeServerID became a grouping dimension. Current active servers: 5, 8, 20, 1776. Older rows have NULL HedgeServerID.

---

## 2. Business Logic

### 2.1 Volume Calculation (VolumeBuy / VolumeSell)

**What**: Aggregated USD trade volumes per minute, combining new opens and closes.

**Columns Involved**: `VolumeBuy`, `VolumeSell`

**Rules**:
- For positions **opened** in the minute: VolumeBuy = SUM(Volume) where IsBuy=1; VolumeSell = SUM(Volume) where IsBuy=0
- For positions **closed** in the minute: VolumeBuy = SUM(VolumeOnClose) where IsBuy=0 (closing a sell is a buy); VolumeSell = SUM(VolumeOnClose) where IsBuy=1 (closing a buy is a sell)
- Both UNIONed and re-aggregated. ISNULL(,0) applied on final INSERT.
- Volume values from Dim_Position are ETL-computed approximations (ROUND of AmountInUnitsDecimal * rate * conversion)

### 2.2 Open Position Values (OP_Buy / OP_Sell / OP_Buy_Units / OP_Sell_Units)

**What**: Total open position exposure at each minute, split by direction.

**Columns Involved**: `OP_Buy_Units`, `OP_Buy`, `OP_Sell_Units`, `OP_Sell`

**Rules**:
- OP_Buy_Units = SUM(AmountInUnitsDecimal) for IsBuy=1 positions open at that minute
- OP_Buy = SUM(AmountInUnitsDecimal × FirstBid × ConversionFirst) — USD-equivalent value of all buy open positions, priced at start-of-minute bid
- OP_Sell_Units / OP_Sell = same for IsBuy=0 positions, using FirstAsk
- A position is "open at minute X" if OpenOccurred <= X AND (CloseOccurred > X OR CloseDateID=0)
- Positions opened in the same minute are excluded from the metric (CASE WHEN DATEADD(...) = pf.fromMinute THEN 0)

### 2.3 Unrealized P&L (UnrealizedStart / UnrealizedEnd)

**What**: Aggregate unrealized P&L for all open client positions at start and end of each minute.

**Columns Involved**: `UnrealizedStart`, `UnrealizedEnd`

**Rules**:
- UnrealizedStart = SUM(AmountInUnitsDecimal × ConversionFirst × (price_delta from InitForexRate) + FullCommissionByUnits) for all positions open at that minute (excluding newly opened ones)
- For buy positions: price_delta = FirstBid − InitForexRate
- For sell positions: price_delta = InitForexRate − FirstAsk
- UnrealizedEnd = UnrealizedStart of the **next** minute (self-join: o2.fromMinute = o.toMinute). NULL for the last minute of the day.

### 2.4 Realized P&L

**What**: Total realized P&L from positions closing in the minute.

**Columns Involved**: `Realized`

**Rules**:
- Realized = SUM(NetProfit + FullCommissionOnClose) for positions closing in the minute (CloseDateID = @DateInt)
- ISNULL(,0) on final INSERT — 0 for minutes with no closes

### 2.5 Price Smoothing (Bid / Ask)

**What**: Start-of-minute bid/ask prices with gap-filling for missing intervals.

**Columns Involved**: `Bid`, `Ask`

**Rules**:
- Raw prices from PriceLog_History_CurrencyPrice, bucketed to 1-minute intervals (last price per minute wins, via ROW_NUMBER ORDER BY Occurred DESC)
- Prices are mapped from hedge instruments to source instruments via PortfolioConversionConfigurations (UNIONed)
- NULL-minute gaps are forward-filled using OUTER APPLY (find latest non-NULL price before this minute)
- Bid = LAG(LastBid, 1) = previous minute's last bid (i.e., the price at the START of the current minute)
- Ask = LAG(LastAsk, 1) = same logic for ask

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: All data evenly spread across distributions with no co-location benefit. No single column dominates query patterns enough for HASH distribution.

**Clustered Index on [Date]**: Date-range queries are efficient. Always include `WHERE [Date] BETWEEN ... AND ...` for partition-like behavior.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Intra-day volume profile for a specific day | `WHERE [Date] = '2026-04-25' AND InstrumentID = 27 ORDER BY Minute_Start` |
| Daily totals for an instrument | `SELECT [Date], SUM(VolumeBuy), SUM(VolumeSell) WHERE InstrumentID = 28 GROUP BY [Date]` |
| Peak unrealized exposure | `SELECT TOP 10 * WHERE InstrumentID = 32 ORDER BY ABS(UnrealizedStart) DESC` |
| Compare buy vs sell open position value | `SELECT Minute_Start, OP_Buy, OP_Sell WHERE [Date] = '2026-04-25'` |
| Realized P&L by minute | `WHERE Realized <> 0 AND [Date] = '2026-04-25' ORDER BY Minute_Start` |
| Client vs eToro comparison | JOIN with `Dealing_IndiciesIntraHour_Etoro` ON Date, Minute_Start, InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | ON Date, Minute_Start, InstrumentID, HedgeServerID | Compare client-side vs eToro hedging activity |

### 3.4 Gotchas

- **Only 3 instruments**: This table ONLY contains data for InstrumentIDs 27, 28, 32 (major indices). Do not expect other instruments.
- **HedgeServerID is NULL for pre-2024 data**: The column was added 2024-04-30 (SR-249626). Older rows have NULL HedgeServerID; newer rows have values like 5, 8, 20, 1776.
- **UnrealizedEnd can be NULL**: For the last minute of the day, there is no "next minute" to self-join, so UnrealizedEnd = NULL.
- **Volume is in USD (approximate)**: VolumeBuy/VolumeSell inherit Volume/VolumeOnClose from Dim_Position, which are ETL-computed rounded approximations.
- **Bid/Ask are start-of-minute prices**: They represent the previous minute's last traded price (LAG), not the current minute's price.
- **Minute_Start/Minute_End are datetime, not time**: They include the full date+time (e.g., '2026-04-25 14:30:00').
- **Delete-insert pattern per day**: Re-running SP_IntraHourIndexReport for a past date will replace all rows for that date.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — description copied as-is from Dim_Position |
| Tier 2 | ETL-computed in SP_IntraHourIndexReport — transform documented from SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trading date extracted from the minute bucket. CONVERT(DATE, fromMinute). One row per instrument per minute per HedgeServerID per date. (Tier 2 — SP_IntraHourIndexReport) |
| 2 | Minute_Start | datetime | YES | Start of the 1-minute time bucket (e.g., '2026-04-25 14:30:00'). Generated from a minute grid covering the full 24-hour day. (Tier 2 — SP_IntraHourIndexReport) |
| 3 | Minute_End | datetime | YES | End of the 1-minute time bucket (Minute_Start + 1 minute, e.g., '2026-04-25 14:31:00'). (Tier 2 — SP_IntraHourIndexReport) |
| 4 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. Filtered to three index instruments: 27 (S&P 500), 28 (DJ30), 32 (GER30). (Tier 1 — Trade.PositionTbl) |
| 5 | VolumeBuy | bigint | YES | Aggregated USD buy volume for the minute. Combines new long opens (SUM of Volume where IsBuy=1) and short closes (SUM of VolumeOnClose where IsBuy=0). ISNULL defaults to 0. (Tier 2 — Dim_Position) |
| 6 | VolumeSell | bigint | YES | Aggregated USD sell volume for the minute. Combines new short opens (SUM of Volume where IsBuy=0) and long closes (SUM of VolumeOnClose where IsBuy=1). ISNULL defaults to 0. (Tier 2 — Dim_Position) |
| 7 | OP_Buy_Units | float | YES | Total units (AmountInUnitsDecimal) of all open buy positions at start of this minute. SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal). (Tier 2 — Dim_Position) |
| 8 | OP_Buy | float | YES | USD-equivalent value of all open buy positions at start of this minute. SUM(AmountInUnitsDecimal × Bid × USDConversionRate). (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 9 | OP_Sell_Units | float | YES | Total units of all open sell positions at start of this minute. SUM(CASE WHEN IsBuy=0 THEN AmountInUnitsDecimal). (Tier 2 — Dim_Position) |
| 10 | OP_Sell | float | YES | USD-equivalent value of all open sell positions at start of this minute. SUM(AmountInUnitsDecimal × Ask × USDConversionRate). (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 11 | UnrealizedStart | float | YES | Aggregate unrealized P&L for all open client positions at start of this minute. SUM(AmountInUnitsDecimal × ConversionRate × (price − InitForexRate) + FullCommissionByUnits), direction-adjusted. Excludes positions opened in the same minute. (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 12 | UnrealizedEnd | float | YES | Aggregate unrealized P&L at end of this minute. Equals UnrealizedStart of the next minute (self-join on toMinute=fromMinute). NULL for the last minute of the day. (Tier 2 — Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice) |
| 13 | Realized | float | YES | Total realized P&L from positions closing in this minute. SUM(NetProfit + FullCommissionOnClose). ISNULL defaults to 0 when no positions close. (Tier 2 — Dim_Position) |
| 14 | Bid | float | YES | Instrument bid price at start of this minute. LAG of last bid from PriceLog_History_CurrencyPrice, with NULL gap-filling via forward-fill. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| 15 | Ask | float | YES | Instrument ask price at start of this minute. LAG of last ask from PriceLog_History_CurrencyPrice, with NULL gap-filling via forward-fill. (Tier 2 — CopyFromLake.PriceLog_History_CurrencyPrice) |
| 16 | UpdateDate | datetime | YES | ETL execution timestamp. Set to GETDATE() at SP_IntraHourIndexReport run time. (Tier 2 — SP_IntraHourIndexReport) |
| 17 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows. (Tier 1 — Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | (generated) | — | CONVERT(DATE, minute bucket) |
| Minute_Start | (generated) | — | Minute grid start |
| Minute_End | (generated) | — | Minute grid end |
| InstrumentID | Trade.PositionTbl | InstrumentID | Passthrough (via Dim_Position) |
| VolumeBuy | Dim_Position | Volume, VolumeOnClose | SUM by direction, combining opens and closes |
| VolumeSell | Dim_Position | Volume, VolumeOnClose | SUM by direction, combining opens and closes |
| OP_Buy_Units | Dim_Position | AmountInUnitsDecimal | SUM for IsBuy=1 open positions |
| OP_Buy | Dim_Position + PriceLog | AmountInUnitsDecimal, Bid, ConversionRate | SUM(units × bid × conversion) |
| OP_Sell_Units | Dim_Position | AmountInUnitsDecimal | SUM for IsBuy=0 open positions |
| OP_Sell | Dim_Position + PriceLog | AmountInUnitsDecimal, Ask, ConversionRate | SUM(units × ask × conversion) |
| UnrealizedStart | Dim_Position + PriceLog | Multiple | Unrealized P&L formula (see Section 2.3) |
| UnrealizedEnd | Dim_Position + PriceLog | Multiple | Self-join to next minute's UnrealizedStart |
| Realized | Dim_Position | NetProfit, FullCommissionOnClose | SUM for closing positions |
| Bid | PriceLog_History_CurrencyPrice | Bid | LAG(LastBid, 1) with gap-fill |
| Ask | PriceLog_History_CurrencyPrice | Ask | LAG(LastAsk, 1) with gap-fill |
| UpdateDate | (generated) | — | GETDATE() |
| HedgeServerID | Trade.PositionTbl | HedgeServerID | Passthrough (via Dim_Position) |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl (open positions)
etoro.History.ClosePosition (closed positions)
  |-- Generic Pipeline (Bronze export) --|
  v
DWH_staging.etoro_Trade_OpenPositionEndOfDay
DWH_staging.etoro_History_ClosePositionEndOfDay
  |-- SP_Dim_Position_DL_To_Synapse @dt --|
  v
DWH_dbo.Dim_Position (~200M+ rows)     DWH_dbo.Dim_Customer
  |                                       |
  |-- JOIN ON CID=RealCID, IsValidCustomer=1 --|
  |
CopyFromLake.PriceLog_History_CurrencyPrice
  |-- SP_Copy_Temporary_Data (load 5 days of prices) --|
  |
Dealing_staging.etoro_History_PortfolioConversionConfigurations
Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations
  |-- Instrument-to-hedge mapping --|
  |
  |-- SP_IntraHourIndexReport @Date --|
  |   (DELETE+INSERT for @Date)
  v
Dealing_dbo.Dealing_IndiciesIntraHour_Clients (~13.3M rows)
  |-- Generic Pipeline (Append, delta, daily) --|
  v
general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolve instrument name, asset class (only IDs 27, 28, 32) |
| HedgeServerID | Trade.HedgeServer | Hedge server identifier |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|-------------------|-------------|-------------|
| Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | Companion table | eToro hedging side of the same intra-hour report; typically joined on Date, Minute_Start, InstrumentID, HedgeServerID |

---

## 7. Sample Queries

### 7.1 Intra-Day Volume Profile for an Instrument

```sql
SELECT Minute_Start,
       VolumeBuy,
       VolumeSell,
       VolumeBuy - VolumeSell AS NetVolume
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients
WHERE [Date] = '2026-04-25'
  AND InstrumentID = 27
ORDER BY Minute_Start;
```

### 7.2 Daily P&L Summary by Instrument

```sql
SELECT [Date],
       InstrumentID,
       SUM(Realized) AS TotalRealized,
       MAX(UnrealizedStart) AS PeakUnrealized
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients
WHERE [Date] >= '2026-04-01'
GROUP BY [Date], InstrumentID
ORDER BY [Date], InstrumentID;
```

### 7.3 Client vs eToro Comparison

```sql
SELECT c.[Date],
       c.Minute_Start,
       c.InstrumentID,
       c.VolumeBuy AS ClientVolumeBuy,
       c.VolumeSell AS ClientVolumeSell,
       e.VolumeBuy AS EtoroVolumeBuy,
       e.VolumeSell AS EtoroVolumeSell
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients c
JOIN Dealing_dbo.Dealing_IndiciesIntraHour_Etoro e
  ON c.[Date] = e.[Date]
  AND c.Minute_Start = e.Minute_Start
  AND c.InstrumentID = e.InstrumentID
  AND c.HedgeServerID = e.HedgeServerID
WHERE c.[Date] = '2026-04-25'
  AND c.InstrumentID = 28
ORDER BY c.Minute_Start;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources were searched in this regen run (Phase 10 skipped in harness mode). SP change history references SR-249626 (HedgeServerID addition) and SR-257613 (CopyFromLake migration).

---

*Generated: 2026-04-30 | Phases: 11/14*
*Tiers: 2 T1, 15 T2, 0 T3, 0 T4, 0 T5 | Elements: 17/17, Logic: 5 subsections*
*Object: Dealing_dbo.Dealing_IndiciesIntraHour_Clients | Type: Table | Production Source: Dim_Position + PriceLog via SP_IntraHourIndexReport*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_IntraHourIndexReport`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_IntraHourIndexReport.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_IntraHourIndexReport] @Date [DATE] AS 
BEGIN



/******************************************************************************************************************************  
Author: Graham Ellinson  
Date: 29.05.22
Description: Caputre the Intra Hour Hedging Activity Client vs Etoro.
   
**************************  
** Change History  
**************************  
Date                Author				SR				Description   
----                ----------			-----------		-----------------------------------  

28.06.2022			Graham Ellinson					     Change Nettings Tables to Synpase Tables.
04.07.2022			Graham Ellinson					     Change Nettings Tables to Prod.
31.08.2022			Nixar							     Extend recursion to 5 days before date in order to smear weekends. 
05.12.2022			Nixar							     Remove HS 127
08.02.2023			Nixar							     Remove HS 25
14.06.2023			Sarah							     Remove HS 24
03.08.2023			Adar							     Mapping- Only HS 21
04.10.2023			Gal								     Migration
30.04.2024          Gal                 #SR-249626       Addind HedgeServerID Column and remove HedgeServer filters
18.06.2024          Adar                #SR-257613       Change the price tables to CopyFromLake

*******************************************************************************************************************************/  

/**************************************************************************************************************************/
--EXEC [Dealing_dbo].[SP_IntraHourIndexReport] '20240410'


---------------------------------------------------------------------------VARS DECLORATIONS--------------------
--Declare @Date Date= '20240429'  
DECLARE @DateInt INT=CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)  
DECLARE @Start DATETIME = @Date 
DECLARE @NextDate DATE=DATEADD(DAY,1,@Date)  
Declare @NextDateInt INT=CAST(CONVERT(VARCHAR(8), @NextDate, 112) AS INT)  
DECLARE @End DATETIME= DATEADD(DAY,1,@Start) 
DECLARE @DateMinusOne DATE = DATEADD(DAY, -1, @Date)  
DECLARE @5DaysBeforeStart DATETIME=DATEADD(DAY,-5,@Start)
--DECLARE @5DaysBeforeStartINT INT = DWH_dbo.DateToDateID(@5DaysBeforeStart)
DECLARE @DAYSback INT = 5


BEGIN
    DECLARE @table2 VARCHAR(500) = 'CopyFromLake.PriceLog_History_CurrencyPrice'
    EXEC [CopyFromLake].[SP_Copy_Temporary_Data] @dest_table = @table2, @fromdate = @5DaysBeforeStart, @todate = @Date
END

---------------------------------------------------------------------------------------defining initial instruments 
IF OBJECT_ID('tempdb..#IniIns') IS NOT NULL 
DROP TABLE #IniIns 
CREATE TABLE #IniIns   
   WITH (HEAP,DISTRIBUTION=ROUND_ROBIN) 
AS 
SELECT 27 InstumerntID
UNION 
SELECT 28 InstumerntID
UNION 
SELECT 32 InstumerntID

----------------------------------------------------------------------------------- Instrumnets&Instruments To Hedge-------------- 
	IF OBJECT_ID('tempdb..#HedgeID') IS NOT NULL 
	DROP TABLE #HedgeID 
CREATE TABLE #HedgeID   
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 
			/*** EXPLANATION:first part of union is historical one and second one is current, for each instrument a row is exsiting in only one of them 
				because if its is no longer relevant it moves automatically to history**/


	AS
	SELECT 
	pcc.InstrumentID
   ,pcc.InstrumentIDToHedge
	FROM [Dealing_staging].[etoro_History_PortfolioConversionConfigurations] pcc 
	WHERE 1=1
	and pcc.SysStartTime<@NextDate 
	AND pcc.SysEndTime>@DateMinusOne
	AND pcc.InstrumentID<>pcc.InstrumentIDToHedge
	AND pcc.InstrumentID IN  (SELECT * FROM #IniIns ii)  
UNION 
	SELECT 
	pcc.InstrumentID
	,pcc.InstrumentIDToHedge
	FROM [Dealing_staging].[etoro_Hedge_PortfolioConversionConfigurations] pcc
	WHERE pcc.SysStartTime< @NextDate 
	AND pcc.InstrumentID <> pcc.InstrumentIDToHedge
	AND pcc.InstrumentID IN  (SELECT * FROM #IniIns ii)  

-----------------------------------------------------------------------------------CREATE INSTRUMENTS ID (INCLUDING HEDGE INSTRUMENTS) 
	IF OBJECT_ID('tempdb..#Ins') IS NOT NULL 
	DROP TABLE #Ins 
	CREATE TABLE #Ins  
	WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

	AS 
SELECT 
	InstrumentID 	
	FROM #HedgeID hi
UNION
	SELECT 
	InstrumentIDToHedge 
	FROM #HedgeID hi

	-----------------------------------------------------------------------------------MINUTES GENERATING - ALL MINUTES OF THE DAY 

IF OBJECT_ID('tempdb..#Minutes') IS NOT NULL
DROP TABLE #Minutes  
CREATE TABLE #Minutes  
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

AS   
  SELECT fromMinute
,
toMinute,
CAST(CONVERT(VARCHAR(8), fromMinute, 112) AS INT) as day
FROM( 

SELECT TOP (24*60*(@DAYSback+1)) 
        DATEADD(minute, ROW_NUMBER() OVER (ORDER BY a.object_id)-1, @5DaysBeforeStart) AS fromMinute,
		DATEADD(minute, ROW_NUMBER() OVER (ORDER BY a.object_id), @5DaysBeforeStart) AS toMinute,
		ROW_NUMBER() OVER (ORDER BY a.object_id) AS r 
  FROM sys.all_objects AS a
		CROSS JOIN sys.all_objects AS b
		) a 
CREATE CLUSTERED INDEX #Minutes ON #Minutes (fromMinute)
--select * from #Minutes
-----------------------------------------------------------------------------------ALL MINUTES OF THE DAY FOR EVERY INS

IF OBJECT_ID('tempdb..#MinutesXins') IS NOT NULL 
DROP TABLE #MinutesXins
CREATE TABLE #MinutesXins  
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 
	AS 

	SELECT  i.*,
			m.*, 
			FORMAT(m.fromMinute, 'yyyyMMdd') date

FROM #Minutes m
CROSS JOIN #Ins i

-----------------------------------------------------------------------------------PULL PRICES FROM [PriceLog_History_CurrencyPrice]
IF OBJECT_ID('tempdb..#OrgPrices') IS NOT NULL
DROP TABLE #OrgPrices  
CREATE TABLE #OrgPrices 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS 

Select InstrumentID
	,Occurred
	,LastBid
	,LastAsk
	,Conversion
	,fromMinute
	,toMinute
  from (

  SELECT InstrumentID
				,Occurred
				,Bid LastBid
				,Ask LastAsk
				,USDConversionRate as Conversion
				,DATEADD(mi,DATEDIFF(mi,0,Occurred),0) fromMinute
				,DATEADD(MINUTE,1,DATEADD(mi,DATEDIFF(mi,0,Occurred),0)) toMinute
				,ROW_NUMBER() OVER (PARTITION BY DATEADD(mi,DATEDIFF(mi,0,Occurred),0), InstrumentID ORDER BY Occurred DESC) rn
		  FROM CopyFromLake.PriceLog_History_CurrencyPrice  

		WHERE InstrumentID in (SELECT InstrumentID FROM #Ins ) and  Occurred >=  Format(@5DaysBeforeStart,'yyyyMMdd') 
		AND Occurred <  Format(DATEADD(MI,-1,CAST(DATEADD(DAY,1,@NextDate) AS DATETIME))  ,'yyyyMMdd')

		) a
 where rn =1

 -------------------------------------------------------------------------------DESPITE HAVING PRICES FOR INS WE'RE HEDGING WITH - WE USE INS PRICES
IF OBJECT_ID('tempdb..#RawPrices') IS NOT NULL
DROP TABLE #RawPrices  
CREATE TABLE #RawPrices 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS 

 SELECT
	InstrumentIDToHedge AS InstrumentID
	,Occurred
	,LastBid
	,LastAsk
	,Conversion
	,fromMinute
	,toMinute
  FROM #HedgeID hi LEFT JOIN #OrgPrices rp  ON hi.InstrumentID = rp.InstrumentID  
UNION 
SELECT *
FROM #OrgPrices rp
WHERE InstrumentID  IN (SELECT InstrumentID FROM #HedgeID hi )
-------------------------------------------------------------------------------RAW PRICES AND LATEST MINUTES
IF OBJECT_ID('tempdb..#Prices_All') IS NOT NULL
DROP TABLE  #Prices_All 
CREATE TABLE  #Prices_All 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS 
SELECT mx.day
	  ,mx.InstrumentID
	  ,mx.fromMinute
	  ,mx.toMinute
	  ,rp.LastBid
	  ,rp.LastAsk
	  ,rp.Conversion
FROM #MinutesXins mx
LEFT JOIN #RawPrices rp
	ON mx.fromMinute=rp.fromMinute AND rp.InstrumentID=mx.InstrumentID 

CREATE CLUSTERED INDEX cid ON  #Prices_All  (InstrumentID, fromMinute)
--------------------------------------------------------------------------DRAGING PRICES FROM THE LAST NON-NULL VALUE FOR SMOOTHNESS
IF OBJECT_ID('tempdb..#Prices_FIX') IS NOT NULL
DROP TABLE  #Prices_FIX  
CREATE TABLE  #Prices_FIX 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS 
SELECT * FROM ( 
SELECT *
,LAG(LastBid,1)  OVER (PARTITION BY InstrumentID ORDER BY fromMinute) FirstBid
,LAG(LastAsk,1)  OVER (PARTITION BY InstrumentID ORDER BY fromMinute) FirstAsk
,LAG(Conversion,1)  OVER (PARTITION BY InstrumentID ORDER BY fromMinute) ConversionFirst 
FROM ( 
SELECT 
t1.InstrumentID,
t1.fromMinute,
t1.toMinute,
COALESCE(t1.LastBid, t2.LastBid) AS LastBid, 
COALESCE(t1.LastAsk, t2.LastAsk) AS LastAsk,
COALESCE(t1.Conversion, t2.Conversion) AS Conversion
FROM #Prices_All t1
OUTER APPLY (
  SELECT TOP 1 *
  FROM #Prices_All t2
  WHERE t2.InstrumentID = t1.InstrumentID
    AND t2.fromMinute <= t1.fromMinute
    AND t2.LastBid IS NOT NULL
	AND t2.LastAsk IS NOT NULL
	AND t2.Conversion IS NOT NULL

ORDER BY t2.fromMinute DESC

) t2
) A
) final 

WHERE fromMinute BETWEEN @Date AND @NextDate
-------------------------------------------------------------------------------------------- ALL POSITIONS

IF OBJECT_ID('tempdb..#Positions') IS NOT NULL 
DROP TABLE #Positions
CREATE TABLE #Positions 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS 
SELECT   dp.InstrumentID
,dp.HedgeServerID
		,dp.IsBuy
		,dp.Volume
		,dp.OpenOccurred
		,DATEADD(MINUTE,DATEDIFF(MINUTE, 0,dp.OpenOccurred), 0) fromMinute
		,dp.OpenDateID
		,dp.CloseOccurred
		,dp.CloseDateID
		,dp.VolumeOnClose  
		,dp.PositionID
		,dp.AmountInUnitsDecimal
		,dp.InitForexRate
		,dp.FullCommissionByUnits
		,dp.FullCommissionOnClose
		,dp.CommissionByUnits
		,dp.CommissionOnClose
		,dp.NetProfit
		,dp.Amount  

 FROM  DWH_dbo.Dim_Position dp WITH (NOLOCK) 

JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)  
ON dp.CID=dc.RealCID  
WHERE 
dp.OpenDateID<=@DateInt ---date+1  
AND  (dp.CloseDateID=0 OR dp.CloseDateID>=@DateInt)  
AND  dp.InstrumentID IN (SELECT InstrumentID FROM #Ins i1)
AND   dc.IsValidCustomer=1 

CREATE CLUSTERED COLUMNSTORE INDEX #Positions ON  #Positions



-------------------------------------------------------------------------------VOLUMES
IF OBJECT_ID('tempdb..#Volume') IS NOT NULL 
DROP TABLE #Volume
CREATE TABLE #Volume 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS    
SELECT  Date day 
	   ,MINUTE fromMinute
	   ,DATEADD(MINUTE, 1, MINUTE) toMinute
	   ,InstrumentID
	   ,HedgeServerID
	   ,SUM(VolumeBuy) VolumeBuy
	   ,SUM(VolumeSell) VolumeSell  
FROM  
(  
	SELECT @Date Date
		  ,DATEADD(MINUTE,DATEDIFF(MINUTE, 0,OpenOccurred), 0) MINUTE
		  ,InstrumentID
		 , HedgeServerID
		  ,SUM(CASE WHEN p.IsBuy=1 THEN p.Volume ELSE 0 END) VolumeBuy
		  ,SUM(CASE WHEN p.IsBuy=0 THEN p.Volume ELSE 0 END ) VolumeSell  
	FROM #Positions p  
	WHERE p.OpenDateID=@DateInt  
	GROUP BY DATEADD(MINUTE,DATEDIFF(MINUTE, 0,OpenOccurred), 0),p.InstrumentID  ,p.HedgeServerID
UNION   
	SELECT @Date Date
		  ,DATEADD(MINUTE,DATEDIFF(MINUTE, 0,CloseOccurred), 0) MINUTE
		  ,p.InstrumentID
		  ,p.HedgeServerID
		  ,SUM(CASE WHEN p.IsBuy=0 THEN p.VolumeOnClose ELSE 0 END) VolumeBuy
		  ,SUM(CASE WHEN p.IsBuy=1THEN p.VolumeOnClose ELSE 0 END ) VolumeSell  
	FROM #Positions p  
	WHERE p.CloseDateID=@DateInt  
	GROUP BY DATEADD(MINUTE,DATEDIFF(MINUTE, 0,CloseOccurred), 0),p.InstrumentID ,p.HedgeServerID 
) a  
GROUP BY a.Date
		,a.MINUTE
		,a.InstrumentID  
		,a.HedgeServerID

CREATE CLUSTERED INDEX #Volume ON  #Volume  (fromMinute,InstrumentID) 
-------------------------------------------------------------------------------AGG OPEN POSITIONS BY MINUTES OF THE DAY


IF OBJECT_ID('tempdb..#OP_complete') IS NOT NULL 
DROP TABLE #OP_complete
CREATE TABLE #OP_complete 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS 
SELECT 
	  pf.fromMinute
	  ,pf.toMinute
	  ,pf.InstrumentID
	  ,p.HedgeServerID
	  ,SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal ELSE 0 END) OP_Buy_Units

	  ,SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal*FirstBid*ConversionFirst ELSE 0 END) OP_Buy

	  ,SUM(CASE WHEN IsBuy=1 THEN (AmountInUnitsDecimal * (FirstBid - InitForexRate) *ConversionFirst + Amount) ELSE 0 END) CurrentMarginBuy

	  ,SUM(CASE WHEN IsBuy=0 THEN AmountInUnitsDecimal ELSE 0 END) OP_Sell_Units

	 ,SUM(CASE WHEN IsBuy=0 THEN AmountInUnitsDecimal*FirstAsk*ConversionFirst ELSE 0 END) OP_Sell

	 ,SUM(CASE WHEN IsBuy=0 THEN (-AmountInUnitsDecimal * (FirstAsk - InitForexRate) * ConversionFirst + Amount) ELSE 0 END) CurrentMarginSell

	 ,SUM(AmountInUnitsDecimal * ((CASE WHEN IsBuy = 1 THEN FirstBid ELSE FirstAsk END) - InitForexRate) * ConversionFirst * (CASE WHEN IsBuy = 1 THEN 1 else -1 END) 
	  + Amount) CurrentMargin

	 ,SUM(CASE WHEN DATEADD(MINUTE,DATEDIFF(MINUTE, 0,OpenOccurred), 0) = pf.fromMinute THEN 0   
                ELSE (AmountInUnitsDecimal * ConversionFirst *(CASE WHEN IsBuy=1 THEN FirstBid -InitForexRate ELSE InitForexRate-FirstAsk END)
				+ FullCommissionByUnits) END) UnrealizedStart  

FROM #Prices_FIX pf 
LEFT JOIN #Positions p
ON p.fromMinute<=pf.fromMinute
AND (p.CloseOccurred>pf.fromMinute  OR p.CloseDateID=0)
AND pf.InstrumentID =p.InstrumentID
GROUP BY
		pf.fromMinute
		,pf.toMinute
		,pf.InstrumentID  
		,p.HedgeServerID


CREATE CLUSTERED INDEX #OP_complete ON  #OP_complete (fromMinute, InstrumentID) 
----------------------------------------------------------------------------------------Realized BY MINUTE 

IF OBJECT_ID('tempdb..#Realized') IS NOT NULL 
DROP TABLE #Realized
CREATE TABLE #Realized 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

AS   

SELECT  DATEADD(MINUTE,DATEDIFF(MINUTE, 0,CloseOccurred), 0) fromMinute
	   ,DATEADD(MINUTE,1 ,DATEADD(MINUTE,DATEDIFF(MINUTE, 0, CloseOccurred), 0)) toMinute
	   ,p.InstrumentID
	   ,p.HedgeServerID
	   ,SUM(NetProfit + p.FullCommissionOnClose) Realized                      
FROM #Positions p  
WHERE p.CloseDateID=@DateInt   
GROUP BY DATEADD(MINUTE,DATEDIFF(MINUTE, 0,CloseOccurred), 0), p.InstrumentID  ,p.HedgeServerID

CREATE CLUSTERED INDEX #Realized ON  #Realized  (fromMinute, InstrumentID)

----------------------------------------------------------------------------------------------------------------------------------------------------------

--#########################################################################################################################################################
-------------------------------------------------------------------------------ETORO SIDE--------------------------------------------------------------------------------
--#########################################################################################################################################################
--#########################################################################################################################################################
--#########################################################################################################################################################
--#########################################################################################################################################################

----------------------------------------------------------------------------------------LOADING RELEVANT DATA TO EXCE-LOG

DECLARE @ExecutionDateFrom DATE=@Date 
DECLARE @ExecutionDateTo DATE=@Date


--IF NOT EXISTS (SELECT TOP 1 * FROM Dealing_staging.Etoro_Hedge_ExecutionLog WHERE etr_ymd = @ExecutionDateFrom )  
--    BEGIN
--        DECLARE @table VARCHAR(500) = 'Dealing_staging.Etoro_Hedge_ExecutionLog'
--        EXEC [Dealing_staging].[SP_Copy_Temporary_Data] @dest_table = @table, @fromdate = @ExecutionDateFrom, @todate = @ExecutionDateTo
--    END

-------------------------------------------------------------------------LiquidityAccounts&minutes&ins
--first step only LiquidityAccountID and InstrumentID exists combinations


DECLARE @StartDate DATE = @Date    
DECLARE @EndDate DATE = DATEADD(DAY, 1, @StartDate)


BEGIN
    DECLARE @table VARCHAR(500) = 'CopyFromLake.etoro_Hedge_ExecutionLog'
    EXEC [CopyFromLake].[SP_Copy_Temporary_Data] @dest_table = @table, @fromdate = @StartDate, @todate = @StartDate
END



	IF OBJECT_ID ('tempdb..#Dim_LiquidityAccounts') IS NOT NULL
	DROP TABLE #Dim_LiquidityAccounts
CREATE TABLE #Dim_LiquidityAccounts 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

		AS   

		SELECT  
		DISTINCT 
		el.LiquidityAccountID
		,el.InstrumentID
		, el.HedgeServerID
		,la.LiquidityAccountName
		FROM CopyFromLake.etoro_Hedge_ExecutionLog el with (NOLOCK)
		LEFT JOIN [Dealing_staging].[etoro_Trade_LiquidityAccounts] la
		ON la.LiquidityAccountID = el.LiquidityAccountID 
		WHERE 1=1 --el.HedgeServerID = 21
		AND el.InstrumentID IN (SELECT * FROM #Ins) 
		--SELECT * FROM #Dim_LiquidityAccounts dla

----second step minutes-------------------------------------------------------------------------


	IF OBJECT_ID ('tempdb..#Minute_LP ') IS NOT NULL
	DROP TABLE #Minute_LP 
CREATE TABLE #Minute_LP  
WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

		AS   
		SELECT 
			day,
			LP.LiquidityAccountID 
			,LP.LiquidityAccountName
			,LP.HedgeServerID
			,minxins.InstrumentID
			,minxins.fromMinute
			,minxins.toMinute

		FROM (
				SELECT * FROM #MinutesXins
				WHERE day = @DateInt
				AND InstrumentID IN (SELECT InstrumentIDToHedge FROM #HedgeID)
			) minxins 
			LEFT JOIN 
		 #Dim_LiquidityAccounts LP ON minxins.InstrumentID=LP.InstrumentID

		 CREATE CLUSTERED INDEX #Minute_LP ON  #Minute_LP  (fromMinute, InstrumentID)
---------------------------------------------------------------------------------------------------VOLUME ETORO

IF OBJECT_ID ('tempdb..#Volume_E') IS NOT NULL
	DROP TABLE #Volume_E
CREATE TABLE #Volume_E 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

		AS   
		SELECT @Date Date
			,DATEADD(MINUTE,DATEDIFF(MINUTE, 0,CAST(ExecutionTime AS DATETIME2)), 0) fromMinute
			,dla.LiquidityAccountName
			,dla.LiquidityAccountID
			,el.HedgeServerID
			,el.InstrumentID
			,SUM(CASE WHEN IsBuy=1 THEN Units*el.ExecutionRate ELSE 0 END) VolumeBuy
			,SUM(CASE WHEN IsBuy=0 THEN Units*el.ExecutionRate ELSE 0 END ) VolumeSell
			,SUM(CASE WHEN IsBuy=1 THEN Units ELSE 0 END) UnitsBuy
			,SUM(CASE WHEN IsBuy=0 THEN Units ELSE 0 END ) UnitsSell  
 FROM CopyFromLake.etoro_Hedge_ExecutionLog el with (NOLOCK)
JOIN #Dim_LiquidityAccounts dla  
	ON el.LiquidityAccountID=dla.LiquidityAccountID  
	AND el.InstrumentID = dla.InstrumentID
		WHERE ExecutionTime  BETWEEN @Date AND @End --and el.HedgeServerID = 21
		GROUP BY DATEADD(MINUTE,DATEDIFF(MINUTE, 0,CAST(ExecutionTime AS DATETIME2) ) , 0)
		--,el.HedgeServerID
		,dla.LiquidityAccountID
		,dla.LiquidityAccountName
		,el.HedgeServerID
		,el.InstrumentID  

-----------------------------------------------------------------------------------------------Calculate NOP 
IF OBJECT_ID ('tempdb..#NOP_E') IS NOT NULL
	DROP TABLE #NOP_E
CREATE TABLE #NOP_E 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

		AS 
SELECT * FROM ( 
SELECT *,
ROW_NUMBER() OVER (PARTITION BY InstrumentID,fromMinute ORDER BY SysEndTime DESC) rn
FROM ( 
		SELECT LiquidityAccountID
			,bdn.HedgeServerID
			,bdn.InstrumentID
			,IsBuy
			,Units
			,bdn.SysStartTime
			,DATEADD(MINUTE,DATEDIFF(MINUTE, 0,bdn.SysStartTime), 0) fromMinute
			,bdn.SysEndTime 
			 FROM [Dealing_staging].[etoro_Hedge_Netting] bdn WITH (NOLOCK) 

		JOIN #Ins i
			ON bdn.InstrumentID = i.InstrumentID
			WHERE 1=1 
			AND  bdn.SysStartTime<=@Date--(DAY,1,@Date) 
			--and  bdn.HedgeServerID = 21  

	UNION  
		SELECT LiquidityAccountID
			,bdnh.HedgeServerID
			,bdnh.InstrumentID
			,IsBuy
			,Units
			,SysStartTime
			,DATEADD(MINUTE,DATEDIFF(MINUTE, 0,SysStartTime), 0) fromMinute
			,SysEndTime

		FROM [Dealing_staging].[etoro_History_Netting_History] bdnh WITH (NOLOCK)
	JOIN #Ins i
		ON bdnh.InstrumentID = i.InstrumentID 
		WHERE 1=1 and bdnh.SysEndTime>= @Date
		AND SysStartTime <=@NextDate --fixing 
	--	and  bdnh.HedgeServerID = 21


  ) a 
  ) b 
  WHERE rn=1 
CREATE CLUSTERED COLUMNSTORE INDEX #NOP_E on #NOP_E 
--------------------------------------------------------------------------------NOP BY MINUTE 	
	IF OBJECT_ID ('tempdb..#NOP_by_minute') IS NOT NULL
	DROP TABLE #NOP_by_minute
CREATE TABLE #NOP_by_minute 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

		AS   

		SELECT   day
			  ,m.fromMinute
			  ,m.toMinute
			  ,m.LiquidityAccountID
			  ,LiquidityAccountName
			  ,ne.HedgeServerID
			  ,m.InstrumentID
			  ,IsBuy
			  ,SysStartTime
			  ,SysEndTime
				 ,Units  

			FROM (SELECT * FROM #Minute_LP MLP WHERE day=@DateInt) m 
		LEFT JOIN  #NOP_E ne
		ON 
		ne.LiquidityAccountID=m.LiquidityAccountID  
		AND   m.fromMinute BETWEEN ne.SysStartTime AND ne.SysEndTime 
		AND ne.InstrumentID=m.InstrumentID
		AND m.HedgeServerID = ne.HedgeServerID

		CREATE CLUSTERED INDEX #NOP_by_minute ON  #NOP_by_minute  (fromMinute, InstrumentID)
------------------------------------------------------------------------------------------ALL MEASURES COMBO
IF OBJECT_ID ('tempdb..#TOTS') IS NOT NULL
	DROP TABLE #TOTS
CREATE TABLE #TOTS 
WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) 

		AS   
SELECT nbm.day
	  ,nbm.fromMinute
	  ,nbm.toMinute
	  ,nbm.LiquidityAccountName
	  ,nbm.LiquidityAccountID
	  ,nbm.InstrumentID
	  ,nbm.HedgeServerID
	  ,SUM(ISNULL(v.VolumeBuy*pf.ConversionFirst,0)) VolumeBuy
	  ,SUM(ISNULL(v.VolumeSell*pf.ConversionFirst,0)) VolumeSell
	  ,SUM(Units * (2*IsBuy-1)) Units_NOP
	  ,SUM(Units * pf.ConversionFirst *(2*IsBuy-1)*CASE WHEN nbm.IsBuy=1 THEN pf.FirstBid ELSE pf.FirstAsk END) NOP
	  ,SUM(Units * pf.ConversionFirst * (2*IsBuy-1)*CASE WHEN nbm.IsBuy=1 THEN pf.FirstBid ELSE pf.FirstAsk END) ValueStart
	  ,SUM(ISNULL(v.VolumeSell*pf.ConversionFirst,0)-ISNULL(v.VolumeBuy*pf.ConversionFirst,0)) ValueRealized  

FROM #NOP_by_minute nbm  

LEFT JOIN #Volume_E v  
	ON nbm.fromMinute=v.fromMinute AND nbm.LiquidityAccountID = v.LiquidityAccountID AND v.InstrumentID=nbm.InstrumentID  AND nbm.HedgeServerID = v.HedgeServerID

LEFT JOIN #Prices_FIX pf  
	ON nbm.fromMinute=pf.fromMinute AND nbm.InstrumentID=pf.InstrumentID 

GROUP BY nbm.day
		,nbm.fromMinute
		,nbm.toMinute
		,nbm.LiquidityAccountName
		,nbm.LiquidityAccountID
		,nbm.InstrumentID   
		,nbm.HedgeServerID



--------------------------------------------------------------------------------------FINAL TABLES: -----------------------------------------------------
/*####################################################################################CLIENTS########################################################### 
*/


DELETE FROM [Dealing_dbo].[Dealing_IndiciesIntraHour_Clients]
WHERE Date=@Date  

INSERT INTO [Dealing_dbo].[Dealing_IndiciesIntraHour_Clients]
(Date
,Minute_Start
,Minute_End
,InstrumentID
,HedgeServerID
,VolumeBuy
,VolumeSell
,OP_Buy_Units
,OP_Buy
,OP_Sell_Units
,OP_Sell
,UnrealizedStart
,UnrealizedEnd
,Realized
,Bid
,Ask
,UpdateDate)

SELECT CONVERT (DATE, o.fromMinute) Date
	  ,o.fromMinute Minute_Start
	  ,o.toMinute Minute_End
	  ,o.InstrumentID
	  ,o.HedgeServerID
	  ,ISNULL(v.VolumeBuy,0) VolumeBuy
	  ,ISNULL(v.VolumeSell,0) VolumeSell
	  ,o.OP_Buy_Units
	  ,o.OP_Buy
	  ,o.OP_Sell_Units
	  ,o.OP_Sell
	  ,o.UnrealizedStart
	  ,o2.UnrealizedStart AS UnrealizedEnd
	  ,ISNULL(r.Realized,0) Realized
	 ,pf.FirstBid Bid
	 ,pf.FirstAsk Ask 
	 ,GETDATE() AS UpdateDate
 FROM #OP_complete o 
LEFT JOIN #OP_complete o2  
ON o.toMinute=o2.fromMinute AND o.InstrumentID=o2.InstrumentID  
LEFT JOIN #Volume v  
ON o.fromMinute=v.fromMinute AND o.InstrumentID=v.InstrumentID  
LEFT JOIN #Realized r  
ON o.fromMinute=r.fromMinute  AND o.InstrumentID=r.InstrumentID  
LEFT JOIN #Prices_FIX pf  
ON o.fromMinute=pf.fromMinute AND o.InstrumentID = pf.InstrumentID 

WHERE o.InstrumentID IN (SELECT * FROM #IniIns ii) 



/*####################################################################################ETORO####################################################### 
*/


DELETE FROM [Dealing_dbo].[Dealing_IndiciesIntraHour_Etoro]
WHERE Date=@Date  

INSERT INTO [Dealing_dbo].[Dealing_IndiciesIntraHour_Etoro] 
(
Date,  
InstrumentID,  
HedgeServerID,
Minute_Start,  
Minute_End,  
LiquidityAccountName,  
LiquidityAccountID,  
VolumeBuy,  
VolumeSell,  
Units_NOP,  
NOP,  
ValueStart,  
ValueEnd,  
ValueRealized,  
UpdateDate)  


SELECT (CONVERT (DATE, te.fromMinute) ) Date
	   ,te.InstrumentID
	   ,te.HedgeServerID
	   ,te.fromMinute Minute_Start
	   ,te.toMinute Minute_End
	   ,te.LiquidityAccountName
	   ,te.LiquidityAccountID
	   ,te.VolumeBuy
	   ,te.VolumeSell
	   ,ISNULL(te.Units_NOP,0) Units_NOP
	   ,ISNULL(te.NOP,0) NOP
	   ,ISNULL(te.ValueStart,0) ValueStart
	   ,ISNULL(te1.ValueStart,0) ValueEnd 
	   ,ISNULL(te.ValueRealized,0) ValueRealized
	   ,GETDATE() UpdateDate 
FROM #TOTS te  
LEFT JOIN #TOTS te1  
ON te.toMinute=te1.fromMinute AND te.LiquidityAccountID=te1.LiquidityAccountID AND te.InstrumentID = te1.InstrumentID  
WHERE (te.VolumeBuy<>0 OR te.VolumeSell<>0 OR te.NOP<>0 OR te.ValueStart<>0 OR te.ValueRealized<>0 OR te1.ValueStart<>0)  
AND te.day=@DateInt  


END;

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_dbo.SP_IntraHourIndexReport` | synapse_sp | Dealing_dbo | SP_IntraHourIndexReport | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_IntraHourIndexReport.sql` |
| `Dealing_staging.etoro_History_PortfolioConversionConfigurations` | unresolved | Dealing_staging | etoro_History_PortfolioConversionConfigurations | `—` |
| `Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations` | unresolved | Dealing_staging | etoro_Hedge_PortfolioConversionConfigurations | `—` |
| `sys.all_objects` | unresolved | sys | all_objects | `—` |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | unresolved | CopyFromLake | PriceLog_History_CurrencyPrice | `—` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `CopyFromLake.etoro_Hedge_ExecutionLog` | unresolved | CopyFromLake | etoro_Hedge_ExecutionLog | `—` |
| `Dealing_staging.etoro_Trade_LiquidityAccounts` | unresolved | Dealing_staging | etoro_Trade_LiquidityAccounts | `—` |
| `Dealing_staging.etoro_Hedge_Netting` | unresolved | Dealing_staging | etoro_Hedge_Netting | `—` |
| `Dealing_staging.etoro_History_Netting_History` | unresolved | Dealing_staging | etoro_History_Netting_History | `—` |
| `Dealing_dbo.Dealing_IndiciesIntraHour_Clients` | synapse | Dealing_dbo | Dealing_IndiciesIntraHour_Clients | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_IndiciesIntraHour_Clients.md` |

