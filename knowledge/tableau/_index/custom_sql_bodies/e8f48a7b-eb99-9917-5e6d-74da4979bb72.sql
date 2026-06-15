SELECT c.InstrumentType
	-- Volume
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Volume * d.CurrentMonth_TotalDays / d.CurrentDate_DayNumber ELSE 0 END) CurrentMonth_Extrapolated_Volume
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Volume ELSE 0 END) LastMonth_Volume
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Volume ELSE 0 END) MonthBeforeLastMonth_Volume
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Volume ELSE 0 END) Trailing_Year_Volume
	--Commission
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.FullCommission * d.CurrentMonth_TotalDays / d.CurrentDate_DayNumber ELSE 0 END) CurrentMonth_Extrapolated_Commission
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.FullCommission ELSE 0 end) LastMonth_Commission
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.FullCommission ELSE 0 end) MonthBeforeLastMonth_Commission
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.FullCommission ELSE 0 end) TrailingYear_Commission
	-- Avg Click Size
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Volume ELSE 0 END) /
			nullif(sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Click ELSE 0 END),0) CurrentMonth_Avg_ClickSize
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Volume ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Click ELSE 0 END),0) LastMonth_Avg_ClickSize
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Volume ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Click ELSE 0 END),0) MonthBeforeLastMonth_Avg_ClickSize
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Volume ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Click ELSE 0 END),0) Trailing_Year_Avg_ClickSize
	-- Number of Clicks
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Click * d.CurrentMonth_TotalDays / d.CurrentDate_DayNumber ELSE 0 END) CurrentMonth_Extrapolated_Nb_Clicks
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Click ELSE 0 END) LastMonth_Nb_Clicks
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Click ELSE 0 END) MonthBeforeLastMonth_Nb_Clicks
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Click ELSE 0 END) Trailing_Year_Nb_Clicks
	-- Unique CIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.CurrentMonth_StartID
			THEN c.CID ELSE 0 END)) CurrentMonth_UniqueCIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.CID ELSE 0 END)) LastMonth_UniqueCIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.CID ELSE 0 END)) MonthBeforeLastMonth_UniqueCIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.CID ELSE 0 END)) Trailing_Year_UniqueCIDs
	-- Avg Invested Amount
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) /
			nullif(sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
						AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) CurrentMonth_Avg_InvestedAmount
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID 
					AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) LastMonth_Avg_InvestedAmount
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
					AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) MonthBeforeLastMonth_Avg_InvestedAmount
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
					AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) Trailing_Year_Avg_InvestedAmount
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c 
LEFT JOIN (SELECT CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT) DateID
		,CAST(CONVERT(VARCHAR(8), DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0), 112) AS INT) CurrentMonth_StartID
		,datediff(dd,getdate(),dateadd(mm,1,getdate())) CurrentMonth_TotalDays
		,DAY(GETDATE()) CurrentDate_DayNumber
		,CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-1,0), 112) AS INT) LastMonth_StartID
		,CAST(CONVERT(VARCHAR(8), DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)), 112) AS INT) LastMonth_EndID
		,CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-2,0), 112) AS INT) MonthBeforeLastMonth_StartID
		,CAST(CONVERT(VARCHAR(8), DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, GETDATE())-1, 0)), 112) AS INT) MonthBeforeLastMonth_EndID
		,CAST(CONVERT(VARCHAR(8), dateadd(m,-12,getdate()), 112) AS INT) Year_BeforeID) d
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
WHERE c.InstrumentTypeID IN (2,4,1,5,6)
		AND t.CID IS NULL -- exclude big CIDs
		AND c.IsCopy = 0
		AND c.IsCFD = 1
GROUP BY c.InstrumentType

UNION

