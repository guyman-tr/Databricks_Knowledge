/*===========================================================================
  02_synapse_demote_mimo_aug2025.sql

  Purpose : One-shot UPDATE on BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms to
            zero IsPlatformFTD (and IsGlobalFTD as belt-and-suspenders) for
            the Aug 2025 bad $1 FTD cohort on dates 2025-08-18..2025-08-20.

  Why     :
    The current Synapse SP_DDR_Fact_Fact_MIMO_AllPlatforms recovery UPDATE
    has 'AND t1.DateID >= 20250901' so it did NOT re-pump IsGlobalFTD for the
    Aug 2025 dates (TVF filter kept IsGlobalFTD=0 since 2025-11-23 patch).
    But the upstream platform SP (SP_DDR_Fact_MIMO_Trading_Platform) sets
    IsFTD=1 based on Dim_Customer.FTDTransactionID without any REMOVE_BAD_FTDS
    filter, so IsPlatformFTD leaked into BI_DB_DDR_Fact_MIMO_AllPlatforms.

    Measured leak:
      8/18 : 2064 PFTD vs 1323 GFTD -> 741 leaked
      8/19 : 2131 PFTD vs 1396 GFTD -> 735 leaked
      8/20 : 5065 PFTD vs 1404 GFTD -> 3661 leaked
      Total: ~5,137 leaked rows.

  Scope   : Synapse Dedicated SQL Pool (sql_dp_prod_we) -> BI_DB_dbo schema.

  NOT in scope of this script (because REQ-25250 + synapse_rerun.sql handle them):
    - May 2026 dates (5/22, 5/23, 5/25) : REQ-25250 + rerun will recompute
      these dates with the demotion UPDATE in place.

  Idempotent : Yes.
===========================================================================*/

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

SELECT 'aug_cohort_size' AS metric, COUNT(*) AS n FROM #bad_cohort_aug;
-- Expected ~ 13302

/*---------------------------------------------------------------------------
  Demotion UPDATE - only target rows where the leak is present.
  Scope: DateID IN (20250818, 20250819, 20250820) AND IsPlatformFTD = 1.
---------------------------------------------------------------------------*/
UPDATE map
SET    IsPlatformFTD = 0,
       IsGlobalFTD   = 0
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
INNER JOIN #bad_cohort_aug bc ON map.RealCID = bc.RealCID
WHERE  map.DateID IN (20250818, 20250819, 20250820)
  AND  (map.IsPlatformFTD = 1 OR map.IsGlobalFTD = 1);

/*---------------------------------------------------------------------------
  Verification
---------------------------------------------------------------------------*/
SELECT map.DateID,
       COUNT(*) AS rows,
       SUM(CAST(map.IsPlatformFTD AS INT)) AS pftd_should_be_0,
       SUM(CAST(map.IsGlobalFTD AS INT))   AS gftd_should_be_0
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
INNER JOIN #bad_cohort_aug bc ON map.RealCID = bc.RealCID
WHERE  map.DateID IN (20250818, 20250819, 20250820)
GROUP BY map.DateID
ORDER BY map.DateID;
-- pftd_should_be_0 and gftd_should_be_0 must both be 0.

DROP TABLE #bad_cohort_aug;
