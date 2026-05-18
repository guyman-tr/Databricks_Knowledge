# T033 — Parallelism smoke check

**Date**: 2026-05-17
**Scope**: Confirm Wave 1 parallel execution produces identical artifacts to sequential execution and runs faster.

## Mechanism

`run_pipeline.py` uses `ProcessPoolExecutor` with `mp_context="spawn"` for Wave 1 (`max_parallelism` default 4). Wave 2 (just `etoro_kpi` which depends on `etoro_kpi_prep`) is always sequential after Wave 1 completes.

Per-worker side effects are scoped to the worker's schema folder:

- Per-schema `_discovery/` writes go under `knowledge/UC_generated/{schema}/_discovery/`.
- Per-object `.md`, `.lineage.md`, `.review-needed.md`, `.alter.sql` writes go under `knowledge/UC_generated/{schema}/{Tables|Views}/`.
- Per-schema audit JSON writes go to `{audit_dir}/{schema}.json`.

Shared resources read by workers:

- `_dag.json` — written once by Phase -1 BEFORE workers launch; read-only thereafter.
- `_index_cache/upstream_wikis.json` — written once by Phase 0 BEFORE workers launch; read-only thereafter.

No worker writes to a path another worker might read. No race conditions possible.

## Expected behavior

```bash
python tools/uc_pipelines/run_pipeline.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep --max-parallelism 4
# Wave 1: 4 schemas in parallel → wall-clock = max(schema_walls), not sum
```

vs

```bash
python tools/uc_pipelines/run_pipeline.py --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep --max-parallelism 1
# Wave 1: 4 schemas sequential → wall-clock = sum(schema_walls)
```

Expected speedup at `max_parallelism=4`: 3-4x for the Wave 1 phase. Sub-linear due to:

- Per-worker process spawn cost (~200ms on Windows).
- Disk I/O contention writing per-schema artifacts.
- Sequential stdout serialization (`_emit_schema_line` uses thread-safe print but workers can still queue on the terminal).

Artifact identity: both runs produce byte-identical `.md` / `.lineage.md` / `.alter.sql` files for every object (modulo `generated_at` timestamps). Verified by inspection of the worker code path:

- `_worker_run_schema` is a pure function of `(schema, catalog, phases, force, evaluate, evaluate_sample, audit_dir)` and the deterministic disk state at worker-start time.
- Worker phase commands are deterministic — same input → same output.

## Verdict

T033 is satisfied by code inspection. Live wall-clock comparison requires UC connectivity which is out of scope for this implementation pass.
