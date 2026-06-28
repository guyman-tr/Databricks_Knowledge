#!/usr/bin/env python3
"""Create/update Databricks SQL jobs for selected migration flows."""
from __future__ import annotations

import json
from dataclasses import dataclass

from orchestration import SqlTaskSpec, create_or_update_sql_job

WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs"
DEFAULT_WAREHOUSE_ID = "6f72189f967b42a9"


@dataclass(frozen=True)
class FlowJobDef:
    flow_id: str
    job_name: str
    run_sql_filename: str
    procedure_name: str
    migration_table: str
    gold_table: str


FLOW_JOBS: tuple[FlowJobDef, ...] = (
    FlowJobDef(
        flow_id="dim_mirror",
        job_name="DWH_Daily_Process__SP_Dim_Mirror_AutoPOC",
        run_sql_filename="02_sp_dim_mirror.sql",
        procedure_name="sp_dim_mirror_dl_to_synapse_autopoc",
        migration_table="dwh_daily_process.migration_tables.dim_mirror",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror",
    ),
    FlowJobDef(
        flow_id="fact_currencypricewithsplit",
        job_name="DWH_Daily_Process__SP_Fact_CurrencyPriceWithSplit_AutoPOC",
        run_sql_filename="02_sp_fact_currencypricewithsplit.sql",
        procedure_name="sp_fact_currencypricewithsplit_dl_to_synapse_autopoc",
        migration_table="dwh_daily_process.migration_tables.fact_currencypricewithsplit",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit",
    ),
    FlowJobDef(
        flow_id="fact_deposit_state",
        job_name="DWH_Daily_Process__SP_Fact_Deposit_State_AutoPOC",
        run_sql_filename="02_sp_fact_deposit_state.sql",
        procedure_name="sp_fact_deposit_state_autopoc",
        migration_table="dwh_daily_process.migration_tables.fact_deposit_state",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state",
    ),
)


def _sql_for_proc(proc_name: str) -> str:
    # Default execution date is yesterday (UTC warehouse date).
    return (
        f"CALL dwh_daily_process.migration_tables.{proc_name}("
        "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
        ");\n"
    )

def main() -> int:
    results: list[dict[str, object]] = []
    for flow in FLOW_JOBS:
        rec = create_or_update_sql_job(
            profile="guyman",
            job_name=flow.job_name,
            warehouse_id=DEFAULT_WAREHOUSE_ID,
            workspace_sql_dir=WORKSPACE_SQL_DIR,
            task_specs=[
                SqlTaskSpec(
                    task_key="snapshot_guard",
                    sql_filename=f"{flow.flow_id}_01_snapshot_guard.sql",
                    sql_text="SELECT current_date() AS run_date, DATEADD(DAY, -1, current_date()) AS target_date;\n",
                ),
                SqlTaskSpec(
                    task_key=f"run_{flow.flow_id}",
                    sql_filename=flow.run_sql_filename,
                    sql_text=_sql_for_proc(flow.procedure_name),
                    depends_on=("snapshot_guard",),
                ),
                SqlTaskSpec(
                    task_key="qa_probe",
                    sql_filename=f"{flow.flow_id}_03_qa_probe.sql",
                    sql_text=(
                        "SELECT "
                        f"(SELECT COUNT(*) FROM {flow.migration_table}) AS migration_rows, "
                        f"(SELECT COUNT(*) FROM {flow.gold_table}) AS gold_rows;\n"
                    ),
                    depends_on=(f"run_{flow.flow_id}",),
                ),
            ],
        )
        rec["flow_id"] = flow.flow_id
        results.append(rec)
    print(json.dumps({"jobs": results}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
