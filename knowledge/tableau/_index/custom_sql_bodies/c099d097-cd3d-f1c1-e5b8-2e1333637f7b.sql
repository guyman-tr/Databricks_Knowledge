SELECT 
		dcdf.Date
		,dcdf.InstrumentID
	  ,dcdf.InstrumentDisplayName
	  ,dcdf.AvgUniqueCIDsPerDay
	  ,dcdf.AvgDailyTrades
	  ,dcdf.AvgDailyVolume
	  ,cdcm.AvgDailyVolume as [3MonthAvgDailyVolume]
	  ,cdcm.AvgDailyTrades as [3MonthAvgDailyTrades]
	  ,cdcm.AvgUniqueCIDsPerDay as [3MonthAvgUniqueCIDsPerDay]
	  ,cdcm1.AvgDailyVolume AS [6MonthAvgDailyVolume]
	  ,cdcm1.AvgDailyTrades AS [6MonthAvgDailyTrades]
	  ,cdcm1.AvgUniqueCIDsPerDay AS [6MonthAvgUniqueCIDsPerDay]
	  FROM Dealing_dbo.Dealing_ClientDataFinal dcdf
 left join [Dealing_dbo].[Dealing_ClientsDataChange_3Months] cdcm ON dcdf.Date BETWEEN DATEADD(DAY, -2, cdcm.Date) AND DATEADD(DAY, 2, cdcm.Date)  AND dcdf.InstrumentID = cdcm.InstrumentID
 FULL OUTER join [Dealing_dbo].[Dealing_ClientsDataChange_6Months] cdcm1 ON dcdf.Date BETWEEN DATEADD(DAY, -2, cdcm1.Date) AND DATEADD(DAY, 2, cdcm1.Date) AND dcdf.InstrumentID = cdcm1.InstrumentID