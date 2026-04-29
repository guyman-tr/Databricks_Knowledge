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
- **Object**: `BI_DB_DailyZeroPnL_Stocks`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_DailyZeroPnL_Stocks\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_DailyZeroPnL_Stocks\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks.sql`
- **No-upstream marker present**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_DailyZeroPnL_Stocks\regen\_no_upstream_found.txt` — object is dormant or has no resolvable upstream wiki. Footer may say `Production Source: Unknown (dormant)`. Tier 4 inferred is STILL banned — ground every column description in DDL + SP code.

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_DailyZeroPnL_Stocks]
(
	[Date] [date] NULL,
	[HedgeServerID] [int] NULL,
	[Industry] [varchar](250) NULL,
	[InstrumentType] [varchar](50) NULL,
	[InstrumentID] [int] NULL,
	[InstrumentDisplayName] [varchar](250) NULL,
	[StockIndex] [varchar](50) NULL,
	[IsManual] [tinyint] NULL,
	[Leverage] [int] NULL,
	[IsCFD] [tinyint] NULL,
	[Regulation] [varchar](50) NULL,
	[MifID] [int] NULL,
	[RealizedCommission] [money] NULL,
	[RealizedZero] [money] NULL,
	[ChangeInUnrealizedZero] [money] NULL,
	[TotalZero] [money] NULL,
	[NOP] [money] NULL,
	[OpenPositions] [money] NULL,
	[NOP_Units] [numeric](38, 6) NULL,
	[VolumeOnOpen] [bigint] NULL,
	[VolumeOnClose] [bigint] NULL,
	[OpenPositionValue] [money] NULL,
	[UpdateDate] [datetime] NULL,
	[InstrumentName] [varchar](100) NULL,
	[Units] [decimal](16, 6) NULL,
	[Currency] [varchar](50) NULL
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

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|


---

# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT — apply ALL of these

Previous attempt scored **7.2** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Fix harness — add knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md to the upstream bundle before regeneration. (2) Fix UpdateDate to Tier 3: '(Tier 3 — Dealing_dbo.Dealing_DailyZeroPnL_Stocks)' verbatim. (3) Promote all 25 remaining passthrough columns to Tier 1, citing Dealing_dbo.Dealing_DailyZeroPnL_Stocks as origin, using verbatim descriptions from that wiki. (4) Fix NOP description to include 'via FX conversion'. (5) Fix OpenPositionValue to 'computed from NOP and FX rate'. (6) Update footer tier counts to 25 T1, 0 T2, 1 T3, 0 T4.

Top issues from the judge:
1. [high] `UpdateDate` — Tagged Tier 2 but should be Tier 3. The Dealing_DailyZeroPnL_Stocks wiki (which exists at knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md) explicitly marks UpdateDate as '(Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE())'. GETDATE() is canonical batch metadata and the wiki's own tier legend defines Tier 3 as 'Batch-system metadata; no upstream traceability'. Footer incorrectly shows 0 T3.
2. [high] `All 26 elements` — BI_DB_DailyZeroPnL_Stocks is a schema-identical migration of Dealing_dbo.Dealing_DailyZeroPnL_Stocks. The Dealing wiki IS present in the knowledge base. Per tier rules, passthroughs WITH upstream wiki present must be Tier 1. The writer's review-needed R5 reasoning ('upstream already documented them as Tier 2 so BI_DB is also Tier 2') is incorrect: the Dealing table's own internal tier does not cascade; the BI_DB columns are Tier 1 relative to their immediate upstream (Dealing_DailyZeroPnL_Stocks).
3. [high] `Upstream bundle` — The harness bundle incorrectly reported 'NO UPSTREAM WIKI resolvable' for this object. The Dealing_DailyZeroPnL_Stocks wiki (knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DailyZeroPnL_Stocks.md) exists, was referenced by the writer in the lineage and review-needed sidecar, and was clearly consulted for descriptions (near-verbatim matches). The harness resolution step must be fixed to search for migration source table wikis.
4. [medium] `NOP` — Description drops FX conversion detail. Dealing wiki: 'Net Open Position in USD for open positions in the group. (Tier 2 -- SP_DailyZeroPnL_Stocks, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion)'. BI_DB wiki omits 'via FX conversion' — semantically important for analysts interpreting USD values.
5. [medium] `OpenPositionValue` — Description semantic drift from upstream. Dealing wiki: 'computed from NOP and FX rate'. BI_DB wiki: 'units × price'. These are not equivalent — the actual computation uses NOP and FX-rate conversion, not raw units × price multiplication.

Tier 1 paraphrasing failures (must be fixed verbatim):

- **InstrumentType**:
  - Upstream: `Instrument type string (Stock / ETF). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.InstrumentType)`
  - You wrote: `Instrument type string (Stocks / ETF); only values 5=Stocks and 6=ETF are present. (Tier 2 — SP_DailyZeroPnL_Stocks)`
  - Loss: Should be Tier 1 citing Dealing wiki; dropped source-column reference; 'Stock' rendered as 'Stocks'
- **UpdateDate**:
  - Upstream: `Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DailyZeroPnL_Stocks, GETDATE())`
  - You wrote: `Batch execution timestamp (GETDATE()). (Tier 2 — SP_DailyZeroPnL_Stocks)`
  - Loss: Tier 3 downgraded to Tier 2; GETDATE() is canonical batch metadata and the Dealing wiki explicitly marks it Tier 3
- **Industry**:
  - Upstream: `Industry classification of the instrument (from Dim_Instrument). (Tier 2 -- SP_DailyZeroPnL_Stocks, DWH_dbo.Dim_Instrument.Industry)`
  - You wrote: `Industry classification of the instrument (from Dim_Instrument). (Tier 2 — SP_DailyZeroPnL_Stocks)`
  - Loss: Should be Tier 1 (mirror passthrough from Dealing); dropped source-column reference

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
