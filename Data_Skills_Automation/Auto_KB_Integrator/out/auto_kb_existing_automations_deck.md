---
marp: true
theme: default
paginate: true
title: Auto KB Existing Automations
description: Current state of the Data Skills Automation watcher stack
---

# Auto KB Existing Automations

## Databricks Knowledge Platform

- Purpose: keep skills and domain memory current automatically
- Model: `diff -> evaluate -> conditional ingest/push`
- Scope: Genie, UC objects, DB wiki-to-lake links, Confluence deltas
- Orchestration: shared `tools/auto_kb` engine + daily wrapper + 6th integrator

---

# Why This Exists

## Before Automation

- New knowledge appeared faster than manual skill updates
- Important updates could be missed between manual curation cycles
- Signals from multiple systems were fragmented

## Current Goal

- Detect meaningful deltas early
- Preserve only durable knowledge
- Avoid skill bloat and duplicate/noisy ingests

---

# System Architecture

## Shared Engine (`tools/auto_kb`)

- `state.py`: snapshot baseline + hash diffing
- `runner.py`: common CLI and app wiring
- `cycle.py`: process loop, notifications, run summary
- `processor.py`: action execution and quality gates
- `runlog.py`: writes per-item outcomes to UC run-log tables
- `notify.py`: operational notifications

---

# Watcher 1: Genie Spaces

## What It Detects

- New/changed Genie spaces
- Curation richness from serialized space artifacts

## Evaluation Signals

- Builder measures, sample/benchmark queries
- Text instructions, join specs, described columns
- Low-score spaces are skipped as thin/non-durable

## Typical Action

- Ingest only when space introduces reusable semantic knowledge

---

# Watcher 2: UC Object + Pipeline

## What It Detects

- New/changed UC tables/views in output/KPI schemas
- Excludes `*_stg` schemas

## What It Learns

- Pulls writer source context (prod workspace `5263962954799003`)
- Runs uc-pipeline-doc flow (lineage-first contract)

## Typical Action

- Generate wiki + lineage + comments
- Conditionally ingest/push only for durable new concepts

---

# Watcher 3: DB-Schema Lake Wiki

## What It Detects

- New/changed DB wikis in sibling `DB_Schema` repo
- Only rows that intersect Generic Pipeline mapping

## What It Adds

- Synapse source table -> UC lake object linkage knowledge
- Cross-system semantic continuity for analysts and agents

---

# Watcher 4: Confluence Delta

## What It Detects

- New/changed pages by version delta

## Special Constraint

- Uses MCP-driven metadata snapshot (SSO path)
- Headless watcher consumes snapshot file (`--current`)

## Typical Action

- Amend skill-backing pages only
- Skip spray-and-pray ingestion of untracked content

---

# Quality Control Layer

## Anti-Bloat Gates (Now Active)

- Duplication/overlap gate in ingest flow
- Adversarial durability gate in shared processor:
  - Heuristic screen for temporary/noisy patterns
  - Adversarial judge: `approve | reject | review`
- `reject/review` => skipped with explicit reason in logs

## Example Outcome

- Campaign/export-like dated object can be filtered as non-durable

---

# Daily End-to-End Run

## One Command Wrapper

- Script: `tools/auto_kb/run_daily_once.py`
- Sequence:
  1) Confluence MCP bridge snapshot
  2) 4 watchers
  3) implications report
  4) 6th integrator
  5) consolidated run summary

## Modes

- Staging mode for safe proving
- Detect-only options for targeted diagnostics

---

# 6th Integrator Agent

## Role

- Combines watcher manifests + implication data into one handoff

## Main Outputs

- `integrated_summary.md/json/csv`
- `implications_summary.csv` and row-level detail
- Agentic appendix for action-oriented follow-up

## Value

- Converts distributed automation signals into one operational narrative

---

# Operational Outputs and Traceability

## Per Run

- Item-level statuses: `done`, `skipped`, `error`
- Notes include gate reasoning and action rationale
- Snapshot advances only on successful non-dry run

## Persistence

- UC run-log tables (`main.de_output.de_output_auto_kb_*`)
- File outputs under `Data_Skills_Automation/Auto_KB_Integrator/out/`

---

# Current Strengths and Limits

## Strengths

- Diff-driven and repeatable
- Multi-source coverage with shared execution model
- Quality filters reduce noisy skill expansion

## Limits / Next Hardening

- Borderline `review` queue with human approval
- Per-app durability thresholds and calibration
- Continuous tuning from false-positive/false-negative feedback

---

# Suggested Rollout Narrative

## Message to Stakeholders

- We now automate discovery and triage across 4 high-value knowledge streams
- We added explicit anti-bloat durability controls before ingest/push
- We produce one daily integrated report for fast decision-making
- Next phase: review queue + threshold tuning + KPI tracking

---

# Appendix: Key Commands

```bash
# Daily integrated run
python tools/auto_kb/run_daily_once.py --staging --limit 1

# Generate implications and integrated summary
python tools/auto_kb/implications_report.py --since-hours 24
python tools/auto_kb/integrator_agent.py --agentic --workspace-cwd .
```

```bash
# Example watcher dry-run
python Data_Skills_Automation/UC_Object_Watcher/watch.py \
  --current Data_Skills_Automation/UC_Object_Watcher/fixtures/current_objects.json \
  --snapshot Data_Skills_Automation/UC_Object_Watcher/fixtures/_tmp_snapshot.json \
  --dry-run --no-notify --no-runlog
```
