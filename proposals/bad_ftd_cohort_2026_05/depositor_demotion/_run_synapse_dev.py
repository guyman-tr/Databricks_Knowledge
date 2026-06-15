"""Execute SP_DDR_Customer_Daily_Status on dev pool for two dates and verify demotion."""
import sys, time, pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"

conn_str = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server={SERVER};Database={DATABASE};"
    f"UID={UID};"
    "Authentication=ActiveDirectoryInteractive;"
    "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=120;"
)

def ts():
    return time.strftime("%H:%M:%S")

print(f"[{ts()}] Connecting...")
conn = pyodbc.connect(conn_str, timeout=120)
conn.autocommit = True
cur = conn.cursor()
print(f"[{ts()}] Connected.")

DATES = ["2026-04-20", "2026-05-22"]
for d in DATES:
    print(f"\n[{ts()}] EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '{d}' ...")
    t0 = time.time()
    try:
        cur.execute(f"EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status '{d}'")
        # Consume any result sets so the connection is ready
        while True:
            try:
                if not cur.nextset():
                    break
            except pyodbc.ProgrammingError:
                break
        print(f"[{ts()}] EXEC {d} OK in {time.time()-t0:.1f}s")
    except Exception as e:
        print(f"[{ts()}] EXEC {d} FAIL: {e}")
        sys.exit(2)

print(f"\n[{ts()}] Verifying demotion...")
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
    FROM    sql_dp_prod_we_BI.dbo.External_etoro_Billing_Deposit fb
    JOIN    sql_dp_prod_we_BI.dbo.External_etoro_Customer_Customer c ON c.CID = fb.CID
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
WHERE   ds.DateID IN (20260420, 20260522)
GROUP BY ds.DateID
ORDER BY ds.DateID;
"""
cur.execute(verify_sql)
cols = [c[0] for c in cur.description]
print("  | ".join(cols))
for row in cur.fetchall():
    print("  | ".join(str(v) for v in row))

print(f"\n[{ts()}] Done.")
