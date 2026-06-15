select distinct
  bw.WithdrawID
  ,bw.WithdrawPaymentID
  ,bw.Amount_WithdrawToFunding
  ,c.Abbreviation
  ,de.Name as Depot,
  ct.CashoutTypeName,
  WF.MIDValue,
  WF.MIDName,
  bw.ModificationDate
FROM DWH_dbo.Fact_BillingWithdraw bw
LEFT JOIN 
  DWH_dbo.Dim_Currency c on c.CurrencyID = bw.ProcessCurrencyID
LEFT JOIN 
  DWH_dbo.Dim_BillingDepot de on de.DepotID = bw.DepotID
--LEFT JOIN 
--  DWH_dbo.Dim_BillingProtocolMIDSettingsID mid on mid.DepotID = bw.DepotID and mid. = bw.ProtocolMIDSettingsID
LEFT JOIN 
  BI_DB_dbo.External_etoro_Dictionary_CashoutType ct on ct.CashoutTypeID=bw.CashoutTypeID
LEFT JOIN 
	BI_DB_dbo.BI_DB_DepositWithdrawFee WF ON WF.WithdrawPaymentID=bw.WithdrawPaymentID
WHERE 
bw.CashoutStatusID_Funding=3
and bw.ModificationDate>='20250901'
and bw.FundingTypeID_Funding=1 --CREDITCARD