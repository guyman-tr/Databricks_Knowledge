# Genie Spaces Watcher

Diff-driven autonomous flow: detect new / changed Databricks Genie spaces, score
each by how much durable knowledge the builder encoded, and -- only when a space
encodes ingestable knowledge -- run `/skills-ingest` and conditionally
`/skills-push`. No Databricks app, no user input: pure `diff -> evaluate -> push`.

Built on the shared engine in [tools/auto_kb/](../../tools/auto_kb). See that
package for the cycle, state, run-log, notify, and Cursor SDK bridge internals.

## Scoring (`score_space`)

A space scores 0-100. Builder-curated query knowledge weighs highest, with data
sources + instruction files as the fallback context (per the original intent):

| Signal | Points |
|---|---|
| `sql_snippets.measures` (baseline queries the builder set) | +30 |
| `sample_questions` / `benchmarks` | +20 |
| `text_instructions` blocks | +25 |
| curated `join_specs` | +15 |
| described columns | +10 |

Spaces scoring `< 30` (`MIN_INGEST_SCORE`) are processed as `skipped` -- too thin
to ingest as durable knowledge.

## State

| What | Where |
|---|---|
| current (live) | `knowledge/skills/_genie_spaces_index.json` + `_genie_cache/<id>.json` (refresh with the existing `extract_genie_edges` tooling before a live run) |
| current (override) | `--current <json>` (fixtures or a fresh export) |
| baseline snapshot | `Data_Skills_Automation/Genie_Watcher/state/snapshot.json` |
| run-log | `main.de_output.de_output_auto_kb_genie_runs` (external, anti-purge compliant) |

The snapshot advances **only** on a fully successful live run. Dry runs never
mutate the snapshot.

## Run

Dry-run (offline -- no Databricks, no Cursor SDK):

```bash
python Data_Skills_Automation/Genie_Watcher/watch.py \
    --current Data_Skills_Automation/Genie_Watcher/fixtures/current_spaces.json \
    --snapshot Data_Skills_Automation/Genie_Watcher/fixtures/_tmp_snapshot.json \
    --dry-run --no-notify --no-runlog \
    --manifest-out Data_Skills_Automation/Genie_Watcher/out/manifest.json
```

Detect only (write the manifest, do not process):

```bash
python Data_Skills_Automation/Genie_Watcher/watch.py --detect-only \
    --manifest-out Data_Skills_Automation/Genie_Watcher/out/manifest.json
```

Live (requires `CURSOR_API_KEY` + Databricks auth; refresh the Genie cache first):

```bash
python Data_Skills_Automation/Genie_Watcher/watch.py --workspace-cwd .
```

## Schedule

Daily, after the Genie cache refresh job. Use the `/loop` skill or an external
scheduler invoking the live command above.
