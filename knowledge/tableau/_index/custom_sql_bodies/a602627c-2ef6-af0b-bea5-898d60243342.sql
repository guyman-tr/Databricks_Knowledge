SELECT q1.CID
	  ,q1.ActiveDate
	  ,q1.OptInDate
	  ,q1.SeniorityOptIn
	  ,q1.OptIn
	  ,q1.EOM_Club
	  ,q1.EOM_Balance
	  ,q1.PlatinumPlusSeniority2023 
	  ,q1.TotalCashouts
	  ,q1.TotalDeposits
	  ,DATEDIFF(MONTH,q1.PlatinumPlusSeniority2023,q1.ActiveDate) SeniorityPlatinum
	  ,q1.EquityLastMonth
	  ,q1.NetDeposits
	  ,q1.Country
	  ,q1.IsOptIn
	  ,q1.NewMarketingRegion 
FROM 
(
SELECT q0.CID
	  ,q0.ActiveDate
	  ,q0.OptInDate
	  ,DATEDIFF(MONTH,OptInDate,ActiveDate) SeniorityOptIn
	  ,q0.OptIn
	  ,q0.EOM_Club
	  ,q0.EOM_Balance
	  ,q0.TotalCashouts
	  ,q0.TotalDeposits
	  ,MIN(CASE WHEN q0.EOM_Club = <[Parameters].[Parameter 1]> THEN q0.ActiveDate END) OVER (PARTITION BY  CID) PlatinumPlusSeniority2023
	  ,q0.EquityLastMonth
	  ,q0.NetDeposits
	  ,q0.Country
	  ,q0.IsOptIn
	  ,q0.NewMarketingRegion 
FROM 
(
SELECT fm.CID
	  ,fm.ActiveDate
	  ,oi.ActiveDate  OptInDate
	  ,CASE WHEN fm.ActiveDate >=oi.ActiveDate THEN 1 ELSE 0 END OptIn
	  ,fm.EOM_Club
	  ,fm.EOM_Balance
	  ,fm.TotalCashouts
	  ,fm.TotalDeposits
	  ,fm.NetDeposits
	  ,CASE WHEN oi.ActiveDate IS NULL THEN 1 ELSE 0 END IsOptIn
	  ,LAG(fm.EOM_Equity) OVER (PARTITION BY fm.CID ORDER BY fm.ActiveDate) EquityLastMonth
	  ,fm.Country
	  ,fm.NewMarketingRegion 
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK) 
LEFT JOIN #Optin oi
ON oi.CID = fm.CID
WHERE fm.ActiveDate >='20221201'
and EOM_Club NOT IN ('HighBronze','LowBronze')
)q0
WHERE q0.ActiveDate >='20230101'
)q1
WHERE q1.PlatinumPlusSeniority2023  IS NOT NULL