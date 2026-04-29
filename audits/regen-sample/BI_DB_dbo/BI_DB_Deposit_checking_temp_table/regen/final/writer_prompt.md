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

## ⛔ REGEN-HARNESS BREVITY OVERRIDE

This is a regen-harness run; we are optimising for token efficiency. The judge's
HARD assertions (8 sections present; ETL diagram in 5.2; Element table shape; row
count = DDL column count; Tier suffix on every Element row) all REMAIN MANDATORY.
Soft prose around them is CAPPED — defer to these caps even when the
GOLDEN-REFERENCE example (Dim_Mirror) shows verbose prose.

| Section | Cap |
|---|---|
| 1. Business Meaning | <=120 words. One paragraph. Must include row count, date range, ETL SP, source. |
| 2. Business Logic | <=2 subsections; each <=80 words What/Columns/Rules. Skip section entirely if no non-trivial logic. |
| 3.1 Distribution & Index | <=2 sentences. |
| 3.2 Common Query Patterns | Table only, max 3 rows, no commentary. |
| 3.3 Common JOINs | Table only, max 3 rows, no commentary. |
| 3.4 Gotchas | <=4 bullets, one line each. |
| 4. Elements | Each row Description: ONE sentence ending `(Tier N — source)`. No multi-sentence per-column descriptions. Inline dictionary values when <=15 distinct (per GOLDEN-REFERENCE Section C). |
| 5.2 ETL Pipeline | Diagram + 1 sentence below. No additional prose. |
| 6. Relationships | Tables only, no prose around them. |
| 7. Sample Queries | EXACTLY 2 queries. One sentence header each, no explanation paragraph. |
| 8. Atlassian Knowledge | Bullets only. |

These caps cut output from ~22K tokens to ~10K tokens per object. Keep the
information density HIGH, drop the explanation/narrative prose. The wiki is for
analysts and AI agents who already know the domain — they do not need essay-style
context.

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

- **Schema**: `BI_DB_dbo`
- **Object**: `BI_DB_Deposit_checking_temp_table`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_Deposit_checking_temp_table/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Deposit_checking_temp_table\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_Deposit_checking_temp_table\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_Deposit_checking_temp_table.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_Deposit_checking_temp_table`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_Deposit_checking_temp_table.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_Deposit_checking_temp_table]
(
	[Deposits_FCA] [decimal](26, 6) NULL,
	[Deposits_CB] [decimal](26, 6) NULL,
	[Balance_diff_deposit] [decimal](26, 6) NULL,
	[Error_Message] [varchar](max) NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = HASH ( [UpdateDate] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 2 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_Aggregate_Level_New.md`

# BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New

> Daily client balance rollup -- same measures as `BI_DB_Client_Balance_CID_Level_New`, aggregated by regulation, geography, account attributes, and transfer flags (no CID). Built in the same ETL run as the CID table from temp table `#RegAgg` (`SUM` over `#CIDAgg` with a wide `GROUP BY`).


| Property                 | Value                                                                                         |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| **Schema**               | BI_DB_dbo                                                                                     |
| **Object Type**          | Table (Fact -- BI reporting layer, aggregate grain)                                           |
| **Production Source**    | Derived -- rollup of `BI_DB_Client_Balance_CID_Level_New` in `SP_Client_Balance_New`          |
| **Refresh**              | Daily                                                                                         |
| **OpsDB**                | Priority 99, ProcessType 3 (same batch as CID Client Balance)                                   |
|                          |                                                                                               |
| **Synapse Distribution** | ROUND_ROBIN                                                                                   |
| **Synapse Index**        | CLUSTERED INDEX (DateID ASC)                                                                  |
|                          |                                                                                               |
| **UC Target**            | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new` (expected)    |
| **UC Format**            | Delta                                                                                         |
| **UC Copy Strategy**     | Append, 1440 min (daily)                                                                      |
| **Generic Pipeline ID**  | 943 (sibling of CID Client Balance pipeline)                                                  |


---

## 1. Business Meaning

`BI_DB_Client_Balance_Aggregate_Level_New` is the **aggregate (non-CID) sibling** of `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New`. Every numeric measure in the CID table is **summed** across customers that share the same combination of classification columns (for example `Regulation`, `Label`, `Country`, `TransferDirection`, `IsCreditReportValidCB`, DLT flags, `TanganyStatus`, `US_State`, and calendar attributes).

Use this table for **segment-level** dashboards, regulatory summaries by jurisdiction, and marketing or operations views where customer-level detail is not required. For **customer-level** balance, reconciliation, cycle-gap checks, and audit trails, use `BI_DB_Client_Balance_CID_Level_New` (and remember to `SUM` by `CID` when transfer rows exist).

### Grain and double counting

- **Grain**: One row per unique combination of all `GROUP BY` keys in `#RegAgg` for a given `DateID` (plus `TanganyStatus` and `US_State` where populated).
- **Transfer rows**: `TransferDirection` and credit-valid transfer flags behave as in the CID table. Aggregated rows still represent the split between current and prior regulation or CB-validity paths -- do not mix with CID-level counts without understanding transfer logic (see `BI_DB_Client_Balance_CID_Level_New`).

### Terminology (shared with CID wiki)

- **NWA** -- Non-Withdrawable Amount (bonus principal not cashable).
- **TRS** -- Total Return Swap (crypto settlement type).
- **DLT** -- Distributed Ledger Technology (Tangany wallet context).
- **SDRT** -- Stamp Duty Reserve Tax (UK).
- **C2P** -- Copy to Portfolio (copied trades as independent positions; column tracks related compensation flow per CID wiki).

---

