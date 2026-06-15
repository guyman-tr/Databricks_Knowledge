"""Inspect what metrics v_ddr_revenues actually emits, vs Synapse fact."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

print("=== UC: distinct Metrics emitted by v_ddr_revenues over Apr-Jun 2026 ===")
r = run_sql(w, """
SELECT Metric, COUNT(*) AS rows_
FROM main.etoro_kpi_prep.v_ddr_revenues
WHERE DateID BETWEEN 20260401 AND 20260610
GROUP BY Metric
ORDER BY Metric
""")
for row in r.rows:
    print(f"  {row[0]:<28} rows={row[1]}")

print()
print("=== UC: source view v_ddr_revenues definition ===")
r = run_sql(w, """
SELECT view_definition
FROM main.information_schema.views
WHERE table_schema = 'etoro_kpi_prep' AND table_name = 'v_ddr_revenues'
""")
if r.rows:
    body = r.rows[0][0]
    # only show the Metric-emitting SELECTs and their UNIONs
    print(f"  view body length: {len(body)} chars")
    import re
    # crude: list all literal metric strings emitted as Metric
    metrics = sorted(set(re.findall(r"'([A-Za-z][A-Za-z0-9_]+)'\s+AS\s+Metric", body, re.IGNORECASE)))
    print(f"  literal metric labels emitted by view body: {metrics}")
else:
    print("  not found")

print()
print("=== Synapse: source TVF for TicketFeeByPercent ===")
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.name = 'Function_Revenue_TicketFeeByPercent'
""")
if r.rows:
    body = r.rows[0][0]
    import re
    metrics = sorted(set(re.findall(r"'([A-Za-z][A-Za-z0-9_]+)'\s+AS\s+Metric", body, re.IGNORECASE)))
    print(f"  Synapse Function_Revenue_TicketFeeByPercent metrics: {metrics}")
    print(f"  body chars: {len(body)}")

print()
print("=== Synapse: source TVF for TicketFee ===")
r = synapse.run("""
SELECT m.definition
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.name = 'Function_Revenue_TicketFee'
""")
if r.rows:
    body = r.rows[0][0]
    import re
    metrics = sorted(set(re.findall(r"'([A-Za-z][A-Za-z0-9_]+)'\s+AS\s+Metric", body, re.IGNORECASE)))
    print(f"  Synapse Function_Revenue_TicketFee metrics: {metrics}")
