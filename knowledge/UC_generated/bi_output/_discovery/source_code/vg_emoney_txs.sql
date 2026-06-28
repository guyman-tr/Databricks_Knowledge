-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoney_txs
-- Captured: 2026-06-19T14:34:04Z
-- ==========================================================================

SELECT
    mdt.CID,
    mdt.GCID,
    mdt.TxStatusModificationDate,
    mdt.USDAmountApprox AS TxAmountInUSD,
    mdt.TransactionID,
    mdt.IsTxSettled,
    mdt.TxType,
    mdt.TxTypeID,
    mdt.HolderCurrencyISO,
    mdt.LocalCurrencyISO
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction mdt
WHERE mdt.IsValidETM = 1
  AND mdt.IsTxSettled = 1
