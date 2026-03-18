<!--
Sync Impact Report — v1.10.0 → v1.11.0 (MINOR)

Version change: 1.10.0 → 1.11.0
Bump rationale: Second-pass speckit.analyze review identified residual bugs and inconsistencies
  in the v1.10.0 fixes across all 6 focus areas. 19 issues remediated in two passes.
  Pass 1 (10 issues): (1) Phase 2 gate checked only at Phase 11, wasting Phases 3-10; added
  MCP pre-flight and IMMEDIATE gate. (2) Phase 4 Steps 3↔4 violated Constitution IX; reordered.
  (3) Phase 8 Phase 2 prerequisite missing. (4) Phase 11 Rule 9 / Phase 10 hierarchy 5 vs 8
  tiers; aligned. (5) Phase 2 B2 only 2 of 5 schemas; generalized. (6) Phase 2 B1b "Stop here"
  without reading DDL; now reads + samples. (7) Phase 4 searched only DWH_dbo Dim_*; expanded.
  (8) Phase 13 Step 1c no independent trigger; added Trigger B. (9) Phase 5/6 prerequisites
  missing supplementary schemas. (10) Config supplementary_knowledge_schemas phases incomplete.
  Pass 2 — self-audit (9 issues): (11) Batch orchestration step label collision (two `b` items);
  relabeled a/b/c/d. (12) Phase 2 B1b gated on migration timestamps only — missed tables like
  Dim_AccountType with GETDATE() refresh; made unconditional when B1 is empty. (13) Phase 2
  Decision Summary table didn't include B1b route; added. (14) Phase 4 Step 4 re-queried
  DWH_Migration tables already sampled in Phase 2 B1b; now consumes B1b results. (15) Phase 9
  didn't read staging/external DDLs for column renames; added instruction. (16) Config
  external_table_paths not referenced by any rule; made authoritative source, Phase 2 B2 and
  Phase 13 Step 1c now read from config. (17) Phase 13 Trigger B grep imprecise; added FROM
  clause anchoring and context verification. (18) Phase 11 Rule 11 tier-to-star mapping
  collapsed 8 tiers to 6 without noting it; made explicit with table. (19) Phase 2 error
  handling missing MCP unavailability and DWH_Migration table-not-found rows; added both.

Pipeline rules updated:
  - 02-live-data-sampling.mdc → B1b now reads DWH_Migration DDL AND samples live Synapse
    table for value maps. Also checks BI_DB_Migration. B2 expanded to ALL 5 target schemas
    + CopyFromLake. Circular import detection note enhanced.
  - 04-lookup-resolution.mdc → Steps 3↔4 reordered: repo Dim_ search (now Step 3, was 4)
    runs before MCP query (now Step 4, was 3). Step 3 expanded to search DWH_Migration,
    BI_DB_Migration, DWH_staging, CopyFromLake. Dim_AccountType example added.
  - 05-join-analysis.mdc → Phase 2 added to prerequisites. Step 3 adds supplementary
    schema awareness (DWH_Migration tables as valid JOIN targets).
  - 06-business-logic-discovery.mdc → Prerequisites updated to reference supplementary
    schema lookups from Phase 4 and supplementary JOINs from Phase 5.
  - 08-procedure-reference-scan.mdc → Phase 2 added to prerequisites.
  - 10-atlassian-knowledge-scan.mdc → Validation hierarchy aligned with Constitution
    Section II (8 tiers, not 5).
  - 11-generate-documentation.mdc → Rule 9 hierarchy aligned with Constitution Section II
    (8 tiers including Tier 5, 2b, 3b, and 4 split). DWH_Migration Tier 2b mentioned.
  - 13-production-lineage-mapping.mdc → Step 1c: added independent Trigger B (writer SP
    scan). External table DDL search expanded to ALL 5 target schemas + CopyFromLake.
    LOCATION path fallback added. Circular import table expanded with CopyFromLake pattern.

