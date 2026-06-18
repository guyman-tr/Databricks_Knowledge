---
name: uc-external-table-naming
description: Enforce Unity Catalog external table naming so assets are not dropped by the Corrupted tables maintenance purge job. Use when creating, renaming, validating, or reviewing external tables and storage locations.
---

# UC External Table Naming (Anti-Purge)

## Why this exists

A maintenance workflow drops external tables multiple times daily when they do
not follow location-derived naming rules, are in the wrong schema/environment,
or fail accessibility checks. This skill is the hard guardrail for table
creation and review.

## Naming formula (authoritative)

For an external table location:

`abfss://<container>@<storage_account>.dfs.core.windows.net/<seg0>/<seg1>/.../<segN>/`

Derive the required table name:

```python
parts = location.split("/")
start_index = 4 if "external-sources" in location else 3
segments = parts[start_index:-1] if location.endswith("/") else parts[start_index:]
table_name = "_".join(segments).lower().replace("-", "_").replace(".", "_")
```

### Example

```text
Location:
abfss://internal-sources@dldataplatformprodwe.dfs.core.windows.net/Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_DDR_Fact_AUM/

Required table name:
gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
```

## Drop triggers (any one causes deletion)

1. Table name differs from the computed formula output.
2. Environment mismatch:
   - prod storage `dldataplatformprodwe` in `_stg` schema
   - staging storage `stgdpdlwe` in non-`_stg` schema
3. Table is in `default` schema.
4. `SELECT * FROM <table> LIMIT 1` fails.
5. Location is not `abfss://...`.

## Excluded schemas (purger skips these)

- `information_schema`
- `etoro_labs`
- `ai_artifacts`
- `ai_artifacts_stg`
- `pii_data`
- `pii_data_stg`
- `etoro_kpi`

## Safe creation checklist

When asked to create an external table:

1. Pick a non-`default`, non-excluded schema.
2. Select storage account by schema suffix:
   - `_stg` schema -> `stgdpdlwe`
   - non-`_stg` schema -> `dldataplatformprodwe`
3. Choose/verify the `LOCATION` path so the formula yields the exact table name.
4. Create as external Delta:

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS <catalog>.<schema>.<table_name>
USING DELTA
LOCATION 'abfss://<container>@<correct_storage>.dfs.core.windows.net/<path>/';
```

5. Validate before declaring done:
   - recompute expected name from `LOCATION`
   - compare to table name exactly
   - run `SELECT * ... LIMIT 1`

## Non-standard names

If a table must keep a non-standard name, add `<schema>.<table_name>` to
`excluded_tables` in the Corrupted tables maintenance notebook.

## Required behavior when this skill is loaded

- Never create managed tables for assets covered by this rule.
- Never create or move these assets into `default`.
- Always show or mention the computed expected name in your response.
- If naming cannot be made compliant, stop and ask whether to whitelist.
