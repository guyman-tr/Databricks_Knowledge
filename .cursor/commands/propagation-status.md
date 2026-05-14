---
description: Generate the enriched UC column-comment propagation status CSV. Pulls every UC object + comment counts and tags each row with an exclusion reason (out-of-scope schema, name-pattern pruned, wiki-failure, propagation-failure, etc.) so an Excel pivot can show the true % of propagation.
---

# Propagation Status — Enriched UC Coverage CSV

Pulls the live UC inventory and joins it with our wiki / deploy / propagation
artifacts to produce a single CSV that the user pivots in Excel to see the
"true %" of column-comment propagation.

The output **brings everything** — every UC object, no rows dropped. Each
row carries an `excluded` boolean and a single `exclude_reason` so the pivot
can slice it any way.

---

## Invocation

```text
/propagation-status
```

There are no arguments. The agent runs:

```bash
python tools/propagation_status.py
```

This:

1. Re-queries `system.information_schema` for every UC object + column counts (one OAuth tab — same auth as `databricks_sql` MCP).
2. Reads every `_deploy-index.md`, `*.alter.sql`, wiki `.md`, and `*.propagation-progress.json` under `knowledge/synapse/Wiki/`.
3. Pulls the explicit object blacklist + name-pattern blacklist from `.specify/Configs/dwh-semantic-doc-config.json`.
4. Applies the prioritized exclusion cascade below to each UC row.
5. Writes `knowledge/uc_propagation_status.csv` and prints a summary breakdown to stderr.

To skip the UC re-fetch (re-classify against the last cached inventory):

```bash
python tools/propagation_status.py --no-fetch
```

To write to a different path:

```bash
python tools/propagation_status.py --out my_path.csv
```

---

## Output Columns

| Column | Meaning |
|---|---|
| `catalog_name`, `schema_name`, `object_name` | UC FQN parts |
| `object_type` | `MANAGED`, `EXTERNAL`, `VIEW`, `FOREIGN`, `METRIC_VIEW`, … |
| `total_columns` | Column count from `information_schema.columns` |
| `columns_with_comments` | Columns whose `comment IS NOT NULL` and non-empty |
| `pct_with_comments` | Integer percent (rounded) |
| `synapse_schema`, `synapse_table` | Parsed from `gold_sql_dp_prod_we_*` UC names — links the row back to its Synapse wiki origin |
| `wiki_authored` | `true` if a `.md` file exists under `knowledge/synapse/Wiki/{schema}/(Tables|Views|Functions)/` |
| `deploy_status` | From `_deploy-index.md`: `Deployed`, `Failed`, `Stub only`, `Generated`, `Pending`, or empty |
| `propagation_run` | `true` if this UC FQN appears in any `*.propagation-progress.json` batch |
| `propagation_failed_stmts` | Count of failed statements targeting this object during downstream propagation |
| `excluded` | `true` if `exclude_reason` is non-empty |
| `exclude_reason` | Single most-specific reason (cascade — first match wins) |
| `exclude_category` | High-level bucket for the pivot |

---

## Exclusion Reason Cascade (priority order — first match wins)