## 2. Business Logic

### 2.1 ETL pattern -- DELETE + INSERT from `#RegAgg`

After `#CIDAgg` is populated (same logic as the CID insert), the SP builds `#RegAgg`:

- `SELECT` from `#CIDAgg` with `SUM(cast(... AS decimal(18,4)))` on all monetary and measure columns.
- `GROUP BY` all dimension keys: `TransferDirection`, `Regulation`, `IsCreditReportValidCB`, `DidRegulationTransfer`, `DidCBValidTransfer`, `DidDLTTransfer`, `IsDLTUser`, `IsEtoroTradingCID`, `eToroTradingGroupUser`, `IsGlenEagleAccount`, `Region`, `FromRegulation`, `ToRegulation`, `AccountType`, `Label`, `Country`, `MifidCategory`, `Club`, `PlayerStatus`, `DateID`, `IsGermanBaFin`, `IsValidCustomer`, `Date`, `YearMonth`, `YearQuarter`, `Year`, `TanganyStatus`, `US_State`.

Then `DELETE ... WHERE DateID = @dateID` and `INSERT INTO BI_DB_Client_Balance_Aggregate_Level_New` selecting from `#RegAgg` with `ISNULL(..., 0)` on most measures, `GETDATE()` for `UpdateDate`, and `NULL` literals for `DepositConversionFee` and `WithdrawConversionFee` (placeholders, same as CID table).

### 2.2 Balance cycle at aggregate level

The **CID-level** balance equation (Opening + flows = Closing) holds per customer path. **Summing** `OpeningBalance` or `ClosingBalance` across this aggregate grain **does not** generally reproduce a single platform-wide balance without careful filters -- many measures are additive at this grain, but interpret totals with finance for official reconciliation.

### 2.3 Internal transfer columns

`InternalTransferDeposits` is loaded from the rolled-up `DepositsInternalTransfer` column in `#RegAgg` (which sums the CID-level internal deposit transfer metric). `InternalTransferWithdraws` rolls up `CashoutsInternalTransfer` from `#CIDAgg` / `#RegAgg`.

---

## 3. Query Advisory

### 3.1 Distribution and indexing

- **ROUND_ROBIN**: No hash key; full scans are typical for broad reporting. Filter on `DateID` to use the clustered index.
- **Clustered index on `DateID`**: Prefer `WHERE DateID = @d` or bounded ranges.

### 3.2 Relationship to CID table

To validate or drill down: join or filter the CID table on the same dimensions, then compare `SUM` of measures to the aggregate row (allowing for floating-point / money rounding).

### 3.3 Data freshness

Loaded in the **same** `SP_Client_Balance_New` execution as `BI_DB_Client_Balance_CID_Level_New` (Priority 99, daily).

### 3.4 View

`V_BI_DB_Client_Balance_Aggregate_Level_New` -- `SELECT * WHERE DateID >= 20200101` (same pattern as CID view with a different cutoff).

---

## 4. Elements

### Confidence Tier Legend

| Stars   | Tiers  | Meaning                                                                      |
| ------- | ------ | ---------------------------------------------------------------------------- |
| 4 stars | Tier 1 | Upstream wiki verbatim (dim names via Dictionary)                            |
| 3 stars | Tier 2 | From Synapse SP code (`SP_Client_Balance_New`) and CID table lineage         |
| 2 stars | Tier 3 | Computed at insert only (`GETDATE()`, NULL placeholders)                     |
| 1 star  | Tier 4 | Inferred from column name -- `[UNVERIFIED]`                                  |


### Dimension and classification (GROUP BY keys)

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 1 | TransferDirection | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferDirection) |
| 2 | Regulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Regulation) |
| 3 | IsCreditReportValidCB | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsCreditReportValidCB) |
| 4 | DidRegulationTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidRegulationTransfer) |
| 5 | DidCBValidTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidCBValidTransfer) |
| 6 | IsEtoroTradingCID | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsEtoroTradingCID) |
| 7 | eToroTradingGroupUser | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.eToroTradingGroupUser) |
| 8 | IsGlenEagleAccount | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsGlenEagleAccount) |
| 9 | Region | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Region) |
| 10 | FromRegulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.FromRegulation) |
| 11 | ToRegulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ToRegulation) |
| 12 | AccountType | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.AccountType) |
| 13 | Label | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Label) |
| 14 | Country | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Country) |
| 15 | MifidCategory | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.MifidCategory) |
| 16 | Club | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Club) |
| 17 | PlayerStatus | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PlayerStatus) |

### Date

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 18 | DateID | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DateID) |

