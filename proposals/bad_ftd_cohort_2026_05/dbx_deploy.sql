-- ============================================================================
-- DBX deploy script: $1 FTD bad-cohort exclusion (2026-05 incident + Aug-2025 backfill)
-- Targets:
--   main.etoro_kpi_prep.v_population_first_time_funded   (extend date list)
--   main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms (add CTE - new filter)
-- Author:  Guy M
-- Date:    2026-05-27
--
-- IMPORTANT: v_population_first_time_funded references v_mimo_allplatforms,
-- which in turn references v_mimo_first_deposit_all_platforms. Deploy in order:
--   1) v_mimo_first_deposit_all_platforms (no dependencies upstream of it)
--   2) v_population_first_time_funded
-- Then validate counts (see bottom of file).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1) v_mimo_first_deposit_all_platforms
--    NEW: REMOVE_BAD_FTDS CTE added + final WHERE NOT IN. The 2025-11-23
--    Synapse exclusion was never ported here; this also backfills Aug-2025.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms (
  RealCID COMMENT 'Routed OLD_BASE vs NEW_BASE; NEW from Dim_Customer; OLD from first-ranked eMoney/TP deposit. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. Bad-FTD cohort excluded (see view comment). (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  DepositID COMMENT 'CASE on FTDPlatformID / joins; IBAN TransactionID, TP DepositID, or neutralized. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FirstDepositDate COMMENT 'OLD: earliest across IBAN/TP union; NEW: Dim_Customer.FirstDepositDate. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FirstDepositAmount COMMENT 'Same routing as date/amount sources. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FTDPlatform COMMENT 'Dim_FTDPlatform.FTDPlatformName (NEW) or "eMoney" / "TradingPlatform" (OLD). Source: Dim_FTDPlatform, literals. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FTDPlatformID COMMENT '3 eMoney / 1 TP (OLD) or Dim_Customer.FTDPlatformID (NEW). Source: Dim_Customer, literals. (T2 - Function_MIMO_First_Deposit_All_Platforms)'
)
COMMENT 'BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms > Single entry point for first-time deposit (FTD) attributes per customer across eMoney and trading-platform sources, with date-routed logic: before 2025-09-01 uses legacy IBAN/TP union and row-numbering; on/after uses Dim_Customer as the spine with joins to refreshed IBAN/TP extracts, C2USD billing, and bad-FTD exclusion. Bad-FTD list: 2025-08-18..20 (orig Nir S) + 2026-05-22..23, 2026-05-25 (synthetic $1 cohort, sequential FTDTransactionID).'
AS
WITH
new_tp AS (
    SELECT
        fca.RealCID,
        fca.DepositID,
        CAST(NULL AS INT) AS IsCryptoToFiat,
        CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0 END AS IsIBANTrade,
        CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0 END AS IsIBANQuickTransfer
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    WHERE (fca.ActionTypeID = 7 AND fca.IsFTD = 1)
       OR (fca.ActionTypeID = 44 AND fca.IsFTD = 1)
),
new_iban AS (
    SELECT
        a.RealCID,
        a.TransactionID AS DepositID,
        a.IsCryptoToFiat,
        a.IsIBANTrade,
        a.IsIBANQuickTransfer,
        a.SourceCugTransactionID
    FROM (
        SELECT
            mfts.CID AS RealCID,
            mfts.TxStatusModificationTime,
            mfts.USDAmountApprox,
            mfts.TransactionID,
            ROW_NUMBER() OVER (PARTITION BY mfts.CID ORDER BY mfts.TxStatusModificationTime, eft.Created) AS RN,
            CASE WHEN mfts.TxTypeID = 14 THEN 1 ELSE 0 END AS IsCryptoToFiat,
            CAST(NULL AS INT) AS IsIBANTrade,
            CAST(NULL AS INT) AS IsIBANQuickTransfer,
            mfts.SourceCugTransactionID
        FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
        LEFT JOIN main.emoney.bronze_fiatdwhdb_dbo_fiattransactions eft
            ON mfts.SourceCugTransactionID = eft.SourceCugTransactionId
        WHERE mfts.MoneyMoveDirection = 'MoneyIn'
          AND mfts.TxStatusID = 2
          AND mfts.TxTypeID IN (7, 14)
    ) a
    WHERE a.RN = 1
),
c2usd AS (
    SELECT CID, fbd.DepositID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd
    WHERE fbd.IsFTD = 1
      AND fbd.FundingTypeID = 27
),
dimcust AS (
    SELECT
        dc.RealCID,
        CASE
            WHEN dc.FTDPlatformID = 3 THEN ib.DepositID
            WHEN dc.FTDPlatformID = 1 THEN CAST(dc.FTDTransactionID AS BIGINT)
            ELSE NULL
        END AS DepositID,
        dc.FirstDepositDate,
        dc.FirstDepositAmount,
        CASE
            WHEN dc.FTDPlatformID = 1 THEN 'TradingPlatform'
            WHEN dc.FTDPlatformID = 2 THEN 'Options'
            WHEN dc.FTDPlatformID = 3 THEN 'eMoney'
            WHEN dc.FTDPlatformID = 4 THEN 'MoneyFarm'
            ELSE 'NA'
        END AS FTDPlatform,
        dc.FTDPlatformID,
        COALESCE(ib.IsCryptoToFiat, tp.IsCryptoToFiat) AS IsCryptoToFiat,
        COALESCE(tp.IsIBANTrade, ib.IsIBANTrade) AS IsIBANTrade,
        COALESCE(ib.IsIBANQuickTransfer, tp.IsIBANQuickTransfer) AS IsIBANQuickTransfer,
        CASE WHEN cus.DepositID IS NOT NULL THEN 1 ELSE 0 END AS IsC2USD
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    LEFT JOIN new_iban ib
        ON dc.RealCID = ib.RealCID
       AND TRY_CAST(dc.FTDTransactionID AS BIGINT) = TRY_CAST(ib.SourceCugTransactionID AS BIGINT)
       AND dc.FTDPlatformID = 3
    LEFT JOIN new_tp tp
        ON dc.RealCID = tp.RealCID
       AND TRY_CAST(ib.DepositID AS BIGINT) = TRY_CAST(tp.DepositID AS BIGINT)
    LEFT JOIN c2usd cus
        ON dc.RealCID = cus.CID
       AND TRY_CAST(tp.DepositID AS BIGINT) = TRY_CAST(dc.FTDTransactionID AS BIGINT)
       AND dc.FTDPlatformID = 1
    WHERE dc.FirstDepositDate >= '2025-09-01'
),
remove_bad_ftds AS (
    -- Synthetic $1 FTD cohorts excluded for parity with Synapse Function_MIMO_First_Deposit_All_Platforms.
    -- 2025-08-18..20: original Nir S cohort (~13K). Backfilled to DBX 2026-05-27 (was missing).
    -- 2026-05-22..23, 2026-05-25: ~17.7K rapid-fire sequential FTDTransactionID cohort on FTDPlatformID=1, all $1.0000.
    SELECT dc.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
            TO_DATE('20250818', 'yyyyMMdd'),
            TO_DATE('20250819', 'yyyyMMdd'),
            TO_DATE('20250820', 'yyyyMMdd'),
            TO_DATE('20260522', 'yyyyMMdd'),
            TO_DATE('20260523', 'yyyyMMdd'),
            TO_DATE('20260525', 'yyyyMMdd')
        )
      AND dc.FirstDepositAmount = 1
      AND dc.RealCID NOT IN (
          SELECT map.RealCID
          FROM main.etoro_kpi_prep.v_mimo_allplatforms map
          WHERE map.MIMOAction = 'Deposit'
          GROUP BY map.RealCID
          HAVING COUNT(map.RealCID) > 1
      )
)
SELECT
    RealCID,
    DepositID,
    FirstDepositDate,
    FirstDepositAmount,
    FTDPlatform,
    FTDPlatformID
