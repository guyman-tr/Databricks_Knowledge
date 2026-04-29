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
- **Object**: `Dealing_CEPDailyAudit_NameLists`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/Dealing_dbo/Dealing_CEPDailyAudit_NameLists/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_CEPDailyAudit_NameLists\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\Dealing_dbo\Dealing_CEPDailyAudit_NameLists\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Tables\Dealing_dbo.Dealing_CEPDailyAudit_NameLists.sql`

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

# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_CEPDailyAudit_NameLists`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_CEPDailyAudit_NameLists.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_CEPDailyAudit_NameLists]
(
	[Date] [date] NULL,
	[NameListID] [int] NULL,
	[Name] [varchar](max) NULL,
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
		[Date] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 6 upstream wiki(s). Read EACH one in full.


### Upstream `Dealing_dbo.Dealing_CEPDailyAudit_Rules` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPDailyAudit_Rules`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_Rules.md`

# Dealing_dbo.Dealing_CEPDailyAudit_Rules

> Daily audit of **CEP Rule** definition changes — creates, deletes, activations, renames, priority moves, and hedge-server moves for the top-level hedging policy objects in the Client Execution Platform.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_Rules` + `External_Etoro_History_Rules` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **daily change log** for **CEP Rules** — the **top-level** entities in the CEP hedging rule engine. Each row records **one rule-level event** on business date **`Date`**: creation, deletion, activation/deactivation, rename, description edit, hedge-server reassignment, or **priority** reordering.

**Rule semantics (conceptual):** A rule has **`RuleName`**, **`Description`**, **`Priority`** (evaluation order — **lower numeric value = higher precedence**, with **0** evaluated first), **`HedgeServerID`** (which hedging backend stack processes the rule), and **`IsActive`**. Rules contain **compound properties (CPs)** and **conditions**; **this table only captures rule-shell changes**, not CP or condition internals (those live in sibling audit tables).

**Why it matters:** Rules **directly govern** how client positions are routed and hedged. Governance, post-incident review, and regulatory questions about **“what hedging policy looked like on date D”** lean on this trail. The table has the **richest `TypeOfChange` vocabulary** in the **CEPDailyAudit** family (**eight** distinct event types, including **Activated** / **Deactivated**).

**Scale (documented sample):** On the order of **~1,003 rows** from **2023-12-13** through **2026-03-09**. **No PII** in the sampled semantics.

**Cadence vs weekly:** **`Dealing_CEPWeeklyAudit_Rules`** holds a **weekly** rollup with history from **Sep 2021**; this **daily** table starts **Dec 2023** and offers **per-day** granularity for investigations after that cutover.

## 2. Business Logic

- **Writer:** `Dealing_dbo.SP_CEPDailyAudit(@Date)` — **DELETE + INSERT** for the target **`Date`** (same pattern as other **CEPDailyAudit** tables).
- **Sources:** Current rules from **`External_Etoro_CEP_Rules`** and temporal history from **`External_Etoro_History_Rules`**.
- **Change detection (high level):** **`LAG()`**-style comparisons detect **name**, **description**, **`IsActive`**, **`HedgeServerID`**, and **`Priority`** changes; **RN / RN_Desc** logic classifies **new rule** and **rule deleted** events (see SP for exact predicates).
- **`TypeOfChange`:** Derived strings such as **`New Rule`**, **`Rule Deleted`**, **`Activated`**, **`Deactivated`**, **`Name Change`**, **`Description Change`**, **`HedgeServerID Change`**, **`Priority Change`** — **exact spelling matters** in filters.
- **`Comments`:** For edits, carries **previous** values (e.g. **Previous Name**, **Previous Priority**) — use for **before/after** reconstructions.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`** so deletions still attribute an actor when the current row’s login is null.
- **`ChangeTime`:** **`SysStartTime`** for most paths; **`SysEndTime`** for deletions — **source event time**, not load time.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for **low thousands** of rows. |
| **Clustered index** | **`Date` ASC** — align filters to **`Date`** for partition-style mental model and index seek. |
| **Scale** | Small — routine audit queries need **no special tuning**. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for **daily** governance review.
- **`WHERE RuleID = @r ORDER BY Date, ChangeTime`** for **full rule timeline** after Dec 2023.
- Join siblings on **`RuleID`** and **`Date`** for **same-day** CP / CP-to-rule / condition context.

### 3.3 Freshness

- **ACTIVE** in documented sample; **max `Date` 2026-03-09**. Expect **next business day** availability for date *D* after the daily batch.

### 3.4 Gotchas

- **Multiple rows per `RuleID` per `Date`** are **valid** if several edits occurred the same calendar day.
- **`Description`** on **`Description Change`** rows holds the **new** text; **old** text is in **`Comments`**.
- **`Priority`** on **`Priority Change`** rows holds the **new** value; **old** is in **`Comments`**.
- Prefer **`ChangeTime`** / **`Date`** for **business timelines**; avoid treating **`UpdateDate`** as the event clock.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this rule change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** identifier that changed. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** at the time of the event. (Tier 2 — SP_CEPDailyAudit) |
| 4 | Description | varchar(max) | YES | **Rule description** at the time of the event; on **`Description Change`**, this is the **new** description (previous text in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** associated with the rule (**source column family**: **`HedgeRuleActionTypeID`**) — which backend stack executes the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | Priority | int | YES | **Execution priority** — **lower value = higher precedence** (**0** first). On **`Priority Change`**, this is the **new** priority (previous in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) |
| 7 | TypeOfChange | varchar(max) | YES | **Event type** — one of: **`New Rule`**, **`Rule Deleted`**, **`Activated`**, **`Deactivated`**, **`Name Change`**, **`Description Change`**, **`HedgeServerID Change`**, **`Priority Change`**. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Comments | varchar(max) | YES | **Prior-value context** for edits (**Previous Name / Description / HedgeServerID / Priority**); **NULL** for simple lifecycle events where not applicable. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** who performed the change (**`COALESCE`** across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Source timestamp** of the event (**`SysStartTime`** vs **`SysEndTime`** per path). (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **not** the business event instant. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
[CEP System — Rules temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Rules  (current)
Dealing_staging.External_Etoro_History_Rules  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — LAG() detects Name/Description/IsActive/HedgeServerID/Priority changes
    — RN=1 + created within 60 min of ValidFrom → New Rule
    — RN_Desc=1 + SysEndDate=@Date → Rule Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Rules  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; identifiers and attributes ← **`External_Etoro_CEP_Rules`**; `TypeOfChange` / `Comments` ← **SP derivation**; `LoginName` ← **`COALESCE(AppLoginName, PreviousAppLoginName)`**; `ChangeTime` ← **`SysStartTime` / `SysEndTime`**; `UpdateDate` ← **`GETDATE()`**.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **CP** changes **under** rules documented here — join on **`RuleID`** + **`Date`**. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **CP-to-rule mapping** changes — same **`Date`** grain. |
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Condition** definition changes within CPs under these rules. |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days` | **View** over recent rows (referenced by email-related SPs). |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | **Weekly** counterpart with **longer history** (from **Sep 2021**). |
| `Dealing_staging.External_Etoro_CEP_Rules` | **Current** rule state **source**. |
| `Dealing_staging.External_Etoro_History_Rules` | **Temporal history** **source**. |

## 7. Sample Queries

**7.1 — All rule events on a business date**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , TypeOfChange
    , Priority
    , HedgeServerID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE Date = '2026-03-09'
ORDER BY ChangeTime, RuleID;
```

**7.2 — Activation and deactivation events (recent window)**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE TypeOfChange IN ('Activated', 'Deactivated')
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — Single-rule timeline with comment context**

```sql
SELECT
      Date
    , TypeOfChange
    , RuleName
    , Description
    , Priority
    , HedgeServerID
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE RuleID = @RuleID
ORDER BY Date, ChangeTime;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.5/10 (★★★★☆) | Batch: CEP audit wiki reformat*  
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_Rules | Type: Table | Production Source: Dealing_staging CEP Rules + history*


### Upstream `Dealing_dbo.Dealing_CEPDailyAudit_CP` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPDailyAudit_CP`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_CP.md`

# Dealing_dbo.Dealing_CEPDailyAudit_CP

> Daily audit trail of **Compound Property (CP)** lifecycle changes in the CEP hedging rule engine — captures creations, renames, and deletions of CPs that control hedging behavior.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily (Priority 0 — OpsDB/Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table records every **Compound Property (CP) lifecycle event** in eToro's CEP (Client Execution Platform) hedging rule engine. CPs are groupings of conditions used within CEP Rules — they act as logical "clauses" that can be reused across multiple hedging rules. When a CP is created, renamed, or deleted, one row is written for that business date.

**Source and lineage**: Data flows from `Dealing_staging.External_Etoro_CEP_CompoundProperties` (current state) and `External_Etoro_History_CompoundProperties` (temporal history). The writer SP `SP_CEPDailyAudit` uses `LAG()` window functions over system-time versioned records to detect changes, then classifies each event by type.

**Freshness**: Runs daily. Data available next business day. Active pipeline — max date 2026-03-09. Sparse table (314 rows since Dec 2023) because rows only appear on days when CP changes actually occur.

**Why it matters**: CEP rules control how eToro routes and hedges client positions. Changes to CPs can materially affect hedging behavior. This audit trail supports regulatory compliance, post-incident investigation, and governance oversight by the Dealing team.

---

## 2. Business Logic

### 2.1 Change Detection via Temporal Tables

**What**: The SP detects CP changes by comparing successive system-time versions of the staging temporal tables using `LAG()` over `SysStartTime`.

**Columns Involved**: `TypeOfChange`, `ChangeTime`, `LoginName`, `Comments`

**Rules**:
- `New Compound Property` — CP created today (new row in current table, no prior history)
- `Name Change` — CP renamed (Comments stores `"Previous Name: {oldName}"`)
- `Compound Property Deleted` — CP removed from CEP (row disappears from current, appears in history with SysEndTime)
- `LoginName` uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture the responsible user even for deletion events

### 2.2 Sentinel Row Pattern

**What**: The SP always writes at least one row per processed date, even if no CP changes occurred that day.

**Rules**:
- On days with no changes, a sentinel row with NULL `TypeOfChange`, `CompoundPropertyID`, etc. is written
- Filter with `WHERE TypeOfChange IS NOT NULL` for actual change events only

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date`. Very small table (~314 rows). No performance concerns. Always filter on `Date` for the most common access pattern.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP changes happened on date X? | `WHERE Date = 'YYYY-MM-DD' AND TypeOfChange IS NOT NULL` |
| Who made a specific CP change? | `WHERE CompoundPropertyID = @id AND TypeOfChange IS NOT NULL ORDER BY Date DESC` |
| All CP renames in a date range | `WHERE Date BETWEEN @start AND @end AND TypeOfChange = 'Name Change'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_CPToRule | `CompoundPropertyID + Date` | Correlate CP changes with Rule-mapping changes on the same day |
| Dealing_CEPDailyAudit_Rules | `RuleID + Date` | See which Rule was affected by this CP change |

### 3.4 Gotchas

- **Sparse table**: Many calendar dates have zero rows (no CP changes). Don't expect continuous daily data.
- **Sentinel rows**: Always filter `WHERE TypeOfChange IS NOT NULL` to exclude placeholder rows.
- This is one of 7 CEPDailyAudit tables, all written by the same SP: CP, CPToRule, ConditionToCP, Conditions, ListCIDMapping, NameLists, Rules.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date on which this CP change occurred. Clustered index key. NULL on sentinel rows (no changes detected). (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | ID of the CEP Rule this Compound Property is associated with (via CP-to-Rule mapping). NULL if the CP change is not linked to a rule (e.g., standalone CP creation). (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | Name of the associated CEP Rule. Denormalized from the Rule dimension for query convenience. (Tier 2 — SP_CEPDailyAudit) |
| 4 | CompoundPropertyID | int | YES | Unique identifier of the Compound Property that changed. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CPName | varchar(max) | YES | Name of the Compound Property at the time of the change. (Tier 2 — SP_CEPDailyAudit) |
| 6 | HedgeServerID | int | YES | Hedge server associated with this Rule. Identifies which hedging server processes the parent rule. (Tier 2 — SP_CEPDailyAudit) |
| 7 | TypeOfChange | varchar(max) | YES | Change event type. Values: `New Compound Property`, `Name Change`, `Compound Property Deleted`. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Comments | varchar(max) | YES | Context for `Name Change` events: `"Previous Name: {oldName}"`. NULL for creation/deletion events and sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | Application login of the user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | Exact timestamp of the change event (SysStartTime or SysEndTime from the temporal record). NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. Not the business change time. [UNVERIFIED] (Tier 4 — inferred) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Dealing_staging CEP temporal tables | Various | LAG()-based change detection |

No Generic Pipeline mapping — CEP is an internal eToro system, not tracked in the Generic Pipeline.

### 5.2 ETL Pipeline

```
CEP Internal System
    → Dealing_staging.External_Etoro_CEP_CompoundProperties (current state)
    → Dealing_staging.External_Etoro_History_CompoundProperties (temporal history)
        → SP_CEPDailyAudit (LAG() change detection)
            → Dealing_dbo.Dealing_CEPDailyAudit_CP
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_CEPDailyAudit_Rules | Parent rule whose CP configuration changed |
| CompoundPropertyID | Dealing_staging.External_Etoro_CEP_CompoundProperties | Source CP entity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPDailyAudit_CPToRule | CompoundPropertyID | CP-to-Rule mapping changes reference the same CP |
| V_Dealing_CEPDailyAudit_CP_Last180Days | All | View over this table for last 180 days |

---

## 7. Sample Queries

### 7.1 All CP changes on a specific date
```sql
SELECT Date, CompoundPropertyID, CPName, TypeOfChange, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE  Date = '2026-03-01'
  AND  TypeOfChange IS NOT NULL
ORDER BY ChangeTime;
```

### 7.2 History of a specific Compound Property
```sql
SELECT Date, TypeOfChange, Comments, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE  CompoundPropertyID = 42
  AND  TypeOfChange IS NOT NULL
ORDER BY Date DESC;
```

### 7.3 All CP renames in the last 30 days
```sql
SELECT Date, CompoundPropertyID, CPName, Comments AS PreviousName, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE  Date >= DATEADD(DAY, -30, GETDATE())
  AND  TypeOfChange = 'Name Change'
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: 7 (redo)*
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_CP | Type: Table | Production Source: Dealing_staging CEP tables*


### Upstream `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPDailyAudit_Conditions`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_Conditions.md`

# Dealing_dbo.Dealing_CEPDailyAudit_Conditions

> Daily audit of **CEP Condition** definition changes — property, operator, and threshold **value** edits, plus condition creation and deletion, in the Client Execution Platform hedging rule engine.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |
| **PII** | No |

## 1. Business Meaning

This table tracks **condition definition changes** in the **CEP (Client Execution Platform)** hedging rule engine. A **condition** is the atomic unit of rule logic: a **`Property OPERATOR Value`** expression that evaluates client trade or position attributes.

**What each row means:** On business date **`Date`**, a condition’s **property type**, **comparison operator**, or **threshold value** changed — or a condition was **created** or **deleted**. Use this table to answer: *“What exactly changed in a CEP rule condition on date X?”*

**Condition anatomy (ETL-resolved):**

- **`Property`** — attribute under test (e.g. instrument type, position size). Names come from **`External_Etoro_Dictionary_ConditionProperties`**.
- **`Operator`** — comparison (e.g. equals, greater than). Names from **`External_Etoro_Dictionary_ConditionOperators`**.
- **`Value`** — threshold or target, stored as **`varchar(100)`** to hold numeric, string, or enum-like literals.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)
        └── Condition   ← definition changes audited here
              └── Property + Operator + Value
```

**Why it matters:** Conditions encode the **business logic** of hedging rules. A **`Value Change`** or **`Operator Change`** can change **which trades** trigger hedging. This audit supports **replay**, **governance**, and **incident analysis** with **user** and **timestamp** attribution.

**Scale (documented sample):** About **3,189 rows** from **2023-12-12** through **2026-03-09**. **Higher churn** than **Condition-to-CP** mapping alone — attribute edits are common.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit`** performs **DELETE + INSERT** for the supplied **`@Date`**. **Daily** refresh (OpsDB / Service Broker **Priority 0**). **SLA:** typically **next business day** for date *D*.

## 2. Business Logic

- **Sources:** **`Dealing_staging.External_Etoro_CEP_Conditions`** (current) and **`External_Etoro_History_Conditions`** (temporal history); dictionary joins to **`External_Etoro_Dictionary_ConditionProperties`** and **`External_Etoro_Dictionary_ConditionOperators`**.
- **Change detection:** **`LAG()`**-style comparisons in the SP detect **property**, **operator**, and **value** transitions; events are classified as **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`** (exact strings from SP).
- **`RuleID` / `RuleName` / `HedgeServerID`:** Resolved through the **condition → CP → rule** chain (e.g. **`#Dim_ConditionRule`** style logic in SP) — attribution can be **non-trivial** when wiring spans multiple rules.
- **`Comments`:** For change events, carries the **previous** property, operator, or value (e.g. `"Previous Value: {old}"`); **NULL** for pure create/delete rows.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`** from the temporal source — **CEP application user**.
- **`ChangeTime`:** **`SysStartTime`** (and analogous semantics per SP path) — **source event time**.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata**, not business time.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for **small** audit fact tables. |
| **Clustered index** | **`Date` ASC** — aligns with **daily** reload and **`WHERE Date = @d`** filters. |
| **Scale** | **Low thousands** of rows — routine analytics do not require special tuning. |

### 3.2 Recommended patterns

- Filter **`WHERE Date = @d`** for **daily** investigations.
- Filter **`WHERE ConditionID = @cid`** (often with **`Date`**) for **single-condition** timelines.
- Join **`RuleID`** / context to **`Dealing_CEPDailyAudit_CPToRule`** and **`Dealing_CEPDailyAudit_ConditionToCP`** for **full rule wiring**.

### 3.3 Freshness

- **ACTIVE** in documented window; **max `Date` 2026-03-09**. Expect **one batch row set per calendar date** processed by the SP.

### 3.4 Gotchas

- **`TypeOfChange`** values are **fixed literals** — match **case and spacing** in predicates.
- **`Value`** is **varchar** — cast or compare carefully when treating as numeric.
- **`Property`** and **`Operator`** are **human-readable** at load time — not raw IDs in this table.
- Multiple **change types** for the **same `ConditionID`** on the **same `Date`** can occur if several attributes changed.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this condition change was recorded — equals **`@Date`** for the SP run. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** containing the **compound property** that contains this **condition** (via CP / mapping chain in SP). (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized for reporting alongside **`RuleID`**. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server** associated with the parent rule context. (Tier 2 — SP_CEPDailyAudit) |
| 5 | ConditionID | int | YES | **Identifier** of the **condition** that changed. (Tier 2 — SP_CEPDailyAudit) |
| 6 | Property | varchar(max) | YES | **Attribute** under test — resolved name from **condition properties** dictionary. (Tier 2 — SP_CEPDailyAudit) |
| 7 | Operator | varchar(max) | YES | **Comparison operator** — resolved name from **condition operators** dictionary. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Value | varchar(100) | YES | **Threshold or literal** compared against the property — stored as **varchar** for mixed types. (Tier 2 — SP_CEPDailyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`**. (Tier 2 — SP_CEPDailyAudit) |
| 10 | Comments | varchar(max) | YES | **Prior value** context for changes (e.g. previous property/operator/value); **NULL** for create/delete-only rows. (Tier 2 — SP_CEPDailyAudit) |
| 11 | LoginName | varchar(max) | YES | **CEP application user** who made the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 12 | ChangeTime | datetime | YES | **Exact source timestamp** of the change event. (Tier 2 — SP_CEPDailyAudit) |
| 13 | UpdateDate | datetime | YES | **DWH load timestamp** via **`GETDATE()`** in the SP — **not** the business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow (see **`.lineage.md`** for full column mapping):

```
[CEP System — Conditions temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Conditions  (current)
Dealing_staging.External_Etoro_History_Conditions  (history)
    ↓ JOIN dictionaries (Property, Operator names)
SP_CEPDailyAudit(@Date)
    — LAG() / comparison logic → change types
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Conditions  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `ConditionID`, `Value`, `LoginName`, `ChangeTime` ← condition external / history; `Property`, `Operator` ← dictionary joins; `RuleID`, `RuleName`, `HedgeServerID` ← derived dimension chain; `TypeOfChange`, `Comments` ← SP logic; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` | **Membership** of conditions in **CPs** — pairs with **definition** changes here. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **Compound property**-level audit — parent entity in the hierarchy. |
| `Dealing_staging.External_Etoro_CEP_Conditions` | **Current** condition rows. |
| `Dealing_staging.External_Etoro_History_Conditions` | **Temporal history** driving diffs. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionProperties` | **Property** name resolution. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionOperators` | **Operator** name resolution. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Weekly rollup** of the same event family. |

## 7. Sample Queries

**7.1 — All condition changes on a business date**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , ConditionID
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE Date = '2026-03-09'
ORDER BY RuleID, ConditionID, ChangeTime;
```

**7.2 — Value changes with previous value in `Comments`**

```sql
SELECT
      Date
    , ConditionID
    , Value
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE TypeOfChange = 'Value Change'
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — New and deleted conditions with rule context**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , ConditionID
    , TypeOfChange
    , Property
    , Operator
    , Value
    , LoginName
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE TypeOfChange IN ('New Condition', 'Condition Deleted')
ORDER BY Date DESC, RuleID, ConditionID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: manual template reformat*  
*Tiers: 0 T1, 12 T2, 0 T3, 1 T4 | Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_Conditions | Type: Table | Production Source: Dealing_staging CEP temporal tables*


### Upstream `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_ConditionToCP.md`

# Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

> Daily audit of Condition-to-Compound Property mapping changes in CEP — when atomic rule conditions are added to or removed from a CP’s condition bundle.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table captures **Condition → Compound Property (CP)** membership changes in the **Client Execution Platform (CEP)** hedging rule engine. **Conditions** are the **atomic predicates** (e.g. comparisons on instrument or account attributes) that, when grouped, define what must hold true for a **compound property** to “fire” inside a **rule**.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)   [linked via CPToRule]
        └── Condition           [linked via ConditionToCP]  ← audited here
              └── Property + Operator + Value (see Conditions audit table)
```

**What each row means:** On business date **`Date`**, a **condition** was **linked to** or **unlinked from** a **CP**. That changes **which atomic tests** participate in the CP’s bundle — and therefore **which client/trade facts** can satisfy the CP under a rule.

**Why it matters:** Unexpected hedging or routing behavior often traces to **“someone added/removed a condition from the CP we thought was stable.”** This audit gives Dealing and Risk a **replayable history** of those edits with **user attribution** and **timestamps**.

**Scale (sampled):** On the order of **~1,219 rows** from **2023-12-12** through **2026-03-09** — **lower churn** than CP-to-Rule mapping (which can rewire CPs across many rules frequently). **No PII.**

**Load pattern:** `SP_CEPDailyAudit` **DELETE + INSERT** per **`@Date`** for this table, same as siblings. **Daily** OpsDB / Service Broker schedule; **SLA** — typically **next business day** availability for date *D*.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` (**current**) and `External_Etoro_History_ConditionToCompoundProperty` (**temporal history**).
- **Add vs remove detection:** If the **start** of the temporal row’s validity lands on **`@Date`**, classify **`Condition Added To CP`**; if the **end** date aligns with **`@Date`**, classify **`Condition Removed from CP`** (see SP for exact `SysStartDate` / `SysEndDate` logic).
- **Rule context (`RuleID`, `RuleName`, `HedgeServerID`):** Resolved by joining through **`#Dim_CPtoRule`** (built from CP-to-rule logs and rules logs). **Important:** If a CP is attached to **multiple rules**, the **same underlying condition membership change** can appear as **multiple rows** — one **per rule context** — mirroring how the dimension explodes for reporting.
- **`CP_Name`:** From **`#CPLog`** “latest state” style resolution — human-readable CP label for the `CompoundPropertyID` on the event.
- **`LoginName`:** `COALESCE(AppLoginName, PreviousAppLoginName)` — **CEP application user**.
- **`ChangeTime`:** **`SysStartTime`** for additions; removals align with **`SysEndTime`** semantics in SP — **source event time**.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — fine for small audit tables. |
| **Clustered index** | **`Date` ASC** — matches primary access path. |
| **Scale** | **Low thousands** of rows in sample window — no tuning required for routine queries. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for daily investigations.
- Join to **`Dealing_CEPDailyAudit_Conditions`** on **`ConditionID`** (and often **`Date`**) to pull **property/operator/value** semantics for the condition that moved.
- Join to **`Dealing_CEPDailyAudit_CP`** / **`CPToRule`** to place the change in **full rule context**.

### 3.3 Freshness

- **ACTIVE**; sampled **max `Date` 2026-03-09**. Treat as **daily** batch aligned to **`@Date`**.

### 3.4 Gotchas

- **Fan-out across rules** — **not all duplicates are errors**; verify whether multiple rows for one `ConditionID` + `Date` are explained by **multi-rule CP attachment**.
- **`TypeOfChange` values** are **exact strings** from SP: `Condition Added To CP`, `Condition Removed from CP` — case and spacing matter in filters.
- Compare volume to **`Dealing_CEPDailyAudit_CPToRule`** — **lower here** is **expected** if **condition bundles** change less often than **CP-to-rule wiring**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Audit business date** for the condition membership event — equals **`@Date`** supplied to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** whose **CP** gained or lost a condition — from **`#Dim_CPtoRule`** explosion; may repeat across rows for multi-rule CPs. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized for readability alongside **`RuleID`**. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server context** for the rule (from CP-to-rule dimension) — ties the event to **which server stack** the rule belongs to. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CompoundPropertyID | int | YES | **CP** that gained or lost the **condition** — the **grouping entity** under the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | CP_Name | varchar(max) | YES | **CP display name** resolved via **`#CPLog`** for analyst-friendly output. (Tier 2 — SP_CEPDailyAudit) |
| 7 | ConditionID | int | YES | **Condition** that was **added** to or **removed** from the CP — join to **conditions audit** for predicate details. (Tier 2 — SP_CEPDailyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | **`Condition Added To CP`** or **`Condition Removed from CP`** — encodes membership direction. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** making the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Exact source timestamp** (`SysStartTime` / `SysEndTime` per add vs remove path). (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **not** business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
[CEP System — ConditionToCompoundProperty temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — JOIN to #CPLog for CP names, #Dim_CPtoRule for rule context
    — SysStartDate = @Date → Condition Added; SysEndDate = @Date → Condition Removed
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `CompoundPropertyID`, `ConditionID`, `LoginName`, `ChangeTime` ← condition-to-CP external / history; `RuleID`, `RuleName`, `HedgeServerID` ← `#Dim_CPtoRule`; `CP_Name` ← `#CPLog`; `TypeOfChange` ← derived from temporal start/end vs `@Date`; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **Parent CP** entity changes — same **`CompoundPropertyID`**, often same **`Date`**. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **CP-to-rule wiring** — explains **which rules** see the CP whose membership changed. |
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Condition definition** audit — **predicate** details for **`ConditionID`**. |
| `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | **Source** — current links. |
| `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | **Source** — temporal **history** of links. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | **Weekly rollup** of the same event types. |

## 7. Sample Queries

**7.1 — All condition membership changes on a date**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP
WHERE Date = '2026-03-09'
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

**7.2 — Removed conditions with CP and rule context**

```sql
SELECT
      Date
    , ConditionID
    , CompoundPropertyID
    , CP_Name
    , RuleID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP
WHERE TypeOfChange = 'Condition Removed from CP'
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — Same-day join: condition removal + CP-to-rule activity**

```sql
SELECT
      c.Date
    , c.ConditionID
    , c.CompoundPropertyID
    , c.TypeOfChange   AS ConditionToCP_Event
    , m.TypeOfChange   AS CPToRule_Event
    , m.RuleID
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP AS c
LEFT JOIN Dealing_dbo.Dealing_CEPDailyAudit_CPToRule AS m
       ON m.CompoundPropertyID = c.CompoundPropertyID
      AND m.Date = c.Date
WHERE c.Date = '2026-03-09'
ORDER BY c.ConditionID, m.RuleID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Batch: 7/8 (redo)*  
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP | Type: Table | Production Source: Dealing_staging CEP tables*


### Upstream `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_CPToRule.md`

# Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

> Daily audit trail of **Compound Property-to-Rule mapping changes** in the CEP hedging rule engine — tracks when CPs are added to, removed from, or have their truth-value toggled within rules.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily (Priority 0 — OpsDB/Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This is the **highest-volume** table in the CEPDailyAudit family (~32K rows vs ~300–3K for sibling tables). It records every time a Compound Property is added to a Rule, removed from a Rule, or has its `IsTrue` boolean polarity toggled within a rule's logic.

**Source and lineage**: Data flows from `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` (current state) and `External_Etoro_History_CompoundPropertyToRule` (temporal history). The writer SP `SP_CEPDailyAudit` uses `LAG()` window functions to detect state changes, then classifies each event.

**Freshness**: Runs daily. Active pipeline — max date 2026-03-09. 32,274 rows since Dec 2023 — high volume confirms frequent CP-to-Rule reconfiguration activity by the Dealing team.

**Why it matters**: CP-to-Rule mappings define which compound property "clauses" are active in each hedging rule. Changing these mappings directly affects eToro's order routing and hedging behavior. This audit trail supports post-incident investigation, governance oversight, and regulatory compliance.

---

## 2. Business Logic

### 2.1 Change Detection and Event Classification

**What**: The SP detects CP-to-Rule mapping changes by comparing successive system-time versions using `LAG()`.

**Columns Involved**: `TypeOfChange`, `IsTrue`, `ChangeTime`, `LoginName`

**Rules**:
- `CP Added to Rule` — CP newly mapped to a rule
- `CP Removed from Rule` — CP removed from a rule
- `Mapping Changed from Not True to True` — IsTrue flipped 0→1
- `Mapping Changed from True to Not True` — IsTrue flipped 1→0
- `LoginName` uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture identity even for removal events

### 2.2 IsTrue Polarity

**What**: Controls whether the CP must evaluate as true or false within the rule's logic.

**Columns Involved**: `IsTrue`

**Rules**:
- `IsTrue = 1` — the CP clause must be satisfied (evaluate true) to match the rule
- `IsTrue = 0` — the CP clause must NOT be satisfied — effectively an exclusion clause
- Polarity toggles are tracked as distinct `TypeOfChange` events

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date`. Moderate size (~32K rows). ROUND_ROBIN appropriate for an audit/log table with no natural join key.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP-to-Rule changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| Which CPs were added to a specific rule? | `WHERE RuleID = @id AND TypeOfChange = 'CP Added to Rule'` |
| All IsTrue polarity toggles in a range | `WHERE Date BETWEEN @start AND @end AND TypeOfChange LIKE 'Mapping Changed%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_CP | `CompoundPropertyID + Date` | Correlate CP property changes with mapping changes on the same day |
| Dealing_CEPDailyAudit_Rules | `RuleID + Date` | See rule-level changes alongside mapping changes |

### 3.4 Gotchas

- **Highest volume** of all CEPDailyAudit tables — CP-to-Rule mappings change more frequently than the entities themselves
- A single CP can be mapped to many rules, so one CP change can generate multiple CPToRule rows
- `IsTrue` semantic is counterintuitive: `IsTrue=0` doesn't mean "inactive" — it means "CP must NOT be true" (exclusion logic)
- This is one of 7 CEPDailyAudit tables, all written by the same SP

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date on which this CP-to-Rule mapping change occurred. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | ID of the CEP Rule that the Compound Property was added to or removed from. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | Name of the CEP Rule at the time of the change. Denormalized for query convenience. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | Hedge server ID associated with this Rule — identifies which hedging server processes this rule. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CompoundPropertyID | int | YES | ID of the Compound Property that was mapped to or removed from the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | CP_Name | varchar(max) | YES | Name of the Compound Property at the time of the change. Note: field named `CP_Name` (with underscore), unlike the CP table's `CPName`. (Tier 2 — SP_CEPDailyAudit) |
| 7 | IsTrue | bit | YES | Whether the CP must evaluate as True (1) or Not True (0) within the rule's logic. Controls boolean polarity of the CP clause. (Tier 2 — SP_CEPDailyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | Change event type. Values: `CP Added to Rule`, `CP Removed from Rule`, `Mapping Changed from Not True to True`, `Mapping Changed from True to Not True`. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | Application login of the user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture identity even for removal events. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | Exact timestamp of the change event (SysStartTime for additions/changes, SysEndTime for removals). (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. Not the business change time. [UNVERIFIED] (Tier 4 — inferred) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Dealing_staging CEP temporal tables | Various | LAG()-based change detection |

No Generic Pipeline mapping — CEP is an internal eToro system.

### 5.2 ETL Pipeline

```
CEP Internal System
    → Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule (current state)
    → Dealing_staging.External_Etoro_History_CompoundPropertyToRule (temporal history)
        → SP_CEPDailyAudit (LAG() change detection)
            → Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_CEPDailyAudit_Rules | Parent rule entity |
| CompoundPropertyID | Dealing_CEPDailyAudit_CP | Parent CP entity whose mapping changed |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPWeeklyAudit_CPToRule | CompoundPropertyID | Weekly rollup of same change events |

---

## 7. Sample Queries

### 7.1 All CP-to-Rule changes on a specific date
```sql
SELECT Date, RuleName, CP_Name, TypeOfChange, IsTrue, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE  Date = '2026-03-01'
ORDER BY ChangeTime;
```

### 7.2 CPs added to a specific rule over time
```sql
SELECT Date, CompoundPropertyID, CP_Name, IsTrue, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE  RuleID = 15
  AND  TypeOfChange = 'CP Added to Rule'
ORDER BY Date DESC;
```

### 7.3 All IsTrue polarity toggles in last 90 days
```sql
SELECT Date, RuleName, CP_Name, TypeOfChange, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE  Date >= DATEADD(DAY, -90, GETDATE())
  AND  TypeOfChange LIKE 'Mapping Changed%'
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: 8 (redo)*
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_CPToRule | Type: Table | Production Source: Dealing_staging CEP tables*


### Upstream `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_ListCIDMapping.md`

# Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

> Daily audit of **CID ↔ Named List** membership changes in CEP — each row is an **add** or **remove** of a **client ID** from a **Named List** used in hedging rule conditions.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |
| **PII** | **Yes — `CID` (client identifier)** |

## 1. Business Meaning

This table tracks **CID-to–Named List mapping changes** in the **Client Execution Platform (CEP)**. **Named Lists** are configuration objects holding **sets of client IDs (CIDs)** that rules can reference — for example, **include** or **exclude** specific clients from a hedging path.

**PII:** The **`CID`** column is a **direct client identifier**. This is the **CEP Daily Audit** table family member with **explicit PII**. Apply **data governance**, **access controls**, and **masking** policies consistent with **client-level** DWH objects.

**What each row means:** On business date **`Date`**, a **CID** was **added to** or **removed from** a **Named List**. Together with **`Dealing_CEPDailyAudit_NameLists`**, it forms the audit trail for **client-scoped** CEP configuration.

**Why it matters:** List membership changes can **change hedging or routing** for **individual clients**. Typical uses:

- **Compliance** — when was client **X** added or removed from list **Y**?
- **Client services** — explain behavior tied to **list membership**.
- **Risk / Dealing oversight** — review **who** changed **which** list and **when**.

**Activity note (documented sample):** About **532 rows** from **2023-12-19** through **2026-01-26**. **Sparse** activity is **expected** — the SP writes rows **only on days** when membership changes occur; many calendar days may have **zero** rows. **Last row date** lagging the documentation date does **not** by itself imply pipeline failure.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit`** — **DELETE + INSERT** for **`@Date`**. **Daily** batch (OpsDB / Service Broker). **SLA:** typically **next business day**.

## 2. Business Logic

- **Sources:** **`Dealing_staging.External_Etoro_CEP_ListCIDMappings`** (current) and **`External_Etoro_History_ListCIDMappings`** (temporal history).
- **Add vs remove:** When temporal **`SysStartDate = @Date`** → **`CID Added`**; when **`SysEndDate = @Date`** and the row is **closed** (non-sentinel end) → **`CID Deleted`** — see SP for exact **`SysEndTime`** handling.
- **`ListName`:** Resolved from **`#NameLists_Log`** (latest name by list id) — may reflect **current** naming even if the list was **renamed** after the mapping event; analysts should cross-check **`NameLists`** audit for **rename** history.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`** — **CEP user** performing the change.
- **`ChangeTime`:** **`SysStartTime`** / **`SysEndTime`** depending on add vs remove path.
- **`UpdateDate`:** **`GETDATE()`** — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN`. |
| **Clustered index** | **`Date` ASC** — primary slice for **daily** audit pulls. |
| **Scale** | **Hundreds** of rows in documented history — **full scans** on **`CID`** filters are still **cheap**, but **always apply PII policies** before exporting results. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for **daily** reconciliation.
- **`WHERE CID = @cid`** for **client-centric** history (**governed** access only).
- Join **`NameListID`** / **`ListName`** to **`Dealing_CEPDailyAudit_NameLists`** on **`Date`** when correlating **list-level** events with **per-CID** rows.

### 3.3 Freshness

- Pipeline **runs daily**; **row count** grows only on **change days**. Use **OpsDB / job** status — not row **recency** alone — to confirm health.

### 3.4 Gotchas

- **`TypeOfChange`** values: **`CID Added`**, **`CID Deleted`** — **exact** string match.
- **Low row volume** vs calendar span is **normal**.
- **PII** — never use this table in **self-service** extracts without **approval**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** of the CID mapping change — **`@Date`** for the SP partition. (Tier 2 — SP_CEPDailyAudit) |
| 2 | NameListID | int | YES | **Named List** identifier whose membership changed. (Tier 2 — SP_CEPDailyAudit) |
| 3 | ListName | varchar(max) | YES | **Human-readable list name** (from **`#NameLists_Log`**) for analyst-friendly reporting. (Tier 2 — SP_CEPDailyAudit) |
| 4 | CID | bigint | YES | **Client ID** added or removed — **PII**; join to **customer / account** dimensions only under **governance**. (Tier 2 — SP_CEPDailyAudit) |
| 5 | TypeOfChange | varchar(max) | YES | **`CID Added`** or **`CID Deleted`**. (Tier 2 — SP_CEPDailyAudit) |
| 6 | LoginName | varchar(max) | YES | **CEP application user** who performed the add/remove. (Tier 2 — SP_CEPDailyAudit) |
| 7 | ChangeTime | datetime | YES | **Exact source timestamp** of the mapping event. (Tier 2 — SP_CEPDailyAudit) |
| 8 | UpdateDate | datetime | YES | **DWH load time** via **`GETDATE()`** — **not** business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow (detail in **`.lineage.md`**):

```
[CEP System — ListCIDMappings temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ListCIDMappings  (current)
Dealing_staging.External_Etoro_History_ListCIDMappings  (history)
    ↓ JOIN #NameLists_Log (list name)
SP_CEPDailyAudit(@Date)
    — SysStartDate / SysEndDate logic → CID Added / CID Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `NameListID`, `CID`, `LoginName`, `ChangeTime` ← list-CID external / history; `ListName` ← **`#NameLists_Log`**; `TypeOfChange` ← temporal classification; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_NameLists` | **List definition** and **list-level** **`Change In CIDs`** events — companion to **per-CID** rows here. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **CP** configuration may **reference** Named Lists in **conditions** — trace upward for **full rule** context. |
| `Dealing_staging.External_Etoro_CEP_ListCIDMappings` | **Current** membership **source**. |
| `Dealing_staging.External_Etoro_History_ListCIDMappings` | **Temporal** **history** **source**. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` | **Weekly rollup** of the same events. |

## 7. Sample Queries

**7.1 — All list membership changes on a date (PII — restricted use)**

```sql
SELECT
      Date
    , NameListID
    , ListName
    , CID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE Date = '2026-01-26'
ORDER BY ListName, TypeOfChange, ChangeTime;
```

**7.2 — History for one client across lists (PII — governed access only)**

```sql
SELECT
      Date
    , ListName
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE CID = @CID
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — Count adds vs deletes by list over a period**

```sql
SELECT
      ListName
    , TypeOfChange
    , COUNT(*) AS EventCount
FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping
WHERE Date >= '2025-01-01'
GROUP BY ListName, TypeOfChange
ORDER BY ListName, TypeOfChange;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Batch: manual template reformat*  
*Tiers: 0 T1, 7 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping | Type: Table | Production Source: Dealing_staging CEP temporal tables*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_CEPDailyAudit`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_CEPDailyAudit.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_CEPDailyAudit] @Date [date] AS
BEGIN

--EXEC [Dealing_dbo].[SP_CEPDailyAudit] '20240827'
/******************************************************************************************************************************
Author: Ziv Shtizer
Date: 12.12.2023
SR-222110


**************************
** Change History
**************************
Date               	Author      	Description 
----            	----------  	----------------------------------
24-09-16            Ziv             SR-271550
									1.Changed the logic for Login Name - 
									Added Previous LoginName for changes in Rules,Conditions,Name Lists, CID etc.
									and now using coalesce(LoginName,PreviouseLoginName)
									2.Changed the 'CP Removed from Rule' logic - changed Where conditions.

******************************************************************************************************************************************************/

/************************************************Declare Parameters***********************************************************************************/

--DECLARE @Date date = DATEADD(DAY,-1,GETDATE())

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
	LEAD(r.AppLoginName,1) OVER (PARTITION BY r.RuleID ORDER BY r.SysEndTime desc) PreviousAppLoginName,
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
,ra.PreviousAppLoginName
,cast (ra.SysStartTime AS DATE) ChangeDate
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
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Name Change' TypeOfChange,
CONCAT('Previous Name',': ',ra.PreviousName) Comments,
ra.AppLoginName,
COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
ChangeTime,
ChangeDate

FROM #RulesAudit1 ra
WHERE ra.NameChange=1
AND ChangeDate =@Date

UNION ALL

SELECT 
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Description Change' TypeOfChange,
CONCAT('Previous Description',': ',ra.PreviousDescription) Comments,
ra.AppLoginName,
COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
ChangeTime,
ChangeDate
FROM #RulesAudit1 ra
WHERE ra.DescriptionChange=1  
AND ChangeDate =@Date 

UNION ALL

SELECT 
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
CASE WHEN ra.PreviousIsActive=0 THEN 'Activated' ELSE 'Deactivated' end TypeOfChange,
Null Comments,
ra.AppLoginName,
COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
ChangeTime,
ChangeDate
FROM #RulesAudit1 ra
WHERE ra.IsActiveChange=1  
AND ChangeDate =@Date

UNION ALL

SELECT 
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'HedgeServerID Change'  TypeOfChange,
CONCAT('Previous HedgeServerID',': ',ra.PreviousHedgeServerID)  Comments,
ra.AppLoginName,
COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
ChangeTime,
ChangeDate
FROM #RulesAudit1 ra
WHERE ra.HedgeServerIDChange=1  
AND ChangeDate=@Date

UNION ALL

SELECT 
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Priority Change'  TypeOfChange,
CONCAT('Previous Priority',': ',ra.PreviousPriority)  Comments,
ra.AppLoginName,
COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
ChangeTime,
ChangeDate
FROM #RulesAudit1 ra
WHERE ra.PriorityChange=1  
AND ChangeDate =@Date

UNION all 

SELECT 
@Date Date, 
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'New Rule'  TypeOfChange,
Null  Comments,
ra.AppLoginName,
COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
ChangeTime,
ChangeDate
FROM #RulesAudit1 ra
WHERE RN=1  
AND ChangeDate =@Date 
AND DATEDIFF(MINUTE,ValidFrom,ChangeTime)<=60

UNION all 

SELECT 
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
'Rule Deleted'  TypeOfChange,
Null  Comments,
 ra.AppLoginName,
 COALESCE(ra.AppLoginName,ra.PreviousAppLoginName) AS PreviousAppLoginName,
 ra.SysEndTime,
 CAST(ra.SysEndTime AS DATE) SysEndDate
 FROM #RulesAudit1 ra 
 WHERE ra.RN_Desc=1  
 AND CAST(ra.SysEndTime AS DATE) =@Date  


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
LEAD(a.AppLoginName,1) OVER (PARTITION BY a.CompoundPropertyID ORDER BY a.SysEndTime desc) PreviousAppLoginName,
CASE WHEN SysEndTime>'3000-01-01' THEN SysStartTime ELSE SysEndTime END ChangeTime,
CASE WHEN SysEndTime>'3000-01-01' THEN CAST(SysStartTime AS DATE) ELSE CAST(SysEndTime AS DATE) END ChangeDate,
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
@Date Date,
c.CompoundPropertyID
,c.Name
,'New Compound Property' TypeOfChange
,Null  Comments
,AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,ChangeTime
,ChangeDate
FROM #CPLog c
WHERE RN=1 
AND c.ChangeDate = @Date 
AND DATEDIFF(MINUTE,c.ValidFrom,c.ChangeTime)<=60

UNION ALL 

select 
@Date Date,
c.CompoundPropertyID
,c.Name
,'Name Change' TypeOfChange
,CONCAT('Previous Name: ',c.PreviousName) Comments
,AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,ChangeTime
,ChangeDate
FROM #CPLog c
WHERE c.NameChange=1 
AND c.ChangeDate =@Date

UNION ALL 

select 
@Date Date,
c.CompoundPropertyID
,c.Name
,'Compound Property Deleted' TypeOfChange
,null Comments
,AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,ChangeTime
,ChangeDate
FROM #CPLog c
WHERE c.RN_Desc=1 
AND CAST(c.SysEndTime AS DATE) =@Date


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
,LEAD(a.AppLoginName,1) OVER (PARTITION BY a.CompoundPropertyID,a.ConditionID ORDER BY a.SysEndTime DESC) PreviousAppLoginName
,a.SysStartTime
,CAST(a.SysStartTime AS DATE) AS SysStartDate
,a.SysEndTime
,CAST(a.SysEndTime AS DATE) AS SysEndDate
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
@Date Date,
ctcl.CompoundPropertyID
,ctcl.CP_Name
,ctcl.ConditionID
,'Condition Added To CP'  TypeOfChange
,ctcl.ValidFrom
,ctcl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,ctcl.SysStartTime ChangeTime
,ctcl.SysStartDate ChangeDate
,ctcl.RN
,ctcl.RN_Desc
FROM #ConditionToCP_Log ctcl
WHERE
 ctcl.SysStartDate =@Date
AND ctcl.SysStartTime<>ctcl.SysEndTime

UNION ALL 

SELECT 
@Date Date
,ctcl.CompoundPropertyID
,ctcl.CP_Name
,ctcl.ConditionID
, 'Condition Removed from CP'  TypeOfChange
,ctcl.ValidFrom
,ctcl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,ctcl.SysEndTime ChangeTime
,ctcl.SysEndDate ChangeDate
,ctcl.RN
,ctcl.RN_Desc 
FROM #ConditionToCP_Log ctcl 
WHERE
ctcl.SysEndTime<'9999-01-01' 
AND ctcl.SysStartTime<>ctcl.SysEndTime
AND ctcl.SysEndDate =@Date



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
LEAD(a.AppLoginName,1) OVER (PARTITION BY a.ConditionID ORDER BY a.SysEndTime DESC) PreviousAppLoginName,
a.SysStartTime,
cast(a.SysStartTime as DATE) SysStartDate,
a.SysEndTime,
cast(a.SysEndTime as DATE) SysEndDate,
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
@Date Date
,cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Property Change' TypeOfChange
,CONCAT('Previous Property',': ',PreviousProperty) Comments
,cl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,cl.SysStartTime ChangeTime
,cl.SysStartDate ChangeDate
FROM #Conditions_Log cl
 WHERE cl.Property<>cl.PreviousProperty AND cl.PreviousProperty IS NOT NULL 
 AND cl.SysStartDate =@Date

UNION ALL 

SELECT 
@Date
,cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Operator Change' TypeOfChange
,CONCAT('Previous Operator',': ',cl.PreviousOperator) Comments
,cl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,cl.SysStartTime
,cl.SysStartDate ChangeDate
FROM #Conditions_Log cl
 WHERE cl.Operator<>cl.PreviousOperator AND cl.PreviousOperator IS NOT NULL 
 AND cl.SysStartDate =@Date
  
UNION ALL 

SELECT 
@Date Date,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Value Change' TypeOfChange
,CONCAT('Previous Value',': ',cl.PreviousValue) Comments
,cl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,cl.SysStartTime
,cl.SysStartDate
FROM #Conditions_Log cl
 WHERE cl.Value<>cl.PreviousValue AND cl.PreviousValue IS NOT NULL 
 AND cl.SysStartDate =@Date

UNION ALL 

SELECT 
@Date Date,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'New Condition' TypeOfChange
,null Comments
,cl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,cl.SysStartTime
,cl.SysStartDate
FROM #Conditions_Log cl
 WHERE RN=1
 AND cl.SysStartDate =@Date

UNION ALL 

SELECT 
@Date Date,
cl.ConditionID
,cl.Property
,cl.Operator
,cl.Value
,'Condition Deleted' TypeOfChange
,null Comments
,cl.AppLoginName
,COALESCE(cl.AppLoginName,cl.PreviousAppLoginName) AS PreviousAppLoginName
,cl.SysEndTime
,cl.SysStartDate
FROM #Conditions_Log cl
 WHERE RN=1
 AND cl.SysStartDate =@Date AND cl.RN_Desc=1


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
,ROW_NUMBER() OVER (PARTITION BY a.RuleID,a.CompoundPropertyID ORDER BY a.SysStartTime) RN
,ROW_NUMBER() OVER (PARTITION BY a.RuleID,a.CompoundPropertyID ORDER BY a.SysEndTime DESC) RN_desc
,a.AppLoginName
,LEAD(a.AppLoginName,1) OVER (PARTITION BY a.RuleID,a.CompoundPropertyID ORDER BY a.SysEndTime DESC) PreviousAppLoginName
,a.SysStartTime
,cast(a.SysStartTime AS DATE) SysStartDate
,a.SysEndTime  
,cast(a.SysEndTime AS DATE) SysEndDate
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
@Date Date,
crl.RuleID
,crl.CompoundPropertyID
,crl.Name CP_Name
,crl.Value IsTrue
,'CP Added to Rule' TypeOfChange
,crl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,crl.SysStartTime ChangeTime
FROM #CPToRule_Log crl
WHERE crl.SysStartDate =@Date 
AND RN=1

UNION ALL

SELECT 
@Date Date,
crl.RuleID
,crl.CompoundPropertyID
,crl.Name CP_Name
,crl.Value
,CASE WHEN crl.Value=1 THEN 'Mapping Changed from Not True to True' ELSE 'Mapping Changed from True to Not True' end TypeOfChange
,crl.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,crl.SysStartTime
FROM #CPToRule_Log crl
WHERE crl.SysStartDate =@Date 
AND RN>1 
AND crl.Value<>crl.PreviousValue

UNION ALL

SELECT 
@Date Date,
crl.RuleID
,crl.CompoundPropertyID
,crl.Name CP_Name
,crl.Value
,'CP Removed from Rule' TypeOfChange
,crl.AppLoginName
,COALESCE(crl.AppLoginName,crl.PreviousAppLoginName) AS PreviousAppLoginName
,crl.SysEndTime
FROM #CPToRule_Log crl
WHERE crl.SysEndDate =@Date 
AND crl.SysEndTime<'9999-01-01' 
AND crl.SysStartTime<>crl.SysEndTime 


--Name Lists 
IF OBJECT_ID('tempdb..#NameLists_Log') IS NOT NULL 
DROP TABLE #NameLists_Log   
CREATE TABLE #NameLists_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT  a.NamedListID
	  ,a.Name
	  ,a.Statment
	  ,a.PeriodicIntervalSec
	  ,a.NamedListTypeID
	  ,a.LastUpdated
	  ,a.ValidFrom
	  ,a.DbLoginName
	  ,a.AppLoginName
	  ,LEAD(a.AppLoginName,1) OVER (PARTITION BY a.NamedListID ORDER BY a.SysEndTime DESC) PreviousAppLoginName
	  ,a.SysStartTime
	  ,a.SysEndTime
	  ,a.HostName	 
,CAST(a.SysStartTime AS DATE) SysStartDate
,CAST(a.SysEndTime AS DATE) SysEndDate
,ROW_NUMBER() OVER (PARTITION BY a.NamedListID ORDER BY a.SysStartTime) RN
,ROW_NUMBER() OVER (PARTITION BY a.NamedListID ORDER BY a.SysEndTime desc) RN_desc

FROM 
(
SELECT NamedListID
	  ,Name
	  ,Statment
	  ,PeriodicIntervalSec
	  ,NamedListTypeID
	  ,LastUpdated
	  ,ValidFrom
	  ,DbLoginName
	  ,AppLoginName
	  ,SysStartTime
	  ,SysEndTime
	  ,HostName	
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
@Date Date,
nll.NamedListID
,nll.Name
,CASE WHEN RN=1 THEN 'New Name List' ELSE 'Change In CIDs' end TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,nll.SysStartTime ChangeTime
,nll.SysStartDate ChangeDate
FROM #NameLists_Log nll
WHERE nll.SysStartDate =@Date

UNION ALL 

SELECT
@Date Date,
nll.NamedListID
,nll.Name
,CASE WHEN nll.RN_desc=1 THEN 'Name List Deleted' ELSE 'Change In CIDs' end TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,COALESCE(nll.AppLoginName,nll.PreviousAppLoginName) AS PreviousAppLoginName
,nll.SysEndTime ChangeTime
,nll.SysEndDate ChangeDate
FROM #NameLists_Log nll 
WHERE SysEndTime<'9999-01-01' 
AND nll.SysEndDate =@Date



--Mapping CID To Name List
IF OBJECT_ID('tempdb..#ListCIDMapping_Log') IS NOT NULL 
DROP TABLE #ListCIDMapping_Log 
CREATE TABLE #ListCIDMapping_Log
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT a.NamedListID
	  ,a.CID
	  ,a.ValidFrom
	  ,a.DbLoginName
	  ,a.AppLoginName
	  ,LEAD(a.AppLoginName,1) OVER (PARTITION BY a.NamedListID,a.CID ORDER BY a.SysEndTime desc) PreviousAppLoginName
	  ,a.SysStartTime
	  ,a.SysEndTime
,CAST(a.SysStartTime AS DATE) SysStartDate
,CAST(a.SysEndTime AS DATE) SysEndDate
,b.Name 
FROM 
(
SELECT *
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
@Date Date,
nll.NamedListID
,nll.Name
,nll.CID
,'CID Added' TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,COALESCE(AppLoginName,PreviousAppLoginName) AS PreviousAppLoginName
,nll.SysStartTime ChangeTime
,nll.SysStartDate ChangeDate
FROM #ListCIDMapping_Log nll
WHERE SysStartDate =@Date

UNION ALL 

SELECT
@Date Date,
nll.NamedListID
,nll.Name
,CID
,'CID Deleted'  TypeOfChange
,nll.ValidFrom
,nll.AppLoginName
,COALESCE(nll.AppLoginName,nll.PreviousAppLoginName) AS PreviousAppLoginName
,nll.SysEndTime ChangeTime
,nll.SysEndDate ChangeDate
FROM #ListCIDMapping_Log nll
WHERE SysEndTime<'9999-01-01' 
AND nll.SysEndDate =@Date




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
SELECT @Date Date

---------------------------------------------------------------------------------------------------------------------------------
--INSERT INTO tables

--Rules 
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_Rules

SELECT 
@Date Date,
RuleID,
Name,
Description,
HedgeServerID,
Priority,
TypeOfChange,
Comments,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM 
#RuleChangesFinal rcf
Where rcf.Date= @Date 

--Compound Property
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_CP WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_CP

SELECT 
@Date Date,
ctr.RuleID,
ctr.RuleName,
rcf.CompoundPropertyID,
Name CPName,
HedgeServerID,
TypeOfChange,
Comments,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM 
#CPChangesFinal rcf
left JOIN #Dim_CPtoRule ctr
ON rcf.CompoundPropertyID=ctr.CompoundPropertyID
Where rcf.Date =@Date

--conditions
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_Conditions

SELECT 
@Date Date,
RuleID,
RuleName,
HedgeServerID,
rcf.ConditionID,
rcf.Property,
rcf.Operator,
rcf.Value,
TypeOfChange,
Comments,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM 
#Conditions_ChangesFinal  rcf
LEFT JOIN #Dim_ConditionRule dcr
ON rcf.ConditionID=dcr.ConditionID
WHERE rcf.Date=@Date 

--condition to cp
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

SELECT 
@Date Date,
RuleID,
RuleName,
HedgeServerID,
rcf.CompoundPropertyID,
rcf.CP_Name,
rcf.ConditionID,
TypeOfChange,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM 
#ConditionToCP_ChangesFinal   rcf
LEFT JOIN #Dim_CPtoRule dcr
ON rcf.CompoundPropertyID = dcr.CompoundPropertyID
WHERE rcf.Date=@Date

--cp to rule
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_CPToRule WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

SELECT 
@Date Date,
rcf.RuleID,
RuleName,
HedgeServerID,
rcf.CompoundPropertyID,
rcf.CP_Name,
IsTrue,
TypeOfChange,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM 
#CPToRule_ChangesFinal  rcf
LEFT JOIN #Dim_CPtoRule dcr
ON rcf.CompoundPropertyID = dcr.CompoundPropertyID
where rcf.Date=@Date


--Name lists
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_NameLists WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_NameLists

SELECT 
@Date Date,
NamedListID,
Name,
TypeOfChange,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM 
#NameLists_ChangesFinal rcf
WHERE rcf.Date=@Date


--list cid mapping
DELETE FROM Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping WHERE Date=@Date
INSERT INTO Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

SELECT 
@Date Date,
NamedListID,
Name,
CID,
TypeOfChange,
PreviousAppLoginName AS AppLoginName,
ChangeTime,
GETDATE()
FROM #ListCIDMapping_ChangesFinal lccf
WHERE lccf.Date=@Date 

END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_dbo.SP_CEPDailyAudit` | synapse_sp | Dealing_dbo | SP_CEPDailyAudit | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_CEPDailyAudit.sql` |
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
| `Dealing_dbo.Dealing_CEPDailyAudit_Rules` | synapse | Dealing_dbo | Dealing_CEPDailyAudit_Rules | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_Rules.md` |
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | synapse | Dealing_dbo | Dealing_CEPDailyAudit_CP | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_CP.md` |
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | synapse | Dealing_dbo | Dealing_CEPDailyAudit_Conditions | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_Conditions.md` |
| `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` | synapse | Dealing_dbo | Dealing_CEPDailyAudit_ConditionToCP | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_ConditionToCP.md` |
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | synapse | Dealing_dbo | Dealing_CEPDailyAudit_CPToRule | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_CPToRule.md` |
| `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping` | synapse | Dealing_dbo | Dealing_CEPDailyAudit_ListCIDMapping | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_CEPDailyAudit_ListCIDMapping.md` |

