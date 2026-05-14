# Lakebridge / BladeBridge custom configuration — eToro

This folder holds the eToro-specific [BladeBridge](https://databrickslabs.github.io/lakebridge/docs/transpile/pluggable_transpilers/bladebridge/bladebridge_configuration/) configuration used by the [Databricks Labs Lakebridge](https://databrickslabs.github.io/lakebridge/) transpiler when converting Synapse SQL into Databricks SQL.

## Design — dual‑schema, single catalog (v3)

We split the transpiler output across two sibling schemas inside the **`dwh_daily_process`** catalog so the migrated SPs can be tested end‑to‑end against a stable daily snapshot of the source data, without ever writing to production tables or to existing UC gold mirrors.

| Synapse schema | UC destination | Role |
| --- | --- | --- |
| `DWH_staging.<X>` (131 staging tables) | `dwh_daily_process.daily_snapshot.<X>` | **Read‑only snapshot** of the production source data. The data engineering team loads this schema every morning. |
| Everything else (`DWH_dbo`, `BI_DB_dbo`, `Dealing_dbo`, `EXW_dbo`, etc.) | `dwh_daily_process.migration_tables.<X>` | **Write target.** Every transpiled SP creates / writes its output here. Quarantined from real production. |

Net effect: any SP we deploy will *read* from the morning's snapshot and *write* into the migration schema, so you can run the entire DWH daily pipeline in parallel with production and diff the outputs.

### History

- **v1 (2026-04-29):** single quarantine schema `main.de_output_synapse_migration` (no read/write split, no snapshot). Only `sp_dim_customer` was deployed against this.
- **v2 (2026-05-11):** dual‑catalog plan — `dwh_daily_process.daily_snapshot` (read) + `migration_output.migration_tables` (write). Plan only; `migration_output` catalog was never created.
- **v3 (2026-05-11):** collapsed to one catalog — both `daily_snapshot` and `migration_tables` live under `dwh_daily_process`. This is what's actually in UC.

The `main.de_output_synapse_migration.sp_dim_customer` from v1 should be dropped during the v3 cutover; it reads/writes from the wrong schemas.

## Files

| File | Purpose |
| --- | --- |
| `etoro_synapse2databricks.json` | The custom BladeBridge config (inherits from `base_synapse2databricks_sql.json`). Apply this when running `databricks labs lakebridge install-transpile` so future transpile runs are already routed correctly. |
| `rewrite_to_dual_target.py` | Post‑hoc rewriter. Walks an existing transpile output dir and applies the same mappings as the JSON config. Use when you don't want to regenerate from scratch. |
| `README.md` | This file. |

The reference documentation for every supported BladeBridge attribute lives at [`knowledge/lakebridge/bladebridge-configuration.md`](../../knowledge/lakebridge/bladebridge-configuration.md).

## Unity Catalog prerequisites

Run once per environment:

```sql
CREATE CATALOG IF NOT EXISTS dwh_daily_process;
CREATE SCHEMA  IF NOT EXISTS dwh_daily_process.daily_snapshot
  COMMENT 'Daily morning snapshot of Synapse DWH_staging tables. Read-only for the migration pipeline.';
CREATE SCHEMA  IF NOT EXISTS dwh_daily_process.migration_tables
  COMMENT 'Write target for the Lakebridge Synapse->Databricks migration. Mirrors DWH_dbo and friends. Quarantined from production.';
```

> As of 2026‑05‑11 both `dwh_daily_process.daily_snapshot` (131 external tables loaded) and `dwh_daily_process.migration_tables` (empty) exist in UC. Ready to receive the rewritten objects.

## Path A — apply to **future** Lakebridge transpile runs (preferred)

1. Lakebridge already installed for the active Databricks profile:
   ```powershell
   databricks labs install lakebridge --profile name-of-profile
   ```
2. Register this config so subsequent `transpile` calls use it:
   ```powershell
   databricks labs lakebridge install-transpile --profile name-of-profile
   # Do you want to override the existing installation? (default: no): yes
   # Specify the config file to override the default[Bladebridge] config - press <enter> for none (default: <none>):
   C:/Users/guyman/Documents/github/Databricks_Knowledge/tools/lakebridge/etoro_synapse2databricks.json
   ```
3. Re‑run `databricks labs lakebridge transpile …`. Generated files will already use the dual‑target routing.

> **Inherit path:** the JSON's `inherit_from` is hard‑coded to the Python 3.10 venv path. If your current Lakebridge install uses Python 3.11+, edit that one line in the JSON.

## Path B — rewrite an **existing** transpile output without re‑running Lakebridge

Use the post‑processor:

```powershell
python tools\lakebridge\rewrite_to_dual_target.py `
  --src "C:\Users\guyman\Desktop\lakebridge_transplier" `
  --dst "C:\Users\guyman\Desktop\lakebridge_transplier_v3" `
  --clean
```

Options:

- `--src` — source directory (the raw transpile output). Default: `C:\Users\guyman\Desktop\lakebridge_transplier`.
- `--dst` — destination directory (mirrored tree, originals never modified). Default: `C:\Users\guyman\Desktop\lakebridge_transplier_v3`.
- `--clean` — wipe `--dst` before writing (safe; only re‑runnable mode).
- `--limit N` — process only the first N files (sorted). Handy for spot checks.
- `--only-name-contains S` — only process files whose name contains `S` (case‑insensitive).
- `--dry-run` — count what *would* change without writing.

After the run a CSV report `rewrite_report.csv` is written into `--dst` with per‑file counts of `snapshot_hits` / `output_hits` / `ignored_dot_refs`.

### What the rewriter handles

- All four reference styles BladeBridge emits:
  - `` `DWH_dbo`.`Foo` ``, `` `DWH_dbo`.Foo ``, `` DWH_dbo.`Foo` ``, `DWH_dbo.Foo`
- Procedure and view declarations (`CREATE OR REPLACE PROCEDURE \`DWH_dbo\`.\`SP_x\``).
- Function calls (`BI_DB_dbo.Function_Revenue_Total(...)`).
- `INSERT INTO`, `MERGE INTO`, `TRUNCATE TABLE`, `FROM … JOIN`, etc.

