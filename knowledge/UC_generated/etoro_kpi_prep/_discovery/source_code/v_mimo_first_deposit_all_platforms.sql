-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
-- Captured: 2026-05-18T08:06:18Z
-- ==========================================================================

WITH 
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
