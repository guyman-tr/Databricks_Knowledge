#!/usr/bin/env python3
from __future__ import annotations

import json
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


def main() -> int:
    w = WorkspaceClient(profile="guyman")
    out: list[dict[str, object]] = []
    for name in TARGET_NAMES:
        job_id = _find_job_id(w, name)
        if job_id is None:
            out.append({"job_name": name, "status": "missing"})
            continue
        runs = list(w.jobs.list_runs(job_id=job_id, limit=1))
        if not runs:
            out.append({"job_name": name, "status": "no_runs"})
            continue
        run = w.jobs.get_run(run_id=int(runs[0].run_id))
        row: dict[str, object] = {
            "job_name": name,
            "job_id": int(job_id),
            "run_id": int(run.run_id) if run.run_id is not None else None,
            "result_state": run.state.result_state.value if run.state and run.state.result_state else None,
            "life_cycle_state": run.state.life_cycle_state.value if run.state and run.state.life_cycle_state else None,
            "tasks": [],
        }
        for t in run.tasks or []:
            task_info: dict[str, object] = {
                "task_key": t.task_key,
                "run_id": int(t.run_id) if t.run_id is not None else None,
                "result_state": t.state.result_state.value if t.state and t.state.result_state else None,
                "life_cycle_state": t.state.life_cycle_state.value if t.state and t.state.life_cycle_state else None,
            }
            if t.run_id is not None:
                try:
                    o = w.jobs.get_run_output(run_id=int(t.run_id))
                    task_info["error"] = o.error
                    task_info["output"] = o.logs
                except Exception as exc:
                    task_info["output_error"] = str(exc)
            row["tasks"].append(task_info)
        out.append(row)
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
