# CLI Contract: `tools/uc_pipelines/run_pipeline.py`

The headless entrypoint for the productized UC documentation pipeline. Designed to be invoked identically from a Cursor agent prompt and from a Claude CLI loop terminal. No interactive prompts during normal-path execution.

## Invocation

```bash
python tools/uc_pipelines/run_pipeline.py [OPTIONS]
```

## Flags

| Flag | Type | Default | Required | Description |
|---|---|---|---|---|
| `--schemas` | comma-separated string | (none) | yes | UC schemas to process. Pilot value: `de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi`. Any schema outside the pilot set fails fast with exit code 4 unless `--allow-non-pilot-schemas` is passed (off by default; not exposed in this spec). |
| `--phases` | comma-separated string of phase numbers | `-1,0,1,2,3,4,5,6` | no | Subset of phases to run. Useful for re-runs after a single phase bug fix. `-1` = DAG build; others as in [data-model.md](../data-model.md). |
| `--force` | flag | `false` | no | Re-run every phase regardless of existing outputs. Without it, the orchestrator skips phases whose canonical output files already exist. |
| `--dry-run` | flag | `false` | no | Run Phase -1 only. Print the DAG summary and exit. No artifacts written for Phases 0-6. |
| `--max-objects-per-schema` | int | unbounded | no | Cap per-schema processing for testing. Pilot runs leave this unbounded. |
| `--max-parallelism` | int | `4` | no | Number of concurrent worker processes for schema-level fan-out (Wave 1). `0` or `1` forces sequential execution. Cannot exceed Wave-1 schema count. |
| `--evaluate` / `--no-evaluate` | flag pair | `--evaluate` (ON) | no | Run the adversarial evaluator (Phase 7) after Phase 6 per object. `--no-evaluate` skips evaluation entirely. Default ON for safety. |
| `--evaluate-sample` | int | unbounded | no | Sample N random objects per schema for adversarial evaluation. Skips eval for the rest. Useful for fast smoke runs; pair with `--evaluate`. |
| `--audit-dir` | path | `knowledge/UC_generated/_runs/{auto-timestamp}` | no | Override the per-run audit directory. Default uses ISO8601 UTC stamp. |
| `--verbose` | flag | `false` | no | Per-row phase output to stdout in addition to the final summary. |

## Required environment

| Variable | Purpose | Source |
|---|---|---|
| `DATABRICKS_TOKEN` | UC SQL auth | Existing `_conn.py` |
| `DATABRICKS_SERVER_HOSTNAME` | UC cluster endpoint | Existing `_conn.py` |
| `DATABRICKS_HTTP_PATH` | UC SQL warehouse HTTP path | Existing `_conn.py` |
| `DATABRICKS_MCP_PROFILE` (optional) | Override default profile | Existing `_conn.py` |

No new env vars introduced by this spec.

## Schema processing waves

The coordinator derives wave assignment from the DAG built in Phase -1. For the pilot universe, the static assignment is:

```text
Wave 1 (parallel, ProcessPoolExecutor max_workers=min(4, --max-parallelism)):
  de_output, bi_output, bi_dealing, etoro_kpi_prep

Wave 2 (sequential, after Wave 1 completes):
  etoro_kpi    (depends on etoro_kpi_prep)
```

A Wave 1 worker failure does NOT abort the other Wave 1 workers. Wave 2 still runs IF its in-scope upstream(s) completed successfully in Wave 1; otherwise the affected Wave 2 schema's objects get `Blocked (upstream wiki failed in same run: <fqn>)` rows in their deploy index.

## Stdout shape (normal path)

