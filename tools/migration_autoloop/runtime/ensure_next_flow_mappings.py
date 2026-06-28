#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


SQLS = [
    """
MERGE INTO dwh_daily_process.qa.gold_phase_table_mapping t
USING (
  SELECT
    'dwh_daily_process.migration_tables.fact_snapshotcustomer' AS migration_table_name,
    'DWH_dbo.Fact_SnapshotCustomer' AS synapse_table_name,
    'main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer' AS gold_table_name
) s
ON lower(t.migration_table_name) = lower(s.migration_table_name)
WHEN MATCHED THEN UPDATE SET
  t.synapse_table_name = s.synapse_table_name,
  t.gold_table_name = s.gold_table_name,
  t.update_date = current_date(),
  t.is_active = 1,
  t.remarks = 'autoloop-next-flow-mapping',
  t.is_check_passed = 0
WHEN NOT MATCHED THEN INSERT (
  migration_table_name, synapse_table_name, gold_table_name, update_date, is_active, remarks, is_check_passed
) VALUES (
  s.migration_table_name, s.synapse_table_name, s.gold_table_name, current_date(), 1, 'autoloop-next-flow-mapping', 0
)
""",
    """
MERGE INTO dwh_daily_process.qa.gold_phase_table_mapping t
USING (
  SELECT
    'dwh_daily_process.migration_tables.fact_regulationtransfer' AS migration_table_name,
    'DWH_dbo.Fact_RegulationTransfer' AS synapse_table_name,
    'main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer' AS gold_table_name
) s
ON lower(t.migration_table_name) = lower(s.migration_table_name)
WHEN MATCHED THEN UPDATE SET
  t.synapse_table_name = s.synapse_table_name,
  t.gold_table_name = s.gold_table_name,
  t.update_date = current_date(),
  t.is_active = 1,
  t.remarks = 'autoloop-next-flow-mapping',
  t.is_check_passed = 0
WHEN NOT MATCHED THEN INSERT (
  migration_table_name, synapse_table_name, gold_table_name, update_date, is_active, remarks, is_check_passed
) VALUES (
  s.migration_table_name, s.synapse_table_name, s.gold_table_name, current_date(), 1, 'autoloop-next-flow-mapping', 0
)
""",
    """
MERGE INTO dwh_daily_process.qa.gold_phase_table_mapping t
USING (
  SELECT
    'dwh_daily_process.migration_tables.fact_snapshotequity' AS migration_table_name,
    'DWH_dbo.v_Fact_SnapshotEquity_FromDateID' AS synapse_table_name,
    'main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid' AS gold_table_name
) s
ON lower(t.migration_table_name) = lower(s.migration_table_name)
WHEN MATCHED THEN UPDATE SET
  t.synapse_table_name = s.synapse_table_name,
  t.gold_table_name = s.gold_table_name,
  t.update_date = current_date(),
  t.is_active = 1,
  t.remarks = 'autoloop-next-flow-mapping',
  t.is_check_passed = 0
WHEN NOT MATCHED THEN INSERT (
  migration_table_name, synapse_table_name, gold_table_name, update_date, is_active, remarks, is_check_passed
) VALUES (
  s.migration_table_name, s.synapse_table_name, s.gold_table_name, current_date(), 1, 'autoloop-next-flow-mapping', 0
)
""",
    """
MERGE INTO dwh_daily_process.qa.gold_phase_table_mapping t
USING (
  SELECT
    'dwh_daily_process.migration_tables.dim_mirror' AS migration_table_name,
    'DWH_dbo.Dim_Mirror' AS synapse_table_name,
    'main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror' AS gold_table_name
) s
ON lower(t.migration_table_name) = lower(s.migration_table_name)
WHEN MATCHED THEN UPDATE SET
  t.synapse_table_name = s.synapse_table_name,
  t.gold_table_name = s.gold_table_name,
  t.update_date = current_date(),
  t.is_active = 1,
  t.remarks = 'autoloop-next-flow-mapping',
  t.is_check_passed = 0
WHEN NOT MATCHED THEN INSERT (
  migration_table_name, synapse_table_name, gold_table_name, update_date, is_active, remarks, is_check_passed
) VALUES (
  s.migration_table_name, s.synapse_table_name, s.gold_table_name, current_date(), 1, 'autoloop-next-flow-mapping', 0
)
""",
    """
MERGE INTO dwh_daily_process.qa.gold_phase_table_mapping t
USING (
  SELECT
    'dwh_daily_process.migration_tables.fact_cashout_state' AS migration_table_name,
    'DWH_dbo.Fact_Cashout_State' AS synapse_table_name,
    'main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state' AS gold_table_name
) s
ON lower(t.migration_table_name) = lower(s.migration_table_name)
WHEN MATCHED THEN UPDATE SET
  t.synapse_table_name = s.synapse_table_name,
  t.gold_table_name = s.gold_table_name,
  t.update_date = current_date(),
  t.is_active = 1,
  t.remarks = 'autoloop-next-flow-mapping',
  t.is_check_passed = 0
WHEN NOT MATCHED THEN INSERT (
  migration_table_name, synapse_table_name, gold_table_name, update_date, is_active, remarks, is_check_passed
) VALUES (
  s.migration_table_name, s.synapse_table_name, s.gold_table_name, current_date(), 1, 'autoloop-next-flow-mapping', 0
)
""",
]


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    for sql in SQLS:
        execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print("ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
