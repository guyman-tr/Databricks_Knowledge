/*
================================================================================
  Synapse REQ-25250 backfill — 2026-05-22 .. 2026-06-06
  Date drafted: 2026-06-08

  Context:
    REQ-25250 deployed the bad-$1-FTD-cohort demotion logic into:
      * BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms
          (recovery-UPDATE filter + final IsPlatformFTD/IsGlobalFTD demotion)
      * BI_DB_dbo.SP_DDR_Customer_Daily_Status
          (final IsDepositor / IsDepositorGlobal / IsFunded / FirstTimeFunded /
           FirstFundedDateID / FTD-anchor / *FirstDeposited demotion)

    The patches demote only on the CURRENT @dateID of each call -- they do NOT
    retro-touch historical rows. Verified working on the 2026-06-07 nightly run
    (Customer_Daily_Status bad-cohort IsDepositor: 30,979 -> 0 vs 06-06).

    Backfill window: every snapshot date that was written under the OLD
    (pre-deployment) SP -> 2026-05-22 (first cohort date) .. 2026-06-06
    (last pre-deployment nightly).

    Total: 16 dates x 3 SPs = 48 SP executions. ~90-180 min on prod.

  Dependency order (DO NOT REORDER between tiers):

    Tier 1a -> SP_DDR_Fact_Fact_MIMO_AllPlatforms
               (writes BI_DB_DDR_Fact_MIMO_AllPlatforms)
    Tier 1b -> SP_DDR_Customer_Daily_Status
               (reads BI_DB_DDR_Fact_MIMO_AllPlatforms + Function TVFs)
    Tier 2  -> SP_DDR_Customer_Periodic_Status
               (MAX-aggregates BI_DB_DDR_Customer_Daily_Status across
                week / month / quarter / year windows)

    Within a tier, dates may run in any order (idempotent DELETE-WHERE-DateID).
    For predictability + log readability the loops run chronologically.

  Recovery:
    Each SP starts with DELETE FROM ... WHERE DateID = @dateID, so any
    failed/partial run is safe to re-execute.

  Run options:
    [A] Paste the three WHILE blocks below into ssms/azure-data-studio
        connected to sql_dp_prod_we. Each block is one transaction-free batch.
    [B] Run via pyodbc + ActiveDirectoryIntegrated for monitored execution
        (see _runners/run_synapse_backfill.py companion script if needed).
================================================================================
*/


-- ============================================================================
-- TIER 1a : SP_DDR_Fact_Fact_MIMO_AllPlatforms
--   16 calls, ~1-3 min each -> ~20-50 min total
-- ============================================================================
DECLARE @d DATE = '2026-05-22';
WHILE @d <= '2026-06-06'
BEGIN
    PRINT 'MIMO_AllPlatforms : ' + CONVERT(VARCHAR(10), @d, 23);
    EXEC BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms @d;
    SET @d = DATEADD(day, 1, @d);
END;


-- ============================================================================
-- TIER 1b : SP_DDR_Customer_Daily_Status
--   16 calls, ~3-6 min each -> ~50-100 min total
--   MUST run after Tier 1a completes (reads Fact_MIMO_AllPlatforms).
-- ============================================================================
DECLARE @d DATE = '2026-05-22';
WHILE @d <= '2026-06-06'
BEGIN
    PRINT 'Customer_Daily_Status : ' + CONVERT(VARCHAR(10), @d, 23);
    EXEC BI_DB_dbo.SP_DDR_Customer_Daily_Status @d;
    SET @d = DATEADD(day, 1, @d);
END;


-- ============================================================================
-- TIER 2 : SP_DDR_Customer_Periodic_Status
--   16 calls, ~1-2 min each -> ~20-30 min total
--   MUST run after Tier 1b completes (MAX-aggregates Customer_Daily_Status
--   across week/month/quarter/year windows -> needs the demoted dailies).
-- ============================================================================
DECLARE @d DATE = '2026-05-22';
WHILE @d <= '2026-06-06'
BEGIN
    PRINT 'Customer_Periodic_Status : ' + CONVERT(VARCHAR(10), @d, 23);
    EXEC BI_DB_dbo.SP_DDR_Customer_Periodic_Status @d;
    SET @d = DATEADD(day, 1, @d);
END;


-- ============================================================================
-- POST-BACKFILL SANITY CHECK  (optional, run separately after all 3 loops)
-- ============================================================================
/*
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
    WHERE fca.ActionTypeID IN (7,44) AND fca.RealCID IS NOT NULL
    UNION ALL
    SELECT mfts.CID AS RealCID FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts
    WHERE mfts.MoneyMoveDirection='MoneyIn' AND mfts.TxStatusID=2
      AND mfts.TxTypeID IN (7,14) AND mfts.CID IS NOT NULL
),
multi_deposit_cids AS (
    SELECT RealCID FROM upstream_deposits GROUP BY RealCID HAVING COUNT(*) > 1
),
bad_cohort AS (
    SELECT dc.RealCID
    FROM   DWH_dbo.Dim_Customer dc
    WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
      AND  dc.FirstDepositAmount = 1
      AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID)
)
SELECT cs.DateID,
       COUNT(*)                                              AS bad_cohort_rows,
       SUM(CAST(cs.IsDepositor AS INT))                      AS dep_should_be_0,
       SUM(CAST(cs.IsDepositorGlobal AS INT))                AS dep_global_should_be_0,
       SUM(CAST(cs.IsFunded AS INT))                         AS funded_should_be_0,
       SUM(CAST(cs.FirstTimeFunded AS INT))                  AS first_funded_should_be_0,
       MAX(cs.UpdateDate)                                    AS last_update
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN bad_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.DateID BETWEEN 20260522 AND 20260607
GROUP BY cs.DateID
ORDER BY cs.DateID;
-- All *_should_be_0 columns must be 0 across every date in the window.
-- last_update should be today (post-backfill).
*/
