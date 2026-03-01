# Tasks: Data Knowledge Platform

**Input**: Design documents from `specs/master/` + `.specify/specs/001-007`
**Prerequisites**: plan.md, research.md, data-model.md, quickstart.md, 7 feature specs

**Organization**: Tasks grouped by spec (each spec = a project-level user story). Specs are the unit of incremental delivery.

## Format: `[ID] [P?] [Spec] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Spec]**: Which spec this task belongs to (e.g., S01, S03, S07)
- File paths are relative to repo root

---

## Phase 1: Setup

**Purpose**: Project structure, configs, pipeline scaffold

- [ ] T001 Create `knowledge/` folder structure per plan.md: `synapse/Wiki/`, `coverage/`, `columns/mappings/`, `columns/descriptions/`, `columns/lineage/`, `domains/`
- [ ] T002 Verify `.specify/Configs/dwh-semantic-doc-config.json` has correct paths to upstream wiki sources in DB_Schema repo
- [ ] T003 [P] Verify Synapse MCP connection works — run a test query via `execute_sql_read_only` against `INFORMATION_SCHEMA.TABLES`
- [ ] T004 [P] Verify Databricks MCP connection works — run a test query against Unity Catalog
- [ ] T005 [P] Verify Atlassian MCP connection works — search Confluence for a known page

---

## Phase 2: Foundational — Spec 001: Canonical Schema (P1) 🎯

**Purpose**: Define the canonical metadata schema and connect upstream wiki. BLOCKS all downstream specs.

**Goal**: A documented schema convention that all wiki files conform to, plus verified upstream wiki consumption.

**Independent Test**: Map 5 trading platform objects from the upstream wiki to the canonical schema without data loss.

