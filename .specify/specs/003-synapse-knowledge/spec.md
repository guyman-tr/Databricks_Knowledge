# Feature Specification: Synapse DWH Semantic Knowledge

**Feature Branch**: `003-synapse-knowledge`
**Created**: 2026-02-28
**Status**: Draft
**Replaces**: 003-map-synapse-warehouse, 006-generate-synapse-knowledge-wiki
**Input**: Adapt the sql-semantic-doc pipeline (originally built for production SQL Server QA) for Synapse DWH objects, producing a semantic knowledge layer that enables analysts and business users to get expert-quality query answers from an AI assistant.

## Core Difference From the Production Pipeline

The original sql-semantic-doc pipeline targets **DBAs doing QA and code review** on production SQL Server objects backed by an SSDT repo. This pipeline targets a fundamentally different audience:

**Analysts and business users who query the Synapse DWH and need an AI that understands the data as deeply as a senior analyst would.**

| Aspect | Production Pipeline | This Pipeline (DWH) |
|--------|--------------------|--------------------|
| Audience | DBAs, code reviewers | Analysts, business users, AI query agents |
| DDL Source | SSDT repo files | Synapse metadata views (`sys.*`, `INFORMATION_SCHEMA`) via MCP |
| Query Hints | `WITH (NOLOCK)` required | Not needed (Synapse uses snapshot isolation) |
| FK Constraints | Some explicit FKs exist | No enforced FKs in Synapse -- all inferred |
| App Code Analysis | C# repos (application services) | Replaced by ETL orchestration analysis |
| Output Focus | Object correctness, code quality | Query guidance, business meaning, lineage, performance |
| Upstream Knowledge | IS the source | Inherited read-only from upstream knowledge sources (see config) |

## Two-Layer Architecture

### Layer 1: Upstream Knowledge Sources (Authoritative Starting Point)

Previously generated semantic wikis for production schemas are the **authoritative baseline** for all Synapse documentation. They have already undergone the full code-is-king pipeline on production sources -- JOIN analysis, procedure logic extraction, live data sampling, application code tracing, and cross-object enrichment. We inherit that work; we do not re-derive it. Upstream sources are configured in `.specify/Configs/dwh-semantic-doc-config.json` under `upstream_knowledge_sources`.

Each upstream source provides:
- **Wiki files**: Deeply validated objects with business meaning, column descriptions, FK resolution, procedure logic -- these are the #1 source in the authority hierarchy
- **FK lookup reference**: Column-to-table mappings for ID resolution in the DWH
- **Semantic index**: Cross-referenced business concepts

The upstream sources are never modified by this pipeline. They are read-only but authoritative -- Synapse-layer analysis extends and supplements them, it does not override their production-level semantic mappings.

### Layer 2: Synapse DWH Knowledge (Built Here)

The adapted 14-phase pipeline runs against Synapse objects, producing wiki files under `knowledge/synapse/Wiki/`.

## User Scenarios & Testing

### User Story 1 - Document a Synapse Table End-to-End (Priority: P1)

As a data knowledge engineer, I need to run the full pipeline against a single Synapse table and produce a comprehensive wiki file that an AI assistant can use to answer analyst queries about that table.

**POC Object**: `DWH_dbo.Dim_Position` (direct lineage to production `Trade.PositionTbl`)

**Why this priority**: Validates the entire scaffold -- all 14 phases, cross-layer lineage, and the query-brain output format -- on one concrete object before scaling.

**Independent Test**: Run the pipeline on `Dim_Position`, then ask an AI assistant "What does StatusID mean in Dim_Position?" and verify it returns the resolved enum values with business context, not just "tinyint."

**Acceptance Scenarios**:

1. **Given** the pipeline runs on `Dim_Position`, **When** Phase 1 completes, **Then** all columns, types, distribution key, and index type are captured from Synapse metadata
2. **Given** the pipeline runs on `Dim_Position`, **When** Phase 10A/10B (Lineage) completes, **Then** the wiki file traces back to `Trade.PositionTbl` in the upstream production wiki with a direct path reference
3. **Given** the generated wiki file, **When** an AI reads it, **Then** it can answer "How should I query open positions?" with the correct JOIN pattern and StatusID filter

---

