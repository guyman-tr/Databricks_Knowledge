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

- **Schema**: `BI_DB_dbo`
- **Object**: `Group_LTV_Table`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/Group_LTV_Table/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\Group_LTV_Table\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\Group_LTV_Table\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.Group_LTV_Table.sql`

---

# build-wiki-bidb-batch

You are running the DWH Semantic Documentation pipeline for schema BI_DB_dbo.
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
- **OpsDB priority file**: `.specify/Configs/opsdb-objects-status.json`
- **OpsDB dependencies**: `.specify/Configs/opsdb-procedure-dependencies.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

---

# PRE-RESOLVED UPSTREAM BUNDLE

Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.Group_LTV_Table`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.Group_LTV_Table.sql`

```sql
CREATE TABLE [BI_DB_dbo].[Group_LTV_Table]
(
	[First_Month_Equity_Tier] [nvarchar](300) NULL,
	[First_Month_Cluster] [nvarchar](300) NULL,
	[Region] [nvarchar](300) NULL,
	[Revenue8Y_LTV_New_Group_LTV] [money] NULL,
	[Revenue8Y_LTV_NoExtreme_New_Group_LTV] [money] NULL,
	[Clients] [int] NULL,
	[UpdateDate] [date] NOT NULL
)
WITH
(
	DISTRIBUTION = HASH ( [Region] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 5 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.BI_DB_LTV_BI_Actual` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_LTV_BI_Actual`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_LTV_BI_Actual.md`

# BI_DB_dbo.BI_DB_LTV_BI_Actual

> Canonical customer-level Lifetime Value (LTV) output table. One row per depositor (~5.84M rows); consolidates three LTV model families: (1) multiplier-model predictions at 1Y/3Y/8Y horizons with volatility smoothing, (2) new-methodology 8Y Revenue LTV variants (with/without group supplement and outlier exclusion), and (3) behavioral segmentation inputs (cluster, equity tier, seniority). Refreshed daily by SP_LTV_BI_Actual (P0, SB_Daily). Primary upstream of BI_DB_LTV_BI_Actual_Daily_Snapshot (4.54B row archive) and LTV_FromDB_ToBigQuery export.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_LTV_Predictions, BI_DB_CIDFirstDates, BI_DB_CID_DailyCluster, Fact_SnapshotEquity, Revenue8Y model |
| **Refresh** | Daily; SP_LTV_BI_Actual, Priority 0, SB_Daily process (full replace) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_LTV_BI_Actual` is eToro's central Lifetime Value prediction store. It holds a current-state snapshot of every depositor's expected cumulative revenue across 1-, 3-, and 8-year horizons, updated daily. Each row represents one customer; the 5.84M rows cover all customers with a FirstDepositDate from 2007 to 2026-03.

The table consolidates two LTV model families:

**1. Multiplier-model predictions** (LTV_1Y/3Y/8Y, VolFix variants, GroupLevel) — from the `SP_LTV_Multiplier_Model` framework (documented in `BI_DB_LTV_Predictions`). These predict LTV by applying revenue multipliers to Current_ACC_Revenue based on the customer's seniority and cohort. Once a customer actually reaches a horizon (Seniority ≥ 12/36/96 months), the prediction column is replaced by the actual accumulated revenue — making these hybrid predicted/actual fields.

**2. Revenue8Y new-methodology predictions** (Revenue8Y_LTV_New and 6 variants) — a newer 2023+ model that produces additional 8Y predictions with group-level supplements and outlier filtering. Revenue8Y_LTV_New_Group_LTV is the recommended primary LTV signal for most downstream analytics.

The table also stores behavioural segmentation attributes (ClusterDetail, EquityTier, Seniority, MonthsSinceLastPosOpen) which are inputs to both LTV model families and enable cohort analysis without additional joins.

**Key downstream consumers**:
- `BI_DB_LTV_BI_Actual_Daily_Snapshot` (SP_D_LTV_BI_Actual_Snapshot, P20): daily timestamped archive (4.54B rows, 865 snapshots, 2023–present)
- `LTV_FromDB_ToBigQuery` (SP_LTV_FromDB_ToBigQuery): BigQuery export for marketing and growth analytics
- 13 total confirmed downstream dependents in BI_DB_dbo

---

## 2. Business Logic

### 2.1 LTV Horizon Family: Predicted vs. Actual Crossover

**What**: LTV_1Y/3Y/8Y are hybrid fields that hold predictions until the customer reaches the milestone, then switch to actuals.
**Columns Involved**: `LTV_1Y`, `LTV_3Y`, `LTV_8Y`, `Seniority`
**Rules**:
- Seniority < 12 months: `LTV_1Y` = multiplier-model prediction of 1Y revenue
- Seniority ≥ 12 months: `LTV_1Y` = actual accumulated revenue at month 12 from BI_DB_CID_MonthlyPanel_FullData
- Same crossover at Seniority ≥ 36 for LTV_3Y, and Seniority ≥ 96 for LTV_8Y
- Implication: querying LTV_1Y for customers with Seniority ≥ 12 returns realized revenue, NOT a forward prediction

### 2.2 Volatility Fix Variants (VolFix)

**What**: LTV_*_VolFix apply a 12-month rolling group average multiplier to smooth cohort-specific noise.
**Columns Involved**: `LTV_1Y_VolFix`, `LTV_3Y_VolFix`, `LTV_8Y_VolFix`
**Rules**:
- Group definition: (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier)
- Smoothing: `LTV_nY_VolFix = LTV_nY × (rolling_group_avg / current_group_avg)`, clamped to [0.5, 2.0]
- VolFix variants are the **preferred LTV values** for downstream revenue modelling — less sensitive to cohort-specific noise than raw predictions
- LTV_8Y_VolFix is the base for the group-level computation (LTV_8Y_GroupLevel)

### 2.3 Group Level LTV

**What**: LTV_8Y_GroupLevel assigns a cohort-average LTV to each customer — useful for thin-history customers.
**Columns Involved**: `LTV_8Y_GroupLevel`
**Rules**:
- = AVG(LTV_8Y_VolFix) across all customers in the same (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier) cohort
- Computed via post-INSERT UPDATE across the entire table
- All customers in the same cohort share the identical LTV_8Y_GroupLevel value
- For inactive customers with low Current_ACC_Revenue, LTV_8Y_GroupLevel > Revenue8Y_LTV_New (cohort median > individual zero-revenue estimate)
- **Do not** use as an upper bound for individual predictions — it reflects group median, not potential

### 2.4 Revenue8Y New-Methodology Variants

**What**: Six Revenue8Y variants from the 2023+ model, combining outlier exclusion and group supplement dimensions.
**Columns Involved**: `Revenue8Y_LTV_New`, `Revenue8Y_LTV_NoExtreme_New`, `Revenue8Y_LTV_New_WO_Group_LTV`, `Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV`, `Revenue8Y_LTV_New_Group_LTV`, `Revenue8Y_LTV_NoExtreme_New_Group_LTV`

| Variant | Outliers | Group Supplement | Recommended Use |
|---------|---------|-----------------|-----------------|
| Revenue8Y_LTV_New | Included | No | Individual prediction baseline |
| Revenue8Y_LTV_NoExtreme_New | Excluded | No | Conservative individual |
| Revenue8Y_LTV_New_WO_Group_LTV | Included | No (explicit 0) | Pure individual analysis |
| Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV | Excluded | No (explicit 0) | Most conservative individual |
| **Revenue8Y_LTV_New_Group_LTV** | Included | **Yes** | **Recommended for most use cases** |
| Revenue8Y_LTV_NoExtreme_New_Group_LTV | Excluded | Yes | Conservative blended |

- `_WO_Group_LTV` (without group LTV) variants are **0** (not NULL) where group-level assignment was applied — sum-aggregations undercount unless using `_Group_LTV` variants
- `Revenue8Y_LTV_All_Conv_Old`: legacy pre-2023 model; retained for historical comparison only

### 2.5 EquityTier Segmentation

**What**: Integer tier based on current realized equity balance.
**Columns Involved**: `EquityTier`
**Rules**:
- Tier 1: RealizedEquity < $100 OR NULL/missing — low equity / new / inactive (67% of rows)
- Tier 2: $100 ≤ RealizedEquity < $500 — medium equity (10%)
- Tier 3: RealizedEquity ≥ $500 — high equity (22%)
- NULL (~8K rows, <0.2%) — no matching Fact_SnapshotEquity row found
- Source: DWH_dbo.Fact_SnapshotEquity (via BI_DB_LTV_Predictions logic)

---

## 3. Query Advisory

### 3.1 Distribution & Index

`HASH(CID)` on a HEAP — no clustered index. Fast for customer-keyed lookups and full scans (5.84M rows is small enough for analytical aggregations). For large-scale aggregations without a CID filter, performance is still acceptable given the row count.

### 3.2 LTV Variant Selection Guide

| Use Case | Recommended Column |
|----------|-------------------|
| Primary 8Y LTV for all downstream | `Revenue8Y_LTV_New_Group_LTV` |
| Conservative 8Y (exclude outliers, blended) | `Revenue8Y_LTV_NoExtreme_New_Group_LTV` |
| Pure individual prediction (no group fallback) | `Revenue8Y_LTV_New` |
| Multiplier-model 8Y (volatility smoothed) | `LTV_8Y_VolFix` |
| Group-benchmark comparison | `LTV_8Y_GroupLevel` |
| Legacy compatibility | `Revenue8Y_LTV_All_Conv_Old` |

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average LTV by region and cluster | `SELECT NewMarketingRegion, ClusterDetail, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] WHERE EquityTier = 3 GROUP BY NewMarketingRegion, ClusterDetail ORDER BY AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) DESC` |
| Top 1000 highest LTV customers | `SELECT TOP 1000 CID, Revenue8Y_LTV_New_Group_LTV, ClusterDetail, EquityTier FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] ORDER BY Revenue8Y_LTV_New_Group_LTV DESC` |
| LTV by cohort (first funded month) | `SELECT FirstFundedMonth, COUNT(*) AS cohort_size, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] GROUP BY FirstFundedMonth ORDER BY FirstFundedMonth` |
| Active vs inactive customer LTV | `SELECT CASE WHEN MonthsSinceLastPosOpen = 0 THEN 'Active' ELSE 'Inactive' END AS status, COUNT(*) AS cnt, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] GROUP BY CASE WHEN MonthsSinceLastPosOpen = 0 THEN 'Active' ELSE 'Inactive' END` |

### 3.4 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `l.CID = dc.RealCID` | Customer demographics (country, registration date) |
| BI_DB_dbo.BI_DB_LTV_BI_Actual_Daily_Snapshot | `l.CID = s.CID AND s.SnapshotDate = @date` | Point-in-time LTV from any past date |
| BI_DB_dbo.BI_DB_LTV_Predictions | `l.CID = p.RealCID` | Cross-validate multiplier-model vs Revenue8Y predictions |

### 3.5 Gotchas

- **LTV_1Y/3Y/8Y switch to actuals at Seniority milestones** — these are NOT forward predictions for customers with Seniority ≥ 12/36/96. For pure forward prediction, use Revenue8Y_LTV_New_Group_LTV.
- **WO_Group_LTV = 0, not NULL** — where group LTV was applied, the WO_Group_LTV variants are 0. SUM(Revenue8Y_LTV_New_WO_Group_LTV) undercounts. Use Revenue8Y_LTV_New_Group_LTV for complete aggregations.
- **Currency = 'Non_USD' / 'USD'** — binary classification, NOT the actual account currency code. Do not use for currency conversion or forex analysis.
- **13% zero LTV_8Y rows** — 742K customers have LTV_8Y = 0 (no prediction generated). These are typically inactive or very recently registered customers. Filter WHERE LTV_8Y > 0 for revenue modelling.
- **HEAP** — no clustered index. Large aggregations without a CID predicate do full scans; acceptable at 5.84M rows but be aware.
- **SP code inaccessible** — SP_LTV_BI_Actual has empty sys.sql_modules definition; some column descriptions are inferred from sibling wikis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo wiki or production DB_Schema wiki) |
| Tier 2 | Derived from sibling BI_DB_dbo wikis, data sampling, or naming conventions |
| Tier 3 | Inferred from naming conventions or context only |
| Tier 4 | Undetermined — pending review |
| P | Propagation metadata (ETL timestamp columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within eToro DB. NOT NULL; hash distribution key. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NO | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NOT NULL. (Tier 1 — Customer.CustomerStatic) |
| 3 | NewMarketingRegion | varchar(50) | YES | Marketing region label. Matches Region in BI_DB_LTV_Predictions (DWH_dbo.Dim_Country.Region via Dictionary.MarketingRegion). Examples: UK (19%), German (15%), French (10%), CEE (8%), Italian (7%), USA (7%). Used as cohort dimension in LTV grouping. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 4 | FirstDepositDate | date | YES | Date of customer's first deposit. Range: 2007-08-29 to 2026-03-12. NULL for customers without deposit. (Tier 2 — BI_DB_CIDFirstDates context + data evidence) |
| 5 | FirstFundedMonth | date | YES | Month-end date of the customer's first funded month: EOMONTH(FirstNewFundedDate). Cohort anchor for group-level LTV averaging and VolFix rolling window. NULL for customers without FirstNewFundedDate (legacy depositors). (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 6 | Seniority | int | YES | Months from FirstFundedMonth to the current SP run date. Key LTV model input. Avg 57 months (4.8 years); max 164 months (13.7 years). Drives the predicted-vs-actual crossover at 12/36/96 months. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 7 | ClusterDetail | varchar(100) | YES | Customer behavioral cluster at the SP run date, from BI_DB_CID_DailyCluster. 7 values: Crypto (26%), Equities Traders (16%), Equities Crypto (14%), NoCluster (18%), Leveraged Traders (11%), Equities Investors (9%), Diversified Traders (6%). LTV model segmentation dimension. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 8 | EquityTier | int | YES | Equity tier from most recent Fact_SnapshotEquity: 1=RealizedEquity<$100 (67%), 2=$100-$500 (10%), 3=≥$500 (22%). NULL for <0.2% where no equity snapshot exists. LTV model segmentation dimension. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 9 | MonthsSinceLastPosOpen | int | YES | Months since this customer last opened a trading position. Inactivity indicator. Avg 37 months; value = 0 for currently active customers. Used in LTV model as recency signal. (Tier 2 — naming + data evidence) |
| 10 | Current_ACC_Revenue | numeric(38,2) | YES | Cumulative revenue this customer has generated for eToro to date. The base value for multiplier-model LTV calculation: LTV_nY = Current_ACC_Revenue / RatioSnapshotTo_nY. Adjusted for underestimation at low seniority (Seniority=1→÷0.80, Seniority=2→÷0.90, Seniority=3→÷0.95). (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 11 | DaysFromFTD | int | YES | Days from FirstDepositDate to the SP run date. Parallel to Seniority (which is in months from funded date); this is in calendar days from first deposit. Avg 1,809 days (~5 years). (Tier 2 — naming + data evidence) |
| 12 | LTV_1Y | money | YES | 1-year LTV: predicted cumulative broker revenue at 12 months from first funding. Switches to actual revenue at month 12 once Seniority ≥ 12. Pre-milestone: multiplier-model prediction. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 13 | LTV_3Y | money | YES | 3-year LTV: same hybrid predicted/actual pattern, crossover at Seniority ≥ 36 months. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 14 | LTV_8Y | money | YES | 8-year LTV: crossover at Seniority ≥ 96 months. Avg $1,266; max $46.5M; 13% zero. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 15 | LTV_1Y_VolFix | money | YES | 1Y LTV with 12-month rolling group average volatility smoothing. Clamped to [0.5, 2.0] × LTV_1Y. Preferred for revenue modelling. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 16 | LTV_3Y_VolFix | money | YES | 3Y LTV with volatility smoothing. Same clamping logic as LTV_1Y_VolFix. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 17 | LTV_8Y_VolFix | money | YES | 8Y LTV with volatility smoothing. **Preferred multiplier-model variant** for downstream analytics. Base for LTV_8Y_GroupLevel computation. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 18 | LTV_8Y_GroupLevel | money | YES | Post-INSERT group average: AVG(LTV_8Y_VolFix) across all customers in the same (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier) cohort. All cohort members share the same value. Better for inactive/new customers where individual history is thin. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 19 | Revenue8Y_LTV_New | money | YES | 8-year cumulative broker revenue prediction, new methodology (2023+). Individual prediction only — may be low for inactive customers. See Section 2.4 for variant selection guide. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 20 | Revenue8Y_LTV_NoExtreme_New | money | YES | 8Y LTV (new methodology) with statistical outliers excluded. Conservative lower bound for individual planning. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 21 | UpdateDate | datetime | NO | ETL metadata: timestamp when SP_LTV_BI_Actual last calculated this customer's LTV. NOT NULL. Note: In BI_DB_LTV_BI_Actual_Daily_Snapshot, this column reflects the LTV model refresh time, not the snapshot time — use Snapshot_UpdateDate there. (P) |
| 22 | Revenue8Y_LTV_New_WO_Group_LTV | money | YES | Individual 8Y LTV without group-level supplement. **Zero** (not NULL) where group-level assignment was applied. Use Revenue8Y_LTV_New_Group_LTV for complete aggregations. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 23 | Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV | money | YES | Outlier-trimmed individual 8Y LTV without group supplement. Most conservative individual estimate. Zero where group LTV applied. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 24 | First_Month_Equity_Tier | int | YES | Customer's equity tier (1/2/3) during their first funded month. Frozen at cohort entry for cohort stability. Distribution: Tier 1 (35%), Tier 2 (28%), Tier 3 (37%). (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 25 | First_Month_Cluster | varchar(100) | YES | Customer's behavioral cluster in their first funded month. Frozen at cohort entry. Enables first-month cohort analysis alongside current ClusterDetail. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 26 | Currency | varchar(300) | YES | Customer account currency classification. Binary values: 'Non_USD' (~67%), 'USD' (~32%), '' empty (~1%). Does NOT store the actual currency code — is a USD vs. non-USD flag used in LTV model calibration. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 27 | Revenue_Change_Percentage_Fixed | float | YES | Fixed calibration multiplier applied to base LTV prediction to adjust for known revenue projection bias. Small positive value (~0.02–0.05 observed). (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 28 | Revenue8Y_LTV_New_Group_LTV | money | YES | Blended 8Y LTV: individual prediction where history is sufficient; group-level supplement applied otherwise. **Recommended for most downstream use cases.** (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 29 | Revenue8Y_LTV_NoExtreme_New_Group_LTV | money | YES | Blended 8Y LTV without outliers. Conservative version of Revenue8Y_LTV_New_Group_LTV. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 30 | Revenue8Y_LTV_All_Conv_Old | money | YES | Legacy 8Y LTV prediction from pre-2023 methodology. Retained for historical comparison only; not recommended for new analyses. (Tier 2 — naming + data evidence) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Passthrough |
| GCID | Customer.CustomerStatic | GCID | Passthrough |
| NewMarketingRegion | DWH_dbo.Dim_Country | Region | Via Dictionary.MarketingRegion |
| FirstDepositDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | Passthrough |
| FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates | FirstNewFundedDate | EOMONTH() |
| Seniority | BI_DB_dbo.BI_DB_CIDFirstDates | FirstFundedMonth | Months to run date |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | Date-range JOIN |
| EquityTier | DWH_dbo.Fact_SnapshotEquity | RealizedEquity | Tier bucketing |
| MonthsSinceLastPosOpen | DWH positions data | last position date | Months elapsed |
| Current_ACC_Revenue | Revenue aggregation source | cumulative revenue | With seniority correction |
| LTV_1Y/3Y/8Y | BI_DB_LTV_Predictions / actuals | LTV columns | Hybrid predicted/actual |
| LTV_*_VolFix | BI_DB_LTV_Predictions | LTV_*_VolFix | With rolling avg smoothing |
| LTV_8Y_GroupLevel | BI_DB_LTV_Predictions | LTV_8Y_VolFix | Post-INSERT group AVG |
| Revenue8Y_LTV_* | Revenue8Y model (new 2023+) | — | Various blending/filtering |
| UpdateDate | ETL pipeline | — | SP run timestamp |

### 5.2 ETL Pipeline

```
BI_DB_CIDFirstDates (Seniority, FirstFundedMonth, FirstDepositDate)
BI_DB_CID_DailyCluster (ClusterDetail)
Fact_SnapshotEquity (EquityTier)
BI_DB_LTV_Predictions (LTV_1Y/3Y/8Y/VolFix)
Revenue8Y model (Revenue8Y_LTV_New variants)
  |-- SP_LTV_BI_Actual (Daily, SB_Daily, Priority 0 — full table replace) ---|
  v
