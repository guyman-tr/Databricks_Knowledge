"""Inspect the gold fact table to understand its writer/owner/last update."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== DESCRIBE EXTENDED main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ===")
try:
    r = run_sql(w, "DESCRIBE EXTENDED main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions")
    for row in r.rows:
        # row format: [col_name, data_type, comment]
        print(" | ".join("" if x is None else str(x) for x in row))
except Exception as e:
    print(f"FAIL: {e}")

print()
print("=== DESCRIBE HISTORY (last 30 ops) ===")
try:
    r = run_sql(w, "DESCRIBE HISTORY main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions LIMIT 30")
    print(f"columns: {r.columns}" if hasattr(r, 'columns') else '')
    for row in r.rows:
        print(" | ".join("" if x is None else str(x)[:120] for x in row))
except Exception as e:
    print(f"FAIL: {e}")

print()
print("=== Tables that target the gold fact (potential writers) ===")
# Search information_schema for any view/proc that writes into this table.
# In UC we can use system.access.table_lineage to see upstream writers.
try:
    sql = """
SELECT DISTINCT source_type, source_table_full_name, source_path, entity_type, entity_run_id
FROM system.access.table_lineage
WHERE target_table_full_name = 'main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions'
  AND event_time > current_timestamp() - INTERVAL 30 DAYS
ORDER BY source_type, source_table_full_name
"""
    r = run_sql(w, sql)
    if not r.rows:
        print("  (no upstream writers in last 30 days)")
    else:
        for row in r.rows:
            print(" | ".join("" if x is None else str(x)[:80] for x in row))
except Exception as e:
    print(f"FAIL: {e}")
