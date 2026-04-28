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

- **Schema**: `EXW_dbo`
- **Object**: `EXW_Conversion_Allowed_Country`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/EXW_dbo/EXW_Conversion_Allowed_Country/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_dbo\EXW_Conversion_Allowed_Country\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_dbo\EXW_Conversion_Allowed_Country\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_dbo\Tables\EXW_dbo.EXW_Conversion_Allowed_Country.sql`
- **No-upstream marker present**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_dbo\EXW_Conversion_Allowed_Country\regen\_no_upstream_found.txt` — object is dormant or has no resolvable upstream wiki. Footer may say `Production Source: Unknown (dormant)`. Tier 4 inferred is STILL banned — ground every column description in DDL + SP code.

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

# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_Conversion_Allowed_Country`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_Conversion_Allowed_Country.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_Conversion_Allowed_Country]
(
	[Country] [varchar](50) NULL,
	[CountryID] [int] NULL,
	[StateProvince] [varchar](100) NULL,
	[RegionByIP_ID] [int] NULL,
	[CryptoID] [int] NOT NULL,
	[Crypto] [nvarchar](256) NULL,
	[AllowedUserResource] [nvarchar](100) NULL,
	[AllowedUserTagType] [nvarchar](50) NULL,
	[AllowedUserTagValue] [nvarchar](50) NULL,
	[AllowedUserSelectedValue] [nvarchar](50) NULL,
	[FromResourceName] [nvarchar](100) NULL,
	[FromTagType] [nvarchar](50) NULL,
	[FromTagValue] [nvarchar](50) NULL,
	[FromSelectedValue] [nvarchar](50) NULL,
	[ToResourceName] [nvarchar](100) NULL,
	[ToTagType] [nvarchar](50) NULL,
	[ToTagValue] [nvarchar](50) NULL,
	[ToSelectedValue] [nvarchar](50) NULL,
	[FromConversionAllowed] [int] NULL,
	[ToConversionAllowed] [int] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CountryID] ),
	HEAP
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

Previous attempt scored **6.55** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Replace Country description with verbatim Dim_Country.Name text: 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.' Append lineage context after the quote. (2) Replace CountryID description with verbatim Dim_Country.CountryID text: 'Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer.' Append 'CountryID=0 excluded by SP WHERE clause. Distribution key for this table.' as supplementary context. (3) Add inline key=value enumeration for AllowedUserTagType, FromConversionAllowed, ToConversionAllowed. (4) Flag upstream bundle resolution gap in review-needed sidecar.

Top issues from the judge:
1. [high] `Country` — Tier 1 column paraphrased: dropped 'Unique per row.' from Dim_Country.Name upstream description. Added non-upstream lineage context inline.
2. [high] `CountryID` — Tier 1 column paraphrased: dropped '0=Not available (fallback/placeholder for users whose country cannot be determined)' sentinel semantics from Dim_Country.CountryID upstream description. Rewrote 'Primary key' to 'Primary key in Dim_Country'. Added distribution key and SP WHERE clause context that is not part of the upstream quote.
3. [medium] `Country, CountryID` — Both Tier 1 columns mix supplementary writer context into what should be a verbatim upstream quote. Lineage notes (passthrough, distribution key) should follow after the quoted text, not replace parts of it.
4. [low] `AllowedUserTagType, FromConversionAllowed, ToConversionAllowed` — Dictionary-like columns with ≤15 distinct values described in prose rather than formal inline key=value pair enumeration.
5. [low] `review-needed.md` — Upstream bundle claimed 'NO UPSTREAM WIKI was resolvable' but Dim_Country.md and Dim_State_and_Province.md exist in the repo. This discrepancy is not flagged in the review-needed sidecar.

Tier 1 paraphrasing failures (must be fixed verbatim):

- **Country**:
  - Upstream: `Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.`
  - You wrote: `Full country name in English. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country).`
  - Loss: Dropped 'Unique per row.' Added non-upstream lineage context ('Passthrough from Dim_Country (c.Name AS Country)').
- **CountryID**:
  - Upstream: `Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDe`
  - You wrote: `Primary key in Dim_Country. 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer. Distribution key for this table`
  - Loss: Dropped critical sentinel semantics: '0=Not available (fallback/placeholder for users whose country cannot be determined)'. Changed 'Primary key' to 'Primary key in Dim_Country'. Added unrelated context (distribution key, SP WHERE clause, passthrough note).

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
