/*===========================================================================
  04_synapse_sp_patch_daily_status.sql

  Purpose : Patch snippet to add to Synapse SP_DDR_Customer_Daily_Status so
            that every nightly run automatically zeros IsDepositor /
            IsDepositorGlobal / FTD anchor columns for the bad $1 FTD cohort.

  Why     : The one-shot UPDATE (script 01) only fixes historical rows.
            Without this SP patch, tonight's run of the SP will write
            IsDepositor=1 for the bad cohort's row on the new etr_ymd
            (because the SP reads bs.IsDepositor from snapshotcustomer
            without any cohort filter), re-introducing Bug #2.

  Pattern : Same shape as the final demotion UPDATE we added to
            SP_DDR_Fact_Fact_MIMO_AllPlatforms in REQ-25250 - run at the
            very end of the procedure after the main INSERT, scoped to the
            current @date_id only.

  How to apply :
    1. Open the existing SP in DataPlatform repo:
       SynapseSQLPool1/sql_dp_prod_we/BI_DB_dbo/Stored Procedures/
         BI_DB_dbo.SP_DDR_Customer_Daily_Status.sql
    2. Locate the last statement before END (likely the main INSERT INTO
       BI_DB_DDR_Customer_Daily_Status, then any UpdateDate housekeeping).
    3. Insert the block below immediately before END.
    4. Bump the change history header with REQ ticket reference.
    5. Open a PR; CI will replace ALTER -> CREATE OR ALTER as usual.

  Self-contained CTE so we don't depend on any view.
===========================================================================*/

----------------------------------------------------------------------------
-- BEGIN PATCH BLOCK (insert at end of SP_DDR_Customer_Daily_Status)
----------------------------------------------------------------------------

/*--------------------------------------------------------------------------
  REQ-xxxxx : demote bad $1 FTD cohort
  Zero IsDepositor / IsDepositorGlobal / FTD anchors for any cohort RealCID
  in today's row. These users made real $1 deposits so Dim_Customer says
  IsDepositor=True, but business semantics say they are not depositors.
--------------------------------------------------------------------------*/
DECLARE @demote_dynsql NVARCHAR(MAX);

IF OBJECT_ID('tempdb..#sp_bad_cohort') IS NOT NULL DROP TABLE #sp_bad_cohort;

CREATE TABLE #sp_bad_cohort
WITH (DISTRIBUTION = REPLICATE, HEAP)
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
    SELECT RealCID FROM upstream_deposits GROUP BY RealCID HAVING COUNT(*) > 1
)
SELECT dc.RealCID
FROM   DWH_dbo.Dim_Customer dc
WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND  dc.FirstDepositAmount = 1
  AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID);

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
INNER JOIN #sp_bad_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.DateID = @DateID;   -- scoped to the SP's @DateID parameter

DROP TABLE #sp_bad_cohort;

----------------------------------------------------------------------------
-- END PATCH BLOCK
----------------------------------------------------------------------------

/*===========================================================================
  Change-history line to add at top of SP:

  -- yyyy-mm-dd | REQ-xxxxx | Guy Mansharov | Final demotion UPDATE for bad
  --   $1 FTD cohort (Aug 2025 + May 2026): IsDepositor/IsDepositorGlobal/all
  --   FTD anchor columns/FirstDeposited flags forced to 0/NULL for cohort
  --   RealCIDs on the current @DateID. Complements REQ-25250 (MIMO demotion).
===========================================================================*/
