Select 
	dc.RealCID
	,dc.GCID
	,dc.AffiliateID
	,dc.RegisteredReal
	,c.Name as Country
	,r.Name as Regulation
	,ps.Name as PlayeStatus
	,pl.Name as PlayerLevel
	,SUM(d.AmountUSD) as TotalDeposits
from 
	DWH_dbo.Dim_Customer dc
LEFT JOIN 
	DWH_dbo.Dim_Country c on c.CountryID = dc.CountryIDByIP
LEFT JOIN 
	DWH_dbo.Dim_Regulation r on r.ID = dc.RegulationID
LEFT JOIN 
	DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID = dc.PlayerStatusID
LEFT JOIN 
	DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN 
	DWH_dbo.Fact_BillingDeposit d on d.CID = dc.RealCID and d.PaymentStatusID = 2
JOIN 
	(Select distinct ReferralID from #cids) c1 on c1.ReferralID = dc.RealCID
GROUP BY 
		dc.RealCID
	,dc.GCID
	,dc.AffiliateID
	,dc.RegisteredReal
	,c.Name
	,r.Name 
	,ps.Name 
	,pl.Name