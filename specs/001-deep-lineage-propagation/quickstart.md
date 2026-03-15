# Quickstart: Deep Lineage Column Propagation

**Branch**: `001-deep-lineage-propagation` | **Date**: 2026-03-15

## What This Does

After the existing 14-phase pipeline documents a Synapse table and generates its `.alter.sql` + `.downstream.alter.sql`, this feature extends downstream propagation from ~6 name-matched objects to **every reachable downstream object** in Unity Catalog via lineage tracing.

## Prerequisites

1. A fully documented table with `.alter.sql` already executed (Phases 1-14 complete)
2. Python 3.11+ with `databricks-sql-connector` installed
3. Databricks OAuth configured (first run opens browser popup)

## How to Run

### Step 1: Generate the Per-Table Script

From the pipeline (Phase 11) or manually:

```python
import sys, os
sys.path.insert(0, r"C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki")
import _deep_propagate_lib as lib

lib.generate_script(
    source_uc_name="main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates",
    source_synapse_name="BI_DB_dbo.BI_DB_CIDFirstDates",
    object_dir=r"knowledge\synapse\Wiki\BI_DB_dbo\Tables",
    object_name="BI_DB_CIDFirstDates",
)
```

### Step 2: Discovery

```bash
python knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates_deep_propagate.py discover
```

Output: `BI_DB_CIDFirstDates.lineage-tree.json` + `BI_DB_CIDFirstDates.propagation-scope.md`

### Step 3: Review Scope Report

Read `BI_DB_CIDFirstDates.propagation-scope.md` — shows total downstream objects, column matches, renames detected, estimated ALTER statements, batch plan.

### Step 4: Execute

```bash
python knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates_deep_propagate.py execute
```

Processes the tree in batches of 30 objects (default). Progress is logged to `.propagation-progress.json`. If interrupted, re-run the same command — it resumes from the last completed batch.

**CLI options**:
- `--batch-size 50` — override batch size
- `--schema-filter main.bi_output,main.etoro_kpi` — limit execution to specific schemas

Or run both in one go:
```bash
python knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates_deep_propagate.py both
```

### Step 5: Broadcast (one-time, separate)

For blacklisted ETL columns (`etr_ymd`, `etr_ym`, `etr_y`, `UpdateDate`, etc.):

```bash
python knowledge\synapse\Wiki\_broadcast_propagate.py           # execute
python knowledge\synapse\Wiki\_broadcast_propagate.py --dry-run  # preview only
```

## Key Files

| File | Purpose |
|------|---------|
| `_deep_propagate_lib.py` | Shared library (committed, not generated) |
| `_build_dependency_order.py` | Builds Synapse dependency graph from SSDT repo |
| `_dependency_order.json` | Generated: 2,134 objects with depth, bottom-up order |
| `_broadcast_propagate.py` | Standalone blacklist propagation |
| `.specify/Configs/dwh-semantic-doc-config.json` | Blacklist configuration |
| | |
| `{Object}.lineage-tree.json` | Discovered lineage tree (per table, on disk) |
| `{Object}.propagation-scope.md` | Pre-execution blast radius report |
| `{Object}.propagation-progress.json` | Resumable execution state |
| `{Object}.downstream.alter.sql` | Generated ALTER statements |

## Validated Example

Running discovery on `BI_DB_CIDFirstDates`:
- **8 downstream objects** discovered (vs 2 in old approach — **4x improvement**)
- **407 column matches** across schemas: `data_rooms`, `regtech`, `api_delta`, `api_general`
- Methods: `lineage` (UC column_lineage BFS) + `name_pattern` (information_schema search)
- Execution time: ~50 seconds
- Memory: stable, no crashes

## What Changed from the Existing Pipeline

| Aspect | Before | After |
|--------|--------|-------|
| Discovery | Name-pattern + column cross-match | Lineage tree BFS + name-pattern (union) |
| Scope | ~2 objects (name-matched) | 8+ objects (lineage-traced), grows with catalog usage |
| Renames | Not detected | Detected via lineage source/target column mapping |
| Memory | All in agent context (crashed) | Python script, batched, on-disk tree |
| Resumability | None (restart from scratch) | Progress log, resume from last batch |
| Ubiquitous columns | Processed per-table | Blacklisted, broadcast separately |
| Processing order | Ad-hoc | Bottom-up via `_dependency_order.json` |
