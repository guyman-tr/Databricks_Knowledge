-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_positions_open_closed_iban_tp
-- Captured: 2026-05-19T15:00:32Z
-- ==========================================================================

SELECT 
a.PositionID, a.CID, a.InstrumentID, a.OpenDateID, a.CloseDateID, a.PlatformTypeID, a.Amount, a.Volume, a.NetProfit, a.Commission, a.Leverage, a.RegulationIDOnOpen, a.UpdateDate AS PositionUpdateDate,
dc.RealCID, dc.CountryID, dc.LanguageID, dc.PlayerLevelID, dc.AccountStatusID, dc.AccountTypeID, dc.RegulationID, dc.RiskStatusID, dc.RiskClassificationID, dc.IsValidCustomer, dc.PlayerStatusID, dc.VerificationLevelID, dc.RegionID, dc.IsDepositor, dc.FirstDepositDate, dc.AccountManagerID, dc.PremiumAccount, dc.AffiliateID, dc.CampaignID, dc.SubChannelID,
 dc.LabelID,  dc.RegisteredReal, dc.RegisteredDemo, dc.ReferralID, dc.UpdateDate AS CustomerUpdateDate,
i.InstrumentType, i.SellCurrency, i.InstrumentDisplayName,
CASE WHEN b.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsCloseToIBan, 
CASE WHEN c.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsOpenFromIBan, 
e.AccountCreateDate, e.AccountSubProgram, e.AccountSubProgramID, case when e.CID is not null then 1 else 0 end as IsEmoneyCustomer
FROM main.dwh.dim_position AS a 
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON a.CID = dc.RealCID AND dc.IsValidCustomer = 1
JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument i ON a.InstrumentID = i.InstrumentID
LEFT JOIN  main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account e on a.CID=e.CID and e.IsValidETM=1 and e.GCID_Unique_Count=1 
LEFT JOIN main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet AS b ON a.PositionID = b.PositionID
LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet AS c ON a.PositionID = c.PositionID
WHERE a.OpenDateID >= 20250101
