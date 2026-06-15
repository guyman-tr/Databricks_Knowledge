SELECT dmz.Date
	  ,dmz.CurrencyID
	  ,dmz.Currency_Name
	  ,dmz.Deposits AS DepositsInUSD--In USD
	  ,dmz.Withdraws AS WithdrawsInUSD--In USD
	  ,dmz.Net AS NetInUSD--In USD
	  ,dmz.DepositsInLocalValue
	  ,dmz.WithdrawsInLocalValue
	  ,dmz.NetInLocalValue
	  ,dmz.AvgRateWithdraws
	  ,dmz.AvgRateDeposits 
	  ,dmz.RateStartDay
	  ,dmz.RateEndDay
	  ,dmz.DailyDepositsZero AS DailyDepositsPnL$
	  ,dmz.DailyWithdrawsZero AS DailyWithdrawsPnL$
	  ,dmz.DailyNetZero AS DailyActivityPnL$
	  ,dmz.Net_Rolling_Zero AS RollingActivityPnL$
	  ,Sum(dmz.Net) Over (PARTITION BY dmz.CurrencyID Order by dmz.Date) As AggergatedExposureInUSD_Net --Remove the Minus Net of today
	  ,Sum(dmz.NetInLocalValue) Over (PARTITION BY dmz.CurrencyID Order by dmz.Date) As AggergatedExposureInLocal_Net --Remove the Minus Net of today
	  ,(Sum(dmz.NetInLocalValue) Over (PARTITION BY dmz.CurrencyID Order by dmz.Date)-dmz.NetInLocalValue)*(dmz.RateEndDay- LAG(dmz.RateEndDay) OVER(PARTITION BY dmz.CurrencyID ORDER BY dmz.Date)) AS AggergatedExposure_PnL$
	  ,LAG(dmz.RateEndDay) OVER(PARTITION BY dmz.CurrencyID ORDER BY dmz.Date) AS RateEndDayBefore
	  ,dmz.Net_Rolling_Zero + (Sum(dmz.NetInLocalValue) Over (PARTITION BY dmz.CurrencyID Order by dmz.Date)-dmz.NetInLocalValue)*(dmz.RateEndDay- LAG(dmz.RateEndDay) OVER(PARTITION BY dmz.CurrencyID ORDER BY dmz.Date)) AS Rolling_PnL$ --Remove the Minus Net of today
FROM Dealing_dbo.Dealing_MIMO_Zero dmz