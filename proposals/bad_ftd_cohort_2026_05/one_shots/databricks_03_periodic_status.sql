/*===========================================================================
  databricks_03_periodic_status.sql

  Purpose : One-shot UPDATE on
            main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
            to zero out all *FirstDeposited / *Deposited / *ReDeposited /
            IsFunded / FirstTimeFunded flags (per ThisWeek / ThisMonth /
            ThisQuarter / ThisYear) for the bad $1 FTD cohort.

  Scope   : Databricks Unity Catalog -> main.bi_db schema. This is the
            bronze mirror of Synapse BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.

  Why a UC one-shot in addition to the Synapse one-shot:
    The bronze sync from Synapse only refreshes rows in its incremental
    window (recent etr_ymd snapshots). Historical rows (back to 2025-08-18)
    do NOT get re-synced after the Synapse UPDATE, so the leak persists in
    UC even after synapse_03_periodic_status.sql runs in Synapse prod.
    This script cleans UC directly to match.

  Note    :
    The UC periodic_status table is still consumed at this stage. Once it
    is deprecated in favour of main.de_output.ddr_tvf_customer_periodic_status,
    this one-shot becomes unnecessary going forward.

  Reuses  : main.etoro_kpi_prep.v_bad_ftd_cohort

  Idempotent : Yes.

  Counterpart : synapse_03_periodic_status.sql (same column list on Synapse).

  Measured leak (queried 2026-06-02):
    bad_cohort_rows           : 4,941,423
    GlobalFirstDeposited_y=1  :    17,678   (matches May 2026 cohort)
    GlobalDeposited_y=1       :   176,283   (rolling 365-day window inflation)
    IsFunded_y=1              :       668
    FirstTimeFunded_y=1        :        74

  Estimated rows touched : ~30,985 RealCIDs x avg ~285 snapshot days
                          ~ 4.9 M rows (same order as Synapse).
===========================================================================*/

-- =============================================================
-- STEP 1 : Pre-flight sanity check
-- =============================================================
SELECT 'cohort_size' AS metric, COUNT(*) AS n
FROM   main.etoro_kpi_prep.v_bad_ftd_cohort;
-- Expected ~ 30985

SELECT 'pre_state' AS phase,
       COUNT(*) AS bad_cohort_rows,
       SUM(CAST(GlobalFirstDeposited_ThisYear AS INT)) AS gftd_y,
       SUM(CAST(GlobalDeposited_ThisYear      AS INT)) AS gdep_y,
       SUM(CAST(IsFunded_ThisYear             AS INT)) AS funded_y,
       SUM(CAST(FirstTimeFunded_ThisYear      AS INT)) AS first_funded_y
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
WHERE  RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);

-- =============================================================
-- STEP 2 : Demotion UPDATE on UC periodic_status
--
-- Columns zeroed (16 flag families x 4 time windows = 64 SET assignments):
--
--   *FirstDeposited                       : per-period FTD anchor flag.
--   GlobalDeposited / GlobalRedeposited   : any deposit/redeposit in window.
--   DepositedTP / IBAN / Options          : per-platform deposit flags.
--   ReDepositedTP / IBAN / Options        : per-platform redeposit flags.
--   IsFunded / FirstTimeFunded            : funded flags - bad cohort users
--                                           with only the bogus $1 deposit
--                                           must never count as funded.
--
-- Columns NOT touched:
--   ActiveTraded_* / Portfolio_Only_* / BalanceOnlyAccount_* : segmentation.
--   FirstActionType_*                                        : attribute.
--   IsCreditReportValidCB_* / IsValidCustomer_* / Mifid*     : attribute.
--   PlayerLevelID_* / CountryID_* / RegulationID_* / MarketingRegion_*
--                                                            : attribute.
--   GlobalCashedOut_* / Redeemed_*                           : withdrawal-side.
-- =============================================================
UPDATE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
SET
    -- ThisWeek
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

    -- ThisMonth
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

    -- ThisQuarter
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

    -- ThisYear
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

    UpdateDate                           = CURRENT_TIMESTAMP()
WHERE RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);

-- =============================================================
-- STEP 3 : Verification - all 12 sampled metrics must be 0
-- =============================================================
SELECT 'post_state' AS phase,
       SUM(CAST(GlobalFirstDeposited_ThisWeek    AS INT)) AS gftd_w,
       SUM(CAST(GlobalFirstDeposited_ThisMonth   AS INT)) AS gftd_m,
       SUM(CAST(GlobalFirstDeposited_ThisQuarter AS INT)) AS gftd_q,
       SUM(CAST(GlobalFirstDeposited_ThisYear    AS INT)) AS gftd_y,
       SUM(CAST(GlobalDeposited_ThisWeek         AS INT)) AS gdep_w,
       SUM(CAST(GlobalDeposited_ThisMonth        AS INT)) AS gdep_m,
       SUM(CAST(GlobalDeposited_ThisQuarter      AS INT)) AS gdep_q,
       SUM(CAST(GlobalDeposited_ThisYear         AS INT)) AS gdep_y,
       SUM(CAST(IsFunded_ThisYear                AS INT)) AS isfund_y,
       SUM(CAST(FirstTimeFunded_ThisYear         AS INT)) AS ftfund_y,
       SUM(CAST(GlobalRedeposited_ThisYear       AS INT)) AS gred_y,
       SUM(CAST(DepositedTP_ThisYear             AS INT)) AS dtp_y
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
WHERE  RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);
-- All 12 columns must be 0.

SELECT DateID,
       COUNT(*) AS bad_cohort_rows,
       SUM(CAST(GlobalFirstDeposited_ThisYear AS INT)) AS gftd_year_should_be_0,
       SUM(CAST(GlobalDeposited_ThisYear      AS INT)) AS gdep_year_should_be_0,
       SUM(CAST(IsFunded_ThisYear             AS INT)) AS funded_year_should_be_0
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
WHERE  RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort)
  AND  DateID IN (20250831, 20251231, 20260331, 20260529)
GROUP BY DateID
ORDER BY DateID;
-- All *_should_be_0 columns must be 0.

-- =============================================================
-- OPTIONAL : Vacuum / Optimize after the large UPDATE
-- =============================================================
-- OPTIMIZE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status;
-- VACUUM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status RETAIN 168 HOURS;
