# Feature Specification: Mass Process Orchestration

**Feature Branch**: `002-mass-process-orchestration`  
**Created**: 2026-03-16  
**Status**: Implemented (synced 2026-03-22)  
**Input**: User description: "Mass documentation orchestration — agent context handoff when context fills up during batch processing, batch tracking with quality scores, embedded in a single unified command per target."

## Background: Current State Analysis

### DB_Schema Pipeline (Bonnie's Work) — Manual Batch System

The production `sql-semantic-doc` pipeline in DB_Schema enforces **strict serial, single-agent execution** with a **manual batch tracking system** via `_index.md` files.

#### The `_index.md` Tracking Registry

Each schema has an `_index.md` file (e.g., `etoro/Wiki/Trade/_index.md`, `etoro/Wiki/Dictionary/_index.md`) that serves as the **central tracking registry**. Structure:

1. **Header metrics**: Total objects, documented count, quality tier breakdown, last updated date
2. **Next Batch section**: The next planned batch with objects, dependency levels, and dependency links — enables the operator to see exactly what will be documented next
3. **Completed batch log**: Per-batch history showing each object with quality score, status, and doc link
4. **Object type sections**: Tables (167), Views (117), Functions (66), Stored Procedures (923) — each with `Object | Quality | Status` columns showing `Done (Batch N)` or `Pending`

#### Scale and Progress

- **Trade schema**: 1,422 total objects, 763 documented (54%), 611 pending
- **29 completed batches** + 1 planned (Batch 30), ~25 objects per batch
- **Dictionary schema**: 373 objects, 100% complete at 9.0+ quality, across 16 sessions
- **Batch cadence**: Multiple batches per day (Batches 25–29 all completed on 2026-03-16)

#### Manual Workflow

1. Bonnie **plans** the next batch: picks ~25 undocumented objects alphabetically within each type
2. For each batch, he **ensures dependencies are satisfied** — objects whose dependencies aren't documented yet are **deferred** to later batches (explicitly noted: "Deferred to later batch: Trade.ForkByDB -> depends on Trade.PositionOpenForFork")
3. He **runs** the `sql-semantic-doc` command for each object serially in a single agent session
4. After completion, he **manually updates** the `_index.md` with batch number, quality scores, and status
5. He **commits** each batch's results with a "wiki" commit message

#### Context Management (The Gap)

- One object at a time, 12 phases per object, full context retained across the chain
- Dependency-first ordering: topological sort into levels (Level 0 = leaf, Level N = target)
- Quality scores embedded in each doc footer (Elements, Logic, Relationships, Sources subscores)
- **No automatic context handoff**: When context fills up, Bonnie simply starts a new chat session and manually tells the agent which batch to run next
- **No machine-readable state**: The `_index.md` is a markdown file — not structured data that an orchestrator could consume
- **No automated batch planning**: Bonnie manually selects objects for each batch based on alphabetical order and dependency analysis

### Databricks_Knowledge Pipeline (DWH / Synapse)

The `dwh-semantic-doc` pipeline has more batch infrastructure but no tracking registry:

- `_run_bottom_up.py`: multi-table orchestrator with `--resume`, `--dry-run`, `--batch-size`
- `_dependency_order.json`: topological depth for all tables
- `.propagation-progress.json` per table: tracks completed batches within deep lineage propagation
- Still single-agent for the main documentation pipeline (Phases 1–14)
- **No `_index.md` equivalent** — no centralized tracking of what's been documented, at what quality, or in which batch

### The Core Problem

When processing 100+ objects across multiple agent sessions:
1. **Manual batch management overhead**: Bonnie manually plans batches, tracks dependencies, updates status files, and defers objects — this is labor-intensive and error-prone at scale
2. **Context window saturation**: After 5–10 fully documented objects within a single session, earlier context is evicted from the agent's working memory — quality degrades for later objects in the batch
3. **No automated context handoff**: When starting a new session for the next batch, the agent has zero knowledge of what was discovered in prior batches — patterns, glossary terms, cross-references are lost
4. **Tracking is manual**: The `_index.md` is maintained by hand — there's no automation to update it after each object completes
5. **No cross-batch enrichment**: Objects documented in Batch 1 don't automatically get "Referenced By" updates when a consumer is documented in Batch 15

