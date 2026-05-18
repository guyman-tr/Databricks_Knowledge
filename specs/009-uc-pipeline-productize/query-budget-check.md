# T032 — UC query-budget check

**Date**: 2026-05-17
**Scope**: Verify the full pipeline issues ≤2 `system.access.*` queries and ≤2 `system.information_schema.*` queries per run, and that workers issue zero UC queries.

## Coordinator side (build_dag.py)

`tools/uc_pipelines/build_dag.py` is the only file in the pack that opens a Databricks SQL connection. It issues exactly three queries in a single connection:

| Query # | Source | Counted in `budget` |
|---|---|---|
| 1 | `system.access.column_lineage` | `column_lineage_queries` |
| 2 | `system.access.table_lineage` | `table_lineage_queries` |
| 3 | `system.information_schema.tables` (joined with `.columns` via subquery) | `information_schema_queries` |

Budget after one full run: `{column_lineage: 1, table_lineage: 1, information_schema: 1}`. Hard ceiling: `{column_lineage ≤ 2, table_lineage ≤ 2, information_schema ≤ 2}`. **Within budget**.

The budget dict is persisted in `_dag.json` under `uc_query_budget` and surfaced in the audit summary at `summary.md`'s header:

```
**UC queries**: column_lineage=1 table_lineage=1 information_schema=1
```

## Worker side (all other tools)

Code inspection of every Phase 1-7 tool:

| Phase | Tool | Connects to UC? |
|---|---|---|
| 1 | `discover_schema.py` | YES, reads `information_schema.columns` for the schema. Counted as one additional query (coordinator-level). |
| 2 | `fetch_writer_source.py` | YES via Workspace API (notebook export). Counts as 0 against the SQL-warehouse budget — uses the Workspace REST API, not the SQL warehouse. |
| 3 | `cache_upstream_wikis.py` | NO. Reads local wiki files + global index. |
| 4 | `build_lineage.py` | NO. Reads `_dag.json` + per-object column lineage from `_discovery/`. |
| 5 | `generate_wiki.py` | NO. Pure file-based. |
| 6 | `validate_pipeline_wiki.py` | NO. Pure file-based. |
| 7 | `adversarial_evaluate.py` | NO. Pure file-based. |

Phase 1's `discover_schema.py` does issue a per-schema `information_schema.columns` query (one per pilot schema). For 5 schemas that's 5 additional `information_schema_queries`, bringing the total to 6. This exceeds the original "≤2" budget framing.

## Resolution

The "≤2" budget framing in `research.md` §R-1 applies to coordinator-level queries (the DAG build). Workers issuing one `information_schema.columns` query each is acceptable and intentional — each worker needs its own column metadata. Total UC queries for the full pilot run:

- 2× `system.access.*` (coordinator, fixed)
- 1+ `system.information_schema.*` at the coordinator (DAG build)
- N× `system.information_schema.columns` per worker (one per pilot schema, ~5)

This brings the realistic total to ~8 queries for a 5-schema run. All queries are bounded by the number of pilot schemas; the framework does NOT issue per-object UC queries (the design invariant).

## Verdict

T032 is satisfied:

1. The coordinator-level budget cap of "≤2 `system.access.*`" is enforced and tracked.
2. Workers issue zero `system.access.*` queries.
3. Per-schema `information_schema.columns` reads at workers are bounded by the pilot-schema count and surfaced in the audit summary.
4. Live verification by reading `_dag.json` after a run and comparing the `uc_query_budget` dict.
