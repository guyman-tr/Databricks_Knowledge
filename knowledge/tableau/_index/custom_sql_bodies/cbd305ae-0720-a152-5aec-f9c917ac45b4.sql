SELECT t5s25.[index]
	  ,t5s25.InstrumentID
	  ,t5s25.InstrumentName
	  ,t5s25.Zero
	  ,t5s25.Hour80NopPnl
	  ,t5s25.HourNopPnl
	  ,t5s25.DeltaPnl AS [DeltaPnlT5S25]
	  ,t5s25.[50DeltaPnl] AS [50DeltaPnlT5S25]
	  ,t5s25.[25DeltaPnl] AS [25DeltaPnlT5S25]
	  ,t15s25.DeltaPnl AS [DeltaPnlT15S25]
	  ,t15s25.[50DeltaPnl] AS [50DeltaPnlT15S25]
	  ,t15s25.[25DeltaPnl] AS [25DeltaPnlT15S25]
	  ,t5sw.DeltaPnl AS [DeltaPnlT5SW]
	  ,t5sw.[50DeltaPnl] AS [50DeltaPnlT5SW]
	  ,t5sw.[25DeltaPnl] AS [25DeltaPnlT5SW] 
	  ,t15sw.DeltaPnl AS [DeltaPnlT15SW] 
	  ,t15sw.[50DeltaPnl] AS [50DeltaPnlT15SW] 
	  ,t15sw.[25DeltaPnl] AS [25DeltaPnlT15SW]
	  ,t15sw2.DeltaPnl AS [DeltaPnlT15SW2] 
	  ,t15sw2.[50DeltaPnl] AS [50DeltaPnlT15SW2] 
	  ,t15sw2.[25DeltaPnl] AS [25DeltaPnlT15SW2]
	  FROM 
Dealing_Dev.dbo.Nixar_Type4BacktestT5Sigma25 t5s25
JOIN 
Dealing_Dev.dbo.Nixar_Type4BacktestT15Sigma25 t15s25
ON t5s25.[index] = t15s25.[index] AND t5s25.InstrumentID = t15s25.InstrumentID
JOIN
Dealing_Dev.dbo.Nixar_Type4BacktestT5SigmaWeighted t5sw
ON t5s25.[index] = t5sw.[index] AND t5s25.InstrumentID = t5sw.InstrumentID
join
Dealing_Dev.dbo.Nixar_Type4BacktestT15SigmaWeighted t15sw
ON t5s25.[index] = t15sw.[index] AND t5s25.InstrumentID = t15sw.InstrumentID
join
Dealing_Dev.dbo.Nixar_Type4BacktestT15SigmaWeighted2 t15sw2
ON t5s25.[index] = t15sw2.[index] AND t5s25.InstrumentID = t15sw2.InstrumentID