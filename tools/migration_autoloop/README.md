# Databricks Migration Autoloop (Foundation)

This module implements the phase-1 migration loop where the work unit is an
ADF pipeline and completion is gated by QA parity vs gold outputs.

## Orchestration Contract (Backward + Forward)

All Databricks job creators under `tools/migration_autoloop/create_or_update_*.py`
now use the shared orchestration helper:

- `tools/migration_autoloop/orchestration.py`
- core API: `create_or_update_sql_job(...)`
- task spec model: `SqlTaskSpec`

This means:

- Existing ("backward") jobs are wired through the same DAG/task uploader + reset flow.
- New ("forward") flows must use the same helper, so preflight/guard/core/qa patterns
  stay consistent and auditable.
- No more per-script custom job-create logic drift.

## Status Model

Registry states are:

- `pending`
- `processing`
- `blocked`
- `qa_failed`
- `done`

Registry file (CSV): `tools/migration_autoloop/runtime/pipeline_registry.csv`

## Loop Stages

1. Seed/refresh registry from ADF pipeline seed list.
2. Detect pipelines where `status != done` (respect retry budget).
3. Execute one pipeline worker:
   - optional deploy hook (`transpile/build/deploy`)
   - optional run hook (`Databricks run/invoke`)
   - QA parity compare from `dwh_daily_process.qa.gold_phase_comparison`
4. Atomically update registry row with run metadata and evidence path.
5. Escalate into inbox after retry budget is exhausted.

## Files

- `seed_registry.py`: creates/updates canonical registry from `seeds/adf_pipelines.csv`
- `select_candidate.py`: watch-only selector; prefers explicit ADF->workspace->job mapping
- `detect_pending.py`: emits `runtime/work_manifest.csv`
- `run_worker.py`: executes one pipeline and updates status + evidence
- `run_cycle.py`: unattended wrapper for one full cycle with safety budgets
- `memory_bank.py`: recurring issue classifier + CSV incident logger
- `seeds/adf_pipelines.csv`: initial inventory
- `seeds/pipeline_job_map.csv`: explicit mapping (`pipeline_name,workspace_host,job_id`)
- `seeds/pipeline_table_map.csv`: optional pipeline -> UC table scope for QA checks

## Commands

Seed registry:

```bash
python tools/migration_autoloop/seed_registry.py
```

Detect pending:

```bash
python tools/migration_autoloop/detect_pending.py --limit 10 --max-retry 3
```

Watch-only candidate selection (cautious mode, explicit mapping first):

```bash
python tools/migration_autoloop/select_candidate.py
```

Optional fallback to heuristic name matching:

```bash
python tools/migration_autoloop/select_candidate.py --allow-heuristic
```

Run one worker:

```bash
python tools/migration_autoloop/run_worker.py \
  --pipeline-name DWH_Daily_Process_-_Entry_Point
```

Run unattended one-cycle wrapper:

```bash
python tools/migration_autoloop/run_cycle.py --limit 3 --max-failures 2
```

With deploy/run shell hooks:

```bash
python tools/migration_autoloop/run_cycle.py \
  --deploy-hook "python tools/lakebridge/deploy_v3.py --only-name-contains {pipeline_name} --resume" \
  --run-hook "python tools/lakebridge/run_pipeline.py --pipeline {pipeline_name}"
```

## Evidence and Escalations

- Evidence JSON: `tools/migration_autoloop/runtime/evidence/*.json`
- Escalation inbox: `tools/migration_autoloop/runtime/inbox/*.md`
- Incident memory bank CSV: `tools/migration_autoloop/runtime/memory_bank.csv`
- Model-only cost ledger CSV: `tools/migration_autoloop/runtime/model_cost_ledger.csv`

Escalation is triggered when `retry_count >= max_retry` while status is
`blocked` or `qa_failed`.

## Memory Bank

`run_worker.py` appends one row per run to `runtime/memory_bank.csv` with:

- normalized `issue_key` for recurring signature tracking
- short `error_excerpt`
- `root_cause` + `recommended_fix`
- QA counters and evidence pointer

This is intended as a growing DE runbook for repetitive migration failures across
many pipelines.

## Model Cost Ledger (Cursor + API only)

Use this to track model spend only (excluding Databricks compute/runtime).

```bash
python tools/migration_autoloop/runtime/log_model_cost_event.py \
  --flow-id fact_snapshotcustomer \
  --status success \
  --run-id 595990055452661 \
  --low 12 --mid 16 --high 22 \
  --notes "end-to-end DAG + patch iterations" \
  --evidence-path tools/migration_autoloop/out/fact_snapshotcustomer_trust_report_2026-06-19.json
```

