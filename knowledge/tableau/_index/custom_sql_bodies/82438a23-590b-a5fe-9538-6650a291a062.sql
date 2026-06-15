SELECT c.InstrumentType
		,cast(DATEADD(m, DATEDIFF(m, 0, c.Date), 0) AS DATE) Date
		,month(c.Date) Month
		,year(Date) Year
		,sum(c.Volume) AS Volume
		,sum(c.FullCommission) Commission
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c 
LEFT JOIN (SELECT a.Month
				,a.Year
				,a.InstrumentType
				,a.InstrumentTypeID
				,a.CID
			FROM (SELECT DISTINCT c.InstrumentType
					,Month(Date) Month
					,Year(Date) Year
					,c.InstrumentTypeID
					,c.CID
					,ROW_NUMBER() OVER (PARTITION BY c.InstrumentType, MONTH(c.Date), Year(c.Date) ORDER BY sum(c.FullCommission) DESC) rn
				FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c 
				WHERE c.DateID >= CAST(CONVERT(VARCHAR(8), dateadd(m,-12,getdate()), 112) AS INT)
				GROUP BY c.InstrumentType
						,MONTH(Date)
						,Year(Date)
						,c.InstrumentTypeID
						,c.CID) a
			WHERE a.rn <= 100) t
ON c.InstrumentTypeID = t.InstrumentTypeID AND c.CID = t.CID AND Month(c.Date) = t.Month AND YEAR(c.Date) = Year
WHERE c.DateID >= CAST(CONVERT(VARCHAR(8), dateadd(m,-12,getdate()), 112) AS INT)
		AND c.InstrumentTypeID IN (2,4,1,5,6)
		AND t.CID IS NULL -- exclude big CIDs
		AND c.IsCopy = 0
		AND c.IsCFD = 1
GROUP BY c.InstrumentType
		,month(c.Date)
		,year(c.Date)
		,DATEADD(m, DATEDIFF(m, 0, c.Date), 0)