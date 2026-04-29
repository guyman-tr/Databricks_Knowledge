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

- **Schema**: `DWH_dbo`
- **Object**: `Dim_HistorySplitRatio`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/DWH_dbo/Dim_HistorySplitRatio/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_HistorySplitRatio\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_HistorySplitRatio\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Tables\DWH_dbo.Dim_HistorySplitRatio.sql`

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

# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_HistorySplitRatio`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_HistorySplitRatio.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_HistorySplitRatio]
(
	[ID] [int] NOT NULL,
	[InstrumentID] [int] NOT NULL,
	[MinDate] [datetime] NULL,
	[MaxDate] [datetime] NULL,
	[PriceRatio] [decimal](16, 8) NOT NULL,
	[AmountRatio] [decimal](16, 8) NOT NULL,
	[PriceRatioUnAdjusted] [decimal](19, 4) NOT NULL,
	[AmountRatioUnAdjusted] [decimal](19, 4) NOT NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[InstrumentID] ASC,
		[MinDate] ASC,
		[MaxDate] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `PriceLog.History.SplitRatio` — production
- **Resolved as**: `etoro.History.SplitRatio`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\History\Tables\History.SplitRatio.md`

# History.SplitRatio

> Active stock split ratio registry for eToro instruments - records each split event with the price and amount adjustment ratios applied to positions, orders, and historical prices, along with a multi-phase completion tracker. This is the primary data store (not a history table), with its own temporal history in History.HistorySplitRatio.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on ID; UNIQUE NONCLUSTERED on InstrumentID + MinDate + MaxDate) |

---

## 1. Business Meaning

**IMPORTANT**: Despite being in the `History` schema, `History.SplitRatio` is the **active primary data store** for stock split ratios. It has its own temporal history table at `History.HistorySplitRatio` (via `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[HistorySplitRatio])`). It was placed in the History schema because it maintains a historical time-series of split events.

This table is the central registry for **stock split adjustments** on eToro's stock instruments. When a publicly listed company performs a stock split (or reverse split), eToro must:
1. Adjust the current prices of the instrument by `PriceRatio`
2. Adjust all customer open positions (units held) by `AmountRatio`
3. Adjust open and close orders
4. Recalculate holding fees
5. Update Redis cache and send notifications

Each row represents one split event for one instrument, bounded by `MinDate`/`MaxDate`. The "active" row for each instrument has `MaxDate = '2100-01-01'` (sentinel). When a new split occurs, the old row's MaxDate is set to the new split's MinDate, and a new row is inserted.

The `CK_InstrumentIsStock` check constraint (`InstrumentID > 1000`) ensures only stocks (not forex, crypto, or other non-stock instruments below ID 1000) have split records.

**Note**: Most of the 10,280 rows have `PriceRatio=1, AmountRatio=1` with the full default date range (2000-01-01 to 2100-01-01) - these are initialization rows for instruments that have no split history, establishing a 1:1 baseline ratio. Only rows with ratios != 1 represent actual split events.

---

## 2. Business Logic

### 2.1 Split Ratio Time-Series Pattern

**What**: Each instrument maintains a chain of non-overlapping split ratio records from its earliest history to the far future.

**Columns/Parameters Involved**: `InstrumentID`, `MinDate`, `MaxDate`, `PriceRatio`, `AmountRatio`

**Rules**:
- `MinDate` = the start of the period this ratio applies (inclusive)
- `MaxDate` = the end of the period (exclusive); sentinel value `'2100-01-01'` = currently active
- UNIQUE INDEX on `(InstrumentID, MinDate, MaxDate)` - no overlapping date ranges per instrument
- `History.InsertSplitRatio` inserts a new split by:
  1. Setting the current active row's `MaxDate = @MinDate`
  2. Inserting a new row with the new ratios and `MinDate = @MinDate, MaxDate = '2100-01-01'`
- PriceRatio and AmountRatio are inversely related: for a 2-for-1 forward split, `AmountRatio=2, PriceRatio=0.5`
- Computed from UnitsBefore/UnitsAfter: `AmountRatio = UnitsAfter / UnitsBefore`, `PriceRatio = UnitsBefore / UnitsAfter`

**Examples**:
- 2-for-1 forward split: PriceRatio=0.5, AmountRatio=2 (positions doubled, price halved)
- 1-for-2 reverse split: PriceRatio=2, AmountRatio=0.5 (positions halved, price doubled)

**Diagram**:
```
InstrumentID=1004 split history:
  Row 1: MinDate=2000-01-01, MaxDate=2025-01-01, Ratio=1 (no adjustment needed)
  Row 2: MinDate=2025-01-01, MaxDate=2025-01-20, PriceRatio=0.5, AmountRatio=2 (2-for-1 split)
  Row 3: MinDate=2025-01-20, MaxDate=2100-01-01, Ratio=? (active - next split pending)
