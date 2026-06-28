#!/usr/bin/env python3
"""Create/update AutoPOC multi-task job for Fact_CustomerAction ETL."""
from __future__ import annotations

import json
from dataclasses import dataclass

from orchestration import SqlTaskSpec, create_or_update_sql_job

JOB_NAME = "DWH_Daily_Process__Fact_CustomerAction_ETL_AutoPOC"
WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_customeraction_autopoc"


@dataclass(frozen=True)
class TaskDef:
    task_key: str
    sql_filename: str
    sql_text: str
    depends_on: tuple[str, ...] = ()


TASKS: tuple[TaskDef, ...] = (
    TaskDef(
        task_key="SP_Dictionaries_Country_DL_To_Synapse",
        sql_filename="01_sp_dictionaries_country_dl_to_synapse_autopoc.sql",
        sql_text="CALL dwh_daily_process.migration_tables.sp_dictionaries_country_dl_to_synapse_autopoc();\n",
    ),
    TaskDef(
        task_key="SP_Fact_CustomerAction_DL_To_Synapse",
        sql_filename="02_sp_fact_customeraction_dl_to_synapse_autopoc.sql",
        sql_text=(
            "CALL dwh_daily_process.migration_tables.sp_fact_customeraction_dl_to_synapse_autopoc("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        ),
        depends_on=("SP_Dictionaries_Country_DL_To_Synapse",),
    ),
    TaskDef(
        task_key="SP_Fact_FirstCustomerAction_DL_To_Synapse",
        sql_filename="03_sp_fact_firstcustomeraction_dl_to_synapse_autopoc.sql",
        sql_text=(
            "CALL dwh_daily_process.migration_tables.sp_fact_firstcustomeraction_dl_to_synapse_autopoc("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        ),
        depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
    ),
    TaskDef(
        task_key="SP_Fact_BillingDeposit_DL_To_Synapse",
        sql_filename="04_sp_fact_billingdeposit_dl_to_synapse_autopoc.sql",
        sql_text=(
            "CALL dwh_daily_process.migration_tables.sp_fact_billingdeposit_dl_to_synapse_autopoc("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        ),
        depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
    ),
    TaskDef(
        task_key="SP_Fact_BillingWithdraw_DL_To_Synapse",
        sql_filename="05_sp_fact_billingwithdraw_dl_to_synapse_autopoc.sql",
        sql_text=(
            "CALL dwh_daily_process.migration_tables.sp_fact_billingwithdraw_dl_to_synapse_autopoc("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        ),
        depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
    ),
    TaskDef(
        task_key="SP_Fact_BillingRedeem_DL_To_Synapse",
        sql_filename="06_sp_fact_billingredeem_dl_to_synapse_autopoc.sql",
        sql_text=(
            "CALL dwh_daily_process.migration_tables.sp_fact_billingredeem_dl_to_synapse_autopoc("
            "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
            ");\n"
        ),
        depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
    ),
)


def main() -> int:
    task_specs = [
        SqlTaskSpec(
            task_key=t.task_key,
            sql_filename=t.sql_filename,
            sql_text=t.sql_text,
            depends_on=t.depends_on,
        )
        for t in TASKS
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