| Priority | `exclude_reason` | `exclude_category` | Detection |
|---|---|---|---|
| 1 | `system_internal` | `system` | Catalog starts with `__databricks_internal` or `system`, or schema = `information_schema` |
| 2 | `_stg_schema` | `out_of_scope_schema` | Schema name ends with `_stg` |
| 3 | `api_unowned_schema` | `out_of_scope_schema` | Schema in `api_delta`, `api_general` (we have SELECT, not MODIFY) |
| 4 | `migration_artifact_schema` | `out_of_scope_schema` | Schema starts with `de_output_synapse_migration` |
| 5 | `foreign_federation_table` | `out_of_scope_type` | `object_type = 'FOREIGN'` (Lakehouse Federation; we cannot ALTER) |
| 6 | `name_pattern_pruned_date` | `pruned_pattern` | Name ends with `_YYYYMMDD` or `_YYYY_MM_DD` (8-digit only — 6-digit was too noisy) |
| 7 | `name_pattern_pruned_keyword` | `pruned_pattern` | Name contains `backup`, `bak`, `bck`, `snapshot`, `tmp`, `temp`, `test`, `archive`, `hold`, `junk`, `copy`, `legacy`, `deprecated`, `old`, `obsolete`, `deleted`, `stale`, `scratch`, `debug`, `dev`, `sandbox`, `wip`, or ends `_v\d+`; OR matches a config `name_patterns` glob |
| 8 | `name_pattern_pruned_dev_prefix` | `pruned_pattern` | Name starts with `ofir_`, `guyman_`, `tmp_`, `temp_`, `test_`, … |
| 9 | `name_pattern_pruned_external` | `pruned_pattern` | Synapse `External_*` pattern (handled by the bronze-leg pipeline) |
| 10 | `wiki_explicit_blacklist` | `blacklisted` | Synapse object listed in `dwh-semantic-doc-config.json → object_blacklist.explicit_blacklist` AND not yet `Deployed`/`Generated` |
| 11 | `empty_object` | `no_columns` | `total_columns = 0` |
| 12 | `wiki_deploy_failed` | `wiki_failure` | `_deploy-index.md` row says `Failed` |
| 13 | `wiki_stub_only` | `stub_no_uc_target` | `_deploy-index.md` says `Stub only` (no UC target — comment-only ALTER) |
| 14 | `propagation_failed` | `propagation_failure` | Has `*.propagation-progress.json` errors targeting this object (e.g., `PERMISSION_DENIED` on api_*) |
| 15 | `wiki_not_attempted_in_scope` | `wiki_pending_backlog` | UC name is `gold_sql_dp_prod_we_*` in a framework schema, but no wiki authored AND no propagation-run AND no deploy-index entry |
| 16 | `out_of_scope_schema` | `out_of_scope_schema` | Catalog/schema is not in our framework adjacency set |
| (none) | `` | `` | **In scope** — what your pivot's "true %" measures |

---

## "Deploy Overrides Blacklist" Rule

If an object's `deploy_status` is `Deployed` or `Generated`, the cascade
**does not** apply blacklist or name-pattern exclusion to it. We explicitly
chose to author / deploy it; the row reflects real coverage. Examples in
practice today:

- `BI_DB_DDR_Daily_Aggregated` is in `explicit_blacklist` (deferred, 137 cols)
  but we deployed it in wave-2 → **excluded = false**.

---

## Excel Pivot Recipes

**True % of column-comment propagation**

```
Filter:  excluded = false
Measure: SUMX(columns_with_comments) / SUMX(total_columns)
```

or, the per-object version:

```
Filter:  excluded = false
Measure: COUNTIFS(pct_with_comments = 100) / COUNT()
```

**What's left to do, by category**

```
Pivot rows: exclude_category, exclude_reason
Pivot val : COUNT(object_name)
```

**Where downstream propagation broke**

```
Filter:  exclude_reason = 'propagation_failed'
       OR (excluded = false AND propagation_failed_stmts > 0)
```

---

## Files Touched

| File | Role |
|---|---|
| `tools/propagation_status.py` | Engine — does all the heavy lifting |
| `knowledge/uc_propagation_status.csv` | The CSV the user opens in Excel |
| `knowledge/.uc_propagation_status_raw.csv` | Cache of last UC pull (for `--no-fetch` re-classify) |

---

## When To Re-run

- After any new wave of `/deploy-alter-dwh` (deploy_status changes).
- After any new `/propagate-downstream-dwh` execution (propagation-progress changes).
- After adding/removing entries in `dwh-semantic-doc-config.json`.
- Any time the user wants a fresh "true %" snapshot.

UC inventory is queried fresh on every default invocation. Use `--no-fetch`
only if you've just run it and want to re-classify after editing the cascade
or config without paying the OAuth round-trip.