- [ ] T006 [S01] Review the existing Phase 11 template in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` and document the canonical schema fields (object name, schema, type, columns, relationships, lineage, description, domain, tags) in `knowledge/canonical-schema.md`
- [ ] T007 [S01] Verify upstream wiki path in `dwh-semantic-doc-config.json` — read 3 wiki files from DB_Schema `etoro/Wiki/` and confirm they parse into canonical schema fields
- [ ] T008 [S01] Map 5 trading platform objects (e.g., `Trade.PositionTbl`, `Trade.Mirror`, `Customer.Customer`, `Dictionary.StatusType`, `Trade.OrderTbl`) from upstream wiki → canonical schema. Document any gaps in `knowledge/canonical-schema.md`
- [ ] T009 [S01] Validate schema across layers — take 3 Synapse objects from `DWH_dbo` schema, describe using canonical schema, confirm compatibility
- [ ] T010 [S01] Add source attribution convention to `knowledge/canonical-schema.md` — document how each metadata element tracks its source and authority tier

**Checkpoint**: Canonical schema documented. Upstream wiki consumption verified. All downstream specs can reference this schema.

---

## Phase 3: Spec 003 — Synapse DWH Pipeline POC (P1) 🎯 MVP

**Goal**: Run the full 14-phase pipeline on `DWH_dbo.Dim_Position` and produce a complete wiki file.

**Independent Test**: Ask an AI "What does StatusID mean in Dim_Position?" and get resolved enum values with business context.

### Structure & Sampling (Phases 1-3)

- [ ] T011 [S03] Run Phase 01 (Structure Analysis) on `Dim_Position` — query `INFORMATION_SCHEMA.COLUMNS`, `sys.tables`, distribution properties via Synapse MCP. Save raw output to working notes.
- [ ] T012 [S03] Run Phase 02 (Live Data Sampling) on `Dim_Position` — sample top rows, NULLs, distinct counts via Synapse MCP
- [ ] T013 [S03] Run Phase 03 (Distribution Analysis) on `Dim_Position` — enum/flag detection via GROUP BY, capture distribution type (HASH/ROUND_ROBIN/REPLICATE)

### Relationship Discovery (Phases 4-6)

- [ ] T014 [S03] Run Phase 04 (Lookup Resolution) on `Dim_Position` — resolve `*ID` columns using upstream FK lookup reference + production Dictionary tables
- [ ] T015 [S03] Run Phase 05 (JOIN Analysis) on `Dim_Position` — query `sys.sql_modules` for SPs/views referencing Dim_Position, extract JOIN patterns
- [ ] T016 [S03] Run Phase 06 (Business Logic Discovery) on `Dim_Position` — analyze column groups, hierarchies, data clusters

### Dependency & Code Analysis (Phases 7-9b)

- [ ] T017 [S03] Run Phase 07 (View Dependency Scan) on `Dim_Position` — query `sys.sql_expression_dependencies` for views referencing this table
- [ ] T018 [S03] Run Phase 08 (Procedure Reference Scan) on `Dim_Position` — find all SPs that read/write this table via `sys.sql_modules`
- [ ] T019 [S03] Run Phase 09 (Procedure Logic Extraction) — read top SPs from Phase 08, extract column assignments and business logic
- [ ] T020 [S03] Run Phase 09b (ETL Orchestration Analysis) — map refresh schedule and SP execution order for Dim_Position's load chain

### Context & Documentation (Phases 10-14)

- [ ] T021 [S03] Run Phase 10 (Atlassian Knowledge Scan) — search Confluence/Jira for Dim_Position, positions, trading context
- [ ] T022 [S03] Run Phase 11 (Generate Documentation) — produce `knowledge/synapse/Wiki/DWH_dbo/Dim_Position.md` using the query-brain template
- [ ] T023 [S03] Run Phase 12 (Cross-Object Enrichment) — link to upstream wiki for `Trade.PositionTbl`, enrich descriptions
- [ ] T024 [S03] Run Phase 13 (Production Lineage Mapping) — trace Dim_Position → lake export → Trade.PositionTbl. Infer Domain tag from source schema.
- [ ] T025 [S03] Run Phase 14 (Query Advisory Metadata) — add distribution key notes, recommended JOINs, sample queries

### Validation

- [ ] T026 [S03] Validate wiki file: every `*ID` column has resolved values, lineage traces to production, 3+ query examples present
- [ ] T027 [S03] Test with AI: ask 3 questions about Dim_Position and verify answers use wiki content correctly

**Checkpoint**: One complete Synapse table documented end-to-end. Pipeline proven on POC object. Ready to scale.

---

## Phase 4: Spec 002 — Map Additional Business Units (P1)

**Goal**: Map at least one additional BU schema (beyond Trading) using the production pipeline methodology.

**Independent Test**: Run production wiki pipeline on eMoney schema objects and produce wiki files.

- [ ] T028 [S02] Identify candidate BU schemas for mapping — prioritize by downstream Synapse/lake presence (per FR-002)
- [ ] T029 [S02] Run sql-semantic-doc pipeline on first candidate BU schema (e.g., eMoney) — produce upstream wiki files in DB_Schema repo
- [ ] T030 [S02] Add new BU wiki path to `dwh-semantic-doc-config.json` as tier 1 upstream source (per FR-006)
- [ ] T031 [S02] Tag mapped objects with Domain labels (many-to-many model: source schema = BusinessUnit ownership, Domain = routing tag)
- [ ] T032 [S02] Validate: run Synapse pipeline (Phase 3 tasks) on a Synapse object that sources from the new BU — verify upstream wiki is correctly inherited

**Checkpoint**: At least 2 BU schemas mapped with upstream wikis available as tier 1 sources.

---

## Phase 5: Spec 003 — Scale Synapse Pipeline

**Goal**: Expand the pipeline beyond Dim_Position to cover key DWH objects across multiple schemas.

- [ ] T033 [S03] Run pipeline on 5 additional `DWH_dbo` dimension tables (e.g., `Dim_Customer`, `Dim_Instrument`, `Dim_Country`, `Dim_Campaign`, `Dim_Manager`)
- [ ] T034 [S03] Run pipeline on 3 `DWH_dbo` fact tables (e.g., `Fact_Trades`, `Fact_Deposits`, `Fact_Withdrawals`)
- [ ] T035 [S03] Run pipeline on 3 `BI_DB_dbo` view/tables (e.g., `BI_DB_CIDFirstDates`, `BI_DB_LTV_BI_Actual`)
- [ ] T036 [S03] Run Phase 12 (Cross-Object Enrichment) across ALL documented objects — sync knowledge, fill gaps
- [ ] T037 [S03] Validate: spot-check 5 wiki files for completeness (IDs resolved, lineage present, query advisory included)

**Checkpoint**: ~15+ Synapse objects documented. Cross-object enrichment applied.

---

## Phase 6: Spec 004 — Audit Lake Coverage (P2)

**Goal**: Map which production objects flow to the lake and UC, producing a coverage matrix.

**Independent Test**: Coverage matrix shows gap analysis, target map, and scope map for each production object.

- [ ] T038 [S04] Query the Generic Pipeline mapping view in Synapse to list all production objects exported to the lake
- [ ] T039 [S04] Query Unity Catalog via Databricks MCP to list all registered objects
- [ ] T040 [S04] Cross-reference: for each production object from specs 001-002, determine lake presence (yes/no) and UC registration status
- [ ] T041 [S04] Generate coverage matrix report at `knowledge/coverage/coverage-matrix.md` — triple purpose: gap analysis, target map for metadata push, scope map for future Databricks layer
- [ ] T042 [S04] Flag notable gaps: production objects with Synapse tables but no lake/UC presence

**Checkpoint**: Coverage matrix complete. Target endpoints for metadata push identified.

---

## Phase 7: Spec 005 — Resolve Column Metadata (P2)

**Goal**: Match columns across all four layers and generate consistent base descriptions.

**Independent Test**: Take one production table, find equivalents in Synapse/lake/UC, match 90%+ columns by name.

- [ ] T043 [S05] For each documented Synapse object (from Phase 5), use lineage to identify production, lake, and UC equivalents
- [ ] T044 [S05] Build column mappings: match by exact name, then fuzzy match, then type comparison. Save to `knowledge/columns/mappings/column-mappings.md`
- [ ] T045 [S05] Generate base descriptions following authority hierarchy (upstream wiki → Synapse wiki → live data → metadata). Save to `knowledge/columns/descriptions/descriptions-only.md`
- [ ] T046 [S05] Enforce 1024-char limit on all UC descriptions — compress where needed, preserving meaning + primary source
- [ ] T047 [S05] Produce clash file: compare generated descriptions against existing UC descriptions. Log overrides. Flag semantic diffs in `knowledge/columns/descriptions/clashes.md`

**Checkpoint**: Column identity resolved across layers. Base descriptions generated. Clash file produced.

---

## Phase 8: Spec 006 — Build Lineage Descriptions (P2)

**Goal**: For each column, assemble lineage narrative from upstream wikis showing transformation chain.

**Independent Test**: Take a revenue column in a BI_DB table, trace it back to production, produce a lineage description.

- [ ] T048 [S06] For each mapped column (from Phase 7), assemble lineage chain from upstream wiki outputs (specs 001, 003) — first source, transformation steps, last source
- [ ] T049 [S06] Handle multi-source columns: list all upstream parents for COALESCE/CASE columns
- [ ] T050 [S06] Handle derived columns: label as "derived: <expression>" for GETDATE(), hardcoded values, identity columns
- [ ] T051 [S06] Generate full-with-lineage descriptions (base description + lineage context). Save to `knowledge/columns/lineage/full-with-lineage.md`
- [ ] T052 [S06] Validate: all descriptions under 1024 chars, lineage traced for 70%+ of columns

**Checkpoint**: Two output formats available for comparison. Lineage descriptions complete.

---

## Phase 9: Spec 007 — Package Agent Domains + UC Tags (P2)

**Goal**: Organize all knowledge into domain packages with routing metadata and UC tags.

**Independent Test**: Inspect Trading domain package — contains all trading objects, routing keywords, UC tags.

- [ ] T053 [S07] Define domain boundaries: assign every documented object to at least one domain (many-to-many). Use Phase 13 Domain tags as starting point.
- [ ] T054 [S07] Create domain folders under `knowledge/domains/` — one folder per domain (e.g., `trading/`, `payments/`, `risk/`)
- [ ] T055 [S07] Generate `index.md` per domain: summary, object list (references by path to source wiki files), routing metadata (keywords, concept aliases)
- [ ] T056 [P] [S07] Generate UC tags per object following Confluence standard (page 13960052801): infer `owner`, `domain`, `layer`, `refresh_frequency`, `source_system` from pipeline outputs. Leave `sla`, `certified` blank.
- [ ] T057 [P] [S07] Infer PII tags at column level: `direct` (column IS PII per Confluence pages 12044435462, 11908645178), `indirect` (column JOINs to direct PII via GCID/CID), `none` otherwise. Add to UC tag output.
- [ ] T058 [S07] Create 3 test questions with expected answers per domain package
- [ ] T059 [S07] Validate: zero orphan objects, all domains have index.md with routing metadata, UC tags complete for inferrable fields

**Checkpoint**: Domain packages ready. UC tags generated. Knowledge platform complete for POC scope.

---

## Phase 10: Polish & Cross-Cutting

**Purpose**: Validation, cleanup, and documentation

- [ ] T060 Run quickstart.md validation: execute the full POC walkthrough (Dim_Position → AI test questions)
- [ ] T061 Review all wiki files for consistency: same terminology, same template sections, no contradictions
- [ ] T062 [P] Update `project-notes.md` with any new post-POC items discovered during implementation
- [ ] T063 [P] Verify git history: all regenerated wiki files have clean diffs showing incremental improvements
- [ ] T064 Final commit with complete POC output

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup) → Phase 2 (Canonical Schema) → Phase 3 (POC: Dim_Position) → Phase 5 (Scale Pipeline)
                                               ↘ Phase 4 (Additional BUs)  ↗
Phase 5 (Scale) → Phase 6 (Lake Audit) → Phase 7 (Column Resolve) → Phase 8 (Lineage) → Phase 9 (Domains)
Phase 9 → Phase 10 (Polish)
```