BI_DB_dbo.BI_DB_LTV_BI_Actual (5.84M rows, HEAP, HASH(CID))
  |-- SP_D_LTV_BI_Actual_Snapshot (P20) → BI_DB_LTV_BI_Actual_Daily_Snapshot (4.54B rows)
  |-- SP_LTV_FromDB_ToBigQuery → LTV_FromDB_ToBigQuery (BigQuery export)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer.CustomerStatic (CID) | Customer reference |
| GCID | Customer.CustomerStatic (GCID) | Global customer reference |
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer demographics |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | Behavioral cluster source |
| Seniority/FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates | Customer lifecycle dates |
| LTV_1Y/3Y/8Y/VolFix | BI_DB_dbo.BI_DB_LTV_Predictions | Multiplier-model LTV source |

### 6.2 Referenced By

| Object | How Used |
|--------|---------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual_Daily_Snapshot | Daily timestamped archive — SP_D_LTV_BI_Actual_Snapshot reads current state |
| BI_DB_dbo.LTV_FromDB_ToBigQuery | BigQuery export — SP_LTV_FromDB_ToBigQuery reads for external analytics |
| (11 additional downstream BI_DB_dbo objects) | Various LTV-derived reports and models |

---

## 7. Sample Queries

### Top 10 LTV customers by blended 8Y prediction

```sql
SELECT TOP 10
    CID,
    NewMarketingRegion,
    ClusterDetail,
    EquityTier,
    Seniority,
    Revenue8Y_LTV_New_Group_LTV AS ltv_8y_blended,
    LTV_8Y_VolFix AS ltv_8y_vol_fixed
FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual]
WHERE Revenue8Y_LTV_New_Group_LTV > 0
ORDER BY Revenue8Y_LTV_New_Group_LTV DESC;
```

### Average LTV by region × cluster × equity tier

```sql
SELECT
    NewMarketingRegion,
    ClusterDetail,
    EquityTier,
    COUNT(*) AS customer_count,
    AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv_8y,
    SUM(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS total_ltv_8y
FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual]
WHERE Revenue8Y_LTV_New_Group_LTV > 0
GROUP BY NewMarketingRegion, ClusterDetail, EquityTier
ORDER BY avg_ltv_8y DESC;
```

### LTV distribution by cohort (first funded month, recent)

```sql
SELECT
    FirstFundedMonth,
    COUNT(*) AS cohort_size,
    AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv_8y,
    AVG(CAST(LTV_8Y_VolFix AS float)) AS avg_ltv_8y_volfix
FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual]
WHERE FirstFundedMonth >= '2024-01-01'
GROUP BY FirstFundedMonth
ORDER BY FirstFundedMonth;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP_LTV_BI_Actual author details unavailable. LTV model documentation available from sibling wikis: BI_DB_LTV_Predictions (multiplier model logic) and BI_DB_LTV_BI_Actual_Daily_Snapshot (LTV variant descriptions, authored Jan Iablunovskey 2023-09-07).

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Phases: 11/14*
*Tiers: 2 T1, 28 T2, 0 T3, 0 T4, 1 P (counted once for UpdateDate) | Elements: 30/30, Logic: 9/10, Data Evidence: 9/10*
*Object: BI_DB_dbo.BI_DB_LTV_BI_Actual | Type: Table | Production Source: BI_DB_LTV_Predictions + Revenue8Y model + segmentation inputs via SP_LTV_BI_Actual*


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

### Upstream `DWH_dbo.Dim_Country` — synapse
- **Resolved as**: `DWH_dbo.Dim_Country`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md`

# DWH_dbo.Dim_Country

