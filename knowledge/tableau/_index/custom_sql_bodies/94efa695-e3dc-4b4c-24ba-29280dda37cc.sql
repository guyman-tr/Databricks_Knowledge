SELECT rba.FirstDayOfMonth
	  ,rba.InstrumentType
	  ,rba.IsSettled
	  ,rba.Metric
	  ,c.Registered
	  ,c.Club
	  ,SUM(rba.Amount) Amount
FROM #RevenueByAsset rba
JOIN #CID c 
	ON rba.RealCID = c.RealCID
	AND rba.FirstDayOfMonth = c.FirstDayOfMonth
WHERE rba.Metric IN ('FullCommission' , 'TicketFeeByPercent', 'TicketFee' ,'RollOverFee')
GROUP BY rba.FirstDayOfMonth
	  ,rba.InstrumentType
	  ,rba.IsSettled
	  ,rba.Metric
	  ,c.Registered
	  ,c.Club