Config updated:
  - dwh-semantic-doc-config.json → supplementary_knowledge_schemas descriptions updated:
    phases list expanded to 2/4/5/8/9/13. Added input_use field per schema. DWH_Migration
    now notes live table sampling. Added external_table_paths section listing all 5 schemas.

Core rules updated:
  - batch-orchestration.mdc → Added MCP pre-flight check (once per batch) before first
    object. Phase 2 gate is now IMMEDIATE — checked right after Phase 2, before Phase 3.
    Prevents wasting Phases 3-10 on objects that will fail at Phase 11. Phase 13 step
    list updated to include Step 1c.

Previous report (v1.9.0 → v1.10.0 (MINOR)):

Sync Impact Report — v1.9.0 → v1.10.0 (MINOR)

Version change: 1.9.0 → 1.10.0
Bump rationale: Cross-artifact consistency analysis (speckit.analyze) identified 20 findings
  across 6 focus areas. Seven CRITICAL issues remediated: Phase 2 skip mechanism, Phase 13/11
  execution ordering, source hierarchy / confidence tier unification, blacklisted objects as
  lineage inputs, DWH_Migration as supplementary knowledge source, circular datalake import
  detection, and Constitution IX violations in 4 phase rules.

Modified principles:
  - Section II: Unified source authority hierarchy and confidence tiers into ONE table.
    Added Tier 2b (migration DDLs) and Tier 4-Atlassian vs Tier 4-Inferred distinction.
    Removed sys.sql_modules references (Constitution IX violation). Promoted migration
    schema encoding from Quality Gates to Section II. Added "blacklisted objects are
    lineage inputs" principle with input-value table by blacklist category.

Pipeline rules updated:
  - 01-structure-analysis.mdc → Fixed sys.sql_modules reference in view checklist.
  - 02-live-data-sampling.mdc → Hard gate with PHASE 2 GATE marker. Error handling
    now fails-hard for target table errors. Tier B uses repo Globs (not INFORMATION_SCHEMA).
    Added B1b for DWH_Migration table check. Added LOCATION path parsing rule.
    Added circular import detection in external table check.
  - 05-join-analysis.mdc → Added Phase 2+3+4 as prerequisites.
  - 06-business-logic-discovery.mdc → Added Phase 4+5 as prerequisites.
  - 08-procedure-reference-scan.mdc → Removed duplicated ETL source fallback chain.
    Now consumes Phase 2 results instead of re-running discovery.
  - 09b-etl-orchestration-analysis.mdc → Fixed INFORMATION_SCHEMA query, replaced
    with repo grep + known orchestration table list.
  - 10-atlassian-knowledge-scan.mdc → Fixed sys.sql_modules reference in hierarchy.
  - 11-generate-documentation.mdc → Added Phase 13 Steps 1/1b/3 as mandatory gate.
    Added execution order clarification showing Phase 13 split model.
  - 12-cross-object-enrichment.mdc → Pre-Read now includes blacklisted input objects.
  - 13-production-lineage-mapping.mdc → Added Step 1c (circular import detection with
    LOCATION path parsing). Split execution model documented in prerequisites.
    Staging table name parsing added to Step 2.

Config updated:
  - dwh-semantic-doc-config.json → Added supplementary_knowledge_schemas section
    with DWH_Migration, BI_DB_Migration, DWH_staging, CopyFromLake.

Core rules updated:
  - batch-orchestration.mdc → Explicit execution order with phase numbers as
    identifiers (not sequence). Phase 13 split documented. Failure severity table
    added (HARD vs SOFT failures per phase).

Previous report (v1.8.0 → v1.9.0 (MINOR)):

Sync Impact Report — v1.8.0 → v1.9.0 (MINOR)

Version change: 1.8.0 → 1.9.0
Bump rationale: Codified three critical process failures discovered during DWH_dbo Batch 1
  (Dim_ActionType and Dim_ClosePositionReason). Root causes: (1) Phase 2 skipped, leading to
  fabricated column descriptions and wrong source attributions; (2) ETL source discovery run
  exhaustively by default instead of as a tiered fallback; (3) migration staging schema names
  (`DWH_Migration` vs `BI_DB_Migration`) misread, causing source system misattribution.

