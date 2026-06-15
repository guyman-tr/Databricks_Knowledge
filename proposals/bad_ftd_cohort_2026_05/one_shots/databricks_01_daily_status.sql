/*===========================================================================
  databricks_01_daily_status.sql

  Purpose : One-shot UPDATE on
            main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
            to zero out depositor / FTD anchor / funded columns for all
            ~30,985 bad $1 FTD cohort RealCIDs across every snapshot DateID.

  Scope   : Databricks Unity Catalog -> main.bi_db schema. This is the
            target table that main.de_output.sp_ddr_customer_daily_status
            DELETE/INSERTs into per etr_ymd.

  Reuses  : main.etoro_kpi_prep.v_bad_ftd_cohort  (already deployed)

  Idempotent : Yes. Re-running zeros already-zeroed columns.

  Counterpart : synapse_01_daily_status.sql (same logic on Synapse).
                Run both — Synapse for the source, DBX for the bronze mirror
                + DBX-native rebuilds.

  Pre-req : Patched main.de_output.sp_ddr_customer_daily_status is already
            deployed (REQ-25250). The patched SP includes a final demotion
            UPDATE that handles the current etr_ymd on each rebuild, so this
            one-shot only needs to clean up historical etr_ymd rows.

  Estimated rows : ~30,985 RealCIDs x avg ~285 days = ~8.8M rows.
                   Delta UPDATE on a partitioned table — plan for ~5-15 min
                   on serverless SQL warehouse depending on size class.
===========================================================================*/

-- =============================================================
-- STEP 1 : Pre-flight sanity check
-- =============================================================
SELECT 'cohort_size' AS metric, COUNT(*) AS n
FROM   main.etoro_kpi_prep.v_bad_ftd_cohort;
-- Expected ~ 30985

SELECT 'rows_to_demote' AS metric,
       COUNT(*) AS n,
       SUM(CAST(cs.IsDepositor AS INT))        AS dep,
       SUM(CAST(cs.IsDepositorGlobal AS INT))  AS dep_global,
       SUM(CAST(cs.IsFunded AS INT))           AS funded,
       SUM(CAST(cs.FirstTimeFunded AS INT))    AS first_funded,
       SUM(CASE WHEN cs.FirstFundedDateID IS NOT NULL THEN 1 ELSE 0 END) AS first_funded_date_set
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cs
WHERE  cs.RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);

-- =============================================================
-- STEP 2 : Demotion UPDATE
--
-- Columns zeroed (rationale per column):
--   IsDepositor / IsDepositorGlobal : long-running depositor flags.
--   IsFunded / FirstTimeFunded / FirstFundedDateID : funded flags. Bad
--     cohort users whose only deposit was the bogus $1 should NOT count
--     as funded customers in any KPI.
--   *_FTD_DateID / *_FTD_Date / *_FTDA : FTD anchors carried via TVF.
--   Global_FTD_DateID = 30000101 : SP's "no FTD" sentinel used by LEAST().
--   *FirstDeposited : one-shot first-deposit flags.
--   LoggedIn*Depositor : "user logged in AND is a depositor" — force 0.
--
-- Columns NOT touched:
--   GlobalDeposited / GlobalRedeposited / GlobalCashedOut / Redeemed /
--     DepositedTP / DepositedIBAN / ReDepositedTP / ReDepositedIBAN /
--     DepositedOptions / ReDepositedOptions : raw MIMO action counts;
--     already 0 for this cohort post REQ-25250 rerun (TVF filters them).
--   ActiveTraded / BalanceOnlyAccount / Portfolio_Only / AccountActive /
--     AccountInActive : segmentation orthogonal to depositor status.
--   RegulationID / CountryID / MarketingRegion / etc : customer attributes.
-- =============================================================
UPDATE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
SET
    IsDepositor              = 0,
    IsDepositorGlobal        = 0,

    IsFunded                 = 0,
    FirstTimeFunded          = 0,
    FirstFundedDateID        = NULL,

    TP_FTD_DateID            = NULL,
    TP_FTD_Date              = NULL,
    TP_FTDA                  = CAST(0 AS DECIMAL(16,6)),
    TP_External_FTDA         = CAST(0 AS DECIMAL(16,6)),

    IBAN_FTD_DateID          = NULL,
    IBAN_FTD_Date            = NULL,
    IBAN_FTDA                = CAST(0 AS DECIMAL(16,6)),

    Options_FTD_DateID       = NULL,
    Options_FTD_Date         = NULL,
    Options_FTDA             = CAST(0 AS DECIMAL(19,4)),

    MoneyFarm_FTD_DateID     = NULL,
    MoneyFarm_FTD_Date       = NULL,
    MoneyFarm_FTDA           = CAST(0 AS DECIMAL(19,4)),

    Global_FTD_DateID        = 30000101,
    Global_FTD_Date          = NULL,
    Global_FTDA              = CAST(0 AS DECIMAL(16,6)),

    GlobalFirstDeposited     = 0,
    TPFirstDeposited         = 0,
    IBANFirstDeposited       = 0,
    OptionsFirstDeposited    = 0,
    MoneyFarmFirstDeposited  = 0,
    TPExternalFirstDeposited = 0,

    LoggedInTPDepositor      = 0,
    LoggedInIBANDepositor    = 0,
    LoggedInGlobalDepositor  = 0,

    UpdateDate               = CURRENT_TIMESTAMP()
WHERE RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);

-- =============================================================
-- STEP 3 : Verification
-- =============================================================
SELECT 'rows_remaining_with_IsDepositor_1' AS metric, COUNT(*) AS n
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cs
WHERE  cs.RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
  AND  (cs.IsDepositor = 1 OR cs.IsDepositorGlobal = 1);
-- Expected: 0

SELECT 'rows_remaining_with_FTD_anchor' AS metric, COUNT(*) AS n
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cs
WHERE  cs.RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
  AND  (cs.TP_FTD_DateID IS NOT NULL
        OR cs.IBAN_FTD_DateID IS NOT NULL
        OR cs.Options_FTD_DateID IS NOT NULL
        OR cs.MoneyFarm_FTD_DateID IS NOT NULL
        OR cs.Global_FTD_DateID <> 30000101);
-- Expected: 0

SELECT 'rows_remaining_with_funded_set' AS metric, COUNT(*) AS n
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cs
WHERE  cs.RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
  AND  (cs.IsFunded = 1
        OR cs.FirstTimeFunded = 1
        OR cs.FirstFundedDateID IS NOT NULL);
-- Expected: 0

SELECT cs.DateID,
       COUNT(*) AS bad_cohort_rows,
       SUM(CAST(cs.IsDepositorGlobal AS INT))    AS dep_global_should_be_0,
       SUM(CAST(cs.GlobalFirstDeposited AS INT)) AS gftd_should_be_0,
       SUM(CAST(cs.IsFunded AS INT))             AS funded_should_be_0
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cs
WHERE  cs.RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
  AND  cs.DateID IN (20250901, 20251201, 20260501, 20260531)
GROUP BY cs.DateID
ORDER BY cs.DateID;
-- All *_should_be_0 columns must be 0.

-- =============================================================
-- OPTIONAL : Vacuum / Optimize after large UPDATE
-- =============================================================
-- OPTIMIZE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status;
-- VACUUM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status RETAIN 168 HOURS;
