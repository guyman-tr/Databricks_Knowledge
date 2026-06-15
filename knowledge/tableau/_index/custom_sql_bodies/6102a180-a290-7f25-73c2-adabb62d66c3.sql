SELECT o.*, ft.Name as FundingType 
FROM BI_DB.dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard o
left join DWH.dbo.Fact_BillingWithdraw bw on bw.WithdrawID=o.WithdrawID
LEFT join DWH.dbo.Dim_FundingType ft on ft.FundingTypeID=bw.FundingTypeID_Funding