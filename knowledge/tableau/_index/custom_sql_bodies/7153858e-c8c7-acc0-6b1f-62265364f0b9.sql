SELECT
	dems.EvMatchStatusName
   ,CASE
		WHEN (dems.EvMatchStatusName = 'None' OR
			dems.EvMatchStatusName IS NULL) THEN 'Manual Verification'
		WHEN (dems.EvMatchStatusName = 'NotVerified' OR
			dems.EvMatchStatusName = 'PartiallyVerified') THEN 'Not Fully Verified'
		ELSE 'EV Check'
	END AS EVCheck_ind
   ,bdcd.VerificationLevel2Date AS Date
   ,bdcd.NewMarketingRegion AS NewMarketingRegion
   ,SUM(CASE
		WHEN dc.IsDepositor = 1 THEN 1
		ELSE 0
	END) AS depositors
   ,COUNT(dc.RealCID) AS clients_amount
   ,GETDATE() AS 'Update_date'
FROM DWH.dbo.Dim_Customer dc WITH (NOLOCK)
LEFT JOIN DWH.dbo.Dim_EvMatchStatus dems WITH (NOLOCK)
	ON dems.EvMatchStatusID = dc.EvMatchStatus
LEFT JOIN DWH.dbo.Dim_Country dcc WITH (NOLOCK)
	ON dcc.CountryID = dc.CountryID
INNER JOIN BI_DB.dbo.BI_DB_CIDFirstDates bdcd WITH (NOLOCK)
	ON dc.RealCID = bdcd.CID
		AND CAST(bdcd.VerificationLevel2Date AS DATE) > EOMONTH(DATEADD(MONTH, -3, GETDATE()) + 1)
WHERE dc.IsValidCustomer = 1
-- CAST(dc.RegisteredReal AS date) > EOMONTH(DATEADD(MONTH,-7,GETDATE())+1) AND  CAST(dc.RegisteredReal AS date)   <= EOMONTH(DATEADD(MONTH,-1,GETDATE())+1)
GROUP BY EvMatchStatusName
		,CASE
			 WHEN (dems.EvMatchStatusName = 'None' OR
				 dems.EvMatchStatusName IS NULL) THEN 'Manual Verification'
			 WHEN (dems.EvMatchStatusName = 'NotVerified' OR
				 dems.EvMatchStatusName = 'PartiallyVerified') THEN 'Not Fully Verified'
			 ELSE 'EV Check'
		 END
		,bdcd.VerificationLevel2Date
		,bdcd.NewMarketingRegion