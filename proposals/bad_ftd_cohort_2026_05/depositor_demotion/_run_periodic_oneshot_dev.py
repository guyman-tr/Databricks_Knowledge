"""Test the periodic_status one-shot on dev, plus catch-up the funded residue
on daily_status (since the daily one-shot was run before we added IsFunded /
FirstTimeFunded / FirstFundedDateID to the column list)."""
import time, pyodbc

SERVER = "stg-synapse-dataplatform-we.sql.azuresynapse.net"
DATABASE = "sql_dp_stg_we_BI_no_retention"

conn_str = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server={SERVER};Database={DATABASE};"
    "Authentication=ActiveDirectoryIntegrated;"
    "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=120;"
)

def ts(): return time.strftime("%H:%M:%S")

print(f"[{ts()}] Connecting via ActiveDirectoryIntegrated (Windows SSO)...")
conn = pyodbc.connect(conn_str, timeout=120)
conn.autocommit = True
cur = conn.cursor()
print(f"[{ts()}] Connected.")

# ----- STEP 0: build the full cohort (Aug + May) -----
print(f"\n[{ts()}] STEP 0: build #bad_cohort (Aug 2025 + May 2026)")
cur.execute("""
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
    SELECT fca.RealCID FROM DWH_dbo.Fact_CustomerAction fca
    WHERE  fca.ActionTypeID IN (7,44) AND fca.RealCID IS NOT NULL
    UNION ALL
    SELECT mfts.CID FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts
    WHERE  mfts.MoneyMoveDirection='MoneyIn' AND mfts.TxStatusID=2 AND mfts.TxTypeID IN (7,14) AND mfts.CID IS NOT NULL
),
multi_deposit_cids AS (
    SELECT RealCID FROM upstream_deposits GROUP BY RealCID HAVING COUNT(*) > 1
)
SELECT dc.RealCID
FROM   DWH_dbo.Dim_Customer dc
WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND  dc.FirstDepositAmount = 1
  AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID);
""")
cur.execute("SELECT COUNT(*) FROM #bad_cohort")
print(f"[{ts()}] cohort_size = {cur.fetchone()[0]}")

# ===========================================================================
# PART A: incremental funded-only catch-up on daily_status
# ===========================================================================
print(f"\n[{ts()}] PART A: catch-up funded residue on daily_status")

print(f"[{ts()}] pre-state:")
cur.execute("""
SELECT 'IsFunded_1'              AS metric, COUNT(*) AS n FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID=cs.RealCID WHERE cs.IsFunded=1
UNION ALL SELECT 'FirstTimeFunded_1',        COUNT(*)   FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID=cs.RealCID WHERE cs.FirstTimeFunded=1
UNION ALL SELECT 'FirstFundedDateID_notnull',COUNT(*)   FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID=cs.RealCID WHERE cs.FirstFundedDateID IS NOT NULL
""")
for r in cur.fetchall(): print(f"   {r[0]}: {r[1]}")

t0 = time.time()
cur.execute("""
UPDATE cs
SET    IsFunded          = 0,
       FirstTimeFunded   = 0,
       FirstFundedDateID = NULL,
       UpdateDate        = GETUTCDATE()
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN #bad_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.IsFunded = 1 OR cs.FirstTimeFunded = 1 OR cs.FirstFundedDateID IS NOT NULL
""")
print(f"[{ts()}] daily catch-up UPDATE rowcount={cur.rowcount} in {time.time()-t0:.1f}s")

print(f"[{ts()}] post-state:")
cur.execute("""
SELECT 'IsFunded_1'              AS metric, COUNT(*) AS n FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID=cs.RealCID WHERE cs.IsFunded=1
UNION ALL SELECT 'FirstTimeFunded_1',        COUNT(*)   FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID=cs.RealCID WHERE cs.FirstTimeFunded=1
UNION ALL SELECT 'FirstFundedDateID_notnull',COUNT(*)   FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs INNER JOIN #bad_cohort bc ON bc.RealCID=cs.RealCID WHERE cs.FirstFundedDateID IS NOT NULL
""")
for r in cur.fetchall(): print(f"   {r[0]}: {r[1]}")

