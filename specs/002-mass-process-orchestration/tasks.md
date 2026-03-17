# Tasks: Pipeline Decomposition — Wiki Build + Write Objects

**Input**: Design documents from `/specs/002-mass-process-orchestration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1=Mass Documentation, US2=Index Tracking, US3=Context Handoff)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Foundation rules and constitution updates that all subsequent phases depend on.

> **NOTE**: T001-T004 are ALREADY COMPLETE from the current planning session. Verify and move on.

- [x] T001 Verify Constitution IX (Repo First, MCP Second) is in `.specify/memory/constitution.md` — v1.8.0
- [x] T002 Verify `.cursor/rules/semantic-layer-core/repo-first-access.mdc` exists with enforcement table, repo paths, phase-by-phase source assignment
- [x] T003 Verify `01-structure-analysis.mdc` reads from Dataplatform SSDT repo (not Synapse MCP) in `.cursor/rules/dwh-semantic-doc/01-structure-analysis.mdc`
- [x] T004 Verify `dwh-semantic-doc-config.json` has `ssdt_repo` block with Dataplatform paths in `.specify/Configs/dwh-semantic-doc-config.json`

---

## Phase 2: Foundational — Rule Refactoring (Blocking Prerequisites)

**Purpose**: Refactor Phase 11 into wiki-only and extract ALTER/deployment logic into Phase 11W. Update batch orchestration. These rules MUST be complete before commands can reference them.

**CRITICAL**: No command work (Phase 3/4) can begin until this phase is complete.

### TG3: Refactor Phase 11 to Wiki-Only

- [x] T005 Strip "UC Object Resolution" section (lines ~330-367) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T006 Strip "UC Table Metadata Discovery" section (lines ~369-387) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T007 Strip "ALTER Script Template" and "ALTER Script Rules" sections (lines ~389-423) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T008 Strip "Table Tags" section (lines ~425-456) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T009 Strip "Column-Level PII Tags" section (lines ~457-474) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T010 Strip "Downstream Column Comment Propagation" section (lines ~476-551) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T011 Strip "ALTER Execution" section (lines ~725-896) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T012 Strip "Deployment Report" section (lines ~898-1003) from `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — move to 11w
- [x] T013 Update "Output Path" section in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — change from FIVE FILES to THREE FILES (wiki + sidecar + lineage). Remove `.alter.sql`, `.downstream.alter.sql`, `.deploy-report.md` from the list
- [x] T014 Update wiki template UC properties in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — replace UC Target/Format/Partitioned/Type with placeholder values: `_Pending — resolved during write-objects_`
- [x] T015 Update Rule B1 rationale in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — remove "AND 4 output files" from table rationale, update to "3 output files (wiki + sidecar + lineage)"
- [x] T016 Update Rule B6 validation gate in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — change output file check from 5 files to 3 (wiki + sidecar + lineage). Remove ALTER/downstream/deploy checks
- [x] T017 Update "Completion" section in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — change from ALL FIVE FILES to THREE FILES. Remove ALTER execution completion criteria
- [x] T018 Update description frontmatter in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — reflect wiki-only focus
- [x] T019 Add `.lineage.md` output to Phase 11 in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — add lineage file generation step (from Phase 13 SP code lineage, Steps 2-6) as a required third output file

### TG4: Create Phase 11W Rule (Write Objects Logic)