```

### 2.2 Multi-Phase Split Execution

**What**: The split adjustment is applied in multiple phases across different system components, each tracked by a completion flag.

**Columns/Parameters Involved**: `IsCompletedOpenPositions`, `IsCompletedClosePositions`, `IsCompletedOpenOrders`, `IsCompletedCloseOrders`, `IsCompletedPricAndAmount`, `IsCompletedModifyPrice`, `IsCompleteHoldingFees`, `IsNotificationSent`, `IsNotificationStartSent`, `IsCurrencyPriceChanged`, `IsRedisUpdated`

**Rules**:
- All flags default to 0 on insert; set to 1 as each phase completes
- `Trade.SplitOpenPositions` processes open positions -> sets `IsCompletedOpenPositions=1`
- `History.SplitClosePositions` processes close positions -> sets `IsCompletedClosePositions=1`
- `Trade.OpenOrdersSplit` / `Stocks.OpenOrdersSplit` process open orders -> `IsCompletedOpenOrders=1`
- `Trade.CloseOrdersSplit` / `Stocks.CloseOrdersSplit` process close orders -> `IsCompletedCloseOrders=1`
- `Trade.SplitHoldingFees` adjusts holding fees -> sets `IsCompleteHoldingFees=1`
- Notification flags track user communication; Redis flag tracks cache invalidation
- A split is fully complete only when all applicable flags are 1
- Out of 10,280 rows, only 6 have all mandatory flags set to 1 (most are init rows with ratio=1 where processing isn't required)

### 2.3 Adjusted vs. Unadjusted Ratios

**What**: Both precise computed ratios and the original unadjusted values are stored for auditability.

**Columns/Parameters Involved**: `PriceRatio`, `AmountRatio`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted`, `PriceRatioUnAdjustedFull`, `AmountRatioUnAdjustedFull`, `UnitsBefore`, `UnitsAfter`

**Rules**:
- `UnitsBefore` and `UnitsAfter`: the raw share counts before and after the split (e.g., 1 and 2 for a 2-for-1 split)
- `PriceRatio` = `UnitsBefore / UnitsAfter` (computed by History.InsertSplitRatio)
- `AmountRatio` = `UnitsAfter / UnitsBefore` (computed by History.InsertSplitRatio)
- `PriceRatioUnAdjusted` / `AmountRatioUnAdjusted`: stored as money - original ratio value before any cumulative adjustment
- `PriceRatioUnAdjustedFull`: decimal(38,19) - maximum precision version for critical calculations

---

## 3. Data Overview

| ID | InstrumentID | MinDate | MaxDate | PriceRatio | AmountRatio | UnitsBefore | UnitsAfter | Meaning |
|---|---|---|---|---|---|---|---|---|
| 10652 | 100038 | 2025-09-01 11:25 | 2025-09-01 11:43 | 0.001 | 1000 | 1 | 24 | Large split (1000x amount ratio); active for only 18 minutes (test or rapid correction) |
| 9629 | 1004 | 2025-01-01 | 2025-01-20 11:27 | 0.5 | 2 | 1 | 2 | Standard 2-for-1 forward split for instrument 1004 |
| 9627 | 1002 | 2025-01-20 09:37 | 2025-01-20 09:44 | 2.0 | 0.5 | 1 | 2 | Reverse split (1-for-2) for instrument 1002; brief 7-minute window |
| 9624 | 1013 | 2025-01-20 06:37 | 2025-01-20 06:43 | 0.25 | 4 | 1 | 2 | 4-for-1 split for instrument 1013 |
| 12036 | 1053988 | 2000-01-01 | 2100-01-01 | 1 | 1 | null | null | Typical initialization row: no split, full date range, all flags=0 |

