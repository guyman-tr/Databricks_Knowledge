"""Compare column shapes of Synapse and UC fact tables before writing the backfill."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import synapse
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== Synapse: BI_DB_DDR_Fact_Revenue_Generating_Actions columns ===")
r = synapse.run("""
SELECT c.name, t.name AS type_name, c.max_length, c.precision, c.scale, c.is_nullable
FROM sys.columns c
JOIN sys.tables tab ON tab.object_id = c.object_id
JOIN sys.schemas s  ON s.schema_id = tab.schema_id
JOIN sys.types t    ON t.user_type_id = c.user_type_id
WHERE s.name = 'BI_DB_dbo' AND tab.name = 'BI_DB_DDR_Fact_Revenue_Generating_Actions'
ORDER BY c.column_id
""")
syn_cols = [(row[0], row[1], row[2], row[3], row[4], row[5]) for row in r.rows]
for c in syn_cols:
    print(f"  {c[0]:<28} {c[1]:<14} max_len={c[2]} prec={c[3]} scale={c[4]} null={c[5]}")

print()
print("=== UC: gold fact columns ===")
r = run_sql(w, """
DESCRIBE TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
""")
uc_cols = []
for row in r.rows:
    name = row[0]
    if not name or name.startswith('#') or name.startswith(' '):
        continue
    uc_cols.append((name, row[1], row[2] if len(row) > 2 else None))
    print(f"  {name:<28} {row[1]}")

print()
print("=== Column name match (case-insensitive) ===")
syn_names = {c[0].lower(): c[0] for c in syn_cols}
uc_names = {c[0].lower(): c[0] for c in uc_cols}
shared = sorted(set(syn_names) & set(uc_names))
syn_only = sorted(set(syn_names) - set(uc_names))
uc_only = sorted(set(uc_names) - set(syn_names))
print(f"  shared: {len(shared)}")
print(f"  syn_only: {syn_only}")
print(f"  uc_only:  {uc_only}")
