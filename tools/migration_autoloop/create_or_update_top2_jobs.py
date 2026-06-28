#!/usr/bin/env python3
"""Create/update AutoPOC jobs for top-2 next flows."""
from __future__ import annotations

import json
from dataclasses import dataclass

from orchestration import SqlTaskSpec, create_or_update_sql_job

WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_top2_autopoc"


@dataclass(frozen=True)
class ProcJobDef:
    job_name: str
    run_sql_filename: str
    run_sql_text: str
    trace_sql_filename: str | None
    trace_sql_text: str | None
    qa_probe_sql_filename: str
    qa_probe_sql_text: str
    parity_gate_sql_filename: str
    parity_gate_sql_text: str


DEFS: tuple[ProcJobDef, ...] = (
    ProcJobDef(
        job_name="DWH_Daily_Process__SP_Dictionaries_AutoPOC",
        run_sql_filename="02_sp_dictionaries_dl_to_synapse_autopoc.sql",
        run_sql_text="CALL dwh_daily_process.migration_tables.sp_dictionaries_dl_to_synapse_autopoc();\n",
        trace_sql_filename=None,
        trace_sql_text=None,
        qa_probe_sql_filename="03_qa_dictionaries.sql",
        qa_probe_sql_text="""
SELECT
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_country) AS migration_rows,
  (SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country) AS gold_rows;
""".strip()
        + "\n",
        parity_gate_sql_filename="04_parity_gate_dictionaries.sql",
        parity_gate_sql_text="""
WITH c AS (
  SELECT
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_country) AS migration_rows,
    (SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country) AS gold_rows
)
SELECT CASE
  WHEN migration_rows = gold_rows THEN 'PARITY_PASS'
  ELSE raise_error(
    concat(
      'PARITY_FAIL dictionaries dim_country count mismatch: migration=',
      CAST(migration_rows AS STRING),
      ', gold=',
      CAST(gold_rows AS STRING)
    )
  )
END AS parity_status
FROM c;
""".strip()
        + "\n",
    ),
    ProcJobDef(
        job_name="DWH_Daily_Process__SP_Dim_Position_AutoPOC",
        run_sql_filename="02_sp_dim_position_dl_to_synapse_autopoc.sql",
        run_sql_text=(
            "CALL dwh_daily_process.migration_tables.sp_dim_position_dl_to_synapse_autopoc("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        ),
        trace_sql_filename="03_sp_trace_dim_position.sql",
        trace_sql_text="""
SELECT
  lower(regexp_extract(statement_text, 'call\\s+[^\\.]+\\.[^\\.]+\\.([^\\(\\s]+)', 1)) AS called_proc,
  COUNT(*) AS calls_last_2h
FROM system.query.history
WHERE start_time >= DATEADD(HOUR, -2, current_timestamp())
  AND lower(statement_text) LIKE 'call dwh_daily_process.migration_tables.sp_dim_position%'
GROUP BY 1
ORDER BY calls_last_2h DESC, called_proc;
""".strip()
        + "\n",
        qa_probe_sql_filename="04_qa_dim_position.sql",
        qa_probe_sql_text="""
WITH bounds AS (
  SELECT LEAST(
    (SELECT MAX(OpenDateID) FROM dwh_daily_process.migration_tables.dim_position),
    (SELECT MAX(OpenDateID) FROM main.dwh.dim_position)
  ) AS common_open_date
),
agg AS (
  SELECT
    b.common_open_date,
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_rows,
    (SELECT COUNT(*) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_rows,
    (SELECT ROUND(COALESCE(SUM(COALESCE(m.Amount, 0.0)), 0.0), 6) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_sum_amount,
    (SELECT ROUND(COALESCE(SUM(COALESCE(g.Amount, 0.0)), 0.0), 6) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_sum_amount,
    (SELECT ROUND(COALESCE(SUM(COALESCE(m.CommissionOnClose, 0.0)), 0.0), 6) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_sum_commission_on_close,
    (SELECT ROUND(COALESCE(SUM(COALESCE(g.CommissionOnClose, 0.0)), 0.0), 6) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_sum_commission_on_close
  FROM bounds b
)
SELECT * FROM agg;
""".strip()
        + "\n",
        parity_gate_sql_filename="05_parity_gate_dim_position.sql",
        parity_gate_sql_text="""
WITH bounds AS (
  SELECT LEAST(
    (SELECT MAX(OpenDateID) FROM dwh_daily_process.migration_tables.dim_position),
    (SELECT MAX(OpenDateID) FROM main.dwh.dim_position)
  ) AS common_open_date
),
agg AS (
  SELECT
    b.common_open_date,
    (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_rows,
    (SELECT COUNT(*) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_rows,
    (SELECT ROUND(COALESCE(SUM(COALESCE(m.Amount, 0.0)), 0.0), 6) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_sum_amount,
    (SELECT ROUND(COALESCE(SUM(COALESCE(g.Amount, 0.0)), 0.0), 6) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_sum_amount,
    (SELECT ROUND(COALESCE(SUM(COALESCE(m.CommissionOnClose, 0.0)), 0.0), 6) FROM dwh_daily_process.migration_tables.dim_position m WHERE m.OpenDateID = b.common_open_date) AS migration_sum_commission_on_close,
    (SELECT ROUND(COALESCE(SUM(COALESCE(g.CommissionOnClose, 0.0)), 0.0), 6) FROM main.dwh.dim_position g WHERE g.OpenDateID = b.common_open_date) AS gold_sum_commission_on_close
  FROM bounds b
)
SELECT CASE
  WHEN migration_rows = gold_rows
    AND ABS(migration_sum_amount - gold_sum_amount) < 0.0001
    AND ABS(migration_sum_commission_on_close - gold_sum_commission_on_close) < 0.0001
  THEN concat('PARITY_PASS common_open_date=', CAST(common_open_date AS STRING))
  ELSE raise_error(
    concat(
      'PARITY_FAIL dim_position common_open_date=',
      CAST(common_open_date AS STRING),
      ' migration_rows=',
      CAST(migration_rows AS STRING),
      ' gold_rows=',
      CAST(gold_rows AS STRING),
      ' migration_sum_amount=',
      CAST(migration_sum_amount AS STRING),
      ' gold_sum_amount=',
      CAST(gold_sum_amount AS STRING),
      ' migration_sum_commission_on_close=',
      CAST(migration_sum_commission_on_close AS STRING),
      ' gold_sum_commission_on_close=',
      CAST(gold_sum_commission_on_close AS STRING)
    )
  )
END AS parity_status
FROM agg;
""".strip()
        + "\n",
    ),
)


