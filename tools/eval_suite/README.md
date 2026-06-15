# eval_suite — answer-correctness eval for Genie Code + custom Databricks MCP

V1 of an answer-correctness eval suite for the eToro analytics-agent stack. Runs daily via a Databricks notebook job with **fresh, no-prior-context agents**; results land in Delta telemetry that the quality-gate team productizes.

This is not the existing routing harness (`tools/skills_eval/` design from 2026-06-08, which checks _which skill activates_) and not the `/feedback` app (slow, requires user grading). It is the missing answer-correctness layer that sits between them.

## Layout

```
tools/eval_suite/
  README.md                       (you are here)
  schema/
    case.schema.json              JSON Schema for cases/*.yaml
  cases/                          ~150 case YAMLs, one per question
  lint_cases.py                   validate every case YAML
  seed_cases.py                   generate cases from truth sources
  run_eval.py                     daily runner — fresh sessions, scores 3 signals
  scoring.py                      numeric tolerance + LLM-judge
  repository.py                   Delta sink for eval_runs
  clients/
    genie_code_client.py          fresh-session wrapper around Genie Conversation API
    custom_mcp_client.py          fresh-session wrapper around our MCP gateway
  drift_sentinel/
    __init__.py                   pluggable TruthSourceAdapter interface
    runner.py                     daily diff + xref + sink driver
    skill_xref.py                 indexes .cursor/skills + knowledge/skills
    sinks.py                      Delta sink for drift_events
    adapters/
      tableau.py                  V1's only adapter (SQL bodies, calc fields, edges)
audits/eval_suite/
  drift_snapshots/<source>/<YYYY-MM-DD>.jsonl   git-reviewable
notebooks/eval_suite/
  daily_run.ipynb                 Lakeflow-scheduled wrapper
```

## Three independent signals per case

Each (case, system, replica) tuple records:

1. **answer_correct** — numeric within `tolerance_pct` of `expected_value`, or LLM-judge for textual answers.
2. **skill_loaded_correct** — did the system load `expected_skill_hub` (or a matching sub-skill)?
3. **canonical_source_used** — does the returned SQL reference any `canonical_tables` and avoid `anti_sources`?

A case can be `answer_correct=true, skill_loaded_correct=false` (right answer for the wrong reason) — flag for review, but do not gate on it.

## Two systems under test

| System | Adapter | How a fresh session is created |
|---|---|---|
| Genie Code | `clients/genie_code_client.py` | new MCP-gateway session per case via mcp-remote; no prior thread |
| Custom Databricks MCP | `clients/custom_mcp_client.py` | direct gateway client, fresh `find_skills` call per case |

Genie spaces are **not** systems under test — their `benchmarks.questions[]` are seed material for cases.

## Pinned-snapshot ground truth

Every case ships with `ground_truth_sql` and a fixed `asof` date. The pinning pass runs once, caches `expected_value`, and never re-runs against live data afterward — numbers cannot drift. Cases use existing UC FQNs (`main.bi_db.gold_sql_dp_prod_we_*`, `main.etoro_kpi.*`, etc.).

## Drift Sentinel

Truth-source-agnostic layer that snapshots reference truth sources and diffs them daily. Tableau is V1's only adapter; Genie spaces, UC metadata, Confluence, SharePoint, MCP telemetry are first-class follow-on adapters that reuse the same `TruthSourceAdapter` protocol, skill xref, severity engine, and Delta sink.

A `ChangeEvent` is severity:

- **high** — affects a top-50 workbook by views, OR an active eval case, OR a `covered` skill.
- **medium** — views-percentile 50-90, OR a `partial` skill.
- **low** — long-tail, no skill mentions.

High-severity events open a Jira/GitHub issue tagged to the domain owner. Medium accumulates on the dashboard. Low is logged-only.

## Delta sinks

Two tables in `main.de_output`:

| Table | Purpose | One row per |
|---|---|---|
| `de_output_eval_runs` | answer-correctness telemetry | (case, system, replica, ts) |
| `de_output_eval_drift_events` | truth-source drift events | (event_id) |

Schemas live in `repository.py` and `drift_sentinel/sinks.py`. "Did that change help?" becomes a SQL query over these tables — Anthropic's "telemetry, not test logs" pattern.
