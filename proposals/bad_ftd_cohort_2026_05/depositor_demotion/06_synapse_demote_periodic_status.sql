/*===========================================================================
  06_synapse_demote_periodic_status.sql

  Purpose : One-shot UPDATE on BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status
            to zero out all xFirstDeposited / xDeposited / xReDeposited flags
            (for ThisWeek / ThisMonth / ThisQuarter / ThisYear) for the bad
            $1 FTD cohort.

  Why     :
    Periodic_Status is built by SP_DDR_Customer_Periodic_Status as MAX(...)
    over the daily snapshots inside each window. Since the daily_status
    rows had IsDepositor / *FirstDeposited / *Deposited flags = 1 for the
    bad cohort (until the REQ-25250 SP patch + one-shot demotion), those 1s
    propagated into the weekly/monthly/quarterly/yearly aggregates.

    Going forward, the SP will pick up the daily_status zeros on next rebuild
    (the periodic SP just MAXes whatever it sees), but historical rows are
    already written with 1s and need a one-shot zeroing.

  Note    :
    You said "in UC I want to eliminate, NOT in Synapse" - so Synapse keeps
    its periodic_status table and we patch it here. UC's
    sp_ddr_customer_periodic_status table will be deprecated separately.

  Scope   : Synapse Dedicated SQL Pool (sql_dp_prod_we) -> BI_DB_dbo schema.

  Idempotent : Yes.
  Safety     : INNER JOIN on deterministic cohort temp table -> only cohort
               CIDs are touched. No DateID filter -> spans the full lifetime
               of each row (the table holds one row per RealCID per snapshot
               date, with rolling Week/Month/Qtr/Year aggregates).

  Pre-req    : Run AFTER 01_synapse_demote_daily_status.sql (so the underlying
               daily snapshots are zeroed). Re-running 06 after a periodic SP
               rebuild is safe.

  Estimated rows touched : ~30,980 RealCIDs x avg ~285 snapshot days
                          ~ 8.8 M rows (same order as daily_status).
===========================================================================*/

/*---------------------------------------------------------------------------
  STEP 1 : Build cohort temp table (same cohort def as the daily script)
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
  AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID);

/*---------------------------------------------------------------------------
  STEP 2 : Sanity check
---------------------------------------------------------------------------*/
SELECT 'cohort_size' AS metric, COUNT(*) AS n FROM #bad_cohort;

/*---------------------------------------------------------------------------
  STEP 3 : Demotion UPDATE on BI_DB_DDR_Customer_Periodic_Status.

  Columns zeroed (per the periodic SP's MAX(...) logic, all 4 time windows
  per column family):

    *FirstDeposited      : the per-period anchor flag - 1 if FTD inside
                           the period. Cohort never made a real FTD -> 0.
    GlobalDeposited      : 1 if any successful deposit inside the period.
                           Cohort's only deposit was the bad $1 -> 0.
    GlobalRedeposited    : 1 if any redeposit (second deposit) inside the
                           period. Cohort users have at most 1 deposit
                           (multi_deposit_cids filter) -> 0.
    DepositedTP / IBAN / Options          : per-platform deposit flags.
    ReDepositedTP / IBAN / Options        : per-platform redeposit flags.

  Columns NOT touched (per the daily-status one-shot's same logic):
    Funded / FirstTimeFunded   : funded != depositor.
    ActiveTraded / Portfolio_Only / BalanceOnly  : segmentation.
    IsCreditReportValid / IsValidCustomer / Mifid / PlayerLevel  : attr.
    Country / Regulation / MarketingRegion       : attr.
    FirstActionType                              : attr.
    Redeemed                                     : withdrawal-side, orthogonal.
---------------------------------------------------------------------------*/
UPDATE ps
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

    UpdateDate                           = GETUTCDATE()
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER JOIN #bad_cohort bc ON ps.RealCID = bc.RealCID;

/*---------------------------------------------------------------------------
  STEP 4 : Verification - all must be 0
---------------------------------------------------------------------------*/
SELECT
    SUM(CAST(GlobalFirstDeposited_ThisWeek    AS INT)) AS gftd_w,
    SUM(CAST(GlobalFirstDeposited_ThisMonth   AS INT)) AS gftd_m,
    SUM(CAST(GlobalFirstDeposited_ThisQuarter AS INT)) AS gftd_q,
    SUM(CAST(GlobalFirstDeposited_ThisYear    AS INT)) AS gftd_y,
    SUM(CAST(GlobalDeposited_ThisWeek         AS INT)) AS gdep_w,
    SUM(CAST(GlobalDeposited_ThisMonth        AS INT)) AS gdep_m,
    SUM(CAST(GlobalDeposited_ThisQuarter      AS INT)) AS gdep_q,
    SUM(CAST(GlobalDeposited_ThisYear         AS INT)) AS gdep_y,
    SUM(CAST(GlobalRedeposited_ThisWeek       AS INT)) AS gred_w,
    SUM(CAST(GlobalRedeposited_ThisMonth      AS INT)) AS gred_m,
    SUM(CAST(GlobalRedeposited_ThisQuarter    AS INT)) AS gred_q,
    SUM(CAST(GlobalRedeposited_ThisYear       AS INT)) AS gred_y
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER JOIN #bad_cohort bc ON ps.RealCID = bc.RealCID;
-- All 12 columns must be 0.

SELECT ps.DateID,
       COUNT(*) AS bad_cohort_rows,
       SUM(CAST(ps.GlobalFirstDeposited_ThisYear AS INT))    AS gftd_year_should_be_0,
       SUM(CAST(ps.GlobalDeposited_ThisYear      AS INT))    AS gdep_year_should_be_0
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status ps
INNER JOIN #bad_cohort bc ON ps.RealCID = bc.RealCID
WHERE  ps.DateID IN (20250831, 20251231, 20260331, 20260529)
GROUP BY ps.DateID
ORDER BY ps.DateID;
-- All gftd_year_should_be_0 / gdep_year_should_be_0 must be 0.

DROP TABLE #bad_cohort;
