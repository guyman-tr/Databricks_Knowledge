select 
	W.* 
	,dr.Name as Regulation
	,dc1.Name as Country
	,dc1.Region
	,bw.ModificationDate
from 
	[BI_DB_dbo].[BI_DB_HourlyReport_Withdraws] W
join 
	DWH_dbo.Dim_Customer dc on dc.RealCID=W.CID
JOIN 
	DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
join 
	DWH_dbo.Dim_Country dc1 on dc1.CountryID=dc.CountryID
LEFT JOIN
	DWH_dbo.Fact_BillingWithdraw bw on bw.WithdrawID = W.WithdrawID
where 
	CashoutStatusID <> 4 --Cancelled