-- =====================================================================
-- v_mimo_first_deposit_all_platforms (refactored)
-- ---------------------------------------------------------------------
-- Equivalent to Synapse BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0).
-- Refactored to consume main.etoro_kpi_prep.v_bad_ftd_cohort instead of
-- inlining the REMOVE_BAD_FTDS CTE — single source of truth for the
-- bad-cohort predicate, used by both this view and the recovery UPDATEs
-- in sp_ddr_fact_mimo_allplatforms.
--
-- Semantically identical to the current production view. Only the
-- remove_bad_ftds CTE is replaced with a SELECT from v_bad_ftd_cohort.
-- =====================================================================
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms AS
WITH new_tp AS (
  SELECT fca.RealCID, fca.DepositID,
         CAST(NULL AS INT) AS IsCryptoToFiat,
         CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0 END AS IsIBANTrade,
         CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0 END AS IsIBANQuickTransfer
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  WHERE (fca.ActionTypeID = 7  AND fca.IsFTD = 1)
     OR (fca.ActionTypeID = 44 AND fca.IsFTD = 1)
),
new_iban AS (
  SELECT a.RealCID, a.TransactionID AS DepositID,
         a.IsCryptoToFiat, a.IsIBANTrade, a.IsIBANQuickTransfer,
         a.SourceCugTransactionID
  FROM (
    SELECT mfts.CID AS RealCID,
           mfts.TxStatusModificationTime,
           mfts.USDAmountApprox,
           mfts.TransactionID,
           ROW_NUMBER() OVER (
             PARTITION BY mfts.CID
             ORDER BY mfts.TxStatusModificationTime, eft.Created
           ) AS RN,
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
  SELECT dc.RealCID,
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
         COALESCE(ib.IsCryptoToFiat, tp.IsCryptoToFiat)     AS IsCryptoToFiat,
         COALESCE(tp.IsIBANTrade,   ib.IsIBANTrade)          AS IsIBANTrade,
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
SELECT
  RealCID,
  DepositID,
  FirstDepositDate,
  FirstDepositAmount,
  FTDPlatform,
  FTDPlatformID
FROM dimcust
WHERE RealCID NOT IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);
