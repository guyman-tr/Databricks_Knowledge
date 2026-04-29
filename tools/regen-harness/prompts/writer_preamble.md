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

## ⛔ TIER ASSIGNMENT — drift modes the judge will catch

The judge has caught five recurring drift modes in past harness runs. Each
mode below has a concrete pre-write check. Run the check for EVERY column
before tagging its Tier — the "I'll tag everything Tier 1 then fix it later"
shortcut is the #1 source of FAIL verdicts.

### Pre-write verification (per column, in order)

1. **Element-row check** — Does an upstream wiki in the bundle contain a row
   for THIS exact column name in its Element table?
   - YES → eligible for Tier 1, continue to step 2.
   - NO → NOT Tier 1 regardless of JOIN graph. Drop to step 3.
2. **Computation check** — Does the SP body apply ANY of these to this
   column? `CASE WHEN` · `COALESCE`/`ISNULL` with branching · arithmetic
   (`+ - * /`, `GREATEST`, `LEAST`, `ROUND`, `ABS`) · aggregate
   (`SUM`/`COUNT`/`MAX`/`AVG` over `GROUP BY`) · string transform
   (`CONCAT`, `SUBSTRING`, `REPLACE`) · `CAST`/`CONVERT` changing precision ·
   JOIN-derived flag (`CASE WHEN j.x IS NOT NULL THEN 1 ELSE 0`).
   - YES → **Tier 2** with the transform named. Wiki presence of the input
     column is IRRELEVANT — the column itself is ETL-computed.
   - NO → Tier 1 (true passthrough). Continue to step 3.
3. **Relay-vs-root check** — Walk the citation chain. If `Dim_Foo` passes
   `Dictionary.Foo.Value` through unchanged AND both have wikis, cite
   `Dictionary.Foo` (root), NOT `Dim_Foo` (relay). If you cite `Wiki_X`
   for column `C` and `Wiki_X.Element_table` does NOT contain a row for `C`,
   that citation is fabricated — downgrade to Tier 2 with note `inferred
   from JOIN context, not present in upstream wiki`.
4. **Verbatim copy** — for every Tier 1 row, open the upstream wiki, locate
   the column row, COPY-PASTE its Description. Preserve abbreviation
   expansions (`FTD = First Time Deposit`), dictionary value=ID mappings
   (`5 = Stocks, 6 = ETF`), clarifying phrases (`via FX conversion`,
   `computed from NOP and FX rate`). The Section 4 brevity cap (`one
   sentence`) lets you condense ETL-computed descriptions; it does NOT let
   you summarise verbatim Tier 1 quotes.

### The five drift modes — explicit prohibitions

- **Mode A · Fabricated Tier 1.** When the bundle contains
  `_no_upstream_found.txt`, OR the bundle's "Upstream Wikis Found" header
  reads `**NO UPSTREAM WIKI**`, you may NOT mark ANY column Tier 1. Tag
  every passthrough as Tier 2 with the writer SP as source. The judge greps
  the bundle for these markers before scoring you.
- **Mode B · Migration mirror.** If `_upstream_resolution.json` lists any
  entry under `migration_mirrors_discovered` (e.g. `Dealing_dbo.Dealing_X`
  for `BI_DB_dbo.BI_DB_X`), treat the mirror's wiki as the CANONICAL Tier 1
  source for every column. The mirror's internal tier does NOT cascade — a
  column the mirror marks Tier 2 is Tier 1 in YOUR wiki because YOUR
  immediate upstream IS the mirror itself.
- **Mode C · Hybrid tier label.** Exactly one tier per Element row. Format
  `(Tier N — source)`. NEVER `(Tier 1 — Dim_X, Tier 2 in source: SP_Y)`,
  NEVER `(Tier 1/2 — X)`, NEVER `(Tier 1 — X via Y)`. When you're torn
  between two tiers, default to the WEAKER (higher number). If you must
  capture nuance, put it in `{Object}.review-needed.md` under
  `## Tier rationale`, NOT in the Element row.
- **Mode D · Computed mistagged as passthrough.** "Passthrough" means the SP
  writes `INSERT … SELECT col FROM src` with NO function on the SELECT side.
  `SELECT GREATEST(d1, d2) AS FirstNewFundedDate` → Tier 2.
  `SELECT CASE WHEN x THEN 1 ELSE 0 END AS IsFlag` → Tier 2.
  `SELECT CAST(x AS BIGINT) AS BigX` where upstream is `INT` → Tier 2.
- **Mode E · Paraphrase loss.** Verbatim means VERBATIM. If the upstream
  description has 9 value=ID mappings, your Tier 1 description has 9
  value=ID mappings. If the upstream says `Net Open Position in USD …
  via FX conversion`, your description includes `via FX conversion` — not
  `Net Open Position in USD`. The brevity cap is for prose, not for
  semantic content of inherited descriptions.

### Footer arithmetic check

`Tier1: N · Tier2: N · Tier3: N · Tier4: N` MUST sum to the DDL column count
AND match the Element-table tier suffix counts. The judge will fail you for
stats inconsistency even if every individual description is correct. Recount
before printing the footer.

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
