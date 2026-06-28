---
description: Run one unattended Databricks migration autoloop cycle. Uses ADF pipeline as work unit and marks done only on QA parity pass.
---

# /migration-autoloop

Run one complete detect -> execute -> QA -> status-update cycle.

## Data contracts

- Seed inventory: `tools/migration_autoloop/seeds/adf_pipelines.csv`
- Optional table scope map: `tools/migration_autoloop/seeds/pipeline_table_map.csv`
- Canonical registry: `tools/migration_autoloop/runtime/pipeline_registry.csv`
- Pending manifest: `tools/migration_autoloop/runtime/work_manifest.csv`
- Evidence artifacts: `tools/migration_autoloop/runtime/evidence/*.json`
- Escalation inbox: `tools/migration_autoloop/runtime/inbox/*.md`

## Run command

```bash
python tools/migration_autoloop/run_cycle.py --limit 3 --max-retry 3 --max-failures 2
```

## Reliability rules

- Never mark `done` when QA parity has mismatches/errors.
- Never exceed retry budget silently; write escalation inbox entry.
- Keep updates atomic via registry rewrite per worker run.
- Keep runs resumable by preserving registry state between cycles.

