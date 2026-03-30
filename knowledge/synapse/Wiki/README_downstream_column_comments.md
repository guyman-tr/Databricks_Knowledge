# `_downstream_column_comments.sql` — purpose and safe regeneration

## What it is

`knowledge/synapse/Wiki/_downstream_column_comments.sql` is an **aggregated** script of `ALTER TABLE … ALTER COLUMN … COMMENT '…'` statements for **Unity Catalog objects that do not have their own wiki** (e.g. `main.etoro_kpi.ftd_funnel_v`, `main.bi_output.*`, `main.api_delta.*`). Header claims source: **Synapse DWH wiki `.alter.sql` column comments**.

It is **not** produced by `/generate-alter-dwh` (per-object `*.alter.sql` under `DWH_dbo` / etc.). It is a **separate, bulk** UC comment deployment path.

## How the bad comments happened (e.g. `ftd_funnel_v`)

Symptoms: column **A** shows text that belongs to column **B** (often from `Dim_Customer` / `SP_Dim_Customer` tier text).

**Likely causes** (any one is enough):

1. **Ordinal merge** — Comments were copied from a **single** source `.alter.sql` in **column order** and applied to the **downstream** `DESCRIBE` column list in order. If the view’s column order ≠ source table order, every comment shifts.
2. **Single source for multi-source views** — A view built from joins may need **different** source tables per column; applying **only** `Dim_Customer` comments by name still fails if the mapping is incomplete.
3. **Manual one-off** — A session script not using the same guards as `merge_wiki_column_comments_into_alter.py` / `sql_string_for_comment`.

**Not** primarily “missing escape characters” — wrong text on the wrong column is a **binding** bug (which column owns which string).

## Canonical name-based logic already in repo

`knowledge/synapse/Wiki/_deep_propagate_lib.py` → `match_columns()` matches downstream `DESCRIBE` columns to **`source_descriptions` by column name** (lowercased), not by index. Lineage-driven `generate_downstream_alter_sql()` emits per-object `.downstream.alter.sql`. That path is **safer** than blind aggregation.

The monolithic file was **not** the sole output of that pipeline (only one `*.downstream.alter.sql` exists today).

## Recommended handling

### A. Going forward (preferred for new / rework)

1. Use **lineage +** `_deep_propagate_lib` to build trees and `generate_downstream_alter_sql()` for each **root** documented table, **or**
2. Maintain an explicit **mapping file** and emit SQL with  
   `python tools/emit_downstream_comments_from_mapping.py`  
   (see `--help`). Every row must name **`target_column`** + **`source_alter`** (or **`source_wiki`**) + optional **`source_column`** (defaults to target name).

**Never** fill downstream comments by zipping `source_row[i]` to `target_row[i]` without a **name** join.

### B. One-time repair of existing monolith

1. Identify each UC table that is wrong (e.g. `main.etoro_kpi.ftd_funnel_v`).
2. For each **target column**, decide the **authoritative** source (wiki Elements row or a named column in `SomeTable.alter.sql`).
3. Add entries to `knowledge/synapse/Wiki/_downstream_column_comment_map.json` (start from `_downstream_column_comment_map.example.json`).
4. Run `emit_downstream_comments_from_mapping.py` to emit a **replacement** section or full file; review diff; deploy.

### C. Validation

- **Structural**: `python tools/audit_alter_uc_mapping.py` (targets, bogus `Tier` as column, etc.).
- **Semantic text**: `audit_wiki_alter_comment_parity.py` applies to **wiki + sibling `.alter.sql`**, not this monolith. For downstream-only objects, use the **mapping emitter** + human review until each UC object has a curated mapping.

### D. Full monolith regeneration (name-based, multi-root discover)

To rebuild `_downstream_column_comments.sql` from scratch **without** ordinal zip:

1. **Preferred**: `tools/regenerate_downstream_column_comments.py` — for each wiki root, runs `discover_tree()` → `load_source_descriptions` from that object’s `.alter.sql`, then `match_columns()` (DESCRIBE + **name** match). Multiple roots are **merged** by UC FQN and `target_column`; emit uses `escape_sql_comment_value` (same path as per-table `.downstream.alter.sql`).

   ```text
   python tools/regenerate_downstream_column_comments.py ^
     --config knowledge/synapse/Wiki/regenerate_downstream_sources.json ^
     -o knowledge/synapse/Wiki/_downstream_column_comments.sql
   ```

   Start from `regenerate_downstream_sources.example.json`: add one `sources[]` entry per root table (path to `.alter.sql`, `source_uc` from the alter header, `source_synapse` like `DWH_dbo.Dim_Customer`). Databricks auth required.

2. **Offline merge only**: if you already have `*.lineage-tree.json` files from per-object `discover`, merge without DB:

   ```text
   python tools/regenerate_downstream_column_comments.py --merge-trees path/a.lineage-tree.json path/b.lineage-tree.json -o _merged.sql
   ```

3. **Curated partials / joins**: multi-source views that need **different** upstream tables per column still need `emit_downstream_comments_from_mapping.py` + a JSON map (section B).

### E. Run the existing monolith (no regeneration)

To execute the current `_downstream_column_comments.sql` as-is and **record failures** (continues after each error):

```text
python tools/run_downstream_column_comments_sql.py
```

- **Auth**: set `DATABRICKS_TOKEN` (and optional `DATABRICKS_SERVER_HOSTNAME`, `DATABRICKS_HTTP_PATH`) for non-interactive runs; otherwise OAuth opens a browser.
- **Report**: writes `knowledge/synapse/Wiki/_downstream_column_comments_run_report.md` (counts + each failed statement and error text).
- **Options**: `--sql-file`, `-o` report path, `--limit N` (smoke test), `--dry-run` (parse/count only), `--progress-every N` (default **50**: prints `[done/total] ok=… fail=… elapsed % ~rate/s`; use `0` for quiet except final line), `-v` logs each failure snippet.

## Related

- FR-017 / `batch-orchestration.mdc` — wiki ↔ ALTER parity for documented objects.
- `propagate-downstream-dwh` — future unified command; until then, mapping emitter + deep propagate lib are the supported mechanisms.
