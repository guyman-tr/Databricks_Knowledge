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
- **Object**: `Dealing_CME_Reporting`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_CME_Reporting/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_CME_Reporting\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_CME_Reporting\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_CME_Reporting.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_CME_Reporting`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_CME_Reporting.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_CME_Reporting]
(
	[Date] [date] NULL,
	[InstrumentDisplayName] [varchar](100) NULL,
	[CID_Count] [int] NULL,
	[Monthly_Volume] [bigint] NULL,
	[UpdateDate] [datetime] NULL
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

Found 2 upstream wiki(s). Read EACH one in full.


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

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_M_CME_Reporting`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_M_CME_Reporting.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_M_CME_Reporting] @Date [DATE] AS  
BEGIN

/******************************************************************************************************************************
Author: Sarah Benchitrit
Date: 2024-01-01
Description: CME Reporting obligation
SR-225467

**************************
** Change History
**************************
Date                   Author			SR			 Description 
----                   ----------		------		 -----------------------------------
2024-07-14			Sarah				SR-261943	Update Crude Oil instruments based on new name
2025-03-05			Sarah				SR-303463	Add 3 instruments
*******************************************************************************************************************************/

-- exec [Dealing_dbo].[SP_M_CME_Reporting] '2024-02-01'
--DECLARE @Date DATE = '2025-03-01'

declare @FirstOfMonth date = dateadd(day,1,@Date) -- @Date is yesterday (end of previous month).
DECLARE @DateID INT = CAST(CONVERT(VARCHAR(8), @FirstOfMonth, 112) AS INT)

DECLARE @StartOfMonth date = DATEADD(MONTH,datediff(month,0,@FirstOfMonth)-1,0)
declare @StartOfMonthID int = Dealing_dbo.DateToDateID(@StartOfMonth)

DECLARE @EndOfMonth date = DATEADD(MONTH,datediff(month,0,@FirstOfMonth),-1)
declare @EndOfMonthID int = Dealing_dbo.DateToDateID(@EndOfMonth)


-- List of relevant instruments

IF OBJECT_ID('tempdb..#Ins') IS NOT NULL
DROP TABLE #Ins
CREATE TABLE #Ins
WITH (DISTRIBUTION=HASH(InstrumentID),HEAP)
AS

SELECT di.InstrumentID
		,di.InstrumentType
		,di.InstrumentDisplayName
FROM DWH_dbo.Dim_Instrument di
WHERE di.InstrumentID IN (21,22,27,28,29,36,91,97,312,313,314,317,318,324,325,331,332,335,336,337,338,380,381,382) 
OR (lower(di.InstrumentDisplayName) LIKE '%crude oil%'	AND lower(di.InstrumentDisplayName) LIKE '%future%')

--select * from #Ins order by 3


-- Client count and volume

IF OBJECT_ID('tempdb..#Positions') IS NOT NULL
DROP TABLE #Positions
CREATE TABLE #Positions
WITH (DISTRIBUTION=HASH(CID),HEAP)
AS

SELECT cast(dp.OpenOccurred as date) Date
		,dp.CID
		,dp.InstrumentID
		,i.InstrumentDisplayName
		,dp.Volume
from DWH_dbo.Dim_Position dp
join #Ins i
on dp.InstrumentID = i.InstrumentID
left join DWH_dbo.Dim_Customer dc
on dc.RealCID = dp.CID
where dp.OpenDateID BETWEEN @StartOfMonthID and @EndOfMonthID
and dc.IsValidCustomer = 1

union all

SELECT cast(dp.CloseOccurred as date) Date
		,dp.CID
		,dp.InstrumentID
		,i.InstrumentDisplayName
		,dp.VolumeOnClose
from DWH_dbo.Dim_Position dp
join #Ins i
on dp.InstrumentID = i.InstrumentID
left join DWH_dbo.Dim_Customer dc
on dc.RealCID = dp.CID
where dp.CloseDateID BETWEEN @StartOfMonthID and @EndOfMonthID
and dc.IsValidCustomer = 1

--SELECT * from #Positions where InstrumentDisplayName like '%Crude%'

--SELECT * FROM DWH_dbo.Dim_Instrument di where InstrumentDisplayName like '%Crude%'

-- Fill tables

DELETE from Dealing_dbo.Dealing_CME_Reporting where Date = @EndOfMonth

INSERT INTO Dealing_dbo.Dealing_CME_Reporting
(Date
	,InstrumentDisplayName
	,CID_Count
	,Monthly_Volume
	,UpdateDate)

SELECT @EndOfMonth as Date
		,case when lower(p.InstrumentDisplayName) LIKE '%crude oil%' then 'Crude Oil Future'
				else p.InstrumentDisplayName end InstrumentDisplayName
		,count(DISTINCT p.CID) as CID_Count
		,sum(cast(p.Volume as bigint)) as Monthly_Volume
		,GETDATE() as UpdateDate
from #Positions p
group by case when lower(p.InstrumentDisplayName) LIKE '%crude oil%' then 'Crude Oil Future'
				else p.InstrumentDisplayName end




END


--SELECT * from Dealing_dbo.Dealing_CME_Reporting where Date >= '2025-02-01' and InstrumentDisplayName like '%Crude%' order by 1

--SELECT * FROM DWH_dbo.Dim_Instrument di WHERE InstrumentDisplayName like '%Crude%' AND di.InstrumentTypeID = 2 ORDER BY 1
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_dbo.SP_M_CME_Reporting` | synapse_sp | Dealing_dbo | SP_M_CME_Reporting | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_M_CME_Reporting.sql` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

