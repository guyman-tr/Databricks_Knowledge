#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.orchestration import SqlTaskSpec, create_or_update_sql_job


WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_restored"
JOB_NAME = "DWH_Daily_Process__SP_Dim_Customer"


def main() -> int:
    specs = [
        SqlTaskSpec(
            task_key="snapshot_guard",
            sql_filename="dim_customer_01_snapshot_guard.sql",
            sql_text="SELECT current_date() AS run_date;\n",
        ),
        SqlTaskSpec(
            task_key="run_proc",
            sql_filename="dim_customer_02_run_proc.sql",
            sql_text="CALL dwh_daily_process.migration_tables.sp_dim_customer();\n",
            depends_on=("snapshot_guard",),
        ),
        SqlTaskSpec(
            task_key="qa_probe",
            sql_filename="dim_customer_03_qa_probe.sql",
            sql_text=(
                "SELECT "
                "(SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_customer) AS migration_rows, "
                "(SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked) AS gold_rows;\n"
            ),
            depends_on=("run_proc",),
        ),
    ]
    payload = create_or_update_sql_job(
        profile="guyman",
        job_name=JOB_NAME,
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir=WORKSPACE_SQL_DIR,
        task_specs=specs,
    )
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

