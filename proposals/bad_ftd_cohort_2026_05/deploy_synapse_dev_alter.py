"""
Deploy patched SP_DDR_Fact_Fact_MIMO_AllPlatforms to Synapse dev pool.

Uses ActiveDirectoryInteractive (WAM) with autocommit=True so Synapse accepts
the ALTER PROC. ssisuser (the MCP default) doesn't have ALTER permission so
we must auth as guyman@etoro.com.
"""
import sys
import os
import time

sys.stdout.reconfigure(line_buffering=True)

import pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"
ALTER_FILE = r"C:\Users\guyman\Documents\github\Databricks_Knowledge\proposals\bad_ftd_cohort_2026_05\_synapse_sp_dev_alter.sql"

conn_str = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server={SERVER};"
    f"Database={DATABASE};"
    f"UID={UID};"
    "Authentication=ActiveDirectoryInteractive;"
    "Encrypt=yes;TrustServerCertificate=no;"
    "Connection Timeout=60;"
)

print(f"[{time.strftime('%H:%M:%S')}] Connecting to {SERVER} / {DATABASE} as {UID}...", flush=True)
print(f"[{time.strftime('%H:%M:%S')}] A Windows auth popup may appear briefly...", flush=True)
conn = pyodbc.connect(conn_str, timeout=60, autocommit=True)
print(f"[{time.strftime('%H:%M:%S')}] Connected. autocommit={conn.autocommit}", flush=True)

cur = conn.cursor()
cur.execute("SELECT SUSER_SNAME() AS who, DB_NAME() AS db")
row = cur.fetchone()
print(f"Logged in as: {row.who}, db={row.db}", flush=True)

print(f"Reading {ALTER_FILE}...", flush=True)
with open(ALTER_FILE, "r", encoding="utf-8-sig") as f:
    body = f.read()
print(f"Body size: {len(body)} chars", flush=True)

print("Executing ALTER PROC...", flush=True)
try:
    cur.execute(body)
    print("OK: ALTER PROC succeeded", flush=True)
except Exception as e:
    print(f"FAIL: {type(e).__name__}: {e}", flush=True)
    raise
finally:
    cur.close()
    conn.close()
print("Done.", flush=True)
