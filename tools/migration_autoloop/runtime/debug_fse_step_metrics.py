#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


SQL = """
WITH p AS (
  SELECT
    CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP) AS dt,
    DATEADD(DAY, 1, CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS DATE)) AS aux
)
SELECT
  (SELECT COUNT(*) FROM dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw) AS src_withdraw_all,
  (SELECT COUNT(*) FROM dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw bw, p WHERE bw.RequestDate < p.aux) AS src_withdraw_lt_aux,
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_billing_withdraw) AS ext_withdraw_rows,
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_inprocesscashouts) AS ext_inprocess_rows,
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.ext_fse_totalpositionamount) AS ext_totalposition_rows,
  (SELECT COALESCE(SUM(CAST(COALESCE(TotalPositionAmount,0) AS DECIMAL(38,10))),0) FROM dwh_daily_process.migration_tables.ext_fse_totalpositionamount) AS ext_totalposition_sum,
  (SELECT COUNT(*) FROM dwh_daily_process.migration_tables.fact_snapshotequity WHERE LEFT(CAST(DateRangeID AS STRING), 8) = DATE_FORMAT(DATEADD(DAY,-1,CURRENT_DATE()), 'yyyyMMdd')) AS fse_rows_target_date,
  (SELECT COALESCE(SUM(CAST(COALESCE(TotalPositionsAmount,0) AS DECIMAL(38,10))),0) FROM dwh_daily_process.migration_tables.fact_snapshotequity WHERE LEFT(CAST(DateRangeID AS STRING), 8) = DATE_FORMAT(DATEADD(DAY,-1,CURRENT_DATE()), 'yyyyMMdd')) AS fse_sum_totalpositions_target_date,
  (SELECT SUM(CASE WHEN COALESCE(TotalPositionsAmount,0)=0 THEN 1 ELSE 0 END) FROM dwh_daily_process.migration_tables.fact_snapshotequity WHERE LEFT(CAST(DateRangeID AS STRING), 8) = DATE_FORMAT(DATEADD(DAY,-1,CURRENT_DATE()), 'yyyyMMdd')) AS fse_zero_totalpositions_rows,
  (SELECT MIN(UpdateDate) FROM dwh_daily_process.migration_tables.fact_snapshotequity WHERE LEFT(CAST(DateRangeID AS STRING), 8) = DATE_FORMAT(DATEADD(DAY,-1,CURRENT_DATE()), 'yyyyMMdd')) AS fse_min_updatedate_target_date,
  (SELECT MAX(UpdateDate) FROM dwh_daily_process.migration_tables.fact_snapshotequity WHERE LEFT(CAST(DateRangeID AS STRING), 8) = DATE_FORMAT(DATEADD(DAY,-1,CURRENT_DATE()), 'yyyyMMdd')) AS fse_max_updatedate_target_date,
  (SELECT COALESCE(SUM(CAST(COALESCE(e.TotalPositionsAmount,0) AS DECIMAL(38,10))),0)
   FROM dwh_daily_process.migration_tables.fact_snapshotequity f
   LEFT JOIN dwh_daily_process.migration_tables.ext_fse_fact_snapshotequity e ON f.CID = e.CID
   WHERE LEFT(CAST(f.DateRangeID AS STRING), 8) = DATE_FORMAT(DATEADD(DAY,-1,CURRENT_DATE()), 'yyyyMMdd')) AS ext_sum_for_target_cids
"""


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=SQL, warehouse_id=wid)
    payload = {"columns": cols, "rows": rows}
    print(json.dumps(payload, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

