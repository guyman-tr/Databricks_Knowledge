#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.orchestration import SqlTaskSpec, create_or_update_sql_job


WAREHOUSE_ID = "6f72189f967b42a9"


def _restore_dictionaries() -> dict[str, object]:
    return create_or_update_sql_job(
        profile="guyman",
        job_name="DWH_Daily_Process__SP_Dictionaries_AutoPOC",
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir="/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_restored",
        task_specs=[
            SqlTaskSpec(
                task_key="run_proc",
                sql_filename="dict_01_run_proc.sql",
                sql_text="CALL dwh_daily_process.migration_tables.sp_dictionaries_dl_to_synapse_autopoc();\n",
            ),
            SqlTaskSpec(
                task_key="qa_probe",
                sql_filename="dict_02_qa_probe.sql",
                sql_text=(
                    "SELECT "
                    "(SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_country) AS migration_rows, "
                    "(SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country) AS gold_rows;\n"
                ),
                depends_on=("run_proc",),
            ),
        ],
    )


def _customeraction_specs() -> list[SqlTaskSpec]:
    return [
        SqlTaskSpec(
            task_key="SP_Dictionaries_Country_DL_To_Synapse",
            sql_filename="ca_01_sp_dictionaries_country_dl_to_synapse_autopoc.sql",
            sql_text="CALL dwh_daily_process.migration_tables.sp_dictionaries_country_dl_to_synapse_autopoc();\n",
        ),
        SqlTaskSpec(
            task_key="SP_Fact_CustomerAction_DL_To_Synapse",
            sql_filename="ca_02_sp_fact_customeraction_dl_to_synapse_autopoc.sql",
            sql_text=(
                "CALL dwh_daily_process.migration_tables.sp_fact_customeraction_dl_to_synapse_autopoc("
                "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
                ");\n"
            ),
            depends_on=("SP_Dictionaries_Country_DL_To_Synapse",),
        ),
        SqlTaskSpec(
            task_key="SP_Fact_FirstCustomerAction_DL_To_Synapse",
            sql_filename="ca_03_sp_fact_firstcustomeraction_dl_to_synapse_autopoc.sql",
            sql_text=(
                "CALL dwh_daily_process.migration_tables.sp_fact_firstcustomeraction_dl_to_synapse_autopoc("
                "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
                ");\n"
            ),
            depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
        ),
        SqlTaskSpec(
            task_key="SP_Fact_BillingDeposit_DL_To_Synapse",
            sql_filename="ca_04_sp_fact_billingdeposit_dl_to_synapse_autopoc.sql",
            sql_text=(
                "CALL dwh_daily_process.migration_tables.sp_fact_billingdeposit_dl_to_synapse_autopoc("
                "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
                ");\n"
            ),
            depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
        ),
        SqlTaskSpec(
            task_key="SP_Fact_BillingWithdraw_DL_To_Synapse",
            sql_filename="ca_05_sp_fact_billingwithdraw_dl_to_synapse_autopoc.sql",
            sql_text=(
                "CALL dwh_daily_process.migration_tables.sp_fact_billingwithdraw_dl_to_synapse_autopoc("
                "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
                ");\n"
            ),
            depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
        ),
        SqlTaskSpec(
            task_key="SP_Fact_BillingRedeem_DL_To_Synapse",
            sql_filename="ca_06_sp_fact_billingredeem_dl_to_synapse_autopoc.sql",
            sql_text=(
                "CALL dwh_daily_process.migration_tables.sp_fact_billingredeem_dl_to_synapse_autopoc("
                "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"
                ");\n"
            ),
            depends_on=("SP_Fact_CustomerAction_DL_To_Synapse",),
        ),
    ]


def _restore_customeraction(job_name: str) -> dict[str, object]:
    return create_or_update_sql_job(
        profile="guyman",
        job_name=job_name,
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir="/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_restored_customeraction",
        task_specs=_customeraction_specs(),
    )


def main() -> int:
    out: dict[str, object] = {}
    out["dictionaries"] = _restore_dictionaries()
    out["fact_customeraction_etl"] = _restore_customeraction("DWH_Daily_Process__Fact_CustomerAction_ETL")
    out["fact_customeraction_etl_autopoc"] = _restore_customeraction("DWH_Daily_Process__Fact_CustomerAction_ETL_AutoPOC")
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

