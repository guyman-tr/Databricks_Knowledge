#!/usr/bin/env python3
"""Create (and optionally run) the SCD daily-snapshot job.

WHY THIS EXISTS
---------------
Derived facts (e.g. fact_guru_copiers) are recomputed in migration from upstream
SCD / snapshot inputs (e.g. Fact_SnapshotCustomer). Gold's derived facts are FROZEN
outputs built from those inputs at a past as-of moment. Delta time travel cannot
reproduce that as-of state (sources may be non-Delta; the exact version/timestamp
gold used is unknown and likely outside Delta retention; and the input membership
keeps drifting forward). The fix is to STOP the inputs from drifting: snapshot the
SCD tables from the gold mirror so migration's inputs == gold's inputs, then run the
derived-fact jobs the SAME DAY. This repairs forward daily runs; it does NOT
retroactively fix already-drifted historical slices.

Each table is copied with CREATE OR REPLACE TABLE ... AS SELECT * FROM <gold mirror>,
i.e. a full-overwrite snapshot that also forces migration's schema to match gold.

Manual trigger only (no schedule) — run on demand via --run or run_block_job-style.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import time

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from databricks.sdk import WorkspaceClient

from tools.migration_autoloop.orchestration import SqlTaskSpec, create_or_update_sql_job

WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_scd_snapshot"
JOB_NAME = "DWH_Daily_Process__SCD_SNAPSHOT__AutoPOC"
PROFILE = "guyman"

# migration target table  ->  gold mirror source table
# Add more rows here to extend the snapshot set.
# NOTE: fact_snapshotequity has NO gold base TABLE — its gold surface is the date-
# partitioned (etr_ymd) EXTERNAL Parquet object v_fact_snapshotequity_fromdateid, which
# is fresh to yesterday. Migration's matching object is its own v_fact_snapshotequity_fromdateid
# (verified bit-exact vs gold at the common day 2026-05-22; only stale, not wrong).
SCD_TABLES: dict[str, str] = {
    "dwh_daily_process.migration_tables.fact_snapshotcustomer": "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer",
    "dwh_daily_process.migration_tables.v_fact_snapshotequity_fromdateid": "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid",
}


def _copy_sql(target: str, source: str) -> str:
    return (
        f"-- SCD snapshot: full-overwrite copy of gold mirror into migration.\n"
        f"-- Makes migration input identical to gold input as of the run moment.\n"
        f"CREATE OR REPLACE TABLE {target} AS SELECT * FROM {source};\n"
    )


def _task_key(target: str) -> str:
    return "snap_" + target.split(".")[-1].lower()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", action="store_true", help="trigger the job once after create/update")
    args = ap.parse_args()

    specs: list[SqlTaskSpec] = []
    for target, source in SCD_TABLES.items():
        tk = _task_key(target)
        specs.append(
            SqlTaskSpec(
                task_key=tk,
                sql_filename=f"{tk}.sql",
                sql_text=_copy_sql(target, source),
            )
        )

    payload = create_or_update_sql_job(
        profile=PROFILE,
        job_name=JOB_NAME,
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir=WORKSPACE_SQL_DIR,
        task_specs=specs,
        max_concurrent_runs=1,
    )
    payload["table_count"] = len(specs)
    print(json.dumps(payload, indent=2))

    if args.run:
        w = WorkspaceClient(profile=PROFILE)
        run = w.jobs.run_now(job_id=int(payload["job_id"]))
        run_id = int(run.run_id)
        print(json.dumps({"triggered_run_id": run_id}, indent=2))
        deadline = time.time() + 3600
        while time.time() < deadline:
            r = w.jobs.get_run(run_id=run_id)
            life = r.state.life_cycle_state.value if r.state and r.state.life_cycle_state else "?"
            if life in {"TERMINATED", "SKIPPED", "INTERNAL_ERROR"}:
                result = r.state.result_state.value if r.state and r.state.result_state else "?"
                print(json.dumps({"run_id": run_id, "life_cycle_state": life, "result_state": result}, indent=2))
                return 0 if result == "SUCCESS" else 2
            time.sleep(15)
        print(json.dumps({"run_id": run_id, "life_cycle_state": "TIMEOUT_WAIT"}, indent=2))
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
