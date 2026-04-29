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
- **Object**: `Dealing_CEPWeeklyAudit_ListCIDMapping`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_CEPWeeklyAudit_ListCIDMapping/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_CEPWeeklyAudit_ListCIDMapping\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_CEPWeeklyAudit_ListCIDMapping\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_CEPWeeklyAudit_ListCIDMapping]
(
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[NameListID] [int] NULL,
	[ListName] [varchar](max) NULL,
	[CID] [bigint] NULL,
	[TypeOfChange] [varchar](max) NULL,
	[LoginName] [varchar](max) NULL,
	[ChangeTime] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[FromDate] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 6 upstream wiki(s). Read EACH one in full.


### Upstream `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_Rules.md`

# Dealing_dbo.Dealing_CEPWeeklyAudit_Rules

> Weekly audit of CEP Rule definition and lifecycle changes (top-level hedging policy objects), loaded from Dealing_staging temporal/external sources by `SP_W_CEPWeeklyAudit` each Sunday.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Weekly (Sunday) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table captures **weekly** audit events for **CEP Rules** — the highest-level configuration objects in the Client Execution Platform hedging model. Each row describes a **change that occurred within the Monday–Sunday window** (`FromDate` / `ToDate`), including creates, deletes, activations, deactivations, and attribute updates (name, description, hedge server, priority).

It is the **long-history** counterpart to `Dealing_CEPDailyAudit_Rules` (daily granularity from approximately December 2023). For **September 2021 through late 2023**, this weekly table is often the **only** Synapse-native audit of rule changes at any granularity.

**Weekly vs daily — LoginName (preserve for review):** The weekly writer uses **`AppLoginName` directly** for `LoginName`. It does **not** apply the `COALESCE(AppLoginName, PreviousAppLoginName)` pattern used in the daily Rules audit. Deletion and certain history rows may therefore show **NULL `LoginName`** more often than the daily table. Treat this as an **expected behavioral difference** unless the procedure is aligned with daily logic.

## 2. Source & ETL

| Aspect | Detail |
|--------|--------|
| **Writer** | `Dealing_dbo.SP_W_CEPWeeklyAudit` |
| **Staging / external** | `Dealing_staging.External_Etoro_CEP_Rules`, `Dealing_staging.External_Etoro_History_Rules` |
| **Week boundaries** | `@weekStart` = Monday, `@weekEnd` = Sunday; changes filtered by `ChangeTime` (and deletion semantics via `SysEndTime` where applicable) |
| **Load pattern** | DELETE + INSERT for the week key |
| **SLA (typical)** | Data available Monday morning after Sunday load |

The procedure applies LAG-style comparisons over temporal history to derive `TypeOfChange` and `Comments` (previous-value context), consistent with the daily audit semantics but at weekly grain.

## 3. Synapse Design & Row Profile

| Metric | Value (as documented) |
|--------|------------------------|
| **Approx. row count** | 1,914 |
| **Date range** | 2021-09-26 → 2026-03-01 |
| **Distribution** | ROUND_ROBIN |
| **Clustered index** | `[FromDate]` ASC |
| **PII** | No |

Volume is moderate; cluster on `FromDate` supports **week-oriented** reporting. Combine with `TypeOfChange` filters for change-only extracts.

## 4. Elements

> **Confidence Tier Legend**
>
> | Tier | Meaning |
> |------|--------|
> | **Tier 1** | Confirmed from declared FK, catalog constraint, or upstream dictionary |
> | **Tier 2** | Inferred from ETL / writer procedure logic (`SP_W_CEPWeeklyAudit`) |
> | **Tier 3** | Operational parameter, runtime constant, or deployment convention |
> | **Tier 4** | ETL metadata (load timestamp, surrogate audit fields) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | Audit week start (Monday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | Audit week end (Sunday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | CEP Rule identifier; NULL for **no-change** placeholder weeks (LEFT JOIN pattern). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | Rule name at time of change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | Description | varchar(max) | YES | Rule description; for description-change events, holds the **new** value while prior text may appear in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | HedgeServerID | int | YES | Hedge server / action type identifier carried from source (`HedgeRuleActionTypeID` lineage). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | Priority | int | YES | Execution priority (lower = higher precedence). For priority-change events, holds the **new** value; old value may be in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | Event type: `New Rule`, `Rule Deleted`, `Activated`, `Deactivated`, `Name Change`, `Description Change`, `HedgeServerID Change`, `Priority Change`; NULL for no-change weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Comments | varchar(max) | YES | Previous-value context (e.g. `CONCAT('Previous X: ', prior_value)`); NULL where not applicable (e.g. simple activate/deactivate/new/delete). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | Application login from `AppLoginName` only — **no** `PreviousAppLoginName` COALESCE fallback in the weekly SP; expect more NULLs than daily audit for some deletes. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | Precise event timestamp (`SysStartTime` / `SysEndTime` lineage). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | Row load time: `GETDATE()` at SP execution. (Tier 4 — SP_W_CEPWeeklyAudit) |

## 5. Relationships & Related Objects

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Rules` | Daily counterpart; prefer for **Dec 2023+** when daily grain is required |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | Child **Coverage Profile** changes under rules |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | Mapping changes between CPs and Rules |
| `Dealing_staging.External_Etoro_CEP_Rules` | Current-state external source |
| `Dealing_staging.External_Etoro_History_Rules` | Temporal history source |

## 6. Usage & Sample Queries

- Filter **`WHERE TypeOfChange IS NOT NULL`** for dashboards that must exclude weekly **no-change** placeholders.
- When reconciling to **daily** audit, compare `RuleID` + `ChangeTime` + `TypeOfChange` semantics; allow for **NULL `LoginName`** on weekly rows where daily shows a value (COALESCE difference).
- Use this table when the question is **historical governance before daily audit existed** or **week-level** summaries.

**Sample Query 1 — Change events only, recent weeks**

```sql
SELECT FromDate,
       ToDate,
       RuleID,
       RuleName,
       TypeOfChange,
       LoginName,
       ChangeTime
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_Rules
WHERE  TypeOfChange IS NOT NULL
  AND  FromDate >= DATEADD(WEEK, -8, CAST(GETDATE() AS date))
ORDER BY ChangeTime DESC;
```

**Sample Query 2 — Full detail for one Rule across history**

```sql
SELECT FromDate,
       ToDate,
       RuleID,
       RuleName,
       Description,
       HedgeServerID,
       Priority,
       TypeOfChange,
       Comments,
       LoginName,
       ChangeTime
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_Rules
WHERE  RuleID = @RuleID
ORDER BY FromDate DESC, ChangeTime DESC;
```

**Sample Query 3 — Count of event types by year**

```sql
SELECT YEAR(FromDate) AS audit_year,
       TypeOfChange,
       COUNT(*) AS cnt
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_Rules
WHERE  TypeOfChange IS NOT NULL
GROUP BY YEAR(FromDate), TypeOfChange
ORDER BY audit_year DESC, TypeOfChange;
```

## 7. Data Quality & Operational Notes

| Topic | Guidance |
|-------|----------|
| **LoginName gaps** | Weekly SP intentionally omits `PreviousAppLoginName`; do not assume parity with daily `LoginName` population. |
| **No-change rows** | Expect NULL core attributes for weeks with no detected changes — filter them out for event-centric reporting. |
| **Eight change types** | Values align with daily Rules audit (`TypeOfChange` enumeration from SP logic). |
| **Lineage artifact** | See `Dealing_CEPWeeklyAudit_Rules.lineage.md` for column mapping and ETL flow. |

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Quality score: 8.5 / 10*

*Tier counts: Tier 2 — 11 columns; Tier 4 — 1 column*

*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_Rules — Table*


### Upstream `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPWeeklyAudit_CP`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_CP.md`

# Dealing_dbo.Dealing_CEPWeeklyAudit_CP

> Weekly audit of **Compound Property (CP)** changes in CEP — new CPs, renames, and deletions — stored with a **Monday–Sunday** week range (`FromDate` / `ToDate`). The job runs on **Sunday**; history reaches back to **Sep 2021**, well before the **daily** audit family (**Dec 2023**).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_CompoundProperties` + `External_Etoro_History_CompoundProperties` |
| **Refresh** | Weekly — **Sunday** run (Priority 0 — OpsDB / Service Broker); data typically usable **Monday** |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** audit trail for **compound property** lifecycle and **name** changes inside the CEP rule engine. Unlike **daily** tables that key on a single **`Date`**, each logical week is represented by **`FromDate`** (week **Monday**, midnight) and **`ToDate`** (week **Sunday**, midnight as stored in the SP — **not** end-of-day **23:59:59**).

**Historical coverage:** Weekly CEP audit tables were populated from **Sep 2021** onward. The **daily** **`Dealing_CEPDailyAudit_CP`** family begins **Dec 2023**; use **this** table for **pre-Dec-2023** CP change history and for a **coarser** weekly governance lens.

**No-change weeks:** The SP **`LEFT JOIN`s** a week spine (**`#FromDateToDate`**) so **every** processed week yields **at least one row** even when **no** CP changed. Those rows carry **NULL** **`TypeOfChange`**, **`CompoundPropertyID`**, etc. Filter **`WHERE TypeOfChange IS NOT NULL`** for **real** events only.

**Why it matters:** CPs sit **under** rules and **above** conditions; renaming or deleting a CP affects **which human-readable configuration** analysts see and can correlate to hedging behavior. The weekly grain is useful when **daily noise** is unnecessary or when reviewing **legacy** periods.

**Scale (documented sample):** On the order of **~641 rows** from **2021-09-26** through **2026-03-01**. **No PII** in the documented semantics.

## 2. Business Logic

- **Writer:** `Dealing_dbo.SP_W_CEPWeeklyAudit(@dd)` — computes **`@weekStart`** (**Monday**) and **`@weekEnd`** (**Sunday**) from the input date, then **DELETE + INSERT** for that week window into this table.
- **Sources:** **`External_Etoro_CEP_CompoundProperties`** (current) and **`External_Etoro_History_CompoundProperties`** (temporal history).
- **Temporal filter:** Change timestamps **`BETWEEN @weekStart AND @weekEnd`** (see SP for exact boundary treatment).
- **`RuleID` / `RuleName` / `HedgeServerID`:** Resolved via **`#Dim_CPtoRule`** / CP-to-rule log style joins — may be **NULL** on **placeholder** rows or when context is absent in the weekly path.
- **`CPName`:** Weekly column name is **`CPName`** (**no** underscore) — the **daily** table uses **`CP_Name`**; mind this when **unioning** or **cross-comparing**.
- **`TypeOfChange`:** **`New Compound Property`**, **`Name Change`**, **`Compound Property Deleted`** (from SP logic) — **NULL** for **no-change** placeholder rows.
- **`Comments`:** For **`Name Change`**, **`Previous Name: {old}`** pattern.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — fine at **hundreds** of weekly rows in sample. |
| **Clustered index** | **`FromDate` ASC** — filter on **`FromDate`** (week start) for predictable scans. |
| **Scale** | Small — no special performance playbook required. |

### 3.2 Recommended patterns

- **`WHERE FromDate = @WeekStartMonday`** to pull **one** audit week (knowing **`ToDate`** is the paired Sunday marker).
- **`WHERE FromDate BETWEEN @Start AND @End`** for **multi-week** reviews.
- **`WHERE TypeOfChange IS NOT NULL`** to drop **placeholder** “no change” rows.

### 3.3 Freshness

- **Weekly Sunday** execution; treat **`max(FromDate)`** near the **most recent completed week** as health signal (documented sample **2026-03-01** week start).

### 3.4 Gotchas

- **`ToDate`** is stored as **Sunday 00:00:00** — do **not** assume **inclusive end-of-Sunday** without adjusting predicates.
- **Column name drift** — **`CPName`** vs daily **`CP_Name`**.
- **Do not** interpret **NULL** **`TypeOfChange`** rows as “silent deletes” — they are **structural placeholders** for empty weeks.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Week start** — **Monday 00:00:00** for the audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Week end marker** — **Sunday 00:00:00** as derived in the SP (**six** days after **`FromDate`** in the documented logic), **not** **23:59:59**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **Rule** associated with the CP context when resolved; **NULL** on **no-change** placeholders or when not resolved. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Denormalized rule name** for the **`RuleID`** context. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | CompoundPropertyID | int | YES | **CP** identifier that changed — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CPName | varchar(max) | YES | **CP display name** — weekly column name (**`CPName`**) differs from **daily** **`CP_Name`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | HedgeServerID | int | YES | **Hedge server** of the parent rule context when present. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | **`New Compound Property`**, **`Name Change`**, **`Compound Property Deleted`**, or **NULL** for **placeholder** rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Comments | varchar(max) | YES | **`Previous Name: …`** text for **`Name Change`**; otherwise **NULL**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | **CEP application login** for the change — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | **Source event timestamp** — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** — **ETL metadata**. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
Dealing_staging.External_Etoro_CEP_CompoundProperties  (current)
Dealing_staging.External_Etoro_History_CompoundProperties  (history)
    ↓
SP_W_CEPWeeklyAudit(@dd)
    — @weekStart = Monday, @weekEnd = Sunday
    — ChangeTime BETWEEN @weekStart AND @weekEnd
    — LEFT JOIN #FromDateToDate guarantees one row per week (nullable if no changes)
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_CP  ← DELETE + INSERT for (@weekStart, @weekEnd)
```

**Column lineage (summary):** `FromDate` / `ToDate` ← **SP week boundaries**; CP fields ← **`#CPChangesFinal` / `#CPLog`**; rule context ← **`#Dim_CPtoRule`**; `TypeOfChange` / `Comments` ← **SP derivation**; `UpdateDate` ← **`GETDATE()`**.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **Daily** counterpart (**`Date`** grain, **Dec 2023+**). |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | **Weekly** **CP↔rule** mapping changes — same **`FromDate`/`ToDate`** convention. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Weekly** condition-level changes in the same engine. |
| `Dealing_staging.External_Etoro_CEP_CompoundProperties` | **Current** CP **source**. |
| `Dealing_staging.External_Etoro_History_CompoundProperties` | **Temporal history** **source**. |

## 7. Sample Queries

**7.1 — Real CP changes for one audit week**

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CPName
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE FromDate = '2026-03-01'   -- illustrative week key (align with sampled max FromDate)
  AND TypeOfChange IS NOT NULL
ORDER BY ChangeTime, CompoundPropertyID;
```

**7.2 — CP renames across a multi-month window**

```sql
SELECT
      FromDate
    , CompoundPropertyID
    , CPName
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP
WHERE TypeOfChange = 'Name Change'
  AND FromDate >= '2025-01-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — Weekly CP events alongside CP-to-rule events (same week)**

```sql
SELECT
      cp.FromDate
    , cp.CompoundPropertyID
    , cp.TypeOfChange   AS CP_Event
    , m.TypeOfChange    AS CPToRule_Event
    , m.RuleID
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP AS cp
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule AS m
       ON m.FromDate = cp.FromDate
      AND m.CompoundPropertyID = cp.CompoundPropertyID
WHERE cp.FromDate = '2026-03-01'
  AND cp.TypeOfChange IS NOT NULL
ORDER BY cp.CompoundPropertyID, m.RuleID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: CEP audit wiki reformat*  
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_CP | Type: Table | Production Source: Dealing_staging CEP CompoundProperties + history*


### Upstream `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_Conditions.md`

# Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

> Weekly audit of **CEP Condition definition** changes — edits to the atomic **Property**, **Operator**, and **Value** that make up each condition, rolled up to a **Monday–Sunday** window.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal / external tables + condition dictionaries |
| **Refresh** | Weekly (Sunday batch; OpsDB Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **Approx. row count** | ~12,333 |
| **Sample date range** | 2021-09-26 → 2026-03-01 (via `FromDate`) |
| **PII** | No |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** counterpart to **`Dealing_dbo.Dealing_CEPDailyAudit_Conditions`**. Each row describes a **change to an atomic CEP condition** during an audit week: **property**, **operator**, or **value** edits, **new condition** creation, or **condition deletion**. Conditions are the **predicates** that sit under **Compound Properties** and **Rules** in the CEP hedging configuration.

**Weekly grain:** Rows are keyed to **`FromDate`** (Monday) and **`ToDate`** (Sunday). As with other weekly CEP audit siblings, the load can produce rows where **`TypeOfChange` is NULL** to represent **weeks with no change** for a given join path — use **`WHERE TypeOfChange IS NOT NULL`** for event-only extracts.

**Volume signal:** On the order of **tens of thousands** of rows across **~230 weeks** implies **material ongoing tuning** of rule logic (especially **value** adjustments). That is **expected** for an active rules engine; compare to the **daily** table when you need **finer-than-week** timing.

**Why it matters:** Mis-set thresholds or wrong operators drive **silent** behavior changes. This audit preserves **who** changed **what**, **when**, and (via **`Comments`**) often the **prior** value for before/after reasoning.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_Conditions` and `Dealing_staging.External_Etoro_History_Conditions`, joined in **`SP_W_CEPWeeklyAudit`** with **dictionary** resolution:
  - **`External_Etoro_Dictionary_ConditionProperties`** → readable **`Property`** names.
  - **`External_Etoro_Dictionary_ConditionOperators`** → readable **`Operator`** names.
- **Change taxonomy (weekly, same family as daily):** `Property Change`, `Operator Change`, `Value Change`, `New Condition`, `Condition Deleted` — all emitted as **`TypeOfChange`** literals from the SP.
- **`Comments`:** For change rows, carries **previous value** context (e.g. previous property/operator/value text). May be **NULL** for pure create/delete paths depending on SP branch.
- **Rule context:** **`RuleID`**, **`RuleName`**, **`HedgeServerID`** are resolved through the **ConditionToCP + CPToRule** style chain in the weekly job (analogous to daily), so **one condition edit** can still **fan out** if multiple rules share the wiring path the SP explodes.
- **`Value`:** Stored as **`varchar(100)`** in Synapse — treat as **opaque predicate literal** unless you parse by **`Property`** semantics in consuming code.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata** only.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN`. |
| **Clustered index** | **`FromDate` ASC** — primary slice for “which week?”. |
| **Scale** | Moderate row count — still small enough for ad hoc analytics without special tuning. |

### 3.2 Recommended patterns

- **`WHERE FromDate BETWEEN @start AND @end`** for multi-week studies; add **`AND TypeOfChange IS NOT NULL`** for real events.
- Investigate **`Comments`** side-by-side with **`Property` / `Operator` / `Value`** for **before/after** narratives.
- Join to **`Dealing_CEPWeeklyAudit_ConditionToCP`** on **`ConditionID` + FromDate** to relate **definition edits** to **CP membership** moves in the same week.

### 3.3 Freshness

- **Sunday** batch via **`Dealing_dbo.SP_W_CEPWeeklyAudit`**. Sample documentation window showed **max `FromDate` 2026-03-01** and **ACTIVE** load health.

### 3.4 Gotchas

- **`Property` / `Operator`** are **already resolved names** at ETL time — not raw enum IDs in this table.
- **High row count vs daily** is largely **longer history** (from **2021**) rather than implying the weekly table is “busier” per calendar day.
- **`TypeOfChange`** strings must match **exactly** in filters (case and spacing).

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Monday** — start of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Sunday** — end of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **Parent rule** ID resolved via weekly **ConditionToCP → CPToRule** style chain. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Rule display name**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** for the rule context. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | ConditionID | int | YES | **Condition** that was created, deleted, or had definition fields changed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | Property | varchar(max) | YES | **Attribute under test** — resolved from **`External_Etoro_Dictionary_ConditionProperties`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | Operator | varchar(max) | YES | **Comparison operator** — resolved from **`External_Etoro_Dictionary_ConditionOperators`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Value | varchar(100) | YES | **Threshold or target literal** for the predicate. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | TypeOfChange | varchar(max) | YES | One of **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`**; **NULL** for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | Comments | varchar(max) | YES | **Previous value** context such as `"Previous Property: …"`, `"Previous Operator: …"`, `"Previous Value: …"` when applicable. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | LoginName | varchar(max) | YES | **CEP application user** for the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 13 | ChangeTime | datetime | YES | **Source timestamp** of the condition event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 14 | UpdateDate | datetime | YES | **DWH insert time** from **`GETDATE()`** — not business time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

**Upstream → writer → target**

```
Dealing_staging.External_Etoro_CEP_Conditions  (current)
Dealing_staging.External_Etoro_History_Conditions  (temporal history)
Dealing_staging.External_Etoro_Dictionary_ConditionProperties
Dealing_staging.External_Etoro_Dictionary_ConditionOperators
    ↓
Dealing_dbo.SP_W_CEPWeeklyAudit
    — weekly FromDate / ToDate windowing
    — dictionary joins for Property / Operator labels
    — TypeOfChange + Comments from temporal diff semantics
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
```

**Column lineage (summary):** `FromDate` / `ToDate` ← weekly boundaries; `ConditionID`, `Value`, `ChangeTime`, `LoginName` ← conditions external / history; `Property` / `Operator` ← dictionary tables; `RuleID`, `RuleName`, `HedgeServerID` ← exploded rule context; `TypeOfChange`, `Comments` ← SP logic; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Daily** definition audit — higher **date** resolution for recent periods. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | **Membership** changes for the same **`ConditionID`** in the same week. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionProperties` | **Property** name resolution. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionOperators` | **Operator** name resolution. |

## 7. Sample Queries

**7.1 — All non-null definition events in a week**

```sql
SELECT
      FromDate
    , ToDate
    , ConditionID
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
WHERE FromDate = '2026-02-24'
  AND TypeOfChange IS NOT NULL
ORDER BY ChangeTime, ConditionID;
```

**7.2 — Value changes with previous value text**

```sql
SELECT
      FromDate
    , ConditionID
    , Property
    , Operator
    , Value
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
WHERE TypeOfChange = 'Value Change'
  AND FromDate >= '2025-06-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — New conditions in a quarter with rule context**

```sql
SELECT
      c.FromDate
    , c.ConditionID
    , c.Property
    , c.Operator
    , c.Value
    , c.RuleID
    , c.RuleName
    , c.LoginName
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions AS c
WHERE c.TypeOfChange = 'New Condition'
  AND c.FromDate >= '2025-01-01'
  AND c.FromDate < '2025-04-01'
ORDER BY c.FromDate, c.ConditionID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Weekly CEP audit family*  
*Tiers: 0 T1, 13 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions | Type: Table | Source: Dealing_staging CEP temporal / external + dictionaries*


### Upstream `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_ConditionToCP.md`

# Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

> Weekly audit of **Condition-to-Compound Property (CP)** mapping changes in CEP — when atomic rule conditions are added to or removed from a CP’s condition bundle, aggregated to a **Monday–Sunday** window.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal / external tables |
| **Refresh** | Weekly (Sunday batch; OpsDB Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **Approx. row count** | ~4,514 |
| **Sample date range** | 2021-09-26 → 2026-03-01 (via `FromDate`) |
| **PII** | No |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** counterpart to **`Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`**. It records **which CEP conditions were linked to or unlinked from a Compound Property (CP)** during each audit week. **`ConditionID` + `CP_Name` (and `CompoundPropertyID`)** identifies the membership edge that changed; **`RuleID` / `RuleName` / `HedgeServerID`** place that CP in **rule** context.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)
        └── Condition   ← ConditionToCP membership audited here
```

**Weekly grain:** Each row is tied to **`FromDate`** (week start, Monday) and **`ToDate`** (week end, Sunday). The ETL uses a **LEFT JOIN** pattern that can emit **placeholder rows** with **`TypeOfChange` NULL** for weeks with **no** membership change for a given key path. For analysis, **`WHERE TypeOfChange IS NOT NULL`** restricts to real events.

**Why it matters:** Membership edits change **which atomic predicates** participate in a CP bundle — a common root cause when hedging or routing behaves differently than expected. Weekly history extends **back to September 2021**, roughly **two years earlier** than the daily audit table’s typical window, which helps long-horizon investigations.

**Load pattern:** **`Dealing_dbo.SP_W_CEPWeeklyAudit`** loads this table together with sibling weekly CEP audit tables from **`Dealing_staging`** externals and temporal history. Refresh aligns to the **Sunday** weekly job.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` (current) and `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` (temporal history).
- **Change typing:** The SP classifies rows as **`Condition Added To CP`** or **`Condition Removed from CP`** from temporal validity boundaries aggregated to the week; exact predicates mirror the weekly SP logic (SysStart/SysEnd style semantics rolled to **`FromDate` / `ToDate`**).
- **Rule context:** **`RuleID`**, **`RuleName`**, **`HedgeServerID`** are resolved through the same **CP-to-rule** style dimension chain used in the daily pipeline (weekly build in **`SP_W_CEPWeeklyAudit`**). A CP attached to **multiple rules** can still produce **multiple rows** for one underlying membership change.
- **No-change weeks:** Expect **`TypeOfChange` NULL** rows from the outer join scaffolding — **not** application nulls; filter them out for change-only reporting.
- **`UpdateDate`:** Set in the SP with **`GETDATE()`** — **DWH load metadata**, not the CEP business timestamp (use **`ChangeTime`** for source time).

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for modest audit volume. |
| **Clustered index** | **`FromDate` ASC** — aligns with “which week?” filters. |
| **Scale** | Low thousands of rows — routine filters on week or change type are inexpensive. |

### 3.2 Recommended patterns

- Filter **`WHERE FromDate = @weekStart`** (Monday) **or** a **`FromDate` range** for multi-week reviews.
- Always consider **`AND TypeOfChange IS NOT NULL`** when counting **events** rather than **scaffold rows**.
- Join to **`Dealing_CEPWeeklyAudit_Conditions`** on **`ConditionID`** (and overlapping week) for **Property / Operator / Value** semantics.
- Compare to **`Dealing_CEPDailyAudit_ConditionToCP`** when you need **calendar-day** precision for recent periods.

### 3.3 Freshness

- Treated as **ACTIVE** in documentation sampling (**max `FromDate` 2026-03-01** in the captured stats). New weeks appear after each **Sunday** successful run of **`SP_W_CEPWeeklyAudit`**.

### 3.4 Gotchas

- **`TypeOfChange`** literals are **exact** (spacing and casing): **`Condition Added To CP`**, **`Condition Removed from CP`**.
- **Fan-out across rules** can duplicate logical membership events — validate with **`RuleID`** when deduplicating.
- **Do not** interpret **`ToDate`** alone as “change happened at end of Sunday” without reading **`ChangeTime`** — **`ToDate`** bounds the **audit window**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Start of the audit week (Monday)** — lower bound of the weekly window written by **`SP_W_CEPWeeklyAudit`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **End of the audit week (Sunday)** — upper bound of the weekly window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **CEP Rule** whose CP gained or lost the condition — from weekly CP-to-rule resolution in the SP. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Human-readable rule name** denormalized for reporting. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** associated with the rule context. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CompoundPropertyID | int | YES | **Compound Property** that gained or lost the **condition**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | CP_Name | varchar(max) | YES | **CP display name** for analyst-friendly output. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | ConditionID | int | YES | **Condition** added to or removed from the CP — join to **weekly conditions audit** for predicate detail. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **`Condition Added To CP`** or **`Condition Removed from CP`**; **NULL** for **no-change** placeholder weeks from the outer join pattern. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | **CEP application user** attributed to the change (temporal / login resolution per SP). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | **Source-system timestamp** of the membership event (add vs remove path per SP). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | **Row insert time** in the warehouse via **`GETDATE()`** in the SP — not the business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

**Upstream → writer → target**

```
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (temporal history)
    ↓
Dealing_dbo.SP_W_CEPWeeklyAudit
    — weekly aggregation to FromDate / ToDate (Monday–Sunday)
    — CP / rule context joins (weekly analog to daily CP-to-rule resolution)
    — TypeOfChange derived from temporal add/remove semantics
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
```

**Column lineage (summary):** `FromDate` / `ToDate` ← weekly window boundaries from the SP; `CompoundPropertyID`, `ConditionID`, `LoginName`, `ChangeTime` ← condition-to-CP external / history; `RuleID`, `RuleName`, `HedgeServerID` ← CP-to-rule chain in weekly build; `CP_Name` ← CP naming resolution; `TypeOfChange` ← SP classification; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` | **Daily** audit of the same event family — use for day-level drill-down on recent history. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Condition definition** changes — predicate semantics for **`ConditionID`**. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | **CP-level** weekly audit — sibling entity in the same weekly job. |
| `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | **Current** condition-to-CP links. |
| `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | **Temporal history** of links. |

## 7. Sample Queries

**7.1 — Real membership changes in one audit week**

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
WHERE FromDate = '2026-02-24'   -- example Monday
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

**7.2 — Removals over a multi-month window**

```sql
SELECT
      FromDate
    , ToDate
    , ConditionID
    , CompoundPropertyID
    , CP_Name
    , RuleID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
WHERE TypeOfChange = 'Condition Removed from CP'
  AND FromDate >= '2025-10-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — Weekly removal plus condition definition context**

```sql
SELECT
      m.FromDate
    , m.ToDate
    , m.ConditionID
    , m.TypeOfChange      AS MembershipChange
    , c.Property
    , c.Operator
    , c.Value
    , c.TypeOfChange      AS DefinitionChange
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP AS m
LEFT JOIN Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions AS c
       ON c.ConditionID = m.ConditionID
      AND c.FromDate = m.FromDate
WHERE m.TypeOfChange = 'Condition Removed from CP'
  AND m.FromDate >= '2025-01-01'
ORDER BY m.FromDate DESC, m.ConditionID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Weekly CEP audit family*  
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Writer: Dealing_dbo.SP_W_CEPWeeklyAudit*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP | Type: Table | Source: Dealing_staging CEP temporal / external*


### Upstream `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_CPToRule.md`

# Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

> Weekly audit of **compound-property-to-rule** mapping changes in CEP — when a CP is **added** or **removed** from a rule, or when the **`IsTrue`** polarity (**must evaluate true** vs **not true**) flips. Written by the same **Sunday** weekly job as other **`CEPWeeklyAudit_***` tables; history from **Sep 2021** predates the **daily** family (**Dec 2023**).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` + `External_Etoro_History_CompoundPropertyToRule` |
| **Refresh** | Weekly — **Sunday** run (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table records **how CPs are wired into rules** over **weekly** windows. Each **real** event row describes **attachment**, **detachment**, or a **boolean polarity** change (**`IsTrue`**) for a **`CompoundPropertyID`** under a **`RuleID`**. The grain is **`FromDate` / `ToDate`** (**Monday** / **Sunday** markers) rather than a single calendar **`Date`**.

**Volume note:** In the documented sample this is the **largest** **CEPWeeklyAudit** table (**~51,076 rows** over **2021-09-26 → 2026-03-01**), mirroring the pattern in the **daily** family where **CP-to-rule** churn is typically **highest**. Frequent Dealing configuration tuning can produce **many** mapping rows per week.

**Overlap with daily:** For periods **after Dec 2023**, **`Dealing_CEPDailyAudit_CPToRule`** offers **per-day** detail; this **weekly** table remains a **rollup** and carries **only** weekly history for **pre-daily** eras.

**No-change weeks:** As with other weekly CEP audit tables, **`LEFT JOIN`** logic can emit **placeholder** rows with **`TypeOfChange IS NULL`** — always filter when you need **true** mapping events.

**Why it matters:** Incorrect or volatile **CP-to-rule** wiring is a common explanation for **“the rule looked right but hedged wrong”** incidents. This audit preserves **who** changed **what** and **when** at the **mapping** grain.

## 2. Business Logic

- **Writer:** `Dealing_dbo.SP_W_CEPWeeklyAudit(@dd)` — shared with all **weekly** CEP audit targets; **DELETE + INSERT** per computed week.
- **Sources:** **`External_Etoro_CEP_CompoundPropertyToRule`** and **`External_Etoro_History_CompoundPropertyToRule`**.
- **Event windows:** **`SysStartTime`** in the week → **add / value change** style paths; **`SysEndTime`** in the week with **`RN_desc = 1`** → **removal** style path (see SP for exact classification).
- **`TypeOfChange` values** (documented): **`CP Added to Rule`**, **`CP Removed from Rule`**, **`Mapping Changed from Not True to True`**, **`Mapping Changed from True to Not True`** — **NULL** for **no-change** placeholders.
- **`IsTrue`:** **`bit`** — **1** means the CP must evaluate **true** inside the rule bundle polarity; **0** means **not true** — identical **business meaning** to the **daily** sibling.
- **`CP_Name`:** Uses **underscore** form here (**`CP_Name`**) unlike **`Dealing_CEPWeeklyAudit_CP.CPName`** — intentional **cross-table naming inconsistency** to flag for analysts.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — acceptable at **tens of thousands** of rows for audit-style filters. |
| **Clustered index** | **`FromDate` ASC** — primary filter for **week** selection. |
| **Scale** | Moderate — still **small** by DWH standards; avoid **full scans** only if you add broad analytics without predicates. |

### 3.2 Recommended patterns

- **`WHERE FromDate = @WeekStart AND TypeOfChange IS NOT NULL`** for a **clean** weekly event list.
- **`WHERE CompoundPropertyID = @cp`** across **`ORDER BY FromDate`** for **CP-centric** history (weekly grain).
- Join **`Dealing_CEPWeeklyAudit_Rules`** on **`RuleID` + week** for **rule-name** stability checks when needed.

### 3.3 Freshness

- **Weekly Sunday** batch; compare **`max(FromDate)`** to the latest **completed** business week (documented sample **2026-03-01**).

### 3.4 Gotchas

- **High row counts** are **often normal** — mapping churn is **structurally frequent** in CEP.
- **Duplicate-looking** rows across **`RuleID`** may reflect **legitimate** repeated adjustments — validate with **`ChangeTime`** and **`TypeOfChange`**.
- Do not confuse **`CP_Name`** here with **`CPName`** in **`Dealing_CEPWeeklyAudit_CP`**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_W_CEPWeeklyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | **Week start** (**Monday 00:00:00**) for the audit bucket. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | **Week end marker** (**Sunday**) paired with **`FromDate`** per SP derivation. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | **CEP Rule** receiving the mapping change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | **Human-readable rule name** denormalized onto the event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** context for the rule (**from dimension join path** in SP). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | CompoundPropertyID | int | YES | **Compound property** participating in the mapping. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | CP_Name | varchar(max) | YES | **CP name** — note **`CP_Name`** here vs **`CPName`** in **`Dealing_CEPWeeklyAudit_CP`**. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | IsTrue | bit | YES | **Polarity** — **1** = must evaluate **true**, **0** = **not true** in rule logic. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **`CP Added to Rule`**, **`CP Removed from Rule`**, **`Mapping Changed from Not True to True`**, **`Mapping Changed from True to Not True`**, or **NULL** for placeholders. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | **CEP application user** attributed to the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | **Source temporal timestamp** for the mapping event. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | **`GETDATE()`** at SP run — **load metadata**, not business time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule
Dealing_staging.External_Etoro_History_CompoundPropertyToRule
    ↓
SP_W_CEPWeeklyAudit(@dd) — @weekStart to @weekEnd window
    — SysStartTime BETWEEN @weekStart AND @weekEnd → Added/ValueChange
    — SysEndTime BETWEEN @weekStart AND @weekEnd AND RN_desc=1 → Removed
    — LEFT JOIN #FromDateToDate → always one row per week
    ↓
Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule  ← DELETE + INSERT for week
```

**Column lineage (summary):** `FromDate` / `ToDate` ← **week parameters**; `RuleID`, mapping keys, `IsTrue`, timestamps ← **CP-to-rule** externals / history and **`#CPToRule_Log`**; `RuleName`, `HedgeServerID`, `CP_Name` ← **SP staging tables**; `TypeOfChange` ← **derivation**; `UpdateDate` ← **`GETDATE()`**.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **Daily** mapping audit (**Dec 2023+**) — finer grain for recent periods. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | **Weekly CP** entity changes — same week keys. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | **Weekly rule** shell changes — join on **`RuleID`** + week. |
| `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` | **Current** mapping **source**. |
| `Dealing_staging.External_Etoro_History_CompoundPropertyToRule` | **Temporal history** **source**. |

## 7. Sample Queries

**7.1 — All mapping events for one audit week (real rows only)**

```sql
SELECT
      FromDate
    , ToDate
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , IsTrue
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE FromDate = '2026-03-01'
  AND TypeOfChange IS NOT NULL
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

**7.2 — Polarity flips (True ↔ Not True) in the last year of weeks**

```sql
SELECT
      FromDate
    , RuleID
    , CompoundPropertyID
    , CP_Name
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE TypeOfChange IN (
        'Mapping Changed from Not True to True'
      , 'Mapping Changed from True to Not True'
    )
  AND FromDate >= '2025-01-01'
ORDER BY FromDate DESC, ChangeTime DESC;
```

**7.3 — CP-centric weekly history**

```sql
SELECT
      FromDate
    , RuleID
    , RuleName
    , TypeOfChange
    , IsTrue
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
WHERE CompoundPropertyID = @CompoundPropertyID
  AND TypeOfChange IS NOT NULL
ORDER BY FromDate, ChangeTime;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Batch: CEP audit wiki reformat*  
*Tiers: 0 T1, 11 T2, 0 T3, 1 T4 | Elements: 7.8/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule | Type: Table | Production Source: Dealing_staging CEP CompoundPropertyToRule + history*


### Upstream `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_NameLists.md`

# Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists

> Weekly audit of CEP Named List definition and membership changes, loaded from Dealing_staging temporal/external sources by `SP_W_CEPWeeklyAudit` each Sunday.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Weekly (Sunday) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** change log for **CEP Named Lists** — collections of customer IDs (CIDs) referenced by CEP rule conditions. It records when lists are created, when CID membership changes, and when lists are deleted, scoped to a **Monday–Sunday** audit week (`FromDate` / `ToDate`).

It is the historical sibling of `Dealing_CEPDailyAudit_NameLists` (daily, from approximately December 2023 onward). For **September 2021 through late 2023**, this weekly table may be the only Synapse audit trail for Named List events, subject to the data-quality caveat below.

**Suspected writer defect (preserve for review):** In `Dealing_dbo.SP_W_CEPWeeklyAudit`, the NameLists path around **line 878** uses a **LEFT JOIN** whose second predicate is effectively `fdtd.ToDate = fdtd.ToDate` (self-join) instead of matching `fdtd.ToDate` to the change row’s `ToDate` (e.g. `rcf.ToDate`). That condition is always true and can cause **every week to emit rows** with **NULL change attributes** (placeholder rows) rather than only emitting placeholders when there were genuinely no changes. **Validate before treating this table as authoritative:** compare to daily audit where available, and check whether `TypeOfChange` is ever populated.

## 2. Source & ETL

| Aspect | Detail |
|--------|--------|
| **Writer** | `Dealing_dbo.SP_W_CEPWeeklyAudit` |
| **Staging / external** | `Dealing_staging.External_Etoro_CEP_NamedLists`, `Dealing_staging.External_Etoro_History_NamedLists` |
| **Load pattern** | DELETE + INSERT for the target audit week |
| **Ops context** | Weekly Sunday job (Priority 0 in orchestration metadata where applicable) |

Intermediate logic builds `#NameLists_ChangesFinal` from a week-window filter on temporal history, then inserts into this table. Exact predicates and join keys are documented in the paired `.lineage.md` file (not modified here).

## 3. Synapse Design & Row Profile

| Metric | Value (as documented) |
|--------|------------------------|
| **Approx. row count** | 698 |
| **Date range** | 2021-09-26 → 2026-03-01 |
| **Distribution** | ROUND_ROBIN |
| **Clustered index** | `[FromDate]` |
| **PII** | No |

The table is small; routine reporting and ad hoc filters on `FromDate` / `ToDate` are not expected to stress the pool. Prefer **narrow date filters** for consistency with other audit tables.

## 4. Elements

> **Confidence Tier Legend**
>
> | Tier | Meaning |
> |------|--------|
> | **Tier 1** | Confirmed from declared FK, catalog constraint, or upstream dictionary |
> | **Tier 2** | Inferred from ETL / writer procedure logic (`SP_W_CEPWeeklyAudit`) |
> | **Tier 3** | Operational parameter, runtime constant, or deployment convention |
> | **Tier 4** | ETL metadata (load timestamp, surrogate audit fields) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | Start of the audit week (Monday). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | End of the audit week (Sunday). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | NameListID | int | YES | Named List identifier from CEP. May be NULL if rows are placeholders from the suspected line-878 JOIN issue. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | Name | varchar(max) | YES | Named List display name. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | TypeOfChange | varchar(max) | YES | Change category: e.g. `New Name List`, `Change In CIDs`, `Name List Deleted`. May be NULL for placeholder rows or if the JOIN bug prevents propagation. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | LoginName | varchar(max) | YES | Application login associated with the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | ChangeTime | datetime | YES | Event time from temporal columns (`SysStartTime` / `SysEndTime` lineage). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | UpdateDate | datetime | YES | Row load time: `GETDATE()` at SP execution. (Tier 4 — SP_W_CEPWeeklyAudit) |

## 5. Relationships & Related Objects

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_NameLists` | Daily counterpart; **preferred** for Named List lifecycle from ~Dec 2023 when non-null change rows exist there |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` | Per-CID mapping changes for the same weekly job; documented as not sharing the NameLists JOIN defect |
| `Dealing_staging.External_Etoro_CEP_NamedLists` | Current-state external source |
| `Dealing_staging.External_Etoro_History_NamedLists` | Temporal history source |

## 6. Usage & Sample Queries

- Treat `TypeOfChange IS NOT NULL` as the primary filter for **real** change events once data quality is confirmed.
- For governance reporting after daily audit exists, **reconcile** weekly rows against `Dealing_CEPDailyAudit_NameLists` for overlapping periods.
- **Do not** assume completeness of `LoginName` or `TypeOfChange` until the line-878 hypothesis is ruled in or out.

**Sample Query 1 — Weeks with any non-null change type (data-quality probe)**

```sql
SELECT DISTINCT
       FromDate,
       ToDate,
       COUNT(*) AS row_cnt
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
WHERE  TypeOfChange IS NOT NULL
GROUP BY FromDate, ToDate
ORDER BY FromDate DESC;
```

**Sample Query 2 — Latest week raw extract**

```sql
SELECT TOP (500) *
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
WHERE  FromDate = (SELECT MAX(FromDate) FROM Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists)
ORDER BY ChangeTime;
```

**Sample Query 3 — Named List history for one ID (if populated)**

```sql
SELECT FromDate,
       ToDate,
       NameListID,
       Name,
       TypeOfChange,
       LoginName,
       ChangeTime
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
WHERE  NameListID = @NameListID   -- parameter
ORDER BY FromDate DESC, ChangeTime DESC;
```

## 7. Data Quality & Operational Notes

| Topic | Guidance |
|-------|----------|
| **JOIN bug hypothesis** | Re-read `SP_W_CEPWeeklyAudit` near **line 878**; confirm whether `fdtd.ToDate` should join to `rcf.ToDate`. |
| **Placeholder rows** | If `TypeOfChange` is always NULL, the table may contain no usable change facts until the procedure is corrected. |
| **Authority** | Use daily audit where available; use this table for **pre-daily** history with explicit validation. |
| **Lineage artifact** | Column-level flow and the JOIN warning are recorded in `Dealing_CEPWeeklyAudit_NameLists.lineage.md`. |

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Quality score: 7.5 / 10*

*Tier counts: Tier 2 — 7 columns; Tier 4 — 1 column*

*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists — Table*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_W_CEPWeeklyAudit`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_W_CEPWeeklyAudit.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_W_CEPWeeklyAudit] @dd [date] AS
--EXEC   [dbo].[SP_W_CEPWeeklyAudit]    '20231118'
/******************************************************************************************************************************
Author: Jenia Simonovitch
Date: 26.09.21
 
**************************
** Change History
**************************
Date		  Author   SR			  Description 
----------	  -------- ------------ ------------------------------------
2021-10-12	  Jenia	    			 Changed the logic so there will be an empty row with FromDate and ToDate for each table if there were no changes during the period 
2023-11-21	  Ziv	   SR-219237	 Migration to synapse
*******************************************************************************************************************************/

/************************************************Declare Parameters**********************************************************************/
BEGIN

-----------------------------------------------------------------------------------------
--DECLARE @dd date = DATEADD(DAY,-1,GETDATE()) 
DECLARE @weekStart date = DATEADD(DAY,1,DATEADD(WW,-1,@dd))  
DECLARE @weekEnd date = DATEADD(DAY,6,@weekStart)  

---------------------------------------------------------------------
--Rules
IF OBJECT_ID('tempdb..#RulesLog') IS NOT NULL 
DROP TABLE #RulesLog  
CREATE TABLE #RulesLog
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
	RuleID,
	Name,
	LAG(Name,1) OVER (PARTITION BY r.RuleID ORDER BY r.SysStartTime) PreviousName,
	r.Description,
	LAG(r.Description,1) OVER (PARTITION BY r.RuleID ORDER BY r.SysStartTime) PreviousDescription,
	r.IsActive,
	LAG(r.IsActive,1) OVER (PARTITION BY r.RuleID ORDER BY r.SysStartTime) PreviousIsActive,
	r.HedgeRuleActionTypeID HedgeServerID,
	LAG(r.HedgeRuleActionTypeID,1) OVER (PARTITION BY r.RuleID ORDER BY r.SysStartTime) PreviousHedgeServerID,
	r.Priority,
	LAG(r.Priority,1) OVER (PARTITION BY r.RuleID ORDER BY r.SysStartTime) PreviousPriority,
	r.AppLoginName,
	r.SysStartTime,
	r.SysEndTime,
	ROW_NUMBER() OVER (PARTITION BY r.RuleID ORDER BY r.SysStartTime) RN,
	ROW_NUMBER() OVER (PARTITION BY r.RuleID ORDER BY r.SysEndTime DESC) RN_Desc,
	r.ValidFrom
 
FROM 
(
SELECT * 
FROM [Dealing_staging].[External_Etoro_CEP_Rules]
UNION ALL 
SELECT * 
FROM [Dealing_staging].[External_Etoro_History_Rules]
) r
 WHERE r.Name<>' '
 
 

--RulesAudit1
IF OBJECT_ID('tempdb..#RulesAudit1') IS NOT NULL 
DROP TABLE #RulesAudit1
CREATE TABLE #RulesAudit1
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

 SELECT
 ra.RuleID
,ra.Name
,ra.PreviousName
,CASE WHEN ra.Name<>ra.PreviousName  AND ra.PreviousName IS NOT NULL then 1 ELSE 0 END NameChange
,ra.Description
,ra.PreviousDescription
,CASE WHEN ra.Description<>ra.PreviousDescription  AND ra.PreviousDescription IS NOT null then 1 ELSE 0 END DescriptionChange
,ra.IsActive
,ra.PreviousIsActive
,CASE WHEN ra.IsActive<>ra.PreviousIsActive AND ra.PreviousIsActive IS NOT NULL THEN 1 else 0 END IsActiveChange
,ra.HedgeServerID
,ra.PreviousHedgeServerID
,CASE WHEN ra.HedgeServerID<>ra.PreviousHedgeServerID AND ra.PreviousHedgeServerID IS NOT null THEN 1 else 0 END HedgeServerIDChange
,ra.Priority
,ra.PreviousPriority
,CASE WHEN ra.Priority<>ra.PreviousPriority AND ra.PreviousPriority IS NOT NULL then 1 else 0 END PriorityChange
,ra.AppLoginName
,ra.SysStartTime ChangeTime
,ra.SysStartTime
,ra.SysEndTime
,ra.RN_Desc
,ra.RN 
,ra.ValidFrom

FROM #RulesLog ra
WHERE 
RN=1 
OR (ra.Priority<>ra.PreviousPriority AND ra.PreviousPriority IS NOT NULL)
OR (ra.HedgeServerID<>ra.PreviousHedgeServerID AND ra.PreviousHedgeServerID IS NOT NULL)
OR (ra.IsActive<>ra.PreviousIsActive AND ra.PreviousIsActive IS NOT NULL )
OR (ra.Description<>ra.PreviousDescription  AND ra.PreviousDescription IS NOT null )
OR (ra.Name<>ra.PreviousName  AND ra.PreviousName IS NOT NULL)


--RuleChangesFinal
IF OBJECT_ID('tempdb..#RuleChangesFinal') IS NOT NULL 
DROP TABLE #RuleChangesFinal
CREATE TABLE #RuleChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Name Change' TypeOfChange,
CONCAT('Previous Name',': ',ra.PreviousName) Comments,
ra.AppLoginName,
ChangeTime

FROM #RulesAudit1 ra
WHERE ra.NameChange=1
AND ChangeTime BETWEEN @weekStart AND @weekEnd

UNION ALL

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Description Change' TypeOfChange,
CONCAT('Previous Description',': ',ra.PreviousDescription) Comments,
ra.AppLoginName,
ChangeTime
FROM #RulesAudit1 ra
WHERE ra.DescriptionChange=1  AND ChangeTime BETWEEN @weekStart AND @weekEnd

UNION ALL

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
CASE WHEN ra.PreviousIsActive=0 THEN 'Activated' ELSE 'Deactivated' end TypeOfChange,
Null Comments,
ra.AppLoginName,
ChangeTime
FROM #RulesAudit1 ra
WHERE ra.IsActiveChange=1  AND ChangeTime BETWEEN @weekStart AND @weekEnd

UNION ALL

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'HedgeServerID Change'  TypeOfChange,
CONCAT('Previous HedgeServerID',': ',ra.PreviousHedgeServerID)  Comments,
ra.AppLoginName,
ChangeTime
FROM #RulesAudit1 ra
WHERE ra.HedgeServerIDChange=1  AND ChangeTime BETWEEN @weekStart AND @weekEnd

UNION ALL

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Priority Change'  TypeOfChange,
CONCAT('Previous Priority',': ',ra.PreviousPriority)  Comments,
ra.AppLoginName,
 ChangeTime
FROM #RulesAudit1 ra
WHERE ra.PriorityChange=1  AND ChangeTime BETWEEN @weekStart AND @weekEnd

UNION all 

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'New Rule'  TypeOfChange,
Null  Comments,
ra.AppLoginName,
ChangeTime
FROM #RulesAudit1 ra
WHERE RN=1  AND ChangeTime BETWEEN @weekStart AND @weekEnd AND DATEDIFF(MINUTE,ValidFrom,ChangeTime)<=60

UNION all 

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Rule Deleted'  TypeOfChange,
Null  Comments,
 ra.AppLoginName,
 ra.SysEndTime
 FROM #RulesAudit1 ra
 WHERE ra.RN_Desc=1  AND ra.SysEndTime BETWEEN @weekStart AND @weekEnd 
 
---------------------------------------------------------------------------------------
--Compound Properties
IF OBJECT_ID('tempdb..#CPLog') IS NOT NULL 
DROP TABLE #CPLog 
CREATE TABLE #CPLog
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT a.CompoundPropertyID,
Name,
LAG(Name,1) OVER (PARTITION BY a.CompoundPropertyID ORDER BY a.SysStartTime) PreviousName,
CASE when Name<> 	LAG(Name,1) OVER (PARTITION BY a.CompoundPropertyID ORDER BY a.SysStartTime) AND 
LAG(Name,1) OVER (PARTITION BY a.CompoundPropertyID ORDER BY a.SysStartTime)  IS NOT NULL 
THEN 1 ELSE 0 END NameChange,
ROW_NUMBER() OVER (PARTITION BY a.CompoundPropertyID ORDER BY a.SysStartTime) RN,
a.AppLoginName,
CASE WHEN SysEndTime>'3000-01-01' THEN SysStartTime ELSE SysEndTime END ChangeTime,
a.SysStartTime,
a.SysEndTime,
ROW_NUMBER() OVER (PARTITION BY a.CompoundPropertyID ORDER BY a.SysEndTime DESC) RN_Desc,
a.ValidFrom
FROM 
(SELECT * 
FROM [Dealing_staging].[External_Etoro_History_CompoundProperties] c
WHERE c.Name<> '  '
UNION ALL 
SELECT *
FROM [Dealing_staging].[External_Etoro_CEP_CompoundProperties] c
WHERE Name<>'  '
)a


--CPChangesFinal

IF OBJECT_ID('tempdb..#CPChangesFinal') IS NOT NULL 
DROP TABLE #CPChangesFinal  
CREATE TABLE #CPChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

select 
@weekStart FromDate,
@weekEnd ToDate,
c.CompoundPropertyID
,c.Name
,'New Compound Property' TypeOfChange
,Null  Comments
,AppLoginName
,ChangeTime
FROM #CPLog c
WHERE RN=1 AND c.ChangeTime BETWEEN @weekStart AND @weekEnd AND DATEDIFF(MINUTE,c.ValidFrom,c.ChangeTime)<=60

UNION ALL 

select 
@weekStart FromDate,
@weekEnd ToDate,
c.CompoundPropertyID
,c.Name
,'Name Change' TypeOfChange
,CONCAT('Previous Name: ',c.PreviousName) Comments
,AppLoginName
,ChangeTime
FROM #CPLog c
WHERE c.NameChange=1 AND c.ChangeTime BETWEEN @weekStart AND @weekEnd		

UNION ALL 
		
select 
@weekStart FromDate,
@weekEnd ToDate,
c.CompoundPropertyID
,c.Name
,'Compound Property Deleted' TypeOfChange
,null Comments
,AppLoginName
,ChangeTime
FROM #CPLog c
WHERE c.RN_Desc=1 AND c.SysEndTime BETWEEN @weekStart AND @weekEnd

-----------------------------------------------------------------------------------------
--Mapping Condition To CP 
IF OBJECT_ID('tempdb..#ConditionToCP_Log') IS NOT NULL 
DROP TABLE #ConditionToCP_Log  
CREATE TABLE #ConditionToCP_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
a.CompoundPropertyID
,c.Name CP_Name
,a.ConditionID
,a.ValidFrom
,a.AppLoginName
,a.SysStartTime
,a.SysEndTime
,ROW_NUMBER() OVER (PARTITION BY a.CompoundPropertyID,a.ConditionID ORDER BY a.SysStartTime) RN
,ROW_NUMBER() OVER (PARTITION BY a.CompoundPropertyID,a.ConditionID ORDER BY a.SysEndTime DESC) RN_Desc
FROM
(
SELECT *
FROM [Dealing_staging].[External_Etoro_CEP_ConditionToCompoundProperty] ctc
UNION ALL
SELECT * 
FROM  [Dealing_staging].[External_Etoro_History_ConditionToCompoundProperty] ctch
) a

JOIN 
(SELECT DISTINCT c.CompoundPropertyID,c.Name FROM #CPLog  c WHERE c.RN_Desc=1) c
ON a.CompoundPropertyID=c.CompoundPropertyID


--ConditionToCP_ChangesFinal
IF OBJECT_ID('tempdb..#ConditionToCP_ChangesFinal') IS NOT NULL 
DROP TABLE #ConditionToCP_ChangesFinal
CREATE TABLE #ConditionToCP_ChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
ctcl.CompoundPropertyID
,ctcl.CP_Name
,ctcl.ConditionID
,'Condition Added To CP'  TypeOfChange
,ctcl.ValidFrom
,ctcl.AppLoginName
,ctcl.SysStartTime ChangeTime
,ctcl.RN
,ctcl.RN_Desc
FROM #ConditionToCP_Log ctcl
WHERE
 ctcl.SysStartTime BETWEEN @weekStart AND @weekEnd
AND ctcl.SysStartTime<>ctcl.SysEndTime

UNION ALL 

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
ctcl.CompoundPropertyID
,ctcl.CP_Name
,ctcl.ConditionID
, 'Condition Removed from CP'  TypeOfChange
,ctcl.ValidFrom
,ctcl.AppLoginName
,ctcl.SysEndTime ChangeTime
,ctcl.RN
,ctcl.RN_Desc FROM #ConditionToCP_Log ctcl
WHERE
ctcl.SysEndTime<'9999-01-01' 
AND ctcl.SysStartTime<>ctcl.SysEndTime
AND ctcl.SysEndTime BETWEEN @weekStart AND @weekEnd

----------------------------------------------------------------------------------------------------------------------------
--Conditions
IF OBJECT_ID('tempdb..#Conditions_Log') IS NOT NULL 
DROP TABLE #Conditions_Log 
CREATE TABLE #Conditions_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
a.ConditionID,
cp.Name Property,
LAG(cp.Name,1) OVER (PARTITION BY a.ConditionID ORDER BY a.SysStartTime) PreviousProperty,
co.Name Operator,
LAG(co.Name,1) OVER (PARTITION BY a.ConditionID ORDER BY a.SysStartTime) PreviousOperator,
a.Value,
LAG(a.Value,1) OVER (PARTITION BY a.ConditionID ORDER BY a.SysStartTime) PreviousValue,
a.AppLoginName,
a.SysStartTime,
a. SysEndTime,
ROW_NUMBER() OVER (PARTITION BY a.ConditionID ORDER BY a.SysStartTime) RN,
ROW_NUMBER() OVER (PARTITION BY a.ConditionID ORDER BY a.SysStartTime DESC) RN_Desc
FROM
(
 SELECT * 
 FROM [Dealing_staging].[External_Etoro_History_Conditions]
 WHERE SysStartTime<>SysEndTime
 UNION ALL
 SELECT * 
 FROM [Dealing_staging].[External_Etoro_CEP_Conditions]
 WHERE SysStartTime<>SysEndTime
 ) a
 JOIN [Dealing_staging].[External_Etoro_Dictionary_ConditionProperties] cp
 ON a.PropertyID=cp.PropertyID
 JOIN [Dealing_staging].[External_Etoro_Dictionary_ConditionOperators] co
 ON a.OperatorID=co.OperatorID


 --Conditions_ChangesFinal
IF OBJECT_ID('tempdb..#Conditions_ChangesFinal') IS NOT NULL 
DROP TABLE #Conditions_ChangesFinal
CREATE TABLE #Conditions_ChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Property Change' TypeOfChange
,CONCAT('Previous Property',': ',PreviousProperty) Comments
,cl.AppLoginName
,cl.SysStartTime ChangeTime
FROM #Conditions_Log cl
 WHERE cl.Property<>cl.PreviousProperty AND cl.PreviousProperty IS NOT NULL 
 AND cl.SysStartTime BETWEEN @weekStart AND @weekEnd
 UNION ALL 
SELECT 
@weekStart FromDate,
@weekEnd ToDate,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Operator Change' TypeOfChange
,CONCAT('Previous Operator',': ',cl.PreviousOperator) Comments
,cl.AppLoginName
,cl.SysStartTime
FROM #Conditions_Log cl
 WHERE cl.Operator<>cl.PreviousOperator AND cl.PreviousOperator IS NOT NULL 
 AND cl.SysStartTime BETWEEN @weekStart AND @weekEnd
  UNION ALL 
SELECT 
@weekStart FromDate,
@weekEnd ToDate,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Value Change' TypeOfChange
,CONCAT('Previous Value',': ',cl.PreviousValue) Comments
,cl.AppLoginName
,cl.SysStartTime
FROM #Conditions_Log cl
 WHERE cl.Value<>cl.PreviousValue AND cl.PreviousValue IS NOT NULL 
 AND cl.SysStartTime BETWEEN @weekStart AND @weekEnd
   UNION ALL 
  SELECT 
  @weekStart FromDate,
@weekEnd ToDate,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'New Condition' TypeOfChange
,null Comments
,cl.AppLoginName
,cl.SysStartTime
FROM #Conditions_Log cl
 WHERE RN=1
 AND cl.SysStartTime BETWEEN @weekStart AND @weekEnd
  UNION ALL 
  SELECT 
  @weekStart FromDate,
@weekEnd ToDate,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Condition Deleted' TypeOfChange
,null Comments
,cl.AppLoginName
,cl.SysEndTime
 FROM #Conditions_Log cl
 WHERE RN=1
 AND cl.SysEndTime BETWEEN @weekStart AND @weekEnd AND cl.RN_Desc=1

------------------------------------------------------------------------------------------------------------------------------------------------------

--CPToRule_Log
IF OBJECT_ID('tempdb..#CPToRule_Log') IS NOT NULL 
DROP TABLE #CPToRule_Log
CREATE TABLE #CPToRule_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
a.RuleID
,a.CompoundPropertyID
,Name
,a.Value
,LAG(a.Value,1) OVER (PARTITION BY a.RuleID,a.CompoundPropertyID ORDER BY a.SysStartTime) PreviousValue
,ROW_NUMBER() OVER  (PARTITION BY a.RuleID,a.CompoundPropertyID ORDER BY a.SysStartTime) RN
,ROW_NUMBER() OVER  (PARTITION BY a.RuleID,a.CompoundPropertyID ORDER BY a.SysEndTime DESC) RN_desc
,a.AppLoginName
,a.SysStartTime
,a.SysEndTime  
FROM
(
SELECT *
FROM [Dealing_staging].[External_Etoro_CEP_CompoundPropertyToRule]
WHERE SysStartTime<>SysEndTime
UNION ALL 
SELECT *
FROM [Dealing_staging].[External_Etoro_History_CompoundPropertyToRule]
WHERE SysStartTime<>SysEndTime
)a 
JOIN
(SELECT DISTINCT CompoundPropertyID, Name FROM #CPLog WHERE RN_Desc=1) b
ON a.CompoundPropertyID=b.CompoundPropertyID


--CPToRule_ChangesFinal

IF OBJECT_ID('tempdb..#CPToRule_ChangesFinal') IS NOT NULL 
DROP TABLE #CPToRule_ChangesFinal
CREATE TABLE #CPToRule_ChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
crl.RuleID
,crl.CompoundPropertyID
,crl.Name CP_Name
,crl.Value IsTrue
,'CP Added to Rule' TypeOfChange
,crl.AppLoginName
,crl.SysStartTime ChangeTime
FROM #CPToRule_Log crl
WHERE crl.SysStartTime BETWEEN @weekStart AND @weekEnd AND RN=1

UNION ALL

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
crl.RuleID
,crl.CompoundPropertyID
,crl.Name CP_Name
,crl.Value
,CASE WHEN crl.Value=1 THEN 'Mapping Changed from Not True to True' ELSE 'Mapping Changed from True to Not True' end TypeOfChange
,crl.AppLoginName
,crl.SysStartTime
FROM #CPToRule_Log crl
WHERE crl.SysStartTime BETWEEN @weekStart AND @weekEnd AND RN>1 AND crl.Value<>crl.PreviousValue

UNION ALL

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
crl.RuleID
,crl.CompoundPropertyID
,crl.Name CP_Name
,crl.Value
,'CP Removed from Rule' TypeOfChange
,crl.AppLoginName
,crl.SysEndTime
FROM #CPToRule_Log crl
WHERE crl.SysEndTime BETWEEN @weekStart AND @weekEnd AND crl.RN_desc=1 

----------------------------!!!!!!!!!!-------------------------------------------------------------------------------------------------------------------------

--Name Lists 
IF OBJECT_ID('tempdb..#NameLists_Log') IS NOT NULL 
DROP TABLE #NameLists_Log   
CREATE TABLE #NameLists_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT  * ,
ROW_NUMBER() OVER (PARTITION BY a.NamedListID ORDER BY a.SysStartTime) RN,
ROW_NUMBER() OVER (PARTITION BY a.NamedListID ORDER BY a.SysEndTime desc) RN_desc

FROM 
(
SELECT *
FROM [Dealing_staging].[External_Etoro_History_NamedLists]
WHERE SysStartTime<>SysEndTime
AND Name<>' '
UNION ALL 
SELECT *
FROM [Dealing_staging].[External_Etoro_CEP_NamedLists]
WHERE SysStartTime<>SysEndTime
AND Name<>' '
)a


--NameLists_ChangesFinal
IF OBJECT_ID('tempdb..#NameLists_ChangesFinal') IS NOT NULL 
DROP TABLE #NameLists_ChangesFinal  
CREATE TABLE #NameLists_ChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT
@weekStart FromDate,
@weekEnd ToDate,
nll.NamedListID
,nll.Name
,CASE WHEN RN=1 THEN 'New Name List' ELSE 'Change In CIDs' end TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,nll.SysStartTime ChangeTime
FROM #NameLists_Log nll
WHERE SysStartTime BETWEEN @weekStart AND @weekEnd

UNION ALL 

SELECT
@weekStart FromDate,
@weekEnd ToDate,
nll.NamedListID
,nll.Name
,CASE WHEN nll.RN_desc=1 THEN 'Name List Deleted' ELSE 'Change In CIDs' end TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,nll.SysEndTime ChangeTime
FROM #NameLists_Log nll
WHERE SysEndTime<'9999-01-01' AND nll.SysEndTime BETWEEN @weekStart AND @weekEnd

------------------------------------------------------------------------------------------------------------------------------------------------------
--Mapping CID To Name List
IF OBJECT_ID('tempdb..#ListCIDMapping_Log') IS NOT NULL 
DROP TABLE #ListCIDMapping_Log 
CREATE TABLE #ListCIDMapping_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT  a.*,b.Name 
FROM 
(SELECT *
FROM [Dealing_staging].[External_Etoro_History_ListCIDMappings]
WHERE SysStartTime<>SysEndTime
UNION ALL 
SELECT *
FROM [Dealing_staging].[External_Etoro_CEP_ListCIDMappings]
WHERE SysStartTime<>SysEndTime
)a
JOIN 
(SELECT DISTINCT NamedListID, Name FROM #NameLists_Log nll WHERE nll.RN_desc=1) b
ON a.NamedListID=b.NamedListID


--ListCIDMapping_ChangesFinal
IF OBJECT_ID('tempdb..#ListCIDMapping_ChangesFinal') IS NOT NULL 
DROP TABLE #ListCIDMapping_ChangesFinal
CREATE TABLE #ListCIDMapping_ChangesFinal
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT
@weekStart FromDate,
@weekEnd ToDate,
nll.NamedListID
,nll.Name
,nll.CID
,'CID Added' TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,nll.SysStartTime ChangeTime
FROM #ListCIDMapping_Log nll
WHERE SysStartTime BETWEEN @weekStart AND @weekEnd

UNION ALL 

SELECT
@weekStart FromDate,
@weekEnd ToDate,
nll.NamedListID
,nll.Name
,CID
,'CID Deleted'  TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,nll.SysEndTime ChangeTime
FROM #ListCIDMapping_Log nll
WHERE SysEndTime<'9999-01-01' AND nll.SysEndTime BETWEEN @weekStart AND @weekEnd

---------------------------------------------------------------------------------------------------------------
--connect CP to Rule
IF OBJECT_ID('tempdb..#Dim_CPtoRule') IS NOT NULL 
DROP TABLE #Dim_CPtoRule  
CREATE TABLE #Dim_CPtoRule
WITH (DISTRIBUTION=HASH(RuleID), HEAP) AS

SELECT DISTINCT rl.RuleID, rl.Name RuleName, CompoundPropertyID , rl.HedgeServerID
FROM #CPToRule_Log crl
JOIN (SELECT RuleID, Name,HedgeServerID FROM #RulesLog WHERE RN_Desc=1) rl
ON rl.RuleID=crl.RuleID
WHERE crl.RN_desc=1

--Dim_ConditionRule
IF OBJECT_ID('tempdb..#Dim_ConditionRule') IS NOT NULL 
DROP TABLE #Dim_ConditionRule 
CREATE TABLE #Dim_ConditionRule
WITH (HEAP ,DISTRIBUTION=ROUND_ROBIN) AS

SELECT DISTINCT crl.ConditionID, RuleID , dcr.RuleName,HedgeServerID
FROM #ConditionToCP_Log  crl
JOIN #Dim_CPtoRule dcr
ON crl.CompoundPropertyID = dcr.CompoundPropertyID

--FromDateToDate

IF OBJECT_ID('tempdb..#FromDateToDate') IS NOT NULL 
DROP TABLE #FromDateToDate
CREATE TABLE #FromDateToDate
WITH (HEAP ,DISTRIBUTION=ROUND_ROBIN) AS
SELECT @weekStart FromDate,
@weekEnd ToDate 

---------------------------------------------------------------------------------------------------------------------------------
--INSERT INTO tables

--Rules 
DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Rules WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_Rules

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
TypeOfChange,
Comments,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT join
#RuleChangesFinal rcf
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate = rcf.ToDate

--Compound Property

DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CP WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_CP

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
ctr.RuleID,
ctr.RuleName,
rcf.CompoundPropertyID,
Name CPName,
HedgeServerID,
TypeOfChange,
Comments,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT join
#CPChangesFinal rcf
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate = rcf.ToDate
left JOIN #Dim_CPtoRule ctr
ON rcf.CompoundPropertyID=ctr.CompoundPropertyID

--conditions

DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
RuleName,
HedgeServerID,
rcf.ConditionID,
rcf.Property,
rcf.Operator,
rcf.Value,
TypeOfChange,
Comments,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT join
#Conditions_ChangesFinal  rcf
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate = rcf.ToDate
LEFT JOIN #Dim_ConditionRule dcr
ON rcf.ConditionID=dcr.ConditionID

--condition to cp

DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
RuleID,
RuleName,
HedgeServerID,
rcf.CompoundPropertyID,
rcf.CP_Name,
rcf.ConditionID,
TypeOfChange,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT JOIN #ConditionToCP_ChangesFinal   rcf
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate = rcf.ToDate
 LEFT JOIN #Dim_CPtoRule dcr
ON rcf.CompoundPropertyID = dcr.CompoundPropertyID

--cp to rule

DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
rcf.RuleID,
RuleName,
HedgeServerID,
rcf.CompoundPropertyID,
rcf.CP_Name,
IsTrue,
TypeOfChange,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT join #CPToRule_ChangesFinal   rcf
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate = rcf.ToDate
LEFT JOIN #Dim_CPtoRule dcr
ON rcf.CompoundPropertyID = dcr.CompoundPropertyID

--Name lists

DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
 NamedListID,
 Name,
TypeOfChange,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT JOIN #NameLists_ChangesFinal rcf
ON fdtd.FromDate = rcf.FromDate AND fdtd.ToDate=fdtd.ToDate

--list cid mapping

DELETE FROM Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping WHERE FromDate=@weekStart AND ToDate=@weekEnd
INSERT INTO Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

SELECT 
@weekStart FromDate,
@weekEnd ToDate,
 NamedListID,
 Name,
 CID,
TypeOfChange,
AppLoginName,
ChangeTime,
GETDATE()
FROM 
#FromDateToDate fdtd
LEFT join #ListCIDMapping_ChangesFinal
ON fdtd.FromDate = #ListCIDMapping_ChangesFinal.FromDate AND fdtd.ToDate = #ListCIDMapping_ChangesFinal.ToDate

END

-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_CP
-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule
-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP
-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions
-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping
-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
-- select * from Dealing_dbo.Dealing_CEPWeeklyAudit_Rules


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `External_Etoro_CEP_ListCIDMappings.NamedListID` | unresolved | External_Etoro_CEP_ListCIDMappings | NamedListID | `—` |
| `External_Etoro_CEP_ListCIDMappings.CID` | unresolved | External_Etoro_CEP_ListCIDMappings | CID | `—` |
| `Dealing_dbo.SP_W_CEPWeeklyAudit` | synapse_sp | Dealing_dbo | SP_W_CEPWeeklyAudit | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_W_CEPWeeklyAudit.sql` |
| `Dealing_staging.External_Etoro_CEP_Rules` | unresolved | Dealing_staging | External_Etoro_CEP_Rules | `—` |
| `Dealing_staging.External_Etoro_History_Rules` | unresolved | Dealing_staging | External_Etoro_History_Rules | `—` |
| `Dealing_staging.External_Etoro_History_CompoundProperties` | unresolved | Dealing_staging | External_Etoro_History_CompoundProperties | `—` |
| `Dealing_staging.External_Etoro_CEP_CompoundProperties` | unresolved | Dealing_staging | External_Etoro_CEP_CompoundProperties | `—` |
| `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | unresolved | Dealing_staging | External_Etoro_CEP_ConditionToCompoundProperty | `—` |
| `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | unresolved | Dealing_staging | External_Etoro_History_ConditionToCompoundProperty | `—` |
| `Dealing_staging.External_Etoro_History_Conditions` | unresolved | Dealing_staging | External_Etoro_History_Conditions | `—` |
| `Dealing_staging.External_Etoro_CEP_Conditions` | unresolved | Dealing_staging | External_Etoro_CEP_Conditions | `—` |
| `Dealing_staging.External_Etoro_Dictionary_ConditionProperties` | unresolved | Dealing_staging | External_Etoro_Dictionary_ConditionProperties | `—` |
| `Dealing_staging.External_Etoro_Dictionary_ConditionOperators` | unresolved | Dealing_staging | External_Etoro_Dictionary_ConditionOperators | `—` |
| `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` | unresolved | Dealing_staging | External_Etoro_CEP_CompoundPropertyToRule | `—` |
| `Dealing_staging.External_Etoro_History_CompoundPropertyToRule` | unresolved | Dealing_staging | External_Etoro_History_CompoundPropertyToRule | `—` |
| `Dealing_staging.External_Etoro_History_NamedLists` | unresolved | Dealing_staging | External_Etoro_History_NamedLists | `—` |
| `Dealing_staging.External_Etoro_CEP_NamedLists` | unresolved | Dealing_staging | External_Etoro_CEP_NamedLists | `—` |
| `Dealing_staging.External_Etoro_History_ListCIDMappings` | unresolved | Dealing_staging | External_Etoro_History_ListCIDMappings | `—` |
| `Dealing_staging.External_Etoro_CEP_ListCIDMappings` | unresolved | Dealing_staging | External_Etoro_CEP_ListCIDMappings | `—` |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | synapse | Dealing_dbo | Dealing_CEPWeeklyAudit_Rules | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_Rules.md` |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | synapse | Dealing_dbo | Dealing_CEPWeeklyAudit_CP | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_CP.md` |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | synapse | Dealing_dbo | Dealing_CEPWeeklyAudit_Conditions | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_Conditions.md` |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | synapse | Dealing_dbo | Dealing_CEPWeeklyAudit_ConditionToCP | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_ConditionToCP.md` |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | synapse | Dealing_dbo | Dealing_CEPWeeklyAudit_CPToRule | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_CPToRule.md` |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists` | synapse | Dealing_dbo | Dealing_CEPWeeklyAudit_NameLists | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPWeeklyAudit_NameLists.md` |

