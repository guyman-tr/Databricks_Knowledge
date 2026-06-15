-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoney_card_transactions
-- Captured: 2026-05-19T14:56:20Z
-- ==========================================================================

select
    CID,
    TxStatusModificationTime      as CardTransaction_Time,
    TxType                        as CardTransaction_Type,
    USDAmountApprox               as CardTransaction_USDAmount,
    LocalAmount                   as CardTransaction_Local_Amount,
    LocalCurrencyDesc             as CardTransaction_Local_Currency,
    ClubTxDate                    as CardTransaction_Club_AtTx,
    CountryTxDate                 as CardTransaction_Country_AtTx,
    RegulationTxDate              as CardTransaction_Regulation_AtTx
from main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
where TxTypeID in (1,2,3,4)
  and IsValidCustomer = 1
  and IsValidETM = 1
  and IsTxSettled = 1
