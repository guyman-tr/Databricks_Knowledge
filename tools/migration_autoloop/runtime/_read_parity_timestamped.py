"""Read parity results from the LATEST run properly."""
import sys, os, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

# Get latest run only (newest ts per ring from today's runs)
_, rows = execute_sql(w,
    sql_text=(
        "SELECT ts, run_date, ring, overall_status, payload "
        "FROM dwh_daily_process.migration_parallel._phase_b_results "
        "WHERE run_date='2026-06-26' "
        "ORDER BY ts DESC LIMIT 10"
    ),
    warehouse_id=wid)

# Group by ring, take latest
latest = {}
for r in rows:
    ts, run_date, ring, overall, payload_str = r
    ring = int(ring)
    if ring not in latest:
        latest[ring] = (ts, overall, payload_str)

print("CURRENT RUN PARITY RESULTS (latest per ring):\n")
for ring in sorted(latest):
    ts, overall, payload_str = latest[ring]
    print(f"Ring {ring}  ts={ts}  overall={overall}")
    try:
        payload = json.loads(payload_str)
        for tr in payload.get("target_results", []):
            tid = tr.get("target_id", "?")
            par = tr.get("parity", {})
            status = par.get("status", "?")
            msg = par.get("message", "") or par.get("reason", "")
            row_info = ""
            if "par_rows" in par:
                row_info = f"par={par['par_rows']} gold={par.get('gold_rows','?')}"
            print(f"  {tid:<42} {status:<10} {row_info}  {msg[:60]}")
    except Exception as e:
        print(f"  parse error: {e}")
    print()