### Balance components

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 19 | OpeningBalance | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OpeningBalance) |
| 20 | Deposits | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Deposits`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Deposits) |
| 21 | CompensationDeposit | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationDeposit`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationDeposit) |
| 22 | Bonus | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Bonus`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Bonus) |
| 23 | Compensation | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Compensation`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Compensation) |
| 24 | CompensationPI | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationPI`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationPI) |
| 25 | CompensationToAffiliate | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationToAffiliate`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationToAffiliate) |
| 26 | NWAAdjustment | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NWAAdjustment`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NWAAdjustment) |
| 27 | NegativeRefill | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeRefill`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeRefill) |
| 28 | Cashouts | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Cashouts`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Cashouts) |
| 29 | CashoutsIncludingRedeem | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutsIncludingRedeem`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutsIncludingRedeem) |
| 30 | CompensationCashouts | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationCashouts`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationCashouts) |
| 31 | CashoutFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutFee) |
| 32 | Chargeback | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Chargeback`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Chargeback) |
| 33 | Refund | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Refund`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Refund) |
| 34 | OvernightFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OvernightFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OvernightFee) |
| 35 | LostDebt | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.LostDebt`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.LostDebt) |
| 36 | ChargebackLoss | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ChargebackLoss`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ChargebackLoss) |
| 37 | OtherNegatives | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OtherNegatives`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OtherNegatives) |
| 38 | Foreclosure | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Foreclosure`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Foreclosure) |
| 39 | CompensationPnLAdjustments | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationPnLAdjustments`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationPnLAdjustments) |
| 40 | CompensationDormantFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationDormantFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationDormantFee) |
| 41 | ClientBalanceRealizedPnL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnL) |
| 42 | ClientBalanceRealizedPnLCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLCFD) |
| 43 | ClientBalanceRealizedPnLRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealStocks) |
| 44 | ClientBalanceRealizedPnLRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCrypto) |
| 45 | TransferCoins | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TransferCoins`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferCoins) |
| 46 | TransferCoinFees | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TransferCoinFees`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferCoinFees) |
| 47 | ClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClosingBalance) |
| 48 | realizedEquity | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.realizedEquity`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.realizedEquity) |
| 49 | RealCryptoOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealCryptoOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealCryptoOpenBalance) |

### Sub-balance buckets

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 50 | RealCryptoClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealCryptoClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealCryptoClosingBalance) |
| 51 | ClientMoneyOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientMoneyOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientMoneyOpenBalance) |
| 52 | ClientMoneyClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientMoneyClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientMoneyClosingBalance) |
| 53 | RealStocksOpeningBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealStocksOpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealStocksOpeningBalance) |
| 54 | RealStocksClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealStocksClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealStocksClosingBalance) |
| 55 | ClientBalanceFullCommission | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommission) |
| 56 | ClientBalanceCommission | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommission) |

### Commission breakdown

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 57 | ClientBalanceFullCommissionCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionCFD) |
| 58 | ClientBalanceCommissionCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionCFD) |
| 59 | ClientBalanceFullCommissionRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealCrypto) |
| 60 | ClientBalanceCommissionRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealCrypto) |
| 61 | ClientBalanceFullCommissionRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealStocks) |
| 62 | ClientBalanceCommissionRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealStocks) |
| 63 | DividendsPaid | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.DividendsPaid`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DividendsPaid) |
| 64 | TotalLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalLiability) |

### Liability and position metrics

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 65 | TotalNegativeLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalNegativeLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalNegativeLiability) |
| 66 | WithdrawableLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.WithdrawableLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.WithdrawableLiability) |
| 67 | NegativeWithdrawableLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeWithdrawableLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeWithdrawableLiability) |
| 68 | LiabilityInUsedMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.LiabilityInUsedMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.LiabilityInUsedMargin) |
| 69 | NegativeLiabilityInUsedMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeLiabilityInUsedMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeLiabilityInUsedMargin) |
| 70 | InProcessCashout | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.InProcessCashout`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.InProcessCashout) |
| 71 | NegativeInProcessCashout | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeInProcessCashout`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeInProcessCashout) |
| 72 | NOPCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCrypto) |
| 73 | NOPCryptoCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCryptoCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCryptoCFD) |
| 74 | NOPStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPStocks) |
| 75 | NOPStocksCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPStocksCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPStocksCFD) |
| 76 | TotalRealCryptoLoan | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoLoan`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoLoan) |
| 77 | TotalRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCrypto) |
| 78 | TotalRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealStocks) |
| 79 | PositionPNLCryptoReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoReal) |
| 80 | PositionPNLStocksReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLStocksReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLStocksReal) |
| 81 | PositionPNL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNL) |
| 82 | AvailableCash | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.AvailableCash`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.AvailableCash) |
| 83 | CashInCopy | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashInCopy`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashInCopy) |
| 84 | NOP | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOP`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOP) |
| 85 | PositionAmount | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionAmount`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionAmount) |
| 86 | StockOrders | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.StockOrders`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.StockOrders) |
| 87 | actualNWA | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.actualNWA`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.actualNWA) |
| 88 | UsedBonus | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UsedBonus`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UsedBonus) |

### Unrealized changes

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 89 | UnrealizedCommissionChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChange) |
| 90 | UnrealizedFullCommissionChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_L

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Fact_CustomerAction` — synapse
- **Resolved as**: `DWH_dbo.Fact_CustomerAction`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`

# DWH_dbo.Fact_CustomerAction

> The central customer activity fact table in the Synapse DWH, recording every significant user action — position opens/closes, logins, deposits, cashouts, fees, bonuses, social engagement, copy-trade operations, and more — as one row per event.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Row Count** | ~11 billion |
| **Production Sources** | `History.Credit` (via `History.ActiveCredit`), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `STS_Audit_UserOperationsData` (logins), `Billing.Login` (cashier logins), `Customer.CustomerStatic` (registrations) |
| **Refresh** | Daily (midnight ETL via SWITCH partition) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + 4 nonclustered |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **UC Format** | Delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` |
| **UC Table Type** | EXTERNAL |

---

## 1. Business Meaning

`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs — opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account — is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?"

The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema:
1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging
2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging
3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007)
4. **Logins** (ActionTypeID 14): From `STS_Audit_UserOperationsData` (Session Tracking Service) with platform/browser detection
5. **Registrations** (ActionTypeID 41): From `Customer.CustomerStatic`