FROM dimcust
WHERE RealCID NOT IN (SELECT RealCID FROM remove_bad_ftds);


-- ----------------------------------------------------------------------------
-- 2) v_population_first_time_funded
--    CHANGED: REMOVE_BAD_FTDS date list extended.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_population_first_time_funded (
  RealCID COMMENT 'Direct (via DWH_FTD). Source: Dim_Customer.RealCID. (T1 - Function_Population_First_Time_Funded)',
  FTDPlatformID COMMENT 'Direct pass-through from Dim_Customer.FTDPlatformID. (T1 - Function_Population_First_Time_Funded)',
  FTDPlatform COMMENT 'COALESCE(FTDPlatformName, "TP"). Source: Dim_FTDPlatform.FTDPlatformName. (T2 - Function_Population_First_Time_Funded)',
  FTDDateID COMMENT 'CAST(CONVERT(VARCHAR(8), FirstDepositDate, 112) AS INT). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Time_Funded)',
  FTDDate COMMENT 'CAST(FirstDepositDate AS DATE). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Time_Funded)',
  FTDTime COMMENT 'Same timestamp as FTD column (first deposit). Source: Dim_Customer.FirstDepositDate. (T2 - Function_Population_First_Time_Funded)',
  FirstTradeDateID COMMENT 'MIN(OpenDateID) WHERE ISNULL(IsAirDrop,0) = 0, grouped by CID AS RealCID. Source: Dim_Position.OpenDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstTradeDate COMMENT 'CONVERT(DATE, CONVERT(VARCHAR(8), MIN(OpenDateID)), 112) under same non-airdrop position filter as row 7. Source: Dim_Position.OpenDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstTradeTime COMMENT 'MIN(OpenOccurred) under same non-airdrop position filter as row 7. Source: Dim_Position.OpenOccurred. (T2 - Function_Population_First_Time_Funded)',
  FirstIOBDateID COMMENT 'MIN(CAST(FORMAT(CAST(Occurred AS DATE), "yyyyMMdd") AS INT)) where ActionTypeID = 36 and CompensationReasonID = 57. Source: Fact_CustomerAction.Occurred. (T2 - Function_Population_First_Time_Funded)',
  FirstIOBDate COMMENT 'CAST(MIN(Occurred) AS DATE). Source: Fact_CustomerAction.Occurred. (T2 - Function_Population_First_Time_Funded)',
  FirstIOBTime COMMENT 'MIN(Occurred). Source: Fact_CustomerAction.Occurred. (T2 - Function_Population_First_Time_Funded)',
  FirstOptionsTradeDateID COMMENT 'MIN(FirstTradeDateID) by RealCID. Source: Function_Revenue_OptionsPlatform.FirstTradeDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstOptionsTradeDate COMMENT 'MIN(FirstTradeDate). Source: Function_Revenue_OptionsPlatform.FirstTradeDate. (T2 - Function_Population_First_Time_Funded)',
  FirstVerifiedDateID COMMENT 'MIN(FromDateID) where VerificationLevelID = 3 on snapshot. Source: Dim_Range.FromDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstVerifiedDate COMMENT 'CONVERT(DATE, CONVERT(VARCHAR(8), MIN(FromDateID)), 112). Source: Dim_Range.FromDateID. (T2 - Function_Population_First_Time_Funded)',
  FirstFundedDateID COMMENT 'GREATEST(FTDDateID, FirstVerifiedDateID, COALESCE(LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID), COALESCE(...))). (T2 - Function_Population_First_Time_Funded)',
  FirstFundedDate COMMENT 'CONVERT(DATE, CONVERT(VARCHAR(8), FirstFundedDateID), 112). (T2 - Function_Population_First_Time_Funded)'
)
COMMENT 'BI_DB_dbo.Function_Population_First_Time_Funded > For depositors with a warehouse FTD (excluding curated bad-FTD set: 2025-08-18..20 + 2026-05-22..23, 2026-05-25), joins first verified snapshot range and left-joins first trade, first IOB, and first options trade. Computes a single FirstFundedDateID/Date as the latest of FTD, verification, and the earliest qualifying activity.'
AS
WITH First_IOB AS (
    SELECT
        RealCID,
        MIN(Occurred) AS FirstIOBTime,
        CAST(MIN(Occurred) AS DATE) AS FirstIOBDate,
        MIN(CAST(DATE_FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT)) AS FirstIOBDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    WHERE ActionTypeID = 36
      AND CompensationReasonID = 57
    GROUP BY RealCID
),
REMOVE_BAD_FTDS AS (
    -- Wrongly tagged $1 FTDs to exclude from all FTF/MIMO outputs.
    -- 2025-08-18..20: original Nir S exclusion (~13K synthetic FTDs).
    -- 2026-05-22..23, 2026-05-25: rapid-fire sequential FTDTransactionID cohort on FTDPlatformID=1
    --   (17,236 + 470 + 10 rows, all $1.0000, no follow-up deposits). Same script signature
    --   as Aug 2025 incident. Added 2026-05-27 by Guy M.
    SELECT
        dc.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
        TO_DATE('20250818', 'yyyyMMdd'),
        TO_DATE('20250819', 'yyyyMMdd'),
        TO_DATE('20250820', 'yyyyMMdd'),
        TO_DATE('20260522', 'yyyyMMdd'),
        TO_DATE('20260523', 'yyyyMMdd'),
        TO_DATE('20260525', 'yyyyMMdd')
    )
    AND dc.FirstDepositAmount = 1
    AND dc.RealCID NOT IN (
        SELECT map.RealCID
        FROM main.etoro_kpi_prep.v_mimo_allplatforms map
        WHERE map.MIMOAction = 'Deposit'
        GROUP BY map.RealCID
        HAVING COUNT(map.RealCID) > 1
    )
),
DWH_FTD AS (
    SELECT
        ftd.FTDPlatformID,
        ftd.Name as FTDPlatform,
        dc.RealCID,
        dc.FirstDepositDate AS FTDTime,
        CAST(dc.FirstDepositDate AS DATE) AS FTDDate,
        CAST(DATE_FORMAT(dc.FirstDepositDate, 'yyyyMMdd') AS INT) AS FTDDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    LEFT JOIN main.etoro_kpi_prep.v_globalftdplatform ftd
        ON ftd.FTDPlatformID = dc.FTDPlatformID
    WHERE dc.IsDepositor = 1
      AND dc.RealCID NOT IN (SELECT RealCID FROM REMOVE_BAD_FTDS)
),
Verification AS (
    SELECT
        fsc.RealCID,
        TO_DATE(CAST(MIN(fsc.FromDateID) AS STRING), 'yyyyMMdd') AS FirstVerifiedDate,
        MIN(fsc.FromDateID) AS FirstVerifiedDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    WHERE fsc.VerificationLevelID = 3
    GROUP BY fsc.RealCID
),
Trade AS (
    SELECT
        CID AS RealCID,
        MIN(OpenOccurred) AS FirstTradeTime,
        TO_DATE(CAST(MIN(OpenDateID) AS STRING), 'yyyyMMdd') AS FirstTradeDate,
        MIN(OpenDateID) AS FirstTradeDateID
    FROM main.dwh.dim_position
    WHERE IFNULL(IsAirDrop, 0) = 0
    GROUP BY CID
),
OptionsTrade AS (
    SELECT
        op.RealCID,
        MIN(op.FirstTradeDate) AS FirstOptionsTradeDate,
        MIN(op.FirstTradeDateID) AS FirstOptionsTradeDateID
    FROM main.etoro_kpi_prep.v_revenue_optionsplatform op
    GROUP BY op.RealCID
)
SELECT
    f.RealCID,
    f.FTDPlatformID,
    f.FTDPlatform,
    f.FTDDateID,
    f.FTDDate,
    f.FTDTime,
    t.FirstTradeDateID,
    t.FirstTradeDate,
    t.FirstTradeTime,
    iob.FirstIOBDateID,
    iob.FirstIOBDate,
    iob.FirstIOBTime,
    ot.FirstOptionsTradeDateID,
    ot.FirstOptionsTradeDate,
    v.FirstVerifiedDateID,
    v.FirstVerifiedDate,
    GREATEST(
        f.FTDDateID,
        v.FirstVerifiedDateID,
        COALESCE(
            LEAST(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID),
            COALESCE(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID)
        )
    ) AS FirstFundedDateID,
    TO_DATE(
        CAST(
            GREATEST(
                f.FTDDateID,
                v.FirstVerifiedDateID,
                COALESCE(
                    LEAST(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID),
                    COALESCE(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID)
                )
            ) AS STRING
        ),
        'yyyyMMdd'
    ) AS FirstFundedDate
