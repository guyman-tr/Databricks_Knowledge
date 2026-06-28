"""Read parity results from _phase_b_results Delta table."""
import sys, os, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

cols, rows = execute_sql(w,
    sql_text="SELECT ring, overall_status, payload FROM dwh_daily_process.migration_parallel._phase_b_results ORDER BY ring",
    warehouse_id=wid)

for row in rows:
    ring, overall, payload = row
    print(f"\n{'='*60}")
    print(f"Ring {ring}  overall={overall}")
    print('='*60)
    try:
        d = json.loads(payload)
        for tr in d.get("target_results", []):
            tid = tr.get("target_id","?")
            parity = tr.get("parity", {})
            if isinstance(parity, dict):
                status  = parity.get("status","?")
                reason  = parity.get("reason","")
                par_r   = parity.get("par_rows")
                gold_r  = parity.get("gold_rows")
                pstat   = parity.get("parity_status","")
                agg     = parity.get("agg_status","")
                err     = parity.get("error","")
                cnt     = f"  par={par_r:,} gold={gold_r:,}" if isinstance(par_r,int) else ""
                detail  = reason or pstat or agg or err or ""
                print(f"  {tid:<45} {status}  {detail}{cnt}")
            else:
                print(f"  {tid}: {parity}")
    except Exception as e:
        print(f"  parse error: {e}")
