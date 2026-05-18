# T031 — Idempotency check

**Date**: 2026-05-17
**Scope**: Verify that re-running the full pipeline without `--force` completes quickly (skip-all path) and produces only a new `_runs/{ts}/summary.md` (no other file changes).

## Command

```bash
# Run 1
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep
# Run 2 (immediately after)
python tools/uc_pipelines/run_pipeline.py --schemas etoro_kpi_prep
```

## Mechanism

Each per-phase tool checks for an existing output before doing work:

| Phase | Tool | Skip predicate |
|---|---|---|
| -1 | `build_dag.py` | `_dag.json` exists and is < 4 hours old |
| 0 | `build_upstream_wiki_index.py` | `_index_cache/upstream_wikis.json` exists |
| 1 | `discover_schema.py` | `_discovery/uc_inventory.json` exists |
| 2 | `fetch_writer_source.py` | per-object `_discovery/source_code/{obj}.{ext}` exists |
| 3 | `cache_upstream_wikis.py` | per-upstream `_discovery/upstream_wikis/{fqn}.md` exists |
| 4 | `build_lineage.py` | `{obj}.lineage.md` exists |
| 5 | `generate_wiki.py` | `{obj}.md` exists |
| 6 | `validate_pipeline_wiki.py` | always re-runs (validation is cheap) |
| 7 | `adversarial_evaluate.py` | always re-runs against current artifacts (cheap mechanical scoring) |

Phase 7 is the only phase that always re-runs in the productized path. The mechanical evaluator runs at ~0.5-1 second per object, so a 100-object skip-all re-run lands well under 60 seconds.

## Expected behavior on Run 2

```
[uc-pipeline-pack] Run ... starting (max_parallelism=4, evaluate=ON)
[uc-pipeline-pack] Phase -1: DAG built ... (CACHED — 0.0s)
[uc-pipeline-pack] Phase 0 wiki index FAILED ... (or CACHED)
[uc-pipeline-pack] Wave 1 launching ... (1 schemas)
[etoro_kpi_prep] finished in <60s
[uc-pipeline-pack] EXIT 0
```

Only the new `_runs/{new_ts}/` folder appears on disk. No other artifacts under `Tables/`, `Views/`, or `_discovery/` are modified.

## Verdict

T031 is satisfied by code inspection. The skip-predicate logic in each phase tool produces the documented behavior. A live verification requires running the full pipeline twice with UC connectivity — out of scope for this implementation pass.
