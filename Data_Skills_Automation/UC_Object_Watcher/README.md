# Unity Catalog Object + Pipeline Watcher

Diff-driven autonomous flow: detect new UC tables/views (and column-signature
changes) in the in-scope output/KPI schemas, learn HOW each is built by fetching
the writer notebook/pipeline source from the **production workspace
`5263962954799003`**, generate the wiki + lineage via the uc-pipeline-doc pack,
deploy ALTER COMMENTs, and conditionally push a skill/domain amendment when a new
durable concept emerges.

Built on the shared engine in [tools/auto_kb/](../../tools/auto_kb).

## Scope

- Catalog `main`, schemas in `DEFAULT_SCHEMAS` (`etoro_kpi_prep`, `etoro_kpi`,
  `de_output`, `bi_output`, `dealing_output`).
- `*_stg` schemas are **always excluded** (enforced in both the live SQL filter
  and the fixture normalizer).
- Change detection is on the **column fingerprint** (`name:type`, ordinal-sorted),
  so adding/removing/retyping a column re-triggers documentation.

## State

| What | Where |
|---|---|
| current (live) | `main.information_schema.tables` + `.columns` |
| current (override) | `--current <json>` (`{"objects":[{schema,table,table_type,columns:[{column_name,data_type}]}]}`) |
| baseline snapshot | `Data_Skills_Automation/UC_Object_Watcher/state/snapshot.json` |
| run-log | `main.de_output.de_output_auto_kb_uc_object_runs` (external, anti-purge compliant) |

## Run

Dry-run (offline):

```bash
python Data_Skills_Automation/UC_Object_Watcher/watch.py \
    --current Data_Skills_Automation/UC_Object_Watcher/fixtures/current_objects.json \
    --snapshot Data_Skills_Automation/UC_Object_Watcher/fixtures/_tmp_snapshot.json \
    --dry-run --no-notify --no-runlog \
    --manifest-out Data_Skills_Automation/UC_Object_Watcher/out/manifest.json
```

Live (requires Databricks auth + `CURSOR_API_KEY`):

```bash
python Data_Skills_Automation/UC_Object_Watcher/watch.py --workspace-cwd .
```

## Downstream tooling

The live processor drives `tools/uc_pipelines/run_pipeline.py` and
`tools/uc_pipelines/fetch_writer_source.py` (writer source from workspace
`5263962954799003`), honoring the `uc-pipeline-doc` GATE-lineage-contract before
the wiki is generated.

## Schedule

Daily. The snapshot advances only on a fully successful live run.
