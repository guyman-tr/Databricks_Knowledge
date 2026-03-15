# Tasks: Deep Lineage Column Propagation

**Input**: Design documents from `/specs/001-deep-lineage-propagation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Config changes and script scaffolding

- [x] T001 Add `propagation` section with `blacklist[]` array to `.specify/Configs/dwh-semantic-doc-config.json` — include 10 ETL infrastructure columns (`etr_ymd`, `etr_ym`, `etr_y`, `UpdateDate`, `CreatedDate`, `FileName`, `_fivetran_synced`, `_row`, `__MEETS_DROP_EXPECTATIONS`, `Created`) each with `column_name`, `canonical_description`, and `category` per data-model.md Blacklist entity
- [x] T002 Create `knowledge/synapse/Wiki/_deep_propagate_lib.py` — shared Python module with: Databricks connection helper (reuses `databricks-sql-connector` with OAuth, single session), CLI argument parsing (`discover` / `execute` subcommands), and constants (batch size default=30, blacklist path)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data structures and query functions that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Implement `LineageTree`, `DownstreamNode`, `ColumnMatch` dataclasses in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — JSON serialization/deserialization for `{Object}.lineage-tree.json` per data-model.md
- [x] T004 [P] Implement `ProgressLog`, `BatchStatus` dataclasses in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — JSON serialization/deserialization for `{Object}.propagation-progress.json` per data-model.md, including `load_or_create()` and `save()` methods
- [x] T005 [P] Implement `load_blacklist()` function in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — reads `propagation.blacklist[].column_name` from `dwh-semantic-doc-config.json`, returns a case-insensitive set for filtering
- [x] T006 Implement `load_source_descriptions()` function in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — reads an existing `{Object}.alter.sql` file from the same directory, parses each `ALTER COLUMN {col} COMMENT '{desc}'` line, returns a dict mapping column_name → description (including tier tags). This is the source of truth for what descriptions to propagate

**Checkpoint**: Foundation ready — data structures, config loading, and source description parsing all work

---

## Phase 3: User Story 1 + User Story 3 — Full Lineage Tree Discovery + Batched Execution (Priority: P1) MVP

**Goal**: Discover ALL downstream objects via lineage traversal (US1) and process them in memory-safe batches (US3). These stories are architecturally intertwined: discovery writes the tree to disk (US3), execution reads from disk and batches (US3), applying descriptions to discovered objects (US1).

**Independent Test**: Run `python {Object}_deep_propagate.py discover` on `BI_DB_CIDFirstDates`. Verify the lineage tree JSON contains significantly more than 6 objects. Then run `execute` and verify ALTER statements succeed in batches without crashing.

### Implementation

- [x] T007 [P] [US1] Implement `query_column_lineage()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — queries `system.access.column_lineage` filtered by `source_table_full_name`, paginates results (LIMIT/OFFSET or date partitioning on `event_date`), returns list of `(target_table_full_name, target_column_name, source_column_name)` tuples. Must filter out rows where `target_table_full_name IS NULL` or `target_column_name IS NULL`. Exclude blacklisted columns from results
- [x] T008 [P] [US1] Implement `query_name_pattern()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — port the existing 3 discovery methods from Phase 11 (name-pattern search on `information_schema.tables`, function search on `information_schema.routines`, column cross-match with 5+ shared business columns). Returns list of candidate `(catalog, schema, table, type)` tuples
- [x] T009 [US1] Implement `discover_tree()` BFS traversal in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — takes source table name + source descriptions dict, runs `query_column_lineage()` recursively with `visited` set for cycle detection (FR-007), unions with `query_name_pattern()` results (FR-012), deduplicates (FR-006), builds `LineageTree` with `DownstreamNode` objects including `hop_distance`, writes `.lineage-tree.json` to disk (FR-003)
- [x] T010 [US1] Implement `match_columns()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — for a given downstream object, runs `DESCRIBE {full_name}` to get its column list, matches against source descriptions by exact name (case-insensitive), populates `ColumnMatch` objects with `match_type='identical'` and the description to propagate. Skips blacklisted columns
- [x] T011 [US3] Implement `execute_batches()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — reads `.lineage-tree.json`, chunks nodes into batches (configurable size, default 30), for each batch: calls `match_columns()`, generates `ALTER TABLE ... ALTER COLUMN ... COMMENT` (for tables) or `COMMENT ON COLUMN` (for views), executes via `cursor.execute()`, updates `ProgressLog` after each batch (FR-009). Skips batches already marked `completed` in progress log (resume support)
- [x] T012 [US3] Implement `generate_downstream_alter_sql()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — after all batches complete, writes the `.downstream.alter.sql` file in the existing format (header with target list, one ALTER per column grouped by target object). Larger than before but same format
- [x] T013 [US1] Create `{Object}_deep_propagate.py` generation template in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — a `generate_script()` function that writes a per-table Python script (like the existing `_deploy.py` pattern) which imports from `_deep_propagate_lib.py`, accepts `discover` or `execute` CLI args, and calls the appropriate functions with the correct source table name and file paths

