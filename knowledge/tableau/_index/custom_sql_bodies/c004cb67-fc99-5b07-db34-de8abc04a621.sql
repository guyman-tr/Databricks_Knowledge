SELECT dbecc.Date
	  ,dbecc.PositionID
	  ,dbecc.CID
	  ,dc.GCID
	  ,dbecc.InstrumentID
	  ,dbecc.InstrumentName
	  ,dbecc.InstrumentTypeID
	  ,dbecc.InstrumentType
	  ,dbecc.HedgeServerID
	  ,dbecc.MirrorID
	  ,dbecc.IsBuy
	  ,dbecc.OrigIsBuy
	  ,dbecc.ExecutionAmountInUnits
	  ,dbecc.AmountInUnitsDecimal
	  ,dbecc.Occurred
	  ,dbecc.EndForexRate
	  ,dbecc.ConversionRate
	  ,dbecc.ActionTypeID
	  ,dbecc.ActionType
	  ,dbecc.IsOpen
	  ,dbecc.Bid
	  ,dbecc.Ask
	  ,dbecc.OccurredAtServer
	  ,dbecc.StopRate
	  ,dbecc.LimitRate
	  ,dbecc.ClientViewRate
	  ,dbecc.CustomerChosenRate
	  ,dbecc.SlippageInDollar
	  ,dbecc.[slippage %]
	  ,dbecc.RequestTime
	  ,dbecc.OverThreshold
	  ,dbecc.OpenSession
	  ,dbecc.Volume
	  ,dbecc.Regulation
	  ,dbecc.TriggerRate
	  ,dbecc.ChosenToTrigger
	  ,dbecc.TriggerToReceived
	  ,dbecc.IsDiscounted
	  ,dbecc.PriceRateID
	  ,dbecc.FinalOccurred
	  ,dbecc.HedgingMode
	  ,dbecc.LiquidityAccountID
	  ,dbecc.LiquidityAccountName
	  ,dbecc.Spread
	  ,dbecc.LP_Rate
	  ,dbecc.Percent_Diff
	  ,dbecc.Compensation_Limit
	  ,dbecc.Compensation
	  ,dbecc.UpdateDate
	  ,pd.UserName
	  ,pd.PI_level
	  ,pd.AUM AS TreeSizeDollar
FROM Dealing.dbo.Dealing_Best_Execution_Compensation_CBH dbecc
JOIN BI_DB.dbo.BI_DB_PI_Dashboard pd
ON dbecc.Date = pd.Date AND dbecc.CID = pd.CID
JOIN DWH..Dim_Customer dc
ON dc.RealCID= dbecc.CID
WHERE PI_level IN ('Elite', 'Elite Pro')