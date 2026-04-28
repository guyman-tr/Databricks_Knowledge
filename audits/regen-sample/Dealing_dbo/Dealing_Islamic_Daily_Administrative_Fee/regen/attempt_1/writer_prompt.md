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
- **Object**: `Dealing_Islamic_Daily_Administrative_Fee`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_Islamic_Daily_Administrative_Fee\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_Islamic_Daily_Administrative_Fee\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee]
(
	[Date] [date] NULL,
	[DateID] [int] NULL,
	[PositionID] [bigint] NULL,
	[RealCID] [int] NULL,
	[GCID] [int] NULL,
	[UserName] [varchar](20) NULL,
	[OpenDateID] [int] NULL,
	[CloseDateID] [int] NULL,
	[OpenOccurred] [datetime] NULL,
	[NewOpenOccurred] [datetime] NULL,
	[CloseOccurred] [datetime] NULL,
	[NewCloseOccurred] [datetime] NULL,
	[IsTheDayBefore] [int] NULL,
	[InstrumentTypeID] [int] NULL,
	[InstrumentType] [varchar](50) NULL,
	[InstrumentID] [int] NULL,
	[InstrumentName] [varchar](50) NULL,
	[InstrumentType_ID_InstrumentGroup] [int] NULL,
	[InstrumentName_InstrumentGroup] [varchar](50) NULL,
	[InstrumentGroup] [int] NULL,
	[Units_per_Contract] [int] NULL,
	[Exchange] [varchar](80) NULL,
	[ExchangeID] [int] NULL,
	[IsBuy] [int] NULL,
	[Leverage] [int] NULL,
	[IsSettled] [int] NULL,
	[ClosedOnWeekend] [int] NULL,
	[Bid] [numeric](36, 12) NULL,
	[Ask] [numeric](36, 12) NULL,
	[ConvertRateIsBuy_1] [numeric](18, 4) NULL,
	[ConvertRateIsBuy_0] [numeric](18, 4) NULL,
	[USD_Price] [money] NULL,
	[AmountInUnitsDecimal] [decimal](16, 6) NULL,
	[Admin_Fee_USD] [money] NULL,
	[Days_Open] [int] NULL,
	[GracePeriod] [int] NULL,
	[Days_Admin_Fee] [int] NULL,
	[Days_To_Charge] [int] NULL,
	[Final_Fee] [decimal](16, 2) NULL,
	[Fee_Type_ID] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[CountryID] [int] NULL
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

Found 6 upstream wiki(s). Read EACH one in full.


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


### Upstream `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Islamic_Admin_Fee_Per_Group.md`

# Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group

> Islamic account administrative fee schedule — USD fee rates per instrument group and asset class, with grace period configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual (12 rows, rarely changes) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on instrument_type_id |

---

## 1. Business Meaning

This is a reference table defining the administrative fee rates charged to Islamic (swap-free) accounts in lieu of overnight swap fees. Islamic accounts don't pay traditional rollover fees due to Sharia compliance; instead, they pay a flat administrative fee per instrument group after a grace period.

Contains 12 rows covering all asset classes (Currencies, Commodities, Indices, Stocks, ETF, Crypto), each subdivided into fee groups (1-4) with different USD rates. The grace period is uniformly 7 days — no fee is charged for the first 7 trading days a position is open.

Used by `SP_Islamic_Administrative_Fee` to calculate daily fees: `Admin_Fee_USD × Days_To_Charge × (units_formula_per_asset_class)`.

---

## 2. Business Logic

### 2.1 Fee Formula Per Asset Class

**Rules** (from SP_Islamic_Administrative_Fee):
- **Currencies (1)**: `(ABS(Units)/100000) × admin_fee_usd × Days_To_Charge`
- **Commodities (2)**: `(ABS(Units)/units_per_contract) × admin_fee_usd × Days_To_Charge`
- **Indices (4)**: `ABS(Units) × admin_fee_usd × Days_To_Charge`
- **Stocks/ETF (5,6)**: `((ABS(Units) × USD_Price)/10000) × admin_fee_usd × Days_To_Charge`
- **Crypto (10)**: `((ABS(Units) × USD_Price)/10000) × admin_fee_usd × Days_To_Charge`

### 2.2 Grace Period

All groups have `grace_period = 7`. Fee starts on day 8 of holding the position.

---

## 3. Query Advisory

### 3.1 Gotchas

- **Only 12 rows**: This is a small reference table. Full table scan is fine.
- **Joined via composite key**: `(instrument_group, instrument_type_id)` — both columns needed.
- **Rates are per unit formula, not per position**: The actual fee depends on position size and the asset class formula.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | instrument_group | int | YES | Fee tier group within an asset class. Groups 1-4 with different rates. Instruments are assigned to groups via `Dealing_Islamic_Instruments_Groups`. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 2 | admin_fee_usd | float | YES | Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4). (Tier 2 — SP_Islamic_Administrative_Fee) |
| 3 | grace_period | int | YES | Number of trading days before fee starts. Currently 7 for all groups. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 4 | currency | nvarchar(4000) | YES | Fee denomination currency. Always 'USD'. (Tier 3 — live data) |
| 5 | instrument_type_id | int | YES | Asset class identifier: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. (Tier 2 — SP_Islamic_Administrative_Fee) |

