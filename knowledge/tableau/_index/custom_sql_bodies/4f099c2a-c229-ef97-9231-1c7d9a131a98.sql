SELECT  dc.GCID
      ,CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate
	  ,CAST(dc.RegisteredReal AS DATE) AS RegDate
	  ,dc1.Name AS Country
	  ,ISNULL(b.Crypto_revenue_2023,0) AS Crypto_revenue_2023
	  ,ISNULL(b.Revenue_2023,0) AS Revenue_2023
FROM DWH_dbo.Dim_Customer dc WITH (NOLOCK)
INNER JOIN 
(SELECT bddcr.CountryID
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr WITH (NOLOCK)
WHERE bddcr.DateID>20230101
GROUP BY bddcr.CountryID
HAVING SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END)>0
)a ON dc.CountryID=a.CountryID
LEFT JOIN 
(SELECT bddcr.RealCID
       ,SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END) AS Crypto_revenue_2023
	   ,SUM( bddcr.FullCommissions +bddcr.RollOverFee ) AS Revenue_2023
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr WITH (NOLOCK)
WHERE bddcr.DateID>20230101
GROUP BY bddcr.RealCID
HAVING SUM(CASE WHEN InstrumentTypeID = 10 THEN bddcr.FullCommissions +bddcr.RollOverFee ELSE 0 END)>0
) b ON dc.RealCID=b.RealCID
INNER JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
WHERE  dc.GCID LIKE '%[013]'
AND dc.IsValidCustomer=1 
AND dc.RegisteredReal>='20211101' 
AND dc.RegisteredReal<'20231101' 
AND dc.VerificationLevelID=3