- [x] T020 [P] Create `.cursor/rules/dwh-semantic-doc/11w-write-objects.mdc` with frontmatter and purpose section — "Phase 11W - Write Objects: ALTER generation + deployment from existing wiki files"
- [x] T021 [P] Add "Wiki File Parsing Protocol" section to `11w-write-objects.mdc` — how to read/extract Elements table, Business Meaning, Lineage from an existing wiki `.md` file (header table, Section 1, Section 4, Section 5)
- [x] T022 Add "UC Object Resolution" section to `11w-write-objects.mdc` — transplant from Phase 11 (resolution algorithm: information_schema → SHOW TABLES → mapping view → INFERRED)
- [x] T023 Add "UC Table Metadata Discovery" section to `11w-write-objects.mdc` — transplant from Phase 11 (DESCRIBE DETAIL + DESCRIBE TABLE EXTENDED)
- [x] T024 Add "Generic Pipeline Mapping" section to `11w-write-objects.mdc` — transplant from Phase 13 Steps 1/1b (FrequencyMinute, ServerName, PII data queries)
- [x] T025 Add "ALTER Script Generation" section to `11w-write-objects.mdc` — transplant template and rules from Phase 11
- [x] T026 Add "Table Tags" section to `11w-write-objects.mdc` — transplant from Phase 11
- [x] T027 Add "Column PII Tags" section to `11w-write-objects.mdc` — transplant from Phase 11
- [x] T028 Add "Downstream Propagation" section to `11w-write-objects.mdc` — transplant deep lineage flow (Steps D1-D5) from Phase 11
- [x] T029 Add "Execution" section to `11w-write-objects.mdc` — transplant single-session Python script flow (Steps E1-E3) from Phase 11
- [x] T030 Add "Deploy Report" section to `11w-write-objects.mdc` — transplant template and rules (Step E5) from Phase 11
- [x] T031 Add "Wiki Backfill" optional section to `11w-write-objects.mdc` — new logic to update wiki `.md` UC properties table with resolved UC target after deployment
- [x] T032 Add output file list and completion criteria to `11w-write-objects.mdc` — 4-5 files per object (alter + downstream + deploy-report + lineage.py, optionally updated wiki)

### TG5: Update Batch Orchestration

- [x] T033 [P] Update `DEFAULT_BATCH_SIZE` from 5 to 15 in `.cursor/rules/semantic-layer-core/batch-orchestration.mdc`
- [x] T034 [P] Add batch sizing guidelines table to `.cursor/rules/semantic-layer-core/batch-orchestration.mdc` — dim tables ≤15 cols: batch 25, medium 15-40 cols: batch 15, large 40+ cols: batch 10
- [x] T035 [P] Add note that write-objects uses its own batch size (default 25) in `.cursor/rules/semantic-layer-core/batch-orchestration.mdc`

### Phase 13 Split

- [x] T036 [P] Modify `.cursor/rules/dwh-semantic-doc/13-production-lineage-mapping.mdc` — split: Steps 2-6 (SP code lineage → `.lineage.md`) stay for wiki build. Steps 1/1b (Generic Pipeline mapping view UC query) marked as write-objects-only with cross-reference to `11w-write-objects.mdc`

**Checkpoint**: All rules refactored. Phase 11 is wiki-only (~450 lines lighter). Phase 11W has all ALTER/deployment logic. Batch size updated. Phase 13 split.

---

## Phase 3: US1+US2+US3 — Wiki Build Command (Priority: P1)

**Goal**: Create the `build-wiki-dwh` command that implements all three P1 user stories: mass documentation with automated batching (US1), automated `_index.md` tracking (US2), and context handoff between batches (US3). Uses Plan/Execute two-session model with parallel subagent dispatch.

**Independent Test**: Run `/build-wiki-dwh DWH_dbo` on a fresh schema. Verify Plan mode discovers objects, writes `## Next Batch` to `_index.md`, and stops. Re-run → Execute mode dispatches subagents, documents 12 objects (4 subagents × 3 tables), updates `_index.md` with quality scores, writes `_batch_context.json`.

### Implementation