> Master country dimension (251 rows) mapping every country/territory to geographic, regulatory, marketing, and risk attributes. One of the most-referenced dimension tables in the DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Country (primary) + etoro.Dictionary.MarketingRegion (region label) + Ext_Dim_Country (EU flags) + Ext_Dim_Country_Region_Desk (desk/CFKey) + ComplianceStateDB.Compliance.RegulationCountry (regulation) |
| **Refresh** | Daily (SP_Dictionaries_Country_DL_To_Synapse, full TRUNCATE+INSERT + 3 UPDATE passes) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (non-clustered PK on CountryID NOT ENFORCED) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Country` is one of the most heavily-referenced dimension tables in the DWH. It defines every country and territory the eToro platform recognizes (251 rows: 250 active countries + 1 "Not available" placeholder at CountryID=0). Each row provides geographic classification, regulatory risk attributes, marketing segmentation, and compliance data for users registered from that country.

When a customer registers, their CountryID determines: which regulatory entity governs them (via RegulationID), what AML/KYC scrutiny level applies (IsHighRiskCountry, RiskGroupID), what marketing desk handles them (Desk), and whether they can receive RAF bonuses (IsEligibleForRAFBonusCountry).

The ETL is multi-step: TRUNCATE+INSERT from etoro.Dictionary.Country (primary, joined to etoro.Dictionary.MarketingRegion for the Region label), then three UPDATE passes that patch in EU classification from Ext_Dim_Country, Desk/CFKey from Ext_Dim_Country_Region_Desk, and RegulationID from ComplianceStateDB.Compliance.RegulationCountry. Several columns present in the upstream Dictionary.Country source are dropped in DWH (IsSettlementRestricted, DefaultCurrencyID, LanguageID, IsActive, PhonePrefix, IsoCode).

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 High-Risk Country Flag (Computed)

**What**: IsHighRiskCountry is derived from RiskGroupID in the ETL, not passed through from source. AML-flagged countries trigger enhanced due diligence.

**Columns Involved**: `IsHighRiskCountry`, `RiskGroupID`

**Rules**:
- `CASE WHEN RiskGroupID IN (0, 4) THEN 0 ELSE 1 END` -> IsHighRiskCountry
- RiskGroupID=0 (None): 70 countries -> not high risk
- RiskGroupID=4 (Verified before deposit): 2 countries -> not high risk
- RiskGroupID=1 (High risk country): 100 countries -> high risk
- RiskGroupID=2 (High risk for new clients): 71 countries -> high risk
- RiskGroupID=3 (High risk FATF country): 8 countries -> high risk
- High-risk countries trigger enhanced document verification, manual review of first deposit, and reduced transaction monitoring thresholds

**Diagram**:
```
RiskGroupID -> IsHighRiskCountry
0 (None)                  -> 0  (70 countries)
4 (Verified bfr deposit)  -> 0  (2 countries)
1 (High risk)             -> 1  (100 countries)
2 (High risk new clients) -> 1  (71 countries)
3 (High risk FATF)        -> 1  (8 countries)
```

### 2.2 EU vs. European Country Classification

**What**: Two separate flags distinguish full EU membership from broader European geography.

**Columns Involved**: `EU`, `IsEuropeanCountry`

**Rules**:
- EU=1: 27 countries with full EU membership (legal/treaty member states)
- IsEuropeanCountry=1: 66 countries total (27 EU members + 39 other European countries)
- Source: Ext_Dim_Country (manual extension table), not from etoro.Dictionary.Country
- EU=1 always implies IsEuropeanCountry=1. IsEuropeanCountry=1 does NOT imply EU=1.

### 2.3 Region vs. MarketingRegion

**What**: DWH exposes two separate geographic segmentations. `Region` is marketing-driven; the source geographic `RegionID` is dropped.

**Columns Involved**: `Region`, `MarketingRegionID`, `MarketingRegionManualName`, `Desk`

**Rules**:
- `Region` is loaded from etoro.Dictionary.MarketingRegion.Name (y.Name AS Region in SP). It is the marketing region label.
- `MarketingRegionManualName` is a manual override from Ext_Dim_Country - may differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE).
- `Desk` is a sales/support desk assignment from Ext_Dim_Country_Region_Desk, joined via MarketingRegionID.
- The upstream Dictionary.Country source has a geographic `RegionID` pointing to Dictionary.Region - this is NOT loaded to DWH.
- 22 distinct Region values in DWH (South & Central America=40, Africa=38, ROW=38, French=23, etc.)

### 2.4 Dropped Source Columns (Compliance-Critical)

**What**: Several compliance and localization columns present in the upstream source are NOT loaded to DWH.

**Dropped from etoro.Dictionary.Country**:
- `IsSettlementRestricted`: 21 countries restricted to CFD-only trading (cannot hold REAL assets). Includes United States (SEC/FINRA). CRITICAL for compliance analysts.
- `DefaultCurrencyID`: Trading account default currency (USD/EUR/GBP/AUD/CAD/PLN).
- `LanguageID`: UI language default.
- `IsActive`: Whether country is active on platform.
- `PhonePrefix`: International dialing code.
- `IsoCode`: ISO 3166-1 numeric code.
- `RegionID`: Geographic region FK (DWH replaces with text Region label from MarketingRegion).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE (correct for a 251-row dimension - broadcast to all nodes avoids data movement on JOINs). HEAP means no sorted index. The non-clustered PK on CountryID is NOT ENFORCED - duplicates are theoretically possible but prevented by ETL TRUNCATE.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (251 rows). Z-ORDER on CountryID optional for join optimization.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode country for a customer | `JOIN DWH_dbo.Dim_Country d ON f.CountryID = d.CountryID` |
| Filter high-risk countries | `WHERE d.IsHighRiskCountry = 1` |
| Filter EU customers | `WHERE d.EU = 1` |
| Group by marketing region | `GROUP BY d.Region` |
| Find regulation for a country | `SELECT RegulationID FROM Dim_Country WHERE CountryID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON c.CountryID = d.CountryID | Decode customer country attributes |
| DWH_dbo.Fact_BillingDeposit | ON f.CountryID = d.CountryID | Country-level deposit analytics |
| DWH_dbo.Dim_CountryBin | ON c.CountryID = d.CountryID | BIN-to-country card mapping |
| DWH_dbo.V_Dim_Customer | ON v.CountryID = d.CountryID | Customer view with country decode |

### 3.4 Gotchas

- CountryID=0 ("Not available") is a real row - use `WHERE CountryID > 0` to exclude the placeholder in population-level queries.
- `IsHighRiskCountry` is RECOMPUTED from `RiskGroupID` by the ETL (not passthrough from source). If source IsHighRiskCountry changes but RiskGroupID stays the same, DWH will not reflect the change.
- `IsSettlementRestricted` is NOT in DWH. This critical compliance flag must be looked up in the source etoro.Dictionary.Country if needed.
- `Region` reflects `MarketingRegion.Name`, not the geographic `Dictionary.Region`. The two segmentations differ (e.g., Albania: geographic region=Europe, marketing Region=ROE).
- `DWHCountryID` always equals `CountryID` (redundant copy from SP: `x.CountryID AS DWHCountryID`). Never use both in GROUP BY.
- `StatusID` is hardcoded to 1 for all rows (including CountryID=0). No meaningful variation.
- `InsertDate` and `UpdateDate` are both set to GETDATE() on each daily reload - they reflect ETL run time, not original insert or data change time.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. (Tier 1 - Dictionary.Country upstream wiki) |
| 2 | Abbreviation | char(2) | NO | ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). Unique per row. Used in UI display, API parameters, and geolocation matching. Trimmed on use (char type has trailing spaces). (Tier 1 - Dictionary.Country upstream wiki) |
| 3 | LongAbbreviation | char(3) | NO | ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). Unique per row. Used in some international reporting standards and Compliance.GetCountryLongAbbreviation (WorldCheck KYC/AML integration). (Tier 1 - Dictionary.Country upstream wiki) |
| 4 | Name | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 5 | IsHighRiskCountry | tinyint | YES | AML/compliance risk flag. 0=standard risk, 1=high risk. RECOMPUTED by SP from RiskGroupID: `CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END`. 179 high-risk countries. Triggers enhanced due diligence and stricter transaction monitoring. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 6 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows by SP. Intended to indicate active status. In practice carries no variation. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | DWHCountryID | int | NO | Redundant copy of CountryID (set to `x.CountryID AS DWHCountryID` in SP). Always equals CountryID. Retained for legacy compatibility. Do not use both CountryID and DWHCountryID in the same GROUP BY. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily full reload. Reflects ETL run time, not when country data actually changed. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate) on each daily full reload. Not a true insert timestamp - both dates are refreshed on every reload due to TRUNCATE+INSERT. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) |
| 11 | EU | int | YES | Whether this country is a full EU member state. 1=EU member (27 countries), 0=non-EU. Source: Ext_Dim_Country manual extension table (left join - NULL if not in Ext_Dim_Country). Always 0 or 1 in practice. Distinct from IsEuropeanCountry. (Tier 3 - Ext_Dim_Country live data) |
| 12 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. (Tier 3 - Ext_Dim_Country_Region_Desk via SP) |
| 13 | RegulationID | int | YES | Regulatory entity ID governing users from this country. Loaded from ComplianceStateDB.Compliance.RegulationCountry via Ext_Dim_Country_Regulation staging. Left join - NULL if country not in compliance mapping. References the regulatory framework (e.g., CySEC, FCA, ASIC). (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse via ComplianceStateDB) |
| 14 | CFKey | int | YES | Clearing/settlement framework key for this country's marketing region. Loaded from Ext_Dim_Country_Region_Desk.CFKey via MarketingRegionID join. Exact business meaning unclear - likely maps to a clearing firm or settlement category. (Tier 3 - Ext_Dim_Country_Region_Desk live data) |
| 15 | MarketingRegionID | int | YES | FK to etoro.Dictionary.MarketingRegion. Marketing segment ID grouping countries by marketing strategy. Distinct from geographic RegionID (which is dropped in DWH). 22 distinct values matching the 22 Region labels. (Tier 1 - Dictionary.Country upstream wiki) |
| 16 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. (Tier 1 - Dictionary.Country upstream wiki) |
| 17 | IsEligibleForRAFBonusCountry | int | YES | Whether users from this country can participate in the Refer-A-Friend bonus program. Source: CAST(etoro.Dictionary.Country.IsEligibleForRAFBonusCountry AS int) - type cast from bit to int. 1=eligible (most countries), 0=ineligible (regulatory/fraud restrictions). (Tier 1 - Dictionary.Country upstream wiki) |
| 18 | IsEuropeanCountry | int | YES | Whether this country is geographically European (broader than EU membership). 1=European (66 countries total: 27 EU + 39 others), 0=non-European. Source: Ext_Dim_Country manual extension table. Always >= EU flag. (Tier 3 - Ext_Dim_Country live data) |
| 19 | MarketingRegionManualName | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 - Ext_Dim_Country live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CountryID | etoro.Dictionary.Country | CountryID | passthrough |
| Abbreviation | etoro.Dictionary.Country | Abbreviation | passthrough (nvarchar(max) -> char(2)) |
| LongAbbreviation | etoro.Dictionary.Country | LongAbbreviation | passthrough (nvarchar(max) -> char(3)) |
| Name | etoro.Dictionary.Country | Name | passthrough |
| IsHighRiskCountry | etoro.Dictionary.Country | RiskGroupID | computed: CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END |
| Region | etoro.Dictionary.MarketingRegion | Name | rename (y.Name AS Region via JOIN on MarketingRegionID) |
| StatusID | - | - | ETL-computed (hardcoded constant 1) |
| DWHCountryID | etoro.Dictionary.Country | CountryID | copy (x.CountryID AS DWHCountryID, always = CountryID) |
| UpdateDate | - | - | ETL-computed (GETDATE()) |
| InsertDate | - | - | ETL-computed (GETDATE()) |
| EU | DWH_dbo.Ext_Dim_Country | EU | UPDATE pass (LEFT JOIN on CountryID) |
| Desk | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| RegulationID | ComplianceStateDB.Compliance.RegulationCountry | RegulationID | UPDATE pass via Ext_Dim_Country_Regulation staging |
| CFKey | DWH_dbo.Ext_Dim_Country_Region_Desk | CFKey | UPDATE pass (LEFT JOIN on MarketingRegionID=RegionID) |
| MarketingRegionID | etoro.Dictionary.Country | MarketingRegionID | passthrough |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | passthrough |
| IsEligibleForRAFBonusCountry | etoro.Dictionary.Country | IsEligibleForRAFBonusCountry | type cast (CAST(bit AS int)) |
| IsEuropeanCountry | DWH_dbo.Ext_Dim_Country | IsEuropeanCountry | UPDATE pass (LEFT JOIN on CountryID) |
| MarketingRegionManualName | DWH_dbo.Ext_Dim_Country | MarketingRegionManualName | UPDATE pass (LEFT JOIN on CountryID) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10).

### 5.2 ETL Pipeline

```
etoro.Dictionary.Country (x)
  -> [Generic Pipeline or direct load]
  -> DWH_staging.etoro_Dictionary_Country
  -> (JOIN) DWH_staging.etoro_Dictionary_MarketingRegion
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_Country (initial population: 19 cols partially loaded)
  -> UPDATE from DWH_dbo.Ext_Dim_Country (EU, IsEuropeanCountry, MarketingRegionManualName)
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Region_Desk (CFKey, Desk via MarketingRegionID)
  -> TRUNCATE+INSERT DWH_dbo.Ext_Dim_Country_Regulation from DWH_staging.ComplianceStateDB_Compliance_RegulationCountry
  -> UPDATE from DWH_dbo.Ext_Dim_Country_Regulation (RegulationID)
  -> DWH_dbo.Dim_Country (fully loaded)
```

