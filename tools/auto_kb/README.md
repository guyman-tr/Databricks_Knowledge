# auto_kb -- shared diff -> ingest -> push framework

Reusable engine for the four knowledge-base watcher apps under
[Data_Skills_Automation/](../../Data_Skills_Automation). Cloned from the generic
half of [tools/skill_suggestions/](../skill_suggestions) but with no Databricks
app and no user-input queue: each app is pure `diff -> evaluate -> conditional push`.

## Modules

| File | Role |
|---|---|
| `models.py` | `WorkItem`, `ItemOutcome`, `RunContext` dataclasses + the `new\|processing\|done\|skipped\|error` lifecycle |
| `state.py` | snapshot load/save, `canonical_hash`, `build_items_map`, `diff_hash_maps` (new/changed/removed) |
| `runlog.py` | per-app EXTERNAL run-log table writer in `main.de_output`; `assert_naming_compliant` enforces the anti-purge formula before any write |
| `processor.py` | `ActionSpec` + `process_item`: dry-run simulation vs live Cursor SDK execution (reuses `skill_suggestions.agent_runner`) |
| `cycle.py` | `run_cycle`: per-item process -> run-log -> notify -> aggregate; advances the snapshot baseline only on a fully successful live run |
| `notify.py` | thin wrapper over `tools/notify/notify.py` |
| `runner.py` | `WatchSpec` + `run_app`: the uniform CLI every app calls (load snapshot, fetch current, diff, build items, run cycle, write manifest) |
| `ddl.sql` | the four anti-purge-compliant run-log tables |
| `implications_report.py` | consolidated UC run-log export + implication classification (`BLOCKER`, `ACTIONABLE_CHANGE`, etc.) into CSV |
| `integrator_agent.py` | end-of-run 6th integrator over five outputs (4 manifests + implications CSV), producing integrated summary artifacts |

## Contract for an app

Each app supplies a `WatchSpec`:

```python
WatchSpec(
    app="genie",                      # run-log key
    default_snapshot="...snapshot.json",
    fetch_current=fn,                 # (current_override|None) -> {key: raw_record}
    make_work_item=fn,                # (key, record, "new"|"changed") -> WorkItem
    build_prompt=fn,                  # (WorkItem, RunContext) -> str   (live mode)
    simulate=fn,                      # (WorkItem) -> ItemOutcome       (dry-run)
)
```

`run_app(spec)` does everything else. Detection always supports `--current`
(fixtures / externally-produced snapshots) so every app dry-runs fully offline.

## Run-log tables (anti-purge)

Names follow the purge formula (location path segments under the `analysis`
container, joined + lowercased). Validate before creating:

```bash
python tools/skill_suggestions/validate_external_name.py \
    --schema de_output --table-name de_output_auto_kb_genie_runs \
    --location "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Auto_Kb/Genie_Runs/" --json
```

Or programmatically: `python -c "from tools.auto_kb import runlog; [runlog.assert_naming_compliant(a) for a in runlog.RUN_LOG_SPECS]"`.

Apply the DDL with your usual Databricks SQL runner (e.g. `tools/dbx_query.py`)
before the first live run.

## Safety invariants

- Dry runs never mutate the snapshot, never write the run-log, never notify,
  never call the Cursor SDK.
- The snapshot baseline advances only when a live run processes every detected
  item with zero failures -- a failed item is re-detected next cycle.
- Live mode requires `CURSOR_API_KEY` (enforced lazily by the agent bridge).

## Daily integration (new)

After the four watcher apps finish, run:

```bash
python tools/auto_kb/implications_report.py --since-hours 24
python tools/auto_kb/integrator_agent.py --agentic --workspace-cwd .
```

Outputs land in `Data_Skills_Automation/Auto_KB_Integrator/out/`:
- `implications_rows.csv`
- `implications_summary.csv`
- `integrated_summary.json`
- `integrated_summary.csv`
- `integrated_summary.md`
- `integrated_agentic_appendix.md` (when `--agentic` is enabled)

## One-command daily run

Use this wrapper to run the whole stack once:

```bash
python tools/auto_kb/run_daily_once.py --staging --no-notify --limit 1 --skip-confluence --uc-detect-only
```

It performs:
1) Confluence MCP bridge fetch (agent-mediated, SSO)
2) 4 watcher runs
3) implications report
4) 6th integrator

Run artifacts:
- `Data_Skills_Automation/Auto_KB_Integrator/out/daily_once_latest.json`
- `Data_Skills_Automation/Auto_KB_Integrator/out/daily_once_latest.md`