- [x] T037 [US1] Create `.cursor/commands/build-wiki-dwh.md` with command header, description, and argument parsing (schema name, optional single object)
- [x] T038 [US1] Add pre-flight checks section to `build-wiki-dwh.md` — Synapse MCP advisory (Phases 2-3 only, Constitution IX), Atlassian MCP mandatory, Databricks SKIPPED, upstream wiki advisory, Dataplatform SSDT repo required
- [x] T039 [US1] Add auto-detect mode logic to `build-wiki-dwh.md` — if `_index.md` has `## Next Batch` section → Execute mode, otherwise → Plan mode
- [x] T040 [US1] Add Plan mode section to `build-wiki-dwh.md` — read `_dependency_order.json`, scan `_index.md` for pending objects, select next 15-25 (depth-ordered, self-consistent slice), write `## Next Batch` to `_index.md`, STOP with plan summary
- [x] T040b [US1] Add staleness detection to Plan mode in `build-wiki-dwh.md` — check wiki `.md` file modified date against configurable staleness threshold (default: 30 days, FR-008). Objects with fresh docs are auto-skipped and marked `Done (Fresh)` in `_index.md`
- [x] T041 [US2] Add `_index.md` auto-generation logic to `build-wiki-dwh.md` Plan mode — if no `_index.md` exists, scan Dataplatform SSDT repo for all objects (Glob on DWH_dbo/Tables/*.sql, Views/*.sql), create `_index.md` with all objects as Pending per `index-management.mdc`
- [x] T042 [US1] Add Execute mode section to `build-wiki-dwh.md` — read queued objects from `_index.md` `## Next Batch`, group by depth level, dispatch parallel subagents per depth level
- [x] T043 [US1] Add parallel subagent dispatch instructions to `build-wiki-dwh.md` Execute mode — up to 4 concurrent subagents, 3 tables/subagent (Rule B1), 5 views/subagent. Include subagent prompt template referencing Phase 11 slim, Constitution IX repo paths, `_batch_context.json` glossary, existing dependency wiki files
- [x] T044 [US1] Add subagent quality enforcement to `build-wiki-dwh.md` — parent spot-check (Rule B7), serial fallback for failed quality checks, re-dispatch failed clusters
- [x] T045 [US2] Add per-object `_index.md` update to `build-wiki-dwh.md` Execute mode — after each subagent completes, update `_index.md` status from `Queued` to `Done (Batch N)` with quality score, or `Failed (Batch N) — {reason}`
- [x] T046 [US3] Add `_batch_context.json` write to `build-wiki-dwh.md` — at end of batch, accumulate glossary terms, relationship summaries, cross-references from all objects documented in this batch. Merge with existing `_batch_context.json` if present
- [x] T047 [US3] Add context loading to `build-wiki-dwh.md` Execute mode — read `_batch_context.json` at start, inject glossary and relationship summaries into each subagent prompt
- [x] T048 [US1] Add end-of-batch banner to `build-wiki-dwh.md` — print batch summary (objects processed/skipped/failed, avg quality, wall-clock time), clear `## Next Batch` section from `_index.md`, instruct operator to start new chat
- [x] T049 [US1] Add single-object mode to `build-wiki-dwh.md` — bypass Plan/Execute, document one object directly using the full phase pipeline (Phases 1-11 slim), update `_index.md`
- [x] T050 [US2] Add status mode to `build-wiki-dwh.md` — read-only: parse `_index.md`, display objects done/pending/failed, next batch plan, quality distribution. No file modifications
- [x] T051 [US1] Add scope option for enrich mode to `build-wiki-dwh.md` — run Phase 12 cross-object enrichment on existing docs without re-documenting
- [x] T052 [US1] Add scope option for review-rerun mode to `build-wiki-dwh.md` — regenerate docs for objects with pending reviewer corrections in `.review-needed.md`, Phase 11 only (no re-running Phases 1-10)
- [x] T053 [US1] Add rule file references to `build-wiki-dwh.md` — list all phase rules to load (01 through 14, 11 slim variant, repo-first-access, batch-orchestration, index-management, context-handoff, mcp-query-rules, fk-lookup-reference)

**Checkpoint**: `/build-wiki-dwh DWH_dbo` can plan batches, dispatch parallel subagents, update `_index.md`, and write `_batch_context.json`. All three P1 user stories are functional.

---

## Phase 4: Deployment Pipeline

**Goal**: Create the `write-objects-dwh` command and its tracking infrastructure. Reads wiki files produced by Phase 3, generates ALTER scripts, and deploys to Unity Catalog.

**Independent Test**: Run `/write-objects-dwh DWH_dbo.Dim_ActionType` (single object). Verify it reads the existing wiki `.md`, resolves the UC target, generates `.alter.sql` and `.downstream.alter.sql`, executes against UC, and writes `.deploy-report.md`.

### TG6: Create Deploy Index Management

- [x] T054 [P] Create `.cursor/rules/semantic-layer-core/deploy-index-management.mdc` with frontmatter — "Deploy Index Management — `_deploy-index.md` generation, update, and status display protocol for schema-level deployment tracking"
- [x] T055 [P] Add CREATE protocol to `deploy-index-management.mdc` — scan `_index.md` for objects with status `Done`, create `_deploy-index.md` with all as `Pending`, YAML frontmatter with schema/database/total_deployable/deployed/failed counts
- [x] T056 [P] Add UPDATE protocol to `deploy-index-management.mdc` — after each object deploys, update status to `Deployed (Batch N)` or `Failed (Batch N) — {reason}`. Update YAML counters
- [x] T057 [P] Add STATUS DISPLAY protocol to `deploy-index-management.mdc` — read-only progress summary with metrics table, next deployment batch, completed deployments log
- [x] T058 [P] Add STALE DETECTION to `deploy-index-management.mdc` — compare wiki `.md` file modification date against `_deploy-index.md` last deploy timestamp. Mark as `Stale — wiki updated` if wiki is newer

### TG2: Create Write Objects Command

- [x] T059 Create `.cursor/commands/write-objects-dwh.md` with command header, description, and argument parsing (schema name or single object)
- [x] T060 Add pre-flight checks to `write-objects-dwh.md` — Databricks MCP mandatory, Synapse MCP optional (PII GDPR queries — graceful degradation to column-name patterns), Atlassian not needed
- [x] T061 Add scope options to `write-objects-dwh.md` — Schema (deploy all Done objects), Resume (continue from last batch), Status (read-only from `_deploy-index.md`), Single (one object), Re-deploy (wiki updated after last deploy)
- [x] T062 Add per-object pipeline to `write-objects-dwh.md` — reference `11w-write-objects.mdc` for: wiki parsing → UC resolution → metadata → mapping → ALTER gen → tags → PII → downstream → execution → deploy report
- [x] T063 Add batch processing to `write-objects-dwh.md` — default batch 25, bottom-up from `_dependency_order.json`, parallel subagents (4 × 5-8 objects each), update `_deploy-index.md` after each object
- [x] T064 Add `_deploy-index.md` management to `write-objects-dwh.md` — auto-create on first run via `deploy-index-management.mdc`, update status after each deployment, stale detection for re-deploy scope
- [x] T065 Add single-object mode to `write-objects-dwh.md` — bypass batch planning, deploy one object directly
- [x] T066 Add rule file references to `write-objects-dwh.md` — list all rules to load (11w-write-objects, deploy-index-management, mcp-query-rules, repo-first-access)

**Checkpoint**: `/write-objects-dwh DWH_dbo` can deploy documented objects to UC. `_deploy-index.md` tracks progress. Single-object mode works for existing Batch 1 docs.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Deprecate old commands, update documentation, validate end-to-end.

### TG7: Deprecate Old Commands

- [x] T067 [P] Add `DEPRECATED` header to `.cursor/commands/build-semantic-layer-dwh.md` — point to `build-wiki-dwh.md` and `write-objects-dwh.md` as replacements. Keep file for reference
- [x] T068 [P] Add `DEPRECATED` header to `.cursor/commands/build-semantic-layer-dwh-no-propagation.md` — mark as redundant (wiki build IS no-propagation). Keep file for reference

### Validation & Documentation

- [x] T069 Update `_index.md` format reference in `.cursor/rules/semantic-layer-core/index-management.mdc` — remove any ALTER-related status text, ensure it only tracks wiki documentation status
- [x] T070 Validate quickstart.md scenarios in `specs/002-mass-process-orchestration/quickstart.md` — verify all command examples match actual command syntax and scope options
- [x] T071 Run backward-compatibility check — verify `/write-objects-dwh DWH_dbo.Dim_ActionType` works on existing Batch 1 wiki docs (already have `.md` files) without needing to re-run wiki build
- [ ] T072 Validate SC-001 quality gap — after first real wiki batch run, compare quality score of first object vs last object in batch. Gap must be ≤ 0.5 points. Log result in `_index.md` batch summary *(DEFERRED: requires real batch execution)*

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: ALREADY COMPLETE — verify only
- **Phase 2 (Foundational)**: Depends on Phase 1 verification — BLOCKS all command work
  - TG3 (Phase 11 refactor) and TG4 (Phase 11W create) can run in parallel
  - TG5 (batch orchestration) and T036 (Phase 13 split) can run in parallel with TG3/TG4
- **Phase 3 (Wiki Build Command)**: Depends on Phase 2 completion — needs slimmed Phase 11 and updated batch rules
- **Phase 4 (Deployment Pipeline)**: Depends on Phase 2 completion (needs Phase 11W) — can run in parallel with Phase 3
- **Phase 5 (Polish)**: Depends on Phases 3 and 4 completion

### Critical Path

```
Phase 1 (verify) → Phase 2 (TG3 + TG4 parallel) → Phase 3 (build-wiki-dwh) → Phase 5 (polish)
                    Phase 2 (TG4)                  → Phase 4 (write-objects-dwh) ↗
```

### Parallel Opportunities

Within Phase 2:
- T005-T019 (TG3: Phase 11 strip) are sequential within the same file
- T020-T032 (TG4: Phase 11W create) can run **in parallel** with TG3 — different file
- T033-T035 (TG5: batch orchestration) can run **in parallel** with TG3/TG4 — different file
- T036 (Phase 13 split) can run **in parallel** with TG3/TG4 — different file

Between Phase 3 and Phase 4:
- Phase 3 (build-wiki-dwh) and Phase 4 (write-objects-dwh) can run **in parallel** — different command files, both depend only on Phase 2

Within Phase 5:
- T067 and T068 can run in parallel — different files

---

## Parallel Execution Example

```
=== Round 1: Phase 2 (parallel rule work) ===
Agent A: T005-T019 (refactor Phase 11 to wiki-only)
Agent B: T020-T032 (create Phase 11W)
Agent C: T033-T036 (batch orchestration + Phase 13 split)

=== Round 2: Phase 3 + Phase 4 (parallel commands) ===
Agent A: T037-T053 (build-wiki-dwh command)
Agent B: T054-T066 (deploy-index + write-objects-dwh command)

=== Round 3: Phase 5 (polish) ===
Agent A: T067-T072 (deprecation + validation)
```

---

## Implementation Strategy

### MVP First (Wiki Build Only)

1. Complete Phase 1: Verify setup (already done)
2. Complete Phase 2: Refactor rules (TG3 + TG4 + TG5)
3. Complete Phase 3: `build-wiki-dwh` command
4. **STOP AND VALIDATE**: Run `/build-wiki-dwh DWH_dbo` — verify Plan mode plans 25 objects, Execute mode documents them with quality ≥ 7.0
5. This is the MVP — the wiki build pipeline is independently valuable even without deployment

### Incremental Delivery

1. Setup + Foundational → Rules ready
2. Wiki Build Command → **MVP — test independently, start documenting the schema**
3. Deployment Pipeline → Adds ALTER generation and UC deployment from wiki files
4. Polish → Deprecate old commands, validate backward compatibility

### Summary

| Metric | Value |
|--------|-------|
| **Total tasks** | 73 |
| **Phase 1 (Setup)** | 4 (verify only) |
| **Phase 2 (Foundational)** | 32 |
| **Phase 3 (Wiki Build)** | 18 (+T040b staleness) |
| **Phase 4 (Deployment)** | 13 |
| **Phase 5 (Polish)** | 6 (+T072 quality gap) |
| **Parallel opportunities** | 3 rounds (see example above) |
| **MVP scope** | Phases 1-3 (54 tasks) |
| **Estimated effort** | Phase 2: ~2-3 hours, Phase 3: ~2 hours, Phase 4: ~2 hours, Phase 5: ~30 min |

---

## Notes

- [P] tasks = different files, no dependencies on in-progress tasks
- [US1/US2/US3] labels map to spec.md user stories — all P1 priority, tightly coupled in the build-wiki-dwh command
- Phase 2 is the heaviest — 15 strip operations on Phase 11 + creating a new 11W rule from scratch
- T005-T019 are sequential because they modify the SAME file — but could be done as one large edit session
- The existing 8 documented objects (Batch 1) are backward compatible — no re-processing needed
- Constitution IX (Repo First) is already enforced — all new commands/rules must reference Dataplatform SSDT repo paths
