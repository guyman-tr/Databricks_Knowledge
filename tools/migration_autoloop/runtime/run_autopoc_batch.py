#!/usr/bin/env python3
from __future__ import annotations

import json
import time
from dataclasses import dataclass
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from databricks.sdk import WorkspaceClient


@dataclass(frozen=True)
class JobTarget:
    name: str
    required_success: bool = False


TARGETS: list[JobTarget] = [
    JobTarget("DWH_Daily_Process__SP_Dictionaries_AutoPOC", required_success=True),
    JobTarget("DWH_Daily_Process__SP_Dim_Position_AutoPOC", required_success=True),
    JobTarget("DWH_Daily_Process__SP_Dim_Mirror_AutoPOC"),
    JobTarget("DWH_Daily_Process__SP_Fact_CurrencyPriceWithSplit_AutoPOC"),
    JobTarget("DWH_Daily_Process__SP_Fact_Deposit_State_AutoPOC"),
]


def _find_job_id(w: WorkspaceClient, name: str) -> int | None:
    for j in w.jobs.list(name=name):
        if j.settings and j.settings.name == name and j.job_id is not None:
            return int(j.job_id)
    return None


def _wait_run(w: WorkspaceClient, run_id: int, timeout_sec: int = 1800) -> dict[str, object]:
    start = time.time()
    while True:
        run = w.jobs.get_run(run_id=run_id)
        state = run.state
        life = state.life_cycle_state.value if state and state.life_cycle_state else "UNKNOWN"
        result = state.result_state.value if state and state.result_state else "NONE"
        if life in {"TERMINATED", "INTERNAL_ERROR", "SKIPPED"}:
            task_states = []
            for t in run.tasks or []:
                ts = t.state
                task_states.append(
                    {
                        "task_key": t.task_key,
                        "life_cycle_state": ts.life_cycle_state.value if ts and ts.life_cycle_state else None,
                        "result_state": ts.result_state.value if ts and ts.result_state else None,
                        "run_id": int(t.run_id) if t.run_id is not None else None,
                    }
                )
            return {
                "run_id": run_id,
                "life_cycle_state": life,
                "result_state": result,
                "state_message": state.state_message if state else None,
                "task_states": task_states,
            }
        if time.time() - start > timeout_sec:
            return {
                "run_id": run_id,
                "life_cycle_state": life,
                "result_state": result,
                "state_message": f"timeout after {timeout_sec}s",
                "task_states": [],
            }
        time.sleep(10)


def _task_error_map(w: WorkspaceClient, task_states: list[dict[str, object]]) -> dict[str, str]:
    out: dict[str, str] = {}
    for t in task_states:
        if t.get("result_state") != "FAILED":
            continue
        run_id = t.get("run_id")
        if not run_id:
            continue
        try:
            o = w.jobs.get_run_output(run_id=int(run_id))
            out[str(t["task_key"])] = str(o.error or "")
        except Exception as exc:
            out[str(t["task_key"])] = f"failed to fetch run output: {exc}"
    return out


def main() -> int:
    w = WorkspaceClient(profile="guyman")
    batch = []
    for target in TARGETS:
        job_id = _find_job_id(w, target.name)
        if job_id is None:
            batch.append({"job_name": target.name, "status": "missing"})
            continue
        run_now = w.jobs.run_now(job_id=job_id)
        run_id = int(run_now.response.run_id)
        done = _wait_run(w, run_id)
        done["job_name"] = target.name
        done["job_id"] = job_id
        done["required_success"] = target.required_success
        done["task_errors"] = _task_error_map(w, done["task_states"])
        batch.append(done)
    print(json.dumps(batch, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