**Checkpoint**: Running `discover` on a documented table produces a `.lineage-tree.json` with 10x+ more objects than the current approach. Running `execute` processes them in batches without crashing and produces a `.downstream.alter.sql`.

---

## Phase 4: User Story 2 — Renamed Column Detection (Priority: P2)

**Goal**: Detect columns renamed downstream (e.g., `FirstDepositDate` → `FTDDate`) via lineage metadata and propagate descriptions with rename context.

**Independent Test**: After discovery, check `.lineage-tree.json` for `ColumnMatch` entries with `match_type='renamed'`. Verify the generated ALTER statement includes the rename annotation.

**Depends on**: Phase 3 (discovery + execution must work for identical columns first)

### Implementation

- [x] T014 [US2] Implement `is_plausible_rename()` heuristic in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — filters `source_column_name != target_column_name` results from lineage: target must be valid SQL identifier (alphanumeric + underscore only), no arithmetic operators, length ratio < 3x. Per research.md R2
- [x] T015 [US2] Extend `discover_tree()` to populate `ColumnMatch` objects with `match_type='renamed'` and `rename_chain` when lineage shows a source→target column name difference that passes `is_plausible_rename()`. Track rename chains across multi-hop traversal (e.g., `FirstDepositDate → FTDDate → ftd`) in `knowledge/synapse/Wiki/_deep_propagate_lib.py`
- [x] T016 [US2] Implement `format_rename_description()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — takes the original description + rename chain, produces a propagation description like: `"Same as FirstDepositDate: {original description}. (Propagated from {source_table}.{source_column})"`. Must fit within 1024-char UC limit
- [x] T017 [US2] Extend `execute_batches()` to handle renamed columns — already handled via generic col_data["target_column"] + col_data["description"] flow — use the formatted rename description for `match_type='renamed'` entries. ALTER statement targets the renamed column name, not the source name

**Checkpoint**: Discovery detects renames in the lineage tree. Execution propagates descriptions with rename context to renamed columns.

---

## Phase 5: User Story 4 — Propagation Scope Report (Priority: P3)

**Goal**: Generate a human-readable scope report before execution showing blast radius, enabling the operator to review before committing.

**Independent Test**: Run `python {Object}_deep_propagate.py discover` and verify `{Object}.propagation-scope.md` is generated with accurate counts. No ALTER statements executed.

### Implementation

- [x] T018 [US4] Implement `generate_scope_report()` in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — reads `.lineage-tree.json`, generates `{Object}.propagation-scope.md` with: source summary, downstream objects table (by type with column match counts), renamed columns table, blacklisted/excluded columns, estimated ALTER statement count, batch breakdown (N batches of M objects). Per data-model.md ScopeReport entity
- [x] T019 [US4] Integrate scope report generation into the `discover` CLI subcommand — after `discover_tree()` writes the lineage tree, automatically call `generate_scope_report()`. Print a summary to stdout (total objects, total statements, renames found)

**Checkpoint**: `discover` produces both `.lineage-tree.json` and `.propagation-scope.md`. Operator can review scope before running `execute`.

---

## Phase 6: Broadcast Propagation (FR-014, FR-015)

**Purpose**: Standalone script for blacklisted ETL columns, independent of per-table pipeline

- [x] T020 [P] Create `knowledge/synapse/Wiki/_broadcast_propagate.py` — standalone script that: reads blacklist from config, for each blacklisted column queries `system.information_schema.columns` to find ALL instances across the catalog (excluding `information_schema` schema), generates ALTER statements with the `canonical_description` from config, executes via single Databricks session in batches of 100 objects, writes `_broadcast_propagation.log` with results
- [x] T021 [P] Add `--dry-run` flag to `_broadcast_propagate.py` — prints estimated ALTER count per blacklisted column without executing

**Checkpoint**: Running `_broadcast_propagate.py` applies trivial descriptions (e.g., "ETL partition column: year-month-day") to all 1,475 instances of `etr_ymd` across the catalog in one batch.

---

## Phase 7: Bottom-Up Dependency Mapping + Pipeline Integration

**Purpose**: Build the source-table dependency graph for bottom-up processing order (FR-016) and wire deep lineage into Phase 11

- [x] T022 ~~Create `knowledge/synapse/Wiki/_build_dependency_order.py`~~ **DONE** — reads the SSDT-generated `sql_dp_prod_we_Dependencies.json` from the DataPlatform repo + parses each SP's `.sql` file for write targets (INSERT INTO, MERGE INTO, UPDATE), builds a table-to-table dependency graph (2,134 objects, 16,252 edges), topologically sorts it, and writes `_dependency_order.json`. Format: `[{table: "schema.table", depth: N, depends_on: [...]}]` sorted bottom-up (depth 0 = leaf/production sources). Pure local processing, no Synapse or Databricks queries. Re-run when DataPlatform repo is updated
- [x] T023 Update the "Downstream Column Comment Propagation" section in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — replace the inline discovery logic with instructions to: (a) generate `{Object}_deep_propagate.py` using the lib's `generate_script()`, (b) run `discover` via Shell tool, (c) read and present the scope report, (d) run `execute` via Shell tool, (e) read execution results for the deploy report. Keep the existing output file format (`.downstream.alter.sql`). Reference `_dependency_order.json` as the recommended processing sequence
- [x] T024 Update the "Deploy Report Template" section in `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` — add deep lineage stats to Section 4: total objects discovered (lineage vs name-pattern breakdown), renames detected, blacklisted columns excluded, batch count, resume events if any
- [x] T025 Add `_deep_propagate_lib.py` and `_build_dependency_order.py` to `.gitignore` exceptions or document them as committed shared modules (not generated/deleted like `_deploy.py`) in the project README or pipeline docs

**Checkpoint**: Running the full 14-phase pipeline on a new table automatically triggers deep lineage propagation instead of the old name-pattern approach.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, error handling, and documentation

- [x] T026 [P] Add error handling for dropped objects in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — when `DESCRIBE {full_name}` fails (object dropped since lineage was recorded), log a warning, skip the object, continue to next batch
- [x] T027 [P] Add error handling for permission denied in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — when `ALTER/COMMENT` fails with permission error, log the object/column, mark in progress log as `failed` with reason, continue
- [x] T028 [P] Add error handling for lineage query failure in `knowledge/synapse/Wiki/_deep_propagate_lib.py` — if `system.access.column_lineage` query fails (permissions, timeout), fall back to name-pattern-only discovery and log a warning
- [x] T029 [P] Add `--schema-filter` and `--batch-size` CLI options to `{Object}_deep_propagate.py` — `--schema-filter` limits execution to specific schemas (e.g., `--schema-filter main.bi_output,main.etoro_kpi`) per US4-AS2; `--batch-size` overrides the default batch size of 30 (FR-004)
- [x] T030 Update `specs/001-deep-lineage-propagation/quickstart.md` with actual file paths and validated CLI commands after implementation is complete
- [x] T031 Clean up temporary research scripts — moved to `scripts/` subfolder: `specs/001-deep-lineage-propagation/column_frequency_query.py` and `specs/001-deep-lineage-propagation/lineage_research.py` — move to a `scripts/` subfolder or delete if no longer needed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (config must exist to load blacklist)
- **US1+US3 (Phase 3)**: Depends on Phase 2 — core discovery + execution
- **US2 (Phase 4)**: Depends on Phase 3 — extends discovery with rename detection
- **US4 (Phase 5)**: Depends on Phase 3 — reads lineage tree to generate report
- **Broadcast (Phase 6)**: Independent — can run in parallel with any phase after Phase 1
- **Pipeline Integration (Phase 7)**: Depends on Phases 3-5 all being complete
- **Polish (Phase 8)**: Can start after Phase 3; T025-T027 are independent

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundation)
                       │
                       ├── Phase 3 (US1+US3) ──┬── Phase 4 (US2) ──┐
                       │                        │                    │
                       │                        └── Phase 5 (US4) ──┤
                       │                                             │
                       └── Phase 6 (Broadcast) ─────────────────────┤
                                                                     │
                                                              Phase 7 (Integration)
                                                                     │
                                                              Phase 8 (Polish)
```

