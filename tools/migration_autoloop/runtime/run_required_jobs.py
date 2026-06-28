#!/usr/bin/env python3
from __future__ import annotations

import json
import time

from databricks.sdk import WorkspaceClient

TARGET_NAMES = [
    "DWH_Daily_Process__SP_Dictionaries_AutoPOC",
    "DWH_Daily_Process__SP_Dim_Position_AutoPOC",
]


def _find_job_id(w: WorkspaceClient, name: str) -> int | None:
    for j in w.jobs.list(name=name):
        if j.settings and j.settings.name == name and j.job_id is not None:
            return int(j.job_id)
    return None


def _wait(w: WorkspaceClient, run_id: int) -> dict[str, object]:
    while True:
        run = w.jobs.get_run(run_id=run_id)
        state = run.state
        life = state.life_cycle_state.value if state and state.life_cycle_state else "UNKNOWN"
        result = state.result_state.value if state and state.result_state else "NONE"
        if life in {"TERMINATED", "INTERNAL_ERROR", "SKIPPED"}:
            out = {
                "run_id": run_id,
                "life_cycle_state": life,
                "result_state": result,
                "state_message": state.state_message if state else None,
                "tasks": [],
            }
            for t in run.tasks or []:
                ts = t.state
                rec = {
                    "task_key": t.task_key,
                    "run_id": int(t.run_id) if t.run_id is not None else None,
                    "life_cycle_state": ts.life_cycle_state.value if ts and ts.life_cycle_state else None,
                    "result_state": ts.result_state.value if ts and ts.result_state else None,
                }
                if rec["result_state"] == "FAILED" and rec["run_id"] is not None:
                    try:
                        rec["error"] = w.jobs.get_run_output(run_id=rec["run_id"]).error
                    except Exception as exc:
                        rec["error"] = str(exc)
                out["tasks"].append(rec)
            return out
        time.sleep(10)


def main() -> int:
    w = WorkspaceClient(profile="guyman")
    res = []
    for name in TARGET_NAMES:
        job_id = _find_job_id(w, name)
        if job_id is None:
            res.append({"job_name": name, "status": "missing"})
            continue
        run_id = int(w.jobs.run_now(job_id=job_id).response.run_id)
        done = _wait(w, run_id)
        done["job_name"] = name
        done["job_id"] = job_id
        res.append(done)
    print(json.dumps(res, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
