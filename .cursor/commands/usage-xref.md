---
description: Cross-reference ad-hoc Databricks usage (Genie Space + SQL Editor + MCP) against deployed skill triggers and required_tables. Surfaces hub-trigger gaps, sub-skill-trigger gaps, coverage gaps, and Genie-space registration mismatches. Designed to be called by future automations (CI, scheduled jobs) at standard windows (7-day weekly, 30-day monthly, 365-day annual).
---

# Usage ↔ Skills Trigger Cross-Reference

Validates what real users query against what we documented. Pulls last N days of
ad-hoc traffic from `system.query.history`, parses every SQL for table FQNs and
column tokens, and diffs that vocabulary against every YAML-frontmatter skill's
`triggers` + `required_tables` + body text.

The motivating failure mode: Genie spaces and MCP load only the hub `SKILL.md`,
match shallow hub-level triggers, then refuse to descend into sub-skills. If a
real user's vocabulary (e.g. "negative market", "alert_root_cause") only lives
in a sub-skill, the hub returns "no match" and the agent gives up. This command
finds those gaps systematically.

---

## Invocation

```text
/usage-xref                     # default: 7-day window
/usage-xref 30                  # 30-day window
/usage-xref 365                 # annual discovery
/usage-xref --genie-space-id 01f0c38d864d10be9b493dfec1f100eb   # spot-check one space
```

The agent runs:

```bash
python tools/skills/usage_trigger_xref.py --lookback-days <days>
```

Available flags (all optional):

| Flag | Default | Meaning |
|---|---|---|
| `--lookback-days` | `7` | Window in days. Standard cadences: `7` (weekly), `30` (monthly), `90` (quarterly), `365` (annual). |
| `--min-query-count` | `3` | Minimum query count for a phrase/table to surface as a gap. Raise to `10`+ for 30d+ windows. |
| `--client-applications` | `'Databricks SQL Genie Space' 'Databricks SQL Editor' 'Databricks SQL MCP'` | Override to widen/narrow ad-hoc surface. |
| `--genie-space-id` | (all) | Single-space spot-check mode. |
| `--profile` | `$DATABRICKS_MCP_PROFILE` or `guyman` | Databricks CLI profile (same auth as MCP). |
| `--warehouse-id` | from `$DATABRICKS_HTTP_PATH` or built-in | SQL warehouse to run the query on. |
| `--output-dir` | `audits/_usage_trigger_xref_<UTC timestamp>` | Override output location. |
| `--skip-fetch` | off | Re-classify against the previous run's `queries.json` (skip the DBX round-trip). |

---

## What it filters

Only ad-hoc / human-interactive traffic. Confirmed via `query_source.*` validation
that these three `client_application` values are 100% pure (no notebook / job /
dashboard / pipeline linkage):

- `Databricks SQL Genie Space` — Genie spaces (chat-driven analyst tool)
- `Databricks SQL Editor` — SQL Editor + Genie Code (hand-typed and Assistant-generated SQL)
- `Databricks SQL MCP` — Claude/Cursor MCP calls

Excluded: notebooks, scheduled jobs, scheduled dashboards, alerts, pipelines, SPs.

---

## Output

```
audits/_usage_trigger_xref_<UTC timestamp>/
  queries.json                  # raw pulled rows (for --skip-fetch re-runs)
  report.csv                    # one row per gap (all four classes, flat)
  report.md                     # narrative summary grouped by class
  proposed_trigger_diff.json    # machine-readable promotions (downstream apply)
  meta.json                     # run metadata (lookback, query count, skill counts)
```

---

## Gap classes

| Class | Definition | Action |
|---|---|---|
| **A** Hub trigger gap | Sub-skill owns a heavily-used table; matching hub has no trigger covering the user vocabulary against it. | Promote phrase to hub triggers. |
| **B** Sub-skill trigger gap | Skill body documents the phrase, but the skill triggers don't list it. | Add phrase to sub-skill triggers. |
| **C** Coverage gap | Table queried ≥ threshold times but isn't in any skill's `required_tables`. | Document the table. |
| **D** Genie-space mismatch | Registered tables in the Genie space diverge from actually-queried tables (over-registered or unregistered-used). | Realign space `data_sources` and/or skill documentation. |

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | No gaps found |
| `1` | Gaps found (designed to gate CI / trigger a workflow) |
| `2` | Tool error (auth failure, missing dep, etc.) |

This makes `/usage-xref` suitable for scheduled automation:

```yaml
# Example GitHub Action (weekly trigger validation)
- run: python tools/skills/usage_trigger_xref.py --lookback-days 7
  continue-on-error: true
- run: python tools/skills/usage_trigger_xref.py --lookback-days 365 --min-query-count 25
  if: github.event.schedule == '0 0 1 * *'  # monthly annual sweep
```

---

## Cadence

| Cadence | Window | Min count | Use |
|---|---|---|---|
| **Weekly** | 7d | 3 | Catch fresh vocabulary drift before it accumulates |
| **Monthly** | 30d | 10 | Promote stable patterns to hub triggers |
| **Quarterly** | 90d | 25 | Re-baseline coverage gaps for documentation work |
| **Annual** | 365d | 50 | Full discovery sweep; informs domain-rebuild specs |

---

## Files

| File | Role |
|---|---|
| `tools/skills/usage_trigger_xref.py` | Engine — pulls, parses, classifies, emits |
| `knowledge/skills/_genie_spaces_index.json` | Class D needs this for registered-vs-used comparison |
| `knowledge/skills/**/SKILL.md` + sub-skills | Trigger lists + `required_tables` + body text |
| `audits/_usage_trigger_xref_<UTC>/` | One folder per run |

---

## Prerequisites

```bash
pip install databricks-sdk pyyaml
```

Auth must be configured for the chosen profile (same auth as the Cursor MCP):

```bash
databricks auth login --host https://<workspace-host> --profile guyman
```

---

## Reading the report

`report.md` is the human-facing summary. For each gap class, top 50 rows are
tabulated in priority order (highest query count first). Full data lives in
`report.csv`.

`proposed_trigger_diff.json` is the apply-ready form. Future tool
`tools/skills/apply_trigger_diff.py` (not yet built) will consume this and emit
the actual YAML diffs to skill files for review-then-merge.

---

## When to re-run

- After deploying new skills (validates triggers actually match usage)
- After Genie spaces are created/renamed (Class D detection)
- After Databricks Assistant or MCP integration changes
- On any documentation gap report from a user (use `--genie-space-id` to spot-check)
- On the standard cadence above