---

## 5. Relationships

### 5.1 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Administrative_Fee | Joins on `(instrument_group, instrument_type_id)` for fee lookup |
| Dealing_Islamic_Instruments_Groups | Provides instrument_group mapping for the join |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 4 T2, 1 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | Type: Table (reference)*


### Upstream `Dealing_dbo.Dealing_Islamic_Instruments_Groups` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Islamic_Instruments_Groups`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Islamic_Instruments_Groups.md`

# Dealing_dbo.Dealing_Islamic_Instruments_Groups

> Islamic fee instrument-to-group mapping — assigns each instrument to a fee tier group for administrative fee calculation.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual (updated when instruments are added/reclassified) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on instrument_id |

---

## 1. Business Meaning

This reference table maps individual instruments to fee tier groups for Islamic account administrative fee calculation. Each instrument is assigned to a `instrument_group` (1-4) within its `instrument_type_id` (asset class). The group determines the USD fee rate from `Dealing_Islamic_Admin_Fee_Per_Group`.

Only instruments in this table are subject to the group-based Islamic fee. Stock/ETF CFDs with Leverage>1 and Crypto CFDs are included via SP logic even without a mapping in this table.

---

## 2. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | instrument_id | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 3 — live data) |
| 2 | name | nvarchar(4000) | YES | Instrument name (e.g., "EUR/USD", "GBP/USD"). From manual configuration. (Tier 3 — live data) |
| 3 | instrument_group | int | YES | Fee tier group (1-4). Maps to `Dealing_Islamic_Admin_Fee_Per_Group.instrument_group` for fee rate lookup. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 4 | instrument_type_id | int | YES | Asset class: 1=Currencies, 2=Commodities, 4=Indices. (Tier 2 — SP_Islamic_Administrative_Fee) |

---

## 3. Relationships

### 3.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| instrument_id | DWH_dbo.Dim_Instrument | Instrument definition |
| (instrument_group, instrument_type_id) | Dealing_Islamic_Admin_Fee_Per_Group | Fee rate lookup |

### 3.2 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Administrative_Fee | LEFT JOIN on instrument_id for group assignment |

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Phases: 5/14*
*Tiers: 0 T1, 2 T2, 2 T3, 0 T4, 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10*
*Object: Dealing_dbo.Dealing_Islamic_Instruments_Groups | Type: Table (reference)*


### Upstream `Dealing_dbo.Dealing_Islamic_Units_Per_Contract` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Islamic_Units_Per_Contract`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Islamic_Units_Per_Contract.md`

# Dealing_dbo.Dealing_Islamic_Units_Per_Contract

> Commodity contract size reference — units per contract for Islamic administrative fee calculation on commodity instruments.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on instrument_id |

---

## 1. Business Meaning

This reference table defines the contract size (units per contract) for commodity instruments. Used exclusively by `SP_Islamic_Administrative_Fee` to calculate the Islamic fee for commodities: `(ABS(Units) / units_per_contract) × admin_fee_usd × Days_To_Charge`.

Contains ~5 commodity instruments (XTI/USD=1000, XAU/USD=100, XAG/USD=5000, XNG/USD=10000, XPT/USD=50).

---

## 2. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | instrument_id | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. E.g., 17=XTI/USD, 18=XAU/USD. (Tier 3 — live data) |
| 2 | name | nvarchar(4000) | YES | Instrument name. E.g., "XTI/USD" (Crude Oil), "XAU/USD" (Gold). (Tier 3 — live data) |
| 3 | units_per_contract | int | YES | Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 4 | instrument_type_id | int | YES | Asset class. Always 2 (Commodities) for this table. (Tier 3 — live data) |

