SELECT DISTINCT
	dc.RealCID
	,c.Name as Country
	,dc.AffiliateID
	,dc.GCID
	,r.Name as Regulation
	,ps.Name as PlayeStatus
	,pl.Name as PlayerLevel
	,dc.ReferralID
	,dc.RegisteredReal
	,SUM(d.AmountUSD) as TotalDeposits
FROM
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
WHERE 
	dc.ReferralID <> 0
	and dc.RegisteredReal >= '2025-01-01'
GROUP BY 
	dc.RealCID
	,c.Name
	,r.Name 
	,ps.Name
	,pl.Name 
	,dc.ReferralID
	,dc.RegisteredReal
	,dc.AffiliateID
	,dc.GCID