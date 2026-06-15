SELECT 
	count(d.CID) as TotalClients
	,count(d.DepositID) as NumOfDeposits
	,f.Name as FundingType
	,r.Name as Regulation
	,c.Name as Country
	,cast(d.ModificationDate as date) as ModificationDate
	,sum(d.AmountUSD) as AmountUSD
	,d.IsFTD
	,c.Region
	,CASE WHEN d.IsFTD = 1 THEN 'FTD' ELSE 'Redeposit' END AS 'Ftd/Redeposit'
FROM 
	DWH_dbo.Fact_BillingDeposit d
LEFT JOIN 
	DWH_dbo.Dim_Customer dc on dc.RealCID = d.CID
LEFT JOIN 
	DWH_dbo.Dim_FundingType f on f.FundingTypeID = d.FundingTypeID
LEFT JOIN 
	DWH_dbo.Dim_Regulation r on r.ID = dc.RegulationID
LEFT JOIN 
	DWH_dbo.Dim_Country c on c.CountryID = dc.CountryID
WHERE 
	d.PaymentStatusID=2
	AND d.ModificationDate>='20240101'
GROUP BY 
	f.Name 
	,r.Name 
	,c.Name
	,cast(d.ModificationDate as date) 
	,d.IsFTD
	,c.Region
	,CASE WHEN d.IsFTD = 1 THEN 'FTD' ELSE 'Redeposit' END