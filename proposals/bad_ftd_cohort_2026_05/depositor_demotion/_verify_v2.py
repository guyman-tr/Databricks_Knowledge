"""Verify-only v2: find external tables locally and check demotion."""
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

# Find candidate external tables for Billing_Deposit and Customer
print("\n--- Looking for External_etoro_Billing_Deposit & External_etoro_Customer in local DB ---")
cur.execute("SELECT SCHEMA_NAME(schema_id) AS schema_name, name AS table_name FROM sys.tables WHERE name LIKE '%External_etoro_Customer%' OR name LIKE '%External_etoro_Billing_Deposit%' OR (name LIKE '%Customer%' AND name NOT LIKE '%Snapshot%' AND name LIKE 'External%') ORDER BY name")
for r in cur.fetchall():
    print(f"  {r}")

# Now run a local cohort-build using local tables (assume dbo.External_etoro_*)
print("\n--- Demotion status (using local dbo.External_*) ---")
verify_sql = """
;WITH cohort_dates AS (
    SELECT CONVERT(DATE,'20250818',112) AS d UNION ALL
    SELECT CONVERT(DATE,'20250819',112)      UNION ALL
    SELECT CONVERT(DATE,'20250820',112)      UNION ALL
    SELECT CONVERT(DATE,'20260522',112)      UNION ALL
    SELECT CONVERT(DATE,'20260523',112)      UNION ALL
    SELECT CONVERT(DATE,'20260525',112)
),
upstream_deposits AS (
    SELECT  CONVERT(INT, CONVERT(VARCHAR(8),fb.UTCBookingDate,112)) AS DateID
    ,       CONVERT(INT, c.RealCID) AS RealCID
    ,       CONVERT(DECIMAL(20,2), fb.Amount * fb.RatePerUSD)       AS AmountUSD
    ,       fb.UTCBookingDate
    FROM    dbo.External_etoro_Billing_Deposit fb
    JOIN    dbo.External_etoro_Customer_Customer c ON c.CID = fb.CID
    WHERE   fb.RatePerUSD > 0
        AND CONVERT(DATE, fb.UTCBookingDate) IN (SELECT d FROM cohort_dates)
),
ranked AS (
    SELECT  ud.*
    ,       ROW_NUMBER() OVER (PARTITION BY ud.RealCID ORDER BY ud.UTCBookingDate) AS rn
    FROM    upstream_deposits ud
),
first_deposit AS (
    SELECT  ud.RealCID
    FROM    ranked ud
    WHERE   ud.rn = 1
        AND ud.AmountUSD BETWEEN 0.95 AND 1.05
)
SELECT  ds.DateID
,       COUNT(*) AS bad_cohort_rows
,       SUM(CASE WHEN ds.IsDepositor       = 1 THEN 1 ELSE 0 END) AS bad_with_isdepositor_1
,       SUM(CASE WHEN ds.IsDepositorGlobal = 1 THEN 1 ELSE 0 END) AS bad_with_isdepositorglobal_1
,       SUM(CASE WHEN ds.IsFirstTimeDepositor = 1 THEN 1 ELSE 0 END) AS bad_with_ftd_1
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status ds
JOIN    first_deposit fd ON fd.RealCID = ds.RealCID
WHERE   ds.DateID IN (20260420, 20260522, 20260523, 20260525)
GROUP BY ds.DateID
ORDER BY ds.DateID;
"""
cur.execute(verify_sql)
cols = [c[0] for c in cur.description]
print("  " + " | ".join(cols))
for row in cur.fetchall():
    print("  " + " | ".join(str(v) for v in row))

print("\n--- Still-running EXEC on dev pool ---")
cur.execute("SELECT request_id, status, DATEDIFF(SECOND, start_time, GETDATE()) AS elapsed_s, SUBSTRING(command, 1, 100) AS snippet FROM sys.dm_pdw_exec_requests WHERE status IN ('Running','Suspended') AND command LIKE '%SP_DDR%' ORDER BY start_time")
for r in cur.fetchall():
    print(f"  {r}")

print(f"\n[{time.strftime('%H:%M:%S')}] Done.")
