"""Pull UC v_revenue_optionsplatform view definition + recent row counts."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from databricks.sdk import WorkspaceClient
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from dbx import run_sql

w = WorkspaceClient()

print("=== UC: main.etoro_kpi_prep.v_revenue_optionsplatform definition ===")
r = run_sql(w, """
SELECT view_definition
FROM main.information_schema.views
WHERE table_schema = 'etoro_kpi_prep' AND table_name = 'v_revenue_optionsplatform'
""")
if r.rows:
    print(r.rows[0][0])
else:
    print("  not found")

print()
print("=== UC: row counts in v_revenue_optionsplatform per day, last 60d ===")
r = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM main.etoro_kpi_prep.v_revenue_optionsplatform
WHERE DateID >= 20260401
GROUP BY DateID
ORDER BY DateID DESC
LIMIT 25
""")
for row in r.rows:
    print(f"  UC view  DateID={row[0]} rows={row[1]} sum_amt={row[2]}")

print()
print("=== UC: row counts of Options_PFOF in fact table per day, last 60d ===")
r = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'Options_PFOF' AND DateID >= 20260401
GROUP BY DateID
ORDER BY DateID DESC
LIMIT 25
""")
for row in r.rows:
    print(f"  UC fact  DateID={row[0]} rows={row[1]} sum_amt={row[2]} max_upd={row[3]}")
