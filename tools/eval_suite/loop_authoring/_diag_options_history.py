"""How long has the UC mirror been missing Options_PFOF?
Compare Synapse vs UC for Options_PFOF over the last 60 days."""
from __future__ import annotations
import os, sys, subprocess, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synapse

print("=== Synapse: Options_PFOF rows per day, last 60 days ===")
r = synapse.run("""
SELECT DateID, COUNT_BIG(*) AS rows_, SUM(Amount) AS amt, MAX(UpdateDate) AS upd
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'Options_PFOF' AND DateID >= 20260410
GROUP BY DateID
ORDER BY DateID
""")
syn_days = {row[0]: (row[1], float(row[2] or 0), row[3]) for row in r.rows}
print(f"  {len(syn_days)} days have Options_PFOF in Synapse")
for d, (n, amt, upd) in sorted(syn_days.items())[:8]: print(f"    {d}: rows={n:>4d}  amt={amt:>10,.2f}  upd={upd}")
print("    ...")
for d, (n, amt, upd) in sorted(syn_days.items())[-8:]: print(f"    {d}: rows={n:>4d}  amt={amt:>10,.2f}  upd={upd}")
print()

print("=== Now query UC for same range ===")
sql_uc = """
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS amt, MAX(UpdateDate) AS upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'Options_PFOF' AND DateID >= 20260410
GROUP BY DateID ORDER BY DateID
"""
proc = subprocess.run(
    ["python", "tools/dbx_query.py", sql_uc],
    capture_output=True, cwd=os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))),
)
out = proc.stdout.decode("utf-8", errors="replace")
print(out)
