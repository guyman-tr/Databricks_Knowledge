# Implementation Plan: Deep Lineage Column Propagation

**Branch**: `001-deep-lineage-propagation` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-deep-lineage-propagation/spec.md`

## Summary

Replace the current name-pattern downstream propagation (6 objects for CIDFirstDates) with a full lineage-tree traversal that traces every documented column through Unity Catalog's `system.access.column_lineage` (297M rows) — including renamed columns — to reach hundreds of downstream objects. Processing is memory-safe via a standalone Python script that discovers the tree on disk, reports scope, and executes ALTER statements in resumable batches. Ultra-ubiquitous ETL columns are blacklisted and broadcast separately.

## Technical Context

**Language/Version**: Python 3.11  
**Primary Dependencies**: `databricks-sql-connector`, `databricks-sdk` (already installed)  
**Storage**: JSON files on disk (lineage tree, progress log), SQL files (ALTER scripts), Markdown (scope report)  
**Testing**: Manual validation against UC (POC phase — no formal test framework)  
**Target Platform**: Windows VM (local machine), Cursor IDE, Databricks SQL Warehouse  
**Project Type**: Cursor rules (.mdc) + Python scripts — extends the existing dwh-semantic-doc pipeline  
**Performance Goals**: Handle 1,000+ downstream objects without memory crashes; < 30min for 500-object tree  
**Constraints**: Cursor agent context window limits; single-session Databricks connection; MCP 10-call write limit for metadata reads  
**Scale/Scope**: 37,293 distinct column names across UC; tables with up to 862 downstream occurrences (InstrumentID); lineage table has 297M rows

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Agent-First Knowledge | **PASS** | ALTER scripts remain the ultimate deliverable. Deep lineage just reaches more objects. |
| II. Code Is King | **PASS** | Lineage data comes from actual query execution — it IS code-derived evidence. Tier hierarchy preserved through bottom-up processing. |
| III. Accuracy Over Coverage | **PASS** | Always-overwrite with bottom-up order preserves the Tier hierarchy (Tier 1 wins). No fabrication — descriptions are copied from documented source, not invented. |
| IV. Incremental Delivery | **PASS** | Per-table processing, resumable batches, independent deployment. Each table can be propagated independently. |
| V. Canonical Metadata Schema | **PASS** | Uses the existing ALTER script format and COMMENT syntax. No new metadata format introduced. |
| VI. Lineage Is First-Class | **PASS** | This feature IS the lineage implementation. Makes lineage operational, not just documented. |
| VII. Domain Boundaries | **N/A** | Propagation crosses domain boundaries by design — a column's meaning is the same regardless of which domain consumes it. |
| VIII. Don't Rebuild What Exists | **PASS** | Extends existing Phase 11 output. Inherits existing discovery methods (name-pattern, column cross-match) and adds lineage traversal on top. |

**Quality Gates**:
- ALTER scripts target validated UC objects: **PASS** — reuses existing UC resolution from Phase 11
- 1024-char limit: **PASS** — descriptions are inherited from source, already within limits
- THREE output files: **PASS** — this adds a 4th/5th file (lineage tree, scope report) alongside the existing 3
- Phase 10 mandatory: **N/A** — this feature operates after Phase 11, not during the documentation phases

**No violations. No complexity tracking needed.**

## Project Structure

### Documentation (this feature)

```text
specs/001-deep-lineage-propagation/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research findings
├── data-model.md        # Entity definitions
├── quickstart.md        # How to run
├── column_frequency.csv # Data-driven analysis (37,293 column names)
├── column_frequency_query.py  # Script that generated the CSV
├── lineage_research.py  # Script that explored system.access.column_lineage
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (changes to existing pipeline)

```text
.cursor/rules/dwh-semantic-doc/
├── 11-generate-documentation.mdc  # MODIFY: Update downstream propagation section
│                                  #   - Add blacklist filtering
│                                  #   - Replace inline discovery with Python script trigger
│                                  #   - Add scope report review step
│                                  #   - Add lineage tree + progress log file references
└── (no new .mdc files — logic lives in Python)

.specify/Configs/
└── dwh-semantic-doc-config.json   # MODIFY: Add propagation.blacklist[] section

knowledge/synapse/Wiki/
├── _broadcast_propagate.py        # NEW: One-time broadcast for blacklisted columns
├── _build_dependency_order.py     # DONE: Parses SSDT deps JSON + SP write targets → topo sort
├── _dependency_order.json         # GENERATED: 2,134 objects, depth 0-5, bottom-up order
└── {Schema}/Tables/
    ├── {Object}_deep_propagate.py       # GENERATED per table (like _deploy.py)
    ├── {Object}.lineage-tree.json       # GENERATED: Discovery output
    ├── {Object}.propagation-scope.md    # GENERATED: Pre-execution scope report
    ├── {Object}.propagation-progress.json  # GENERATED: Resumable execution state
    └── {Object}.downstream.alter.sql    # EXISTING: Now much larger with deep lineage
```

