"""
Traverse: orchestrator run → child job runs → notebook task runs → get_run_output
"""
import sys, os, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client

ORCHESTRATOR_RUN_ID = 1125394687867775
w = make_workspace_client()

orch = w.jobs.get_run(run_id=ORCHESTRATOR_RUN_ID)
for t in sorted(orch.tasks or [], key=lambda x: x.task_key or ""):
    key = t.task_key or "?"
    child_run_id = t.run_id
    if not child_run_id or key == "gate":
        continue
    print(f"\n=== {key} (child_run={child_run_id}) ===")
    try:
        child_run = w.jobs.get_run(run_id=child_run_id)
        child_tasks = child_run.tasks or []
        target_run_id = child_tasks[0].run_id if child_tasks else child_run_id
        out = w.jobs.get_run_output(run_id=target_run_id)
        nb = out.notebook_output
        if nb and nb.result:
            try:
                data = json.loads(nb.result)
                if isinstance(data, dict) and "targets" in data:
                    print(f"  overall: {data.get('overall_status')}")
                    for tgt, info in data.get("targets", {}).items():
                        if isinstance(info, dict):
                            status   = info.get("status","?")
                            parity   = info.get("parity","")
                            skip     = " [skip]" if info.get("skip_compare") else ""
                            par      = info.get("par_rows")
                            gold_r   = info.get("gold_rows")
                            cnt_s    = f"  par={par:,} gold={gold_r:,}" if isinstance(par,int) else ""
                            print(f"    {tgt}: {status}{skip}  parity={parity}{cnt_s}")
                        else:
                            print(f"    {tgt}: {info}")
                elif isinstance(data, dict) and "error" in data:
                    print(f"  ERROR: {data['error'][:400]}")
                    tb = data.get("traceback","")
                    if tb: print(f"  TB: {tb[-800:]}")
                else:
                    print(f"  {nb.result[:500]}")
            except json.JSONDecodeError:
                print(f"  RAW: {nb.result[:500]}")
        else:
            err = getattr(out, "error", None)
            print(f"  no nb output" + (f" | {err}" if err else ""))
    except Exception as e:
        print(f"  failed: {e}")
