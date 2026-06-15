select 
	fbd.CID,
	fbd.ModificationDate, 
	ft.Name as MOP,
	fbd.AmountUSD,
	dr.Name AS Regulation,
pl.Name as Club
from DWH_dbo.Fact_BillingDeposit fbd
join DWH_dbo.Dim_Customer dc on dc.RealCID=fbd.CID
left join DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
left join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=dc.PlayerLevelID
join DWH_dbo.Dim_FundingType ft on ft.FundingTypeID=fbd.FundingTypeID
where fbd.PaymentStatusID=37	--ChargebackReversal
and fbd.ModificationDateID>='20250101'