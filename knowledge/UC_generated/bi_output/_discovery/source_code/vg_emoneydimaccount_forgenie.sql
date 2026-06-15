-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoneydimaccount_forgenie
-- Captured: 2026-05-19T14:57:03Z
-- ==========================================================================

SELECT 
    mda.CID,
    mda.GCID,
    mda.AccountSubProgram,
    mda.AccountCreateDate,
    mda.RegAccountSubProgram,
    COALESCE(mda.CurrencyBalanceStatus, 'Active') AS CurrencyBalanceStatus,
    mda.CurrencyBalanceISODesc, 
    mda.CurrencyBalanceID
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account mda
WHERE mda.IsValidETM = 1 
  AND mda.GCID_Unique_Count = 1 
  AND mda.IsTestAccount = 0