```text
[uc-pipeline-pack] Run 2026-05-17T19:00:00Z starting (max_parallelism=4, evaluate=ON)
[uc-pipeline-pack] Phase -1: building DAG... 1248 lineage rows, 280 nodes, 91 in-scope, 22 out-of-scope, 5 layers
[uc-pipeline-pack] Phase 0: upstream wiki cache built (4327 wikis indexed)
[uc-pipeline-pack] Wave 1 launching (4 schemas in parallel):
[de_output] Phase 1: inventory ... OK (22 objects)
[bi_output] Phase 1: inventory ... OK (39 objects)
[bi_dealing] Phase 1: inventory ... OK (8 objects)
[etoro_kpi_prep] Phase 1: inventory ... OK (27 objects)
[de_output] Phase 2: source code ... 21/22 OK, 1 missing
[bi_output] Phase 2: source code ... 36/39 OK, 3 missing
... (interleaved per-schema output) ...
[de_output] Phase 7: adversarial eval ... 17/18 PASS, 1 FAIL (regenerated, second-pass PASS)
[bi_output] Phase 7: adversarial eval ... 26/28 PASS, 2 FAIL (1 regen-PASS, 1 regen-FAIL)
[bi_dealing] Phase 7: adversarial eval ... 6/6 PASS
[etoro_kpi_prep] Phase 7: adversarial eval ... 22/22 PASS
[uc-pipeline-pack] Wave 1 complete in 12m41s. Generated 71, Failed 1, Blocked 4.
[uc-pipeline-pack] Wave 2 launching (etoro_kpi):
[etoro_kpi] Phase 1: inventory ... OK (17 objects)
[etoro_kpi] ... 
[etoro_kpi] Phase 7: adversarial eval ... 13/14 PASS, 1 FAIL (regen-PASS)
[uc-pipeline-pack] Wave 2 complete in 4m31s.
[uc-pipeline-pack] Run complete. Wall-clock: 17m12s. Summary: knowledge/UC_generated/_runs/2026-05-17T19-00-00Z/summary.md
[uc-pipeline-pack] Per-schema: de_output 17/18, bi_output 26/28, bi_dealing 6/6, etoro_kpi_prep 22/22, etoro_kpi 13/14
[uc-pipeline-pack] Adversarial eval: 84/86 first-pass PASS, 2 regen-PASS, 0 regen-FAIL
[uc-pipeline-pack] EXIT 0
```

`--verbose` adds per-object lines like `[de_output][phase 5] generated de_output_etoro_kpi_fact_customeraction_w_metrics.md`.

`--no-evaluate` skips the Phase 7 lines and the final adversarial-eval summary line.

## Exit codes

| Code | Meaning | Trigger |
|---|---|---|
| `0` | Success | Every in-scope object reached either `Generated`, `Blocked`, or explicit `Out-of-scope` state. No phase-level hard errors. Adversarial evaluator did not produce any final-FAIL (after one retry). |
| `1` | Per-object failures present | One or more objects hit a hard error during Phases 0-7. Includes adversarial-eval final-FAIL (FAIL after retry). Run continued; audit summary names them. Operator follow-up required. |
| `2` | Run aborted at DAG build | Phase -1 hit a cycle, an auth failure to `system.access.*`, or a schema misspelling. No artifacts written for Phases 0-7. |
| `3` | Auth failure | `DATABRICKS_TOKEN` / hostname / HTTP-path missing or rejected before Phase -1 could run. |
| `4` | Invalid arguments | Non-pilot schema in `--schemas`, malformed phase list, malformed `--max-parallelism`, etc. |

## Stderr shape

Reserved for hard errors only. Stack traces from Python exceptions captured here. Normal-path runs produce empty stderr.

## Idempotency

Running the same command twice with no `--force` and no intervening UC change produces:

- Identical `_dag.json` (modulo `built_at` timestamp).
- Zero changes to `.md`, `.lineage.md`, `.review-needed.md`, `.alter.sql` files.
- A second audit summary at a fresh `_runs/{ts}/` path. The two summaries' per-schema rollup numbers MUST be identical.

Verifiable by `diff -r --exclude='_runs' --exclude='_dag.json' knowledge/UC_generated knowledge/UC_generated_after_rerun`.

## Parity contract — Cursor vs Claude CLI

The identical command string MUST produce byte-identical artifacts (modulo timestamps) when invoked from:

1. A Cursor agent prompt running `python tools/uc_pipelines/run_pipeline.py --schemas ...`.
2. A bash/PowerShell terminal in a Claude CLI loop running the same command.

No runtime detection. No conditional logic. If the user wants a watch loop in CLI, the wrapper shell script handles the loop; the Python tool is unchanged.

## Non-goals

- No HTTP server. CLI only.
- No streaming JSON-RPC output. Stdout is human-readable.
- No interactive prompts. Anything that would interactively confirm gets a default; `--force` exists for the one ambiguous case (re-run on existing outputs).
