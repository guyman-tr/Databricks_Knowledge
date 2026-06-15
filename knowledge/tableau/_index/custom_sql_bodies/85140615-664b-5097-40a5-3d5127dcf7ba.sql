SELECT bdadh.* 
      ,NULL [Platform]
      ,NULL MOPCountry
      ,dc.Region [Region (Custom SQL Query)]
	  ,dc.EU
	  ,dc.Name 
	 -- ,CASE WHEN bt1.TransactionId IS NOT NULL THEN 1 ELSE 0 END IsThreeDS 
      ,NULL MOPRegion
      ,dc3.Name WireCountry
      ,dc3.Region WireRegion
FROM BI_DB_dbo.BI_DB_AllDeposits bdadh
LEFT JOIN DWH_dbo.Dim_Country dc
	ON dc.Name = bdadh.BINCountry
--left join OPENQUERY([AZR-W-REAL-DB-2-BIDBUser],'SELECT DISTINCT a.TransactionId 
	--		FROM etoro.Billing.Trace a') bt1
	--ON bdadh.DepositID = bt1.TransactionId
LEFT JOIN DWH_dbo.Dim_Country dc3
    ON dc3.CountryID = CAST(bdadh.CountryIDAsInteger AS INT)