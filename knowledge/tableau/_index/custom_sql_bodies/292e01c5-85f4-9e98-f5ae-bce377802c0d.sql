SELECT 
dcdf.Date
,dcdf.InstrumentID
	  ,dcdf.InstrumentDisplayName
	  ,dcdf.other_closed
	  ,dcdf.sl_closed
	  ,dcdf.tp_closed
	  ,dcdf.opened
	  ,cdcm.opened AS [3Month_opened]
	  ,cdcm.sl_closed AS [3Month_sl_closed]
	  ,cdcm.tp_closed as [3Month_tp_closed]
	  ,cdcm.other_closed as [3Month_other_closed]
	  ,cdcm1.opened AS [6Month_opened]
	  ,cdcm1.sl_closed AS [6Month_sl_closed]
	  ,cdcm1.tp_closed as [6Month_tp_closed]
	  ,cdcm1.other_closed as [6Month_other_closed]
	  FROM Dealing_dbo.Dealing_ClientDataFinal dcdf
 left join [Dealing_dbo].[Dealing_ClientsDataChange_3Months] cdcm ON dcdf.Date BETWEEN DATEADD(DAY, -2, cdcm.Date) AND DATEADD(DAY, 2, cdcm.Date)  AND dcdf.InstrumentID = cdcm.InstrumentID
 FULL OUTER join [Dealing_dbo].[Dealing_ClientsDataChange_6Months] cdcm1 ON dcdf.Date BETWEEN DATEADD(DAY, -2, cdcm1.Date) AND DATEADD(DAY, 2, cdcm1.Date) AND dcdf.InstrumentID = cdcm1.InstrumentID