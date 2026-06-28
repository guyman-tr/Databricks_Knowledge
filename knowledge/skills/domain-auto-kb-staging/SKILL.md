---
name: domain-auto-kb-staging
description: Tracks Auto KB watcher run outcomes and promotion readiness signals across staging pipelines so operators can decide whether automation outputs are safe to promote.
required_tables:
  - main.de_output.de_output_auto_kb_genie_runs
  - main.de_output.de_output_auto_kb_uc_object_runs
  - main.de_output.de_output_auto_kb_dbschema_runs
  - main.de_output.de_output_auto_kb_confluence_runs
triggers:
  - auto kb staging
  - auto kb run status
  - watcher promotion readiness
  - auto kb pipeline health
sample_questions:
  - Which watcher run statuses are currently blocking promotion?
  - Did the latest Auto KB run produce deliverables across all watchers?
  - Are there any skipped overlap-gate outcomes in the latest batch?
domain_tags:
  - automation
  - auto-kb
  - staging
version: 1
owner: dataplatform
last_validated_at: "2026-06-18"
---

# Auto KB Staging Runbook

## When to Use
Use this skill when evaluating staging watcher outcomes for Auto KB pipelines and determining whether a promotion is safe to proceed.
It is intended for run-status triage across Genie, UC object, DB schema, and Confluence watcher outputs.

## Scope
In scope: `main.de_output.de_output_auto_kb_genie_runs`, `main.de_output.de_output_auto_kb_uc_object_runs`, `main.de_output.de_output_auto_kb_dbschema_runs`, and `main.de_output.de_output_auto_kb_confluence_runs` run outcomes and promotion-readiness interpretation.
Out of scope: generating new watcher artifacts, editing source watcher logic, and DataPlatform PR orchestration.
Last verified: 2026-06-18

## Critical Warnings
1. Silent wrong risk: treating partial watcher success as globally promotable can hide failing streams, so promotion decisions must consider all watcher run statuses in the same run window.
2. Aggregate inflat risk: counting status rows without run-level deduplication inflates failure or success rates when retries emit multiple rows for the same watcher execution.
3. Dependency risk: artifact availability depends on downstream systems and handoff processes, so `status=done` without a valid artifact reference is not sufficient evidence for promotion.

## Checks
- Any `status=error` rows in the latest `run_id` block promotion.
- `status=skipped` rows are expected when overlap guards trigger.
- `status=done` with `artifact_ref` set indicates a concrete deliverable was produced.
