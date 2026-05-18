# Quickstart: UC-Pipeline Productized Run

5-minute operator walkthrough for running the productized `uc-pipeline-doc` pack across the 5 pilot schemas.

## Prerequisites

1. Active Databricks profile with read access to `system.access.column_lineage`, `system.access.table_lineage`, and `system.information_schema.*`. Write access NOT required at this stage (writes happen later via `deploy_alter_batch.py`).
2. Env vars set: `DATABRICKS_TOKEN`, `DATABRICKS_SERVER_HOSTNAME`, `DATABRICKS_HTTP_PATH`. The repo's existing `_conn.py` resolves these.
3. Python 3.11 environment with `requirements.txt` installed.
4. Branch `009-uc-pipeline-productize` checked out.

## Run

```bash
python tools/uc_pipelines/run_pipeline.py \
  --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi
```

Expected wall-clock: ~45-60 minutes for the full pilot universe of ~80-150 objects.

Expected final lines on stdout:

```text
[uc-pipeline-pack] Run complete. Wall-clock: 47m12s. Summary: knowledge/UC_generated/_runs/2026-05-17T19-00-00Z/summary.md
[uc-pipeline-pack] Per-schema: de_output 17/18, bi_output 28/31, bi_dealing 6/6, etoro_kpi_prep 22/22, etoro_kpi 13/14
[uc-pipeline-pack] EXIT 0
```

## Review the audit summary

Open the run summary:

```bash
code knowledge/UC_generated/_runs/<timestamp>/summary.md
```

Check four things:

1. **Per-schema rollup**: confirm `Generated` count matches expected. If `Failed` or `Blocked` > 0, scroll down.
2. **Blocked-by-upstream table**: tells you which upstream wikis are missing and how many downstream objects each is blocking. Highest-impact upstreams are your follow-up backlog.
3. **Phase time breakdown**: shows where wall-clock went. Phase 4 (column lineage) typically dominates.
4. **Errors section**: any per-object hard failures get one bullet here with object name + phase + cause.

## Spot-check a wiki

Pick any `Generated` object and validate:

```bash
python tools/uc_pipelines/validate_pipeline_wiki.py \
  --wiki knowledge/UC_generated/de_output/Tables/de_output_etoro_kpi_fact_customeraction_w_metrics.md \
  --assert-no-inference
```

Expected: exit 0, no warnings. If `--assert-no-inference` fails on a column, the producer drifted — file an issue and re-run with `--force` for that object after fixing the source-code-narration logic.

## Deploy

For each schema with `Generated` rows:

```bash
python tools/deploy_alter_batch.py \
  --deploy-index knowledge/UC_generated/de_output/_deploy-index.md \
  --schema de_output \
  --batch-size 5 \
  --deploy-batch 1
```

Repeat with `--deploy-batch 2`, `--deploy-batch 3`, ... until all `Generated` rows transition to `Deployed (Batch N)`.

`tools/deploy_alter_batch.py` is the SAME runner used by `dwh-semantic-doc`. No productization-specific flags needed.

## Re-run after a fix

If you find an issue in one object's wiki and want to regenerate just that object:

```bash
rm knowledge/UC_generated/<schema>/<Tables|Views>/<object>.md
rm knowledge/UC_generated/<schema>/<Tables|Views>/<object>.lineage.md
rm knowledge/UC_generated/<schema>/<Tables|Views>/<object>.review-needed.md
rm knowledge/UC_generated/<schema>/<Tables|Views>/<object>.alter.sql
python tools/uc_pipelines/run_pipeline.py --schemas <schema>
```

The orchestrator only regenerates phases whose outputs are missing.

If you want to regenerate everything:

```bash
python tools/uc_pipelines/run_pipeline.py --schemas <schema> --force
```

## Headless runner from a Claude CLI loop

The same Python command works inside a bash/PowerShell loop. Optional helper at `tools/uc_pipelines/loop_runner.sh` runs the entrypoint hourly:

```bash
bash tools/uc_pipelines/loop_runner.sh \
  --schemas de_output,bi_output,bi_dealing,etoro_kpi_prep,etoro_kpi \
  --interval-min 60
```

(Helper script is delivered as a follow-up; the core entrypoint works standalone today.)

## Common gotchas

- **Auth fails with `system.access.column_lineage` empty**: your profile needs the `account_admin` or `metastore_admin` lineage-read grant. Ask your Databricks admin.
- **DAG build returns 0 nodes for a pilot schema**: schema is empty in UC — confirm with `SHOW TABLES IN main.{schema}` from a SQL editor.
- **`Phase 2: source code` missing for an object**: writer is a JOB with no notebook task (e.g., a SQL stored proc on a pipeline). The pipeline transparently emits a `source_code_available=false` node and proceeds without source-code narration. Downstream objects of this writer can still document if their upstream wiki exists.
- **`Phase 6: ALTER` fails for one object after Phase 5 succeeded**: usually a column-name typo in the generated `.alter.sql`. Open the file, fix the column name, re-run `deploy_alter_batch.py` against that single object.

## What to do next

After a successful run + deploy:

1. Open Databricks SQL editor and run `DESCRIBE TABLE EXTENDED main.de_output.<object>` — confirm COMMENT lines for table and columns are populated.
2. Confirm the column comments are visible in the Databricks AI assistant by asking it a question about the table.
3. Browse the per-schema `_deploy-index.md` files for any `Blocked` rows; those are your follow-up backlog.

Once you're satisfied the pilot is healthy, the next spec extends the pilot to additional schemas. That's a separate ticket.