---

## Architecture Decision: Command Pipeline with Embedded Batch Handling

### Decision

**Commands per target:** wiki build (`build-wiki-{target}`), ALTER script generation (`generate-alter-{target}`), UC deployment (`deploy-alter-{target}`), with optional downstream propagation (`propagate-downstream-{target}`) [FUTURE]. Batch handling, tracking, context handoff, and resume are embedded in each command via scope options. The pipeline is decomposed to allow focused wiki batches (10-15 objects, serial inline) and independent deployment cycles.

The wiki build command runs Phases 1-12, 14 producing documentation artifacts. The generation command reads wiki files and produces ALTER scripts for Unity Catalog; the deployment command executes those scripts against UC.

### Command Naming Convention

| Command | Purpose | MCP Required | Phase Rules |
| --- | --- | --- | --- |
| `build-wiki-dwh` | Wiki documentation build | Synapse (Phases 2-3 live data only), Atlassian | `.cursor/rules/dwh-semantic-doc/` (Phases 1-12, 14) |
| `generate-alter-dwh` | ALTER script generation from wiki files | Databricks (optional — resolves _Pending UC targets) | `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc` |
| `deploy-alter-dwh` | ALTER execution against Unity Catalog | Databricks (mandatory) | `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc` |
| `propagate-downstream-dwh` | [FUTURE] Downstream column comment propagation | Databricks (mandatory) | `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc` |
| `build-wiki-{future}` | Wiki for new target | Target-specific | Target-specific rules |
| `generate-alter-{future}` | ALTER generation for new target | Databricks + target-specific | Target-specific + `11w-write-objects.mdc` |

### Shared vs Target-Specific

**Shared orchestration layer** (`.cursor/rules/semantic-layer-core/`):
- `batch-orchestration.mdc` — batch planning, size management, dependency-aware segmentation, resume protocol
- `index-management.mdc` — `_index.md` auto-generation and bulk status updates at end of each batch
- `context-handoff.mdc` — format, serialization, and loading protocol for inter-batch context
- `deploy-index-management.mdc` — `_deploy-index.md` tracking for ALTER generation and deployment commands
- `repo-first-access.mdc` — Constitution IX enforcement (NON-NEGOTIABLE)

**Target-specific** (stays where it is today):
- Phase rule files (e.g., `01-structure-analysis.mdc` through `14-query-advisory-metadata.mdc`)
- `11w-write-objects.mdc` — ALTER generation and deployment logic
- MCP connection details
- Object type pipeline mapping (which phases apply to tables vs views vs SPs)
- Output path conventions

### Parallelism (Abandoned)

Parallel subagent dispatch (4 concurrent subagents × 3 tables each) was designed as the core throughput optimization (Research R3). It was abandoned during implementation for the following reasons:

1. **Quality degradation**: Each subagent starts with zero context about peer objects. Despite objects being at the same dependency depth (theoretically independent), shared domain context (glossary terms, naming patterns, common source tables) significantly improved quality when processed serially. The DB_Schema quality data (serial 9-10 vs parallel 6-7) applied equally to DWH tables.
2. **GATE enforcement complexity**: Subagents could not reliably follow the lineage-first contract (Phase 10B before Phase 11) or load the mandatory spec files before generation. Serial inline processing with GATE enforcement achieved avg quality 8.0 across 130 DWH_dbo objects.
3. **Cursor subagent limitations**: Subagents could not be given the full phase pipeline context within their context window while also processing multiple objects.

Serial inline processing with phase-skip optimization achieves sufficient throughput: DWH_dbo (130 objects) completed in 15 batches, Dealing_dbo (231 objects) in 20 batches.

### Scope Options

**`build-wiki-{target}`** scope options:

