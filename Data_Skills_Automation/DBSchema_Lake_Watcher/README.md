# DB-Schema Lake Wiki Watcher

Diff-driven autonomous flow: detect new / changed Synapse source-DB table wikis
(in the sibling `DB_Schema` repo: `etoro`, banking, crypto, compliance, ...) that
ALSO map to a lake/UC object via the Generic Pipeline, then ingest the semantic
knowledge and conditionally push a skill/domain amendment linking the Synapse
source table to its bronze UC object.

Built on the shared engine in [tools/auto_kb/](../../tools/auto_kb).

## Scope (the intersection)

A table wiki is in scope only if all three hold:

1. It lives under `{DB}/Wiki/{Schema}/Tables/{Schema}.{Object}.md` in the
   `DB_Schema` repo (only `Tables` -- the Generic Pipeline copies tables).
2. `(database_name, schema_name, table_name)` (case-insensitive) intersects
   [`knowledge/synapse/Wiki/_generic_pipeline_mapping.json`](../../knowledge/synapse/Wiki/_generic_pipeline_mapping.json)
   -- i.e. the Generic Pipeline materializes it to the lake.
3. (change detection) the wiki content SHA differs from the snapshot.

Non-lake-backed wikis are dropped during detection.

## State

| What | Where |
|---|---|
| current (live) | `../DB_Schema/{DB}/Wiki/**/Tables/*.md` INTERSECT generic mapping |
| current (override) | `--current <json>` (`{"wikis":[{db,schema,object,object_type,wiki_path,content}]}`; `uc_table` resolved from the mapping if omitted) |
| baseline snapshot | `Data_Skills_Automation/DBSchema_Lake_Watcher/state/snapshot.json` |
| run-log | `main.de_output.de_output_auto_kb_dbschema_runs` (external, anti-purge compliant) |

## Run

Dry-run (offline -- still reads the real mapping to resolve `uc_table`):

```bash
python Data_Skills_Automation/DBSchema_Lake_Watcher/watch.py \
    --current Data_Skills_Automation/DBSchema_Lake_Watcher/fixtures/current_wikis.json \
    --snapshot Data_Skills_Automation/DBSchema_Lake_Watcher/fixtures/_tmp_snapshot.json \
    --dry-run --no-notify --no-runlog \
    --manifest-out Data_Skills_Automation/DBSchema_Lake_Watcher/out/manifest.json
```

Live (requires the sibling `DB_Schema` repo + `CURSOR_API_KEY`):

```bash
python Data_Skills_Automation/DBSchema_Lake_Watcher/watch.py --workspace-cwd .
```

## Schedule

Daily / after a DB-Schema wiki batch. The snapshot advances only on a fully
successful live run.
