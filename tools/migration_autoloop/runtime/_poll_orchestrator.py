"""
Poll orchestrator run 1125394687867775 and print task outcomes.
For notebook tasks that call dbutils.notebook.exit(), we read the output
to get the full Phase A/B result JSON.
"""
import sys, os, time, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client

ORCHESTRATOR_RUN_ID = 936854510579291
w = make_workspace_client()

seen_completed = set()

def poll():
    run = w.jobs.get_run(run_id=ORCHESTRATOR_RUN_ID)
    state = run.state
    print(f"\n[{time.strftime('%H:%M:%S')}] Orchestrator state: "
          f"{state.life_cycle_state} / {state.result_state}")

    if run.tasks:
        for t in run.tasks:
            key = t.task_key or "(unknown)"
            ts = t.state
            lc = ts.life_cycle_state if ts else "?"
            rs = ts.result_state if ts else "?"
            run_id = t.run_id

            status = f"{lc}/{rs}"
            if lc in ("RUNNING",):
                status = "RUNNING"
            elif lc == "TERMINATED":
                status = f"DONE({rs})"

            tag = f"  {key:<45} {status}"

            if lc == "TERMINATED" and run_id and run_id not in seen_completed:
                seen_completed.add(run_id)
                try:
                    out = w.jobs.get_run_output(run_id=run_id)
                    nb_out = out.notebook_output
                    if nb_out and nb_out.result:
                        blob = nb_out.result
                        try:
                            data = json.loads(blob)
                            # summarise
                            if isinstance(data, dict) and "targets" in data:
                                summary = {
                                    "overall": data.get("overall_status"),
                                    "targets": {
                                        k: v.get("status") if isinstance(v, dict) else v
                                        for k, v in data["targets"].items()
                                    }
                                }
                                tag += f"\n    OUTPUT: {json.dumps(summary)}"
                            elif isinstance(data, dict) and "error" in data:
                                tag += f"\n    ERROR: {data['error']}"
                                tag += f"\n    TRACEBACK:\n{data.get('traceback','')[:2000]}"
                            else:
                                tag += f"\n    OUTPUT: {blob[:500]}"
                        except json.JSONDecodeError:
                            tag += f"\n    RAW OUTPUT: {blob[:500]}"
                    elif out.error:
                        tag += f"\n    CLUSTER_ERROR: {out.error}"
                except Exception as e:
                    tag += f"\n    (get_run_output failed: {e})"

            print(tag)

    return state

TERMINAL = {"TERMINATED", "SKIPPED", "INTERNAL_ERROR"}

while True:
    state = poll()
    lc = state.life_cycle_state
    if lc in TERMINAL or (hasattr(lc, "value") and lc.value in TERMINAL):
        print("\nFinal state:", state.result_state)
        break
    time.sleep(30)
