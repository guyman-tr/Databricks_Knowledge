SELECT 
	m.MIMOPlatform,
	m.Date,
	r.Name as Regulation,
	count(m.RealCID) as CountTotalRedeposits,
    SUM(AmountUSD) AS SumTotalRedeposits
FROM 
	[BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms] m
LEFT JOIN 
	DWH_dbo.Dim_Customer dc on dc.RealCID = m.RealCID
LEFT JOIN 
	DWH_dbo.Dim_Regulation r on r.ID = dc.RegulationID
where 
	m.MIMOAction = 'Deposit'
	and m.IsPlatformFTD <> 1
	and m.DateID >= 20170101
group by    
	MIMOPlatform,
	r.Name,
	m.Date