# ===========================================================================
# PART B: periodic_status one-shot test
# ===========================================================================
print(f"\n[{ts()}] PART B: periodic_status one-shot test")

print(f"[{ts()}] pre-state (sample of 4 flag families x 4 windows):")
cur.execute("""
SELECT SUM(CAST(GlobalFirstDeposited_ThisWeek    AS INT)) AS gftd_w,
       SUM(CAST(GlobalFirstDeposited_ThisMonth   AS INT)) AS gftd_m,
       SUM(CAST(GlobalFirstDeposited_ThisQuarter AS INT)) AS gftd_q,
       SUM(CAST(GlobalFirstDeposited_ThisYear    AS INT)) AS gftd_y,
       SUM(CAST(GlobalDeposited_ThisWeek         AS INT)) AS gdep_w,
       SUM(CAST(GlobalDeposited_ThisMonth        AS INT)) AS gdep_m,
       SUM(CAST(IsFunded_ThisWeek                AS INT)) AS isfund_w,
       SUM(CAST(IsFunded_ThisYear                AS INT)) AS isfund_y,
       SUM(CAST(FirstTimeFunded_ThisMonth        AS INT)) AS firstfund_m,
       SUM(CAST(DepositedTP_ThisWeek             AS INT)) AS deptp_w,
       SUM(CAST(ReDepositedTP_ThisYear           AS INT)) AS redeptp_y
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER JOIN #bad_cohort bc ON bc.RealCID = ps.RealCID
""")
cols = [c[0] for c in cur.description]
row = cur.fetchone()
for c,v in zip(cols, row): print(f"   {c}: {v}")

# Also row count
cur.execute("SELECT COUNT(*) FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps INNER JOIN #bad_cohort bc ON bc.RealCID = ps.RealCID")
print(f"   periodic_rows_for_cohort: {cur.fetchone()[0]}")

print(f"\n[{ts()}] Running periodic demotion UPDATE...")
t0 = time.time()
cur.execute("""
UPDATE ps
SET
    TPFirstDeposited_ThisWeek            = 0,
    IBANFirstDeposited_ThisWeek          = 0,
    TPExternalFirstDeposited_ThisWeek    = 0,
    GlobalFirstDeposited_ThisWeek        = 0,
    OptionsFirstDeposited_ThisWeek       = 0,
    MoneyFarmFirstDeposited_ThisWeek     = 0,
    GlobalDeposited_ThisWeek             = 0,
    GlobalRedeposited_ThisWeek           = 0,
    DepositedTP_ThisWeek                 = 0,
    DepositedIBAN_ThisWeek               = 0,
    DepositedOptions_ThisWeek            = 0,
    ReDepositedTP_ThisWeek               = 0,
    ReDepositedIBAN_ThisWeek             = 0,
    ReDepositedOptions_ThisWeek          = 0,
    IsFunded_ThisWeek                    = 0,
    FirstTimeFunded_ThisWeek             = 0,

    TPFirstDeposited_ThisMonth           = 0,
    IBANFirstDeposited_ThisMonth         = 0,
    TPExternalFirstDeposited_ThisMonth   = 0,
    GlobalFirstDeposited_ThisMonth       = 0,
    OptionsFirstDeposited_ThisMonth      = 0,
    MoneyFarmFirstDeposited_ThisMonth    = 0,
    GlobalDeposited_ThisMonth            = 0,
    GlobalRedeposited_ThisMonth          = 0,
    DepositedTP_ThisMonth                = 0,
    DepositedIBAN_ThisMonth              = 0,
    DepositedOptions_ThisMonth           = 0,
    ReDepositedTP_ThisMonth              = 0,
    ReDepositedIBAN_ThisMonth            = 0,
    ReDepositedOptions_ThisMonth         = 0,
    IsFunded_ThisMonth                   = 0,
    FirstTimeFunded_ThisMonth            = 0,

    TPFirstDeposited_ThisQuarter         = 0,
    IBANFirstDeposited_ThisQuarter       = 0,
    TPExternalFirstDeposited_ThisQuarter = 0,
    GlobalFirstDeposited_ThisQuarter     = 0,
    OptionsFirstDeposited_ThisQuarter    = 0,
    MoneyFarmFirstDeposited_ThisQuarter  = 0,
    GlobalDeposited_ThisQuarter          = 0,
    GlobalRedeposited_ThisQuarter        = 0,
    DepositedTP_ThisQuarter              = 0,
    DepositedIBAN_ThisQuarter            = 0,
    DepositedOptions_ThisQuarter         = 0,
    ReDepositedTP_ThisQuarter            = 0,
    ReDepositedIBAN_ThisQuarter          = 0,
    ReDepositedOptions_ThisQuarter       = 0,
    IsFunded_ThisQuarter                 = 0,
    FirstTimeFunded_ThisQuarter          = 0,

    TPFirstDeposited_ThisYear            = 0,
    IBANFirstDeposited_ThisYear          = 0,
    TPExternalFirstDeposited_ThisYear    = 0,
    GlobalFirstDeposited_ThisYear        = 0,
    OptionsFirstDeposited_ThisYear       = 0,
    MoneyFarmFirstDeposited_ThisYear     = 0,
    GlobalDeposited_ThisYear             = 0,
    GlobalRedeposited_ThisYear           = 0,
    DepositedTP_ThisYear                 = 0,
    DepositedIBAN_ThisYear               = 0,
    DepositedOptions_ThisYear            = 0,
    ReDepositedTP_ThisYear               = 0,
    ReDepositedIBAN_ThisYear             = 0,
    ReDepositedOptions_ThisYear          = 0,
    IsFunded_ThisYear                    = 0,
    FirstTimeFunded_ThisYear             = 0,

    UpdateDate                           = GETUTCDATE()
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER JOIN #bad_cohort bc ON ps.RealCID = bc.RealCID
""")
print(f"[{ts()}] periodic UPDATE rowcount={cur.rowcount} in {time.time()-t0:.1f}s")

