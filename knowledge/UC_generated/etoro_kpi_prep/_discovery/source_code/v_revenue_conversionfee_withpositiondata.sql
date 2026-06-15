-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
-- Captured: 2026-05-19T12:22:08Z
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
    COALESCE(bdpcti.PositionID, bdpofi.PositionID) AS PositionID,
    dp.IsSettled,
    dp.IsBuy,
    dp.Leverage,
    dp.IsAirDrop,
    CASE WHEN COALESCE(bdpcti.PositionID, bdpofi.PositionID) IS NULL AND fca.IsIBANTrade = 1 THEN 0 ELSE 1 END AS ExecutionIBANTradeSuccess,
    di.InstrumentID,
    di.InstrumentTypeID,
    di.InstrumentType,
    CASE WHEN dp.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy,
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
LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban bdpofi
    ON fca.DepositID = bdpofi.DepositID
LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban bdpcti
    ON fca.WithdrawPaymentID = bdpcti.WithdrawPaymentID
LEFT JOIN main.dwh.dim_position dp
    ON COALESCE(bdpcti.PositionID, bdpofi.PositionID) = dp.PositionID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON dp.InstrumentID = di.InstrumentID