**Structure Decision**: No new directories. The deep lineage propagator follows the existing pattern of generating a temporary Python script per table (like `_deploy.py`), plus on-disk artifacts for the tree, scope report, and progress log. The broadcast propagator is a single shared script.

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 11 (AI Agent in Cursor)                              │
│                                                             │
│  1. Generate wiki + sidecar + ALTER script (existing)       │
│  2. Execute main ALTER via _deploy.py (existing)            │
│  3. Generate _deep_propagate.py ◄── NEW                    │
│  4. Trigger discovery ◄── NEW                               │
│  5. Review scope report ◄── NEW                             │
│  6. Trigger batched execution ◄── NEW                       │
└────────────────────┬────────────────────────────────────────┘
                     │ Shell tool
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  _deep_propagate.py (standalone Python, single DB session)  │
│                                                             │
│  discover:                                                  │
│    1. Query system.access.column_lineage (paginated)        │
│    2. Recursive BFS traversal (with cycle detection)        │
│    3. Union with name-pattern + column cross-match          │
│    4. Filter out blacklisted columns                        │
│    5. Detect renames (heuristic filter)                     │
│    6. Write .lineage-tree.json to disk                      │
│    7. Generate .propagation-scope.md                        │
│                                                             │
│  execute:                                                   │
│    1. Read .lineage-tree.json                               │
│    2. Load/create .propagation-progress.json                │
│    3. For each batch (default 30 objects):                    │
│       a. DESCRIBE each object → get column list             │
│       b. Match columns (identical + renamed)                │
│       c. Generate ALTER statements                          │
│       d. Execute via cursor.execute()                       │
│       e. Update progress log                                │
│    4. Write final .downstream.alter.sql                     │
│    5. Append summary to deploy-report.md                    │
└─────────────────────────────────────────────────────────────┘
```

### Discovery Algorithm (BFS with Cycle Detection)

```
INPUT: source_table (catalog.schema.table), source_columns with descriptions
OUTPUT: lineage-tree.json

visited = set()
queue = [source_table]
tree = []

while queue:
    current = queue.pop(0)
    if current in visited: continue  # cycle detection
    visited.add(current)
    
    # Query lineage for this object's columns
    downstream = query_column_lineage(
        source_table=current,
        exclude_blacklist=True
    )
    
    for target in downstream:
        # Deduplicate
        if target.full_name not in visited:
            queue.append(target.full_name)
        
        # Record column matches
        for col_mapping in target.columns:
            if col_mapping.source != col_mapping.target:
                # Rename detected — apply heuristic filter
                if is_plausible_rename(col_mapping):
                    record_rename(col_mapping)
            else:
                record_identical(col_mapping)
    
    # Also run name-pattern search (union)
    name_matches = query_name_pattern(current)
    for match in name_matches:
        if match.full_name not in visited:
            tree.append(match)  # Don't traverse further — these are leaf nodes

# Fallback: if column_lineage query fails (permissions, timeout),
# fall back to name-pattern-only discovery and log a warning (FR-012 + T028)
write_to_disk(tree)
generate_scope_report(tree)
```

### Rename Heuristic

```
is_plausible_rename(mapping):
    target = mapping.target_column_name
    
    # Must be a valid SQL identifier
    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', target):
        return False
    
    # Must not contain arithmetic operators
    if any(op in target for op in ['+', '-', '*', '/', '%']):
        return False
    
    # Length ratio < 3x
    ratio = max(len(source), len(target)) / min(len(source), len(target))
    if ratio > 3.0:
        return False
    
    return True
```

### Batched Execution Flow

```
execute(tree, batch_size=30):
    progress = load_or_create_progress()
    batches = chunk(tree.nodes, batch_size)
    
    for batch in batches:
        if progress.is_completed(batch.id):
            continue  # resume support
        
        progress.mark_in_progress(batch.id)
        save_progress(progress)
        
        for node in batch.objects:
            columns = describe_table(node.full_name)
            for match in node.column_matches:
                if match.target_column in columns:
                    stmt = generate_alter(node, match)
                    execute_stmt(stmt)
        
        progress.mark_completed(batch.id)
        save_progress(progress)
    
    write_downstream_alter_sql(all_statements)
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Discovery engine | Standalone Python script | Agent context window caused crashes; Python can handle 297M row table |
| Tree traversal | BFS with visited-set cycle detection | Handles DAG with possible cycles; BFS gives hop distance for free |
| Rename detection | Heuristic filter on lineage data | Lineage records all column mappings; heuristic separates renames from expressions |
| Blacklist scope | ETL infrastructure only (~10 columns) | Universal FKs stay in pipeline (rich context); `Name`/`Date`/`Amount` stay (context-dependent) |
| Output format | Same `.downstream.alter.sql` (larger) | Preserves independent deployment per source table |
| Execution | Single Databricks session, batched | Avoids MCP tab explosion; batching prevents memory issues |
| Conflict resolution | Bottom-up order, always overwrite | Most upstream (Tier 1) description is written first; later runs converge on same root |
| Discovery strategy | Union of lineage + name-pattern | Maximizes coverage during POC; lineage primary, name-pattern fills gaps |
| Dependency order source | SSDT repo (not UC lineage) | UC can't see Synapse-internal ETL ("black hole"). SSDT deps JSON + SP code parsing gives the real table-to-table graph. 2,134 objects, 16,252 edges, pure local processing |
