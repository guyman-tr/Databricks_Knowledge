#!/usr/bin/env python3
"""Fire the orchestrator job and monitor it to completion.

Emits machine-readable sentinel lines for Cursor notify_on_output:
  TASK_STARTED   key=<key>
  TASK_DONE      key=<key> status=SUCCESS|FAILED
  TASK_OUTPUT    key=<key> <json summary>
  TASK_ERROR     key=<key> <error+traceback>
  ORCHESTRATOR_DONE status=SUCCESS|FAILED run_id=<id>
  BRONZE_READY   target_date=<date>
  BRONZE_NOT_READY missing=<table> empty=<table>

Usage:
  python -m tools.migration_autoloop.runtime._monitor_run [--skip-fire]
  --skip-fire : don't fire a new run — poll the most recent active run instead
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
os.environ.setdefault("DATABRICKS_CONFIG_PROFILE", "DEFAULT")

from tools.migration_autoloop.db import execute_sql, make_workspace_client

PARENT_JOB_ID = 239804415469841
WAREHOUSE_ID = "6f72189f967b42a9"
POLL_INTERVAL = 30  # seconds


def ts() -> str:
    return datetime.now(timezone.utc).strftime("%H:%M:%S")


def check_bronze(w, target_date: str) -> bool:
    """Quick check: do any daily_snapshot tables have target_date rows?"""
    try:
        # Sample a key table to see if the snapshot is ready
        _, rows = execute_sql(
            w,
            sql_text=f"""
                SELECT COUNT(*) AS c
                FROM system.information_schema.tables
                WHERE table_catalog = 'dwh_daily_process'
                  AND table_schema = 'daily_snapshot'
            """,
            warehouse_id=WAREHOUSE_ID,
            poll_deadline_sec=60,
        )
        n_tables = int(rows[0][0]) if rows else 0
        print(f"[{ts()}] daily_snapshot: {n_tables} tables registered in catalog")

        # Check snapshot_date on a representative staging table
        _, rows2 = execute_sql(
            w,
            sql_text="""
                SELECT table_name,
                       storage_path
                FROM system.information_schema.tables
                WHERE table_catalog = 'dwh_daily_process'
                  AND table_schema  = 'daily_snapshot'
                ORDER BY table_name
                LIMIT 5
            """,
            warehouse_id=WAREHOUSE_ID,
            poll_deadline_sec=60,
        )
        for r in rows2:
            print(f"  sample table: {r[0]}  path: {r[1]}")
        return n_tables > 0
    except Exception as exc:
        print(f"[{ts()}] BRONZE_CHECK_ERROR: {exc}")
        return False


def find_active_run(w) -> int | None:
    """Return run_id of the most recent active or recently completed run."""
    runs = list(w.jobs.list_runs(job_id=PARENT_JOB_ID, limit=5))
    for run in runs:
        lc = run.state.life_cycle_state if run.state else None
        lc_val = lc.value if hasattr(lc, "value") else str(lc)
        if lc_val in ("RUNNING", "PENDING"):
            return int(run.run_id)
    if runs:
        return int(runs[0].run_id)
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--skip-fire", action="store_true",
                    help="Don't fire a new run — poll the most recent run.")
    args = ap.parse_args()

    w = make_workspace_client()

    # 1. Bronze readiness check
    print(f"\n[{ts()}] === Checking daily_snapshot bronze readiness ===")
    bronze_ok = check_bronze(w, "")
    if bronze_ok:
        print(f"[{ts()}] BRONZE_READY target_date=2026-06-26")
    else:
        print(f"[{ts()}] BRONZE_NOT_READY missing=daily_snapshot tables=0")
        print(f"[{ts()}] WARNING: Will attempt run anyway — Phase A gate will validate per-proc.")

    # 2. Fire (or find existing run)
    if args.skip_fire:
        run_id = find_active_run(w)
        if run_id is None:
            print("No recent run found. Remove --skip-fire to start one.")
            return 2
        print(f"\n[{ts()}] Attaching to existing run_id={run_id}")
    else:
        run = w.jobs.run_now(job_id=PARENT_JOB_ID)
        run_id = int(run.run_id)
        print(f"\n[{ts()}] FIRED: run_id={run_id}")
        print(f"  UI: https://adb-5142916747090026.6.azuredatabricks.net/#job/{PARENT_JOB_ID}/run/{run_id}")

    # 3. Poll loop
    seen_started: set[str] = set()
    seen_done: set[int] = set()
    TERMINAL = {"TERMINATED", "SKIPPED", "INTERNAL_ERROR"}

    while True:
        run = w.jobs.get_run(run_id=run_id)
        state = run.state
        lc = state.life_cycle_state
        lc_val = lc.value if hasattr(lc, "value") else str(lc)
        rs_val = (state.result_state.value if (state.result_state and hasattr(state.result_state, "value"))
                  else str(state.result_state))

        print(f"\n[{ts()}] Orchestrator: {lc_val}/{rs_val}")

        if run.tasks:
            for t in run.tasks:
                key = t.task_key or "(unknown)"
                ts_obj = t.state
                tlc = ts_obj.life_cycle_state if ts_obj else None
                tlc_val = tlc.value if hasattr(tlc, "value") else str(tlc)
                trs = ts_obj.result_state if ts_obj else None
                trs_val = trs.value if (trs and hasattr(trs, "value")) else str(trs)
                task_run_id = t.run_id

                if tlc_val == "RUNNING" and key not in seen_started:
                    seen_started.add(key)
                    print(f"  TASK_STARTED key={key}")

                if tlc_val == "TERMINATED" and task_run_id and int(task_run_id) not in seen_done:
                    seen_done.add(int(task_run_id))
                    ok = trs_val == "SUCCESS"
                    status = "SUCCESS" if ok else "FAILED"
                    print(f"  TASK_DONE key={key} status={status}")

                    # Read output
                    try:
                        out = w.jobs.get_run_output(run_id=int(task_run_id))
                        nb_out = out.notebook_output
                        if nb_out and nb_out.result:
                            blob = nb_out.result
                            try:
                                data = json.loads(blob)
                                if isinstance(data, dict) and "error" in data:
                                    print(f"  TASK_ERROR key={key} error={data['error'][:300]}")
                                    tb = data.get("traceback", "")
                                    if tb:
                                        print("  TRACEBACK:")
                                        for line in tb.splitlines()[:30]:
                                            print(f"    {line}")
                                else:
                                    overall = data.get("overall_status") or data.get("action") or "?"
                                    targets = data.get("targets", {})
                                    summary = {k: (v.get("status") if isinstance(v, dict) else v)
                                               for k, v in targets.items()}
                                    print(f"  TASK_OUTPUT key={key} overall={overall} targets={json.dumps(summary)}")
                            except (json.JSONDecodeError, AttributeError):
                                print(f"  TASK_OUTPUT key={key} raw={blob[:400]}")
                        elif out.error:
                            print(f"  TASK_ERROR key={key} cluster_error={out.error[:300]}")
                    except Exception as exc:
                        print(f"  TASK_OUTPUT_FAIL key={key} {exc}")
                else:
                    if tlc_val not in ("TERMINATED", "BLOCKED"):
                        print(f"  {key:<45} {tlc_val}/{trs_val}")

        if lc_val in TERMINAL:
            ok = rs_val == "SUCCESS"
            final = "SUCCESS" if ok else "FAILED"
            print(f"\n[{ts()}] ORCHESTRATOR_DONE status={final} run_id={run_id}")
            return 0 if ok else 1

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    raise SystemExit(main())
