#!/usr/bin/env python3
"""Trigger a block's Databricks Job (created by create_or_update_block_job.py) and wait.

Finds the job by the canonical block-job name, runs it now, polls to completion,
and prints per-task result states plus the parity-gate task's output message.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from databricks.sdk import WorkspaceClient

from tools.migration_autoloop.adf_block_catalog import ADF_BLOCKS


def _job_name(block_id: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_]+", "_", block_id)
    return f"DWH_Daily_Process__BLOCK__{safe}__AutoPOC"


def _find_job_id(w: WorkspaceClient, name: str) -> int | None:
    for j in w.jobs.list(name=name):
        if j.settings and j.settings.name == name and j.job_id is not None:
            return int(j.job_id)
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--block-id", required=True, choices=sorted(ADF_BLOCKS.keys()))
    ap.add_argument("--timeout-sec", type=float, default=1500.0)
    args = ap.parse_args()

    w = WorkspaceClient(profile="guyman")
    name = _job_name(args.block_id)
    job_id = _find_job_id(w, name)
    if job_id is None:
        print(json.dumps({"status": "missing", "job_name": name}))
        return 1

    run_id = int(w.jobs.run_now(job_id=job_id).response.run_id)
    host = (w.config.host or "").rstrip("/")
    deadline = time.time() + args.timeout_sec
    while time.time() < deadline:
        run = w.jobs.get_run(run_id=run_id)
        st = run.state
        life = st.life_cycle_state.value if st and st.life_cycle_state else "UNKNOWN"
        if life in {"TERMINATED", "INTERNAL_ERROR", "SKIPPED"}:
            break
        time.sleep(10)

    run = w.jobs.get_run(run_id=run_id)
    st = run.state
    out: dict[str, object] = {
        "job_name": name,
        "job_id": job_id,
        "run_id": run_id,
        "run_url": f"{host}/jobs/{job_id}/runs/{run_id}",
        "life_cycle_state": st.life_cycle_state.value if st and st.life_cycle_state else None,
        "result_state": st.result_state.value if st and st.result_state else None,
        "tasks": [],
    }
    for t in run.tasks or []:
        ts = t.state
        rec: dict[str, object] = {
            "task_key": t.task_key,
            "result_state": ts.result_state.value if ts and ts.result_state else None,
        }
        if t.run_id is not None and t.task_key and "parity" in t.task_key:
            try:
                o = w.jobs.get_run_output(run_id=int(t.run_id))
                rec["message"] = getattr(o, "error", None) or getattr(o, "logs", None)
            except Exception as exc:  # noqa: BLE001
                rec["message"] = str(exc)
        if (rec.get("result_state") == "FAILED") and t.run_id is not None:
            try:
                rec["error"] = w.jobs.get_run_output(run_id=int(t.run_id)).error
            except Exception as exc:  # noqa: BLE001
                rec["error"] = str(exc)
        out["tasks"].append(rec)
    print(json.dumps(out, indent=2, default=str))
    return 0 if out["result_state"] == "SUCCESS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
