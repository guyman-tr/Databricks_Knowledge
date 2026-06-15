"""Investigate the production state of sp_ddr_fact_revenue_generating_actions.

Goals:
  1. Confirm the SP exists and where (de_output vs de_output_stg).
  2. Find the most recent successful invocation.
  3. Identify any orchestrator job(s) that call it.
  4. Check upstream view freshness (v_revenue_*) — if these are stale, the SP
     output will be stale too.
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=" * 70)
print("(1) SP existence & location")
print("=" * 70)
r = run_sql(w, """
SELECT routine_catalog, routine_schema, routine_name, routine_type, created, last_altered
FROM main.information_schema.routines
WHERE LOWER(routine_name) = 'sp_ddr_fact_revenue_generating_actions'
ORDER BY routine_schema
""")
if not r.rows:
    print("  NOT FOUND in any schema")
else:
    for row in r.rows:
        print(f"  {row[0]}.{row[1]}.{row[2]}  type={row[3]}  created={row[4]}  last_altered={row[5]}")

print()
print("=" * 70)
print("(2) Most recent runs of any sp_ddr_* — query history (last 60 days)")
print("=" * 70)
try:
    r = run_sql(w, """
SELECT
    statement_text,
    start_time,
    end_time,
    execution_status,
    executed_by,
    statement_type
FROM system.query.history
WHERE start_time > current_timestamp() - INTERVAL 60 DAYS
  AND LOWER(statement_text) LIKE '%sp_ddr_fact_revenue_generating_actions%'
ORDER BY start_time DESC
LIMIT 30
""")
    if not r.rows:
        print("  no invocations found in last 60 days")
    else:
        for row in r.rows:
            txt = (row[0] or "")[:120].replace("\n", " ")
            print(f"  {row[1]} | {row[3]} | by={row[4]} | {txt}")
except Exception as e:
    print(f"  FAIL querying system.query.history: {e}")

print()
print("=" * 70)
print("(3) Look in workflow / job runs for SP-name references (last 60 days)")
print("=" * 70)
# Note: system.lakeflow / system.job is the right path when available. Try both.
queries_to_try = [
    """
SELECT job_id, job_name, last_modified
FROM system.lakeflow.jobs
WHERE LOWER(job_name) LIKE '%revenue_generating%'
   OR LOWER(job_name) LIKE '%ddr_fact_revenue%'
   OR LOWER(job_name) LIKE '%sp_ddr%'
""",
    """
SELECT name AS job_name, job_id, change_time
FROM system.lakeflow.job_runs
WHERE change_time > current_timestamp() - INTERVAL 30 DAYS
LIMIT 5
""",
]
for q in queries_to_try:
    try:
        r = run_sql(w, q)
        for row in r.rows:
            print("  " + " | ".join("" if x is None else str(x)[:80] for x in row))
        print(f"  ({len(r.rows)} rows)")
        print()
    except Exception as e:
        print(f"  FAIL: {e}")
        print()

print()
print("=" * 70)
print("(4) Upstream view freshness — when did v_revenue_* views last get queried?")
print("=" * 70)
# Trick: views don't have an UpdateDate, but we can check the underlying table
# system.access.column_lineage to see when the view was last referenced.
print("  v_revenue_stakingfee:")
try:
    r = run_sql(w, """
SELECT MAX(event_time) AS last_seen
FROM system.access.table_lineage
WHERE source_table_full_name = 'main.etoro_kpi_prep.v_revenue_stakingfee'
   OR target_table_full_name = 'main.etoro_kpi_prep.v_revenue_stakingfee'
""")
    print(f"    last_seen = {r.rows[0][0] if r.rows else None}")
except Exception as e:
    print(f"    FAIL: {e}")

print("  v_revenue_optionsplatform:")
try:
    r = run_sql(w, """
SELECT MAX(event_time) AS last_seen
FROM system.access.table_lineage
WHERE source_table_full_name = 'main.etoro_kpi_prep.v_revenue_optionsplatform'
   OR target_table_full_name = 'main.etoro_kpi_prep.v_revenue_optionsplatform'
""")
    print(f"    last_seen = {r.rows[0][0] if r.rows else None}")
except Exception as e:
    print(f"    FAIL: {e}")

print()
print("=" * 70)
print("(5) Last actual data refresh of the gold target — by writer")
print("=" * 70)
try:
    r = run_sql(w, """
SELECT
    DATE_TRUNC('DAY', timestamp) AS day,
    operation,
    userName,
    COUNT(*) AS ops
FROM (
    DESCRIBE HISTORY main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
)
WHERE timestamp > current_timestamp() - INTERVAL 30 DAYS
GROUP BY DATE_TRUNC('DAY', timestamp), operation, userName
ORDER BY day DESC, operation
""")
    for row in r.rows:
        print(f"  {row[0]} | {row[1]:<10} | {row[2]:<40} | {row[3]} ops")
except Exception as e:
    print(f"  FAIL: {e}")
