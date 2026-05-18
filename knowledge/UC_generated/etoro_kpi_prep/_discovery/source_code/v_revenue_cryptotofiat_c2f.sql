-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
-- Captured: 2026-05-18T08:12:27Z
-- ==========================================================================

SELECT
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
