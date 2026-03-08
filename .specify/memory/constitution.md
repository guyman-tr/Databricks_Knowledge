<!--
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
  - dwh-semantic-doc.md → Add Databricks pre-flight check (advisory)
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

**Source authority hierarchy (higher wins):**

1. **Upstream semantic wikis** (production wiki, previously generated docs) -- already validated through the full code-is-king pipeline on production sources; this is our starting point, not a fallback. The upstream wiki has already done JOIN analysis, procedure logic extraction, live data sampling, application code tracing, and cross-object enrichment on the production layer. We inherit that work.
2. **Live code** (Synapse SP definitions, view definitions, function bodies in `sys.sql_modules`) -- Synapse-layer ground truth for ETL transformations and DWH-specific logic
3. **Live data** (sampling results, actual enum values, row patterns) -- empirical evidence from the DWH layer
4. **Metadata views** (`INFORMATION_SCHEMA`, `sys.*`, distribution properties) -- structural truth
5. **Confluence / Jira** (business documentation) -- intent and context, frequently stale
6. **Human descriptions** (column comments, verbal explanations) -- lowest weight

**Why upstream wiki is #1:** We are not recreating production knowledge -- we start from the Synapse DWH layer. The upstream wiki has already gone through an even stricter code-is-king analysis on the production source code (SSDT repos, C# application code, live production data). Synapse SPs primarily import and transform data FROM those production sources. When a Synapse column is a passthrough from production, the upstream wiki's deep semantic analysis is more authoritative than anything we can re-derive from Synapse ETL code.

**When Synapse code wins over upstream wiki:** Synapse live code (tier 2) is authoritative for DWH-specific logic: new derived columns, ETL transformations, aggregation logic, and any business rules that exist ONLY in the DWH layer. If a Synapse SP adds a computed column that doesn't exist in production, the SP definition is the sole authority.

**Recency tiebreaker:** Within the same tier, newer evidence outweighs older. A Confluence page from 2025 outweighs one from 2021. A wiki file regenerated last week outweighs one from six months ago. Always prefer the freshest source at a given tier.

**Collision resolution in output:** If Phase 2 (sampling) discovers values that contradict Phase 10 (Atlassian), the sampled values are authoritative. The Atlassian source is cited as "historical context" with its date, so analysts can see the evolution. Undocumented values discovered via code or data are flagged for investigation, not silently dropped. If Synapse live data reveals enum values not in the upstream wiki, both sources are valid -- the wiki provides the known mappings and the new values are flagged for investigation upstream.

**Verbatim inheritance:** When a column exists in an upstream wiki, copy its description verbatim into the DWH wiki. Do not paraphrase, summarize, or rewrite. Only APPEND DWH-specific notes if the DWH transforms that column differently (e.g., "DWH note: renamed from X" or "DWH note: derived via SP Y"). The upstream wiki's descriptions have already been validated through the full code-is-king pipeline on production sources — rewriting them introduces errors and loses context.

**Sampling adds, never subtracts:** When querying Synapse for enum values or lookup mappings, start from the upstream wiki's documented values as the baseline. Synapse sampling may discover additional values not yet in the upstream wiki — include them and flag for upstream investigation. Never drop documented upstream values because they were absent from a filtered or time-bounded sample. A value documented in the upstream wiki is assumed valid until explicitly deprecated in code.

**Full upstream search scope:** Before labeling any column as "DWH-specific" or "unresolved," search the entire upstream wiki folder — tables, views, related objects, and all schemas — not just the source table's wiki file. Columns frequently originate from views (e.g., `Trade.OpenPositionEndOfDay`), related tables (e.g., `Trade.PositionTreeInfo`), or history schemas. A simple grep across the upstream wiki folder catches these. Only after an exhaustive search returns no results may a column be flagged as DWH-specific or unresolved.

### III. Accuracy Over Coverage
It is better to have 50 objects with correct, verified metadata than 500 with guesses. Every column description, relationship, and lineage trace must be validated against the actual data or code. When uncertain, mark it explicitly rather than fabricating.

**No fabrication:** If no source (upstream wiki, Synapse code, live data, or Atlassian) documents a column's meaning, do NOT invent a description from the column name or general domain knowledge. Instead: (1) write only what can be mechanically inferred (data type, nullability, observed values), (2) flag the description as `[UNVERIFIED]` in the wiki, and (3) add it to the review sidecar for domain expert review. Acronyms must not be expanded from general knowledge (e.g., "DLT" could mean many things — never assume). Flag-style columns (e.g., `IsAirDrop`) must not be described with assumed business semantics.

**Confidence tiers:** Every element description carries an implicit or explicit confidence tier based on its source:

| Tier | Source | Authority |
|------|--------|-----------|
| 5 | Domain expert / reviewer correction | Absolute — human-verified override |
| 1 | Upstream wiki verbatim | Highest — already code-validated |
| 2 | Synapse SP code / downstream CASE patterns | High — direct code evidence |
| 3 | Live data distribution analysis | Medium — empirical but context-free |
| 4 | Column name inference | Low — must be flagged `[UNVERIFIED]` |

Tier 4 descriptions must be visually flagged in the output so human reviewers can prioritize corrections. Higher tiers always win over lower tiers when sources conflict. Tier 5 is the only tier that overrides Tier 1 (upstream wiki).

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
- **Every pipeline run must produce THREE output files**: wiki (`.md`), review sidecar (`.review-needed.md`), and Databricks ALTER script (`.alter.sql`). The ALTER script is the primary deliverable — a pipeline run without it is incomplete
- **ALTER scripts must target a validated Unity Catalog object.** The UC fully-qualified name (`catalog.schema.table`) must be resolved by querying Unity Catalog directly — never inferred from Synapse naming conventions alone. If the Databricks connection is unavailable, the ALTER script must be generated with an `-- UNVALIDATED UC TARGET` header and the inferred name treated as a placeholder until validated
- Every domain package must include at least 3 test questions with expected agent responses
- Gap analysis (what's NOT in the lake) is as important as mapping what IS
- No environment-specific statistics in wiki descriptions (row counts, percentages, date ranges) — these belong in working notes or query advisory, not in element descriptions
- Phase 10 (Atlassian Knowledge Scan) is mandatory for every pipeline run — it must not be deferred or skipped

## Governance

This constitution governs all phases of the Data Knowledge Platform. Amendments require documentation and agreement between project contributors. The canonical metadata schema (Phase 1 output) becomes binding once ratified.

**Version**: 1.6.0 | **Ratified**: 2026-02-25 | **Last Amended**: 2026-03-08
