# Questions Watcher

The 5th auto_kb watcher. Mines the questions real users actually ask -- via
the MCP gateway and via Genie -- finds the recurring interests our skills answer
poorly, and produces a gap dossier proposing the skill that would fix each gap.

Pure `diff -> evaluate -> propose`. No Databricks app, no user input. Built on the
shared engine in [tools/auto_kb/](../../tools/auto_kb).

## Sources

| Source | Table | Question text | Coverage signal |
|---|---|---|---|
| MCP | `main.config.monitoring_mcp_logs_mcp_gateway` | `args_preview` JSON `question` (tools `skills_find_skills`, `databricks_ops_ask_genie`) | `skills_top_score`, `skills_match_quality_hint`, `skills_all_below_floor`, `returned_skill_ids` |
| Genie | `main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway` | `nl_prompt` | `message_status` (failures), `thumb_down`, local trigger router |

## How it works

1. **Denoise** every question (`tools/auto_kb/questions/normalize.py`): strip
   dates, quarters, years, month names, raw numbers, URLs, country/region
   literals, and conversational filler.
2. **Signature**: identify METRICS first, then CLASSIFIERS (dimensions). The
   intent signature is `m:<metrics>|c:<classifiers>`, so "FTD by country Q2" and
   "FTD by country June" collapse to the same recurring interest.
3. **Cluster + quantify**: group by signature; a cluster is tracked only if it
   is recurring (`>= QUESTIONS_MIN_SUPPORT` occurrences **or**
   `>= QUESTIONS_MIN_USERS` distinct users).
4. **Coverage** (`tools/auto_kb/questions/coverage.py`): reuse the MCP gateway's
   own skill match scores; for Genie clusters (no skill score) use the local
   trigger router (`tools/routing_inventory/smoke_test.py`); fold in Genie
   failure rate + thumb-down. Each cluster -> `well_covered | partial | underserved`.
5. **Diff** on the intent signature: a NEW recurring interest, or a cluster that
   DEGRADES to under-served, becomes a `WorkItem`.
6. **Gate + propose**: the shared adversarial durability gate runs first; only
   approved, non-well-covered intents reach the agent, which investigates the gap
   (skills, Tableau, Confluence, Jira, wikis, UC) and writes a **gap dossier** with
   a proposed domain/sub-domain placement. It does **not** author skills or push.

## Outputs

| File | Content |
|---|---|
| `out/intent_inventory.csv` | Every cluster: signature, metrics, classifiers, coverage, counts, top skill, denoised examples |
| `out/underserved_clusters.csv` | The ranked gaps (coverage != well_covered) |
| `out/dossiers/gap_dossier_<signature>.md` | Per-gap agent dossier + proposed placement |
| `main.de_output.de_output_auto_kb_questions_runs` | Run-log (external, anti-purge compliant) |

## PII

User emails are hashed to count distinct users and then discarded. State,
run-log, and all artifacts persist only denoised intent signatures and counts --
no email, no raw customer-specific value.

## Run

Dry-run (offline -- no Databricks, no Cursor SDK):

```bash
python Data_Skills_Automation/Questions_Watcher/watch.py \
    --current Data_Skills_Automation/Questions_Watcher/fixtures/current_questions.json \
    --snapshot Data_Skills_Automation/Questions_Watcher/fixtures/_tmp_snapshot.json \
    --dry-run --no-notify --no-runlog \
    --manifest-out Data_Skills_Automation/Questions_Watcher/out/manifest.json
```

Detect only (write the manifest + inventory, do not process):

```bash
python Data_Skills_Automation/Questions_Watcher/watch.py --detect-only \
    --current Data_Skills_Automation/Questions_Watcher/fixtures/current_questions.json \
    --manifest-out Data_Skills_Automation/Questions_Watcher/out/manifest.json
```

Staging (live read + agent dossier, no push; requires `CURSOR_API_KEY` + Databricks auth):

```bash
python Data_Skills_Automation/Questions_Watcher/watch.py --staging --limit 1 --workspace-cwd .
```

## Tunables (env)

| Var | Default | Meaning |
|---|---|---|
| `QUESTIONS_LOOKBACK_DAYS` | 30 | Live query window over both gateway tables |
| `QUESTIONS_MIN_SUPPORT` | 3 | Min occurrences to track a cluster |
| `QUESTIONS_MIN_USERS` | 2 | ...or min distinct users |

## Schedule

Daily, as part of `tools/auto_kb/run_daily_once.py`.
