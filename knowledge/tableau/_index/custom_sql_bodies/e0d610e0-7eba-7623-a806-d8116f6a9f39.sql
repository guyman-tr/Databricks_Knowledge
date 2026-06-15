SELECT dsc.[StartDate],
  dsc.[EndDate],
  dsc.[DateRange],
  dsc.[InstrumentID],
  MAX(dsc.[ThresholdID]) ThresholdID,
  dsc.[InactivityTimeoutDayChanged],
  dsc.[InactivityTimeoutLastWeek],
  dsc.[InactivityTimeoutThisWeek],
  dsc.[RateVolatilityPercentageDayChanged],
  dsc.[RateVolatilityPercentageLastWeek],
  dsc.[RateVolatilityPercentageThisWeek],
  dsc.[RateVolatilityPipDayChanged],
  dsc.[RateVolatilityPipLastWeek],
  dsc.[RateVolatilityPipThisWeek]
FROM [dbo].[Dealing_SettingsChanged_RateVolatilityAndTimeout_Weekly] dsc
GROUP BY dsc.[StartDate],
  dsc.[EndDate],
  dsc.[DateRange],
  dsc.[InstrumentID],
  dsc.[InactivityTimeoutDayChanged],
  dsc.[InactivityTimeoutLastWeek],
  dsc.[InactivityTimeoutThisWeek],
  dsc.[RateVolatilityPercentageDayChanged],
  dsc.[RateVolatilityPercentageLastWeek],
  dsc.[RateVolatilityPercentageThisWeek],
  dsc.[RateVolatilityPipDayChanged],
  dsc.[RateVolatilityPipLastWeek],
  dsc.[RateVolatilityPipThisWeek]