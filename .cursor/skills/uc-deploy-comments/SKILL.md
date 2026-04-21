---
name: uc-deploy-comments
description: Deploy column and table comments/descriptions to Unity Catalog tables and views. Use when deploying ALTER scripts, applying column comments, retrying failed metadata updates, or working with deploy-index tracking. Covers views vs tables, DELTA_METADATA_CHANGED retries, Override table wipes, and all available deployment tools.
---

# UC Deploy Comments

## Available Tools (pick the right one)

| Tool | Path | When to use |
|------|------|-------------|
| `deploy_alter_batch.py` | `tools/deploy_alter_batch.py` | **Batch deploy from `_deploy-index.md`** — the canonical tool for schema-wide deploys. Tracks status, supports `--redo-batch`, writes execution footers. |
| `deploy_ddr_enrichment.py` | `tools/deploy_ddr_enrichment.py` | **One-off deploy of specific alter files** — no deploy-index dependency. Good for targeted re-deploys. |
| `apply_tvf_col_comments.py` | `tools/apply_tvf_col_comments.py` | **TVF views in `etoro_kpi_prep`** — reads wiki §4 Output Columns, applies `COMMENT ON COLUMN`. Canonical for TVF-mapped views. |
| `propagate_upstream_cols.py` | `tools/propagate_upstream_cols.py` | Propagate comments from upstream tables to downstream views/tables. |

## Critical: Views vs Tables

```
TABLE  →  ALTER TABLE main.schema.tbl ALTER COLUMN col COMMENT 'desc';
VIEW   →  COMMENT ON COLUMN main.schema.vw.col IS 'desc';
```

`ALTER TABLE ... ALTER COLUMN ... COMMENT` throws `EXPECT_TABLE_NOT_VIEW` on views. Use `COMMENT ON COLUMN` (ANSI SQL) for views — it works without recreating the view.

Both table and view table-level descriptions use:
```sql
ALTER TABLE main.schema.tbl SET TBLPROPERTIES ('comment' = 'desc');
ALTER VIEW  main.schema.vw  SET TBLPROPERTIES ('comment' = 'desc');
```

## deploy_alter_batch.py Usage

```bash
# Standard batch deploy (next 25 Generated objects)
python tools/deploy_alter_batch.py --schema DWH_dbo --batch-size 25 --deploy-batch 2 -v

# Redo a failed batch
python tools/deploy_alter_batch.py --schema DWH_dbo --redo-batch 5 --deploy-batch 5 -v

# Dry run
python tools/deploy_alter_batch.py --schema BI_DB_dbo --batch-size 50 --dry-run
```

Requires `_deploy-index.md` in the schema folder. Objects must have status `Generated`.

## DELTA_METADATA_CHANGED — Retry Pattern

`DELTA_METADATA_CHANGED` means the daily ETL pipeline is writing to the table concurrently. This is **transient** — not a permissions or schema error.

**Fix**: Wait 5–15 minutes for the ETL to finish, then re-run the same script. The tool is idempotent — already-applied comments are harmlessly rewritten.

**Peak ETL windows** (avoid deploying during these):
- 04:00–08:00 UTC — overnight DDR/dimension refresh
- CIDFirstDates and DDR tables are the heaviest concurrent-write targets

## Override Tables — Daily Metadata Wipes

Tables with `copy_strategy: Override` in `_generic_pipeline_mapping.json` lose ALL column comments daily when the generic pipeline recreates them. ~71 tables are affected (mostly dimensions).

**Identifying Override tables**:
```python
import json
with open("knowledge/synapse/Wiki/_generic_pipeline_mapping.json") as f:
    mapping = json.load(f)
for item in mapping:
    if item.get("copy_strategy") == "Override":
        print(item["uc_table"])
```

**Previously generated list**: `guyman-tr-sandbox/snippets/dwh_wipe_victims.csv`

**Implication**: Deploying comments to Override tables is futile unless:
1. The pipeline is modified to preserve metadata (not yet done)
2. Comments are re-applied after each pipeline run via a post-hook
3. Tags (`SET TAGS`) may survive Override — needs verification

## deploy_ddr_enrichment.py Usage (one-off)

For targeted alter files not tracked by deploy-index:

```bash
python -u tools/deploy_ddr_enrichment.py
```

Edit `ALTER_FILES` list in the script to control which files are deployed. Uses `databricks.sql` connector (OAuth or PAT).

## Performance Rules

1. **Always use `databricks.sql` connector** for bulk deploys — single cursor, synchronous, fast (~1s per statement)
2. **Never use `databricks-sdk` Statement Execution API** for bulk — polling overhead makes it ~60s per statement
3. **Never use MCP** for >10 write calls — opens browser tabs per call
4. **Use `python -u`** and `flush=True` in print statements for real-time progress
5. **Single connection** — never create a new client per statement

## Verifying Deployment

```sql
-- Check comment coverage per table
SELECT table_name,
       COUNT(*) as total_cols,
       COUNT(comment) as commented_cols,
       ROUND(COUNT(comment)*100.0/COUNT(*),1) as pct
FROM main.information_schema.columns
WHERE table_schema = 'bi_db'
  AND table_name LIKE 'gold_sql_dp_prod_we_bi_db_dbo_%'
GROUP BY table_name
ORDER BY pct DESC;
```

## Alter File Format

Standard `.alter.sql` files contain:
```sql
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates SET TBLPROPERTIES ('comment' = 'Table description');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN DateID COMMENT 'Column description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates SET TAGS ('col_name' = 'tier');
```

Execution footer is appended automatically after deploy:
```sql
-- == LAST EXECUTION ==
-- Timestamp: 2026-04-16 08:30:00 UTC
-- Statements: 130/130 succeeded
-- ====================
```
