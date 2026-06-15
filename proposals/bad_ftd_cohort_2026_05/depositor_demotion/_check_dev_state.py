"""Quick check: what's in dev daily_status + any running sessions."""
import time, pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"

conn_str = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server={SERVER};Database={DATABASE};"
    f"UID={UID};"
    "Authentication=ActiveDirectoryInteractive;"
    "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=60;"
)

print(f"[{time.strftime('%H:%M:%S')}] Connecting...")
conn = pyodbc.connect(conn_str, timeout=60)
conn.autocommit = True
cur = conn.cursor()
print(f"[{time.strftime('%H:%M:%S')}] Connected.")

print("\n--- Existing dates in dev daily_status (top 10 most recent) ---")
cur.execute("SELECT TOP 10 DateID, COUNT(*) AS rows_, MAX(UpdateDate) AS last_update FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status WHERE DateID >= 20260401 GROUP BY DateID ORDER BY DateID DESC")
for r in cur.fetchall():
    print(f"  {r}")

print("\n--- Specific dates of interest ---")
cur.execute("SELECT DateID, COUNT(*) AS rows_, SUM(CASE WHEN IsDepositor=1 THEN 1 ELSE 0 END) AS isdep, SUM(CASE WHEN IsDepositorGlobal=1 THEN 1 ELSE 0 END) AS isdep_global FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status WHERE DateID IN (20260420, 20260522, 20260523, 20260525) GROUP BY DateID ORDER BY DateID")
for r in cur.fetchall():
    print(f"  {r}")

print("\n--- Active long-running requests on dev pool ---")
try:
    cur.execute("SELECT TOP 10 request_id, status, start_time, DATEDIFF(SECOND, start_time, GETDATE()) AS elapsed_s, SUBSTRING(command, 1, 200) AS snippet FROM sys.dm_pdw_exec_requests WHERE status IN ('Running','Suspended') AND start_time > DATEADD(MINUTE, -60, GETDATE()) ORDER BY start_time DESC")
    for r in cur.fetchall():
        print(f"  {r}")
except Exception as e:
    print(f"  cannot query DMV: {e}")

print(f"\n[{time.strftime('%H:%M:%S')}] Done.")
