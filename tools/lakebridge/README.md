# Lakebridge / BladeBridge custom configuration — eToro

This folder holds the eToro-specific [BladeBridge](https://databrickslabs.github.io/lakebridge/docs/transpile/pluggable_transpilers/bladebridge/bladebridge_configuration/) configuration used by the [Databricks Labs Lakebridge](https://databrickslabs.github.io/lakebridge/) transpiler when converting Synapse SQL into Databricks SQL.

## Why we need a custom config

By default BladeBridge will:

- emit `CREATE TABLE <schema>.<name>` using the **source** Synapse schema names (`BI_DB_dbo.`, `DWH_dbo.`, etc.), which may collide with existing UC schemas
- in some cases emit a `LOCATION '...'` clause that points at an **existing** Azure data‑lake path (e.g. `abfss://internal-sources@.../Gold/sql_dp_prod_we/DWH_dbo/Fact_CustomerAction`)

The second case is the dangerous one — running the generated DDL on Databricks would register a new managed/external table on top of a path that's already owned by another production gold mirror, silently corrupting the existing table.

The config in `etoro_synapse2databricks.json` defends against both:

1. **Schema redirect** – every `<synapse_schema>.` reference is rewritten to `de_output_synapse_migration.`, so all generated tables live in **`main.de_output_synapse_migration`** — a quarantine schema that contains nothing else.
2. **Catalog/schema header** – `target_sql_file_header` prepends `USE CATALOG main; USE SCHEMA de_output_synapse_migration;` to every output file.
3. **`LOCATION` strip** – any `LOCATION 'abfss://…'` / `dbfs:` / `s3:` / `wasb:` clauses are removed.
4. **External → managed** – `CREATE EXTERNAL TABLE` is rewritten to `CREATE TABLE`, so the generated tables are UC‑managed and live under the schema's default location.

Net effect: no transpiled object can ever land outside `main.de_output_synapse_migration`, and none can ever bind to an existing lake path.

## Files

| File | Purpose |
| --- | --- |
| `etoro_synapse2databricks.json` | The custom BladeBridge config (inherits from `base_synapse2databricks_sql.json`). |
| `README.md` | This file. |

The reference documentation for every supported attribute lives at `knowledge/lakebridge/bladebridge-configuration.md` (a clean ingest of the Lakebridge docs page).

## Pre‑reqs

- **Lakebridge installed** for the active Databricks profile:
  ```powershell
  databricks labs install lakebridge --profile name-of-profile
  ```
- **Target schema exists** in Unity Catalog. Run once:
  ```sql
  CREATE SCHEMA IF NOT EXISTS main.de_output_synapse_migration
    COMMENT 'Quarantine schema for Synapse->Databricks transpiler output. Owned by Lakebridge migration; do not put production data here.';
  ```
- **Inherit path is correct.** The JSON's `inherit_from` points at:
  ```
  C:/Users/guyman/.databricks/labs/remorph-transpilers/bladebridge/lib/.venv/lib/python3.10/site-packages/databricks/labs/bladebridge/Converter/Configs/base_synapse2databricks_sql.json
  ```
  Adjust the `python3.10` segment if your venv differs (e.g. `python3.11`).

## How to register the config

```powershell
databricks labs lakebridge install-transpile --profile name-of-profile
# Do you want to override the existing installation? (default: no): yes
# Specify the config file to override the default[Bladebridge] config - press <enter> for none (default: <none>):
C:/Users/guyman/Documents/github/Databricks_Knowledge/tools/lakebridge/etoro_synapse2databricks.json
```

After this, every `databricks labs lakebridge transpile …` invocation will use this config.

## How to verify it's actually applied

After running a transpile, every generated `.sql` file should:

1. Begin with the catalog/schema preamble:
   ```sql
   USE CATALOG main;
   USE SCHEMA de_output_synapse_migration;
   ```
2. Contain **zero** references to the source Synapse schemas (`BI_DB_dbo.`, `DWH_dbo.`, `Dealing_dbo.`, etc.).
3. Contain **zero** `LOCATION '…'` clauses pointing at `abfss://`, `dbfs:`, `s3:`, or `wasb:` paths.
4. Have all `CREATE TABLE` statements that reference unqualified table names (which then resolve under `de_output_synapse_migration`).

Quick `rg` checks from the transpile output dir:

```powershell
rg -n "BI_DB_dbo|DWH_dbo|Dealing_dbo|EXW_dbo" .   # should return nothing
rg -n "LOCATION\s+'(abfss|dbfs|s3|wasb)" .         # should return nothing
rg -n "CREATE\s+EXTERNAL\s+TABLE" .                # should return nothing
rg -n "USE CATALOG main" .                         # should appear at top of every file
```

## How to extend

### Adding a new Synapse schema

If you find a Synapse schema not yet in the list (re‑run the enumeration query in the file's `//_order` comments), add a new line in the `line_subst` array, **above** the catch‑all rules and **above** any partial‑name overlaps:

```jsonc
{ "from": "\\bMyNewSchema\\b\\.", "to": "de_output_synapse_migration." }
```

> Order matters: BladeBridge applies `line_subst` rules in array order, and longer/more‑specific patterns must come first. `BI_DB_staging` must precede `BI_DB_dbo`; both must precede a generic `\\bdbo\\b\\.` rule.

### Routing a specific schema to a different UC schema

If you decide that some objects should land in a different target schema (e.g. dimension tables in `main.dim_migration`), add explicit rules with that specific target before the generic ones. First match wins on rules with `"first_match": "1"`; otherwise BladeBridge applies all matching `line_subst` rules in order, so the **last** rule that matches a given segment is the one whose substitution sticks. Use `first_match` to be defensive:

```jsonc
{ "from": "\\bDWH_dbo\\.Dim_", "to": "main.dim_migration.Dim_", "first_match": "1" }
```

### Catching procedure / view bodies that reference unqualified objects

Some Synapse SPs reference tables without a schema (e.g. `SELECT * FROM Fact_CustomerAction`). Those are not caught by the schema‑prefix rules. Either:

- pre‑qualify them in source before transpiling, or
- add per‑object rewrites in the `line_subst` array (less scalable).

## Source documentation

Mirror of the upstream BladeBridge config docs (clean ingest):
[`knowledge/lakebridge/bladebridge-configuration.md`](../../knowledge/lakebridge/bladebridge-configuration.md)

Original URL: <https://databrickslabs.github.io/lakebridge/docs/transpile/pluggable_transpilers/bladebridge/bladebridge_configuration/>