Total: 10,280 rows | 9,928 distinct instruments | 6 fully completed splits

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto). |
| 3 | MinDate | datetime | NO | '2000-01-01' | VERIFIED | Start of the period this split ratio is effective. Default '2000-01-01' means "from the beginning of the instrument's history." The split adjustment applies to transactions from this date forward until MaxDate. |
| 4 | MaxDate | datetime | NO | '2100-01-01' | VERIFIED | End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means "currently active - no end date set." When a new split occurs, the current active row's MaxDate is set to the new split's MinDate. |
| 5 | PriceRatio | decimal(16,8) | NO | 1 | VERIFIED | Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment. |
| 6 | AmountRatio | decimal(16,8) | NO | 1 | VERIFIED | Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment. |
| 7 | IsCompletedOpenPositions | tinyint | NO | 0 | CODE-BACKED | 1 when all open customer positions for this instrument have had their unit counts adjusted by AmountRatio. Set by Trade.SplitOpenPositions. |
| 8 | IsCompletedClosePositions | tinyint | NO | 0 | CODE-BACKED | 1 when all closed positions within the split window have had their data adjusted. Set by History.SplitClosePositions. |
| 9 | IsCompletedOpenOrders | tinyint | NO | 0 | CODE-BACKED | 1 when all open pending orders have been adjusted for the split. Set by Trade.OpenOrdersSplit or Stocks.OpenOrdersSplit. |
| 10 | IsCompletedCloseOrders | tinyint | NO | 0 | CODE-BACKED | 1 when all close orders have been adjusted for the split. Set by Trade.CloseOrdersSplit or Stocks.CloseOrdersSplit. |
| 11 | PriceRatioUnAdjusted | money | NO | - | CODE-BACKED | Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. |
| 12 | AmountRatioUnAdjusted | money | NO | - | CODE-BACKED | Original unadjusted amount ratio stored as money type. Before cumulative adjustments. |
| 13 | IsNotificationSent | tinyint | NO | 0 | CODE-BACKED | 1 when the "split completed" user notification has been sent to affected customers. |
| 14 | IsCurrencyPriceChanged | tinyint | NO | 0 | CODE-BACKED | 1 when the currency price has been updated to reflect the split. |
| 15 | IsRedisUpdated | tinyint | NO | 0 | CODE-BACKED | 1 when the Redis cache has been invalidated/updated with the new split ratios. |
| 16 | IsNotificationStartSent | tinyint | YES | 0 | CODE-BACKED | 1 when the "split starting" notification was sent before the split begins. Nullable (added later). |
| 17 | IsCompletedPricAndAmount | tinyint | YES | 0 | CODE-BACKED | 1 when price and amount data in historical price feeds have been adjusted. Nullable (added later). |
| 18 | IsCompletedModifyPrice | tinyint | YES | 0 | CODE-BACKED | 1 when the current market price has been adjusted. Nullable (added later). |
| 19 | IsCompleteHoldingFees | tinyint | NO | 0 | CODE-BACKED | 1 when holding fees (overnight/weekend fees) have been recalculated for the split. Set by Trade.SplitHoldingFees. |
| 20 | DbLoginName | nvarchar(128) | - | - | CODE-BACKED | Computed column: `suser_name()` - SQL Server login that modified this split record. |
| 21 | AppLoginName | varchar(500) | - | - | CODE-BACKED | Computed column: `CONVERT(varchar(500), context_info())` - application context at time of change. |
| 22 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Temporal system versioning start time. Used by History.HistorySplitRatio for tracking changes to split records. |
| 23 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | Temporal system versioning end time. |
| 24 | HostName | - | - | - | CODE-BACKED | Computed column: `host_name()` - server hostname that modified the record. |
| 25 | UnitsBefore | decimal(19,12) | YES | - | VERIFIED | Number of units per share before the split (e.g., 1). Used to compute PriceRatio and AmountRatio. Nullable for older records inserted before this column was added. |
| 26 | UnitsAfter | decimal(19,12) | YES | - | VERIFIED | Number of units per share after the split (e.g., 2 for a 2-for-1 split). Used with UnitsBefore to derive the adjustment ratios. |
| 27 | PriceRatioUnAdjustedFull | decimal(38,19) | YES | - | CODE-BACKED | Ultra-high precision (38,19) version of PriceRatioUnAdjusted. Added to avoid rounding errors in cumulative split calculations for instruments with many historical splits. |
| 28 | AmountRatioUnAdjustedFull | decimal(38,19) | YES | - | CODE-BACKED | Ultra-high precision (38,19) version of AmountRatioUnAdjusted. Same purpose as PriceRatioUnAdjustedFull. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The stock instrument being split. CHECK enforces InstrumentID > 1000 (stocks only). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.HistorySplitRatio | HISTORY_TABLE | Temporal History | Temporal history of changes to this table's rows. |
| History.InsertSplitRatio | INSERT/UPDATE | Writer | Creates new split events; closes prior active row by setting MaxDate. |
| History.SplitClosePositions | SELECT/UPDATE | Reader + Updater | Adjusts close positions for the split; sets IsCompletedClosePositions=1. |
| Trade.SplitOpenPositions | SELECT/UPDATE | Reader + Updater | Adjusts open positions; sets IsCompletedOpenPositions=1. |
| Trade.ActivateSplit_Inner | SELECT/UPDATE | Orchestrator | Orchestrates the full split execution pipeline. |
| Trade.SplitHoldingFees | SELECT/UPDATE | Reader + Updater | Adjusts holding fees; sets IsCompleteHoldingFees=1. |
| Trade.OpenOrdersSplit / Stocks.OpenOrdersSplit | SELECT/UPDATE | Reader + Updater | Adjusts open orders; sets IsCompletedOpenOrders=1. |
| Trade.CloseOrdersSplit / Stocks.CloseOrdersSplit | SELECT/UPDATE | Reader + Updater | Adjusts close orders; sets IsCompletedCloseOrders=1. |
| Trade.InsertSplitToPriceDB | SELECT | Reader | Propagates split ratios to the price database. |
| dbo.AccountStatement_GetTransactionsReport_v* | SELECT | Reader | Uses split ratios to adjust historical transaction amounts in account statements. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SplitRatio (table)
  -> Trade.Instrument (FK on InstrumentID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK on InstrumentID - only valid stock instruments (ID > 1000) can have split records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.HistorySplitRatio | Table | Temporal history of changes to this table (HISTORY_TABLE). |
| History.InsertSplitRatio | Procedure | Primary writer - creates split events and closes prior active rows. |
| History.SplitClosePositions | Procedure | Adjusts close positions for split events. |
| Trade.SplitOpenPositions | Procedure | Adjusts open customer positions. |
| Trade.ActivateSplit_Inner | Procedure | Main orchestrator of the split pipeline. |
| Trade.SplitHoldingFees | Procedure | Recalculates holding fees post-split. |
| Trade.OpenOrdersSplit / Stocks.OpenOrdersSplit | Procedure | Adjusts open orders. |
| Trade.CloseOrdersSplit / Stocks.CloseOrdersSplit | Procedure | Adjusts close orders. |
| Trade.InsertSplitToPriceDB | Procedure | Propagates ratios to price DB. |
| dbo.AccountStatement_GetTransactionsReport_v* | Procedure | Historical reporting with split-adjusted amounts. |
| Trade.CheckValidInstruments | Procedure | References split ratio data. |
| Monitor.CheckInsertInstrumentNewProcess | Procedure | Monitors split insertion process. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistorySplitRatio | CLUSTERED PK | ID ASC | - | - | Active |
| IX_InstrumentID_MinDate_MaxDate | UNIQUE NONCLUSTERED | InstrumentID ASC, MinDate ASC, MaxDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistorySplitRatio | PRIMARY KEY | Uniqueness on ID. CLUSTERED. NOT FOR REPLICATION. |
| IX_InstrumentID_MinDate_MaxDate | UNIQUE | No overlapping date ranges per instrument. |
| FK_HistorySplitRatio_TradeInstrument | FOREIGN KEY | InstrumentID -> Trade.Instrument. |
| CK_HistorySplitAmountPriceRatio | CHECK | AmountRatio > 0. |
| CK_HistorySplitRatioPriceRatio | CHECK | PriceRatio > 0. |
| CK_InstrumentIsStock | CHECK | InstrumentID > 1000 (stocks only). |
| DF_HistorySplitRatio_MinDate | DEFAULT | MinDate defaults to '2000-01-01'. |
| DF_HistorySplitRatio_MaxDate | DEFAULT | MaxDate defaults to '2100-01-01' (active sentinel). |
| DF_HistorySplitRatio_PriceRatio | DEFAULT | PriceRatio defaults to 1 (no adjustment). |
| DF_HistorySplitRatio_AmountRatio | DEFAULT | AmountRatio defaults to 1 (no adjustment). |

---

## 8. Sample Queries

### 8.1 Get current active split ratio for a specific instrument
```sql
SELECT
    ID,
    InstrumentID,
    PriceRatio,
    AmountRatio,
    UnitsBefore,
    UnitsAfter,
    MinDate,
    MaxDate
FROM [History].[SplitRatio] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND MaxDate = '21000101'  -- active sentinel
```

### 8.2 Find splits in progress (not fully completed)
```sql
SELECT
    ID,
    InstrumentID,
    PriceRatio,
    AmountRatio,
    IsCompletedOpenPositions,
    IsCompletedClosePositions,
    IsCompletedOpenOrders,
    IsCompletedCloseOrders,
    IsCompleteHoldingFees,
    IsNotificationSent,
    MinDate
FROM [History].[SplitRatio] WITH (NOLOCK)
WHERE PriceRatio <> 1
  AND (IsCompletedOpenPositions = 0
    OR IsCompletedClosePositions = 0
    OR IsCompleteHoldingFees = 0)
ORDER BY MinDate DESC
```

### 8.3 Get applicable split ratio for a transaction at a historical date
```sql
SELECT PriceRatio, AmountRatio
FROM [History].[SplitRatio] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND @TransactionDate >= MinDate
  AND @TransactionDate < MaxDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SplitRatio | Type: Table | Source: etoro/etoro/History/Tables/History.SplitRatio.sql*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dim_HistorySplitRatio_DL_To_Synapse] AS
BEGIN

-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-10-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Dim_History_SplitRatio_DL_To_Synapse]
-- =============================================



 --truncate table [DWH_dbo].[History_SplitRatio] ----------------------------


    truncate table [DWH_dbo].[Dim_HistorySplitRatio]
--------------------------------------------------
-- --Insert data into [DWH_dbo].[History_SplitRatio] -------------------
	
	

	INSERT INTO [DWH_dbo].[Dim_HistorySplitRatio]
	(
	         ID	
			,InstrumentID	
			,MinDate	
			,MaxDate	
			,PriceRatio	
			,AmountRatio	
			,PriceRatioUnAdjusted  
			,AmountRatioUnAdjusted 
			,UpdateDate 
	  )

	 SELECT
			 ID	
			,InstrumentID	
			,MinDate	
			,MaxDate	
			,PriceRatio	
			,AmountRatio	
			,PriceRatioUnAdjusted  
			,AmountRatioUnAdjusted 
			,Getdate() AS UpdateDate
	From [DWH_staging].[etoro_History_SplitRatio]



END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio | `—` |
| `PriceLog.History.SplitRatio` | production | History | SplitRatio | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\History\Tables\History.SplitRatio.md` |
| `DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse` | synapse_sp | DWH_dbo | SP_Dim_HistorySplitRatio_DL_To_Synapse | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse.sql` |
| `DWH_staging.etoro_History_SplitRatio` | unresolved | DWH_staging | etoro_History_SplitRatio | `—` |