Note: The same SP also loads Dim_CountryIPAnonymous in the same transaction.

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Country | Master country reference (251 rows). 16-column source, DWH drops 8 columns. |
| Source | etoro.Dictionary.MarketingRegion | Marketing region labels. Provides Region text and MarketingRegionID. |
| Staging | DWH_staging.etoro_Dictionary_Country | Raw staging: 16 cols, HEAP ROUND_ROBIN. |
| ETL | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse | TRUNCATE + INSERT. Computes IsHighRiskCountry from RiskGroupID. Joins MarketingRegion. Hardcodes StatusID=1. Sets GETDATE() for UpdateDate/InsertDate. |
| Patch 1 | DWH_dbo.Ext_Dim_Country | Manual extension table: EU=1/0, IsEuropeanCountry=1/0, MarketingRegionManualName. LEFT JOIN on CountryID. |
| Patch 2 | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk and CFKey lookup by MarketingRegionID. LEFT JOIN on MarketingRegionID=RegionID. |
| Patch 3 | DWH_dbo.Ext_Dim_Country_Regulation | Regulation staging loaded from ComplianceStateDB.Compliance.RegulationCountry. Then LEFT JOIN on CountryID. |
| Target | DWH_dbo.Dim_Country | Final DWH dimension (251 rows). |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MarketingRegionID | etoro.Dictionary.MarketingRegion | Marketing region segment. Implicit FK (not enforced in Synapse). |
| RiskGroupID | etoro.Dictionary.CountryRiskGroup | Country risk classification. Implicit FK (not enforced in Synapse). |
| RegulationID | ComplianceStateDB (Regulation) | Regulatory entity governing country users. Sourced from ComplianceStateDB. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | CountryID | Customer view JOINs to Dim_Country for country attributes. |
| DWH_dbo.Dim_CountryIP | CountryID | IP-to-country lookup table references Dim_Country via Abbreviation join. |
| DWH_dbo.Dim_CountryIPAnonymous | CountryID | Anonymous proxy IP table; CountryID set via Abbreviation-to-CountryID lookup against Dim_Country. |
| DWH_dbo.SP_Fact_BillingDeposit | CountryID | Billing deposit facts reference Dim_Country for country-level analytics. |
| BI_DB_dbo.SP_BI_DB_LTV_Conversions_Multipliers_Table | CountryID | LTV modeling references country dimension. |
| BI_DB_dbo.SP_Group_LTV_Table | CountryID | Group LTV analytics references country dimension. |

---

## 7. Sample Queries

### 7.1 Decode customer country
```sql
SELECT c.CustomerID, d.Name AS Country, d.Region, d.IsHighRiskCountry
FROM [DWH_dbo].[Dim_Customer] c
JOIN [DWH_dbo].[Dim_Country] d ON c.CountryID = d.CountryID
WHERE d.IsHighRiskCountry = 1;
```

### 7.2 Countries by EU membership
```sql
SELECT CountryID, Name, Abbreviation, EU, IsEuropeanCountry, Region
FROM [DWH_dbo].[Dim_Country]
WHERE EU = 1
ORDER BY Name;
```

### 7.3 Risk group distribution
```sql
SELECT RiskGroupID, IsHighRiskCountry, COUNT(*) AS CountryCount
FROM [DWH_dbo].[Dim_Country]
WHERE CountryID > 0
GROUP BY RiskGroupID, IsHighRiskCountry
ORDER BY RiskGroupID;
```

### 7.4 RAF-ineligible countries by region
```sql
SELECT Region, Name, Abbreviation
FROM [DWH_dbo].[Dim_Country]
WHERE IsEligibleForRAFBonusCountry = 0 AND CountryID > 0
ORDER BY Region, Name;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` (quality 9.4/10, 16 VERIFIED columns).

---

*Generated: 2026-03-19 | Quality: 8.8/10 (4 stars) | Phases: 9/14 (full pipeline, no Atlassian)*
*Tiers: 6 T1, 8 T2, 5 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Country | Type: Table | Production Source: etoro.Dictionary.Country + etoro.Dictionary.MarketingRegion + Ext_Dim_Country + ComplianceStateDB*


### Upstream `BI_DB_dbo.BI_DB_CIDFirstDates` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CIDFirstDates`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`

# BI_DB_dbo.BI_DB_CIDFirstDates

> 46.7M-row customer lifecycle milestone table tracking every eToro customer's first and last occurrence of key platform events -- registration, deposit, login, trade, copy, contact, verification, and funded status -- serving as the central customer-level dimension for BI reporting, CRM enrichment, and lifecycle segmentation. Updated daily by SP_CIDFirstDates via incremental INSERT (new customers) + UPDATE (changed attributes and new events).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Dimension -- customer lifecycle milestones) |
| **Row Count** | ~46.7M (one row per valid customer) |
| **Date Range** | Registrations from 2007-08-29 to present |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (core), Fact_CustomerAction (events), Fact_BillingDeposit (deposits), V_Liabilities (equity), Dim_Mirror (copy), BI_DB_UsageTracking_SF (CRM contacts), Fact_SnapshotCustomer (verification), Function_Population_Funded/First_Time_Funded (funded status), BI_DB_DDR_Customer_Daily_Status (last funded), BI_DB_AppFlyer_Reports (mobile install) |
| **Refresh** | Daily incremental -- INSERT new valid customers + multi-pass UPDATE for changed attributes and new events (SP_CIDFirstDates) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_CIDFirstDates` is the BI layer's master customer lifecycle dimension. It maintains one row per valid customer (IsValidCustomer=1 in Dim_Customer, i.e., not PlayerLevelID=4, not LabelID 26/30, not CountryID=250), capturing:

- **Identity & demographics**: CID, GCID, UserName, Gender, BirthDate, Email, Country, CountryID, State, Language, CommunicationLanguage
- **Acquisition**: Channel, SubChannel, SerialID (AffiliateID), LabelName, FunnelName, FunnelFromName, BannerID, SubAffiliateID, DownloadID, ReferralID
- **Account status**: Club (PlayerLevel name), Blocked flag, Verified (VerificationLevel), RegulationID, DesignatedRegulationID, Manager, PrivacyPolicyID
- **Deposit milestones**: FirstDepositAttempt/Amount/Processor/FundingType, FirstDeposit/LastDeposit dates/amounts/funding types, Credit, RealizedEquity
- **Trading milestones**: FirstPosOpenDate, FirstMenualPosOpenDate, FirstMirrorPosOpenDate, FirstMirrorRegistrationDate, FirstStocksOpenDate, and their Last counterparts
- **Login milestones**: FirstLoggedIn, LastLoggedIn, FirstCashierLogin, LastCashierLogin
- **Social/copy milestones**: FirstTimeBeingCopied, LastTimeBeingCopied
- **Contact milestones**: FirstContactDate, LastContactDate, LastContactDate_ByPhone (from Salesforce CRM)
- **Verification milestones**: VerificationLevel1/2/3Date, EmailVerifiedDate, EvMatchStatusDate, PhoneVerifiedDate
- **Funded status**: IsFundedNew, FirstNewFundedDate, LastNewFundedDate
- **Cashout milestones**: FirstCashoutDate, LastCashoutDate
- **Other**: FirstInstallDate (mobile), FirstCampaignID/Date/Amount, KycModeID, ProfessionalApplicationDate, IsAirDropBefore, FTDIsLessThanAWeek

The table is populated from 15+ sources via SP_CIDFirstDates (Author: Adi Ferber, 2016-03-01). The SP first builds a full valid-customer set from Dim_Customer, inserts new customers with demographic/acquisition attributes, then runs ~20 multi-pass UPDATEs to populate first/last event dates from Fact_CustomerAction, deposit details from Fact_BillingDeposit, equity from V_Liabilities, copy data from Dim_Mirror, CRM contacts from BI_DB_UsageTracking_SF, verification dates from Fact_SnapshotCustomer, and funded status from the Function_Population_Funded/First_Time_Funded TVFs.

**Important**: Many columns are **deprecated** and no longer updated. Columns like KYC, DocsOK, Bankruptcy, PremiumAccount, Evangelist, SuitabilityTestCompletedAt, PassedSuitabilityTest, PEPCreatedTime, PEPStatusUpdatedDate, isPassedPEP, PEPStatusID were explicitly nullified on 2022-02-22. Demo-related columns (FirstDemoLoggedIn, FirstDemoPosOpenDate, etc.) were disabled in 2017. Social/engagement columns were disabled when source tables stopped updating. RiskGroup and DepositGroup were disabled 2023-05-09. These columns remain in the DDL but carry NULL/0 for all rows.

Invalid customers (IsValidCustomer=0) are actively DELETED from this table each run.

---

## 2. Business Logic

### 2.1 Valid Customer Population

**What**: Only valid customers are tracked. Invalid customers are deleted each run.

**Columns Involved**: CID, all columns

**Rules**:
- Valid = IsValidCustomer=1 in Dim_Customer (PlayerLevelID != 4, LabelID NOT IN (26,30), CountryID != 250)
- Invalid customers are identified via `#internal` temp table and DELETEd from BI_DB_CIDFirstDates
- New valid customers not yet in the table are INSERTed with demographic/acquisition attributes
- Changed attributes (Club, Language, Email, Blocked, etc.) trigger UPDATEs via change detection using COLLATE Latin1_General_BIN comparison

### 2.2 Blocked Flag Derivation

**What**: Binary flag indicating whether the customer account is restricted.

**Columns Involved**: `Blocked`

**Rules**:
- `CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0 END`
- PlayerStatusID values: 2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked

### 2.3 Registration Date Logic

**What**: The `registered` column takes the earlier of demo and real registration dates.

**Columns Involved**: `registered`

**Rules**:
- `CASE WHEN RegisteredDemo < RegisteredReal THEN RegisteredDemo ELSE RegisteredReal END`
- This captures the customer's first interaction with the platform regardless of account type

### 2.4 First/Last Event Pattern

**What**: Most first/last date columns follow a consistent pattern from Fact_CustomerAction.

**Columns Involved**: FirstLoggedIn, LastLoggedIn, FirstPosOpenDate, LastPosOpenDate, FirstCashierLogin, LastCashierLogin, FirstCashoutDate, LastCashoutDate, FirstMirrorRegistrationDate, LastMirrorRegistrationDate, FirstMenualPosOpenDate, LastMenualPosOpenDate, FirstMirrorPosOpenDate, LastMirrorPosOpenDate, FirstStocksOpenDate

**Rules**:
- SP filters Fact_CustomerAction by DateID range (today only) and ActionTypeID
- First dates: UPDATE only WHERE current value IS NULL or > @date (never overwrite an earlier first)
- Last dates: UPDATE with MAX(Occurred) -- always overwrite with latest
- ActionTypeID mapping: 1=ManualPositionOpen, 2=CopyPositionOpen, 7=Deposit, 8=Cashout, 14=Login, 15=AccountToMirror, 17=RegisterMirror, 21=PublishPost, 29=CashierLogin, 34=OpenStockOrder

### 2.5 Deposit Details (First and Last)

**What**: First and last deposit details including processor, funding type, amount, and date.

**Columns Involved**: FirstDepositDate, FirstDepositAmount, FirstDepositProcessor, FirstDepositFundingType, LastDepositDate, LastDepositAmount, LastDepositFundingType

**Rules**:
- FirstDeposit: Sourced via Dim_Customer.FTDTransactionID joined to Fact_BillingDeposit (IsFTD=1), enriched with Dim_FundingType.Name and Dim_BillingDepot.Name
- LastDeposit: From today's Fact_CustomerAction ActionTypeID=7 rows joined back to Fact_BillingDeposit
- FirstDepositAttempt: From Fact_FirstCustomerAction WHERE ActionTypeID=27 (deposit attempt)
- Amount is in USD (Amount * ExchangeRate for last deposit)

### 2.6 Credit and Equity Snapshot

**What**: Daily credit and realized equity from V_Liabilities, updated only for yesterday's date.

**Columns Involved**: `Credit`, `RealizedEquity`

**Rules**:
- Only updated when `@date = @yesterday` (i.e., running for the most recent day)
- `Credit = ISNULL(V_Liabilities.Credit, 0)`
- `RealizedEquity = ISNULL(V_Liabilities.RealizedEquity, 0)`

### 2.7 Funded Status (IsFundedNew)

**What**: Whether the customer meets all four funded criteria today.

**Columns Involved**: `IsFundedNew`, `FirstNewFundedDate`, `LastNewFundedDate`

**Rules**:
- `IsFundedNew`: 1 if customer is in the result set of Function_Population_Funded(@dateINT), else 0. The function requires: (1) past first-funded date, (2) positive combined equity across TP/eMoney/Options
- `FirstNewFundedDate`: From Function_Population_First_Time_Funded(). Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Only set once (WHERE NULL)
- `LastNewFundedDate`: COALESCE of MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1 and current Function_Population_Funded result

### 2.8 FTD Speed Flag

**What**: Whether the customer's first deposit was within 7 days of registration.

**Columns Involved**: `FTDIsLessThanAWeek`

**Rules**:
- `CASE WHEN DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0 THEN 1 ELSE 0 END`
- Only computed for customers registered in the last 10 days

### 2.9 Copy Milestones

**What**: First and last time another customer started copying this customer's trades.

**Columns Involved**: `FirstTimeBeingCopied`, `LastTimeBeingCopied`

**Rules**:
- Source: Dim_Mirror WHERE OpenOccurred in today's date range, grouped by ParentCID
- First: MIN(OpenOccurred), only if current value is NULL or > @date
- Last: MAX(OpenOccurred), always updated

### 2.10 Verification Dates

**What**: First date each verification level was reached, plus email and phone verification dates.