Because the table unions fundamentally different event types, **most columns are only populated for specific ActionTypeIDs**. Position-related columns (InstrumentID, Leverage, Commission, IsBuy, etc.) are NULL/0 for non-position events. Fee-specific columns (IsFeeDividend, DividendID) are only set for ActionTypeID=35. This is a sparse fact table by design.

The data originates from production systems, flows through the Azure Data Lake and DWH staging tables, and is loaded by `SP_Fact_CustomerAction_DL_To_Synapse` (staging extract) and `SP_Fact_CustomerAction` (transform + load). Post-load, `SP_Fact_CustomerAction_IsParitalCloseParent` marks partial-close parents. The load uses SWITCH partition for daily increments.

---

## 2. Business Logic

### 2.1 ActionTypeID — Event Classification

**What**: Every row is classified by ActionTypeID, which determines what type of customer action occurred and which columns are populated.

**Columns Involved**: `ActionTypeID`, mapped via `DWH_dbo.Dim_ActionType`

**Rules**:

| ActionTypeID | Name | Category | Source |
|---|---|---|---|
| 1 | ManualPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID=0 |
| 2 | CopyPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID>0, OrigParentPositionID>0 |
| 3 | CopyPlusPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID>0 |
| 4 | ManualPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 5 | CopyPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 6 | CopyPlusPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 7 | Deposit | Deposit | History.Credit (CreditTypeID=1) |
| 8 | Cashout | Cashout | History.Credit (CreditTypeID=2) |
| 9 | Bonus | Bonus | History.Credit (CreditTypeID=7) |
| 10 | Cashout request | Cashout request | History.Credit (CreditTypeID=9) |
| 11 | Chargeback | Chargeback | History.Credit (CreditTypeID=11) |
| 12 | Refund | Refund | History.Credit (CreditTypeID=12) |
| 14 | LoggedIn | LoggedIn | STS_Audit_UserOperationsData |
| 15 | Account balance to mirror | Mirror ops | History.Credit (CreditTypeID=18) |
| 16 | Mirror balance to account | Mirror ops | History.Credit (CreditTypeID=19) |
| 17 | Register new mirror | Mirror ops | History.Credit (CreditTypeID=20) |
| 18 | Unregister mirror | Mirror ops | History.Credit (CreditTypeID=21) |
| 19 | Detach position from mirror | DetachPosition | History.Credit |
| 21-26 | Publish Post/Comment/Like, Received Post/Comment/Like | Social engagement | **DEAD DATA** — legacy rows exist but no longer updated. No active ETL. |
| 27 | DepositAttempt | DepositAttempt | History.Credit |
| 28 | DetachedPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 29 | Cashier Loggin | Cashier login | Billing.Login |
| 30 | Processed Cashout | Processed Cashout | History.Credit (CreditTypeID=2 processed) |
| 32 | Edit StopLoss | Edit StopLoss | History.Credit (CreditTypeID=13) |
| 34 | Open Stock Order | Stock order | History.Credit (CreditTypeID=29) |
| 35 | End Of The Week Fee | Fees | History.Credit (CreditTypeID=14) — overnight, weekend, dividend, SDRT, ticket fees |
| 36 | Compensation | Compensation | History.Credit (CreditTypeID=6) |
| 37 | Reverse cashout | Reverse cashout | History.Credit (CreditTypeID=8) |
| 38 | Affiliate Deposit | Deposit | History.Credit |
| 39 | PositionOpenTypeUnknown | PositionOpen | Position open without matching History.Credit (fix at weekly maintenance) |
| 40 | PositionCloseTypeUnknown | PositionClose | Position close without matching History.Credit |
| 41 | Customer Registration | Registration | Customer.CustomerStatic |
| 42 | Cashout Rollback | Chargeback | History.Credit (CreditTypeID=33) |
| 43 | Reverse Deposit | Reverse Deposit | History.Credit (CreditTypeID=32) |
| 44 | InternalDeposit | Deposit | History.Credit (MoveMoneyReasonID=5) |
| 45 | InternalWithdraw | Withdraw | History.Credit (MoveMoneyReasonID=5) |

### 2.2 IsFeeDividend — Fee Sub-Classification

**What**: For ActionTypeID=35 (End of Week Fee), classifies the specific fee type.

**Columns Involved**: `IsFeeDividend`, `Description`

**Rules** (per DSM-1463):
- `1` = Overnight/weekend fee (Description: "Over night fee", "Weekend fee")
- `2` = Dividend payment (Description LIKE '%dividend%')
- `3` = SDRT charge (Description LIKE '%sdrt%')
- `4` = Ticket fees (Description: "OpenTotalFees" or "CloseTotalFees")
- `NULL` = Not ActionTypeID=35

### 2.3 Position-Derived Columns (Shared with Dim_Position)

**What**: ~33 columns in Fact_CustomerAction are copies of the same data from `Trade.OpenPositionEndOfDay` / `History.ClosePositionEndOfDay` that also populates `DWH_dbo.Dim_Position`. These columns display the same data under the same column names but are populated independently at ETL time.

**Shared columns**: `PositionID`, `InstrumentID`, `Amount`, `Leverage`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `MirrorID`, `IsSettled`, `InitialUnits`, `IsDiscounted`, `CommissionByUnits`, `FullCommissionByUnits`, `RegulationIDOnOpen`, `ReopenForPositionID`, `IsReOpen`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `OriginalPositionID`, `IsPartialCloseParent`, `IsPartialCloseChild`, `IsAirDrop`, `SettlementTypeID`, `DLTOpen`, `DLTClose`, `OpenMarkupByUnits`, `IsBuy`, `NetProfit`, `RedeemStatus`, `RedeemID`, `IsRedeem`

