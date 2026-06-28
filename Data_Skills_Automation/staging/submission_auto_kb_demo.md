---
name: auto-kb-staging-demo
description: Staging-only skill for interpreting auto_kb watcher runlog outcomes and deciding promotion readiness.
required_tables:
  - main.de_output.de_output_auto_kb_genie_runs
  - main.de_output.de_output_auto_kb_uc_object_runs
  - main.de_output.de_output_auto_kb_dbschema_runs
  - main.de_output.de_output_auto_kb_confluence_runs
version: 1
owner: dataplatform
---

# Auto KB Staging Runbook

## Purpose
Review watcher run outcomes and quickly decide whether a change is safe to promote.

## Checks
- Any status=error rows in the latest run_id block promotion.
- status=skipped rows are expected when overlap guards trigger.
- status=done with artifact_ref set means a concrete deliverable was produced.
