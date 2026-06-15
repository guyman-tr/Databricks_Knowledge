"""Run the historical daily_status demotion one-shot against the dev pool.

Strategy:
  1. Open ONE connection (so #bad_cohort survives across steps).
  2. STEP A: build cohort -> SELECT size
  3. STEP B: pre-UPDATE diagnostic (rows currently still flagged 1 across all dates)
  4. STEP C: run the UPDATE, capture rowcount
  5. STEP D: post-UPDATE verification (must be 0)

Because dev pool's Dim_Customer is older than today, only the Aug 2025 portion
of the cohort will be present (~13K CIDs).
"""
import time, pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"
UID = "guyman@etoro.com"

conn_str = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server={SERVER};Database={DATABASE};"
    "Authentication=ActiveDirectoryIntegrated;"
    "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=120;"
)

def ts(): return time.strftime("%H:%M:%S")

print(f"[{ts()}] Connecting to dev pool as {UID}...")
print(f"[{ts()}] >>> If a Windows auth popup appears, please respond. <<<")
conn = pyodbc.connect(conn_str, timeout=120)
conn.autocommit = True
cur = conn.cursor()
print(f"[{ts()}] Connected.")

# ----- STEP A: build cohort temp table -----
print(f"\n[{ts()}] STEP A: build #bad_cohort temp table")
build_sql = """
IF OBJECT_ID('tempdb..#bad_cohort') IS NOT NULL DROP TABLE #bad_cohort;

CREATE TABLE #bad_cohort
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP)
AS
WITH cohort_dates AS (
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
    WHERE  fca.ActionTypeID IN (7, 44) AND fca.RealCID IS NOT NULL
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
)
SELECT dc.RealCID
FROM   DWH_dbo.Dim_Customer dc
WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND  dc.FirstDepositAmount = 1
  AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID);
"""
t0 = time.time()
cur.execute(build_sql)
print(f"[{ts()}] cohort built in {time.time()-t0:.1f}s")

cur.execute("SELECT COUNT(*) FROM #bad_cohort")
cohort_n = cur.fetchone()[0]
print(f"[{ts()}] cohort_size = {cohort_n}")

# Also break it down by FirstDepositDate so we can see Aug 2025 vs May 2026
cur.execute("""
SELECT CAST(dc.FirstDepositDate AS DATE) AS ftd, COUNT(*) AS n
FROM   DWH_dbo.Dim_Customer dc
INNER JOIN #bad_cohort bc ON bc.RealCID = dc.RealCID
GROUP BY CAST(dc.FirstDepositDate AS DATE)
ORDER BY ftd
""")
for r in cur.fetchall():
    print(f"   {r[0]}: {r[1]}")

# ----- STEP B: pre-UPDATE diagnostic -----
print(f"\n[{ts()}] STEP B: pre-UPDATE state (rows for cohort with depositor flags)")
cur.execute("""
SELECT  'pre_isdepositor_1'       AS metric, COUNT(*) AS n
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.IsDepositor = 1
UNION ALL
SELECT  'pre_isdepositorglobal_1', COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.IsDepositorGlobal = 1
UNION ALL
SELECT  'pre_global_ftda_nonzero', COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.Global_FTDA <> 0
UNION ALL
SELECT  'pre_tp_ftd_dateid_notnull', COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.TP_FTD_DateID IS NOT NULL
""")
for r in cur.fetchall():
    print(f"   {r[0]}: {r[1]}")

# ----- STEP C: the UPDATE -----
print(f"\n[{ts()}] STEP C: running demotion UPDATE...")
update_sql = """
UPDATE cs
SET    IsDepositor              = 0,
       IsDepositorGlobal        = 0,

       TP_FTD_DateID            = NULL,
       TP_FTD_Date              = NULL,
       TP_FTDA                  = 0,
       TP_External_FTDA         = 0,

       IBAN_FTD_DateID          = NULL,
       IBAN_FTD_Date            = NULL,
       IBAN_FTDA                = 0,

       Options_FTD_DateID       = NULL,
       Options_FTD_Date         = NULL,
       Options_FTDA             = 0,

       MoneyFarm_FTD_DateID     = NULL,
       MoneyFarm_FTD_Date       = NULL,
       MoneyFarm_FTDA           = 0,

       Global_FTD_DateID        = 30000101,
       Global_FTD_Date          = NULL,
       Global_FTDA              = 0,

       GlobalFirstDeposited     = 0,
       TPFirstDeposited         = 0,
       IBANFirstDeposited       = 0,
       OptionsFirstDeposited    = 0,
       MoneyFarmFirstDeposited  = 0,
       TPExternalFirstDeposited = 0,

       LoggedInTPDepositor      = 0,
       LoggedInIBANDepositor    = 0,
       LoggedInGlobalDepositor  = 0,

       UpdateDate               = GETUTCDATE()
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN #bad_cohort bc ON cs.RealCID = bc.RealCID
"""
t0 = time.time()
cur.execute(update_sql)
rc = cur.rowcount
print(f"[{ts()}] UPDATE complete in {time.time()-t0:.1f}s, rowcount={rc}")

# ----- STEP D: post-UPDATE verification -----
print(f"\n[{ts()}] STEP D: post-UPDATE verification (all must be 0)")
cur.execute("""
SELECT  'post_isdepositor_1'              AS metric, COUNT(*) AS n
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.IsDepositor = 1
UNION ALL
SELECT  'post_isdepositorglobal_1'        , COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.IsDepositorGlobal = 1
UNION ALL
SELECT  'post_global_ftda_nonzero'         , COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.Global_FTDA <> 0
UNION ALL
SELECT  'post_any_ftd_anchor_set'          , COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.TP_FTD_DateID IS NOT NULL
   OR   cs.IBAN_FTD_DateID IS NOT NULL
   OR   cs.Options_FTD_DateID IS NOT NULL
   OR   cs.MoneyFarm_FTD_DateID IS NOT NULL
   OR   cs.Global_FTD_DateID <> 30000101
UNION ALL
SELECT  'post_first_deposited_flag_set'    , COUNT(*)
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.GlobalFirstDeposited = 1
   OR   cs.TPFirstDeposited = 1
   OR   cs.IBANFirstDeposited = 1
   OR   cs.OptionsFirstDeposited = 1
   OR   cs.MoneyFarmFirstDeposited = 1
   OR   cs.TPExternalFirstDeposited = 1
""")
for r in cur.fetchall():
    print(f"   {r[0]}: {r[1]}")

# Also a per-date spot check
print(f"\n[{ts()}] STEP D2: per-date spot check (across cohort lifetime)")
cur.execute("""
SELECT  cs.DateID,
        COUNT(*) AS bad_cohort_rows,
        SUM(CASE WHEN cs.IsDepositor = 1 THEN 1 ELSE 0 END)         AS isdep_1,
        SUM(CASE WHEN cs.IsDepositorGlobal = 1 THEN 1 ELSE 0 END)   AS isdep_global_1,
        SUM(CASE WHEN cs.GlobalFirstDeposited = 1 THEN 1 ELSE 0 END) AS gftd_1
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER   JOIN #bad_cohort bc ON bc.RealCID = cs.RealCID
WHERE   cs.DateID IN (20250818, 20250901, 20251001, 20260101, 20260420, 20260522, 20260525, 20260529)
GROUP BY cs.DateID
ORDER BY cs.DateID
""")
for r in cur.fetchall():
    print(f"   {r}")

cur.execute("IF OBJECT_ID('tempdb..#bad_cohort') IS NOT NULL DROP TABLE #bad_cohort")

print(f"\n[{ts()}] Done.")