**Rules**:
- These columns are ONLY populated for position events (ActionTypeID IN 1-6, 28, 39, 40)
- For non-position events, these columns are 0 or NULL
- The ETL joins from staging tables directly — NOT from Dim_Position itself
- Column meanings are identical to Dim_Position (see `Dim_Position.md` for detailed descriptions)

### 2.4 PlatformID — Product/Platform Resolution

**What**: Identifies which product/platform the action originated from. Badly named — it's actually a FK to `Dim_Product.ProductID`, not a standalone platform enum.

**Columns Involved**: `PlatformID`

**Rules**:
- Only populated for ActionTypeID=14 (logins) and 41 (registrations)
- Resolve via JOIN to `DWH_dbo.Dim_Product` — provides Product, Platform, and SubPlatform columns
- Do NOT hard-code value mappings (101=Android, etc.) — always JOIN to Dim_Product

**Query pattern**:
```sql
SELECT dp.Product, dp.Platform, dp.SubPlatform, fca.*
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Product dp ON fca.PlatformID = dp.ProductID
WHERE fca.ActionTypeID = 14
```

### 2.6 Reopen Commission Adjustment

**What**: For reopened positions (IsReOpen=1), the commission at close is adjusted.

**Columns Involved**: `CommissionOnClose`, `FullCommissionOnClose`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `IsReOpen`, `ReopenForPositionID`

**Rules**:
- `CommissionOnClose = new_position.CommissionOnClose - original_position.CommissionOnClose`
- `CommissionOnCloseOrig` / `FullCommissionOnCloseOrig` preserve original values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX + 4 nonclustered indexes (`ActionTypeID+DateID`, `ActionTypeID`, `CompensationReasonID`, `RealCID+DateID`). Always include `RealCID` in WHERE or JOIN for optimal single-distribution queries. The columnstore index enables efficient analytical scans across the ~11B rows.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as **Delta** (EXTERNAL, ~430 GB, ~7K files), partitioned by `etr_y`, `etr_ym`, `etr_ymd` (year, year-month, year-month-day). Always include partition columns in WHERE clauses for partition pruning — e.g., `WHERE etr_y = '2025' AND etr_ym = '202503'` will skip scanning irrelevant partitions. Given the table's ~11B rows, partition pruning is critical for any practical query. The partition columns are Databricks-layer additions not present in the Synapse source. Deletion vectors are enabled (`delta.enableDeletionVectors = true`).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All logins for a customer | `WHERE ActionTypeID = 14 AND RealCID = @cid` |
| Position opens in a date range | `WHERE ActionTypeID IN (1,2,3) AND DateID BETWEEN @start AND @end` |
| Revenue (commissions) | `WHERE ActionTypeID IN (1,2,3,4,5,6,28) AND Commission > 0` |
| Deposits for a customer | `WHERE ActionTypeID = 7 AND RealCID = @cid` |
| Overnight fees | `WHERE ActionTypeID = 35 AND IsFeeDividend = 1` |
| Dividend payments | `WHERE ActionTypeID = 35 AND IsFeeDividend = 2` |
| First-time deposits (FTD) | `WHERE IsFTD = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_ActionType` | `ON fca.ActionTypeID = dat.ActionTypeID` | Action type name and category |
| `DWH_dbo.Dim_Customer` | `ON fca.RealCID = dc.RealCID` | Customer demographics, country |
| `DWH_dbo.Dim_Instrument` | `ON fca.InstrumentID = di.InstrumentID` | Instrument name (position events only) |
| `DWH_dbo.Dim_Position` | `ON fca.PositionID = dp.PositionID` | Full position details (avoid when possible — heavy join on 11B rows) |
| `DWH_dbo.Dim_BonusType` | `ON fca.BonusTypeID = dbt.BonusTypeID` | Bonus type name, IsWithdrawable (bonus events only) |
| `DWH_dbo.Dim_Campaign` | `ON fca.CampaignID = dcm.CampaignID` | Campaign code, description, dates |
| `DWH_dbo.Dim_Country` | `ON fca.CountryIDByIP = dco.CountryID` | Country name from IP geolocation |
| `DWH_dbo.Dim_FundingType` | `ON fca.FundingTypeID = dft.FundingTypeID` | Payment method name (deposit/cashout events) |
| `DWH_dbo.Dim_PaymentStatus` | `ON fca.PaymentStatusID = dps.PaymentStatusID` | Payment status name |
| `DWH_dbo.Dim_Product` | `ON fca.PlatformID = dp.ProductID` | Product, Platform, SubPlatform (logins/registrations only) |
| `DWH_dbo.Dim_Date` | `ON fca.DateID = dd.DateID` | Calendar attributes |
| `DWH_dbo.Dim_Regulation` | `ON fca.RegulationIDOnOpen = dr.ID` | Regulation name |

### 3.4 Gotchas