### Spec Dependencies

- **Spec 001** (Phase 2): No dependencies — start first
- **Spec 002** (Phase 4): Depends on 001 — can run parallel with 003
- **Spec 003** (Phase 3+5): Depends on 001 + upstream wikis
- **Spec 004** (Phase 6): Depends on 003 (needs Synapse inventory)
- **Spec 005** (Phase 7): Depends on 001-004
- **Spec 006** (Phase 8): Depends on 005
- **Spec 007** (Phase 9): Depends on 001-006

### Parallel Opportunities

- **Phase 3 + Phase 4**: Synapse POC and BU mapping can run in parallel
- **T003 + T004 + T005**: MCP connection tests are independent
- **T056 + T057**: UC tag generation and PII inference are independent
- **T033 + T034 + T035**: Pipeline runs on different schemas are independent

---

## Implementation Strategy

### MVP First (Phases 1-3)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Canonical schema + upstream wiki (T006-T010)
3. Complete Phase 3: Full pipeline on `Dim_Position` (T011-T027)
4. **STOP and VALIDATE**: One table fully documented, AI can answer questions about it
5. Demo to stakeholders

### Incremental Delivery

1. Setup + Schema + POC → **Demo: "Here's what one table looks like"**
2. Scale to 15+ objects → **Demo: "Here's the DWH coverage"**
3. Lake audit + column resolution → **Demo: "Here's the cross-layer view"**
4. Lineage + domains → **Demo: "Here's the complete knowledge platform"**

---

## Summary

| Metric | Value |
|--------|-------|
| Total tasks | 64 |
| Phase 1 (Setup) | 5 |
| Phase 2 (Schema) | 5 |
| Phase 3 (POC) | 17 |
| Phase 4 (BUs) | 5 |
| Phase 5 (Scale) | 5 |
| Phase 6 (Lake) | 5 |
| Phase 7 (Columns) | 5 |
| Phase 8 (Lineage) | 5 |
| Phase 9 (Domains) | 7 |
| Phase 10 (Polish) | 5 |
| Parallel opportunities | 8 |
| MVP scope | Phases 1-3 (27 tasks) |
