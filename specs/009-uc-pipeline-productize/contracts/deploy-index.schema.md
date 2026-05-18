# Contract: Per-schema `_deploy-index.md`

The deploy index is the operator's single source of truth for what is ready to deploy, what is blocked on what, and what has already shipped. This spec does NOT change the existing format used by `tools/deploy_alter_batch.py`. It DOES formalize the `Blocked (upstream wiki missing: <fqn>)` row class and the per-schema rollup that the productized pack writes.

## File path

`knowledge/UC_generated/{schema}/_deploy-index.md`, one per schema processed in the current run.

## Required structure

```markdown
# Deploy Index — main.{schema}

**Generated**: 2026-05-17
**Pack**: uc-pipeline-doc v{semver}
**Run**: 2026-05-17T19:00:00Z

## Rollup

| Status | Count |
|---|---|
| Pending | 0 |
| Generated | 17 |
| Deployed (Batch 1) | 0 |
| Failed | 0 |
| Blocked | 1 |
| Stub only | 4 |
| **Total** | **22** |

## Objects

| Object FQN | Status | Last action | Notes |
|---|---|---|---|
| main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics | Generated | 2026-05-17 | Passthrough table; 97 columns inherited verbatim. |
| main.de_output.foo_bar | Blocked (upstream wiki missing: main.bronze_db_schema.foo) | 2026-05-17 | Rule 4 missed: no entry in _generic_pipeline_mapping.json. |
| ... | ... | ... | ... |
```

## Field specs

| Header field | Type | Required | Description |
|---|---|---|---|
| Title `# Deploy Index — main.{schema}` | string | yes | Exact prefix. The schema name is the literal UC schema. |
| `**Generated**` | ISO date | yes | YYYY-MM-DD. The day the index was last written. |
| `**Pack**` | string | yes | Identifies which pack authored the index. For this productized pack: `uc-pipeline-doc v{semver}`. |
| `**Run**` | ISO timestamp | yes | UTC ISO8601 timestamp matching the audit-summary directory name. |

## Rollup table

Required exactly as shown — six status rows + `**Total**`. Row order is fixed. Counts MUST equal the count of `Objects` rows with that status. The validator at `tools/uc_pipelines/validate_pipeline_wiki.py` enforces this.

## Objects table

Four columns, in this order:

1. **Object FQN** — UC fully qualified name. MUST match the artifact filename's parent directory + stem.
2. **Status** — one of the six enums:
   - `Pending` — DAG places this object in scope but no artifact files exist yet.
   - `Generated` — `.md`, `.lineage.md`, `.review-needed.md`, AND `.alter.sql` all exist on disk; ALTER has not yet been applied to UC.
   - `Deployed (Batch N)` — `deploy_alter_batch.py` ran successfully for this object in batch N. The literal text is `Deployed (Batch N)` with a single space and parenthesized integer.
   - `Failed (deploy Batch N)` — `deploy_alter_batch.py` returned a UC error for this object. The `Notes` column names the SQL error.
   - `Blocked (upstream wiki missing: <fqn>)` — At least one upstream is `in_scope_not_yet_authored` or `out_of_scope` AND no fallback (Rule 6 placeholder) was acceptable per FR-005. The `<fqn>` names the first such upstream encountered; multiples are noted in `Notes`.
   - `Stub only` — The object is in scope but its lineage is opaque AND its upstreams are out-of-scope. A minimal `.md` exists with structural metadata only; no `.alter.sql`. Used sparingly.
3. **Last action** — ISO date YYYY-MM-DD of the most recent status transition.
4. **Notes** — free text. For `Blocked`: routing-rule attempts. For `Failed`: SQL error. For `Generated`: a one-line summary of the object's documentation character (passthrough vs. derived). For `Stub only`: the reason lineage is opaque.

## Validation rules (mechanically checked by FR-009 validator)

1. Rollup counts equal `Objects` table row counts per status.
2. Every `Generated` row's four artifact files exist on disk.
3. Every `Blocked` row's `Notes` cell contains at least one routing-rule attempt name (e.g., `Rule 4 missed`).
4. `**Total**` row count matches `nodes[].in_pilot_scope=true` count for this schema in the run's `_dag.json`.
5. The schema name in the title matches the parent directory's name.

## Operator contract with `deploy_alter_batch.py`

The existing runner reads this file, ignores rows with status ≠ `Generated`, and emits `Deployed (Batch N)` rows (or `Failed (...)` rows) on completion. Productized pack does NOT change this contract. Specifically:

- The runner does NOT touch `Blocked` rows.
- The runner does NOT touch `Pending` rows.
- The runner does NOT touch `Stub only` rows.
- The runner DOES update `Generated` → `Deployed (Batch N)` on success and `Generated` → `Failed (deploy Batch N)` on UC error.

## Non-goals

- No JSON sibling of `_deploy-index.md`. The Markdown IS the canonical form (operator-readable).
- No automatic re-run trigger when a `Blocked` row's upstream is later authored. Operator re-runs `run_pipeline.py` manually; the pack picks up the new state at the next DAG build.