### User Story 2 - Resolve All ID Columns to Business Meaning (Priority: P1)

As an analyst, when I encounter a column like `SettlementTypeID` in the DWH, I need the AI to know that 0=CFD, 1=Real, 2=TRS, etc. without me having to look it up manually.

**Why this priority**: The #1 complaint from analysts is cryptic ID columns. Resolving them is the highest-value output.

**Independent Test**: For `Dim_Position`, verify every `*ID` column has its lookup values resolved in the wiki file's Elements section.

**Acceptance Scenarios**:

1. **Given** no FKs exist in Synapse, **When** Phase 4 runs, **Then** ID columns are resolved via production Dictionary tables using the upstream FK lookup reference
2. **Given** Phase 5 (JOIN Analysis) discovers SPs that reference `Dim_Position`, **When** those SPs contain value mappings in comments or CASE expressions, **Then** the mappings are captured

---

### User Story 3 - Query Advisory Output (Priority: P2)

As an analyst, I need the wiki to tell me HOW to query a table effectively -- which columns to filter on, which JOINs are recommended, and what performance pitfalls to avoid.

**Why this priority**: This is what differentiates the query-brain from a simple data dictionary.

**Independent Test**: The generated wiki file includes a "Query Advisory" section with at least 3 practical query examples and performance notes about distribution keys.

**Acceptance Scenarios**:

1. **Given** a Synapse table uses HASH distribution on `PositionID`, **When** the wiki is generated, **Then** it notes "Filter or JOIN on PositionID for best performance (HASH distribution key)"
2. **Given** the wiki file, **When** an analyst asks "show me closed positions for CID 12345", **Then** the AI produces a query using the correct StatusID value and recommended JOINs

---

### Edge Cases

- What if a Synapse table has no clear production source (derived entirely from DWH calculations)? → Document it. Synapse SP code is the authority (tier 2 becomes effective tier 1). Lineage section notes "DWH-derived, no production source."
- What if Synapse metadata views return incomplete information for external tables?
- What if the upstream production wiki doesn't cover a referenced production table yet?
- What about Synapse objects that exist in multiple schemas (e.g., a view in `BI_DB_dbo` over a table in `DWH_dbo`)?

## Adapted Pipeline Phases

### Phase 01 - Structure Analysis (adapted from DDL Analysis)
Query `INFORMATION_SCHEMA.COLUMNS`, `sys.tables`, `sys.indexes`, `sys.pdw_table_distribution_properties` via Synapse MCP. Captures columns, types, distribution strategy, index type.

### Phase 02 - Live Data Sampling (minor adaptation)
Same approach. No `WITH (NOLOCK)` needed. Synapse snapshot isolation handles reads safely.

### Phase 03 - Distribution Analysis (extended)
Same GROUP BY approach for enum/flag detection. Additionally captures Synapse distribution type (HASH/ROUND_ROBIN/REPLICATE) and distribution column.

### Phase 04 - Lookup Resolution (adapted from FK Resolution)
No explicit FKs in Synapse. Instead, use the upstream FK lookup reference to match `*ID` columns to production Dictionary tables. Query those lookup tables (either in Synapse if replicated, or reference the upstream wiki).

### Phase 05 - JOIN Analysis (adapted)
Instead of grepping an SSDT repo, query `sys.sql_modules` in Synapse to find SPs/views/functions that reference the target object. Extract JOIN patterns from the SQL text.

### Phase 06 - Business Logic Discovery (same approach)
Column groups, self-references, data clusters. Same MCP queries.

### Phase 07 - View Dependency Scan (adapted)
Query `sys.sql_expression_dependencies` in Synapse instead of grepping repo files.

### Phase 08 - Procedure Reference Scan (adapted)
Query `sys.sql_modules` for all objects referencing the target. Categorize as WRITER/MODIFIER/READER/DELETER.

### Phase 09 - Procedure Logic Extraction (adapted)
Read SP code from `sys.sql_modules` instead of SSDT files. Same extraction logic for column assignments, modifications, conditionals. **Must include both ETL writer SPs AND at least 10 downstream reader SPs.** Scan reader SPs for CASE/IF patterns that reveal column semantics independently (e.g., `CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD'`). Reader SPs are a critical independent validation source — they are not filler.

