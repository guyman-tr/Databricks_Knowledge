/*===========================================================================
  databricks_02_mimo_allplatforms.sql

  Purpose : One-shot UPDATE on
            main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
            to zero IsPlatformFTD (and IsGlobalFTD belt-and-suspenders) for
            the bad $1 FTD cohort across all 6 bad-FTD dates.

  Why     :
    The DBX MIMO view (v_mimo_allplatforms) has the REMOVE_BAD_FTDS filter
    so going-forward rebuilds drop the bad cohort. But historical rows
    written before the filter still carry IsPlatformFTD=1 for the bad
    cohort. Measured leak (queried 2026-06-01):

      DateID    rows_in_cohort  IsPlatformFTD=1  IsGlobalFTD=1
      20250819      10,383           0               0
      20250820       2,924         2,924             2
      20260522      17,201           0               0
      20260523         467           467             0
      20260525          10            10             0
      ---------------------------------------------------------
      Total                       3,401 PFTD       2 GFTD

  Counterpart : synapse_02_mimo_allplatforms.sql (same logic on Synapse,
                Aug-only because REQ-25250 SP rerun handles May 2026
                on the Synapse side). DBX has no equivalent rerun yet,
                so this script covers BOTH Aug 2025 AND May 2026 dates.

  Reuses  : main.etoro_kpi_prep.v_bad_ftd_cohort

  Idempotent : Yes.
===========================================================================*/

-- =============================================================
-- STEP 1 : Pre-flight sanity check
-- =============================================================
SELECT 'cohort_size' AS metric, COUNT(*) AS n
FROM   main.etoro_kpi_prep.v_bad_ftd_cohort;
-- Expected ~ 30985

SELECT DateID,
       COUNT(*)              AS rows_in_cohort,
       SUM(IsPlatformFTD)    AS pftd,
       SUM(IsGlobalFTD)      AS gftd
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE  DateID IN (20250818, 20250819, 20250820, 20260522, 20260523, 20260525)
  AND  RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
GROUP BY DateID
ORDER BY DateID;
-- See "Why" block above for expected leak per date.

-- =============================================================
-- STEP 2 : Demotion UPDATE
--
-- Scope: any row where IsPlatformFTD=1 or IsGlobalFTD=1 for a bad cohort
-- RealCID on a bad FTD date. We do not touch other MIMO action rows
-- (Trade / CashOut / etc) — the FTD anchor flags are the only thing
-- that needs zeroing; the actual deposit amount rows are independent.
-- =============================================================
UPDATE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
SET    IsPlatformFTD = 0,
       IsGlobalFTD   = 0,
       UpdateDate    = CURRENT_TIMESTAMP()
WHERE  DateID IN (20250818, 20250819, 20250820, 20260522, 20260523, 20260525)
  AND  RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
  AND  (IsPlatformFTD = 1 OR IsGlobalFTD = 1);

-- =============================================================
-- STEP 3 : Verification
-- =============================================================
SELECT DateID,
       COUNT(*)                      AS rows_in_cohort,
       SUM(IsPlatformFTD)            AS pftd_should_be_0,
       SUM(IsGlobalFTD)              AS gftd_should_be_0
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE  DateID IN (20250818, 20250819, 20250820, 20260522, 20260523, 20260525)
  AND  RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
GROUP BY DateID
ORDER BY DateID;
-- pftd_should_be_0 and gftd_should_be_0 must both be 0 for every date.

-- =============================================================
-- OPTIONAL : Vacuum / Optimize after the UPDATE
-- =============================================================
-- OPTIMIZE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms;
-- VACUUM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms RETAIN 168 HOURS;