- **Most columns are only populated for specific ActionTypeIDs.** InstrumentID, Leverage, Commission, IsBuy are all 0/NULL for logins, deposits, social events, etc.
- **11 billion rows** — always filter by ActionTypeID + DateID to avoid full scans
- **IsReal is always 1** in this table — it only contains real-account actions (no demo)
- **Leverage=0 means non-position event**, not "no leverage". For actual position opens, Leverage=1 means no leverage (real ownership)
- **IsBuy NULL** means non-position event. For position events: True=Buy, False=Sell
- **Description is sparse** — only populated for fee events (ActionTypeID=35) and a few others. Contains human-readable strings like "Over night fee", "Payment caused by dividend", "OpenTotalFees"
- **PlatformTypeID** vs **PlatformID**: PlatformTypeID is a legacy field (0=default, 99=STS); PlatformID is a FK to `Dim_Product.ProductID` (badly named — always JOIN to Dim_Product, don't hard-code values)
- **StatusID is nearly always 1** (~11B rows with StatusID=1, ~2M NULL)
- **DemoCID is always 0** (real accounts only)
- **HistoryID is NOT unique** — despite being intended as a key, it contains duplicates. Never use it for JOINs, deduplication, or row identification

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | NO | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | int | NO | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | NO | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | NO | Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. (Tier 1 — ETL-derived from CreditTypeID/source) |
| 9 | PlatformTypeID | smallint | NO | Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 11 | Amount | decimal(11,2) | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 12 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 13 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 14 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 15 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 16 | CampaignID | int | NO | Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 — domain expert) |
| 17 | BonusTypeID | smallint | NO | Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` — JOIN for Name, IsWithdrawable, IsActive. (Tier 5 — domain expert) |
| 18 | FundingTypeID | smallint | NO | Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 — domain expert) |
| 19 | LoginID | int | NO | Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 — Billing.Login) |
| 20 | MirrorID | int | NO | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 21 | WithdrawID | int | NO | Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | int | YES | Duration of a login session in seconds. NULL for non-login events. (Tier 1 — Billing.Login) |
| 23 | PostID | uniqueidentifier | YES | Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 — Social platform) |
| 24 | CaseID | int | NO | CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 — CRM) |
| 25 | UpdateDate | datetime | NO | UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 — ETL-assigned) |
| 26 | DateID | int | NO | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 — ETL-computed) |
| 27 | TimeID | int | NO | Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 — ETL-computed) |
| 28 | StatusID | tinyint | YES | Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | datetime | YES | Deprecated/unused column. NULL for most rows — not reliably populated. Do not use. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | int | NO | Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 — History.Credit, updated 2025-12-21) |
| 31 | WithdrawPaymentID | int | NO | Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 33 | IsPlug | bit | YES | Deprecated/unused column. Always NULL. (Tier 5 — domain expert) |
| 34 | DepositID | int | YES | Deposit transaction identifier. NULL for non-deposit events. (Tier 1 — History.Credit) |
| 35 | PostRootID | varchar(200) | YES | Root post ID for social engagement events. NULL for non-social events. (Tier 1 — Social platform) |
| 36 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 37 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 39 | RedeemStatus | int | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 40 | SessionID | bigint | YES | STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 — STS) |
| 41 | IsRedeem | int | YES | Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 — ETL-derived) |
| 42 | RegulationIDOnOpen | int | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer's regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 43 | PlatformID | int | YES | Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 45 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 46 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 47 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen. ETL default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 48 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 49 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 51 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 52 | PaymentStatusID | int | YES | Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` — JOIN for Name. (Tier 5 — domain expert) |
| 53 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. (Tier 1 — Trade.PositionTbl) |
| 54 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 57 | IsFTD | int | YES | First-Time Deposit flag: 1 = this is the customer's first deposit. NULL for non-deposit events. (Tier 2 — ETL-computed) |
| 58 | CountryIDByIP | int | YES | Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | int | YES | Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 — IP geolocation) |
| 60 | ProxyType | varchar(3) | YES | Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 — STS) |
| 61 | IsFeeDividend | int | YES | Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 — ETL-derived from Description) |
| 62 | IsAirDrop | int | YES | 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | DividendID | int | YES | Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 — Trade positions) |
| 64 | MoveMoneyReasonID | int | YES | Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 — History.Credit) |
| 65 | SettlementTypeID | int | YES | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) |
| 66 | DLTOpen | smallint | YES | DLT flag at open. Added 2024-06-02 (Ofir A). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 67 | DLTClose | smallint | YES | DLT flag at close. Added 2024-06-02. NULL for open positions and older positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 69 | Description | varchar(255) | YES | Human-readable description. Populated mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". For deposits: "Processed By eToro.Payments.Deposit", etc. (Tier 1 — History.Credit, added 2024-08) |
| 70 | IsBuy | bit | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 71 | CreditID | bigint | YES | Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 — History.Credit, added 2025-07) |

---

## 5. Relationships

### 5.1 References To

| Target Object | Join Column | Purpose |
|--------------|-------------|---------|
| DWH_dbo.Dim_ActionType | ActionTypeID | Action type name and category |
| DWH_dbo.Dim_Customer | RealCID | Customer demographics, country, regulation |
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument name, type (position events only) |
| DWH_dbo.Dim_Position | PositionID | Full position details (position events only) |
| DWH_dbo.Dim_Product | PlatformID → ProductID | Product, Platform, SubPlatform (badly named FK) |
| DWH_dbo.Dim_Regulation | RegulationIDOnOpen | Regulation name at event time |
| DWH_dbo.Dim_Date | DateID | Calendar attributes |
| DWH_dbo.Dim_BonusType | BonusTypeID | Bonus type name, IsWithdrawable, IsActive |
| DWH_dbo.Dim_Campaign | CampaignID | Campaign code, description, dates, bonus amount |
| DWH_dbo.Dim_Country | CountryIDByIP → CountryID | Country name (IP geolocation) |
| DWH_dbo.Dim_FundingType | FundingTypeID | Payment method name and properties |
| DWH_dbo.Dim_PaymentStatus | PaymentStatusID | Payment status name |
| Dictionary.CreditType | (via CreditID → History.Credit) | Credit type classification |
| Dictionary.MoveMoneyReason | MoveMoneyReasonID | Money movement reason |

### 5.2 Referenced By