### What it deliberately does **not** touch

- Column aliases like `a.CountryID`, `b.RegulationID`. Schemas like `a`, `b`, `t` are not in the allow‑list, so these stay as is.
- Comments referencing source schema names (left for traceability).
- Dynamic SQL strings that embed backticked schema names inside single quotes (rare; review individually if any SP relies on them).

## How to verify

```powershell
$v3 = "C:\Users\guyman\Desktop\lakebridge_transplier_v3"
# (1) No source-schema references should remain (outside comments):
Select-String -Path "$v3\*\*.sql" -Pattern '(?i)(?<![A-Za-z_])(DWH_staging|DWH_dbo|BI_DB_dbo|DE_dbo|DWH_pagetracking)\b\s*\.\s*\w+' -List
# (2) Header should be present on every file:
Get-ChildItem $v3 -Filter *.sql -Recurse | ForEach-Object {
  $h = Get-Content $_.FullName -TotalCount 2
  if ($h[0] -notmatch 'USE CATALOG dwh_daily_process' -or $h[1] -notmatch 'USE SCHEMA migration_tables') {
    "MISSING HEADER: $($_.FullName)"
  }
}
# (3) Snapshot reads + migration writes should target the right schemas:
Select-String -Path "$v3\*\*.sql" -Pattern 'dwh_daily_process\.daily_snapshot\.'    | Measure-Object
Select-String -Path "$v3\*\*.sql" -Pattern 'dwh_daily_process\.migration_tables\.'  | Measure-Object
```

Last full v3 run on 2026‑05‑11:

- 528 files processed
- 401 snapshot rewrites (DWH_staging → dwh_daily_process.daily_snapshot)
- 3,202 output rewrites (DWH_dbo / BI_DB_dbo / DE_dbo / DWH_pagetracking → dwh_daily_process.migration_tables)
- 11,026 dot references intentionally ignored (column aliases etc.)
- 13 residual `DWH_dbo.[Foo]` references — all inside `--` SQL comments. 0 functional leakage.

## How to extend

### Routing a new Synapse schema

Add a `line_subst` entry in `etoro_synapse2databricks.json` **above** any partial‑name overlaps (longer first), and add the lowercased name to `OUTPUT_SCHEMAS` (or `SNAPSHOT_SCHEMAS`) in `rewrite_to_dual_target.py`. Both layers must agree.

### Pointing a specific table at a different schema

Add an explicit rule with `first_match` in the JSON, before the generic schema rules:

```jsonc
{ "from": "\\bDWH_dbo\\.Dim_", "to": "main.dim_migration.Dim_", "first_match": "1" }
```

For the post‑processor you'd hardcode the override in `rewrite_match()`.

## Source documentation

Mirror of the upstream BladeBridge config docs (clean ingest): [`knowledge/lakebridge/bladebridge-configuration.md`](../../knowledge/lakebridge/bladebridge-configuration.md)

Original URL: <https://databrickslabs.github.io/lakebridge/docs/transpile/pluggable_transpilers/bladebridge/bladebridge_configuration/>