print(f"\n[{ts()}] post-state (must all be 0):")
cur.execute("""
SELECT SUM(CAST(GlobalFirstDeposited_ThisWeek    AS INT)) AS gftd_w,
       SUM(CAST(GlobalFirstDeposited_ThisMonth   AS INT)) AS gftd_m,
       SUM(CAST(GlobalFirstDeposited_ThisQuarter AS INT)) AS gftd_q,
       SUM(CAST(GlobalFirstDeposited_ThisYear    AS INT)) AS gftd_y,
       SUM(CAST(GlobalDeposited_ThisWeek         AS INT)) AS gdep_w,
       SUM(CAST(GlobalDeposited_ThisMonth        AS INT)) AS gdep_m,
       SUM(CAST(IsFunded_ThisWeek                AS INT)) AS isfund_w,
       SUM(CAST(IsFunded_ThisYear                AS INT)) AS isfund_y,
       SUM(CAST(FirstTimeFunded_ThisMonth        AS INT)) AS firstfund_m,
       SUM(CAST(DepositedTP_ThisWeek             AS INT)) AS deptp_w,
       SUM(CAST(ReDepositedTP_ThisYear           AS INT)) AS redeptp_y
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER JOIN #bad_cohort bc ON bc.RealCID = ps.RealCID
""")
cols = [c[0] for c in cur.description]
row = cur.fetchone()
for c,v in zip(cols, row): print(f"   {c}: {v}")

print(f"\n[{ts()}] per-snapshot-date spot check:")
cur.execute("""
SELECT  ps.DateID,
        COUNT(*) AS bad_cohort_rows,
        SUM(CAST(ps.GlobalFirstDeposited_ThisYear AS INT))  AS gftd_year_must_be_0,
        SUM(CAST(ps.GlobalDeposited_ThisYear      AS INT))  AS gdep_year_must_be_0,
        SUM(CAST(ps.IsFunded_ThisYear             AS INT))  AS isfund_year_must_be_0
FROM    BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER   JOIN #bad_cohort bc ON bc.RealCID = ps.RealCID
WHERE   ps.DateID IN (20250831, 20251231, 20260331, 20260529)
GROUP BY ps.DateID
ORDER BY ps.DateID
""")
for r in cur.fetchall(): print(f"   {r}")

cur.execute("IF OBJECT_ID('tempdb..#bad_cohort') IS NOT NULL DROP TABLE #bad_cohort")
print(f"\n[{ts()}] Done.")