1. **Single Object** — Document one object (same as today's single-object flow, Phases 1-12, 14 as applicable)
2. **Schema** — Mass documentation with single continuous flow (plan + execute + finalize in one session per batch); serial inline processing
3. **Status** — Show current progress: what's done, what's pending, next batch plan
4. **Enrich** — Run Phase 12 cross-object enrichment on existing docs
5. **Review-Rerun** — Regenerate docs for tables with pending reviewer corrections

**`generate-alter-dwh`** scope options:

1. **Schema** — Generate ALTER scripts for all objects with wiki status `Done` in `_index.md`
2. **Single** — Generate ALTER for one object
3. **Status** — Show generation progress from `_deploy-index.md`
4. **Regenerate** — Re-generate ALTERs for objects whose wiki was updated after last generation

**`deploy-alter-dwh`** scope options:

1. **Schema** — Deploy all Generated objects to Unity Catalog
2. **Single** — Deploy one object
3. **Status** — Show deployment progress from `_deploy-index.md`
4. **Resume** — Continue from last deployment batch
5. **Dry-run** — Validate without executing

**`propagate-downstream-dwh`** [FUTURE]:

1. **Discover** — Show propagation scope without executing
2. **Execute** — Run full downstream propagation
3. **Status** — Show propagation progress

### Batch Flow (Wiki Build — Single Continuous Flow)

**Single-flow model** (one uninterrupted session per batch):

1. **Load State**: Read `_index.md` and `_batch_context.json`. If `_index.md` missing, auto-generate via `index-management.mdc`. If interrupted batch has `Queued` objects, resume from first Queued.
2. **Plan Batch**: Select next 10-15 objects from Pending (depth-ordered, dependency-consistent). Write `## Next Batch` to `_index.md`.
3. **Execute Serial**: Process each object inline through the phase pipeline (Phases 1 through 12). No subagent dispatch — the agent runs all phases directly for each object.
4. **Finalize**: Bulk-update `_index.md` (all objects Done/Failed/Skipped in one write), write `_batch_context.json`, print end-of-batch summary.
5. **Stop**: Print resume instruction. Operator starts a new chat for the next batch.

The Plan/Execute two-session model (from DB_Schema) was evaluated during design but abandoned during implementation. A single continuous flow eliminates the overhead of a manual chat restart between planning and execution with no loss of quality.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Schema-Level Mass Documentation with Automated Batching (Priority: P1)

An operator runs `/build-wiki-dwh DWH_dbo` (schema scope). The command automatically discovers all objects in the schema, builds a dependency graph, plans batches of N objects each, and begins documenting in a single continuous session per batch. At batch end, `_index.md` is bulk-updated (all object statuses in one write), `_batch_context.json` is written, and the operator is told to start a new chat for the next batch.

**Why this priority**: This is the core capability — turning a fully manual process (Bonnie's 29-batch, hand-tracked workflow) into a semi-automated one where the operator only needs to start new chats at batch boundaries.

**Independent Test**: Run a schema with 50 objects. Verify the system auto-plans ~4 batches of ~15, documents batch 1 with quality 8.0+, writes `_index.md` with all 50 objects (~15 Done, ~35 Pending), and produces a context handoff file.

**Acceptance Scenarios**:

1. **Given** a schema with 30 tables and a dependency graph, **When** the operator runs the command with schema scope, **Then** the system builds dependency order, segments into batches of configurable size, and begins processing batch 1 serially.
2. **Given** batch 1 of 6 has completed, **When** the batch ends, **Then** the system writes `_batch_context.json`, updates `_index.md` (batch 1 objects = Done, batch 2–6 = Pending), and prints a resume instruction.
3. **Given** the operator starts a new chat and runs schema scope again, **When** the command loads, **Then** it reads `_index.md` + `_batch_context.json`, auto-resumes from the first `Queued` or next `Pending` slice as applicable, and begins the next batch with inherited cross-object knowledge.

---

### User Story 2 - Automated `_index.md` Tracking Registry (Priority: P1)

The `_index.md` file is generated and maintained automatically by the command — no manual editing needed. It follows the same structure as Bonnie's proven format (header metrics, batch log, object-type sections with Quality/Status) but is machine-maintained.

**Why this priority**: Without tracking, resume and batch planning are impossible. This is the foundation for all batch operations.

**Independent Test**: Document 3 objects from an empty schema. Verify `_index.md` is auto-created with correct metrics, all schema objects listed (3 Done, rest Pending), and batch 1 logged with quality scores.

**Acceptance Scenarios**:

1. **Given** no `_index.md` exists for a schema, **When** the command starts schema-scope documentation, **Then** it auto-generates `_index.md` by scanning the schema's object inventory and marking all objects as Pending.
2. **Given** all objects in the current batch have finished the phase pipeline (through validation), **When** the batch finalizes, **Then** `_index.md` is updated in one bulk write: each object shows Done/Failed/Skipped with quality score and batch number as applicable.
3. **Given** `_index.md` already exists from a prior run, **When** the command runs status scope, **Then** it prints a summary: X done, Y pending, Z failed, next batch plan, average quality.

---

### User Story 3 - Context Handoff Between Batches (Priority: P1)

When a batch ends and the operator starts a new chat for the next batch, the system loads a structured context handoff file so the new agent session has cross-object knowledge from prior batches — glossary terms, relationship maps, what objects reference what.

**Why this priority**: Without context handoff, each batch starts from zero, producing documentation that's internally consistent but disconnected from prior batches. Cross-references and "Referenced By" sections will be incomplete.

**Independent Test**: Document batch 1 (5 tables), start a new chat for batch 2. Verify that batch 2's documentation correctly references objects from batch 1 in "Relationships" and "Dependencies" sections, and uses glossary terms discovered in batch 1.

**Acceptance Scenarios**:

1. **Given** batch 1 has completed, **When** the context handoff file is written, **Then** it contains: all glossary terms discovered, per-object relationship summaries, cross-reference index, and quality scores — in a structured JSON format.
2. **Given** a new chat starts for batch 2, **When** the command loads in resume mode, **Then** it reads the context handoff and uses it to: populate "Referenced By" sections, inherit glossary definitions, and link new objects to previously documented ones.
3. **Given** 10 batches have completed, **When** the context handoff file grows large, **Then** the system distills it to keep only the most relevant cross-references (objects in the dependency graph of the upcoming batch), staying within a size budget.

---

### User Story 4 - Generation and Deployment Pipeline from Wiki Files (Priority: P2)

After wiki documentation is complete (or partially complete), an operator runs `/generate-alter-dwh` to read existing wiki `.md` files, resolve UC targets, and emit per-object `.alter.sql` scripts, then runs `/deploy-alter-dwh` to execute those scripts against Unity Catalog. Progress is tracked via `_deploy-index.md`. Downstream column propagation is a separate future command (`propagate-downstream-dwh`).

**Why this priority**: Deployment depends on wiki files existing. The wiki build (US1-US3) must be operational first, but generation and deployment are independently valuable — they can run on any objects already documented.

**Independent Test**: Run `/generate-alter-dwh` then `/deploy-alter-dwh` for `DWH_dbo.Dim_ActionType` (single object). Verify generation reads the wiki `.md`, resolves the UC target, writes `.alter.sql`; deployment executes against UC and writes `.deploy-report.md`.

**Acceptance Scenarios**:

1. **Given** a schema with 10 objects marked `Done` in `_index.md`, **When** the operator runs `generate-alter-dwh` in schema scope, **Then** it updates `_deploy-index.md` and produces `.alter.sql` for each object in dependency order; **When** the operator runs `deploy-alter-dwh` in schema scope, **Then** it executes ALTERs and updates deployment status to `Deployed (Deploy Batch N)` as each succeeds.
2. **Given** a single object with an existing wiki `.md`, **When** the operator runs `generate-alter-dwh` then `deploy-alter-dwh` in single-object scope, **Then** it reads the wiki, resolves the UC target, generates `.alter.sql`, executes against UC, and writes `.deploy-report.md`.
3. **Given** an object's wiki was regenerated after last generation or deployment, **When** the operator runs `generate-alter-dwh` Regenerate scope or `deploy-alter-dwh` after stale detection, **Then** the system refreshes only stale artifacts.

---

### Edge Cases

- What happens when an object has dependencies in a different batch? The context handoff file includes dependency summaries so later batches can reference them.
- How does the system handle an object that fails documentation (e.g., MCP timeout)? Marked as Failed in `_index.md` with error reason. Subsequent objects proceed with a warning.
- What happens when the context handoff file exceeds the size budget after 50+ batches? Distillation step keeps only cross-references relevant to the upcoming batch's dependency graph.
- What if the operator resumes but objects have been added to the schema since the last run? The resume step re-scans the schema, adds new objects as Pending, and incorporates them into batch planning.
- What if an ALTER deployment fails for one object? Marked as `Failed (Deploy Batch N) — {reason}` in `_deploy-index.md`. Other objects continue. Failed objects can be retried via `deploy-alter-dwh` Single or Resume scope after fixing the cause.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST embed batch orchestration directly in each command (wiki build and deployment). Schema scope triggers batch mode with single continuous flow (plan + execute + finalize in one session); single-object scope works as today.
- **FR-002**: System MUST auto-generate and maintain `_index.md` per schema, following the proven format: header metrics, batch log, object-type sections with Object/Quality/Status.
- **FR-003**: System MUST segment a schema's objects into ordered batches based on the dependency graph, respecting topological order within each batch.
- **FR-004**: System MUST produce a context handoff file (`_batch_context.json`) at the end of each batch containing: glossary terms, relationship map, cross-reference index, quality summaries.
- **FR-005**: System MUST support resuming from any batch boundary via a "resume" scope option that reads `_index.md` + `_batch_context.json`.
- **FR-006**: System MUST update `_index.md` at the end of each batch in a single bulk operation. All object status changes (Done/Failed/Skipped) are written together for crash resilience and write efficiency.
- **FR-007**: System MUST support configurable batch size (default: 15 for wiki build, 25 for deployment) tunable based on object complexity and context window capacity.
- **FR-008**: System MUST detect already-documented objects (fresh within configurable staleness threshold, default: 30 days) and skip them during mass runs.
- **FR-009**: System MUST produce a run summary at the end of each batch: objects processed, skipped, failed; average quality; wall-clock time; resume instruction.
- **FR-010**: The command naming convention MUST follow `build-wiki-{target}` for documentation, `generate-alter-{target}` for ALTER script generation, and `deploy-alter-{target}` for UC deployment, to support multiple targets (DWH, etoro, future).
- **FR-011**: Batch orchestration rules MUST be shared across targets via `.cursor/rules/semantic-layer-core/` — target-specific rules remain in their existing locations.
- **FR-012**: A "status" scope option MUST show current progress without modifying any files: objects done/pending/failed, next batch plan, quality distribution.
- **FR-013**: All structural and code-based metadata MUST be read from the locally cloned SSDT repositories (Dataplatform, DB_Schema) — NEVER queried from the database via MCP. MCP is ONLY permitted for live data queries (Phases 2-3: `SELECT TOP N`, `COUNT(*)`, `GROUP BY`, `MIN/MAX`, `DISTINCT`). This is a binding constraint per Constitution IX (Repo First, MCP Second). See `.cursor/rules/semantic-layer-core/repo-first-access.mdc` for full enforcement table.
- **FR-014**: Wiki build MUST produce a `.lineage.md` file per object containing SP code lineage traces (source tables, transformations, ETL flow) extracted from Phase 10B Steps 2-6. This is a required third wiki output alongside `.md` and `.review-needed.md`.
- **FR-015**: The ALTER generation command (`generate-alter-{target}`) MUST read from existing wiki `.md` files — it MUST NOT re-run analysis phases (1-10). Wiki parsing is its sole input for ALTER script content.
- **FR-016**: The ALTER generation command (`generate-alter-{target}`) MUST produce per-object ALTER scripts (`.alter.sql`). The deployment command (`deploy-alter-{target}`) MUST execute ALTER scripts and produce deployment reports (`.deploy-report.md`). Downstream propagation is handled by a separate future command (`propagate-downstream-{target}`).
- **FR-017**: The deployment command MUST auto-generate and maintain `_deploy-index.md` per schema, tracking deployment status with Deploy Batch numbers distinct from wiki batch numbers.
- **FR-018**: The deployment command MUST detect stale deployments (wiki `.md` updated after last deploy) and support re-deployment of stale objects.
- **FR-019**: System MUST enforce lineage-first execution order: Phase 10B (Column Lineage) MUST run before Phase 11 (Generate Documentation). The `.lineage.md` file must exist before the wiki `.md` is generated. Tier assignment in Phase 11 is mechanical — derived from the lineage file, not inferred. See `GATE-lineage-contract.mdc`.
- **FR-020**: System MUST run post-write validation after every wiki file: structural validation (`validate-wiki.ps1/.sh`) and semantic Tier 1 coverage validation (`validate-tier1-coverage.ps1/.sh`). Both must pass before the object is marked Done. Failure requires deletion and regeneration.
- **FR-021**: System MUST support Functions as a documentable object type with a tailored phase path: no Phase 2/3 (no live sampling), reversed Phase 7 (find callers instead of dependencies), UC Target defaults to `_Not_Migrated` for functions without UC counterparts.
- **FR-022**: System MUST support phase-skip optimization: phases with no relevant input (zero grep hits for SP scan, no ID columns for lookup resolution, MCP unavailable for live sampling) are skipped rather than forced. A Simple Dictionary Fast-Path (Phases 1→2→8→4→10A→10B→11) is available for tables with ≤10 columns and single-source SP_Dictionaries origin.
- **FR-023**: System MUST support multi-schema operation. Each schema (`DWH_dbo`, `Dealing_dbo`, `BI_DB_dbo`, future schemas) has independent `_index.md`, `_batch_context.json`, and `_deploy-index.md` tracking. Object discovery adapts per schema: OpsDB-based priority for schemas with Service Broker orchestration, dependency-graph-based for others.

### Key Entities

- **Wiki Batch**: An ordered subset of objects processed together in a single wiki build session. Bounded by configurable size. Each wiki batch produces a context handoff file. Numbered as "Wiki Batch N" in `_index.md`.
- **Deploy Batch**: An ordered subset of objects deployed together in a single deployment session. Numbered as "Deploy Batch N" in `_deploy-index.md`. Deploy Batch numbers are independent from Wiki Batch numbers.
- **Context Handoff** (`_batch_context.json`): Structured JSON persisted between batches containing distilled knowledge — glossary, relationships, cross-references, quality scores. Loaded at the start of each resume.
- **Object Registry** (`_index.md`): Per-schema tracking file. Auto-generated and auto-maintained. Contains header metrics, batch log, and per-object-type status tables.
- **Deployment Registry** (`_deploy-index.md`): Per-schema tracking file for `generate-alter-{target}` and `deploy-alter-{target}`. Tracks which objects have generated ALTER scripts and been deployed to UC, with Deploy Batch numbers, timestamps, and stale detection (wiki updated after last deploy).
- **Target Config**: The set of MCP connection, phase rules, and output path conventions that differentiate one `build-wiki-{target}` / `generate-alter-{target}` / `deploy-alter-{target}` set from another.

---

## Comparison: DB_Schema vs DWH Pipeline Differences

| Aspect | DB_Schema (Bonnie) | DWH (Databricks_Knowledge) | Gap / Action |
| --- | --- | --- | --- |
| **Phases** | 12 phases (DDL through Cross-Object Enrichment) | 15 phases (Structure through UC Lineage Injection) | DWH has 3 additional phases (Production Lineage, Query Advisory, UC Lineage) |
| **Batch tracking** | `_index.md` per schema: Object/Quality/Status/Batch, manually maintained | `.propagation-progress.json` per table; no central registry | DWH needs to adopt `_index.md` pattern — but automated, not manual |
| **Batch planning** | Manual: operator selects ~25 objects, checks dependencies, defers unsatisfied ones | `_run_bottom_up.py` auto-selects by depth, but only for lineage propagation | Need to bring `_run_bottom_up.py` automation to the documentation pipeline |
| **Serial enforcement** | Explicit prohibition with quality comparison table (6-7 parallel vs 9-10 serial) | Implicit (single-object command design) | Both agree; need to maintain this within batches |
| **Dependency ordering** | Topological sort built into command (Step 2.9), manual in `_index.md` batch planning | `_build_dependency_order.py` + `_dependency_order.json` | DWH has pre-computed dependency graph — should feed batch planning |
| **Context handoff** | Manual: start new chat, tell agent which batch to run | None — same limitation | Core gap both pipelines share — needs automation via `_batch_context.json` |
| **Cross-object sync** | Phase 12 batch enrichment after all objects | Phase 12 Pre-Read during Phase 11 + batch pass | DWH's Phase 12 pre-read is more proactive |
| **Object completeness** | Trade: 763/1,422 done (54%); Dictionary: 373/373 done (100%) | 130 objects documented across 15 batches (100% of active objects) | DB_Schema is far ahead in coverage |
| **Drift detection** | Built-in (Scope Option 5) | Not implemented | DWH should adopt drift detection |
| **Review workflow** | Not implemented | Review-Rerun mode with `.review-needed.md` | DB_Schema could adopt review sidecars |
| **Batch cadence** | Multiple batches per day, 25 objects each | 10-15 objects per batch, serial inline processing | Both need automated pacing |
| **Command name** | `sql-semantic-doc` | `dwh-semantic-doc` (split to `build-wiki-dwh` + `generate-alter-dwh` + `deploy-alter-dwh`) | Multi-command naming convention |

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Documentation quality score for the last object in a batch is within 1.0 point of the first object's score — proving that batch sizing and serial processing prevent context overflow.
- **SC-002**: A mass run can be interrupted and resumed at any batch boundary, with zero re-processing of completed objects and full cross-reference integrity maintained.
- **SC-003**: 100% of documented objects appear in `_index.md` with accurate quality scores, batch assignments, and timestamps — updated automatically, no manual editing.
- **SC-004**: An operator running schema scope only needs to: (1) start the command, (2) start a new chat for each subsequent batch. The command auto-detects interrupted batches and resumes from the first Queued object.
- **SC-005**: Cross-references between objects in different batches (e.g., "Referenced By" pointing to a later-documented consumer) are correctly established via context handoff, verified by automated check.
- **SC-006**: Adding a new target (e.g., `build-wiki-{newdb}` + `generate-alter-{newdb}` + `deploy-alter-{newdb}`) requires only: one command set + one config — all batch orchestration logic is inherited from shared rules.
- **SC-007**: Quality average across all documented schemas is ≥ 7.5. Actual measured: DWH_dbo 8.0 (130 objects, 15 batches), Dealing_dbo 7.8 (231 objects, 20 batches), BI_DB_dbo 9.1 (30 objects, 6 batches).

---

## Assumptions

- Default wiki batch size of 10-15 is a conservative estimate aligned with serial inline processing. Bonnie uses 25 for simpler SPs; DWH tables are heavier but the wiki-only pipeline (no ALTER in the same session) keeps batches manageable.
- The 30-day staleness threshold for skipping already-documented objects matches existing practice in both pipelines.
- The context handoff file format is JSON (consistent with `_dependency_order.json` and `.propagation-progress.json` patterns already in the DWH pipeline).
- The operator's manual step at batch boundaries (start new chat, re-run schema-scope wiki build) is acceptable for now. Full automation (headless agent invocation) is deferred to a future iteration — likely via Claude Code CLI or similar.
- The existing phase rule files (`.cursor/rules/dwh-semantic-doc/*.mdc`) are modified where they violate Constitution IX (Repo First): notably `01-structure-analysis.mdc` which previously mandated Synapse MCP queries for structure that exists in the Dataplatform SSDT repo.
- The Dataplatform SSDT repo (`Dataplatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\`) contains all DDLs (343 tables, 126 SPs, 22 views) locally — eliminating Synapse MCP dependency for Phases 1, 4-9B. Only Phases 2-3 (live data) require Synapse MCP.