---

## 3. Relationships

### 3.1 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Administrative_Fee | LEFT JOIN on instrument_id for contract size lookup |

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Phases: 5/14*
*Tiers: 0 T1, 1 T2, 3 T3, 0 T4, 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10*
*Object: Dealing_dbo.Dealing_Islamic_Units_Per_Contract | Type: Table (reference)*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_Islamic_Administrative_Fee`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Islamic_Administrative_Fee.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_Islamic_Administrative_Fee] @Date [DATE] AS  --Yesterday 
BEGIN


/******************************************************************************************************************************
Author: Gili Goldbaum
Date: 2024-02-21
Description: Daily Calculation of Islamic accounts Administrative Fee
   
**************************  
** Change History  
**************************  
Date           Author        SR             Description   
----------    ----------    -----------    ----------------------------------------------------------------------------------  
2024-02-22     Gili			 SR-234738		Creating SP
2024-02-29	   Gili			 SR-237430		Adding Update Date to the Fivetran tables, ranking it so it will take the last Update Date
2024-03-07	   Gili			 SR-240007		Fixed the ranking so it will take the last Update Date
2024-03-27     Gili			 SR-243980		Changed the SP so it will use 3 new tables instead of Fivetran Tables
2024-03-28     Gili			 SR-244452		Excluding Crypto long leverage 1 Positions of German Islamic Customers + CountryID Column
2024-04-04	   Gili			 SR-245865	    Changed the SP so it will run at Sundays and Suturdays
2024-06-26	   Gili			 SR-258928	    Removed a list of suspended instruments from #Final_Table
2025-11-17	   Gili			 SR-343388		Updated the Logic for InstrumentID = 62
*******************************************************************************************************************************/  
  
/************************************************Declare Parameters**********************************************************************/  
     
--exec  [Dealing_dbo].[SP_Islamic_Administrative_Fee] '20251114'  

--DECLARE @Date DATE='20251116'

DECLARE @ReportDateID INT=CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)  
DECLARE @DateMinusOne DATE = DATEADD(DAY,-1,@Date)
DECLARE @DateID INT=CAST(CONVERT(VARCHAR(8), @DateMinusOne, 112) AS INT)  

--Start of payments
DECLARE @StartTrade DATETIME, @time time
SET @StartTrade=@DateMinusOne
SET @time='22:00:00'
SET @StartTrade=@StartTrade+CAST(@time AS DATETIME)

DECLARE @CutoffTime TIME = '22:00:00.0000000'

--End of payments
DECLARE @DatePlusOne DATE = DATEADD(DAY, 1, @DateMinusOne)
DECLARE @EndTrade DATETIME
SET @EndTrade=@DatePlusOne
SET @EndTrade=@EndTrade+CAST(@time AS DATETIME)

--SELECT * FROM #Units_per_Contract
----------#####################################################################################
----------------------------------------------------------------------------
--Creating 4 different counting forms of days on which the Fee applies: --Manually
--Count_Wed - Wednesdays count as 3 days. Sundays and Saturdays don't count.
--Count_Fri - Fridays count as 3 days. Sundays and Saturdays don't count.
--Count_i - Sundays and Saturdays don't count.
--Count_All - Every day counts

IF OBJECT_ID('tempdb..#Dates') IS NOT NULL
DROP TABLE #Dates
CREATE TABLE #Dates   
   WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT 
FullDate,
DayNumberOfWeek_Sun_Start,
CASE WHEN DayNumberOfWeek_Sun_Start IN (1,7) THEN 0 WHEN DayNumberOfWeek_Sun_Start = 4 THEN 3 ELSE 1 END Count_Wed, --Manually
CASE WHEN DayNumberOfWeek_Sun_Start IN (1,7) THEN 0 WHEN DayNumberOfWeek_Sun_Start = 5 THEN 3 ELSE 1 END Count_Thu, --Manually
CASE WHEN DayNumberOfWeek_Sun_Start IN (1,7) THEN 0 WHEN DayNumberOfWeek_Sun_Start = 6 THEN 3 ELSE 1 END Count_Fri, --Manually
CASE WHEN DayNumberOfWeek_Sun_Start IN (1,7) THEN 0 ELSE 1 END Count_i,--Manually
1 AS Count_All
FROM [DWH_dbo].[Dim_Date]

--select * from #Dates order by FullDate

----------------------------------------------------------------------------
--All open positions at the EOD of report day(22GMT), Only Islamic accounts

IF OBJECT_ID('tempdb..#Positions') IS NOT NULL
DROP TABLE #Positions
CREATE TABLE #Positions
   WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT 
@Date AS [Date]
,@ReportDateID AS [DateID]
,dp.PositionID
,dp.OpenDateID
,dp.OpenOccurred
,CASE WHEN CONVERT(time, OpenOccurred) >= @CutoffTime THEN 1 ELSE 0 END IsTheDayBefore  -- Whether the position was opened after 22pm 
,CASE WHEN (CASE WHEN CONVERT(time, OpenOccurred) >= @CutoffTime THEN 1 ELSE 0 END) = 1 -- Whether the position was opened after 22pm 
	  THEN CONVERT(DATE,DATEADD(dd,1,CONVERT(DATE,OpenOccurred)))					-- Then we switch the OpenOccurred to be beginning of the next day
      ELSE CONVERT(DATE,OpenOccurred) END AS NewOpenOccurred											-- otherwise we keep the same date
,dp.CloseDateID
,dp.CloseOccurred
,dp.CloseOccurred AS NewCloseOccurred
,dp.CID
,dc.RealCID
,dc.GCID
,dc.UserName
,dc.CountryID
,dp.InstrumentID
,dp.IsSettled
,dp.IsBuy
,dp.Leverage
,dp.AmountInUnitsDecimal
,0 AS ClosedOnWeekend
FROM [DWH_dbo].[Dim_Position] dp WITH (NOLOCK)
JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK) 
ON dp.CID = dc.RealCID 
WHERE
dc.IsValidCustomer = 1 AND
dc.WeekendFeePrecentage = 0 
AND (dp.CloseDateID = 0 OR dp.CloseOccurred  >= @EndTrade) --units held at cuttoff
AND dp.OpenOccurred < @EndTrade 

--select count(*) from #Positions

----------------------------------------------------------------------------
--JOIN OF #Positions,Dim_Instrument,#Instruments_Groups,#Units_per_Contract
--Only Instruments from #Instruments_Groups OR Stocks and ETF with Leverage>1 OR Crypto CFDS - Manually 

IF OBJECT_ID('tempdb..#Positions_Relevant_Inst') IS NOT NULL 
DROP TABLE #Positions_Relevant_Inst
CREATE TABLE #Positions_Relevant_Inst
   WITH (HEAP, DISTRIBUTION=HASH (InstrumentID))      
AS

SELECT 
p.Date
,p.DateID
,p.PositionID
,p.RealCID
,p.GCID
,p.UserName
,p.CountryID
,p.OpenDateID
,p.OpenOccurred
,p.NewOpenOccurred
,p.CloseDateID
,p.CloseOccurred
,p.NewCloseOccurred
,CAST(CONVERT(VARCHAR(8), DATEADD(DAY,-1,p.NewCloseOccurred), 112) AS INT) AS NewCloseOccurredMinusOneID
,p.InstrumentID
,p.IsTheDayBefore
,i.InstrumentTypeID
,i.InstrumentType
,i.[Name] AS InstrumentName
,g.[name] AS InstrumentName_InstrumentGroup
,g.instrument_group as InstrumentGroup
,g.instrument_type_id AS InstrumentType_ID_InstrumentGroup
,u.units_per_contract AS Units_per_Contract
,i.Exchange
,e.ExchangeID
,p.IsBuy
,p.Leverage
,p.AmountInUnitsDecimal
,p.IsSettled
,p.ClosedOnWeekend
FROM #Positions p WITH (NOLOCK)
JOIN [DWH_dbo].[Dim_Instrument] i WITH (NOLOCK)
ON p.InstrumentID = i.InstrumentID
LEFT JOIN [Dealing_dbo].[Dealing_Islamic_Instruments_Groups] g
ON p.InstrumentID = g.instrument_id
LEFT JOIN [Dealing_dbo].[Dealing_Islamic_Units_Per_Contract] u
ON p.InstrumentID = u.instrument_id
LEFT JOIN [DWH_dbo].[Dim_ExchangeInfo] e WITH (NOLOCK)
ON LOWER(i.Exchange) = LOWER(e.ExchangeDescription)
WHERE 
((i.InstrumentTypeID IN  (5,6) AND p.Leverage > 1 AND p.IsSettled = 0 AND p.IsBuy = 1) --Stocks and ETF CFDs above Leverage 1 Long Positions
OR (i.InstrumentTypeID = 10 AND p.IsSettled = 0 AND (CASE WHEN p.CountryID = 79 AND p.Leverage = 1 AND p.IsBuy = 1 THEN 1 ELSE 0 END = 0)) -- Crypto CFDs positions except German leverage 1 Long Positions
OR g.instrument_type_id IS NOT NULL)--Manually

--select distinct InstrumentID from #Positions_Relevant_Inst where ExchangeID = 2
--select * from #Positions_Relevant_Inst WHERE InstrumentTypeID = 10 order by ClosedOnWeekend desc

----------------------------------------------------------------------------
--Adding EOD Prices and Currencies
--Creating Days_Open column calculated according to Harnan's requirements - Manually
--Only ClosedOnWeekend = 0

IF OBJECT_ID('tempdb..#Positions2') IS NOT NULL 
DROP TABLE #Positions2
CREATE TABLE #Positions2
   WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT 
t.*
,CASE WHEN t.InstrumentID IN (17,22,339,340,341,343,344) OR (ExchangeID >= 3  AND ExchangeID <> 8) THEN (SELECT SUM(Count_Fri) FROM #Dates WHERE FullDate BETWEEN NewOpenOccurred AND [Date])  --Manually
      WHEN (ExchangeID = 1 and t.InstrumentID <> 62) OR ExchangeID = 2 THEN (SELECT SUM(Count_Wed) FROM #Dates WHERE FullDate BETWEEN NewOpenOccurred AND [Date])
	  WHEN (ExchangeID = 1 and t.InstrumentID = 62) THEN (SELECT SUM(Count_Thu) FROM #Dates WHERE FullDate BETWEEN NewOpenOccurred AND [Date])
	  WHEN ExchangeID = 8 THEN (SELECT SUM(Count_All) FROM #Dates WHERE FullDate BETWEEN NewOpenOccurred AND [Date])
	  ELSE (SELECT SUM(Count_i) FROM #Dates WHERE FullDate BETWEEN NewOpenOccurred AND [Date])
	  END AS Days_Open
,f.Bid
,f.Ask
,f.ConvertRateIsBuy_1
,f.ConvertRateIsBuy_0
,CASE WHEN IsBuy = 1 THEN Bid*ConvertRateIsBuy_1 ELSE Ask*ConvertRateIsBuy_0 END AS USD_Price
FROM #Positions_Relevant_Inst t
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit f
ON t.DateID = f.OccurredDateID AND t.InstrumentID = f.InstrumentID AND f.ConvertRateIsBuy_1 IS NOT NULL 
WHERE ClosedOnWeekend = 0

--select * from #Positions2


----------------------------------------------------------------------------
--Adding EOD Prices and Currencies
--Creating Days_Open column calculated according to Harnan's requirements - Manually

IF OBJECT_ID('tempdb..#Final_Table_Step2') IS NOT NULL 
DROP TABLE #Final_Table_Step2
CREATE TABLE #Final_Table_Step2
   WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT
t.*
,a.admin_fee_usd AS Admin_Fee_USD
,a.grace_period AS GracePeriod
,Days_Open - grace_period AS Days_Admin_Fee
,CASE WHEN ExchangeID = 8 AND Days_Open - grace_period > 0 THEN 1
--WHEN ClosedOnWeekend = 1 AND Days_Open - grace_period > 1 AND convert(Date,NewCloseOccurred) = @Date
--THEN 2
--WHEN ClosedOnWeekend = 1 AND Days_Open - grace_period > 0
--THEN 1
	  WHEN (DATEPART(dw,@Date) = 6 AND (t.InstrumentID IN (17,22,339,340,341,343,344) OR (ExchangeID >= 3 AND ExchangeID <> 8))) OR
		   (DATEPART(dw,@Date) = 4 AND t.InstrumentID NOT IN (17,22,339,340,341,343,344,62) AND ExchangeID IN (1,2)) OR
		   (DATEPART(dw,@Date) = 5 AND t.InstrumentID = 62 AND ExchangeID = 1)
	  THEN (CASE WHEN Days_Open - grace_period = 1 THEN 1
				 WHEN Days_Open - grace_period = 2 THEN 2
				 WHEN Days_Open - grace_period > 2 THEN 3
				 ELSE 0 END)
	  WHEN (DATEPART(dw,@Date) BETWEEN 2 AND 6) and (Days_Open - grace_period) > 0 
	  THEN 1
	  ELSE 0 
	  END AS Days_To_Charge
FROM #Positions2 t 
LEFT JOIN [Dealing_dbo].[Dealing_Islamic_Admin_Fee_Per_Group] a
ON (t.InstrumentGroup = a.instrument_group AND t.InstrumentTypeID = a.instrument_type_id) OR (t.InstrumentTypeID = a.instrument_type_id AND t.InstrumentGroup IS NULL)


----------------------------------------------------------------------------
--Adding AdminFee - Manually

IF OBJECT_ID('tempdb..#Final_Table') IS NOT NULL 
DROP TABLE #Final_Table
CREATE TABLE #Final_Table 
   WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT 
[Date]
,DateID
,PositionID
,RealCID
,GCID
,UserName
,CountryID
,OpenDateID
,CloseDateID
,OpenOccurred
,NewOpenOccurred
,CloseOccurred
,NewCloseOccurred
,IsTheDayBefore
,InstrumentTypeID
,InstrumentType
,InstrumentID
,InstrumentName
,InstrumentType_ID_InstrumentGroup
,InstrumentName_InstrumentGroup
,InstrumentGroup
,Units_per_Contract
,Exchange
,ExchangeID
,IsBuy
,Leverage
,IsSettled
,ClosedOnWeekend
,Bid
,Ask
,ConvertRateIsBuy_1
,ConvertRateIsBuy_0
,USD_Price
,AmountInUnitsDecimal
,Admin_Fee_USD
,Days_Open
,GracePeriod
,Days_Admin_Fee
,NULL AS [Front]
,NULL AS [Next]
,NULL AS Days_Between_Expiration 
,Days_To_Charge
,(CASE WHEN InstrumentTypeID = 1 THEN (ABS(AmountInUnitsDecimal)/100000)*Admin_Fee_USD*Days_To_Charge
	 WHEN InstrumentTypeID = 2 THEN (ABS(AmountInUnitsDecimal)/Units_per_Contract)*Admin_Fee_USD*Days_To_Charge
	 WHEN InstrumentTypeID = 4 THEN ABS(AmountInUnitsDecimal)*Admin_Fee_USD*Days_To_Charge
	 WHEN InstrumentTypeID in (5,6) THEN ((ABS(AmountInUnitsDecimal)*USD_Price)/10000)*Admin_Fee_USD*Days_To_Charge
	 WHEN InstrumentTypeID = 10 THEN ((ABS(AmountInUnitsDecimal)*USD_Price)/10000)*Admin_Fee_USD*Days_To_Charge
	 ELSE 0
	 END)*(-1) AS Final_Fee
FROM #Final_Table_Step2
WHERE InstrumentID
NOT IN
(
6775,
1053,
1054,
1360,
1353,
1352,
1359,
1349,
1361,
1346,
1357,
6253,
8620,
2687,
3011,
8690,
2683,
1189,
1193,
2902,
1199,
2641,
6219,
2306,
2594,
2393
)
--select * from #Final_Table WHERE Days_To_Charge > 0


DELETE FROM [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee] WHERE Date = @Date

INSERT INTO [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee]
	([Date]
	,DateID
	,PositionID
	,RealCID
	,GCID
	,UserName
	,OpenDateID
	,CloseDateID
	,OpenOccurred
	,NewOpenOccurred
	,CloseOccurred
	,NewCloseOccurred
	,IsTheDayBefore
	,InstrumentTypeID
	,InstrumentType
	,InstrumentID
	,InstrumentName
	,InstrumentType_ID_InstrumentGroup
	,InstrumentName_InstrumentGroup
	,InstrumentGroup
	,Units_per_Contract
	,Exchange
	,ExchangeID
	,IsBuy
	,Leverage
	,IsSettled
	,ClosedOnWeekend
	,Bid
	,Ask
	,ConvertRateIsBuy_1
	,ConvertRateIsBuy_0
	,USD_Price
	,AmountInUnitsDecimal
	,Admin_Fee_USD
	,Days_Open
	,GracePeriod
	,Days_Admin_Fee
	,Days_To_Charge
	,Final_Fee
	,Fee_Type_ID
	,[UpdateDate]
	,CountryID
)
SELECT
[Date]
,DateID
,PositionID
,RealCID
,GCID
,UserName
,OpenDateID
,CloseDateID
,OpenOccurred
,NewOpenOccurred
,CloseOccurred
,NewCloseOccurred
,IsTheDayBefore
,InstrumentTypeID ---TABLE
,InstrumentType
,InstrumentID
,InstrumentName
,InstrumentType_ID_InstrumentGroup ---TABLE
,InstrumentName_InstrumentGroup
,InstrumentGroup
,Units_per_Contract
,Exchange
,ExchangeID
,IsBuy
,Leverage
,IsSettled
,ClosedOnWeekend
,Bid
,Ask
,ConvertRateIsBuy_1
,ConvertRateIsBuy_0
,USD_Price
,AmountInUnitsDecimal
,Admin_Fee_USD
,Days_Open
,GracePeriod
,Days_Admin_Fee
,Days_To_Charge
,Final_Fee
,1
,GETDATE()
,CountryID
FROM #Final_Table

END 


--SELECT * FROM [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee] where DateID = 20240403
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_dbo.SP_Islamic_Administrative_Fee` | synapse_sp | Dealing_dbo | SP_Islamic_Administrative_Fee | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Islamic_Administrative_Fee.sql` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | synapse | DWH_dbo | Fact_CurrencyPriceWithSplit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group` | synapse | Dealing_dbo | Dealing_Islamic_Admin_Fee_Per_Group | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Islamic_Admin_Fee_Per_Group.md` |
| `Dealing_dbo.Dealing_Islamic_Instruments_Groups` | synapse | Dealing_dbo | Dealing_Islamic_Instruments_Groups | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Islamic_Instruments_Groups.md` |
| `Dealing_dbo.Dealing_Islamic_Units_Per_Contract` | synapse | Dealing_dbo | Dealing_Islamic_Units_Per_Contract | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Islamic_Units_Per_Contract.md` |
| `Dim_Position.PositionID` | unresolved | Dim_Position | PositionID | `—` |
| `Dim_Customer.RealCID` | unresolved | Dim_Customer | RealCID | `—` |
| `Dim_Customer.GCID` | unresolved | Dim_Customer | GCID | `—` |
| `Dim_Customer.UserName` | unresolved | Dim_Customer | UserName | `—` |
| `Dim_Customer.CountryID` | unresolved | Dim_Customer | CountryID | `—` |
| `Dim_Position.OpenDateID` | unresolved | Dim_Position | OpenDateID | `—` |
| `Dim_Position.OpenOccurred` | unresolved | Dim_Position | OpenOccurred | `—` |
| `Dim_Position.CloseDateID` | unresolved | Dim_Position | CloseDateID | `—` |
| `Dim_Position.CloseOccurred` | unresolved | Dim_Position | CloseOccurred | `—` |
| `Dim_Instrument.InstrumentTypeID` | unresolved | Dim_Instrument | InstrumentTypeID | `—` |
| `Dim_Position.InstrumentID` | unresolved | Dim_Position | InstrumentID | `—` |
| `Dealing_Islamic_Instruments_Groups.instrument_group` | unresolved | Dealing_Islamic_Instruments_Groups | instrument_group | `—` |
| `Dealing_Islamic_Units_Per_Contract.units_per_contract` | unresolved | Dealing_Islamic_Units_Per_Contract | units_per_contract | `—` |
| `Dim_ExchangeInfo.ExchangeID` | unresolved | Dim_ExchangeInfo | ExchangeID | `—` |
| `Dim_Position.IsBuy` | unresolved | Dim_Position | IsBuy | `—` |
| `Dim_Position.Leverage` | unresolved | Dim_Position | Leverage | `—` |
| `Dim_Position.AmountInUnitsDecimal` | unresolved | Dim_Position | AmountInUnitsDecimal | `—` |
| `Dealing_Islamic_Admin_Fee_Per_Group.admin_fee_usd` | unresolved | Dealing_Islamic_Admin_Fee_Per_Group | admin_fee_usd | `—` |
| `Dealing_Islamic_Admin_Fee_Per_Group.grace_period` | unresolved | Dealing_Islamic_Admin_Fee_Per_Group | grace_period | `—` |

