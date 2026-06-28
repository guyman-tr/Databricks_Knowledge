#!/usr/bin/env python3
"""Loop orchestrator for fact_snapshotequity.

Sequence (matches the intended POC loop):
  1. detect whether the prior-day baseline is missing/corrupt in the migration schema
  2. if so, reseed it on the SIDE (POC-only bootstrap) -- the job itself stays clean
  3. proceed as if the data was there all along: run the production-shaped job
  4. read the parity gate result and report honestly (no masking inside the job)
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import time
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import make_workspace_client
from tools.migration_autoloop.runtime.prepare_snapshot_baseline import (
    clear_target_day_pollution,
    ensure_prior_day_baseline,
    purge_corrupt_rows,
)

JOB_ID = 660422186057164
PARITY_TASK = "s08_parity_gate"


def _target_date(arg: str | None) -> dt.date:
    if arg:
        return dt.date.fromisoformat(arg)
    return dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)


def run_job_and_wait(w, job_id: int, deadline_sec: float = 3600.0) -> dict:
    run = w.jobs.run_now(job_id=job_id)
    rid = int(run.response.run_id)
    start = time.time()
    while time.time() - start < deadline_sec:
        r = w.jobs.get_run(run_id=rid)
        s = r.state
        life = s.life_cycle_state.value if s and s.life_cycle_state else "UNKNOWN"
        if life in {"TERMINATED", "INTERNAL_ERROR", "SKIPPED"}:
            tasks = {}
            for t in (r.tasks or []):
                ts = t.state
                tasks[t.task_key] = {
                    "result_state": ts.result_state.value if ts and ts.result_state else None,
                    "run_id": int(t.run_id) if t.run_id is not None else None,
                }
            return {
                "run_id": rid,
                "life_cycle_state": life,
                "result_state": s.result_state.value if s and s.result_state else None,
                "tasks": tasks,
            }
        time.sleep(10)
    return {"run_id": rid, "life_cycle_state": "TIMEOUT", "tasks": {}}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD; default = yesterday UTC.")
    args = ap.parse_args()
    target = _target_date(args.target_date.strip() or None)

    w = make_workspace_client()

    # Step 1+2: side-action precondition repair (POC-only; not part of the job DAG).
    #   a) purge malformed DateRangeID rows left by earlier buggy runs (they shadow CIDs)
    #   b) bootstrap a clean prior-day baseline (the snapshot prod would already have)
    #   c) clear leftover target-day rows from prior POC reruns (prod never pre-has today)
    corrupt_purge = purge_corrupt_rows(apply=True)
    baseline = ensure_prior_day_baseline(target_date=target, apply=True)
    target_cleanup = clear_target_day_pollution(target_date=target, apply=True)

    # Step 3: proceed as if data was there all along -- run the clean production-shaped job.
    job = run_job_and_wait(w, JOB_ID)

    # Step 4: report parity honestly.
    parity = job.get("tasks", {}).get(PARITY_TASK, {})
    parity_message = None
    if parity.get("run_id"):
        try:
            o = w.jobs.get_run_output(run_id=parity["run_id"])
            parity_message = getattr(o, "error", None)
        except Exception as exc:  # parity success returns no error payload
            parity_message = f"(no error payload: {exc})"

    report = {
        "corrupt_purge": corrupt_purge,
        "baseline_side_repair": baseline,
        "target_day_cleanup": target_cleanup,
        "job_run": job,
        "parity_gate_result": parity.get("result_state"),
        "parity_gate_message": parity_message,
        "e2e_success": job.get("result_state") == "SUCCESS",
    }
    print(json.dumps(report, indent=2, default=str))
    return 0 if report["e2e_success"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
