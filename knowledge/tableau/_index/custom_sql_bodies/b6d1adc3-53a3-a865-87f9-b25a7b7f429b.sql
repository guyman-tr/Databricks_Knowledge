SELECT c.InstrumentID
		,c.InstrumentDisplayName
		,c.InstrumentType
	-- Volume
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Volume ELSE 0 END) LastMonth_Volume
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Volume ELSE 0 END) MonthBeforeLastMonth_Volume
	--Commission
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.FullCommission ELSE 0 end) LastMonth_Commission
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.FullCommission ELSE 0 end) MonthBeforeLastMonth_Commission
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c 
LEFT JOIN (SELECT CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT) DateID
		,CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-1,0), 112) AS INT) LastMonth_StartID
		,CAST(CONVERT(VARCHAR(8), DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)), 112) AS INT) LastMonth_EndID
		,CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-2,0), 112) AS INT) MonthBeforeLastMonth_StartID
		,CAST(CONVERT(VARCHAR(8), DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, GETDATE())-1, 0)), 112) AS INT) MonthBeforeLastMonth_EndID) d
ON d.DateID = CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)
LEFT JOIN (SELECT a.InstrumentType
				,a.InstrumentTypeID
				,a.CID
			FROM (SELECT DISTINCT c.InstrumentType
					,c.InstrumentTypeID
					,c.CID
					,ROW_NUMBER() OVER (PARTITION BY c.InstrumentType ORDER BY sum(c.FullCommission) DESC) rn
				FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c 
				WHERE c.DateID >= CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-1,0), 112) AS INT) -- LastMonthStart
				GROUP BY c.InstrumentType
						,c.InstrumentTypeID
						,c.CID) a
			WHERE a.rn <= 100) t
ON c.InstrumentTypeID = t.InstrumentTypeID AND c.CID = t.CID
WHERE c.InstrumentTypeID IN (4,2)
		AND t.CID IS NULL -- exclude big CIDs
		AND c.IsCopy = 0
		AND c.IsCFD = 1
GROUP BY c.InstrumentID
		,c.InstrumentDisplayName
		,c.InstrumentType