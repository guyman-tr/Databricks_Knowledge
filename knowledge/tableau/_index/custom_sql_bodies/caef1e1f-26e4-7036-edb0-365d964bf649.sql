SELECT  
       cast(LEFT(DateID, 6) as INT) YearMonth
	  ,SUM(Amount+PositionPnL) AUA
	  ,di.InstrumentType
	  ,dc1.Name Country
      ,Region
      ,CASE WHEN dp.MirrorID = 0 THEN 0 ELSE 1 END IsCopy
	  ,CASE WHEN Leverage >1 or IsBuy = 0 THEN 1 ELSE 0 END IsCFD
FROM BI_DB..BI_DB_PositionPnL dp
JOIN DWH..Dim_Date dd
ON dp.DateID = dd.DateKey
JOIN DWH..Dim_Instrument di
ON dp.InstrumentID = di.InstrumentID
JOIN DWH..Dim_Customer dc
ON dp.CID = dc.RealCID
JOIN DWH..Dim_Country dc1
ON dc.CountryID = dc1.CountryID
WHERE DateID >= CONVERT(char(8),DATEADD(month, DATEDIFF(month, 0, DATEADD(MONTH,-6,GETDATE())), 0),112) 
AND dc1.Region in ('Other Asia', 'China')
AND (CASE WHEN IsLastDayOfMonth = 'Y' OR dp.DateID = CONVERT(CHAR(8),CAST(GETDATE()-1 AS DATE),112) THEN 1 ELSE 0 END) = 1 
GROUP BY cast(LEFT(DateID, 6) as INT)
		,di.InstrumentType
	    ,dc1.Name 
        ,Region
        ,CASE WHEN dp.MirrorID = 0 THEN 0 ELSE 1 END
		,CASE WHEN Leverage >1 or IsBuy = 0 THEN 1 ELSE 0 END