-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
-- Col comments: 6 added, 0 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent - safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms (
  RealCID COMMENT 'Routed OLD_BASE vs NEW_BASE; NEW from Dim_Customer; OLD from first-ranked eMoney/TP deposit. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  DepositID COMMENT 'CASE on FTDPlatformID / joins; IBAN TransactionID, TP DepositID, or neutralized. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FirstDepositDate COMMENT 'OLD: earliest across IBAN/TP union; NEW: Dim_Customer.FirstDepositDate. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FirstDepositAmount COMMENT 'Same routing as date/amount sources. Source: Dim_Customer, eMoney_Fact_Transaction_Status, Fact_CustomerAction. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FTDPlatform COMMENT 'Dim_FTDPlatform.FTDPlatformName (NEW) or ''eMoney'' / ''TradingPlatform'' (OLD). Source: Dim_FTDPlatform, literals. (T2 - Function_MIMO_First_Deposit_All_Platforms)',
  FTDPlatformID COMMENT '3 eMoney / 1 TP (OLD) or Dim_Customer.FTDPlatformID (NEW). Source: Dim_Customer, literals. (T2 - Function_MIMO_First_Deposit_All_Platforms)'
)
COMMENT 'BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms > Single entry point for first-time deposit (FTD) attributes per customer across eMoney and trading-platform sources, with date-routed logic: before 2025-09-01 uses legacy IBAN/TP union and row-numbering; on/after uses Dim_Customer as the spine with joins to refreshed IBAN/TP extracts, C2USD billing, and bad-FTD exclusion. Each row is enriched with Fact_SnapshotCustomer as-of the FTD date via Dim_Range.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms > Single entry point for first-time deposit (FTD) attributes per customer across eMoney and trading-platform sources, with date-routed logic: before 2025-09-01 uses legacy IBAN/TP union and row-numbering; on/after uses Dim_Customer as the spine with joins to refreshed IBAN/TP extracts, C2USD billing, and bad-FTD exclusion. Each row is enriched with Fact_SnapshotCustomer as-of the FTD date via Dim_Range.')
WITH SCHEMA COMPENSATION
AS WITH 
-- Trading Platform FTDs from Fact_CustomerAction
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

-- eMoney FTDs - FIRST deposit per customer
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

-- Crypto to USD deposits
c2usd AS (
    SELECT CID, fbd.DepositID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd
    WHERE fbd.IsFTD = 1
      AND fbd.FundingTypeID = 27
),

-- Main FTD data from Dim_Customer
dimcust AS (
    SELECT
        dc.RealCID,
        
        -- DepositID logic: use IBAN for platform 3, TP for platform 1, else NULL
        CASE 
            WHEN dc.FTDPlatformID = 3 THEN ib.DepositID
            WHEN dc.FTDPlatformID = 1 THEN CAST(dc.FTDTransactionID AS BIGINT)
            ELSE NULL
        END AS DepositID,
        
        dc.FirstDepositDate,
        dc.FirstDepositAmount,
        
        -- FTDPlatform name mapping
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
REMOVE_BAD_FTDS AS (
    -- Wrongly tagged $1 FTDs to exclude (parity with Synapse Function_MIMO_First_Deposit_All_Platforms).
    -- Backfilled into DBX on 2026-05-27: the 2025-11-23 Synapse exclusion was never ported here,
    -- so Aug 2025 bad FTDs were still flowing through DBX MIMO. Also adds 2026-05-22..23, 2026-05-25
    -- ($1 cohort, rapid-fire sequential FTDTransactionIDs on FTDPlatformID=1).
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
)

-- Final output: simplified to just FTD essentials
SELECT
    RealCID,
    DepositID,
    FirstDepositDate,
    FirstDepositAmount,
    FTDPlatform,
    FTDPlatformID
FROM dimcust
WHERE RealCID NOT IN (SELECT RealCID FROM REMOVE_BAD_FTDS)

;
