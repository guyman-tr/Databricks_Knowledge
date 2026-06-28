"""Show final parity results for the most recent run per ring."""
import sys, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

_, rows = execute_sql(w,
    sql_text=(
        "SELECT ts, run_date, ring, overall_status, payload "
        "FROM dwh_daily_process.migration_parallel._phase_b_results "
        "ORDER BY ts DESC LIMIT 40"
    ),
    warehouse_id=wid)

latest = {}
for r in rows:
    ts, run_date, ring, overall, payload_str = r
    ring = int(ring)
    if ring not in latest:
        latest[ring] = (ts, run_date, overall, payload_str)

print("FINAL RUN PARITY RESULTS (latest per ring):\n")
all_ok = True
for ring in sorted(latest):
    ts, run_date, overall, payload_str = latest[ring]
    ok = overall == "success"
    flag = "OK" if ok else "FAIL"
    print(f"[{flag}] Ring {ring}  ts={ts}  run_date={run_date}  overall={overall}")
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
            print(f"  {tid:<42} {status:<10} {row_info}  {msg[:80]}")
    except Exception as e:
        print(f"  parse error: {e}")
    if not ok:
        all_ok = False
    print()

print("=" * 60)
print("OVERALL:", "ALL RINGS PASSED" if all_ok else "SOME RINGS FAILED")