**Columns Involved**: `VerificationLevel1Date`, `VerificationLevel2Date`, `VerificationLevel3Date`, `EmailVerifiedDate`, `EvMatchStatusDate`, `PhoneVerifiedDate`

**Rules**:
- Sourced from Fact_SnapshotCustomer joined to Dim_Range (FromDateID)
- VerificationLevelNDate = MIN(FromDateID) WHERE VerificationLevelID = N
- Backfill logic: if Level 3 date is set but Level 2 is NULL, Level 2 is set to Level 3 date (cascade)
- EmailVerifiedDate = MIN(FromDateID) WHERE IsEmailVerified = 1
- EvMatchStatusDate = MIN(FromDateID) WHERE EvMatchStatus = 2
- PhoneVerifiedDate from BackOffice history WHERE PhoneVerifiedID IN (1,2)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CID) with CLUSTERED INDEX on CID. Single-customer lookups are optimal (data-local). Cross-customer aggregations by Channel, Country, or Region work well with the columnstore segment elimination on the clustered index. 46.7M rows -- manageable for full scans but prefer filtered queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer lifecycle summary | `SELECT * WHERE CID = @cid` |
| FTD funnel (registered → first deposit) | `SELECT Channel, COUNT(*) WHERE FirstDepositDate IS NOT NULL GROUP BY Channel` |
| Time-to-first-deposit | `DATEDIFF(DAY, registered, FirstDepositDate) WHERE FirstDepositDate > '1900-01-01'` |
| Currently funded customers | `WHERE IsFundedNew = 1` |
| Active copiers (Popular Investors) | `WHERE FirstTimeBeingCopied IS NOT NULL` |
| Recently contacted customers | `WHERE LastContactDate >= DATEADD(DAY, -7, GETDATE())` |
| Verification funnel | `COUNT by VerificationLevel3Date IS NOT NULL vs IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Extended customer attributes not in this table |
| DWH_dbo.Dim_Country | ON CountryID | Country details beyond Name/Region |
| DWH_dbo.Dim_Regulation | ON RegulationID | Regulation name |
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | ON CID = RealCID AND DateID | Daily status for a specific date |

### 3.4 Gotchas

- **46.7M rows, NOT all customers**: Only IsValidCustomer=1 customers. Invalid customers (PlayerLevelID=4, LabelID 26/30, CountryID=250) are actively deleted each run
- **~40 deprecated columns**: Many columns carry NULL/0 for all rows. See the Elements table for individual deprecation notes. Do not use deprecated columns for analytics
- **FirstDepositDate sentinel**: `1900-01-01` means no deposit, not a historical deposit. Filter `WHERE FirstDepositDate > '1900-01-01'` for depositors
- **FirstLeadDate sentinel**: Set to `1900-01-01` universally -- deprecated
- **Credit/RealizedEquity**: Only updated when SP runs for yesterday's date. Not a real-time snapshot -- reflects previous day's end-of-day values
- **registered is MIN(demo, real)**: Not the real-account registration date. For real-only registration, use Dim_Customer.RegisteredReal
- **Channel defaults to 'Direct'**: ISNULL(Channel, 'Direct') is applied in the SP. Customers without an affiliate mapping show 'Direct'
- **Manager is concatenated**: `FirstName + ' ' + LastName` from Dim_Manager. NULL if no manager assigned
- **IsFundedNew can toggle**: A customer can be funded one day and not the next (if equity drops to 0). It reflects the CURRENT day's funded status, not a permanent flag
- **FirstNewFundedDate is permanent**: Once set, it is never overwritten (WHERE NULL guard). It represents the graduation date, not a daily status

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 -- upstream wiki verbatim | (Tier 1 -- {source}) |
| Tier 2 -- SP ETL code | (Tier 2 -- SP_CIDFirstDates) |
| Tier 3 -- deprecated/not populated | (Tier 3 -- deprecated) |

### 4.1 Customer Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -- Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -- Customer.CustomerStatic) |
| 3 | OriginalCID | int | YES | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 -- Customer.CustomerStatic) |
| 4 | UserName | varchar(500) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 -- Customer.CustomerStatic) |

### 4.2 Acquisition & Classification

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 5 | Club | varchar(500) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -- Dictionary.PlayerLevel) |
| 6 | SerialID | int | YES | Affiliate (partner) ID under which the customer was acquired (renamed from AffiliateID in Dim_Customer). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 -- Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' -> 'Affiliate', AffiliateID IN (56662,56663) -> 'Direct'. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.Channel. ISNULL default 'Direct' for customers without affiliate mapping. (Tier 2 -- SP_CIDFirstDates via Dim_Channel) |
| 8 | SubChannel | nvarchar(500) | NO | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Derived via parallel CASE expression alongside SubChannelID. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.SubChannel. ISNULL default 'Direct'. (Tier 2 -- SP_CIDFirstDates via Dim_Channel) |
| 9 | LabelName | varchar(500) | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). Dim-lookup from Dim_Label.Name via LabelID. (Tier 1 -- Dictionary.Label) |
| 10 | Country | varchar(500) | YES | Full country name in English. Dim-lookup from Dim_Country.Name via CountryID. (Tier 1 -- Dictionary.Country) |
| 11 | Language | char(500) | YES | Platform language display name. Dim-lookup from Dim_Language.Name via LanguageID. Fixed-width char(500) -- trailing spaces expected. (Tier 1 -- Dictionary.Language) |
| 12 | Region | nvarchar(500) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Dim-lookup from Dim_Country.Region via CountryID. (Tier 1 -- Dictionary.MarketingRegion) |
| 13 | PotentialDesk | varchar(8000) | YES | Sales/support desk assignment for this country. From Dim_Country.Desk via CountryID. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping. (Tier 1 -- Ext_Dim_Country_Region_Desk) |
| 14 | Email | varchar(500) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. Dynamically masked with default(). (Tier 1 -- Customer.CustomerStatic) |
| 15 | FunnelName | varchar(500) | YES | Registration funnel name. Dim-lookup from Dim_Funnel.Name via FunnelID. Tracks which user journey/funnel variant the customer came through. (Tier 1 -- Dictionary.Funnel) |
| 16 | DownloadID | int | YES | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 -- Customer.CustomerStatic) |
| 17 | FunnelFromName | varchar(500) | YES | Source funnel variant name. Dim-lookup from Dim_Funnel.Name via FunnelFromID. (Tier 1 -- Dictionary.Funnel) |
| 18 | BannerID | int | YES | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 -- Customer.CustomerStatic) |
| 19 | SubAffiliateID | nvarchar(1024) | YES | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. Mapped from Dim_Customer.SubSerialID. (Tier 1 -- Customer.CustomerStatic) |
| 20 | ReferralID | int | YES | Referral CID -- the customer who referred this customer (for RAF program tracking). (Tier 1 -- Customer.CustomerStatic) |

### 4.3 Account Status & Demographics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | Blocked | int | YES | Account block flag. ETL-computed: 1 when PlayerStatusID IN (2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked), else 0. (Tier 2 -- SP_CIDFirstDates) |
| 22 | Verified | int | YES | KYC verification level ID. 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Dim-lookup from Dim_VerificationLevel.ID via VerificationLevelID. (Tier 1 -- Dictionary.VerificationLevel) |
| 23 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). CHECK constraint enforces these three values only. (Tier 1 -- Customer.CustomerStatic) |
| 24 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 -- Customer.CustomerStatic) |
| 25 | BirthDate | datetime | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 -- Customer.CustomerStatic) |
| 26 | CommunicationLanguage | varchar(500) | YES | Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language). (Tier 1 -- Dictionary.Language) |
| 27 | Manager | nvarchar(500) | YES | Assigned account manager full name. ETL-computed: Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via AccountManagerID. NULL if no manager assigned. (Tier 2 -- SP_CIDFirstDates) |
| 28 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. (Tier 1 -- BackOffice.Customer) |
| 29 | DesignatedRegulationID | int | YES | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 -- BackOffice.Customer) |
| 30 | PrivacyPolicyID | tinyint | YES | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 -- Customer.CustomerStatic) |
| 31 | IP | bigint | YES | Registration IP address as numeric value. Dynamically masked with default(). (Tier 1 -- Customer.CustomerStatic) |
| 32 | State | varchar(100) | YES | Full human-readable geographic name of the region -- state, province, or territory. Sourced from Dictionary.RegionName.Name. Dim-lookup from Dim_State_and_Province.Name via Dim_Customer.RegionID = RegionByIP_ID. NULL if region not in the 181-row Dim_State_and_Province table. (Tier 1 -- Dictionary.RegionName) |
| 33 | NewMarketingRegion | varchar(100) | YES | Manual override name for the marketing region. From Dim_Country.MarketingRegionManualName via CountryID. May differ from Region (e.g., Albania: Region=ROE, NewMarketingRegion=CEE). (Tier 1 -- Ext_Dim_Country) |

### 4.4 Registration & Login Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | registered | datetime | NO | Earliest registration date across demo and real accounts. ETL-computed: MIN(RegisteredDemo, RegisteredReal). Not the real-account-only date. (Tier 2 -- SP_CIDFirstDates) |
| 35 | FirstLoggedIn | datetime | YES | First platform login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -- SP_CIDFirstDates) |
| 36 | LastLoggedIn | datetime | YES | Most recent platform login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -- SP_CIDFirstDates) |
| 37 | FirstCashierLogin | datetime | YES | First cashier/billing login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -- SP_CIDFirstDates) |
| 38 | LastCashierLogin | datetime | YES | Most recent cashier login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -- SP_CIDFirstDates) |

### 4.5 Deposit Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 39 | FirstDepositAttempt | datetime | YES | Timestamp of the customer's first deposit attempt (whether successful or not). From Fact_FirstCustomerAction WHERE ActionTypeID=27. (Tier 2 -- SP_CIDFirstDates) |
| 40 | FirstDepositAttemptAmount | numeric(36,12) | YES | Amount of the first deposit attempt in USD. (Tier 2 -- SP_CIDFirstDates) |
| 41 | FirstDepositAttemptProcessor | varchar(500) | YES | Payment processor name for the first deposit attempt. Dim-lookup from Dim_BillingDepot.Name via DepotID. (Tier 2 -- SP_CIDFirstDates) |
| 42 | FirstDepositAttemptFundingType | varchar(500) | YES | Payment method name for the first deposit attempt. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 43 | FirstDepositDate | datetime | YES | Date of first successful deposit. From Dim_Customer.FirstDepositDate via FTDTransactionID join to Fact_BillingDeposit. Sentinel 1900-01-01 = no deposit. (Tier 2 -- SP_CIDFirstDates) |
| 44 | FirstDepositProcessor | varchar(500) | YES | Payment processor name for the first successful deposit. Dim-lookup from Dim_BillingDepot.Name. (Tier 2 -- SP_CIDFirstDates) |
| 45 | FirstDepositFundingType | varchar(500) | YES | Payment method name for the first successful deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 46 | FirstDepositAmount | money | YES | Amount of first deposit in USD. Default 0. From Dim_Customer.FirstDepositAmount. (Tier 2 -- SP_CIDFirstDates) |
| 47 | Credit | money | YES | Customer credit balance (promotional/bonus credit). Daily snapshot from V_Liabilities.Credit. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
| 48 | RealizedEquity | money | YES | Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |
| 49 | LastDepositDate | datetime | YES | Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. (Tier 2 -- SP_CIDFirstDates) |
| 50 | LastDepositAmount | money | YES | Most recent deposit amount in USD (Amount * ExchangeRate). (Tier 2 -- SP_CIDFirstDates) |
| 51 | LastDepositFundingType | varchar(500) | YES | Payment method name for the most recent deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -- SP_CIDFirstDates) |
| 52 | FirstDepositAmountExtended | money | YES | Not populated by current SP. Deprecated. (Tier 3 -- deprecated) |

### 4.6 Trading Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 53 | FirstPosOpenDate | datetime | YES | First position open timestamp (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) |
| 54 | LastPosOpenDate | datetime | YES | Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -- SP_CIDFirstDates) |
| 55 | FirstMenualPosOpenDate | datetime | YES | First manual (non-copy) position open timestamp. MIN(Occurred) WHERE ActionTypeID=1. Note: column name has typo 'Menual' (not 'Manual'). (Tier 2 -- SP_CIDFirstDates) |
| 56 | LastMenualPosOpenDate | datetime | YES | Most recent manual position open timestamp. MAX(Occurred) WHERE ActionTypeID=1. (Tier 2 -- SP_CIDFirstDates) |
| 57 | FirstMirrorPosOpenDate | datetime | YES | First copy-trade position open timestamp. MIN(Occurred) WHERE ActionTypeID=2. (Tier 2 -- SP_CIDFirstDates) |
| 58 | LastMirrorPosOpenDate | datetime | YES | Most recent copy-trade position open. MAX(Occurred) WHERE ActionTypeID=2. (Tier 2 -- SP_CIDFirstDates) |
| 59 | FirstMirrorRegistrationDate | datetime | YES | First copy-trade mirror registration timestamp. MIN(Occurred) WHERE ActionTypeID=17. (Tier 2 -- SP_CIDFirstDates) |
| 60 | LastMirrorRegistrationDate | datetime | YES | Most recent copy-trade mirror registration. MAX(Occurred) WHERE ActionTypeID=17. (Tier 2 -- SP_CIDFirstDates) |
| 61 | FirstStocksOpenDate | datetime | YES | First stock order open timestamp. MIN(Occurred) WHERE ActionTypeID=34. (Tier 2 -- SP_CIDFirstDates) |

### 4.7 Cashout Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 62 | FirstCashoutDate | datetime | YES | First withdrawal timestamp. MIN(Occurred) WHERE ActionTypeID=8. (Tier 2 -- SP_CIDFirstDates) |
| 63 | LastCashoutDate | datetime | YES | Most recent withdrawal timestamp. MAX(Occurred) WHERE ActionTypeID=8. (Tier 2 -- SP_CIDFirstDates) |

### 4.8 Copy & Social Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 64 | FirstTimeBeingCopied | datetime | YES | First time another customer started copying this customer's trades. MIN(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -- SP_CIDFirstDates) |
| 65 | LastTimeBeingCopied | datetime | YES | Most recent time another customer started copying this customer. MAX(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -- SP_CIDFirstDates) |

### 4.9 Contact Milestones (Salesforce CRM)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | LastContactDate | datetime | YES | Most recent successful contact date. MAX(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 -- SP_CIDFirstDates) |
| 67 | LastContactDate_ByPhone | datetime | YES | Most recent successful phone contact. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. Dynamically masked. (Tier 2 -- SP_CIDFirstDates) |
| 68 | FirstContactDate | datetime | YES | First successful contact date. MIN(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN successful contacts. (Tier 2 -- SP_CIDFirstDates) |
| 69 | FirstContactDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |
| 70 | LastContactAttemptDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |
| 71 | LastContactAttemptDate | datetime | YES | Not updated by current SP. (Tier 3 -- deprecated) |
| 72 | FirstContactAttemptDate | datetime | YES | Not updated by current SP. (Tier 3 -- deprecated) |
| 73 | FirstContactAttemptDate_ByPhone | datetime | YES | Not updated by current SP. Dynamically masked. (Tier 3 -- deprecated) |

### 4.10 Verification & Compliance Milestones

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 74 | VerificationLevel1Date | datetime | YES | Date customer first reached KYC verification level 1 (basic). From Fact_SnapshotCustomer + Dim_Range: MIN(FromDateID) WHERE VerificationLevelID=1. Backfilled from Level 2/3 dates if missing. (Tier 2 -- SP_CIDFirstDates) |
| 75 | VerificationLevel2Date | datetime | YES | Date customer first reached KYC verification level 2 (intermediate). MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from Level 3 date if missing. (Tier 2 -- SP_CIDFirstDates) |
| 76 | VerificationLevel3Date | datetime | YES | Date customer first reached KYC verification level 3 (full KYC). MIN(FromDateID) WHERE VerificationLevelID=3. (Tier 2 -- SP_CIDFirstDates) |
| 77 | EmailVerifiedDate | date | YES | Date customer verified their email address. MIN(FromDateID) from Fact_SnapshotCustomer WHERE IsEmailVerified=1. (Tier 2 -- SP_CIDFirstDates) |
| 78 | EvMatchStatusDate | datetime | YES | Date electronic verification matched (EvMatchStatus=2). MIN(FromDateID) from Fact_SnapshotCustomer. (Tier 2 -- SP_CIDFirstDates) |
| 79 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 -- BackOffice.Customer) |
| 80 | PhoneVerifiedDate | datetime | YES | Date phone number was verified. MIN(ValidFrom) from BackOffice history WHERE PhoneVerifiedID IN (1=AutomaticallyVerified, 2=ManuallyVerified). (Tier 2 -- SP_CIDFirstDates) |
| 81 | KycModeID | int | YES | KYC workflow mode from ComplianceStateDB.Compliance.CustomerKycMode. Updated via GCID join. (Tier 2 -- SP_CIDFirstDates) |
| 82 | ProfessionalApplicationDate | date | YES | Date the customer applied for MiFID II professional categorization. From ComplianceStateDB.Compliance.CustomerProfessionalQuesti

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md`

# BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData

> Monthly per-depositor customer panel — the broadest monthly CRM fact table in BI_DB_dbo. 189 columns covering registration, trading activity, revenue, PnL, equity, copy trading, lifetime accumulators, life-stage classification, and LTV predictions. One row per depositor (IsFunded) per calendar month. 353.8M rows total; 5.87M distinct CIDs; date range 2007-08 to present (oldest data in BI_DB_dbo).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL (see Section 4) |
| **Refresh** | Daily — DELETE WHERE ActiveDate = @BeginOfMonth + INSERT, then 4× POST-INSERT UPDATEs (SP_CID_MonthlyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (ActiveDate ASC, CID ASC) |
| **Row Count** | ~353.8M total; ~5.87M per month-slice (April 2026) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CID_MonthlyPanel_FullData` is the primary **monthly CRM analytics panel** for all eToro depositors — the widest monthly customer table in BI_DB_dbo. For each customer who is classified as "funded" (IsFunded), it provides a full monthly snapshot of their trading activity, financial position, revenue contribution, lifecycle stage, and accumulated lifetime totals.

The table serves as the central input for:
- **CRM and retention analytics**: Club tier distribution, life-stage transitions (EOM_LSD), churn (IsChurn_ThisM) and win-back (IsWB_ThisM) detection
- **Revenue reporting**: Monthly and lifetime revenue by instrument type and fee category; two revenue total formulas (legacy Revenue_Total and current Revenue_Total_New since 2025)
- **LTV modeling**: Six LTV columns written by a separate SP (`SP_LTV_BI_Actual`) representing 1Y, 3Y, and 8Y lifetime value predictions
- **PnL and equity tracking**: End-of-month equity by asset class and leverage tier
- **Acquisition analytics**: Channel, affiliate, first action, and seniority data from the customer's registration
- **Compliance**: AML last ticket date, IsChurn flag, professional client status

**Population boundary**: Only **funded/depositing customers** are included. Non-depositing registered users are absent. ~5.87M distinct CIDs as of April 2026; earliest CID dates from 2007-08 (oldest data in BI_DB_dbo).

**Instrument taxonomy**: Activity, revenue, PnL, and equity columns are systematically repeated across 6 asset-class families:
- **Copy** — copy-mirror positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** sub-divides four asset classes (Real Stocks, CFD Stocks, Real Crypto, CFD Crypto):
- **Lev1** — 1:1 leverage, IsBuy=1 (long un-leveraged position)
- **LevCFD** — leveraged or short position (CFD-style)

**ACC_ prefix**: Accumulator columns carry a running lifetime total from the customer's first month. Each month's value = current month's metric + prior month's ACC_ value (self-reference pattern). For a customer's first ever month, ACC_ initialises from the current month values only.

**Column evolution**: The SP has been extended many times since 2019. Columns 176–189 (ActiveOpenManual, ActiveOpenWOAirdrop, ActiveOpenWOAirdropManual, EOM_LSD, ActiveOpen_AirDrop, ActiveOpen_Mirror, ActiveOpen_Manual, ActiveOpen_IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, Revenue_Total_New, ACC_Revenue_Total_New, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, Revenue_TicketFeeByPercent) were added 2021–2025. Historical rows pre-dating those additions will show NULL.

---

## 2. Business Logic

### 2.1 EOM_Club — Monthly Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of the calendar month, based on `Dim_PlayerLevel` with a LowBronze/HighBronze split applied within BI_DB_dbo.

**Columns Involved**: `EOM_Club`

**Rules**:
```
EOM_Club =
  WHEN EOM_Equity < 1000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                         → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                      → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split at the $1,000 equity mark. Observed distribution (April 2026): LowBronze 79.6%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOM_Regulation — Regulatory Jurisdiction

**What**: Customer's regulatory entity at end of month, from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`.

**Columns Involved**: `EOM_Regulation`

**Observed values (April 2026)**: CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, FinCEN 1.7%, FSRA 1.5%, ASIC 0.9%, MAS, FINRAONLY, NFA, BVI, NYDFS+FINRA, eToroUS (<1% each).

### 2.3 Active / ActiveOpen / NewTrades Definitions

**Columns Involved**: `Active`, `ActiveOpen`, `ActiveOpen_Manual`, `ActiveOpen_Mirror`, `ActiveOpen_AirDrop`, `NewTrades_*`, `Active_*`, `ActiveOpen_*`

**Rules**:
```
Active = 1       → customer closed ≥1 position this calendar month (any asset class)
ActiveOpen = 1   → CASE WHEN ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1 THEN 1 ELSE 0 END
                   (Or Filizer update 2025-01-06)
ActiveUser = 1   → EOM_Equity > 0 (customer has any equity at month end)
NewTrades_Total  → count of all newly opened positions (across all asset classes) this month
```
Note: `ActiveOpen` is a composite flag. A customer counts as ActiveOpen if they have any open manual, new-mirror, or add-mirror position. Copy-portfolio positions count separately (`ActiveOpen_Copy`, `IsOpen_CopyPortfolio`).

### 2.4 Revenue Taxonomy (Post-2025 Update)

**What**: Two parallel revenue totals exist due to the 2025 fee component expansion by Or Filizer.

**Columns Involved**: `Revenue_Total`, `Revenue_Total_New`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Formulas**:
```
FullCommissions = Revenue_Copy + Revenue_Real_Crypto + Revenue_CFD_Crypto
                + Revenue_Real_Stocks + Revenue_CFD_Stocks + Revenue_FX/Comm/Ind + Revenue_Other
                [sourced from BI_DB_DailyCommisionReport]

Revenue_Total     = FullCommissions only (LEGACY formula — excludes function fees)

Revenue_Total_New = FullCommissions
                  + Revenue_AdminFee (Islamic account admin fee)
                  + Revenue_TicketFees (Function_Revenue_TicketFee)
                  + Revenue_ConversionFees (Function_Revenue_ConversionFee)
                  + Revenue_SpotAdjustFee (Islamic spot adjustment fee)
                  + Revenue_TicketFeeByPercent (Function_Revenue_TicketFeeByPercent)

Revenue_IslamicFees = Revenue_AdminFee + Revenue_SpotAdjustFee
                   [fee components specific to Islamic/swap-free accounts]

Transactional_Revenue_Total = Revenue_Total_New − Revenue_ConversionFees
                             [excludes currency conversion fees; pure transactional/trading revenue]
```
**Guidance**: Use `Revenue_Total_New` for all current reporting. `Revenue_Total` is retained for historical comparability only. `Transactional_Revenue_Total` is used when conversion fee effects should be excluded (e.g., revenue from trading activity only).

### 2.5 ACC_ Column Accumulation Pattern

**What**: Running lifetime totals built by reading the prior month's row from the same table.

**Columns Involved**: All `ACC_*` columns (22 columns)

**Pattern**:
```sql
-- Pseudo-code for each ACC_ column:
ACC_Revenue_Total_New(this_month) =
    Revenue_Total_New(this_month)
  + ISNULL(ACC_Revenue_Total_New FROM same_table WHERE ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth), 0)
```
The prior month's ACC_ value is fetched into temp table `#History` via a SELECT on the same Synapse table. For a customer's first month in the table (no prior row exists), `ACC_` initialises to the current month's value only.

**Important**: Because the current month's row is deleted and re-inserted daily (while the month is open), the `#History` lookup always reads the prior *closed* month. The current month's running total accumulates correctly only when the prior month is locked.

### 2.6 IsChurn_ThisM / IsWB_ThisM — Churn and Win-Back Flags

**What**: Monthly churn and win-back event detection based on IsFunded_New transitions.

**Columns Involved**: `IsChurn_ThisM`, `IsWB_ThisM`, `IsFunded_New`

**Rules** (POST-INSERT UPDATE from #ChurnWB):
```
IsChurn_ThisM = 1   when prior_month.IsFunded_New > 0  AND  this_month.IsFunded_New = 0
IsWB_ThisM    = 1   when prior_month.IsFunded_New = 0  AND  this_month.IsFunded_New > 0
```
The prior month's `IsFunded_New` is read from the already-inserted row for `ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth)`.

### 2.7 Seniority_FundedNew — Adjusted Seniority Since First Funding

**What**: Months since the customer's "new funded" date — a composite date that takes the latest of FTD, first action, and KYC level-3 completion dates, rounded to month start.

**Columns Involved**: `Seniority_FundedNew`, `Seniority`

**Rules** (POST-INSERT UPDATE from #Seniority_FundedNew):
```
NewFunded_Date0 = MAX(
    DATEFROMPARTS(YEAR(FTDDate), MONTH(FTDDate), 1),
    DATEFROMPARTS(YEAR(FirstActionDate), MONTH(FirstActionDate), 1),
    DATEFROMPARTS(YEAR(V3_Date), MONTH(V3_Date), 1)
)
Seniority_FundedNew = DATEDIFF(MONTH, NewFunded_Date0, ActiveDate)
                      (NULL for unfunded customers or if dates unavailable)

Seniority (original) = DATEDIFF(MONTH, FTDdate, @BeginOfMonth)
```

### 2.8 LTV Columns — Populated by Separate SP

**What**: Six LTV model predictions. NOT set by `SP_CID_MonthlyPanel_FullData` — they are hardcoded `0` in the initial INSERT to avoid an SP→table circular dependency.

**Columns Involved**: `LTV_1Y`, `LTV_3Y`, `LTV_8Y`, `LTV_8Y_NoExtreme`, `LTV_Expected_bySeniority`, `NoExtremeLTV_Expected_bySeniority`

**Rules**:
```
SP_CID_MonthlyPanel_FullData: LTV_* = 0 (hardcoded, prevents loop)
SP_LTV_BI_Actual:             LTV_* = model predictions (runs separately, UPDATEs these columns)
```
Circular dependency note: `SP_LTV_BI_Actual` reads from `BI_DB_CID_MonthlyPanel_FullData` (for revenue/activity input features), so if `SP_CID_MonthlyPanel_FullData` tried to read LTV from itself, it would create a loop. The solution is to initialise LTV to 0 and let `SP_LTV_BI_Actual` fill them in on a separate pass.

### 2.9 EOM_LSD — Life Stage Description

**What**: 17-value customer lifecycle classification at end of month, set from `BI_DB_CID_LifeStageDefinition`.

**Columns Involved**: `EOM_LSD`

**Observed values (April 2026)**:
| Life Stage | Count | % |
|---|---|---|
| Dump Churn | 2,184,880 | 37.2% |
| Holder | 1,139,396 | 19.4% |
| No Activity - Not Funded | 712,990 | 12.2% |
| Active Open Club | 311,045 | 5.3% |
| Active Open | 296,517 | 5.0% |
| Churn over 60 days | 286,978 | 4.9% |
| Active Open 30-90 days | 257,397 | 4.4% |
| Holder Club | 193,957 | 3.3% |
| No Activity - Funded | 169,824 | 2.9% |
| Active Open 30-90 days Club | 115,709 | 2.0% |
| Win Back Active Open | 72,325 | 1.2% |
| Active LogIn | 40,768 | 0.7% |
| Churn 31-60 days | 38,262 | 0.7% |
| Churn 14-30 days | 22,393 | 0.4% |
| New Funded | 9,458 | 0.2% |
| New Depositor Only | 6,003 | 0.1% |
| Win Back Deposit | 267 | 0.004% |

---

## 3. Query Advisory

### 3.1 Grain and Filtering
- **One row per CID per calendar month**. Always filter `WHERE ActiveDate = '20XX-MM-01'` (first day of month) for a single-month slice. Do NOT filter on Active_Month (char type has trailing spaces, comparisons can fail).
- **ActiveDate is DATE type** (not INT). Use `ActiveDate = '2026-04-01'` not `ActiveDate = 20260401`.
- **Bracket-escape "/" column names**: `[Active_FX/Comm/Ind]`, `[Revenue_FX/Comm/Ind]`, `[PnL_FX/Comm/Ind]`, `[ACC_Revenue_FX/Comm/Ind]`, `[ACC_PnL_FX/Comm/Ind]`, `[AmountIn_NewTrades_FX/Comm/Ind]`, `[NewTrades_FX/Comm/Ind]`, `[EOM_Equity_FX/Comm/Ind]`.

### 3.2 Revenue Columns — Which to Use
- Use **`Revenue_Total_New`** for all current revenue analysis (includes all fee components since 2025).
- Use **`Revenue_Total`** only for pre-2025 historical comparability — it excludes function-based fees.
- Use **`Transactional_Revenue_Total`** when you want to exclude currency conversion fees (e.g., pure trading activity measurement).
- Use **`ACC_Revenue_Total_New`** for lifetime revenue totals. Do NOT use `ACC_Revenue_Total` for new analysis — it accumulates the legacy formula.

### 3.3 LTV Columns
- **LTV columns are always 0 unless SP_LTV_BI_Actual has run for that month**. If you see all-zero LTV values, check whether the LTV SP has been executed. LTV is typically available for historical months only.
- LTV applies to funded/active customers only; check for 0 vs NULL before aggregating.

### 3.4 ACC_ Column Behaviour for Current Month
- The current open month's ACC_ values accumulate correctly only after the prior month is locked. For the **live/current month**, ACC_ reflects: prior month's ACC_ + current run's values. It is refreshed daily on DELETE+INSERT.
- Do NOT compare ACC_ totals across different months for the same CID — the prior month's value is included, making comparisons misleading.

### 3.5 Lev1/LevCFD Sub-Tier Columns
- The **plain** `Active_Real_Stocks`, `Active_CFD_Stocks`, etc. columns include **both Lev1 and LevCFD** combined.
- `Active_Real_Stocks_Lev1` and `Active_CFD_Stocks_LevCFD` are **sub-breakdowns** of the plain columns.
- Note: the Lev1/LevCFD flag columns (Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL) are stored as `[money]` type in the DDL, though semantically binary (0 or 1 for Active/ActiveOpen). This is a known DDL quirk.
- These columns contain NULL for pre-2023 periods when the Lev split was not yet tracked.

### 3.6 EOM_Segment Always NULL
- The `EOM_Segment` column is always NULL in practice — it was reserved but never populated by the ETL.

### 3.7 Large Table Query Guidance
- With 353.8M rows, **always filter on `ActiveDate`** before adding other predicates. `ActiveDate` is the leading index key.
- The table is HASH(CID)-distributed. Joins to other HASH(CID) tables (e.g., BI_DB_CID_DailyPanel_FullData) are co-located — no data movement.
- Avoid `COUNT(*)` without a date filter. Use `sys.dm_pdw_nodes_db_partition_stats` for rowcount estimates.
- For `GROUP BY` analytics on a single month, add `WHERE ActiveDate = '20XX-MM-01'` and include `ActiveDate` in the GROUP BY if reporting multiple months.

### 3.8 CountryID vs Country / Region
- `CountryID` (int, FK → Dim_Country) is the canonical geographic key. JOIN to `DWH_dbo.Dim_Country` for country attributes.
- `Country` (varchar) and `Region` (varchar) are denormalized strings copied from Dim_Customer at ETL time. They may lag Dim_Country changes by up to one day.
- `NewMarketingRegion` is a more recent marketing region label that may differ from `Region` for some countries.

---

## 4. Data Elements

### 4.1 Identity / Grain

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | NO | Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 2 | Active_Month | char(7) | NO | Calendar month this row represents, in YYYY-MM format with trailing space pad to 7 chars (e.g., '202604 '). Grain identifier alongside ActiveDate. Always use ActiveDate (DATE) for filtering; char comparisons on Active_Month can fail due to trailing space. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 3 | ActiveDate | date | NO | First day of the calendar month (e.g., 2026-04-01). Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for month slices. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 109 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_CID_MonthlyPanel_FullData. Refreshed daily during the current open month. (Tier 2 — ETL metadata) |

### 4.2 Registration & Acquisition

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 4 | Seniority | int | YES | Months since first deposit: DATEDIFF(MONTH, FTDdate, ActiveDate). 0 = FTD month. NULL for customers without a deposit. Observed range: 0–225 months (2007–2026). (Tier 2 — SP_CID_MonthlyPanel_FullData, BI_DB_CIDFirstDates) |
| 5 | RegMonth | char(7) | YES | Month of customer registration in YYYY-MM format. (Tier 2 — Dim_Customer via #CIDs) |
| 6 | RegDate | date | YES | Exact date of customer registration. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 7 | IsReg_ThisM | tinyint | YES | 1 if the customer registered during this calendar month; 0 otherwise. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 8 | FTD_Month | char(7) | YES | Month of first time deposit (FTD) in YYYY-MM format. NULL before FTD. (Tier 2 — BI_DB_CIDFirstDates) |
| 9 | FTDdate | date | YES | Exact date of first deposit. NULL before FTD. (Tier 2 — BI_DB_CIDFirstDates) |
| 10 | IsFTD_ThisM | tinyint | YES | 1 if the customer made their first deposit this calendar month; 0 otherwise. (Tier 2 — BI_DB_CIDFirstDates) |
| 11 | FTDA | money | YES | First time deposit amount (USD). Amount of the initial deposit event. (Tier 2 — BI_DB_CIDFirstDates) |
| 12 | Region | varchar(50) | YES | Marketing region name as of ETL run (e.g., 'ROW', 'UK', 'CEE', 'Latam'). Denormalized from Dim_Customer. May differ from NewMarketingRegion for some countries. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 13 | Country | varchar(50) | YES | Customer's country name (e.g., 'United Kingdom', 'Israel'). Denormalized from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 14 | Channel | varchar(50) | YES | Acquisition channel (e.g., 'Affiliate', 'SEM', 'Media Performance'). (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 15 | SubChannel | varchar(250) | YES | Acquisition sub-channel. More granular than Channel. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 16 | AffiliateID | bigint | YES | Affiliate partner identifier. FK → DWH_dbo.Dim_Affiliate. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 17 | FirstAction | varchar(50) | YES | Instrument type of the customer's first-ever trade (e.g., 'FX/Commodities/Indices', 'Crypto'). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions) |
| 18 | FirstInstrument | varchar(250) | YES | Name of the specific instrument in the customer's first trade (e.g., 'EUR/USD', 'BTC'). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions) |
| 19 | V2_Complete | tinyint | YES | 1 if KYC level 2 (identity verification) was completed before this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 20 | V3_Complete | tinyint | YES | 1 if KYC level 3 (enhanced due diligence / proof of address) was completed before this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |

### 4.3 Engagement & State

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | LastPosOpenDate | date | YES | Date of the customer's last position open event (any instrument) up to and including this month. (Tier 2 — Fact_CustomerAction) |
| 22 | LastLoggedIn | date | YES | Date of the customer's last login before end of this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 23 | IsPro | tinyint | YES | 1 if the customer has professional client status (from External_BI_OUTPUT_Customer_ProfessionalCustomers). (Tier 2 — External table) |
| 24 | IsOTD | tinyint | YES | 1 if the customer is classified as OTD (Over-the-Desk / client service tier). (Tier 2 — Fact_SnapshotCustomer) |
| 110 | AccountManager | varchar(250) | YES | Name of the assigned account manager at ETL run time. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 111 | IsIslamic | tinyint | YES | 1 if the customer's account is Islamic (swap-free). Islamic accounts incur AdminFee and SpotAdjustFee instead of overnight swaps. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 112 | IsContacted | tinyint | YES | 1 if the customer was contacted by sales/CRM this month. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 113 | IsContactedAmount | money | YES | Amount associated with the CRM contact event this month (if applicable). (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 117 | LastApplicationProAccountDate | date | YES | Date of the customer's most recent professional account application. 1900-01-01 if no application. (Tier 2 — Fact_SnapshotCustomer) |
| 173 | LastAMLTicketDate | date | YES | Most recent AML-related Salesforce case date for this customer (POST-INSERT UPDATE from BI_DB_SF_Cases_Panel). NULL if no AML case history. (Tier 2 — BI_DB_SF_Cases_Panel) |

### 4.4 EOM Classification & Segmentation

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | EOM_Club | varchar(50) | YES | eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000–Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 26 | EOM_Regulation | varchar(50) | YES | Regulatory jurisdiction at end of month (e.g., CySEC, FCA, FinCEN+FINRA, ASIC & GAML). Sourced from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 15 distinct values observed. (Tier 2 — Fact_SnapshotCustomer / Dim_Regulation) |
| 27 | EOM_Equity | money | YES | Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. (Tier 2 — DWH_dbo.V_Liabilities) |
| 28 | EOM_Balance | money | YES | Cash balance (USD) at end of month — equity minus unrealised PnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| 29 | EOM_Segment | varchar(50) | YES | Reserved classification field. Always NULL in practice — never populated by current ETL. (Tier 2 — Reserved) |
| 32 | ActiveUser | tinyint | YES | 1 if EOM_Equity > 0 (customer has any portfolio value at month end). Broader than Active or ActiveOpen. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 114 | EOM_IsFunded | tinyint | YES | Legacy funded flag at end of month from Fact_SnapshotCustomer snapshot. Differs from IsEOM_Funded_NEW / IsFunded_New in calculation. Use IsFunded_New or IsEOM_Funded_NEW for current analysis. (Tier 2 — Fact_SnapshotCustomer) |
| 158 | IsFunded_New | tinyint | YES | Current funding flag (new definition). Used as the base for IsChurn_ThisM and IsWB_ThisM churn detection. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 159 | Seniority_FundedNew | int | YES | Months since customer's "new funded" date: DATEDIFF(MONTH, MAX(FTDMonth, FirstActionMonth, V3Month), ActiveDate). NULL for unfunded customers. (Tier 2 — BI_DB_CIDFirstDates + BI_DB_First5Actions, POST-INSERT UPDATE) |
| 168 | NewMarketingRegion | varchar(50) | YES | Marketing region label (newer vintage than Region). Values: ROW, UK, CEE, Nordics, Latam, SEA, Australia, etc. (Tier 2 — Fact_SnapshotCustomer / Dim_Customer) |
| 169 | ClusterDetail | varchar(50) | YES | Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., 'Equities Crypto'). NULL for unclustered customers. (Tier 2 — BI_DB_CID_DailyCluster) |
| 170 | IsEOM_Funded_NEW | tinyint | YES | End-of-month funded flag under the new funded definition. Closely related to IsFunded_New; reflects EOM state. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 172 | CountryID | int | YES | FK → DWH_dbo.Dim_Country.CountryID. Use for country attribute lookups (regulation, AML risk, EU membership). CountryID=0 = Not available. (Tier 1 — DWH_dbo.Dim_Country wiki) |
| 174 | IsChurn_ThisM | int | YES | 1 if customer was funded last month (IsFunded_New=1) but not this month (IsFunded_New=0). Churn event indicator. POST-INSERT UPDATE. (Tier 2 — SP_CID_MonthlyPanel_FullData self-reference) |
| 175 | IsWB_ThisM | int | YES | 1 if customer was not funded last month but is funded this month. Win-back event indicator. POST-INSERT UPDATE. (Tier 2 — SP_CID_MonthlyPanel_FullData self-reference) |
| 179 | EOM_LSD | nvarchar(50) | YES | Life Stage Description at end of month from BI_DB_CID_LifeStageDefinition. 17 possible values: e.g., 'Dump Churn', 'Holder', 'Active Open Club', 'New Funded', 'Win Back Active Open'. (Tier 2 — BI_DB_CID_LifeStageDefinition) |

### 4.5 Activity Flags — Top Level

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | Active | tinyint | YES | 1 if customer closed ≥1 position this month (any asset class). (Tier 2 — Fact_CustomerAction) |
| 34 | ActiveOpen | tinyint | YES | 1 if customer has open positions at month end. Composite: 1 when ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1. (Tier 2 — SP_CID_MonthlyPanel_FullData, Or Filizer 2025-01-06) |
| 176 | ActiveOpenManual | int | YES | Count of open manual (non-copy) positions at month end. Stored as count, not a binary flag. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 177 | ActiveOpenWOAirdrop | int | YES | Count of open positions at month end, excluding airdrop-type positions. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 178 | ActiveOpenWOAirdropManual | int | YES | Count of open manual positions at month end excluding airdrop positions. (Tier 2 — SP_CID_MonthlyPanel_FullData) |

### 4.6 Activity Flags — Asset Class

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 45 | Active_Copy | tinyint | YES | 1 if customer had active copy trades closed this month. (Tier 2 — Fact_CustomerAction) |
| 46 | Active_Real_Stocks | tinyint | YES | 1 if customer closed ≥1 real (settled) stock/ETF position this month. (Tier 2 — Fact_CustomerAction) |
| 47 | Active_CFD_Stocks | tinyint | YES | 1 if customer closed ≥1 CFD (leveraged) stock position this month. (Tier 2 — Fact_CustomerAction) |
| 48 | Active_Real_Crypto | tinyint | YES | 1 if customer closed ≥1 settled crypto position this month. (Tier 2 — Fact_CustomerAction) |
| 49 | Active_CFD_Crypto | tinyint | YES | 1 if customer closed ≥1 CFD crypto position this month. (Tier 2 — Fact_CustomerAction) |
| 50 | [Active_FX/Comm/Ind] | tinyint | YES | 1 if customer closed ≥1 FX/commodity/index position this month. Column name contains "/" — must use bracket quoting. (Tier 2 — Fact_CustomerAction) |
| 51 | ActiveOpen_Copy | tinyint | YES | 1 if customer has open copy trades at month end. (Tier 2 — Fact_CustomerAction) |
| 52 | ActiveOpen_Real_Stocks | tinyint | YES | 1 if customer has open real stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 53 | ActiveOpen_CFD_Stocks | tinyint | YES | 1 if customer has open CFD stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 54 | ActiveOpen_Real_Crypto | tinyint | YES | 1 if customer has open settled crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 55 | ActiveOpen_CFD_Crypto | tinyint | YES | 1 if customer has open CFD crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 56 | [ActiveOpen_FX/Comm/Ind] | tinyint | YES | 1 if customer has open FX/commodity/index positions at month end. Bracket-quote required. (Tier 2 — Fact_CustomerAction) |
| 180 | ActiveOpen_AirDrop | int | YES | 1 if customer has open airdrop-type positions at month end. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 181 | ActiveOpen_Mirror | int | YES | 1 if customer has open mirror/add-mirror copy positions at month end. CASE WHEN NewMirror=1 OR AddMirror=1. (Tier 2 — Dim_Mirror via #mrr/#addmrr) |
| 182 | ActiveOpen_Manual | int | YES | 1 if customer has open manually-executed positions at month end (non-copy). (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 183 | ActiveOpen_IncludeCopy | int | YES | 1 if customer has open positions including copy trades at month end. Superset of ActiveOpen. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 128 | Active_Real_Stocks_Lev1 | money | YES | Flag (stored as money: 0.0 or 1.0) — customer traded real stocks with 1:1 leverage (un-leveraged long) this month. (Tier 2 — Fact_CustomerAction Lev sub-split) |
| 129 | Active_CFD_Stocks_LevCFD | money | YES | Flag — customer traded leveraged/short CFD stock positions this month. (Tier 2 — Fact_CustomerAction) |
| 130 | Active_Real_Crypto_Lev1 | money | YES | Flag — customer traded un-leveraged real crypto positions this month. (Tier 2 — Fact_CustomerAction) |
| 131 | Active_CFD_Crypto_LevCFD | money | YES | Flag — customer traded leveraged/short CFD crypto positions this month. (Tier 2 — Fact_CustomerAction) |
| 132 | ActiveOpen_Real_Stocks_Lev1 | money | YES | Flag — customer has open un-leveraged real stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 133 | ActiveOpen_CFD_Stocks_LevCFD | money | YES | Flag — customer has open leveraged CFD stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 134 | ActiveOpen_Real_Crypto_Lev1 | money | YES | Flag — customer has open un-leveraged real crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 135 | ActiveOpen_CFD_Crypto_LevCFD | money | YES | Flag — customer has open leveraged CFD crypto positions at month end. (Tier 2 — Fact_CustomerAction) |

### 4.7 Copy / Portfolio Copy Activity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 35 | IsOpen_Copy | tinyint | YES | 1 if customer has an open copy trade relationship at month end. (Tier 2 — Fact_CustomerAction) |
| 36 | Count_Opened_Copy | int | YES | Number of new copy trade relationships opened this month. (Tier 2 — Fact_CustomerAction) |
| 37 | Count_Closed_Copy | int | YES | Number of copy trade relationships closed this month. (Tier 2 — Fact_CustomerAction) |
| 38 | MoneyIn_Copy | money | YES | USD amount allocated to new copy trades this month. (Tier 2 — Fact_CustomerAction) |
| 39 | MoneyOut_Copy | money | YES | USD amount withdrawn from copy trades this month (stop-copy events). (Tier 2 — Fact_CustomerAction) |
| 40 | IsOpen_CopyPortfolio | tinyint | YES | 1 if customer has an open copy-portfolio (SmartPo

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Group_LTV_Table`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Group_LTV_Table.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Group_LTV_Table] AS  

/**************************************Start Main Comment History******************************************************
Author:      Jan Iablunovskey
Date:        2024-10-21
Description: This model creates Group LTV values based on the first-month Equity Tier, first-month Cluster, and the Region. 
             The population used is from January 2021 to June 2024. 
             This table is static and will be updated on demand.
 
**************************
** Change History
**************************
Date             Author          Description   


****************************************End Main Comment History****************************************************/

IF CAST(GETDATE() AS DATE) <= '2024-10-30'--- Making sure that SP will not run daily

BEGIN


BEGIN  

/********** Create Relevant Population **********/

DECLARE @StartDate AS DATE  = '20220101'
DECLARE @EndDate AS DATE  = '20240630' 

IF OBJECT_ID('tempdb..#Temp1') IS NOT NULL
DROP TABLE #Temp1
CREATE TABLE #Temp1 WITH (HEAP, DISTRIBUTION = HASH (CID))
AS
SELECT
  bdlp.CID
, dc.GCID
, dc1.MarketingRegionManualName AS NewMarketingRegion
, bdlp.Revenue8Y_LTV_New
, bdlp.Revenue8Y_LTV_NoExtreme_New
, CASE
	WHEN dc1.MarketingRegionManualName = 'Arabic' AND
		bdcmpfd.EOM_Equity < 500 THEN 2
	WHEN dc1.MarketingRegionManualName = 'Latam' AND
		bdcmpfd.ClusterDetail IN ('Crypto', 'Leveraged Traders') AND
		bdcmpfd.EOM_Equity < 500 THEN 2
	WHEN dc1.MarketingRegionManualName = 'Spain' AND
		bdcmpfd.ClusterDetail = 'Diversified Traders' AND
		bdcmpfd.EOM_Equity < 500 THEN 2
	WHEN dc1.MarketingRegionManualName = 'USA' AND
		bdcmpfd.ClusterDetail = 'Equities Traders' AND
		bdcmpfd.EOM_Equity < 500 THEN 2
	WHEN dc1.MarketingRegionManualName = 'UK' AND
		bdcmpfd.ClusterDetail = 'Diversified Traders' AND
		bdcmpfd.EOM_Equity < 500 THEN 2
	WHEN bdcmpfd.EOM_Equity < 100 OR
		EOM_Equity IS NULL THEN 1
	WHEN bdcmpfd.EOM_Equity < 500 THEN 2
	WHEN bdcmpfd.EOM_Equity >= 500 THEN 3
	ELSE 0
END First_Month_Equity_Tier
, CASE
	WHEN bdcmpfd.ClusterDetail IS NOT NULL THEN bdcmpfd.ClusterDetail
	WHEN bdcmpfd.FirstAction IS NOT NULL AND
		dc.VerificationLevelID = 3 THEN 'No Cluster - Active'
	ELSE 'No Cluster - Inactive'
END First_Month_Cluster
FROM BI_DB_dbo.BI_DB_LTV_BI_Actual bdlp WITH (NOLOCK)
INNER JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON bdlp.CID = dc.RealCID
INNER JOIN DWH_dbo.Dim_Country dc1 WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
LEFT JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd WITH (NOLOCK) ON dc.GCID = bdcd.GCID
LEFT JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd WITH (NOLOCK)
ON bdlp.CID = bdcmpfd.CID
AND bdcmpfd.Seniority = 1 
WHERE bdlp.FirstDepositDate >= @StartDate
AND bdlp.FirstDepositDate <= @EndDate    
AND bdlp.Revenue8Y_LTV_New < 1000000 -- EXCLUDE USERS WITH LTV above 1m 

/********** Create Group LTV **********/

IF OBJECT_ID('tempdb..#GLTV_Model') IS NOT NULL
DROP TABLE #GLTV_Model
CREATE TABLE #GLTV_Model
WITH (DISTRIBUTION = ROUND_ROBIN)
AS
SELECT
  p.First_Month_Equity_Tier
, p.First_Month_Cluster
, p.NewMarketingRegion AS Region
, AVG(p.Revenue8Y_LTV_New) Revenue8Y_LTV_New_Group_LTV
, AVG(p.Revenue8Y_LTV_NoExtreme_New) Revenue8Y_LTV_NoExtreme_New_Group_LTV
, COUNT(*) Clients
FROM #Temp1 p
GROUP BY
  p.First_Month_Equity_Tier
, p.First_Month_Cluster
, p.NewMarketingRegion 

TRUNCATE TABLE [BI_DB_dbo].[Group_LTV_Table]

INSERT INTO [BI_DB_dbo].[Group_LTV_Table] 
(
[First_Month_Equity_Tier] ,
[First_Month_Cluster],
[Region],
[Revenue8Y_LTV_New_Group_LTV],
[Revenue8Y_LTV_NoExtreme_New_Group_LTV],
[Clients],
[UpdateDate]
)
SELECT 
[First_Month_Equity_Tier] ,
[First_Month_Cluster],
[Region],
[Revenue8Y_LTV_New_Group_LTV],
[Revenue8Y_LTV_NoExtreme_New_Group_LTV],
[Clients],
GETDATE()
FROM #GLTV_Model

END
END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Group_LTV_Table` | synapse_sp | BI_DB_dbo | SP_Group_LTV_Table | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Group_LTV_Table.sql` |
| `BI_DB_dbo.BI_DB_LTV_BI_Actual` | synapse | BI_DB_dbo | BI_DB_LTV_BI_Actual | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_LTV_BI_Actual.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Country` | synapse | DWH_dbo | Dim_Country | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | synapse | BI_DB_dbo | BI_DB_CIDFirstDates | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` | synapse | BI_DB_dbo | BI_DB_CID_MonthlyPanel_FullData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md` |

