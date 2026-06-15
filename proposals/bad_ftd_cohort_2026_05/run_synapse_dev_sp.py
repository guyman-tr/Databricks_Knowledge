"""
Run the patched SP_DDR_Fact_Fact_MIMO_AllPlatforms on Synapse dev pool.
Uses ActiveDirectoryInteractive WAM + autocommit=True.
"""
import sys
import os
import time

sys.stdout.reconfigure(line_buffering=True)

import pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"

target_date = sys.argv[1] if len(sys.argv) > 1 else "20260420"

conn_str = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server={SERVER};"
    f"Database={DATABASE};"
    f"UID={UID};"
    "Authentication=ActiveDirectoryInteractive;"
    "Encrypt=yes;TrustServerCertificate=no;"
    "Connection Timeout=60;"
)

print(f"[{time.strftime('%H:%M:%S')}] Connecting...", flush=True)
conn = pyodbc.connect(conn_str, timeout=60, autocommit=True)
conn.timeout = 3600  # 1h query timeout for SP execution
print(f"[{time.strftime('%H:%M:%S')}] Connected. autocommit={conn.autocommit}", flush=True)

cur = conn.cursor()
sql = f"EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms '{target_date}'"
print(f"[{time.strftime('%H:%M:%S')}] Running: {sql}", flush=True)
try:
    cur.execute(sql)
    while cur.nextset():
        pass
    print(f"[{time.strftime('%H:%M:%S')}] OK: SP completed", flush=True)
except Exception as e:
    print(f"[{time.strftime('%H:%M:%S')}] FAIL: {type(e).__name__}: {e}", flush=True)
    raise
finally:
    cur.close()
    conn.close()
print(f"[{time.strftime('%H:%M:%S')}] Done.", flush=True)
