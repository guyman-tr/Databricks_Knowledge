-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_CryptoToFiat_C2F
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
-- Col comments: 16 added, 0 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f (
  RealCID COMMENT 'Direct pass-through from EXW_C2F_E2E.RealCID. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  LastModificationDate COMMENT 'GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime). Source: EXW_C2F_E2E. (T2 — Function_Revenue_CryptoToFiat_C2F)',
  LastModificationDateID COMMENT 'CAST(FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE), ''yyyyMMdd'') AS INT). Source: EXW_C2F_E2E. (T2 — Function_Revenue_CryptoToFiat_C2F)',
  TotalFeePercentage COMMENT 'TotalFeePercentage WHERE ConversionCycle = ''Full Cycle'' AND CAST(FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE),''yyyyMMdd'') AS INT) BETWEEN @sdateInt AND @edateInt. Source: EXW_C2F_E2E.TotalFeePercentage. (T2 — Function_Revenue_CryptoToFiat_C2F)',
  TotalFeeUSD COMMENT 'TotalFeeUSD WHERE ConversionCycle = ''Full Cycle'' AND same LastModificationDateID between params (snapshot DateRange join on that date). Source: EXW_C2F_E2E.TotalFeeUSD. (T2 — Function_Revenue_CryptoToFiat_C2F)',
  FiatAmount COMMENT 'Direct pass-through from EXW_C2F_E2E.FiatAmount. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  CryptoAmount COMMENT 'Direct pass-through from EXW_C2F_E2E.CryptoAmount. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  FiatCurrency COMMENT 'Direct pass-through from EXW_C2F_E2E.FiatCurrency. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  UsdAmount COMMENT 'Direct pass-through from EXW_C2F_E2E.UsdAmount. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  Crypto COMMENT 'Direct pass-through from EXW_C2F_E2E.Crypto. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  TargetPlatformID COMMENT 'Direct pass-through from EXW_C2F_E2E.TargetPlatformID. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  TargetPlatform COMMENT 'Direct pass-through from EXW_C2F_E2E.TargetPlatform. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  DepositID COMMENT 'Direct pass-through from EXW_C2F_E2E.DepositID. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  eMoneyTransactionID COMMENT 'Direct pass-through from EXW_C2F_E2E.eMoneyTransactionID. (T1 — Function_Revenue_CryptoToFiat_C2F)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 — Function_Revenue_CryptoToFiat_C2F)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_CryptoToFiat_C2F > Surfaces completed crypto-to-fiat (C2F) conversions from the E2E pipeline (ConversionCycle = Full Cycle), with fee and amount fields, platform metadata, and customer snapshot attributes aligned to the last modification date derived from the greatest of several event timestamps.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_CryptoToFiat_C2F > Surfaces completed crypto-to-fiat (C2F) conversions from the E2E pipeline (ConversionCycle = Full Cycle), with fee and amount fields, platform metadata, and customer snapshot attributes aligned to the last modification date derived from the greatest of several event timestamps.')
WITH SCHEMA COMPENSATION
AS SELECT
    ecfee.RealCID,
    fsc.GCID,
    GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransactionDateTime) AS LastModificationDate,
    CAST(DATE_FORMAT(CAST(GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransactionDateTime) AS DATE), 'yyyyMMdd') AS INT) AS LastModificationDateID,
    ecfee.TotalFeePercentage,
    ecfee.TotalFeeUSD,
    ecfee.FiatAmount,
    ecfee.CryptoAmount,
    ecfee.FiatCurrency,
    ecfee.UsdAmount,
    ecfee.Crypto,
    ecfee.TargetPlatformID,
    ecfee.TargetPlatform,
    ecfee.DepositID,
    ecfee.eMoneyTransactionID,
    fsc.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ecfee
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON ecfee.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND CAST(DATE_FORMAT(CAST(GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransactionDateTime) AS DATE), 'yyyyMMdd') AS INT)
        BETWEEN dr.FromDateID AND dr.ToDateID
WHERE ecfee.ConversionCycle = 'Full Cycle'

;
