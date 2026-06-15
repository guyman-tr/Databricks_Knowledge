SELECT  	
m.Date, 	
count(m.RealCID) as CountTotalFTDs,     
SUM(AmountUSD) AS SumTotalFTDs 
FROM  	[BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms] m 
LEFT JOIN  	DWH_dbo.Dim_Customer dc on dc.RealCID = m.RealCID 
LEFT JOIN  	DWH_dbo.Dim_Regulation r on r.ID = dc.RegulationID 
where  	
m.MIMOAction = 'Deposit' 	
and m.IsPlatformFTD = 1 	
and m.DateID >= 20170101 
and m.MIMOPlatform = 'TradingPlatform' 
group by   	m.Date