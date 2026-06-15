"""Verify v3: use the actual cohort logic from the SP (local tables only)."""
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
    SELECT fca.RealCID
    FROM   DWH_dbo.Fact_CustomerAction fca
    WHERE  fca.ActionTypeID IN (7, 44)
      AND  fca.RealCID IS NOT NULL
    UNION ALL
    SELECT mfts.CID AS RealCID
    FROM   eMoney_dbo.eMoney_Fact_Transaction_Status mfts
    WHERE  mfts.MoneyMoveDirection = 'MoneyIn'
      AND  mfts.TxStatusID = 2
      AND  mfts.TxTypeID IN (7, 14)
      AND  mfts.CID IS NOT NULL
),
multi_deposit_cids AS (
    SELECT RealCID FROM upstream_deposits GROUP BY RealCID HAVING COUNT(*) > 1
),
bad_cohort AS (
    SELECT dc.RealCID
    FROM   DWH_dbo.Dim_Customer dc
    WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
      AND  dc.FirstDepositAmount = 1
      AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID)
)
SELECT  ds.DateID
,       COUNT(*) AS bad_cohort_rows
,       SUM(CASE WHEN ds.IsDepositor       = 1 THEN 1 ELSE 0 END) AS bad_with_isdepositor_1
,       SUM(CASE WHEN ds.IsDepositorGlobal = 1 THEN 1 ELSE 0 END) AS bad_with_isdepositorglobal_1
,       SUM(CASE WHEN ds.GlobalFirstDeposited = 1 THEN 1 ELSE 0 END) AS bad_with_global_first_dep_1
,       SUM(CASE WHEN ds.Global_FTDA <> 0 THEN 1 ELSE 0 END) AS bad_with_global_ftda_nonzero
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status ds
JOIN    bad_cohort bc ON bc.RealCID = ds.RealCID
WHERE   ds.DateID IN (20260420, 20260522, 20260523, 20260525)
GROUP BY ds.DateID
ORDER BY ds.DateID;
"""

print("\nDemotion status by DateID (bad-cohort rows still flagged as depositors):")
cur.execute(verify_sql)
cols = [c[0] for c in cur.description]
print("  " + " | ".join(cols))
rows = cur.fetchall()
for row in rows:
    print("  " + " | ".join(str(v) for v in row))

print("\n--- Still-running SP_DDR on dev pool ---")
cur.execute("SELECT request_id, status, DATEDIFF(SECOND, start_time, GETDATE()) AS elapsed_s, SUBSTRING(command, 1, 100) AS snippet FROM sys.dm_pdw_exec_requests WHERE status IN ('Running','Suspended') AND command LIKE '%SP_DDR%' ORDER BY start_time")
for r in cur.fetchall():
    print(f"  {r}")

print(f"\n[{time.strftime('%H:%M:%S')}] Done.")
