#!/usr/bin/env python3
"""One-shot status check: latest run + per-task state. No polling, no loop."""
import os, sys, datetime
os.environ["DATABRICKS_CONFIG_PROFILE"] = "DEFAULT"
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")

from databricks.sdk import WorkspaceClient
w = WorkspaceClient()
JOB_ID = 239804415469841

run = next(iter(w.jobs.list_runs(job_id=JOB_ID, limit=1)), None)
if not run:
    print("No runs found.")
    sys.exit(0)

def fmt_ts(ms):
    if not ms: return "?"
    return datetime.datetime.fromtimestamp(ms / 1000, tz=datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

lc = run.state.life_cycle_state.value if run.state and run.state.life_cycle_state else "?"
rs = run.state.result_state.value if run.state and run.state.result_state else "-"
trigger = run.trigger.value if run.trigger else "?"
print(f"run_id : {run.run_id}")
print(f"started: {fmt_ts(run.start_time)}  trigger={trigger}")
print(f"state  : {lc}/{rs}")
if run.state and run.state.state_message:
    print(f"msg    : {run.state.state_message}")
print()

r = w.jobs.get_run(run_id=run.run_id)
for t in sorted(r.tasks or [], key=lambda x: x.task_key):
    tlc = t.state.life_cycle_state.value if t.state and t.state.life_cycle_state else "?"
    trs = t.state.result_state.value if t.state and t.state.result_state else "-"
    icon = {"SUCCESS": "✓", "FAILED": "✗", "SKIPPED": "—"}.get(trs, "…" if tlc == "RUNNING" else "·")
    print(f"  {icon}  {t.task_key:<30}  {tlc}/{trs}")

print()
print(f"UI: https://adb-5142916747090026.6.azuredatabricks.net/#job/{JOB_ID}/run/{run.run_id}")
