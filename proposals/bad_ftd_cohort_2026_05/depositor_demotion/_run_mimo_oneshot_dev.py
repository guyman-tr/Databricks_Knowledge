"""Run the MIMO Aug-2025 demotion one-shot against the dev pool."""
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
conn = pyodbc.connect(conn_str, timeout=120)
conn.autocommit = True
cur = conn.cursor()
print(f"[{ts()}] Connected.")

# ----- STEP A: build cohort temp table (Aug 2025 only) -----
print(f"\n[{ts()}] STEP A: build #bad_cohort_aug (Aug 2025 only)")
build_sql = """
IF OBJECT_ID('tempdb..#bad_cohort_aug') IS NOT NULL DROP TABLE #bad_cohort_aug;

CREATE TABLE #bad_cohort_aug
WITH (DISTRIBUTION = ROUND_ROBIN, HEAP)
AS
WITH cohort_dates AS (
    SELECT CONVERT(DATE,'20250818',112) AS d UNION ALL
    SELECT CONVERT(DATE,'20250819',112)      UNION ALL
    SELECT CONVERT(DATE,'20250820',112)
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

cur.execute("SELECT COUNT(*) FROM #bad_cohort_aug")
print(f"[{ts()}] aug_cohort_size = {cur.fetchone()[0]}")

# ----- STEP B: pre-UPDATE state on the 3 dates -----
print(f"\n[{ts()}] STEP B: pre-UPDATE MIMO state for Aug 2025 dates")
cur.execute("""
SELECT map.DateID,
       COUNT(*) AS bad_cohort_rows,
       SUM(CASE WHEN map.IsPlatformFTD=1 THEN 1 ELSE 0 END) AS pftd_1,
       SUM(CASE WHEN map.IsGlobalFTD=1   THEN 1 ELSE 0 END) AS gftd_1
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
INNER JOIN #bad_cohort_aug bc ON bc.RealCID = map.RealCID
WHERE  map.DateID IN (20250818, 20250819, 20250820)
GROUP BY map.DateID ORDER BY map.DateID
""")
for r in cur.fetchall():
    print(f"   {r}")

# ----- STEP C: the UPDATE -----
print(f"\n[{ts()}] STEP C: running MIMO demotion UPDATE...")
t0 = time.time()
cur.execute("""
UPDATE map
SET    IsPlatformFTD = 0,
       IsGlobalFTD   = 0
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
INNER JOIN #bad_cohort_aug bc ON map.RealCID = bc.RealCID
WHERE  map.DateID IN (20250818, 20250819, 20250820)
  AND  (map.IsPlatformFTD = 1 OR map.IsGlobalFTD = 1)
""")
print(f"[{ts()}] UPDATE complete in {time.time()-t0:.1f}s, rowcount={cur.rowcount}")

# ----- STEP D: post-UPDATE verification -----
print(f"\n[{ts()}] STEP D: post-UPDATE verification (all pftd/gftd must be 0)")
cur.execute("""
SELECT map.DateID,
       COUNT(*) AS bad_cohort_rows,
       SUM(CASE WHEN map.IsPlatformFTD=1 THEN 1 ELSE 0 END) AS pftd_1,
       SUM(CASE WHEN map.IsGlobalFTD=1   THEN 1 ELSE 0 END) AS gftd_1
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
INNER JOIN #bad_cohort_aug bc ON bc.RealCID = map.RealCID
WHERE  map.DateID IN (20250818, 20250819, 20250820)
GROUP BY map.DateID ORDER BY map.DateID
""")
for r in cur.fetchall():
    print(f"   {r}")

cur.execute("IF OBJECT_ID('tempdb..#bad_cohort_aug') IS NOT NULL DROP TABLE #bad_cohort_aug")
print(f"\n[{ts()}] Done.")
