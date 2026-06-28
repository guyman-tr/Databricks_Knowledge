#!/usr/bin/env python3
"""Create/update block-level DAG job for Fact_SnapshotEquity flow."""
from __future__ import annotations

import json

from orchestration import SqlTaskSpec, create_or_update_sql_job

WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_snapshotequity_dag"
JOB_NAME = "DWH_Daily_Process__Fact_SnapshotEquity_DAG_AutoPOC"

def main() -> int:
    sql_files = {
        "01_preflight_restore.sql": """
DECLARE v_restore_version BIGINT;
SET VAR v_restore_version = (
  SELECT COALESCE(
    MAX(CASE
      WHEN timestamp <= CAST(date_format(DATEADD(DAY, -1, current_timestamp()), 'yyyy-MM-dd 23:59:59') AS TIMESTAMP)
       AND timestamp >= DATEADD(HOUR, -167, current_timestamp())
      THEN version END),
    MAX(CASE WHEN timestamp >= DATEADD(HOUR, -167, current_timestamp()) THEN version END)
  )
  FROM (DESCRIBE HISTORY dwh_daily_process.migration_tables.fact_snapshotequity)
);
EXECUTE IMMEDIATE COALESCE(
  'RESTORE TABLE dwh_daily_process.migration_tables.fact_snapshotequity TO VERSION AS OF '
  || CAST(v_restore_version AS STRING),
  'SELECT 1'
);
""".strip()
        + "\n",
        "02_snapshot_guard.sql": """
SELECT
  current_date() AS run_date,
  DATEADD(DAY, -1, current_date()) AS target_date,
  (SELECT MAX(DATE(CAST(Occurred AS TIMESTAMP))) FROM dwh_daily_process.daily_snapshot.etoro_History_Credit) AS max_history_credit_date,
  (SELECT MAX(DATE(CAST(Occurred AS TIMESTAMP))) FROM dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay) AS max_open_position_date;
""".strip()
        + "\n",
        "03_extract.sql": """
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_extract_autopoc(
  CAST(DATEADD(DAY, -1, current_date()) AS TIMESTAMP)
);
""".strip()
        + "\n",
        "04_validate_extract.sql": """
SELECT
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_history_credit) AS ext_fse_history_credit_rows,
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_trade_position) AS ext_fse_trade_position_rows;
""".strip()
        + "\n",
        "05_inprocess.sql": """
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_inprocesscashouts_autopoc(
  CAST(DATEADD(DAY, -1, current_date()) AS TIMESTAMP)
);
""".strip()
        + "\n",
        "06_totalposition.sql": """
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_totalpositionamount_autopoc(
  CAST(DATEADD(DAY, -1, current_date()) AS TIMESTAMP)
);
""".strip()
        + "\n",
        "07_core.sql": """
CALL dwh_daily_process.migration_tables.sp_fact_snapshotequity_autopoc(
  CAST(DATEADD(DAY, -1, current_date()) AS TIMESTAMP)
);
""".strip()
        + "\n",
        "08_qa_probe.sql": """
WITH mig_max AS (
  SELECT MAX(CAST(LEFT(CAST(DateRangeID AS STRING), 8) AS INT)) AS d
  FROM dwh_daily_process.migration_tables.fact_snapshotequity
),
gold_max AS (
  SELECT MAX(CAST(LEFT(CAST(DateRangeID AS STRING), 8) AS INT)) AS d
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
),
common_date AS (
  SELECT LEAST(mig_max.d, gold_max.d) AS d FROM mig_max CROSS JOIN gold_max
),
mig AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalCash, 0) AS DECIMAL(38,10))) AS sum_totalcash
  FROM dwh_daily_process.migration_tables.fact_snapshotequity
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = CAST((SELECT d FROM common_date) AS STRING)
),
gold AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(CAST(COALESCE(TotalCash, 0) AS DECIMAL(38,10))) AS sum_totalcash
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
  WHERE LEFT(CAST(DateRangeID AS STRING), 8) = CAST((SELECT d FROM common_date) AS STRING)
)
SELECT
  (SELECT d FROM common_date) AS common_date_id,
  mig.rows_cnt AS migration_rows,
  gold.rows_cnt AS gold_rows,
  (mig.rows_cnt - gold.rows_cnt) AS delta_rows,
  mig.sum_totalcash AS migration_sum_totalcash,
  gold.sum_totalcash AS gold_sum_totalcash,
  (mig.sum_totalcash - gold.sum_totalcash) AS delta_sum_totalcash
FROM mig CROSS JOIN gold;
""".strip()
        + "\n",
    }

    task_specs = [
        SqlTaskSpec(
            task_key="preflight_restore",
            sql_filename="01_preflight_restore.sql",
            sql_text=sql_files["01_preflight_restore.sql"],
        ),
        SqlTaskSpec(
            task_key="snapshot_guard",
            sql_filename="02_snapshot_guard.sql",
            sql_text=sql_files["02_snapshot_guard.sql"],
            depends_on=("preflight_restore",),
        ),
        SqlTaskSpec(
            task_key="extract_staging",
            sql_filename="03_extract.sql",
            sql_text=sql_files["03_extract.sql"],
            depends_on=("snapshot_guard",),
        ),
        SqlTaskSpec(
            task_key="validate_extract",
            sql_filename="04_validate_extract.sql",
            sql_text=sql_files["04_validate_extract.sql"],
            depends_on=("extract_staging",),
        ),
        SqlTaskSpec(
            task_key="inprocesscashouts",
            sql_filename="05_inprocess.sql",
            sql_text=sql_files["05_inprocess.sql"],
            depends_on=("validate_extract",),
        ),
        SqlTaskSpec(
            task_key="totalpositionamount",
            sql_filename="06_totalposition.sql",
            sql_text=sql_files["06_totalposition.sql"],
            depends_on=("validate_extract",),
        ),
        SqlTaskSpec(
            task_key="core_apply",
            sql_filename="07_core.sql",
            sql_text=sql_files["07_core.sql"],
            depends_on=("inprocesscashouts", "totalpositionamount"),
        ),
        SqlTaskSpec(
            task_key="qa_probe",
            sql_filename="08_qa_probe.sql",
            sql_text=sql_files["08_qa_probe.sql"],
            depends_on=("core_apply",),
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
