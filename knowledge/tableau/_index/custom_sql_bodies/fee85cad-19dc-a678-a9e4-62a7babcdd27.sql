SELECT `bi_output_dealing_bestexecution_report`.`ActionTypeReason` AS `ActionTypeReason`,
  `bi_output_dealing_bestexecution_report`.`ActionType` AS `ActionType`,
  `bi_output_dealing_bestexecution_report`.`AmountInUnitsDecimal` AS `AmountInUnitsDecimal`,
  --`bi_output_dealing_bestexecution_report`.`Ask` AS `Ask`,
  --`bi_output_dealing_bestexecution_report`.`Bid` AS `Bid`,
  `bi_output_dealing_bestexecution_report`.`CID` AS `CID`,
  --`bi_output_dealing_bestexecution_report`.`ClientToDbLatency` AS `ClientToDbLatency`,
  `bi_output_dealing_bestexecution_report`.`ClientToExecutionLatency` AS `ClientToExecutionLatency`,
  `bi_output_dealing_bestexecution_report`.`ClientToRoutedLatency` AS `ClientToRoutedLatency`,
  --`bi_output_dealing_bestexecution_report`.`ClientViewRate` AS `ClientViewRate`,
  `bi_output_dealing_bestexecution_report`.`Club` AS `Club`,
  `bi_output_dealing_bestexecution_report`.`ConversionRate` AS `ConversionRate`,
  `bi_output_dealing_bestexecution_report`.`Date` AS `Date`,
  --`bi_output_dealing_bestexecution_report`.`ExecutionID` AS `ExecutionID`,
  `bi_output_dealing_bestexecution_report`.`ExecutionTime` AS `ExecutionTime`,
  `bi_output_dealing_bestexecution_report`.`ForexRate` AS `ForexRate`,
  `bi_output_dealing_bestexecution_report`.`GCID` AS `GCID`,
  `bi_output_dealing_bestexecution_report`.`HedgeServerID` AS `HedgeServerID`,
  `bi_output_dealing_bestexecution_report`.`HedgingType` AS `HedgingType`,
  `bi_output_dealing_bestexecution_report`.`History_Price_Rate` AS `History_Price_Rate`,
  `bi_output_dealing_bestexecution_report`.`InstrumentDisplayName` AS `InstrumentDisplayName`,
  `bi_output_dealing_bestexecution_report`.`InstrumentID` AS `InstrumentID`,
  --`bi_output_dealing_bestexecution_report`.`InstrumentTypeID` AS `InstrumentTypeID`,
  `bi_output_dealing_bestexecution_report`.`InstrumentType` AS `InstrumentType`,
  `bi_output_dealing_bestexecution_report`.`IsBuy` AS `IsBuy`,
  `bi_output_dealing_bestexecution_report`.`IsDLTUser` AS `IsDLTUser`,
  `bi_output_dealing_bestexecution_report`.`IsOpen` AS `IsOpen`,
  `bi_output_dealing_bestexecution_report`.`IsSettled` AS `IsSettled`,
  `bi_output_dealing_bestexecution_report`.`IsTriggeredPosition` AS `IsTriggeredPosition`,
  --`bi_output_dealing_bestexecution_report`.`LimitRate` AS `LimitRate`,
  --`bi_output_dealing_bestexecution_report`.`LiquidityAccountID` AS `LiquidityAccountID`,
  --`bi_output_dealing_bestexecution_report`.`MarketReceivedTime` AS `MarketReceivedTime`,
  `bi_output_dealing_bestexecution_report`.`Markup` AS `Markup`,
  `bi_output_dealing_bestexecution_report`.`Occurred` AS `Occurred`,
  --`bi_output_dealing_bestexecution_report`.`OpenTimeUTC` AS `OpenTimeUTC`,
  --`bi_output_dealing_bestexecution_report`.`OrderID` AS `OrderID`,
  --`bi_output_dealing_bestexecution_report`.`PnLVersion` AS `PnLVersion`,
  `bi_output_dealing_bestexecution_report`.`PositionID` AS `PositionID`,
  --`bi_output_dealing_bestexecution_report`.`PriceExistsFlag` AS `PriceExistsFlag`,
  `bi_output_dealing_bestexecution_report`.`Regulation` AS `Regulation`,
  `bi_output_dealing_bestexecution_report`.`RequestOccurred` AS `RequestOccurred`,
  --`bi_output_dealing_bestexecution_report`.`RequestTime` AS `RequestTime`,
  `bi_output_dealing_bestexecution_report`.`RoutedTime` AS `RoutedTime`,
  `bi_output_dealing_bestexecution_report`.`SlippageInDollar` AS `SlippageInDollar`,
  --`bi_output_dealing_bestexecution_report`.`StopRate` AS `StopRate`,
  `bi_output_dealing_bestexecution_report`.`Threshold_BP` AS `Threshold_BP`,
  `bi_output_dealing_bestexecution_report`.`TradingToExecutionLatency` AS `TradingToExecutionLatency`,
  --`bi_output_dealing_bestexecution_report`.`UpdateDate` AS `UpdateDate`,
  `bi_output_dealing_bestexecution_report`.`Volatility_Bucket` AS `Volatility_Bucket`,
  --`bi_output_dealing_bestexecution_report`.`Volume` AS `Volume`,
  `bi_output_dealing_bestexecution_report`.`WithinFirst5Minutes_EU` AS `WithinFirst5Minutes_EU`,
  `bi_output_dealing_bestexecution_report`.`WithinFirst5Minutes_MarketHours` AS `WithinFirst5Minutes_MarketHours`,
  `bi_output_dealing_bestexecution_report`.`WithinFirst5Minutes_Nasdaq` AS `WithinFirst5Minutes_Nasdaq`
  --`bi_output_dealing_bestexecution_report`.`WithinFirst7Minutes_MarketHours` AS `WithinFirst7Minutes_MarketHours`
FROM `main`.`dealing`.`bi_output_dealing_bestexecution_report` `bi_output_dealing_bestexecution_report`
where bi_output_dealing_bestexecution_report.Date >= dateadd(year, -1, current_date())