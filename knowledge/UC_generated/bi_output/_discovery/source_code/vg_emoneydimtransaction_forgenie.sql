-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoneydimtransaction_forgenie
-- Captured: 2026-06-19T14:34:13Z
-- ==========================================================================

SELECT 
    mdt.CID,
    mdt.GCID,
    mdt.TxTypeID,
    mdt.TxType,
    CASE 
        WHEN mdt.TxTypeID IN (1, 2, 3, 4, 13) THEN mdt.TxType || ' - eToro Debit Card Transaction'
        WHEN mdt.TxType = 'Payment' THEN 'Payment - IBAN to External (Outgoing Payment)'
        WHEN mdt.TxType = 'PaymentReceived' THEN 'PaymentReceived - External to IBAN (Incoming Payment)'
        WHEN mdt.TxType = 'Transfer' THEN 'Transfer - IBAN to Trading Platform (Internal Transfer Out)'
        WHEN mdt.TxType = 'TransferReceived' THEN 'TransferReceived - Trading Platform to IBAN (Internal Transfer In)'
        ELSE mdt.TxType
    END AS TxTypeDescription,
    mdt.USDAmountApprox,
    mdt.HolderAmount,
    mdt.HolderCurrencyDesc,
    mdt.MerchantID,
    mdt.TxStatusModificationTime,
    mdt.TxLabel,
    mdt.MoneyMoveDirection,
    mdt.USDRateApprox
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction mdt
WHERE mdt.IsValidETM = 1 
  AND mdt.IsTxSettled = 1
