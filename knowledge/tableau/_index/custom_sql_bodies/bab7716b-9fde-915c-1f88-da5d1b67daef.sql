SELECT *
FROM
(SELECT a.*,
rank() OVER (PARTITION BY a.StartDate, a.EndDate, a.DateRange, a.InstrumentID, a.InactivityTimeoutLastWeek, a.InactivityTimeoutThisWeek
ORDER BY a.InactivityTimeoutDayChanged DESC) AS [Rank1],
rank() OVER (PARTITION BY a.StartDate, a.EndDate, a.DateRange, a.InstrumentID, a.RateVolatilityPercentageLastWeek, a.RateVolatilityPercentageThisWeek 
ORDER BY a.RateVolatilityPercentageDayChanged DESC) AS [Rank2]
FROM
(SELECT ISNULL(dscrvatw.StartDate, dscslacw.StartDate) StartDate
	  ,ISNULL(dscrvatw.EndDate, dscslacw.EndDate) EndDate
	  ,ISNULL(dscrvatw.DateRange, dscslacw.DateRange) DateRange
	  ,ISNULL(dscrvatw.InstrumentID, dscslacw.InstrumentID) InstrumentID
	  ,di.InstrumentDisplayName
	  ,MAX(dscrvatw.ThresholdID) ThresholdID
	  ,dscrvatw.InactivityTimeoutLastWeek
	  ,dscrvatw.InactivityTimeoutThisWeek
	  ,dscrvatw.InactivityTimeoutDayChanged
	  ,dscrvatw.RateVolatilityPipLastWeek
	  ,dscrvatw.RateVolatilityPipThisWeek
	  ,dscrvatw.RateVolatilityPipDayChanged
	  ,dscrvatw.RateVolatilityPercentageLastWeek
	  ,dscrvatw.RateVolatilityPercentageThisWeek
	  ,dscrvatw.RateVolatilityPercentageDayChanged	  
	  ,dscslacw.CircuitBreakerTriggerThresholdUSDLastWeek
	  ,dscslacw.CircuitBreakerTriggerThresholdUSDThisWeek
	  ,dscslacw.CircuitBreakerDayChanged
	  ,dscslacw.SpreadLockThresholdPercentageLastWeek
	  ,dscslacw.SpreadLockThresholdPercentageThisWeek
	  ,dscslacw.SpreadLockDayChanged
FROM Dealing.dbo.Dealing_SettingsChanged_RateVolatilityAndTimeout_Weekly dscrvatw 
FULL OUTER JOIN Dealing.dbo.Dealing_SettingsChanged_SpreadLocksAndCB_Weekly dscslacw
ON dscrvatw.StartDate = dscslacw.StartDate AND dscrvatw.InstrumentID = dscslacw.InstrumentID
JOIN DWH..Dim_Instrument di
ON di.InstrumentID= isnull(dscrvatw.InstrumentID, dscslacw.InstrumentID)
GROUP BY ISNULL(dscrvatw.StartDate, dscslacw.StartDate)
	  ,ISNULL(dscrvatw.EndDate, dscslacw.EndDate)
	  ,ISNULL(dscrvatw.DateRange, dscslacw.DateRange)
	  ,ISNULL(dscrvatw.InstrumentID, dscslacw.InstrumentID)
	  ,di.InstrumentDisplayName
	  ,dscrvatw.InactivityTimeoutLastWeek
	  ,dscrvatw.InactivityTimeoutThisWeek
	  ,dscrvatw.InactivityTimeoutDayChanged
	  ,dscrvatw.RateVolatilityPipLastWeek
	  ,dscrvatw.RateVolatilityPipThisWeek
	  ,dscrvatw.RateVolatilityPipDayChanged
	  ,dscrvatw.RateVolatilityPercentageLastWeek
	  ,dscrvatw.RateVolatilityPercentageThisWeek
	  ,dscrvatw.RateVolatilityPercentageDayChanged	  
	  ,dscslacw.CircuitBreakerTriggerThresholdUSDLastWeek
	  ,dscslacw.CircuitBreakerTriggerThresholdUSDThisWeek
	  ,dscslacw.CircuitBreakerDayChanged
	  ,dscslacw.SpreadLockThresholdPercentageLastWeek
	  ,dscslacw.SpreadLockThresholdPercentageThisWeek
	  ,dscslacw.SpreadLockDayChanged) a ) b
WHERE b.Rank1= 1 AND b.Rank2= 1