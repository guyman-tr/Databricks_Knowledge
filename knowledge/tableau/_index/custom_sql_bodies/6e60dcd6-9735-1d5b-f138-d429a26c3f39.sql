SELECT cast(DATEADD(m, DATEDIFF(m, 0, vl.FullDate), 0) AS DATE) Date
		,avg(vl.TotalPositionsAmount+vl.TotalCash+vl.PositionPnL) AS Avg_Total_Equity
		,avg(vl.PositionPnL) AS Avg_PnL
		,avg(vl.TotalPositionsAmount) AS Avg_Invested_Amount
FROM DWH_dbo.V_Liabilities vl
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
				WHERE c.DateID >= CAST(CONVERT(VARCHAR(8), dateadd(m,-24,getdate()), 112) AS INT)
				GROUP BY c.InstrumentType
						,MONTH(Date)
						,Year(Date)
						,c.InstrumentTypeID
						,c.CID) a
			WHERE a.rn <= 100
) b
ON b.CID = vl.CID AND b.Month = MONTH(vl.FullDate) AND b.Year = YEAR(vl.FullDate) AND b.CID IS NULL
WHERE vl.FullDate >= dateadd(m,-24,getdate())
GROUP BY cast(DATEADD(m, DATEDIFF(m, 0, vl.FullDate), 0) AS DATE)