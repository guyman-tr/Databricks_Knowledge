"""Re-pin the canonical UC value for revenue_totals_yesterday using
IsValidCustomer=1 (the actual pill on every DDR tab) instead of
IsCreditReportValidCB=1 (the regulatory variant footnote).
"""
from __future__ import annotations
import os, time
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

w = WorkspaceClient()
warehouse_id = os.environ.get("DATABRICKS_WAREHOUSE_ID") or next(w.warehouses.list()).id

q = """
SELECT SUM(d.Amount) AS TotalRevenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap
    ON snap.RealCID = d.RealCID
   AND snap.IsValidCustomer = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = 20260608
  AND d.IncludedInTotalRevenue = 1
"""
print(">>> SQL:")
print(q.strip())
resp = w.statement_execution.execute_statement(statement=q, warehouse_id=warehouse_id, wait_timeout="50s")
sid = resp.statement_id
while True:
    s = w.statement_execution.get_statement(sid)
    if s.status.state in (StatementState.SUCCEEDED, StatementState.FAILED, StatementState.CANCELED):
        break
    time.sleep(0.5)
if s.status.state == StatementState.SUCCEEDED:
    rows = (s.result.data_array if s.result else None) or []
    print(f"\n>>> ROWS:")
    for r in rows:
        print(f"  {r}")
else:
    print(f"FAILED: {s.status.error.message if s.status.error else s.status.state}")