### Parallel Opportunities

- **Phase 2**: T003, T004, T005 can all run in parallel (different dataclasses/functions)
- **Phase 3**: T007 and T008 can run in parallel (different discovery methods)
- **Phase 5 + Phase 4**: US4 scope report (Phase 5) can start as soon as Phase 3 is done, in parallel with US2 rename detection (Phase 4)
- **Phase 6**: Broadcast is fully independent after Phase 1 — can be built alongside Phase 3
- **Phase 8**: T025, T026, T027 are all independent of each other

---

## Parallel Example: Phase 2 (Foundational)

```
# All three can be launched together (different functions, no dependencies):
Task T003: "Implement LineageTree, DownstreamNode, ColumnMatch dataclasses"
Task T004: "Implement ProgressLog, BatchStatus dataclasses"
Task T005: "Implement load_blacklist() function"
```

## Parallel Example: Phase 3 (US1+US3)

```
# These two discovery methods are independent:
Task T007: "Implement query_column_lineage() — lineage-based discovery"
Task T008: "Implement query_name_pattern() — name-pattern discovery (ported from Phase 11)"

# After both complete, T009 unions them into the BFS traversal
```

---

## Implementation Strategy

### MVP First (Phase 1 + 2 + 3 Only)

1. Complete Phase 1: Setup (config + scaffold) — ~15 min
2. Complete Phase 2: Foundation (dataclasses + loaders) — ~30 min
3. Complete Phase 3: US1+US3 (discovery + batched execution) — ~2 hours
4. **STOP and VALIDATE**: Run on `BI_DB_CIDFirstDates`, compare object count vs old approach
5. If 10x+ more objects discovered and execution completes without crashing → MVP proven

### Incremental Delivery

1. **MVP**: Setup + Foundation + US1/US3 → Deep lineage works for identical columns
2. **+Renames**: Add Phase 4 (US2) → Renamed columns also propagated
3. **+Scope Report**: Add Phase 5 (US4) → Operator visibility before execution
4. **+Broadcast**: Add Phase 6 → ETL columns handled separately
5. **+Integration**: Add Phase 7 → Wired into the main pipeline rule
6. **+Polish**: Add Phase 8 → Error handling, filtering, cleanup

---

## Notes

- All Python code lives in ONE shared module (`_deep_propagate_lib.py`) plus generated per-table scripts. No package structure — this is a POC.
- The `_deep_propagate_lib.py` is a committed file (unlike `_deploy.py` which is generated and deleted). It persists across runs.
- The `.lineage-tree.json` and `.propagation-progress.json` are ephemeral artifacts — they can be regenerated by re-running `discover`.
- Total tasks: 31
- Estimated MVP time (Phases 1-3): ~3 hours of implementation
- Estimated full implementation (all phases): ~6-8 hours
