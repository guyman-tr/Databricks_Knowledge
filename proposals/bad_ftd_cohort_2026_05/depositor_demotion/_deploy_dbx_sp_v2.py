"""Deploy patched DBX sp_ddr_customer_daily_status (with IsFunded fields) to UC.

Uses databricks.sql connector for reliable large-DDL execution.
"""
import os, time, sys

sys.path.insert(0, r"C:\Users\guyman\.cursor")
try:
    from databricks import sql as dbx_sql
except Exception as e:
    print(f"Cannot import databricks.sql: {e}")
    sys.exit(1)

DDL_PATH = r"C:\Users\guyman\Documents\github\Databricks_Knowledge\proposals\bad_ftd_cohort_2026_05\sp_ddr_customer_daily_status.aligned.sql"

# Load creds from databricks-credentials.env (same pattern as the synapse mcp)
ENV_PATH = r"C:\Users\guyman\.cursor\databricks-credentials.env"
host, token, http_path = None, None, None
if os.path.exists(ENV_PATH):
    with open(ENV_PATH, encoding="utf-8-sig") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line: continue
            k,v = line.split("=", 1)
            k,v = k.strip(), v.strip()
            if k == "DATABRICKS_HOST": host = v
            elif k == "DATABRICKS_TOKEN": token = v
            elif k == "DATABRICKS_HTTP_PATH": http_path = v

if not (host and token and http_path):
    print(f"Missing creds in {ENV_PATH}; got host={bool(host)} token={bool(token)} http_path={bool(http_path)}")
    sys.exit(1)

with open(DDL_PATH, encoding="utf-8-sig") as f:
    ddl = f.read()

print(f"[{time.strftime('%H:%M:%S')}] Loaded DDL: {len(ddl)} chars from {DDL_PATH}")
print(f"[{time.strftime('%H:%M:%S')}] Connecting to {host} ...")
with dbx_sql.connect(server_hostname=host, http_path=http_path, access_token=token) as conn:
    with conn.cursor() as cur:
        print(f"[{time.strftime('%H:%M:%S')}] Connected. Executing DDL...")
        t0 = time.time()
        cur.execute(ddl)
        print(f"[{time.strftime('%H:%M:%S')}] OK in {time.time()-t0:.1f}s")
print(f"[{time.strftime('%H:%M:%S')}] Done.")
