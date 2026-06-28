#!/usr/bin/env python3
"""Create/update block-level DAG job for Fact_SnapshotCustomer flow."""
from __future__ import annotations

import json

from orchestration import SqlTaskSpec, create_or_update_sql_job

WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_snapshotcustomer_dag"
JOB_NAME = "DWH_Daily_Process__Fact_SnapshotCustomer_DAG_AutoPOC"

def main() -> int:
    sql_files = {
        "01_snapshot_guard.sql": """
SELECT
  current_date() AS run_date,
  DATEADD(DAY, -1, current_date()) AS target_date,
  (SELECT MAX(DATE(CAST(ValidFrom AS TIMESTAMP))) FROM dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer) AS max_backofficecustomer_date,
  (SELECT MAX(DATE(CAST(ValidFrom AS TIMESTAMP))) FROM dwh_daily_process.daily_snapshot.etoro_History_Customer) AS max_customer_history_date;
""".strip()
        + "\n",
        "02_run_wrapper.sql": """
CALL dwh_daily_process.migration_tables.sp_fact_snapshotcustomer_dl_to_synapse_autopoc(
  CAST(DATEADD(DAY, -1, current_date()) AS TIMESTAMP)
);
""".strip()
        + "\n",
        "03_qa_probe.sql": """
WITH t AS (
  SELECT date_format(DATEADD(DAY, -1, current_date()), 'yyyyMMdd') AS dt
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(CAST(IsDepositor AS INT), 0) AS DECIMAL(38,10))) AS sum_isdepositor
  FROM dwh_daily_process.migration_tables.fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT dt FROM t)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(CAST(IsDepositor AS INT), 0) AS DECIMAL(38,10))) AS sum_isdepositor
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = (SELECT dt FROM t)
)
SELECT
  (SELECT dt FROM t) AS target_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  (mig.rows_cnt - gold.rows_cnt) AS delta_rows,
  mig.sum_isdepositor AS migration_sum_isdepositor,
  gold.sum_isdepositor AS gold_sum_isdepositor,
  (mig.sum_isdepositor - gold.sum_isdepositor) AS delta_sum_isdepositor
FROM mig CROSS JOIN gold;
""".strip()
        + "\n",
    }

    task_specs = [
        SqlTaskSpec(
            task_key="snapshot_guard",
            sql_filename="01_snapshot_guard.sql",
            sql_text=sql_files["01_snapshot_guard.sql"],
        ),
        SqlTaskSpec(
            task_key="run_fact_snapshotcustomer_wrapper",
            sql_filename="02_run_wrapper.sql",
            sql_text=sql_files["02_run_wrapper.sql"],
            depends_on=("snapshot_guard",),
        ),
        SqlTaskSpec(
            task_key="qa_probe",
            sql_filename="03_qa_probe.sql",
            sql_text=sql_files["03_qa_probe.sql"],
            depends_on=("run_fact_snapshotcustomer_wrapper",),
        ),
    ]

    payload = create_or_update_sql_job(
        profile="guyman",
        job_name=JOB_NAME,
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir=WORKSPACE_SQL_DIR,
        task_specs=task_specs,
    )

    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
