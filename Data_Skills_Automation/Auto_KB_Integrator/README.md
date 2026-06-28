# Auto KB Integrator (6th agent)

End-of-run integrator for the watcher stack. It consumes five outputs:

1. `Genie_Watcher` manifest
2. `UC_Object_Watcher` manifest
3. `DBSchema_Lake_Watcher` manifest
4. `Confluence_Watcher` manifest
5. `implications_rows.csv` from UC run-logs

Then it writes an integrated daily handoff summary.

## Run

```bash
python tools/auto_kb/implications_report.py --since-hours 24
python tools/auto_kb/integrator_agent.py --agentic --workspace-cwd .
```

## Outputs

All files are written under `Data_Skills_Automation/Auto_KB_Integrator/out/`:

- `implications_rows.csv` (row-level implications)
- `implications_summary.csv` (aggregate counts)
- `integrated_summary.json` (machine-readable merged summary)
- `integrated_summary.csv` (flat metrics table)
- `integrated_summary.md` (human handoff)
- `integrated_agentic_appendix.md` (LLM-generated action-focused appendix)