Modified principles:
  - Quality Gates: Added mandatory Phase 2 gate (cannot proceed to Phase 11 without sampling).
  - Quality Gates: Added tiered ETL fallback chain rule (A→B→C, stop when source confirmed).
  - Quality Gates: Added migration staging schema encoding rule (schema name = source system).

Pipeline rules updated:
  - 02-live-data-sampling.mdc → Step 6 restructured as tiered fallback chain (A/B/C tiers).
    Tier A: timestamp analysis + SP_Dictionaries. Tier B: staging/external tables.
    Tier C (fallback only): NoDbObjectsScripts, ADF JSONs, broad SP grep.
  - 08-procedure-reference-scan.mdc → SP_Dictionaries check is now Tier A with explicit
    stop-here instruction. DWH_Migration fallback is Tier C. Absence documented explicitly.
  - 11-generate-documentation.mdc → Phase 2 + Phase 8 declared as hard prerequisite gates.

Previous report (v1.7.0 → v1.8.0 (MINOR)

Version change: 1.7.0 → 1.8.0
Bump rationale: Updated Quality Gates to accommodate two-command pipeline
  decomposition (build-wiki-dwh + write-objects-dwh). The prior gate required
  every pipeline *run* to produce THREE files including ALTER script. Now:
  every documented *object* must have FOUR files (wiki + sidecar + lineage +
  ALTER) produced across the full pipeline — not necessarily in one run.
  Added .lineage.md as a required output file.

Modified principles:
  - Quality Gates: Changed from per-run atomicity to per-object completeness.
    Added .lineage.md as fourth required file. Clarified that decomposed
    commands each produce a subset — object is complete when all four exist.

Pipeline rules requiring updates:
  - None — plan.md and tasks.md already implement this model.

Previous report (v1.6.0 → v1.7.0):

Sync Impact Report — v1.6.0 → v1.7.0 (MINOR)

Version change: 1.6.0 → 1.7.0
Bump rationale: Codified "Repo First, MCP Second" as a NON-NEGOTIABLE
  constitution principle (IX). The locally cloned SSDT repos (Dataplatform,
  DB_Schema) contain all DDLs, SP code, view definitions, and table structures.
  MCP is ONLY for live data queries (Phases 2-3). Querying the database for
  structural/code metadata that exists in repo files is now a rule violation.

Modified principles:
  - Added: IX. Repo First, MCP Second (NON-NEGOTIABLE). NEVER seek from the
    database what you can get from the repo. MCP is ONLY for live data queries.

Pipeline rules requiring updates:
  - 01-structure-analysis.mdc → Remove "CRITICAL: DDL Source is Synapse
    Metadata, NOT a Repo" header. Replace with repo-first approach.
  - All phase rules that query sys.* or INFORMATION_SCHEMA for structural
    metadata → redirect to Dataplatform repo file reads.
  - semantic-layer-core/repo-first-access.mdc → NEW shared rule (already
    created) with full enforcement table and repository paths.

Previous report (v1.5.0 → v1.6.0):

Sync Impact Report — v1.5.0 → v1.6.0 (MINOR)

Version change: 1.5.0 → 1.6.0
Bump rationale: ALTER scripts must target validated UC objects. The prior
  naming convention (DWH_dbo.Fact_CustomerAction → dwh.fact_customeraction)
  was pure inference and produced ALTER scripts targeting non-existent UC
  tables. Now: query Unity Catalog directly to resolve the actual
  catalog.schema.table before generating any ALTER statement.

Modified principles:
  - Quality Gates: Added: ALTER scripts must target a validated UC object.
    UC fully-qualified name resolved by querying UC, not inferred.
    If Databricks unavailable, ALTER script gets UNVALIDATED header.

Pipeline rules requiring updates:
  - build-semantic-layer-dwh.md (formerly dwh-semantic-doc.md) → Add Databricks pre-flight check (advisory)
  - 11-generate-documentation.mdc → Replace UC naming inference with
    UC Object Resolution algorithm (query UC directly)

Previous report (v1.4.0 → v1.5.0):
  Databricks ALTER script (.alter.sql) is THE primary output.
  The entire pipeline exists to produce machine-consumable metadata for
  Unity Catalog. The ALTER script is now a mandatory, constitution-level
  output alongside the wiki and review sidecar.

Modified principles:
  - I. Agent-First Knowledge: Added: the Databricks ALTER script is the
    ULTIMATE deliverable. Wiki and sidecar are intermediate artifacts.
  - Quality Gates: Added: every run must produce .alter.sql with table +
    column COMMENTs within UC's 1024-char limit.

Pipeline rules requiring updates:
  - 11-generate-documentation.mdc → THREE files per object (wiki + sidecar + .alter.sql)

Previous report (v1.3.0 → v1.4.0):
  Add reviewer feedback loop (Tier 5, corrections, glossary).
  Enables domain experts to correct pipeline output and have corrections
  persist across reruns. Adds global glossary for cross-table domain terms.

Modified principles:
  - III. Accuracy Over Coverage:
    (d) Tier 5 added — domain expert / reviewer correction. Absolute
        authority, overrides all other tiers including Tier 1.
    (e) Reviewer corrections — .review-needed.md sidecar gains a
        "Reviewer Corrections" section. Pipeline reads this FIRST on
        rerun and applies as Tier 5 overrides.
    (f) Domain glossary — knowledge/glossary.md holds cross-table
        domain terms (acronyms, value maps). Tier 5 authority.
        Pipeline reads before Phase 4 and Phase 11.

Added sections: none
Removed sections: none

Pipeline rules requiring updates:
  - 11-generate-documentation.mdc   → add rules 14-16 (corrections, glossary, Tier 5)
  - 04-lookup-resolution.mdc        → add glossary consultation step
  - canonical-schema.md             → document sidecar corrections format

Specs requiring updates: none (operational change, not functional requirement)
Templates requiring updates: none

Follow-up TODOs: none

Previous report (v1.2.0 → v1.3.0):
  Codified quality guardrails from Dim_Position POC first-run debriefing.
  Added Tiers 1-4, verbatim inheritance, sampling-adds-never-subtracts,
  full upstream search, no fabrication, mandatory review sidecar.
  See git history for full v1.3.0 sync impact report.
-->

# Data Knowledge Platform Constitution

## Core Principles

### I. Agent-First Knowledge (NON-NEGOTIABLE)
Every knowledge artifact produced by this project must be machine-readable and consumable by the Databricks AI assistant. Human readability is a bonus, not the goal. If a piece of knowledge can't be programmatically parsed, routed, and served by an agent, it doesn't ship.

**The Databricks ALTER script is the ULTIMATE deliverable.** The wiki documentation and review sidecar are intermediate artifacts that feed the final output: a `.alter.sql` file containing `ALTER TABLE ... SET TBLPROPERTIES ('comment' = ...)` and `ALTER TABLE ... ALTER COLUMN ... COMMENT '...'` statements ready to execute against Unity Catalog. Every column description must fit within UC's 1024-character limit. This script IS the metadata that powers the Databricks AI assistant — everything else in the pipeline exists to produce it.

### II. Code Is King (NON-NEGOTIABLE)
When information from different sources conflicts, the hierarchy is absolute. The production pipeline's constitution (DB_Schema, Section XII) establishes the principle: JOIN analysis beats explicit FKs beats naming heuristics -- because "the application code reveals the TRUE relationships." This DWH pipeline inherits that principle and extends it: the upstream semantic wiki IS the output of that strict production analysis, so it starts as the authoritative baseline for everything we document here.

**Unified source authority and confidence tier hierarchy (higher wins):**

The source authority hierarchy and confidence tiers are ONE system. Each source has both an authority rank (which wins in conflicts) and a confidence tier (tagged on element descriptions).

| Rank | Source | Confidence Tier | Tag in Elements | Notes |
|------|--------|----------------|-----------------|-------|
| **0** | Domain expert / reviewer correction | Tier 5 | `(Tier 5 — domain expert)` | Absolute override. Only source that beats upstream wiki. Applied via `.review-needed.md` corrections or `glossary.md`. |
| **1** | Upstream semantic wikis (production wiki, previously generated docs) | Tier 1 | `(Tier 1 — upstream wiki, {source})` | Already validated through full code-is-king pipeline on production sources. Starting point, not fallback. |
| **2** | Live code (Synapse SP definitions, view definitions, function bodies — read from **Dataplatform SSDT repo**, NOT from `sys.sql_modules`) | Tier 2 | `(Tier 2 — Synapse code, {SP/view name})` | Synapse-layer ground truth for ETL transformations and DWH-specific logic. |
| **2b** | DWH_Migration / BI_DB_Migration tables (migration staging DDLs in SSDT repo) | Tier 2 | `(Tier 2 — migration DDL, {schema}.{table})` | Source of frozen dimension data migrated from legacy systems. Essential for tables with no active ETL. |
| **3** | Live data (sampling results, actual enum values, row patterns) | Tier 3 | `(Tier 3 — live data)` | Empirical evidence from the DWH layer. |
| **3b** | Structural metadata (DDL columns, types, distribution — from SSDT repo) | Tier 3 | `(Tier 3 — DDL)` | Structural truth. Always from repo files, never from `INFORMATION_SCHEMA` or `sys.*` (Constitution IX). |
| **4** | Confluence / Jira (business documentation) | Tier 4-Atlassian | `(Tier 4 — Confluence/Jira, {source})` | Business meaning and intent. Frequently stale. Not flagged `[UNVERIFIED]` but lower authority than code/data. |
| **5** | Column name inference / general knowledge | Tier 4-Inferred | `[UNVERIFIED] (Tier 4 — inferred)` | Lowest confidence. MUST be flagged `[UNVERIFIED]` in output. |

**Why upstream wiki is #1:** We are not recreating production knowledge -- we start from the Synapse DWH layer. The upstream wiki has already gone through an even stricter code-is-king analysis on the production source code (SSDT repos, C# application code, live production data). Synapse SPs primarily import and transform data FROM those production sources. When a Synapse column is a passthrough from production, the upstream wiki's deep semantic analysis is more authoritative than anything we can re-derive from Synapse ETL code.

**When Synapse code wins over upstream wiki:** Synapse live code (tier 2) is authoritative for DWH-specific logic: new derived columns, ETL transformations, aggregation logic, and any business rules that exist ONLY in the DWH layer. If a Synapse SP adds a computed column that doesn't exist in production, the SP definition is the sole authority.

**Migration staging schemas encode the source system (Tier 2 — migration DDL):** The staging schema in a `NoDbObjectsScripts` migration DDL or a `DWH_Migration`/`BI_DB_Migration` table is NOT arbitrary — it identifies the origin:

| Schema Pattern | Source System | Example |
|----------------|--------------|---------|
| `DWH_Migration.X` | Legacy on-premises **DWH SQL Server** | `Dim_AccountType` — migrated from old DWH, frozen, no production equivalent |
| `BI_DB_Migration.X` | Legacy on-premises **BI_DB** production SQL Server | BI_DB-specific tables like reporting aggregations |
| `DWH_staging.X` | Active lake/Databricks pipeline (regular ETL) | `etoro_Dictionary_ActionType` — refreshed via Generic Pipeline |
| `CopyFromLake.X` | Alternative lake import path | Some schemas use this instead of DWH_staging |

These schemas are supplementary knowledge sources configured in `dwh-semantic-doc-config.json` under `supplementary_knowledge_schemas`. Their tables are NOT documentation targets but their DDLs MUST be consulted during ETL source discovery (Phase 2), procedure scanning (Phase 8), and lineage mapping (Phase 13).

**Blacklisted objects are lineage inputs, not just exclusions:** External tables (`Ext_*`), staging tables, etl_source tables, and utility tables are blacklisted from wiki documentation but their DDLs in the SSDT repo contain essential lineage and reference information. The pipeline MUST read their DDLs when tracing lineage for DWH tables they feed. "Blacklisted for output" does NOT mean "invisible for input."

Specific blacklist categories that serve as knowledge inputs:

| Blacklist Category | Input Use |
|-------------------|-----------|
| `staging` (Ext_*, DWH_staging) | LOCATION paths reveal production source. Column lists show renames. |
| `etl_source` (etoro_*) | Direct lake-read tables — trace through to production source via Generic Pipeline. |
| `utility` (Dim_Date) | Reference dimension for DateID resolution. Read its DDL for date hierarchy columns. |
| `system` (DataLakeTableStatus, etc.) | ETL orchestration metadata — query for refresh frequencies in Phase 9B. |
| All others (backup, test, junk, switch, partition, replication, validation, poc) | No input value — truly excluded. |

**Recency tiebreaker:** Within the same tier, newer evidence outweighs older. A Confluence page from 2025 outweighs one from 2021. A wiki file regenerated last week outweighs one from six months ago. Always prefer the freshest source at a given tier.

**Collision resolution in output:** If Phase 2 (sampling) discovers values that contradict Phase 10 (Atlassian), the sampled values are authoritative. The Atlassian source is cited as "historical context" with its date, so analysts can see the evolution. Undocumented values discovered via code or data are flagged for investigation, not silently dropped. If Synapse live data reveals enum values not in the upstream wiki, both sources are valid -- the wiki provides the known mappings and the new values are flagged for investigation upstream.

**Verbatim inheritance:** When a column exists in an upstream wiki, copy its description verbatim into the DWH wiki. Do not paraphrase, summarize, or rewrite. Only APPEND DWH-specific notes if the DWH transforms that column differently (e.g., "DWH note: renamed from X" or "DWH note: derived via SP Y"). The upstream wiki's descriptions have already been validated through the full code-is-king pipeline on production sources — rewriting them introduces errors and loses context.

**Sampling adds, never subtracts:** When querying Synapse for enum values or lookup mappings, start from the upstream wiki's documented values as the baseline. Synapse sampling may discover additional values not yet in the upstream wiki — include them and flag for upstream investigation. Never drop documented upstream values because they were absent from a filtered or time-bounded sample. A value documented in the upstream wiki is assumed valid until explicitly deprecated in code.

**Full upstream search scope:** Before labeling any column as "DWH-specific" or "unresolved," search the entire upstream wiki folder — tables, views, related objects, and all schemas — not just the source table's wiki file. Columns frequently originate from views (e.g., `Trade.OpenPositionEndOfDay`), related tables (e.g., `Trade.PositionTreeInfo`), or history schemas. A simple grep across the upstream wiki folder catches these. Only after an exhaustive search returns no results may a column be flagged as DWH-specific or unresolved.

### III. Accuracy Over Coverage
It is better to have 50 objects with correct, verified metadata than 500 with guesses. Every column description, relationship, and lineage trace must be validated against the actual data or code. When uncertain, mark it explicitly rather than fabricating.

**No fabrication:** If no source (upstream wiki, Synapse code, live data, or Atlassian) documents a column's meaning, do NOT invent a description from the column name or general domain knowledge. Instead: (1) write only what can be mechanically inferred (data type, nullability, observed values), (2) flag the description as `[UNVERIFIED]` in the wiki, and (3) add it to the review sidecar for domain expert review. Acronyms must not be expanded from general knowledge (e.g., "DLT" could mean many things — never assume). Flag-style columns (e.g., `IsAirDrop`) must not be described with assumed business semantics.

**Confidence tiers:** Every element description carries an explicit confidence tier based on its source. The tiers are defined in the unified hierarchy table in Section II. Key rules:

- **Tier 5** (domain expert) is absolute — overrides all others including Tier 1
- **Tier 1** (upstream wiki) is the highest non-human authority — already code-validated
- **Tier 2** (Synapse code / migration DDLs) — direct code evidence
- **Tier 3** (live data / DDL structure) — empirical or structural
- **Tier 4-Atlassian** (Confluence/Jira) — business meaning, frequently stale, not flagged `[UNVERIFIED]`
- **Tier 4-Inferred** (column name guessing) — MUST be flagged `[UNVERIFIED]` in output

Higher tiers always win over lower tiers when sources conflict. Only Tier 5 overrides Tier 1.

**Review sidecar:** Every wiki file generation must produce a companion `.review-needed.md` file alongside the wiki, listing all Tier 4 items and specific questions for domain experts. This is not interactive during generation — it is a post-generation review artifact that surfaces what the pipeline could not resolve from code or data alone.

**Reviewer corrections (inbound feedback):** The `.review-needed.md` sidecar includes a `## Reviewer Corrections` section where domain experts record corrections. On rerun, the pipeline MUST read this section FIRST and apply corrections as Tier 5 overrides before regenerating. Corrections marked with `Scope = glossary` must also be checked against `knowledge/glossary.md` for cross-table applicability. Resolved items should be carried forward (not deleted) with a `[RESOLVED]` marker.

**Domain glossary:** `knowledge/glossary.md` contains domain-wide terms, acronym expansions, and value maps confirmed by domain experts. All entries are Tier 5 authority. The pipeline MUST read this file before generating any wiki documentation (Phase 11) or resolving lookups (Phase 4). Glossary entries override any pipeline-inferred expansions — the pipeline must NOT infer alternative meanings from column names, code comments, or general knowledge when a glossary entry exists.

### IV. Incremental Delivery
The project spans 7 specifications across production SQL Server, Synapse DWH, Data Lake, and Unity Catalog. Each phase delivers independently usable output. No phase should block on perfection of a prior phase -- deliver what's ready, iterate on what's not.

### V. Canonical Metadata Schema
All knowledge -- regardless of source layer (production, Synapse, lake, UC) -- must conform to a single, agreed-upon metadata schema. This schema defines what a "known object" looks like: name, schema, type, columns, relationships, lineage, description, domain, tags. Deviations require explicit justification.

### VI. Lineage Is First-Class
Every object and column must trace back to its upstream source(s). Lineage is not optional metadata -- it is the backbone of the knowledge system. The agent needs lineage to answer "where does this data come from?" and "what transformations happened?"

### VII. Domain Boundaries
Knowledge is organized into domains (Trading, Payments, Risk, Revenue, etc.). Each domain is self-contained with its own knowledge package. Cross-domain relationships are explicit edges, not implicit assumptions. The agent uses domain boundaries for routing.

### VIII. Don't Rebuild What Exists
Existing upstream knowledge sources — such as semantic wikis generated for production schemas — are consumed as-is. We extend the methodology to new schemas and layers; we don't re-derive what has already been mapped. Upstream sources are declared in `dwh-semantic-doc-config.json` and referenced by path during lineage tracing and lookup resolution.

### IX. Repo First, MCP Second (NON-NEGOTIABLE)
**NEVER seek from the database what you can get from the repo.** The locally cloned SSDT / SQL project repositories (Dataplatform, DB_Schema) contain DDLs, stored procedure code, view definitions, function definitions, and table structures as version-controlled `.sql` files. These are the source of truth for all structural and code-based information.

**MCP is ONLY for live data queries**: `SELECT TOP N`, `COUNT(*)`, `GROUP BY`, `MIN/MAX`, `DISTINCT` — operations that require actual row data not present in DDL files. That's Phases 2-3 (Live Data Sampling and Distribution Analysis). Nothing else.

Querying a database via MCP for metadata that exists as a file on disk (e.g., `INFORMATION_SCHEMA.COLUMNS`, `sys.sql_modules`, `sys.tables`, `sys.indexes`) is a rule violation — it is slower, fragile, wasteful of context window, and redundant with the repo. See `.cursor/rules/semantic-layer-core/repo-first-access.mdc` for the full enforcement table and repository paths.

## Data Stack Scope

This project covers the full eToro data path:
- **Production SQL Server**: Source of truth for business data (multiple business unit schemas)
- **Data Lake**: Raw exports via the Generic Pipeline (hourly/daily)
- **Synapse DWH**: Incremental imports with ETL transformations (SPs, functions, views)
- **Unity Catalog (Databricks)**: Target catalog where metadata, descriptions, and tags are published

Knowledge flows downstream: Production -> Lake -> Synapse -> Unity Catalog. Metadata flows upstream: we gather knowledge at every layer and propagate it back to UC.

## Quality Gates

- No spec proceeds to implementation without validation against the canonical metadata schema
- Column descriptions must fit Unity Catalog's 1024-character limit
- **Every documented object must ultimately have FOUR output files** across the full pipeline: wiki (`.md`), review sidecar (`.review-needed.md`), lineage map (`.lineage.md`), and Databricks ALTER script (`.alter.sql`). The ALTER script is the primary deliverable. In a decomposed pipeline (wiki build + write-objects), these files are produced by different commands — `build-wiki-dwh` produces the first three, `write-objects-dwh` produces the ALTER script. An object is not fully complete until all four exist
- **ALTER scripts must target a validated Unity Catalog object.** The UC fully-qualified name (`catalog.schema.table`) must be resolved by querying Unity Catalog directly — never inferred from Synapse naming conventions alone. If the Databricks connection is unavailable, the ALTER script must be generated with an `-- UNVALIDATED UC TARGET` header and the inferred name treated as a placeholder until validated
- **Phase 2 (Live Data Sampling) is a mandatory hard gate IMMEDIATELY after Phase 2, before Phase 3.** Documentation cannot proceed without live data sampling. Phase 2 produces a machine-readable `PHASE 2 GATE: PASSED/FAILED` marker. The gate is checked immediately after Phase 2 — if FAILED or missing, the object fails and skips to the next object. Phases 3-10 do NOT execute. Phase 11 also checks the gate as a safety net. MCP connectivity is verified once per batch before the first object. Target table errors (timeout, not found, permission denied) are HARD FAIL — the object cannot be documented. See `02-live-data-sampling.mdc` for the completion gate specification and `batch-orchestration.mdc` for the MCP pre-flight check.
- **ETL source discovery uses a tiered fallback chain — do NOT run all lookup methods by default.** Tier A (timestamp analysis + SP_Dictionaries grep) covers ~80% of cases at minimal cost. Tier B (staging/external table checks via repo Globs — Constitution IX) runs only when Tier A is inconclusive. Tier C (NoDbObjectsScripts, ADF JSONs, broad SP grep) runs only when both Tiers A and B come up empty. Running Tier C by default wastes context and produces noise.
- **Migration staging schema names encode the source system.** Now codified in Section II with the full schema-to-source mapping table. See Section II for the authoritative reference. Supplementary knowledge schemas (DWH_Migration, BI_DB_Migration, DWH_staging, CopyFromLake) are configured in `dwh-semantic-doc-config.json` under `supplementary_knowledge_schemas`.
- Every domain package must include at least 3 test questions with expected agent responses
- Gap analysis (what's NOT in the lake) is as important as mapping what IS
- No environment-specific statistics in wiki descriptions (row counts, percentages, date ranges) — these belong in working notes or query advisory, not in element descriptions
- Phase 10 (Atlassian Knowledge Scan) is mandatory for every pipeline run — it must not be deferred or skipped

## Governance

This constitution governs all phases of the Data Knowledge Platform. Amendments require documentation and agreement between project contributors. The canonical metadata schema (Phase 1 output) becomes binding once ratified.

**Version**: 1.11.0 | **Ratified**: 2026-02-25 | **Last Amended**: 2026-03-18
