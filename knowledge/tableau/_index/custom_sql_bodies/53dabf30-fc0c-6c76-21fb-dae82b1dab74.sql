SELECT t.Date
	  ,t.OrderID
	  ,t.InstrumentID
	  ,t.InstrumentDisplayName
	  ,t.HedgeServer
	  ,t.LiquidityAccountID
	  ,t.LiquidityAccountName
	  ,t.IsBuy
	  ,t.Units
	  ,t.ExecutionRate
	  ,t.UpdateDate
	  ,t.Sender
	  ,t.ExecutionTime
            ,t.RequestTypeID
	  ,p.ConvertRateIsBuy_1
	  ,p.ConvertRateIsBuy_0
FROM Dealing_dbo.Dealing_Manual_Exec_Trade t
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit p
ON t.Date = p.OccurredDate AND t.InstrumentID = p.InstrumentID