def _task_specs(d: ProcJobDef) -> list[SqlTaskSpec]:
    specs = [
        SqlTaskSpec(
            task_key="snapshot_guard",
            sql_filename="01_snapshot_guard.sql",
            sql_text=(
                "SELECT current_date() AS run_date, DATEADD(DAY, -1, current_date()) AS target_date;\n"
            ),
        ),
        SqlTaskSpec(
            task_key="run_proc",
            sql_filename=d.run_sql_filename,
            sql_text=d.run_sql_text,
            depends_on=("snapshot_guard",),
        ),
    ]

    qa_dep = "run_proc"
    if d.trace_sql_filename and d.trace_sql_text:
        specs.append(
            SqlTaskSpec(
                task_key="sp_trace",
                sql_filename=d.trace_sql_filename,
                sql_text=d.trace_sql_text,
                depends_on=("run_proc",),
            )
        )
        qa_dep = "sp_trace"

    specs.extend(
        [
            SqlTaskSpec(
                task_key="qa_probe",
                sql_filename=d.qa_probe_sql_filename,
                sql_text=d.qa_probe_sql_text,
                depends_on=(qa_dep,),
            ),
            SqlTaskSpec(
                task_key="parity_gate",
                sql_filename=d.parity_gate_sql_filename,
                sql_text=d.parity_gate_sql_text,
                depends_on=("qa_probe",),
            ),
        ]
    )
    return specs


def main() -> int:
    out = []
    for d in DEFS:
        payload = create_or_update_sql_job(
            profile="guyman",
            job_name=d.job_name,
            warehouse_id=WAREHOUSE_ID,
            workspace_sql_dir=WORKSPACE_SQL_DIR,
            task_specs=_task_specs(d),
        )
        out.append(payload)

    print(json.dumps({"jobs": out}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
