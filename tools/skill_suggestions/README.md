# skill_suggestions tools

Utilities for the autonomous skill-suggestion flow.

## Files

- `ddl.sql` — creates external queue table + external volume in `main.de_output`.
- `naming.py` — shared anti-purge naming helpers.
- `validate_external_name.py` — CLI check for naming/storage/schema correctness.
- `db.py` — Databricks SQL execution helper using `databricks-sdk`.
- `scan.py` — scans and claims queue rows (`status='new'` by default) and writes a JSON manifest.
- `update_status.py` — updates queue status and metadata for a row.

## Typical loop

1. `python tools/skill_suggestions/scan.py --status new --claim`
2. For each manifest item:
   - process request (`new_skill` or `correction`)
   - `python tools/skill_suggestions/update_status.py --id <id> --status <pushed|skipped_overlap|error> --set-processed-now ...`

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
  --table-name skill_suggestions `
  --location "abfss://<container>@dldataplatformprodwe.dfs.core.windows.net/skill_suggestions/"
```

Exit code `0` means safe; non-zero means the purger is likely to drop the table.