| Source Object | Type | Usage |
|--------------|------|-------|
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | Function | First deposit across platforms |
| BI_DB_dbo.Function_Population_Active_Traders | Function | Active trader population |
| BI_DB_dbo.Function_Population_First_Time_Funded | Function | FTD population |
| BI_DB_dbo.Function_Population_First_Trading_Action | Function | First trading action |
| BI_DB_dbo.Function_Population_OTD_DateRange | Function | OTD date range population |
| BI_DB_dbo.Function_Revenue_Commissions | Function | Commission revenue calculation |
| BI_DB_dbo.Function_Revenue_FullCommissions | Function | Full commission revenue |
| BI_DB_dbo.Function_Revenue_CashoutFee_* | Function | Cashout fee revenue |
| BI_DB_dbo.Function_Revenue_DormantFee | Function | Dormant fee revenue |
| BI_DB_dbo.Function_Revenue_Share_Lending | Function | Share lending revenue |
| BI_DB_dbo.Function_Revenue_TransferCoinFee | Function | Crypto transfer fee revenue |
| BI_DB_dbo.V_C2P_Positions | View | CRM-to-position mapping |
| DWH_dbo.V_FCA_NumOfLogins_mean_1q | View | Average login count (1 quarter) |
| DWH_dbo.SP_Fact_FirstCustomerAction | SP | First action per customer |
| DWH_dbo.Fact_FirstCustomerAction | Table | Derivative table: first action per customer per type |

---

## 6. Dependencies

### 6.1 ETL Pipeline

```
Production Sources:
  History.ActiveCredit + Archive Credit Tables (2007-2022Q1)
    → History.Credit (view, UNION ALL)
      → Generic Pipeline → DWH_staging.Ext_FCA_Real_History_Credit_ForFactAction
  
  Trade.PositionTbl → Trade.OpenPositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_Trade_OpenPositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Trade_Position
  
  History.Position_Active → History.ClosePositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_History_ClosePositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_History_Position
  
  STS_Audit_UserOperationsData (Session Tracking Service)
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Audit_Loggin
  
  Billing.Login → DWH_staging.etoro_Billing_Login
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Cashier_Loggin
  
  Customer.CustomerStatic → DWH_staging.etoro_Customer_CustomerStatic
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Customer_Registration

All staging → SP_Fact_CustomerAction → Ext_FCA_Fact_CustomerAction
  → SP_Fact_CustomerAction_SWITCH → Fact_CustomerAction (SWITCH partition)
  → SP_Fact_CustomerAction_IsParitalCloseParent (post-load update)
```

### 6.2 ETL Stored Procedures

