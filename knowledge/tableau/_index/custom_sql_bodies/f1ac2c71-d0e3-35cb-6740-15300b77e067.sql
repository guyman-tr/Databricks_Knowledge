SELECT 
dcdf.Date
,dcdf.InstrumentID
	  ,dcdf.InstrumentDisplayName
	  ,dcdf.WeeklyTotalVolume
	  ,dcdf.AvgWeeklyOrderSize
	  ,dcdf.MaxWeeklyOrderSize
	  ,dcdf.AvgWeeklyInvestedAmt
	  ,cdcm.AverageMaximumWeeklyOrderSize AS [3MonthAverageMaximumWeeklyOrderSize]
	  ,cdcm.Avg3MonthInvestedAmt as [Avg3MonthInvestedAmt]
	  ,cdcm.Avg3MonthOrderSize AS [Avg3MonthOrderSize]
	  ,cdcm.MaxWeeklyOrderSize AS [Avg3MonthMaxWeeklyOrderSize]
	  ,cdcm1.AverageMaximumWeeklyOrderSize AS [6MonthAverageMaximumWeeklyOrderSize]
	  ,cdcm1.Avg3MonthInvestedAmt AS [Avg6MonthInvestedAmt]
	  ,cdcm1.Avg3MonthOrderSize AS [Avg6MonthOrderSize]
	  ,cdcm1.MaxWeeklyOrderSize AS [Avg6MonthMaxWeeklyOrderSize]
	  FROM Dealing_dbo.Dealing_ClientDataFinal dcdf
 left join [Dealing_dbo].[Dealing_ClientsDataChange_3Months] cdcm ON dcdf.Date BETWEEN DATEADD(DAY, -2, cdcm.Date) AND DATEADD(DAY, 2, cdcm.Date)  AND dcdf.InstrumentID = cdcm.InstrumentID
 FULL OUTER join [Dealing_dbo].[Dealing_ClientsDataChange_6Months] cdcm1 ON dcdf.Date BETWEEN DATEADD(DAY, -2, cdcm1.Date) AND DATEADD(DAY, 2, cdcm1.Date) AND dcdf.InstrumentID = cdcm1.InstrumentID