### Phase 09b - ETL Orchestration Analysis (replaces App Code Analysis)
DWH SPs are ETL, not app-called. Map refresh schedules, SP execution order, dependencies between load processes.

### Phase 10 - Atlassian Knowledge Scan (MANDATORY — same approach)
Search Confluence/Jira for business context. Same validation against code evidence. **This phase is mandatory for every pipeline run and must not be deferred or skipped.** The Atlassian tools (Rovo Search, Confluence page fetch, Jira search) are available. Search for the target table name, key business concepts (e.g., "settlement type", "copy trade"), and related terms.

### Phase 11 - Generate Documentation (new template)
Query-brain template: Business Meaning, Query Advisory, Elements with resolved enums, Lineage, Performance Notes, Sample Queries. **Column descriptions from upstream wiki must be inherited verbatim — no paraphrasing, summarizing, or rewriting.** No environment-specific statistics (row counts, percentages, date ranges) in element descriptions. Confidence tier tagging required. A `.review-needed.md` sidecar must be produced alongside every wiki file.

### Phase 12 - Cross-Object Enrichment (extended)
Same gap detection + fix approach. Extended to cross-layer: links Synapse objects to upstream production wiki files.

### Phase 10A (Upstream Wiki Bridge) + Phase 10B (Column Lineage) — formerly Phase 13
Trace each Synapse table back through its populating SP to the lake import to the production source table. Link to the upstream wiki file for each production source. Phase 10A (Steps 1/1b/1c/3) runs BEFORE Phase 11 — traces to production source and reads upstream wiki. Phase 10B (Steps 2/4/5/6) runs AFTER Phase 11 — produces `.lineage.md` file. Additionally, infer Domain tags from the production lineage chain — tag the Synapse object with the Domain(s) of its source BU schemas (per spec 002's many-to-many model). For DWH-derived objects with no production source, Domain is inferred from the Synapse schema or consuming views/reports.

### Phase 14 (NEW) - Query Advisory Metadata
Distribution keys, recommended JOIN patterns, common WHERE clauses, performance notes, data freshness / refresh schedule.

## Clarifications

### Session 2026-03-01

- Q: When the pipeline re-runs on an object that already has a wiki file, what happens? → A: Full regeneration when triggered by change (not scheduled or wasteful). The wiki file is overwritten entirely with fresh output; the previous version is preserved in git history for diffing. Cross-object enrichment (Phase 12) is additive and idempotent — consistent with the DB_Schema pipeline model.
- Q: For Synapse tables with no production source (DWH-derived), what is the authority source? → A: Document them with Synapse SP code as authority (tier 2 becomes effective tier 1). Lineage section notes "DWH-derived, no production source." All semantic meaning comes from the SP code that creates/maintains the object.
- Q: Should the pipeline assign Domain tags, and which phase handles it? → A: Yes, Phase 10A/10B (Production Lineage Mapping, formerly Phase 13) infers Domain tags from the production lineage chain. Since it traces which production schemas feed each Synapse object, it can automatically tag with the Domain(s) of the source BU schemas (per spec 002's many-to-many model).

### Session 2026-03-02 (Post-POC Debriefing — Dim_Position First Run)

- Q: What happens if Phase 10 (Atlassian Knowledge Scan) is skipped? → A: It must not be skipped. Elevated to mandatory in constitution v1.3.0. The first run skipped Phase 10 entirely, losing business context from ~240 referencing SPs across BI, compliance, dealing, and finance.
- Q: Should Phase 9 cover downstream reader SPs, not just ETL writers? → A: Yes. At least 10 downstream readers must be scanned for CASE/IF patterns on each column. These reveal business semantics independently (e.g., `CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD'`). The first run only read ETL writer SPs, missing this independent validation.
- Q: How to handle columns not found in the upstream wiki source table? → A: Search the entire upstream wiki folder (views, related tables, history schemas) before concluding a column is undocumented. The first run only read `Trade.PositionTbl.md`, missing columns documented on `Trade.PositionTreeInfo`, `Trade.OpenPositionEndOfDay`, `Trade.PositionForExternalUse`, and `History.Position`.
- Q: What if no source documents a column? → A: Flag as `[UNVERIFIED]` in the wiki, add to `.review-needed.md` sidecar, write only mechanically inferred facts (type, nullability, observed values). Never fabricate from column names. The first run incorrectly guessed meanings for DLTOpen/DLTClose, IsAirDrop, CommissionByUnits, FullCommission, and IsDiscounted.
- Q: Should sampling results override upstream wiki enum values? → A: Never. Sampling adds newly discovered values; it never drops documented upstream values absent from a filtered sample. The first run dropped SettlementTypeID values 2 (TRS) and 3 (CMT) because they filtered to 2025 data only.
- Q: Should element descriptions include runtime statistics? → A: No. Phase 11 rule #3: "No environment-specific statistics." The first run included "~85% Buy", "~69% leverage=1", "~79% settled", "2.64B rows" in descriptions. These belong in query advisory or working notes.

### Session 2026-03-30 (UC ALTER deploy — regression prevention)

- **Failure**: Batch UC deploy emitted `ALTER COLUMN Tier 4` / `Tier 1` … — parser treated `Tier` and `4` as separate tokens (`PARSE_SYNTAX_ERROR` near `4`). **Cause**: generator treated documentation tier legend rows as column names. **Rule**: `ALTER COLUMN` names MUST match real DDL columns only; tier tags appear only inside `COMMENT '...'` strings.
- **Failure**: `ALTER COLUMN Organic/Paid` without quoting — slash broke Databricks SQL. **Fix**: backtick-quote identifiers with `/` (and other special characters): `` `Organic/Paid` ``.
- **Failure**: `ALTER TABLE Not in Generic Pipeline mapping - not exported…` — prose pasted as object name. **Fix**: comment-only stub or omit file; never executable `ALTER` without `main.{uc_table}`.
- **Failure**: Multiline Databricks error text in `_deploy-index.md` broke markdown tables. **Fix**: sanitize failure strings to one line in deploy batch scripts.

## Requirements

### Functional Requirements

- **FR-001**: Pipeline MUST query Synapse metadata via MCP for all structural information (no SSDT dependency)
- **FR-002**: Pipeline MUST resolve ID columns to business-readable values using upstream Dictionary/lookup tables
- **FR-003**: Pipeline MUST trace lineage from Synapse objects to production sources using upstream wiki references
- **FR-004**: Output MUST include query advisory information (recommended JOINs, filters, performance notes)
- **FR-005**: Output MUST follow the query-brain template, not the QA/code-review template
- **FR-006**: Pipeline MUST be executable via a Cursor command (`/build-semantic-layer-dwh`). Re-runs fully regenerate the wiki file (overwrite); git history preserves the diff. Regeneration is triggered by change (upstream wiki update, new SPs discovered, etc.), not scheduled.
- **FR-007**: Upstream knowledge sources MUST be configured in `dwh-semantic-doc-config.json`, not hardcoded
- **FR-008**: Pipeline MUST work against any Synapse schema listed in the config
- **FR-009**: Pipeline MUST produce a `.review-needed.md` sidecar alongside each wiki file, listing all Tier 4 (column-name-inferred) items with specific questions for domain experts. Columns without any source documentation must be flagged `[UNVERIFIED]`, not given fabricated descriptions.
- **FR-010**: Pipeline MUST NOT include environment-specific statistics (row counts, percentages, date ranges) in wiki column descriptions. These belong in working notes or query advisory metadata, not in the Elements table.
- **FR-011**: Pipeline MUST search the entire upstream wiki folder (tables, views, related objects across all schemas) before labeling any column as DWH-specific or unresolved. The source table wiki alone is insufficient — columns may be documented on related tables, views, or history schemas.
- **FR-012 (UC ALTER — column identifiers)**: Generated `.alter.sql` MUST emit `ALTER COLUMN` only for real Synapse/UC column names taken from the wiki Elements table (and DDL). MUST NOT emit `ALTER COLUMN Tier 1` … `ALTER COLUMN Tier 5` — those strings are documentation-tier markers inside prose, not columns. (2026-03-30: batch deploy failures from Tier rows treated as columns.)
- **FR-013 (UC ALTER — special identifiers)**: Databricks SQL identifiers that contain `/`, spaces, or other non-regular characters MUST be backtick-quoted in `ALTER COLUMN` (e.g. `` ALTER COLUMN `Organic/Paid` COMMENT ... ``). (2026-03-30: `Dim_Channel` failed until quoted.)
- **FR-014 (UC ALTER — no prose table targets)**: When Generic Pipeline / UC has no resolved `uc_table`, the pipeline MUST emit a **comment-only stub** `.alter.sql` (no executable `ALTER TABLE` lines) or omit the file per generator contract. MUST NOT paste wiki prose such as `Not in Generic Pipeline mapping - not exported to Gold/UC` into the `ALTER TABLE` object position. (2026-03-30: invalid SQL and failed deploys.)
- **FR-015 (Post-gen validation)**: After generating or changing `.alter.sql` for a schema, run `python tools/audit_alter_uc_mapping.py knowledge/synapse/Wiki/{Schema}` (directory accepted; structural pass; optional `--mapping`). The audit MUST flag bogus Tier columns and unquoted slash identifiers in addition to invalid `ALTER TABLE` targets. A full-repo scan may still list **legacy** issues in other schemas until those files are migrated — the **deploy target schema** MUST pass before batch UC deploy.
- **FR-016 (Deploy index integrity)**: Batch deploy tooling that writes failure reasons into `_deploy-index.md` MUST sanitize error text to a **single line** (strip newlines/pipes/truncate) so markdown tables cannot split across rows. (2026-03-30: corrupted `_deploy-index.md` from multiline Databricks errors.)
- **FR-017 (Wiki ↔ ALTER COMMENT text)**: For every object with both `{Object}.md` and `{Object}.alter.sql`, each column’s `COMMENT` literal MUST match the wiki **## 4. Elements** description for that column name (same encoding as `sql_string_for_comment` in `merge_wiki_column_comments_into_alter.py`). Prevents wrong text on wrong columns and drift. Verified by `tools/audit_wiki_alter_comment_parity.py` (schema: `--under {Schema}`; single: path to `.md`). Cursor: `.cursor/scripts/validate-wiki.ps1` enforces per object when `.alter.sql` exists. Documented in `.cursor/rules/semantic-layer-core/batch-orchestration.mdc` and Cursor commands `/build-wiki-dwh`, `/generate-alter-dwh`, `/deploy-alter-dwh`.

### Key Entities

- **SynapseObject**: A table, view, SP, or function in the Synapse DWH
- **UpstreamSource**: A previously documented object in an upstream knowledge source (e.g., production wiki)
- **LineageChain**: Production table -> lake export -> Synapse SP -> Synapse table
- **QueryAdvisory**: Recommended query patterns, performance notes, distribution key guidance

## Success Criteria

### Measurable Outcomes

- **SC-001**: Pipeline successfully documents `Dim_Position` with all 14 phases completing
- **SC-002**: Every `*ID` column in `Dim_Position` has resolved business-readable values
- **SC-003**: Lineage is traced from `Dim_Position` back to `Trade.PositionTbl` with a path reference to the upstream wiki
- **SC-004**: Generated wiki file includes at least 3 practical query examples
- **SC-005**: An AI assistant reading the wiki can answer "What does StatusID=2 mean in Dim_Position?" correctly
- **SC-006**: Pipeline is reusable -- can be run against any Synapse table by changing the target object name
- **SC-007**: Upstream knowledge sources are configurable -- adding a new source only requires a config entry, not code changes
- **SC-008**: For each schema **in active UC deploy** (e.g. `DWH_dbo`), `python tools/audit_alter_uc_mapping.py knowledge/synapse/Wiki/{Schema}` exits 0 (no bogus Tier-as-column lines, no unquoted `Col/Name` identifiers, valid `ALTER TABLE` targets). Other schemas may be non-zero until legacy `.alter.sql` files are fixed.
- **SC-009**: No **newly generated** `.alter.sql` in an active deploy schema contains `ALTER TABLE` followed by English prose or “Not in Generic Pipeline…” as the object name (structural audit)
- **SC-010**: For each schema targeted for UC comment deployment, `python tools/audit_wiki_alter_comment_parity.py --under {Schema}` exits 0 (wiki Elements ↔ `ALTER COLUMN ... COMMENT` parity per FR-017), or the team explicitly accepts drift with a tracked remediation plan