FROM DWH_FTD f
INNER JOIN Verification v ON f.RealCID = v.RealCID
LEFT JOIN Trade t ON f.RealCID = t.RealCID
LEFT JOIN First_IOB iob ON f.RealCID = iob.RealCID
LEFT JOIN OptionsTrade ot ON f.RealCID = ot.RealCID
WHERE (t.FirstTradeDateID IS NOT NULL
    OR iob.FirstIOBDateID IS NOT NULL
    OR ot.FirstOptionsTradeDateID IS NOT NULL);


-- ----------------------------------------------------------------------------
-- POST-DEPLOY VALIDATION (run after both views are updated)
-- ----------------------------------------------------------------------------

-- A. Confirm the new dates' $1 cohorts are gone from v_mimo_first_deposit_all_platforms
-- (expect 33, 2, 0 - the legitimate repeat-depositors only)
SELECT CAST(FirstDepositDate AS DATE) AS d, COUNT(*) AS n
FROM main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
WHERE CAST(FirstDepositDate AS DATE) IN ('2026-05-22', '2026-05-23', '2026-05-25')
  AND FirstDepositAmount = 1
GROUP BY CAST(FirstDepositDate AS DATE)
ORDER BY d;

-- B. Confirm v_population_first_time_funded also excludes them
SELECT FTDDateID, COUNT(*) AS n
FROM main.etoro_kpi_prep.v_population_first_time_funded
WHERE FTDDateID IN (20260522, 20260523, 20260525)
GROUP BY FTDDateID
ORDER BY FTDDateID;

-- C. Spot-check ONE of the synthetic CIDs is excluded
SELECT 'mimo' AS view_name, COUNT(*) AS n FROM main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms WHERE RealCID = 34707124
UNION ALL
SELECT 'ftf'  AS view_name, COUNT(*) AS n FROM main.etoro_kpi_prep.v_population_first_time_funded WHERE RealCID = 34707124;
-- Both expected 0.

-- D. Make sure legit repeat-depositors WERE kept (those 33 + 2 with HAVING COUNT>1)
-- Should match the "would_be_kept_repeat_depositor" from the cohort verify query.
WITH legit AS (
    SELECT dc.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    WHERE CAST(dc.FirstDepositDate AS DATE) = '2026-05-22'
      AND dc.FirstDepositAmount = 1
      AND dc.RealCID IN (
          SELECT map.RealCID
          FROM main.etoro_kpi_prep.v_mimo_allplatforms map
          WHERE map.MIMOAction = 'Deposit'
          GROUP BY map.RealCID
          HAVING COUNT(map.RealCID) > 1
      )
)
SELECT COUNT(*) AS kept_after_exclusion
FROM main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms v
JOIN legit l ON v.RealCID = l.RealCID;
-- Expect 33.