| SP | Role |
|----|------|
| SP_Fact_CustomerAction_DL_To_Synapse | Stage 1: Extract data from lake staging tables into Ext_FCA_* intermediate tables |
| SP_Fact_CustomerAction | Stage 2: Transform and load into Ext_FCA_Fact_C

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_Client_Balance_Check_Opening_Balance`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Client_Balance_Check_Opening_Balance.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_Client_Balance_Check_Opening_Balance] @date [date] AS   

/********************************************************************************************        
Author:      Daniel Kaplan         
Date:        2023-05-07        
Description: this proc to compare a Client Balance OpeningBalance day to ClosingBalance previous day    
        
**************************        
** Change History        
**************************        
Date        Author        Description         
     
21.10.2020  Daniel Kaplan  create SP , running from SP_Client_Balance_New  
11.02.2025  Daniel Kaplan  add checking of Deposits  
----------    ----------   ------------------------------------  
*/  
-- exec [BI_DB_dbo].[SP_Client_Balance_Check_Opening_Balance] '2024-03-11'

BEGIN

	--DECLARE @date DATE = DATEADD(DAY,-1,GETDATE())
	DECLARE @datePrev DATE = DATEADD(DAY,-1,@date)  
	DECLARE @dateID INT = BI_DB_dbo.DateToDateID (@date)  
	DECLARE @datePrevID INT = BI_DB_dbo.DateToDateID (@datePrev)
	
	DECLARE @v_OpeningBalance DECIMAL(26,6) ,
			@v_ClosingBalance DECIMAL(26,6) ,
			@v_Deposits_FCA DECIMAL(26,6) ,@v_Deposits_CB DECIMAL(26,6) ,
			@v_Balance_diff DECIMAL(26,6) ,@v_Balance_diff_deposit DECIMAL(26,6) ,
	        @v_error_message VARCHAR(MAX) ,@v_error_message_deposit VARCHAR(MAX) 
	
	select @v_OpeningBalance = sum(isnull(OpeningBalance,0)) , @v_Deposits_CB = sum(isnull(Deposits,0)) - sum(isnull(InternalTransferDeposits,0))
	from BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New 
	WHERE DateID = @dateID
	
	select @v_ClosingBalance = sum(isnull(ClosingBalance,0))
	from BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New 
	WHERE DateID = @datePrevID
	
	select @v_Balance_diff = @v_OpeningBalance - @v_ClosingBalance
	
	select @dateID as Curr_Date, @datePrevID  as Prev_Date,@v_OpeningBalance as OpeningBalance,@v_ClosingBalance as ClosingBalance, @v_Balance_diff as Balance_diff

	---------------------- Deposits	----------------------  		
	SELECT @v_Deposits_FCA = sum(isnull(Amount,0))
	FROM DWH_dbo.Fact_CustomerAction
	WHERE DateID = @dateID
	AND ActionTypeID = 7

	select @v_Balance_diff_deposit = @v_Deposits_FCA - @v_Deposits_CB
	
	select @dateID as Curr_Date,@v_Deposits_FCA as Deposits_FCA,@v_Deposits_CB as Deposits_CB, @v_Balance_diff_deposit as Balance_diff_deposit

	---------------------- Deposits	----------------------  

	IF isnull(@v_Balance_diff,-1) <> 0
	BEGIN
		set @v_error_message = 'We have a difference in Client Balance between OpeningBalance at ' + CAST(@dateID as varchar(20)) 
								+ ' and ClosingBalance at ' + CAST(@datePrevID as varchar(20))
								+ ' !!!
The OpeningBalance = ' + isnull(CAST(@v_OpeningBalance as varchar(20)),'NULL')
+ '
The ClosingBalance = ' + isnull(CAST(@v_ClosingBalance as varchar(20)),'NULL')
+ '
The difference = ' + isnull(CAST(@v_Balance_diff as varchar(20)),'NULL')
+ '
Please check a BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New table '
		select @v_error_message
		RAISERROR( @v_error_message , 18, -1)
	END
	ELSE IF isnull(@v_Balance_diff_deposit,-1) <> 0
	BEGIN
		set @v_error_message_deposit = 'We have a difference in deposit ' + CAST(@dateID as varchar(20)) 
								+ ' !!!
The Fact_CustomerAction Deposit = ' + isnull(CAST(@v_Deposits_FCA as varchar(20)),'NULL')
+ '
The CB Deposit = ' + isnull(CAST(@v_Deposits_CB as varchar(20)),'NULL')
+ '
The difference = ' + isnull(CAST(@v_Balance_diff_deposit as varchar(20)),'NULL')
+ '
Please check a (Deposits-InternalTransferDeposits) in BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New and Amount in Fact_CustomerAction tables '
		print @v_error_message_deposit
		--RAISERROR( @v_error_message , 18, -1)
	END
	ELSE 
		BEGIN
			select 'Any difference in Client Balance between OpeningBalance at ' + CAST(@dateID as varchar(20)) + ' and ClosingBalance at ' + CAST(@datePrevID as varchar(20))
		END

--IF OBJECT_ID('BI_DB_dbo.##BI_DB_Deposit_checking_temp_table') IS NOT NULL DROP TABLE BI_DB_dbo.BI_DB_Deposit_checking_temp_table;
--CREATE TABLE BI_DB_dbo.BI_DB_Deposit_checking_temp_table  
--    WITH (HEAP,DISTRIBUTION=HASH(UpdateDate))
--AS
	delete BI_DB_dbo.BI_DB_Deposit_checking_temp_table

	insert into BI_DB_dbo.BI_DB_Deposit_checking_temp_table
	select @v_Deposits_FCA as Deposits_FCA, @v_Deposits_CB as Deposits_CB, @v_Balance_diff_deposit as Balance_diff_deposit,
	CAST(@v_error_message_deposit as VARCHAR(MAX)) as [Error_Message], GETDATE() as UpdateDate

	select *
	from BI_DB_dbo.BI_DB_Deposit_checking_temp_table

END

/*
drop table BI_DB_dbo.BI_DB_Deposit_checking_temp_table

select *
from BI_DB_dbo.BI_DB_Deposit_checking_temp_table
*/
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_Client_Balance_Check_Opening_Balance` | synapse_sp | BI_DB_dbo | SP_Client_Balance_Check_Opening_Balance | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_Client_Balance_Check_Opening_Balance.sql` |
| `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` | synapse | BI_DB_dbo | BI_DB_Client_Balance_Aggregate_Level_New | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_Aggregate_Level_New.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |


---

# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT — apply ALL of these

Previous attempt scored **7.15** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Fix Error_Message NULL claim in Section 3.4 Gotchas — @v_error_message_deposit is NULL (not empty string) when Balance_diff_deposit=0, per SP source. (2) Add staleness gotcha for UpdateDate: RAISERROR(severity 18) for opening balance mismatch may abort before DELETE/INSERT runs, leaving stale data. (3) Add UC Target row to property table. (4) Add Tier Confidence Legend to Section 4 (4-star to 1-star table). (5) Add footer with tier breakdown counts (Tier 1: 0, Tier 2: 5, Tier 3: 0), quality score placeholder, and phases-completed list. (6) Restructure Section 5: move ASCII diagram to 5.2, renumber References To as 5.3, Referenced By as 5.4.

Top issues from the judge:
1. [high] `Error_Message (Section 2.1 and Section 3.4 Gotchas)` — Wiki states 'Error_Message is an empty string (not NULL) when the check passes.' SP source shows @v_error_message_deposit is declared VARCHAR(MAX) with no initialization and is never SET in the passing branch. CAST(NULL AS VARCHAR(MAX)) inserts NULL, not empty string. This is a factual error contradicted by the SP code.
2. [high] `UpdateDate (Section 1, 3.4)` — Wiki claims the table 'always holds exactly 1 row (the latest check result).' SP code shows RAISERROR(severity 18) fires when the opening balance check fails, which can abort the batch before the DELETE/INSERT executes, leaving stale data in the table. This critical staleness scenario is not documented.
3. [medium] `Property Table` — UC Target row is missing from the property table. Other wikis in the same schema include this row. Should be added (even if value is 'not yet provisioned' or expected).
4. [medium] `Section 4` — No Tier Confidence Legend present at the top of the Elements section. The golden reference shape requires a stars/tier legend (e.g., 4 stars = Tier 1 verbatim, 3 stars = Tier 2 SP-derived, etc.).
5. [medium] `Footer / Section 5` — Footer is a bare duplicate property table — missing tier breakdown counts, quality score, and phases-completed list. Additionally, the ETL ASCII diagram is placed in Section 5.1 instead of 5.2 per the golden reference structure.

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
