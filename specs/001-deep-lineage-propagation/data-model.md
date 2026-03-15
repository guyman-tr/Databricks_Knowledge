# Data Model: Deep Lineage Column Propagation

**Branch**: `001-deep-lineage-propagation` | **Date**: 2026-03-15

## Entities

### 1. LineageTree (on-disk artifact)

The complete downstream dependency graph for a single source table. Written to disk as JSON after discovery, consumed by execution.

```
{ObjectName}.lineage-tree.json
```

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `source` | object | `{catalog, schema, table, type}` — the documented source table |
| `discovered_at` | datetime | When discovery was run |
| `discovery_methods` | string[] | Which methods found results: `["lineage", "name_pattern", "column_cross_match"]` |
| `total_downstream_objects` | int | Count of all unique downstream objects |
| `total_column_matches` | int | Count of same-name column matches |
| `total_renames` | int | Count of detected renames |
| `nodes` | DownstreamNode[] | All downstream objects |

### 2. DownstreamNode

A single downstream object in the lineage tree.

| Field | Type | Description |
|-------|------|-------------|
| `catalog` | string | UC catalog |
| `schema` | string | UC schema |
| `table` | string | UC table/view name |
| `full_name` | string | `catalog.schema.table` |
| `object_type` | string | TABLE, VIEW, MATERIALIZED_VIEW, STREAMING_TABLE, METRIC_VIEW |
| `hop_distance` | int | Shortest path length from source (1 = direct child) |
| `discovered_via` | string | `lineage`, `name_pattern`, `column_cross_match`, `function_search` |
| `columns` | ColumnMatch[] | Matched columns for this object |

### 3. ColumnMatch

A single column mapping between source and downstream.

| Field | Type | Description |
|-------|------|-------------|
| `source_column` | string | Column name in the documented source table |
| `target_column` | string | Column name in the downstream object |
| `match_type` | enum | `identical` (same name) or `renamed` (different name, lineage-traced) |
| `rename_chain` | string[] | If renamed: the full chain, e.g., `["FirstDepositDate", "FTDDate", "ftd"]` |
| `description` | string | The description to propagate (from source Elements table) |
| `tier` | string | Confidence tier from source (e.g., `Tier 2 — SP code`) |

### 4. ProgressLog (on-disk artifact)

Tracks execution progress for resumability.

```
{ObjectName}.propagation-progress.json
```

| Field | Type | Description |
|-------|------|-------------|
| `source` | string | Source table full name |
| `started_at` | datetime | When execution began |
| `total_batches` | int | Total batches planned |
| `completed_batches` | int | Batches finished |
| `batches` | BatchStatus[] | Per-batch status |

### 5. BatchStatus

| Field | Type | Description |
|-------|------|-------------|
| `batch_id` | int | Sequential batch number |
| `objects` | string[] | Full names of objects in this batch |
| `status` | enum | `pending`, `in_progress`, `completed`, `failed` |
| `statements_succeeded` | int | ALTER statements that succeeded |
| `statements_failed` | int | ALTER statements that failed |
| `completed_at` | datetime | When batch finished |
| `errors` | ErrorEntry[] | Any failures |

### 6. Blacklist (config artifact)

```
dwh-semantic-doc-config.json → propagation.blacklist[]
```

| Field | Type | Description |
|-------|------|-------------|
| `column_name` | string | Column name to exclude (case-insensitive) |
| `canonical_description` | string | Trivial universal description for broadcast |
| `category` | string | `etl_partition`, `etl_metadata`, `infrastructure` |

### 7. ScopeReport (on-disk artifact)

```
{ObjectName}.propagation-scope.md
```

Pre-execution summary showing blast radius. Markdown format for human review.

| Section | Content |
|---------|---------|
| Source table | Name, column count, description count |
| Downstream objects | Table of all objects by type with column match counts |
| Renamed columns | Table of source→target rename mappings detected |
| Blacklisted (excluded) | Columns skipped due to blacklist |
| Skipped — computed transformation | Lineage-detected column mappings that failed the rename heuristic (e.g., `YEAR(col)`, `col * 100`). Listed for operator review per FR-011 |
| Estimated statements | Total ALTER statements that will execute |
| Execution plan | Batch breakdown (N batches of M objects each) |

## Relationships

```
Source Table (documented)
    │
    ├── LineageTree (1:1, written to disk after discovery)
    │       │
    │       ├── DownstreamNode (1:N, each downstream object)
    │       │       │
    │       │       └── ColumnMatch (1:N, per matched column)
    │       │
    │       └── ScopeReport (1:1, generated before execution)
    │
    ├── ProgressLog (1:1, tracks execution state)
    │       │
    │       └── BatchStatus (1:N, per batch)
    │
    └── Blacklist (N:1, shared config across all source tables)
```

## State Transitions

### Propagation Run Lifecycle

```
DISCOVERY → TREE_BUILT → SCOPE_REPORTED → EXECUTING → COMPLETED
                                              │
                                              ├── INTERRUPTED (crash/cancel)
                                              │       │
                                              │       └── RESUMED → EXECUTING
                                              │
                                              └── FAILED (unrecoverable)
```

### Batch Lifecycle

```
pending → in_progress → completed
                    └── failed
```
