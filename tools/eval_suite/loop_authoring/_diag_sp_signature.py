"""Pull signature + first 200 lines of de_output.sp_ddr_fact_revenue_generating_actions
to confirm it's runnable and what its parameters look like.

Goal: produce a `CALL` we can invoke for a single test date end-to-end.
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== Parameters ===")
r = run_sql(w, """
SELECT parameter_name, parameter_mode, data_type, ordinal_position, parameter_default
FROM main.information_schema.parameters
WHERE specific_schema = 'de_output'
  AND specific_name LIKE 'sp_ddr_fact_revenue_generating_actions%'
ORDER BY ordinal_position
""")
for row in r.rows:
    print(f"  ord={row[3]} name={row[0]} mode={row[1]} type={row[2]} default={row[4]}")

print()
print("=== Definition (first 200 lines) ===")
r = run_sql(w, """
SELECT routine_definition
FROM main.information_schema.routines
WHERE specific_schema = 'de_output'
  AND routine_name = 'sp_ddr_fact_revenue_generating_actions'
""")
if r.rows:
    body = r.rows[0][0] or ""
    lines = body.splitlines()
    print(f"  total lines: {len(lines)}")
    for i, ln in enumerate(lines[:200], 1):
        print(f"  L{i:>3}: {ln}")

# write the full body so we can read it
out = "audits/eval_suite/sp_de_output_revgen_full.sql"
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w", encoding="utf-8") as f:
    f.write(body)
print()
print(f"  full body written to: {out}")
