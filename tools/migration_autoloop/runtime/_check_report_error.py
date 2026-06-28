#!/usr/bin/env python3
"""Check generate_report task output from the two latest failures and the successful run."""
import os, sys
os.environ["DATABRICKS_CONFIG_PROFILE"] = "DEFAULT"
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")

from databricks.sdk import WorkspaceClient
w = WorkspaceClient()

# Check the successful 07:30 run on Jun 27
print("=== Jun 27 07:30 PERIODIC run (779209709646572) ===")
r = w.jobs.get_run(run_id=779209709646572)
for t in (r.tasks or []):
    lc = t.state.life_cycle_state.value if t.state and t.state.life_cycle_state else "?"
    rs = t.state.result_state.value if t.state and t.state.result_state else "-"
    print(f"  task={t.task_key}  {lc}/{rs}")

print()
print("=== generate_report output (latest failure run 783105657324191) ===")
r2 = w.jobs.get_run(run_id=783105657324191)
for t in (r2.tasks or []):
    if t.task_key == "generate_report":
        print(f"  run_page_url: {t.run_page_url}")
        try:
            out = w.jobs.get_run_output(run_id=t.run_id)
            nb = out.notebook_output
            if nb:
                result = nb.result or ""
                print(f"  notebook_result: {result[:600]}")
            err = out.error
            trace = out.error_trace
            if err:
                print(f"  error: {err[:600]}")
            if trace:
                print(f"  trace:\n{trace[:1500]}")
            if not err and not trace and (not nb or not nb.result):
                print("  (no output captured)")
        except Exception as e:
            print(f"  (could not get output: {e})")
