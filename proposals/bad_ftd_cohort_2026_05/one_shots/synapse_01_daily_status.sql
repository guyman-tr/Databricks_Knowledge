/*===========================================================================
  01_synapse_demote_daily_status.sql

  Purpose : One-shot UPDATE on BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status to
            zero out depositor / FTD anchor columns for all 30,980 bad $1
            FTD cohort RealCIDs (Aug 2025 + May 2026), across every snapshot
            DateID >= the cohort's FirstDepositDate.

  Scope   : Synapse Dedicated SQL Pool (sql_dp_prod_we) -> BI_DB_dbo schema.

  Idempotent : Yes. Re-running zeros already-zeroed columns.

  Safety  :
    - INNER JOIN on a deterministic cohort temp table -> only bad cohort
      rows are touched.
    - All columns set to 0 / NULL / sentinel (30000101 for the Global_FTD_DateID
      "no FTD" sentinel used by the SP).
    - DOES NOT modify rows where DateID < FirstDepositDateID (cohort users
      were not yet customers there, so they're absent from daily_status anyway,
      but the join is safe).

  Pre-req  : DO NOT RUN until REQ-25250 (PR #3875) is merged + Synapse rerun
             script has been executed, otherwise the SP will overwrite the
             current etr_ymd row tonight.

  Estimated rows touched : ~30,980 RealCIDs x (5/31 - cohort_FTD_date) days
                          ~ 30,980 x ~285 avg days = ~8.8 M rows.

  Recommended : run in dev pool first, audit, then prod. Use a transaction
                in prod if your CI/CD supports it (Synapse DDL aside,
                UPDATE on a Delta-style HEAP/CLUSTERED COLUMNSTORE table can
                be wrapped in BEGIN TRAN / COMMIT TRAN if needed).
===========================================================================*/

/*---------------------------------------------------------------------------
  STEP 1 : Build cohort temp table
  Mirrors main.etoro_kpi_prep.v_bad_ftd_cohort + the REMOVE_BAD_FTDS CTE.
---------------------------------------------------------------------------*/
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
    SELECT RealCID
    FROM   upstream_deposits
    GROUP BY RealCID
    HAVING COUNT(*) > 1
)
SELECT dc.RealCID
FROM   DWH_dbo.Dim_Customer dc
WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND  dc.FirstDepositAmount = 1
  AND  NOT EXISTS (
        SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID
       );

/*---------------------------------------------------------------------------
  STEP 2 : Sanity check - expected ~30,980 rows
---------------------------------------------------------------------------*/
SELECT 'cohort_size' AS metric, COUNT(*) AS n FROM #bad_cohort;
-- Expected output ~ 30980 (13302 Aug 2025 + 17678 May 2026 as of 2026-06-01)

/*---------------------------------------------------------------------------
  STEP 3 : Demotion UPDATE on BI_DB_DDR_Customer_Daily_Status

  Columns zeroed (rationale per column):
    - IsDepositor / IsDepositorGlobal : the long-running depositor flags.
    - *_FTD_DateID / *_FTD_Date / *_FTDA : FTD anchors carried via TVF.
    - Global_FTD_DateID = 30000101 : SP's "no FTD" sentinel used by LEAST().
    - GlobalFirstDeposited / TPFirstDeposited / IBANFirstDeposited /
      OptionsFirstDeposited / MoneyFarmFirstDeposited / TPExternalFirstDeposited :
      one-shot first-deposit flags (will only be 1 on the FTD date).
    - LoggedInTPDepositor / LoggedInIBANDepositor / LoggedInGlobalDepositor :
      "user logged in AND is a depositor" - if not a depositor, force 0.

  Columns NOT touched:
    - GlobalDeposited / GlobalRedeposited / GlobalCashedOut / Redeemed /
      DepositedTP / DepositedIBAN / ReDepositedTP / ReDepositedIBAN /
      DepositedOptions / ReDepositedOptions : reflect raw MIMO action counts;
      already 0 for this cohort post REQ-25250 rerun and not depositor-flag.
    - IsFunded / FirstTimeFunded / FirstFundedDateID : funded != depositor;
      0 for this cohort anyway because $1 < min funding threshold.
    - ActiveTraded / BalanceOnlyAccount / Portfolio_Only / AccountActive /
      AccountInActive : segmentation orthogonal to depositor status.
    - RegulationID / CountryID / MarketingRegion / etc : customer attributes.
---------------------------------------------------------------------------*/
UPDATE cs
SET    IsDepositor              = 0,
       IsDepositorGlobal        = 0,

       IsFunded                 = 0,
       FirstTimeFunded          = 0,
       FirstFundedDateID        = NULL,

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
INNER JOIN #bad_cohort bc ON cs.RealCID = bc.RealCID;

/*---------------------------------------------------------------------------
  STEP 4 : Verification queries (run after UPDATE completes)
---------------------------------------------------------------------------*/
SELECT 'rows_remaining_with_IsDepositor_1' AS metric,
       COUNT(*) AS n
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN #bad_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.IsDepositor = 1 OR cs.IsDepositorGlobal = 1;
-- Expected: 0

SELECT 'rows_remaining_with_FTD_anchor' AS metric,
       COUNT(*) AS n
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN #bad_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.TP_FTD_DateID IS NOT NULL
   OR  cs.IBAN_FTD_DateID IS NOT NULL
   OR  cs.Options_FTD_DateID IS NOT NULL
   OR  cs.MoneyFarm_FTD_DateID IS NOT NULL
   OR  cs.Global_FTD_DateID <> 30000101;
-- Expected: 0

SELECT cs.DateID,
       COUNT(*) AS bad_cohort_rows,
       SUM(CAST(cs.IsDepositorGlobal AS INT)) AS dep_global_should_be_0,
       SUM(CAST(cs.GlobalFirstDeposited AS INT)) AS gftd_should_be_0
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN #bad_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.DateID IN (20250901, 20251201, 20260501, 20260531)
GROUP BY cs.DateID
ORDER BY cs.DateID;
-- All dep_global_should_be_0 and gftd_should_be_0 must be 0.

DROP TABLE #bad_cohort;
