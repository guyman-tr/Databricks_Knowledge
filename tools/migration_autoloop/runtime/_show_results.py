"""Pull notebook exit() output for all 8 ring tasks from orchestrator run 1125394687867775."""
import sys, os, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client

ORCHESTRATOR_RUN_ID = 1125394687867775
w = make_workspace_client()

run = w.jobs.get_run(run_id=ORCHESTRATOR_RUN_ID)
print(f"Orchestrator job: 239804415469841")
print(f"Run ID: {ORCHESTRATOR_RUN_ID}")
print(f"State: {run.state.result_state}\n")

for t in sorted(run.tasks or [], key=lambda x: x.task_key or ""):
    key = t.task_key or "?"
    run_id = t.run_id
    if not run_id:
        continue
    try:
        out = w.jobs.get_run_output(run_id=run_id)
        nb = out.notebook_output
        if nb and nb.result:
            try:
                data = json.loads(nb.result)
                print(f"=== {key} ===")
                if isinstance(data, dict) and "targets" in data:
                    print(f"  overall: {data.get('overall_status')}")
                    for tgt, info in data.get("targets", {}).items():
                        if isinstance(info, dict):
                            status = info.get("status", "?")
                            parity = info.get("parity", "")
                            skip = info.get("skip_compare", False)
                            rows_par = info.get("par_rows")
                            rows_gold = info.get("gold_rows")
                            note = f"  par={rows_par} gold={rows_gold}" if rows_par is not None else ""
                            skip_tag = " [skip_compare]" if skip else ""
                            parity_tag = f" parity={parity}" if parity else ""
                            print(f"    {tgt}: {status}{skip_tag}{parity_tag}{note}")
                        else:
                            print(f"    {tgt}: {info}")
                elif isinstance(data, dict) and "error" in data:
                    print(f"  ERROR: {data['error']}")
                else:
                    print(f"  {json.dumps(data, default=str)[:300]}")
            except json.JSONDecodeError:
                print(f"=== {key} === RAW: {nb.result[:300]}")
        else:
            err = getattr(out, "error", None)
            print(f"=== {key} === no notebook output" + (f" | error: {err}" if err else ""))
    except Exception as e:
        print(f"=== {key} === get_run_output failed: {e}")