SELECT 'Total' AS InstrumentType
	-- Volume
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Volume * d.CurrentMonth_TotalDays / d.CurrentDate_DayNumber ELSE 0 END) CurrentMonth_Extrapolated_Volume
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Volume ELSE 0 END) LastMonth_Volume
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Volume ELSE 0 END) MonthBeforeLastMonth_Volume
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Volume ELSE 0 END) Trailing_Year_Volume
	--Commission
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.FullCommission * d.CurrentMonth_TotalDays / d.CurrentDate_DayNumber ELSE 0 END) CurrentMonth_Extrapolated_Commission
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.FullCommission ELSE 0 end) LastMonth_Commission
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.FullCommission ELSE 0 end) MonthBeforeLastMonth_Commission
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.FullCommission ELSE 0 end) TrailingYear_Commission
	-- Avg Click Size
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Volume ELSE 0 END) /
			nullif(sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Click ELSE 0 END),0) CurrentMonth_Avg_ClickSize
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Volume ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Click ELSE 0 END),0) LastMonth_Avg_ClickSize
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Volume ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Click ELSE 0 END),0) MonthBeforeLastMonth_Avg_ClickSize
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Volume ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Click ELSE 0 END),0) Trailing_Year_Avg_ClickSize
	-- Number of Clicks
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.Click * d.CurrentMonth_TotalDays / d.CurrentDate_DayNumber ELSE 0 END) CurrentMonth_Extrapolated_Nb_Clicks
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.Click ELSE 0 END) LastMonth_Nb_Clicks
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.Click ELSE 0 END) MonthBeforeLastMonth_Nb_Clicks
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.Click ELSE 0 END) Trailing_Year_Nb_Clicks
	-- Unique CIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.CurrentMonth_StartID
			THEN c.CID ELSE 0 END)) CurrentMonth_UniqueCIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.CID ELSE 0 END)) LastMonth_UniqueCIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.CID ELSE 0 END)) MonthBeforeLastMonth_UniqueCIDs
		,Count(DISTINCT (CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.CID ELSE 0 END)) Trailing_Year_UniqueCIDs
	-- Avg Invested Amount
		,sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) /
			nullif(sum(CASE WHEN c.DateID >= d.CurrentMonth_StartID 
						AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) CurrentMonth_Avg_InvestedAmount
		,sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.LastMonth_StartID
					AND c.DateID <= d.LastMonth_EndID 
					AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) LastMonth_Avg_InvestedAmount
		,sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.MonthBeforeLastMonth_StartID
					AND c.DateID <= d.MonthBeforeLastMonth_EndID
					AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) MonthBeforeLastMonth_Avg_InvestedAmount
		,sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
			THEN c.InitialAmountUSDOnOpen ELSE 0 END) / 
			nullif(sum(CASE WHEN c.DateID >= d.Year_BeforeID
					AND c.DateID <= d.DateID
					AND c.OpenOrCloseID = 1
			THEN c.Click ELSE 0 END),0) Trailing_Year_Avg_InvestedAmount
FROM Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown c 
LEFT JOIN (SELECT CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT) DateID
		,CAST(CONVERT(VARCHAR(8), DATEADD(m, DATEDIFF(m, 0, GETDATE()), 0), 112) AS INT) CurrentMonth_StartID
		,datediff(dd,getdate(),dateadd(mm,1,getdate())) CurrentMonth_TotalDays
		,DAY(GETDATE()) CurrentDate_DayNumber
		,CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-1,0), 112) AS INT) LastMonth_StartID
		,CAST(CONVERT(VARCHAR(8), DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)), 112) AS INT) LastMonth_EndID
		,CAST(CONVERT(VARCHAR(8), DATEADD(m,DATEDIFF(m,0,GETDATE())-2,0), 112) AS INT) MonthBeforeLastMonth_StartID
		,CAST(CONVERT(VARCHAR(8), DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, GETDATE())-1, 0)), 112) AS INT) MonthBeforeLastMonth_EndID
		,CAST(CONVERT(VARCHAR(8), dateadd(m,-12,getdate()), 112) AS INT) Year_BeforeID) d
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
WHERE c.InstrumentTypeID IN (2,4,1,5,6)
		AND t.CID IS NULL -- exclude big CIDs
		AND c.IsCopy = 0
		AND c.IsCFD = 1