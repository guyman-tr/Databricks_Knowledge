-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_conversionfee
-- Captured: 2026-05-19T12:21:53Z
-- ==========================================================================

SELECT
    fca.CID,
    fsc.GCID,
    fca.DateID,
    fca.PIPsCalculation AS ConversionFee,
    fca.TransactionType,
    fca.IsIBANTrade,
    CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) AS TransactionID,
    fca.PaymentMethod,
    fca.Amount,
    fca.Currency,
    fca.AmountUSD,
    fca.ExchangeRate,
    fca.BaseExchangeRate,
    fca.Depot,
    fca.MIDValue,
    fbd.IsRecurring,
    fsc.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.CID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd
    ON CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) = fbd.DepositID
    AND fca.TransactionType = 'Deposit'
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw fbw
    ON CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) = fbw.WithdrawPaymentID
    AND fca.TransactionType = 'Withdraw'
