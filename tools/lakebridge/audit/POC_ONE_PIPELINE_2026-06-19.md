# POC: One Pipeline Migration Unit (2026-06-19)

## Goal
Run a single end-to-end work unit using the agreed shape:

- **Work unit**: ADF pipeline
- **Definition of done**: QA parity against current gold

## Selected Unit
- **ADF pipeline**: `DWH_Daily_Process_-_Entry_Point`
- **Domain source**: `domains/dwh.md` (vault grounding)

## Checks Performed

### 1) Migration runtime exists in UC
- Catalog inventory for `dwh_daily_process` confirms migration footprint exists:
  - `migration_tables`: 253 managed tables, 1 view
  - `migration_tables`: 129 procedures
  - `qa`: 7 managed QA tables

### 2) Candidate Databricks job mapping signal
- Queried Databricks jobs with name filter `DWH_Daily_Process_-_Entry_Point`.
- Result returned no match in the list call.
- Interpretation for this POC: no one-to-one job naming parity yet for this pipeline key.

### 3) QA parity evidence (required done gate)
Data from `dwh_daily_process.qa`:

- `gold_phase_table_mapping` has 14 mapped tables.
- `gold_phase_comparison` has 13 comparison rows:
  - `Mismatch`: 12
  - `Error`: 1
  - `Pass`: 0

Representative rows include:
- `dwh_daily_process.migration_tables.dim_customer` -> `Mismatch`
- `dwh_daily_process.migration_tables.fact_customeraction` -> `Error`
- `dwh_daily_process.migration_tables.dim_historysplitratio` -> `Mismatch`

## POC Verdict
- **Status**: `NOT_DONE`
- **Reason**: `qa-parity` gate failed (0 pass rows, 12 mismatches, 1 error).

## Why This POC Is Useful
This provides the minimal autonomous loop contract for one pipeline:

1. Resolve pipeline identity from domain graph.
2. Verify migrated runtime objects exist in UC.
3. Check run/registration signal for mapped Databricks job.
4. Enforce hard gate on parity table (`qa.gold_phase_comparison`).
5. Emit deterministic unit status (`DONE` or `NOT_DONE` + reason).

## Next Automation Step
Generalize this exact sequence into `run_one_pipeline(pipeline_name)` and drive it from a queue of ADF pipelines, starting with DWH top-level orchestrators.

