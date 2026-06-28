# skill_suggestions tools

Utilities for the autonomous skills-automation user submission flow.

## Files

- `ddl.sql` — creates external queue table + external volume in `main.de_output`.
- `naming.py` — shared anti-purge naming helpers.
- `validate_external_name.py` — CLI check for naming/storage/schema correctness.
- `db.py` — Databricks SQL execution helper using `databricks-sdk`.
- `scan.py` — scans and claims queue rows (`status='new'` by default) and writes a JSON manifest.
- `update_status.py` — updates queue status and metadata for a row.
- `run_once.py` — one executable processing cycle for manifest items.
- `run_cycle.py` — one-command cycle: `scan.py` then `run_once.py`.
- `agent_runner.py` — Cursor SDK bridge used by live `run_once.py` execution.
- `fixtures/dryrun_manifest.json` — local fixture for reproducible dry-run.

## Typical loop

1. `python tools/skill_suggestions/scan.py --status new --claim`
2. For each manifest item:
   - process request (`new_skill` or `correction`)
   - `python tools/skill_suggestions/update_status.py --id <id> --status <pushed|skipped_overlap|error> --set-processed-now ...`

Or execute one cycle directly:

```powershell
python tools/skill_suggestions/run_once.py --manifest tools/skill_suggestions/work_manifest.json
```

Or do full scan+process in one command:

```powershell
python tools/skill_suggestions/run_cycle.py --status new --claim --execution-mode full
```

Run from an existing manifest without scanning Databricks:

```powershell
python tools/skill_suggestions/run_cycle.py `
  --skip-scan `
  --manifest tools/skill_suggestions/fixtures/dryrun_manifest_ok.json `
  --dry-run `
  --execution-mode ingest_only `
  --no-status-update `
  --no-notify
```

Live mode (`run_once.py` without `--dry-run`) requires Python package:

```powershell
pip install cursor-sdk
```

and valid Cursor SDK auth (typically `CURSOR_API_KEY`).

## Live preflight (automatic)

Before any non-dry-run `execution-mode full`, `run_once.py` enforces:

1. `DataPlatform` repo must be discoverable from `--workspace-cwd`.
2. `DataPlatform` working tree must be clean (`git status --porcelain` empty).
3. Checkout `dev`.
4. `git pull --ff-only origin dev`.

If any step fails, the run exits before ingest/push, with a clear error message.

### Optional auto-stash mode

Use `--auto-stash-dataplatform` to temporarily stash pre-existing DataPlatform
changes, run on clean `dev`, then attempt to restore the stash afterward.

If stash restore conflicts occur, the run exits with a warning in summary and
leaves conflict resolution to manual git workflow.

## Local dry-run test (no DB writes, no webhook calls)

```powershell
python tools/skill_suggestions/run_once.py `
  --manifest tools/skill_suggestions/fixtures/dryrun_manifest.json `
  --dry-run
```

## Required environment

- Databricks auth via `~/.databrickscfg` profile (`DATABRICKS_MCP_PROFILE` or `DEFAULT`)
- SQL warehouse id via either:
  - `DATABRICKS_WAREHOUSE_ID`, or
  - `DATABRICKS_HTTP_PATH` (warehouse id parsed from path)

## Anti-purge safety gate

Before creating/changing queue storage:

```powershell
python tools/skill_suggestions/validate_external_name.py `
  --schema de_output `
  --table-name de_output_skills_automation_user_suggestions_agent `
  --location "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Skills_Automation/User_Suggestions_Agent/"
```

Exit code `0` means safe; non-zero means the purger is likely to drop the table.
