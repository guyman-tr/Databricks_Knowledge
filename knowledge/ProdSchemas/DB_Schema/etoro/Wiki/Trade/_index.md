# Trade Schema - Documentation Index

| Metric | Value |
|--------|-------|
| **Database** | etoro |
| **Schema** | Trade |
| **Total Objects** | 1,423 |
| **Tables** | 167 |
| **Views** | 117 |
| **Functions** | 66 |
| **Stored Procedures** | 924 |
| **Synonyms** | 23 |
| **User Defined Types** | 126 |
| **Documented** | 1422 (99.9%) |
| **Last Updated** | 2026-03-18 |

## Next Batch (Batch 54) - 1 object

Planned: 2026-03-18

| # | Object | Type | Level | Dependencies |
|---|--------|------|-------|--------------|
| 1 | Trade.GetAccountOrdersForLiquidation | Stored Procedure | 1 | Trade.OrderForClose [done], Trade.Orders [done], Trade.OrderForOpen [done] |

All within-batch dependencies are satisfied.

## Tables (167)

| Object | Quality | Status |
|--------|---------|--------|
| [Trade.AccountLiquidationSaga](Tables/Trade.AccountLiquidationSaga.md) | 8.8 | Done (Batch 3) |
| [Trade.ActiveFeatureThreshold](Tables/Trade.ActiveFeatureThreshold.md) | 8.1 | Done (Batch 2) |
| [Trade.AdminPositionLog](Tables/Trade.AdminPositionLog.md) | 8.5 | Done (Batch 3) |
| [Trade.AdminPositionLogOLD](Tables/Trade.AdminPositionLogOLD.md) | 7.8 | Done (Batch 3) |
| [Trade.BSLBlackList](Tables/Trade.BSLBlackList.md) | 8.2 | Done (Batch 3) |
| [Trade.BSLQueue](Tables/Trade.BSLQueue.md) | 8.6 | Done (Batch 3) |
| [Trade.BSLUsersWhiteList](Tables/Trade.BSLUsersWhiteList.md) | 8.8 | Done (Batch 3) |
| [Trade.BulkOperationsAllowedCids](Tables/Trade.BulkOperationsAllowedCids.md) | 7.5 | Done (Batch 2) |
| [Trade.BulkOperationsAllowedCidsGroups](Tables/Trade.BulkOperationsAllowedCidsGroups.md) | 7.8 | Done (Batch 1) |
| [Trade.CandleGroupToIntervals](Tables/Trade.CandleGroupToIntervals.md) | 8.7 | Done (Batch 1) |
| [Trade.CandleIntervalGroups](Tables/Trade.CandleIntervalGroups.md) | 8.1 | Done (Batch 1) |
| [Trade.CashingOperationMonitor](Tables/Trade.CashingOperationMonitor.md) | 8.5 | Done (Batch 3, #7) |
| [Trade.CashoutRange](Tables/Trade.CashoutRange.md) | 9.0 | Done (Batch 17) |
| [Trade.CashPaymentStatus](Tables/Trade.CashPaymentStatus.md) | 8.2 | Done (Batch 4) |
| [Trade.CIDsInLiquidation](Tables/Trade.CIDsInLiquidation.md) | 8.5 | Done (Batch 4) |
| [Trade.CloseExecutionPlan](Tables/Trade.CloseExecutionPlan.md) | 8.7 | Done (Batch 3, #9) |
| [Trade.CopyTradeSettlementRestrictions](Tables/Trade.CopyTradeSettlementRestrictions.md) | 8.2 | Done (Batch 3, #10) |
| [Trade.CorporateInstrumentActions](Tables/Trade.CorporateInstrumentActions.md) | 7.8 | Done (Batch 2) |
| [Trade.CountryCopySettledResrictionsByInstrumentType](Tables/Trade.CountryCopySettledResrictionsByInstrumentType.md) | 7.2 | Done (Batch 3) |
| [Trade.CurrencyPrice](Tables/Trade.CurrencyPrice.md) | 8.4 | Done (Batch 2) |
| [Trade.CurrencyPrice_20210321](Tables/Trade.CurrencyPrice_20210321.md) | 7.2 | Done (Batch 3) |
| [Trade.CurrencyPrice_SnapShot](Tables/Trade.CurrencyPrice_SnapShot.md) | 7.8 | Done (Batch 3) |
| [Trade.CurrencyPriceFeedDifferences](Tables/Trade.CurrencyPriceFeedDifferences.md) | 8.0 | Done (Batch 3) |
| [Trade.CurrencyPriceSecondary](Tables/Trade.CurrencyPriceSecondary.md) | 8.0 | Done (Batch 3) |
| [Trade.DebugSplitwithError](Tables/Trade.DebugSplitwithError.md) | 7.5 | Done (Batch 3) |
| [Trade.Del_DemoCopiedCIDs](Tables/Trade.Del_DemoCopiedCIDs.md) | 7.0 | Done (Batch 3) |
| [Trade.Del_DemoCopiedOrders](Tables/Trade.Del_DemoCopiedOrders.md) | 7.0 | Done (Batch 3) |
| [Trade.Del_DemoCopiedPositions](Tables/Trade.Del_DemoCopiedPositions.md) | 6.5 | Done (Batch 3) |
| [Trade.DelayedOrderForClose](Tables/Trade.DelayedOrderForClose.md) | 8.3 | Done (Batch 3) |
| [Trade.DelayedOrderForOpen](Tables/Trade.DelayedOrderForOpen.md) | 8.0 | Done (Batch 3) |
| [Trade.DeltaDiff](Tables/Trade.DeltaDiff.md) | 7.8 | Done (Batch 3) |
| [Trade.DemoTreeToSplitFromReal](Tables/Trade.DemoTreeToSplitFromReal.md) | 8.2 | Done (Batch 3) |
| [Trade.DividendEndedWithError](Tables/Trade.DividendEndedWithError.md) | 8.2 | Done (Batch 3) |
| [Trade.ExchangeInstrumentFeeDefinition](Tables/Trade.ExchangeInstrumentFeeDefinition.md) | 9.0 | Done (Batch 3) |
| [Trade.ExcludeFeeByFundID](Tables/Trade.ExcludeFeeByFundID.md) | 7.8 | Done (Batch 5) |
| [Trade.ExecutedCloseOrders](Tables/Trade.ExecutedCloseOrders.md) | 7.8 | Done (Batch 4) |
| [Trade.ExecutedOpenOrders](Tables/Trade.ExecutedOpenOrders.md) | 7.5 | Done (Batch 4) |
| [Trade.ExecutionPlanChangeLog](Tables/Trade.ExecutionPlanChangeLog.md) | 7.5 | Done (Batch 4) |
| [Trade.ExposureIDs](Tables/Trade.ExposureIDs.md) | 7.2 | Done (Batch 1) |
| [Trade.ExposuresForAllHedgeServers](Tables/Trade.ExposuresForAllHedgeServers.md) | 8.5 | Done (Batch 5) |
| [Trade.ExposuresForAllHedgeServers_Log](Tables/Trade.ExposuresForAllHedgeServers_Log.md) | 8.2 | Done (Batch 5) |
| [Trade.ExposuresForAllHedgeServersLOG](Tables/Trade.ExposuresForAllHedgeServersLOG.md) | 8.3 | Done (Batch 5) |
| [Trade.FeatureThresholdValues](Tables/Trade.FeatureThresholdValues.md) | 8.3 | Done (Batch 2) |
| [Trade.FeeInPercentageConfigurations](Tables/Trade.FeeInPercentageConfigurations.md) | 8.8 | Done (Batch 4) |
| [Trade.FeeNightProcess](Tables/Trade.FeeNightProcess.md) | 8.6 | Done (Batch 4) |
| [Trade.FeeNightProcessJobsLogs](Tables/Trade.FeeNightProcessJobsLogs.md) | 8.0 | Done (Batch 5) |
| [Trade.FixPerLotConfigurations](Tables/Trade.FixPerLotConfigurations.md) | 8.7 | Done (Batch 4) |
| [Trade.Fund](Tables/Trade.Fund.md) | 8.6 | Done (Batch 1) |
| [Trade.FundInterval](Tables/Trade.FundInterval.md) | 8.9 | Done (Batch 1) |
| [Trade.FundIntervalAllocation](Tables/Trade.FundIntervalAllocation.md) | 8.4 | Done (Batch 2) |
| [Trade.FundIntervalAllocation_New](Tables/Trade.FundIntervalAllocation_New.md) | 5.5 | Done (Batch 5) |
| [Trade.FuturesInstrumentRiskSettings](Tables/Trade.FuturesInstrumentRiskSettings.md) | 8.2 | Done (Batch 5) |
| [Trade.FuturesInstrumentsInitialMarginByProviderMapping](Tables/Trade.FuturesInstrumentsInitialMarginByProviderMapping.md) | 8.2 | Done (Batch 5) |
| [Trade.FuturesMetaData](Tables/Trade.FuturesMetaData.md) | 8.0 | Done (Batch 5) |
| [Trade.GetSpreadGroup_New](Tables/Trade.GetSpreadGroup_New.md) | 7.5 | Done (Batch 5) |
| [Trade.GuarenteedSLTP_CIDBlacklist](Tables/Trade.GuarenteedSLTP_CIDBlacklist.md) | 7.0 | Done (Batch 5) |
| [Trade.Hedge](Tables/Trade.Hedge.md) | 7.8 | Done (Batch 2) |
| [Trade.HedgeCloseErrors](Tables/Trade.HedgeCloseErrors.md) | 7.0 | Done (Batch 5) |
| [Trade.HedgeFilter](Tables/Trade.HedgeFilter.md) | 8.3 | Done (Batch 1) |
| [Trade.HedgeRequest](Tables/Trade.HedgeRequest.md) | 8.0 | Done (Batch 2) |
| [Trade.HedgeServer](Tables/Trade.HedgeServer.md) | 7.4 | Done (Batch 1) |
| [Trade.HedgeServerToFilter](Tables/Trade.HedgeServerToFilter.md) | 8.5 | Done (Batch 1) |
| [Trade.IndexDividends](Tables/Trade.IndexDividends.md) | 9.5 | Done (Batch 1) |
| [Trade.IndexDividends_20210509](Tables/Trade.IndexDividends_20210509.md) | 7.0 | Done (Batch 6) |
| [Trade.IndexDividends_20210509_after](Tables/Trade.IndexDividends_20210509_after.md) | 7.0 | Done (Batch 6) |
| [Trade.IndexDividends_DryRun](Tables/Trade.IndexDividends_DryRun.md) | 7.5 | Done (Batch 6) |
| [Trade.InsertedInstrument](Tables/Trade.InsertedInstrument.md) | 8.0 | Done (Batch 6) |
| [Trade.Instrument](Tables/Trade.Instrument.md) | 9.1 | Done (Batch 1) |
| [Trade.Instrument_080121](Tables/Trade.Instrument_080121.md) | 6.5 | Done (Batch 6) |
| [Trade.InstrumentActivitySchedule](Tables/Trade.InstrumentActivitySchedule.md) | 5.6 | Done (Batch 1) |
| [Trade.InstrumentConversion](Tables/Trade.InstrumentConversion.md) | 8.4 | Done (Batch 1) |
| [Trade.InstrumentExludedFromOME](Tables/Trade.InstrumentExludedFromOME.md) | 6.5 | Done (Batch 5) |
| [Trade.InstrumentGroups](Tables/Trade.InstrumentGroups.md) | 8.7 | Done (Batch 17) |
| [Trade.InstrumentImages](Tables/Trade.InstrumentImages.md) | 8.2 | Done (Batch 1) |
| [Trade.InstrumentMetaData](Tables/Trade.InstrumentMetaData.md) | 7.8 | Done (Batch 1) |
| [Trade.InstrumentRateSources](Tables/Trade.InstrumentRateSources.md) | 7.8 | Done (Batch 2) |
| [Trade.InstrumentsExcludedFromHalt](Tables/Trade.InstrumentsExcludedFromHalt.md) | 8.1 | Done (Batch 2) |
| [Trade.InstrumentSplitStatus](Tables/Trade.InstrumentSplitStatus.md) | 7.8 | Done (Batch 5) |
| [Trade.InstrumentSpread](Tables/Trade.InstrumentSpread.md) | 8.9 | Done (Batch 1) |
| [Trade.InstrumentToFeeConfig](Tables/Trade.InstrumentToFeeConfig.md) | 8.5 | Done (Batch 4) |
| [Trade.InstrumentToFeeConfig_Backup](Tables/Trade.InstrumentToFeeConfig_Backup.md) | 8.5 | Done (Batch 6) |
| [Trade.InstrumentToFeeConfigOld](Tables/Trade.InstrumentToFeeConfigOld.md) | 8.0 | Done (Batch 6) |
| [Trade.InstrumentToFeeConfigV2](Tables/Trade.InstrumentToFeeConfigV2.md) | 8.8 | Done (Batch 4) |
| [Trade.InstrumentVolatilityThresholdType](Tables/Trade.InstrumentVolatilityThresholdType.md) | 8.0 | Done (Batch 5) |
| [Trade.InterestDaily_July](Tables/Trade.InterestDaily_July.md) | 7.0 | Done (Batch 6) |
| [Trade.InterestMonthly_July](Tables/Trade.InterestMonthly_July.md) | 7.0 | Done (Batch 6) |
| [Trade.InterestWhitelist](Tables/Trade.InterestWhitelist.md) | 9.0 | Done (Batch 17) |
| [Trade.InternalLeveragesWhiteList](Tables/Trade.InternalLeveragesWhiteList.md) | 8.5 | Done (Batch 17) |
| [Trade.LastWeekPrices](Tables/Trade.LastWeekPrices.md) | 7.5 | Done (Batch 5) |
| [Trade.LeverageRestrictionsByCountry](Tables/Trade.LeverageRestrictionsByCountry.md) | 8.0 | Done (Batch 5) |
| [Trade.LeverageRestrictionsByCustomer](Tables/Trade.LeverageRestrictionsByCustomer.md) | 7.5 | Done (Batch 5) |
| [Trade.LeveragesRestrictionsWhiteList](Tables/Trade.LeveragesRestrictionsWhiteList.md) | 7.2 | Done (Batch 5) |
| [Trade.LiquidityAccounts](Tables/Trade.LiquidityAccounts.md) | 8.2 | Done (Batch 2) |
| [Trade.LiquidityProviderContracts](Tables/Trade.LiquidityProviderContracts.md) | 8.9 | Done (Batch 1) |
| [Trade.LiquidityProviderExchanges](Tables/Trade.LiquidityProviderExchanges.md) | 7.8 | Done (Batch 1) |
| [Trade.LiquidityProviderInstuments](Tables/Trade.LiquidityProviderInstuments.md) | 7.5 | Done (Batch 2) |
| [Trade.LiquidityProviders](Tables/Trade.LiquidityProviders.md) | 8.2 | Done (Batch 1) |
| [Trade.LiquidityProvidersORG](Tables/Trade.LiquidityProvidersORG.md) | 7.0 | Done (Batch 6) |
| [Trade.LiquidityProviderType](Tables/Trade.LiquidityProviderType.md) | 8.7 | Done (Batch 1) |
| [Trade.ManageBSL](Tables/Trade.ManageBSL.md) | 8.5 | Done (Batch 5) |
| [Trade.ManageBSL_OLD](Tables/Trade.ManageBSL_OLD.md) | 6.5 | Done (Batch 6) |
| [Trade.ManageBSL_OLD2](Tables/Trade.ManageBSL_OLD2.md) | 6.5 | Done (Batch 6) |
| [Trade.MaxLeverageByInstrumentForExposure](Tables/Trade.MaxLeverageByInstrumentForExposure.md) | 8.2 | Done (Batch 5) |
| [Trade.Mirror](Tables/Trade.Mirror.md) | 8.5 | Done (Batch 2) |
| [Trade.MirrorCloseSaga](Tables/Trade.MirrorCloseSaga.md) | 8.0 | Done (Batch 4) |
| [Trade.MirrorStopLoss_Del](Tables/Trade.MirrorStopLoss_Del.md) | 6.5 | Done (Batch 6) |
| [Trade.MirrorToReopen](Tables/Trade.MirrorToReopen.md) | 8.2 | Done (Batch 4) |
| [Trade.MostPopularInstruments](Tables/Trade.MostPopularInstruments.md) | 7.8 | Done (Batch 5) |
| [Trade.NonLiquidatablePositionRules](Tables/Trade.NonLiquidatablePositionRules.md) | 7.5 | Done (Batch 5) |
| [Trade.OMEPoolConfig](Tables/Trade.OMEPoolConfig.md) | 8.5 | Done (Batch 6) |
| [Trade.OpenExecutionPlan](Tables/Trade.OpenExecutionPlan.md) | 8.2 | Done (Batch 4) |
| [Trade.OperationTypeForBlockingToAtomic](Tables/Trade.OperationTypeForBlockingToAtomic.md) | 8.5 | Done (Batch 2) |
| [Trade.OrderExecutionData](Tables/Trade.OrderExecutionData.md) | 7.9 | Done (Batch 4) |
| [Trade.OrderForClose](Tables/Trade.OrderForClose.md) | 8.5 | Done (Batch 4) |
| [Trade.OrderForExecutionChangeLog](Tables/Trade.OrderForExecutionChangeLog.md) | 7.5 | Done (Batch 4) |
| [Trade.OrderForOpen](Tables/Trade.OrderForOpen.md) | 8.5 | Done (Batch 4) |
| [Trade.Orders](Tables/Trade.Orders.md) | 8.5 | Done (Batch 2) |
| [Trade.OrdersEntryTbl](Tables/Trade.OrdersEntryTbl.md) | 8.3 | Done (Batch 4) |
| [Trade.OrdersExitTbl](Tables/Trade.OrdersExitTbl.md) | 8.2 | Done (Batch 4) |
| [Trade.PositionAdjustmentAudit](Tables/Trade.PositionAdjustmentAudit.md) | 7.5 | Done (Batch 6) |
| [Trade.PositionAirdropLogOldD_DoNotdelete](Tables/Trade.PositionAirdropLogOldD_DoNotdelete.md) | 7.0 | Done (Batch 6) |
| [Trade.PositionChangeOld](Tables/Trade.PositionChangeOld.md) | 7.0 | Done (Batch 6) |
| [Trade.PositionEndedWithTOError](Tables/Trade.PositionEndedWithTOError.md) | 7.0 | Done (Batch 6) |
| [Trade.PositionOpenByFork](Tables/Trade.PositionOpenByFork.md) | 8.0 | Done (Batch 4) |
| [Trade.PositionOpenInDLT](Tables/Trade.PositionOpenInDLT.md) | 7.0 | Done (Batch 6) |
| [Trade.PositionRequest](Tables/Trade.PositionRequest.md) | 7.0 | Done (Batch 4) |
| [Trade.PositionsHedgeServerChangeLog](Tables/Trade.PositionsHedgeServerChangeLog.md) | 9.0 | Done (Batch 17) |
| [Trade.PositionsHedgeServerChangeLog_INT_2021Junk](Tables/Trade.PositionsHedgeServerChangeLog_INT_2021Junk.md) | 6.5 | Done (Batch 6) |
| [Trade.PositionsHedgeServerChangeSummaryLog](Tables/Trade.PositionsHedgeServerChangeSummaryLog.md) | 8.4 | Done (Batch 1) |
| [Trade.PositionsProcessedForIndexDividnds](Tables/Trade.PositionsProcessedForIndexDividnds.md) | 8.5 | Done (Batch 6) |
| [Trade.PositionsProcessedForIndexDividnds_OLD](Tables/Trade.PositionsProcessedForIndexDividnds_OLD.md) | 7.0 | Done (Batch 6) |
| [Trade.PositionTbl](Tables/Trade.PositionTbl.md) | 8.6 | Done (Batch 2, #24) |
| [Trade.PositionTblRep_Log](Tables/Trade.PositionTblRep_Log.md) | 6.5 | Done (Batch 6) |
| [Trade.PositionToReopen](Tables/Trade.PositionToReopen.md) | 8.5 | Done (Batch 4) |
| [Trade.PositionToReopen_Timeouts](Tables/Trade.PositionToReopen_Timeouts.md) | 7.0 | Done (Batch 6) |
| [Trade.PositionToSplitByJob](Tables/Trade.PositionToSplitByJob.md) | 8.8 | Done (Batch 4) |
| [Trade.PositionTreeInfo](Tables/Trade.PositionTreeInfo.md) | 8.5 | Done (Batch 2, #25) |
| [Trade.PositionTreeInfoRep_Log](Tables/Trade.PositionTreeInfoRep_Log.md) | 6.5 | Done (Batch 6) |
| [Trade.PostDetachOperation](Tables/Trade.PostDetachOperation.md) | 8.5 | Done (Batch 4) |
| [Trade.PostDetachOperation_Old](Tables/Trade.PostDetachOperation_Old.md) | 8.0 | Done (Batch 7) |
| [Trade.PostPositionOpenForSdrt](Tables/Trade.PostPositionOpenForSdrt.md) | 8.2 | Done (Batch 7) |
| [Trade.PostPositionOpenMot](Tables/Trade.PostPositionOpenMot.md) | 8.0 | Done (Batch 7) |
| [Trade.Provider](Tables/Trade.Provider.md) | 8.8 | Done (Batch 1) |
| [Trade.ProviderInstrumentToLeverage](Tables/Trade.ProviderInstrumentToLeverage.md) | 8.2 | Done (Batch 2) |
| [Trade.ProviderInstrumentToLotCount](Tables/Trade.ProviderInstrumentToLotCount.md) | 8.1 | Done (Batch 2) |
| [Trade.ProviderMarginMarkupByInstrument](Tables/Trade.ProviderMarginMarkupByInstrument.md) | 8.5 | Done (Batch 7) |
| [Trade.ProviderToInstrument](Tables/Trade.ProviderToInstrument.md) | 8.2 | Done (Batch 1) |
| [Trade.RebalanceRequests](Tables/Trade.RebalanceRequests.md) | 8.2 | Done (Batch 7, #13) |
| [Trade.ReopenOperation](Tables/Trade.ReopenOperation.md) | 8.5 | Done (Batch 4) |
| [Trade.RolloverFeeAlertThreshold](Tables/Trade.RolloverFeeAlertThreshold.md) | 8.4 | Done (Batch 7, #14) |
| [Trade.SbrEventsQueueTable](Tables/Trade.SbrEventsQueueTable.md) | 8.0 | Done (Batch 7, #15) |
| [Trade.SevisionCriticalInstruments](Tables/Trade.SevisionCriticalInstruments.md) | 8.3 | Done (Batch 7, #16) |
| [Trade.SplitRealInDemoMap](Tables/Trade.SplitRealInDemoMap.md) | 8.0 | Done (Batch 7) |
| [Trade.Spread](Tables/Trade.Spread.md) | 8.2 | Done (Batch 2) |
| [Trade.SpreadGroup](Tables/Trade.SpreadGroup.md) | 8.7 | Done (Batch 1) |
| [Trade.SpreadToGroup](Tables/Trade.SpreadToGroup.md) | 8.5 | Done (Batch 2) |
| [Trade.SyncConfiguration](Tables/Trade.SyncConfiguration.md) | 7.8 | Done (Batch 7) |
| [Trade.SynchOrdersEntry](Tables/Trade.SynchOrdersEntry.md) | 7.5 | Done (Batch 7) |
| [Trade.SyncTSL](Tables/Trade.SyncTSL.md) | 8.5 | Done (Batch 7) |
| [Trade.TerminalIDToCorporateAction](Tables/Trade.TerminalIDToCorporateAction.md) | 8.8 | Done (Batch 7) |
| [Trade.TradeOrphanedPositionsCloseByJob](Tables/Trade.TradeOrphanedPositionsCloseByJob.md) | 8.0 | Done (Batch 7) |
| [Trade.TradonomiContracts](Tables/Trade.TradonomiContracts.md) | 8.5 | Done (Batch 1) |
| [Trade.TradonomiContractsDailySchedule](Tables/Trade.TradonomiContractsDailySchedule.md) | 8.0 | Done (Batch 2) |
| [Trade.TradonomiToLiquidityProviderContracts](Tables/Trade.TradonomiToLiquidityProviderContracts.md) | 8.4 | Done (Batch 2) |
| [Trade.UsAllowedInstruments](Tables/Trade.UsAllowedInstruments.md) | 8.5 | Done (Batch 7) |
| [Trade.UsUnitsToAddByPositionToSplitByJob](Tables/Trade.UsUnitsToAddByPositionToSplitByJob.md) | 8.5 | Done (Batch 17) |
| [Trade.VolatilityHighImpactInstruments](Tables/Trade.VolatilityHighImpactInstruments.md) | 8.2 | Done (Batch 7) |

## Views (117)

| Object | Quality | Status |
|--------|---------|--------|
| [Trade.AnalyseSplitwithError](Views/Trade.AnalyseSplitwithError.md) | 7.8 | Done (Batch 11, #1) |
| [Trade.BslView](Views/Trade.BslView.md) | 8.7 | Done (Batch 17) |
| [Trade.CheckIsFund](Views/Trade.CheckIsFund.md) | 7.5 | Done (Batch 11, #2) |
| [Trade.ClosePositionsGetRecoveryItemsDemo](Views/Trade.ClosePositionsGetRecoveryItemsDemo.md) | 8.2 | Done (Batch 14, #2) |
| [Trade.CurrencyPriceSafty](Views/Trade.CurrencyPriceSafty.md) | 7.8 | Done (Batch 11, #3) |
| [Trade.ExposurePerInstrument](Views/Trade.ExposurePerInstrument.md) | 7.8 | Done (Batch 11, #4) |
| [Trade.GetActiveFeatureThresholds](Views/Trade.GetActiveFeatureThresholds.md) | 8.0 | Done (Batch 11, #5) |
| [Trade.GetActiveIndexDividends](Views/Trade.GetActiveIndexDividends.md) | 8.8 | Done (Batch 11, #6) |
| [Trade.GetAllOpenOrders](Views/Trade.GetAllOpenOrders.md) | 8.6 | Done (Batch 11, #7) |
| [Trade.GetCrossesMajorInstruments](Views/Trade.GetCrossesMajorInstruments.md) | 7.8 | Done (Batch 12) |
| [Trade.GetCurrencyConversionsView](Views/Trade.GetCurrencyConversionsView.md) | 8.7 | Done (Batch 11, #8) |
| [Trade.GetCurrencyConversionsView_test](Views/Trade.GetCurrencyConversionsView_test.md) | 8.2 | Done (Batch 11, #9) |
| [Trade.GetCurrentPrice](Views/Trade.GetCurrentPrice.md) | 8.7 | Done (Batch 11, #10) |
| [Trade.GetCurrentPriceAndConversionRate](Views/Trade.GetCurrentPriceAndConversionRate.md) | 8.5 | Done (Batch 11, #11) |
| [Trade.GetDemoOpenPositionsForMMRecovery](Views/Trade.GetDemoOpenPositionsForMMRecovery.md) | 8.5 | Done (Batch 14, #3) |
| [Trade.GetDictionaryStocksIndustry](Views/Trade.GetDictionaryStocksIndustry.md) | 8.2 | Done (Batch 11, #12) |
| [Trade.GetExposuresForAllHedgeServers](Views/Trade.GetExposuresForAllHedgeServers.md) | 8.8 | Done (Batch 14, #4) |
| [Trade.GetGuruOpenPositions](Views/Trade.GetGuruOpenPositions.md) | 8.5 | Done (Batch 14, #5) |
| [Trade.GetHedgeExposure](Views/Trade.GetHedgeExposure.md) | 8.2 | Done (Batch 14, #6) |
| [Trade.GetHedgeExposureDetailed](Views/Trade.GetHedgeExposureDetailed.md) | 8.0 | Done (Batch 14, #7) |
| [Trade.GetHedgeExposureDetailedWithActiveParent](Views/Trade.GetHedgeExposureDetailedWithActiveParent.md) | 8.0 | Done (Batch 14, #8) |
| [Trade.GetHedgeExposureWithActiveParent](Views/Trade.GetHedgeExposureWithActiveParent.md) | 8.0 | Done (Batch 14, #9) |
| [Trade.GetHedgeRequest](Views/Trade.GetHedgeRequest.md) | 8.5 | Done (Batch 11, #13) |
| [Trade.GetHedgeWithoutPosition](Views/Trade.GetHedgeWithoutPosition.md) | 8.5 | Done (Batch 14, #10) |
| [Trade.GetInstrument](Views/Trade.GetInstrument.md) | 8.5 | Done (Batch 11, #14) |
| [Trade.GetInstrumentConfiguration](Views/Trade.GetInstrumentConfiguration.md) | 8.2 | Done (Batch 11, #15) |
| [Trade.GetInstrumentContracts](Views/Trade.GetInstrumentContracts.md) | 8.2 | Done (Batch 11, #16) |
| [Trade.GetInstrumentConversions](Views/Trade.GetInstrumentConversions.md) | 8.5 | Done (Batch 12, #2) |
| [Trade.GetInstrumentDataDealing](Views/Trade.GetInstrumentDataDealing.md) | 8.2 | Done (Batch 11, #17) |
| [Trade.GetInstrumentDeal](Views/Trade.GetInstrumentDeal.md) | 8.1 | Done (Batch 11, #18) |
| [Trade.GetInstrumentMappingToUSDInstrument](Views/Trade.GetInstrumentMappingToUSDInstrument.md) | 8.2 | Done (Batch 12, #4) |
| [Trade.GetInstrumentMaxLeverage](Views/Trade.GetInstrumentMaxLeverage.md) | 8.6 | Done (Batch 12, #3) |
| [Trade.GetInstrumentMetaData](Views/Trade.GetInstrumentMetaData.md) | 8.5 | Done (Batch 11, #19) |
| [Trade.GetInstrumentMetaDataExtend](Views/Trade.GetInstrumentMetaDataExtend.md) | 8.4 | Done (Batch 11, #20) |
| [Trade.GetInstrumentRateSources](Views/Trade.GetInstrumentRateSources.md) | 8.2 | Done (Batch 12, #5) |
| [Trade.GetInstrumentsBuyNames](Views/Trade.GetInstrumentsBuyNames.md) | 7.5 | Done (Batch 11, #21) |
| [Trade.GetInstrumentTradingData](Views/Trade.GetInstrumentTradingData.md) | 8.4 | Done (Batch 11, #22) |
| [Trade.GetLeverages](Views/Trade.GetLeverages.md) | 8.5 | Done (Batch 11, #23) |
| [Trade.GetLiquidityAccounts](Views/Trade.GetLiquidityAccounts.md) | 8.6 | Done (Batch 11, #24) |
| [Trade.GetLiquidityAccountsDetails](Views/Trade.GetLiquidityAccountsDetails.md) | 8.7 | Done (Batch 12, #6) |
| [Trade.GetLiquidityProviderContracts](Views/Trade.GetLiquidityProviderContracts.md) | 8.7 | Done (Batch 11, #25) |
| [Trade.GetLiquidityProviders](Views/Trade.GetLiquidityProviders.md) | 8.2 | Done (Batch 12) |
| [Trade.GetMajorAffectedCrosses](Views/Trade.GetMajorAffectedCrosses.md) | 8.0 | Done (Batch 12) |
| [Trade.GetMoneyConversionsView](Views/Trade.GetMoneyConversionsView.md) | 8.5 | Done (Batch 12) |
| [Trade.GetOpenOrders](Views/Trade.GetOpenOrders.md) | 7.8 | Done (Batch 12) |
| [Trade.GetOpenPositionAsXML](Views/Trade.GetOpenPositionAsXML.md) | 8.5 | Done (Batch 14, #23) |
| [Trade.GetOpenPositionDataForGuro](Views/Trade.GetOpenPositionDataForGuro.md) | 8.2 | Done (Batch 12) |
| [Trade.GetOpenPositionsForMMRecovery](Views/Trade.GetOpenPositionsForMMRecovery.md) | 8.5 | Done (Batch 14, #11) |
| [Trade.GetOrderExitData](Views/Trade.GetOrderExitData.md) | 8.5 | Done (Batch 14, #12) |
| [Trade.GetOrders](Views/Trade.GetOrders.md) | 8.4 | Done (Batch 12) |
| [Trade.GetPosition](Views/Trade.GetPosition.md) | 8.5 | Done (Batch 14, #13) |
| [Trade.GetPositionAsXML](Views/Trade.GetPositionAsXML.md) | 8.5 | Done (Batch 14, #24) |
| [Trade.GetPositionData](Views/Trade.GetPositionData.md) | 8.5 | Done (Batch 13, #1) |
| [Trade.GetPositionData_WithCommissionOnClose](Views/Trade.GetPositionData_WithCommissionOnClose.md) | 7.5 | Done (Batch 13, #2) |
| [Trade.GetPositionData_WithIsComputeForHedge](Views/Trade.GetPositionData_WithIsComputeForHedge.md) | 7.5 | Done (Batch 13, #3) |
| [Trade.GetPositionDataForExternalUse](Views/Trade.GetPositionDataForExternalUse.md) | 9.0 | Done (Batch 17) |
| [Trade.GetPositionDataSlim](Views/Trade.GetPositionDataSlim.md) | 8.5 | Done (Batch 13, #4) |
| [Trade.GetPositionForXML](Views/Trade.GetPositionForXML.md) | 8.8 | Done (Batch 14, #14) |
| [Trade.GetPositionInfo](Views/Trade.GetPositionInfo.md) | 8.7 | Done (Batch 17) |
| [Trade.GetPositionType](Views/Trade.GetPositionType.md) | 7.8 | Done (Batch 12) |
| [Trade.GetPriceConversionInstrumentToUSD](Views/Trade.GetPriceConversionInstrumentToUSD.md) | 8.2 | Done (Batch 13, #5) |
| [Trade.GetProvider](Views/Trade.GetProvider.md) | 8.2 | Done (Batch 12) |
| [Trade.GetProvidersTradonomiContracts](Views/Trade.GetProvidersTradonomiContracts.md) | 7.6 | Done (Batch 12) |
| [Trade.GetProviderToInstrument](Views/Trade.GetProviderToInstrument.md) | 8.8 | Done (Batch 12) |
| [Trade.GetRealClosePositionMMRecovery](Views/Trade.GetRealClosePositionMMRecovery.md) | 8.0 | Done (Batch 14, #15) |
| [Trade.GetRealEditOWMMRecovery](Views/Trade.GetRealEditOWMMRecovery.md) | 8.0 | Done (Batch 14, #16) |
| [Trade.GetRealEditSLMMRecovery](Views/Trade.GetRealEditSLMMRecovery.md) | 8.2 | Done (Batch 14, #17) |
| [Trade.GetRealEditSLMMRecovery_Org](Views/Trade.GetRealEditSLMMRecovery_Org.md) | 7.8 | Done (Batch 14, #18) |
| [Trade.GetRealEditTPMMRecovery](Views/Trade.GetRealEditTPMMRecovery.md) | 7.8 | Done (Batch 14, #19) |
| [Trade.GetRealizedEquity_View](Views/Trade.GetRealizedEquity_View.md) | 7.5 | Done (Batch 12) |
| [Trade.GetRecoveryItemsDemo](Views/Trade.GetRecoveryItemsDemo.md) | 8.5 | Done (Batch 14, #20) |
| [Trade.GetSpreadGroup](Views/Trade.GetSpreadGroup.md) | 8.5 | Done (Batch 12) |
| [Trade.GetSpreadGroupSafty](Views/Trade.GetSpreadGroupSafty.md) | 7.8 | Done (Batch 13, #6) |
| [Trade.GetTotalCash_View](Views/Trade.GetTotalCash_View.md) | 7.5 | Done (Batch 12) |
| [Trade.GetTradonomiContracts](Views/Trade.GetTradonomiContracts.md) | 8.5 | Done (Batch 12) |
| [Trade.GetTradonomiContractsDailySchedule](Views/Trade.GetTradonomiContractsDailySchedule.md) | 8.0 | Done (Batch 12) |
| [Trade.InstrumentAvailableLeverages](Views/Trade.InstrumentAvailableLeverages.md) | 8.5 | Done (Batch 12) |
| [Trade.InstrumentCusip](Views/Trade.InstrumentCusip.md) | 8.5 | Done (Batch 12) |
| [Trade.InstrumentMarketRange](Views/Trade.InstrumentMarketRange.md) | 8.5 | Done (Batch 12) |
| [Trade.InstrumentMaxPositionUnits](Views/Trade.InstrumentMaxPositionUnits.md) | 8.5 | Done (Batch 12) |
| [Trade.InstrumentMaxRateDiffPercentage](Views/Trade.InstrumentMaxRateDiffPercentage.md) | 7.5 | Done (Batch 13, #7) |
| [Trade.InstrumentMaxStopLossPercentage](Views/Trade.InstrumentMaxStopLossPercentage.md) | 7.5 | Done (Batch 13, #8) |
| [Trade.InstrumentMetaData_Daily](Views/Trade.InstrumentMetaData_Daily.md) | 7.5 | Done (Batch 13, #9) |
| [Trade.InstrumentMinPositionAmount](Views/Trade.InstrumentMinPositionAmount.md) | 7.5 | Done (Batch 13, #10) |
| [Trade.InstrumentNWADecreasePercentage](Views/Trade.InstrumentNWADecreasePercentage.md) | 7.5 | Done (Batch 13, #11) |
| [Trade.InstrumentPrecision](Views/Trade.InstrumentPrecision.md) | 7.5 | Done (Batch 13, #12) |
| [Trade.InstrumentSafty](Views/Trade.InstrumentSafty.md) | 7.8 | Done (Batch 13, #13) |
| [Trade.InstrumentsOmeID](Views/Trade.InstrumentsOmeID.md) | 8.2 | Done (Batch 13, #14) |
| [Trade.InstrumentToFeeConfig](Views/Trade.InstrumentToFeeConfig.md) | 8.7 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay](Views/Trade.OpenPositionEndOfDay.md) | 8.7 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay_392025](Views/Trade.OpenPositionEndOfDay_392025.md) | 8.0 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay_before0192025](Views/Trade.OpenPositionEndOfDay_before0192025.md) | 8.0 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay_PartialCloseFix](Views/Trade.OpenPositionEndOfDay_PartialCloseFix.md) | 8.5 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay_Test4Pini](Views/Trade.OpenPositionEndOfDay_Test4Pini.md) | 7.8 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay_Test4Pini_RAN](Views/Trade.OpenPositionEndOfDay_Test4Pini_RAN.md) | 7.8 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDay_TestSplit](Views/Trade.OpenPositionEndOfDay_TestSplit.md) | 7.8 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDaytest](Views/Trade.OpenPositionEndOfDaytest.md) | 8.0 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDayTestElad](Views/Trade.OpenPositionEndOfDayTestElad.md) | 8.0 | Done (Batch 17) |
| [Trade.OpenPositionEndOfDayWith2Pnl](Views/Trade.OpenPositionEndOfDayWith2Pnl.md) | 8.5 | Done (Batch 17) |
| [Trade.OrdersEntry](Views/Trade.OrdersEntry.md) | 7.8 | Done (Batch 13, #15) |
| [Trade.OrdersExit](Views/Trade.OrdersExit.md) | 8.0 | Done (Batch 13, #16) |
| [Trade.PnL](Views/Trade.PnL.md) | 9.2 | Done (Batch 17) |
| [Trade.PosionByRowVersion](Views/Trade.PosionByRowVersion.md) | 7.5 | Done (Batch 14, #25) |
| [Trade.Position](Views/Trade.Position.md) | 8.5 | Done (Batch 13, #17) |
| [Trade.Position_DataFactory](Views/Trade.Position_DataFactory.md) | 7.8 | Done (Batch 13, #18) |
| [Trade.Position_DataFactory_Test](Views/Trade.Position_DataFactory_Test.md) | 7.5 | Done (Batch 17) |
| [Trade.PositionAirdropLog](Views/Trade.PositionAirdropLog.md) | 7.8 | Done (Batch 13, #19) |
| [Trade.PositionChange](Views/Trade.PositionChange.md) | 8.0 | Done (Batch 14, #21) |
| [Trade.PositionForExternalUse](Views/Trade.PositionForExternalUse.md) | 8.5 | Done (Batch 14, #1) |
| [Trade.PositionForExternalUseWithPnL](Views/Trade.PositionForExternalUseWithPnL.md) | 9.0 | Done (Batch 17) |
| [Trade.PositionsHedgeServerChangeLog_DP](Views/Trade.PositionsHedgeServerChangeLog_DP.md) | 7.2 | Done (Batch 13, #20) |
| [Trade.PositionTblOnlyOpen](Views/Trade.PositionTblOnlyOpen.md) | 7.5 | Done (Batch 13, #21) |
| [Trade.ProviderToInstrument_Daily](Views/Trade.ProviderToInstrument_Daily.md) | 7.5 | Done (Batch 13, #22) |
| [Trade.ProviderToInstrumentSafty](Views/Trade.ProviderToInstrumentSafty.md) | 7.8 | Done (Batch 13, #23) |
| [Trade.TradableInstrumentMaxRateDiffPercentage](Views/Trade.TradableInstrumentMaxRateDiffPercentage.md) | 7.8 | Done (Batch 13, #24) |
| [Trade.vExposuresForAllHedgeServers](Views/Trade.vExposuresForAllHedgeServers.md) | 8.0 | Done (Batch 13, #25) |
| [Trade.vGetUsRegulationIds](Views/Trade.vGetUsRegulationIds.md) | 7.0 | Done (Batch 14, #22) |

## Functions (66)

| Object | Quality | Status |
|--------|---------|--------|
| [Trade.Bsl_MultiTEST](Functions/Trade.Bsl_MultiTEST.md) | 8.0 | Done (Batch 18) |
| [Trade.CalcNetProfit](Functions/Trade.CalcNetProfit.md) | 8.2 | Done (Batch 15) |
| [Trade.CalculatePositionOvernightFee](Functions/Trade.CalculatePositionOvernightFee.md) | 8.5 | Done (Batch 15) |
| [Trade.ChangeTreeInfoPerInstrument](Functions/Trade.ChangeTreeInfoPerInstrument.md) | 8.5 | Done (Batch 16) |
| [Trade.ConvertTimeLocalToUTC](Functions/Trade.ConvertTimeLocalToUTC.md) | 8.0 | Done (Batch 15) |
| [Trade.ConvertUtcToLocal](Functions/Trade.ConvertUtcToLocal.md) | 8.0 | Done (Batch 15) |
| [Trade.FnCalculateCurrentPnL](Functions/Trade.FnCalculateCurrentPnL.md) | 9.2 | Done (Batch 15) |
| [Trade.FnCalculatePnL](Functions/Trade.FnCalculatePnL.md) | 8.8 | Done (Batch 15) |
| [Trade.FnCalculatePnLByRates](Functions/Trade.FnCalculatePnLByRates.md) | 9.2 | Done (Batch 15) |
| [Trade.FnCalculatePnLWrapper](Functions/Trade.FnCalculatePnLWrapper.md) | 9.2 | Done (Batch 16) |
| [Trade.FnGetCloseFee](Functions/Trade.FnGetCloseFee.md) | 8.8 | Done (Batch 15) |
| [Trade.FnGetCloseFeeInPercentage](Functions/Trade.FnGetCloseFeeInPercentage.md) | 8.8 | Done (Batch 15) |
| [Trade.FnGetCloseFeeOnOpen](Functions/Trade.FnGetCloseFeeOnOpen.md) | 8.5 | Done (Batch 15) |
| [Trade.FnGetCloseFixPerLot](Functions/Trade.FnGetCloseFixPerLot.md) | 8.8 | Done (Batch 15) |
| [Trade.FnGetConversionInstrument](Functions/Trade.FnGetConversionInstrument.md) | 8.8 | Done (Batch 15) |
| [Trade.FnGetCurrentClosingRate](Functions/Trade.FnGetCurrentClosingRate.md) | 9.0 | Done (Batch 15) |
| [Trade.FnGetCurrentConversionRate](Functions/Trade.FnGetCurrentConversionRate.md) | 9.0 | Done (Batch 15) |
| [Trade.FnIsRealPosition](Functions/Trade.FnIsRealPosition.md) | 9.0 | Done (Batch 15) |
| [Trade.FunDelayedOrdersOvernight](Functions/Trade.FunDelayedOrdersOvernight.md) | 8.6 | Done (Batch 16) |
| [Trade.FunGetAleErrorReportNew](Functions/Trade.FunGetAleErrorReportNew.md) | 8.5 | Done (Batch 16) |
| [Trade.FunGetFirmAggregationHWM](Functions/Trade.FunGetFirmAggregationHWM.md) | 8.5 | Done (Batch 16) |
| [Trade.FunGetInstrumentConfiguration](Functions/Trade.FunGetInstrumentConfiguration.md) | 8.5 | Done (Batch 16) |
| [Trade.FunPositionCloseWithTimeout](Functions/Trade.FunPositionCloseWithTimeout.md) | 8.2 | Done (Batch 16) |
| [Trade.FunPositionEditSLWithTimeout](Functions/Trade.FunPositionEditSLWithTimeout.md) | 7.8 | Done (Batch 16) |
| [Trade.FunPositionOpenWithTimeout](Functions/Trade.FunPositionOpenWithTimeout.md) | 8.2 | Done (Batch 16) |
| [Trade.FunRejectedOrders](Functions/Trade.FunRejectedOrders.md) | 8.0 | Done (Batch 16) |
| [Trade.FunStuckOrders](Functions/Trade.FunStuckOrders.md) | 8.4 | Done (Batch 16) |
| [Trade.FunUnRegisterMirrorMot](Functions/Trade.FunUnRegisterMirrorMot.md) | 8.2 | Done (Batch 16) |
| [Trade.GetAvailableLiquidityProviderContracts](Functions/Trade.GetAvailableLiquidityProviderContracts.md) | 8.5 | Done (Batch 16) |
| [Trade.GetAverageHedgeInitRate](Functions/Trade.GetAverageHedgeInitRate.md) | 8.2 | Done (Batch 16) |
| [Trade.GetAveragePositionInitRate](Functions/Trade.GetAveragePositionInitRate.md) | 8.0 | Done (Batch 16) |
| [Trade.GetBonusUsed](Functions/Trade.GetBonusUsed.md) | 8.2 | Done (Batch 15) |
| [Trade.GetChangePercent](Functions/Trade.GetChangePercent.md) | 8.0 | Done (Batch 15) |
| [Trade.GetClosingPrice](Functions/Trade.GetClosingPrice.md) | 8.0 | Done (Batch 16) |
| [Trade.GetClosingPriceOpenQuery](Functions/Trade.GetClosingPriceOpenQuery.md) | 7.8 | Done (Batch 16) |
| [Trade.GetExchangeIDsByTime](Functions/Trade.GetExchangeIDsByTime.md) | 8.2 | Done (Batch 15) |
| [Trade.GetInstrumentTypeIDsForCFDFee](Functions/Trade.GetInstrumentTypeIDsForCFDFee.md) | 8.0 | Done (Batch 15) |
| [Trade.GetLiguidityProviderContractData](Functions/Trade.GetLiguidityProviderContractData.md) | 8.2 | Done (Batch 16) |
| [Trade.GetLiguidityProviderContractsForTradonomiContract](Functions/Trade.GetLiguidityProviderContractsForTradonomiContract.md) | 8.5 | Done (Batch 16) |
| [Trade.GetLotCountTillTime](Functions/Trade.GetLotCountTillTime.md) | 7.5 | Done (Batch 16) |
| [Trade.GetMarketCloseTimeByExDate](Functions/Trade.GetMarketCloseTimeByExDate.md) | 8.5 | Done (Batch 15) |
| [Trade.GetMarketCloseTimeByExDate_SS](Functions/Trade.GetMarketCloseTimeByExDate_SS.md) | 8.5 | Done (Batch 18) |
| [Trade.GetMarketTimes](Functions/Trade.GetMarketTimes.md) | 8.5 | Done (Batch 15) |
| [Trade.GetMinorConversionRate](Functions/Trade.GetMinorConversionRate.md) | 8.5 | Done (Batch 15) |
| [Trade.GetMinorConversionRate_testinline](Functions/Trade.GetMinorConversionRate_testinline.md) | 8.5 | Done (Batch 18) |
| [Trade.GetMinorConversionRate_testinline1](Functions/Trade.GetMinorConversionRate_testinline1.md) | 8.5 | Done (Batch 18) |
| [Trade.GetMinorConversionRateAsk](Functions/Trade.GetMinorConversionRateAsk.md) | 8.5 | Done (Batch 15) |
| [Trade.GetMirrorValidationRules](Functions/Trade.GetMirrorValidationRules.md) | 7.2 | Done (Batch 16) |
| [Trade.GetOnePip](Functions/Trade.GetOnePip.md) | 8.2 | Done (Batch 15) |
| [Trade.GetPositionInfoFromAnyTable](Functions/Trade.GetPositionInfoFromAnyTable.md) | 7.8 | Done (Batch 16) |
| [Trade.GetTotalCash](Functions/Trade.GetTotalCash.md) | 7.4 | Done (Batch 16) |
| [Trade.GetTotalManualOrdersForOpenAmount](Functions/Trade.GetTotalManualOrdersForOpenAmount.md) | 7.6 | Done (Batch 16) |
| [Trade.IsInstrumentInGroup](Functions/Trade.IsInstrumentInGroup.md) | 7.6 | Done (Batch 16) |
| [Trade.IsUsUser](Functions/Trade.IsUsUser.md) | 9.2 | Done (Batch 17) |
| [Trade.OldAndNewTakeProfitPerInstrumentID](Functions/Trade.OldAndNewTakeProfitPerInstrumentID.md) | 9.0 | Done (Batch 18) |
| [Trade.ReturnInstruemtFirstConfiguration](Functions/Trade.ReturnInstruemtFirstConfiguration.md) | 8.2 | Done (Batch 18) |
| [Trade.ReturnInstruemtFirstConfigurationNew](Functions/Trade.ReturnInstruemtFirstConfigurationNew.md) | 8.2 | Done (Batch 18) |
| [Trade.RoundByPrecisions](Functions/Trade.RoundByPrecisions.md) | 8.2 | Done (Batch 15) |
| [Trade.RoundByPrecisions_ForDebug](Functions/Trade.RoundByPrecisions_ForDebug.md) | 8.5 | Done (Batch 18) |
| [Trade.ValidateCorrectionDividendId](Functions/Trade.ValidateCorrectionDividendId.md) | 9.0 | Done (Batch 17) |
| [Trade.ValidateMaxMirrorActionAmountAbsolute](Functions/Trade.ValidateMaxMirrorActionAmountAbsolute.md) | 8.7 | Done (Batch 18) |
| [Trade.ValidateMaxMirrorActionAmountPercentage](Functions/Trade.ValidateMaxMirrorActionAmountPercentage.md) | 8.7 | Done (Batch 18) |
| [Trade.ValidateMinMirrorAmountAbsolute](Functions/Trade.ValidateMinMirrorAmountAbsolute.md) | 8.5 | Done (Batch 18) |
| [Trade.ValidateMirrorStopLossPercentage](Functions/Trade.ValidateMirrorStopLossPercentage.md) | 8.5 | Done (Batch 18) |
| [Trade.ValidateNumOfActiveMirrors](Functions/Trade.ValidateNumOfActiveMirrors.md) | 8.7 | Done (Batch 18) |
| [Trade.ValidateSmallAmountsRangePercentage](Functions/Trade.ValidateSmallAmountsRangePercentage.md) | 8.7 | Done (Batch 18) |

## Stored Procedures (924)

| Object | Quality | Status |
|--------|---------|--------|
| [Trade.AcatsOut](Stored Procedures/Trade.AcatsOut.md) | 8.5 | Done (Batch 22) |
| [Trade.AcknowledgeMessagesBSL](Stored Procedures/Trade.AcknowledgeMessagesBSL.md) | 8.2 | Done (Batch 19) |
| [Trade.AcknowledgeMessagesBSLTest](Stored Procedures/Trade.AcknowledgeMessagesBSLTest.md) | 7.8 | Done (Batch 19) |
| [Trade.ActivateSplit](Stored Procedures/Trade.ActivateSplit.md) | 9.0 | Done (Batch 22) |
| [Trade.ActivateSplit_Inner](Stored Procedures/Trade.ActivateSplit_Inner.md) | 9.0 | Done (Batch 22) |
| [Trade.ActivateStocksFeeJobs](Stored Procedures/Trade.ActivateStocksFeeJobs.md) | 7.5 | Done (Batch 19) |
| [Trade.AddCopyTradeSettlementRestriction](Stored Procedures/Trade.AddCopyTradeSettlementRestriction.md) | 7.5 | Done (Batch 19) |
| [Trade.AddExchangesHedgeGroups](Stored Procedures/Trade.AddExchangesHedgeGroups.md) | 7.5 | Done (Batch 19) |
| [Trade.AddFeeInPercentageConfigurations](Stored Procedures/Trade.AddFeeInPercentageConfigurations.md) | 8.5 | Done (Batch 22) |
| [Trade.AddFixPerLotConfigurations](Stored Procedures/Trade.AddFixPerLotConfigurations.md) | 8.5 | Done (Batch 22) |
| [Trade.AdminPositionCreate](Stored Procedures/Trade.AdminPositionCreate.md) | 7.8 | Done (Batch 19) |
| [Trade.AdminPositionOpen](Stored Procedures/Trade.AdminPositionOpen.md) | 9.0 | Done (Batch 22) |
| [Trade.Alert_LiquidityProviderContracts](Stored Procedures/Trade.Alert_LiquidityProviderContracts.md) | 7.5 | Done (Batch 19) |
| [Trade.AlertForActiveCreditRecentMemory](Stored Procedures/Trade.AlertForActiveCreditRecentMemory.md) | 7.0 | Done (Batch 19) |
| [Trade.AlertForExitOrders_which_should_have_closed](Stored Procedures/Trade.AlertForExitOrders_which_should_have_closed.md) | 8.0 | Done (Batch 19) |
| [Trade.AlertForExitOrders_which_should_have_clsoed](Stored Procedures/Trade.AlertForExitOrders_which_should_have_clsoed.md) | 7.5 | Done (Batch 19) |
| [Trade.AlertForExitOrders_which_should_have_clsoed_new](Stored Procedures/Trade.AlertForExitOrders_which_should_have_clsoed_new.md) | 7.5 | Done (Batch 19) |
| [Trade.AlertForExitOrders_which_should_have_clsoed1](Stored Procedures/Trade.AlertForExitOrders_which_should_have_clsoed1.md) | 7.5 | Done (Batch 19) |
| [Trade.AlertForMirrors_which_should_have_clsoed](Stored Procedures/Trade.AlertForMirrors_which_should_have_clsoed.md) | 8.0 | Done (Batch 19) |
| [Trade.AlertForOpenPositionWithStatus2](Stored Procedures/Trade.AlertForOpenPositionWithStatus2.md) | 8.0 | Done (Batch 19) |
| [Trade.AlertForOrphanedPositions](Stored Procedures/Trade.AlertForOrphanedPositions.md) | 8.5 | Done (Batch 19) |
| [Trade.AlertSplitPositionEndedWithError](Stored Procedures/Trade.AlertSplitPositionEndedWithError.md) | 7.5 | Done (Batch 19) |
| [Trade.AlertSplitTreeEndedWithErrorDemo](Stored Procedures/Trade.AlertSplitTreeEndedWithErrorDemo.md) | 7.5 | Done (Batch 19) |
| [Trade.ApexIdsToCIDs](Stored Procedures/Trade.ApexIdsToCIDs.md) | 7.5 | Done (Batch 19) |
| [Trade.ArchiveAccountLiquidationSaga](Stored Procedures/Trade.ArchiveAccountLiquidationSaga.md) | 7.8 | Done (Batch 19) |
| [Trade.ArchiveMirrorCloseSaga](Stored Procedures/Trade.ArchiveMirrorCloseSaga.md) | 8.0 | Done (Batch 19) |
| [Trade.AsyncOrdersChangeLog](Stored Procedures/Trade.AsyncOrdersChangeLog.md) | 8.5 | Done (Batch 22) |
| [Trade.BatchInsertEventsToSbrInstrumentsUpdates](Stored Procedures/Trade.BatchInsertEventsToSbrInstrumentsUpdates.md) | 7.8 | Done (Batch 19) |
| [Trade.BSLSetNewExecutionID](Stored Procedures/Trade.BSLSetNewExecutionID.md) | 8.0 | Done (Batch 19) |
| [Trade.BulkUpdatePositionTreeInfo](Stored Procedures/Trade.BulkUpdatePositionTreeInfo.md) | 8.5 | Done (Batch 20) |
| [Trade.CalcOverNightFeeRates](Stored Procedures/Trade.CalcOverNightFeeRates.md) | 9.0 | Done (Batch 22) |
| [Trade.CalcOverNightFeeRates_TRDOPS](Stored Procedures/Trade.CalcOverNightFeeRates_TRDOPS.md) | 8.5 | Done (Batch 22) |
| [Trade.CalcPNLForSpecificRate](Stored Procedures/Trade.CalcPNLForSpecificRate.md) | 8.5 | Done (Batch 19) |
| [Trade.CalculateLatencyMetrics](Stored Procedures/Trade.CalculateLatencyMetrics.md) | 8.5 | Done (Batch 19) |
| [Trade.CalculateLatencyMetricsVer2](Stored Procedures/Trade.CalculateLatencyMetricsVer2.md) | 8.2 | Done (Batch 19) |
| [Trade.CalculateLatencyMetricsWrapper](Stored Procedures/Trade.CalculateLatencyMetricsWrapper.md) | 8.5 | Done (Batch 20) |
| [Trade.ChangeIsSettledForASYCUsers](Stored Procedures/Trade.ChangeIsSettledForASYCUsers.md) | 8.5 | Done (Batch 22) |
| [Trade.ChangeMirrorAmount_20220317Junk](Stored Procedures/Trade.ChangeMirrorAmount_20220317Junk.md) | 7.5 | Done (Batch 20) |
| [Trade.ChangeMirrorAmount_testJunk](Stored Procedures/Trade.ChangeMirrorAmount_testJunk.md) | 7.0 | Done (Batch 20) |
| [Trade.ChangeMirrorAmountForMoe](Stored Procedures/Trade.ChangeMirrorAmountForMoe.md) | 8.0 | Done (Batch 20) |
| [Trade.ChangeMirrorCalculationType](Stored Procedures/Trade.ChangeMirrorCalculationType.md) | 7.5 | Done (Batch 20) |
| [Trade.ChangeMirrorState](Stored Procedures/Trade.ChangeMirrorState.md) | 8.0 | Done (Batch 20) |
| [Trade.ChangePositionsHedgeServer](Stored Procedures/Trade.ChangePositionsHedgeServer.md) | 7.5 | Done (Batch 20) |
| [Trade.ChangeTreePropertiesPerInstrument](Stored Procedures/Trade.ChangeTreePropertiesPerInstrument.md) | 8.5 | Done (Batch 22) |
| [Trade.CheckAllInstrumentUpload](Stored Procedures/Trade.CheckAllInstrumentUpload.md) | 7.5 | Done (Batch 20) |
| [Trade.CheckBSL](Stored Procedures/Trade.CheckBSL.md) | 8.0 | Done (Batch 20) |
| [Trade.CheckDuplicateFee](Stored Procedures/Trade.CheckDuplicateFee.md) | 7.5 | Done (Batch 20) |
| [Trade.CheckInstrumentIdExistsSecurityOpsAPI](Stored Procedures/Trade.CheckInstrumentIdExistsSecurityOpsAPI.md) | 7.5 | Done (Batch 20) |
| [Trade.CheckListOfManuallPositions](Stored Procedures/Trade.CheckListOfManuallPositions.md) | 8.0 | Done (Batch 20) |
| [Trade.CheckPriceInstrumentClosingDataExistence](Stored Procedures/Trade.CheckPriceInstrumentClosingDataExistence.md) | 7.0 | Done (Batch 20) |
| [Trade.CheckValidInstruments](Stored Procedures/Trade.CheckValidInstruments.md) | 8.5 | Done (Batch 21) |
| [Trade.CheckValidInstruments_bck](Stored Procedures/Trade.CheckValidInstruments_bck.md) | 7.5 | Done (Batch 21) |
| [Trade.CheckValidInstrumentsConstrients](Stored Procedures/Trade.CheckValidInstrumentsConstrients.md) | 8.0 | Done (Batch 20) |
| [Trade.ChekAsyncFailedSteps](Stored Procedures/Trade.ChekAsyncFailedSteps.md) | 8.0 | Done (Batch 20) |
| [Trade.CIDsInLiquidationAdd](Stored Procedures/Trade.CIDsInLiquidationAdd.md) | 7.5 | Done (Batch 20) |
| [Trade.CIDsInLiquidationRemove](Stored Procedures/Trade.CIDsInLiquidationRemove.md) | 8.5 | Done (Batch 20) |
| [Trade.ClaimEndOfWeekFee](Stored Procedures/Trade.ClaimEndOfWeekFee.md) | 8.5 | Done (Batch 20) |
| [Trade.CleanupCloseExecutionPlanJob](Stored Procedures/Trade.CleanupCloseExecutionPlanJob.md) | 8.0 | Done (Batch 20) |
| [Trade.CleanupExecutedCloseOrdersJob](Stored Procedures/Trade.CleanupExecutedCloseOrdersJob.md) | 7.5 | Done (Batch 20) |
| [Trade.CleanUpExecutedOpenOrdersJob](Stored Procedures/Trade.CleanUpExecutedOpenOrdersJob.md) | 7.5 | Done (Batch 20) |
| [Trade.CleanupExecutionPlanChangeLogJob](Stored Procedures/Trade.CleanupExecutionPlanChangeLogJob.md) | 7.5 | Done (Batch 20) |
| [Trade.CleanupOpenExecutionPlanJob](Stored Procedures/Trade.CleanupOpenExecutionPlanJob.md) | 7.5 | Done (Batch 20) |
| [Trade.CleanupOrderExecutionDataCloseOrdersJob](Stored Procedures/Trade.CleanupOrderExecutionDataCloseOrdersJob.md) | 7.5 | Done (Batch 20) |
| [Trade.CleanupOrderExecutionDataOpenOrdersJob](Stored Procedures/Trade.CleanupOrderExecutionDataOpenOrdersJob.md) | 8.0 | Done (Batch 21) |
| [Trade.CleanupOrderForExecutionChangeLogJob](Stored Procedures/Trade.CleanupOrderForExecutionChangeLogJob.md) | 8.0 | Done (Batch 21) |
| [Trade.ClearGuarenteedSLTP_CIDBlacklist](Stored Procedures/Trade.ClearGuarenteedSLTP_CIDBlacklist.md) | 8.0 | Done (Batch 21) |
| [Trade.CloseAllOpenPositions](Stored Procedures/Trade.CloseAllOpenPositions.md) | 7.5 | Done (Batch 21) |
| [Trade.CloseAllOrphandPositions](Stored Procedures/Trade.CloseAllOrphandPositions.md) | 8.5 | Done (Batch 22) |
| [Trade.CloseByRateAlert](Stored Procedures/Trade.CloseByRateAlert.md) | 8.0 | Done (Batch 21) |
| [Trade.CloseManualPositionByInitRate](Stored Procedures/Trade.CloseManualPositionByInitRate.md) | 8.5 | Done (Batch 22) |
| [Trade.CloseMultiplePositionsFailInfo](Stored Procedures/Trade.CloseMultiplePositionsFailInfo.md) | 8.0 | Done (Batch 21) |
| [Trade.CloseOpenPositionWithStatus2](Stored Procedures/Trade.CloseOpenPositionWithStatus2.md) | 8.5 | Done (Batch 21) |
| [Trade.CloseOrdersSplit](Stored Procedures/Trade.CloseOrdersSplit.md) | 8.5 | Done (Batch 21) |
| [Trade.CloseOrpahnedPositions](Stored Procedures/Trade.CloseOrpahnedPositions.md) | 8.0 | Done (Batch 21) |
| [Trade.CloseOrphanedMirrorPositionsAutomaticProcess](Stored Procedures/Trade.CloseOrphanedMirrorPositionsAutomaticProcess.md) | 8.0 | Done (Batch 21) |
| [Trade.ClosePositionAtPriceRateID](Stored Procedures/Trade.ClosePositionAtPriceRateID.md) | 8.5 | Done (Batch 22) |
| [Trade.ClosePositionsByInstrumentID](Stored Procedures/Trade.ClosePositionsByInstrumentID.md) | 8.5 | Done (Batch 22) |
| [Trade.CM_DeleteLeveragesRestrictionsWhiteList](Stored Procedures/Trade.CM_DeleteLeveragesRestrictionsWhiteList.md) | 8.0 | Done (Batch 22) |
| [Trade.CM_GetLeveragesRestrictionsWhiteList](Stored Procedures/Trade.CM_GetLeveragesRestrictionsWhiteList.md) | 8.0 | Done (Batch 22) |
| [Trade.CM_InsertLeveragesRestrictionsWhiteList](Stored Procedures/Trade.CM_InsertLeveragesRestrictionsWhiteList.md) | 8.5 | Done (Batch 23) |
| [Trade.CM_UpdateLeveragesRestrictionsWhiteList](Stored Procedures/Trade.CM_UpdateLeveragesRestrictionsWhiteList.md) | 8.0 | Done (Batch 23) |
| [Trade.CollectCurrencyPriceDifferencesBetweenFeeds](Stored Procedures/Trade.CollectCurrencyPriceDifferencesBetweenFeeds.md) | 8.5 | Done (Batch 23) |
| [Trade.CreateNewFundAllocation](Stored Procedures/Trade.CreateNewFundAllocation.md) | 9.0 | Done (Batch 23) |
| [Trade.CurrencyPriceDifferencesAlert](Stored Procedures/Trade.CurrencyPriceDifferencesAlert.md) | 8.5 | Done (Batch 23) |
| [Trade.CurrencyPriceRemove](Stored Procedures/Trade.CurrencyPriceRemove.md) | 7.0 | Done (Batch 23) |
| [Trade.CusipsToInstrumentIDs](Stored Procedures/Trade.CusipsToInstrumentIDs.md) | 8.0 | Done (Batch 23) |
| [Trade.CustomerRestrictionCIDs_Wrapper](Stored Procedures/Trade.CustomerRestrictionCIDs_Wrapper.md) | 8.5 | Done (Batch 22) |
| [Trade.CustomerRestrictionCIDs_Wrapper_MainJOB](Stored Procedures/Trade.CustomerRestrictionCIDs_Wrapper_MainJOB.md) | 8.5 | Done (Batch 22) |
| [Trade.CustomerRestrictionRemove](Stored Procedures/Trade.CustomerRestrictionRemove.md) | 8.5 | Done (Batch 23) |
| [Trade.CustomerRestrictionRemove_CIDs](Stored Procedures/Trade.CustomerRestrictionRemove_CIDs.md) | 8.5 | Done (Batch 22) |
| [Trade.CustomerRestrictionSet](Stored Procedures/Trade.CustomerRestrictionSet.md) | 8.0 | Done (Batch 23) |
| [Trade.CustomerRestrictionSet_CIDs](Stored Procedures/Trade.CustomerRestrictionSet_CIDs.md) | 8.5 | Done (Batch 22) |
| [Trade.CustomerRestrictionsRemove](Stored Procedures/Trade.CustomerRestrictionsRemove.md) | 8.5 | Done (Batch 23) |
| [Trade.CustomerRestrictionsSet](Stored Procedures/Trade.CustomerRestrictionsSet.md) | 8.5 | Done (Batch 23) |
| [Trade.DailyDigest](Stored Procedures/Trade.DailyDigest.md) | 9.0 | Done (Batch 23) |
| [Trade.DBtestMot](Stored Procedures/Trade.DBtestMot.md) | 7.0 | Done (Batch 23) |
| [Trade.DealingMasterQuery](Stored Procedures/Trade.DealingMasterQuery.md) | 7.5 | Done (Batch 24) |
| [Trade.DelayedOrderForCloseStatusUpdate](Stored Procedures/Trade.DelayedOrderForCloseStatusUpdate.md) | 8.5 | Done (Batch 24) |
| [Trade.DelayedOrderForOpenStatusUpdate](Stored Procedures/Trade.DelayedOrderForOpenStatusUpdate.md) | 8.5 | Done (Batch 24) |
| [Trade.DelayedOrdersOvernight](Stored Procedures/Trade.DelayedOrdersOvernight.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteBulkOperationsAllowedCid](Stored Procedures/Trade.DeleteBulkOperationsAllowedCid.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteClosedTrees](Stored Procedures/Trade.DeleteClosedTrees.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteCloseExecutionPlanJob](Stored Procedures/Trade.DeleteCloseExecutionPlanJob.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteCloseOrderExecutionData](Stored Procedures/Trade.DeleteCloseOrderExecutionData.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteCopyTradeSettlementRestriction](Stored Procedures/Trade.DeleteCopyTradeSettlementRestriction.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteCopyTradeSettlementRestrictionsValues](Stored Procedures/Trade.DeleteCopyTradeSettlementRestrictionsValues.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS](Stored Procedures/Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteDelayedOrderForCloseJob](Stored Procedures/Trade.DeleteDelayedOrderForCloseJob.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteDelayedOrderForOpenJob](Stored Procedures/Trade.DeleteDelayedOrderForOpenJob.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteDividend](Stored Procedures/Trade.DeleteDividend.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteExecutedCloseOrdersJob](Stored Procedures/Trade.DeleteExecutedCloseOrdersJob.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteExecutedOpenOrdersJob](Stored Procedures/Trade.DeleteExecutedOpenOrdersJob.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteExecutionPlanChangeLogJob](Stored Procedures/Trade.DeleteExecutionPlanChangeLogJob.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteFeeInPercentageConfigurations](Stored Procedures/Trade.DeleteFeeInPercentageConfigurations.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteFixPerLotConfigurations](Stored Procedures/Trade.DeleteFixPerLotConfigurations.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteFromBSLUsersWhiteList](Stored Procedures/Trade.DeleteFromBSLUsersWhiteList.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteFundAllocationBacktestData](Stored Procedures/Trade.DeleteFundAllocationBacktestData.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteIndexDividends](Stored Procedures/Trade.DeleteIndexDividends.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteInstrumentGroup](Stored Procedures/Trade.DeleteInstrumentGroup.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteInterestRateOverride](Stored Procedures/Trade.DeleteInterestRateOverride.md) | 7.5 | Done (Batch 24) |
| [Trade.DeleteInterestRateOverride_TRDOPS](Stored Procedures/Trade.DeleteInterestRateOverride_TRDOPS.md) | 8.0 | Done (Batch 24) |
| [Trade.DeleteMessagesFromManageBSL](Stored Procedures/Trade.DeleteMessagesFromManageBSL.md) | 8.4 | Done (Batch 25) |
| [Trade.DeleteOldOrderOnlyDemo](Stored Procedures/Trade.DeleteOldOrderOnlyDemo.md) | 8.6 | Done (Batch 25) |
| [Trade.DeleteOpenExecutionPlanJob](Stored Procedures/Trade.DeleteOpenExecutionPlanJob.md) | 8.6 | Done (Batch 25) |
| [Trade.DeleteOpenOrderExecutionData](Stored Procedures/Trade.DeleteOpenOrderExecutionData.md) | 8.4 | Done (Batch 25) |
| [Trade.DeleteOrderForCloseJob](Stored Procedures/Trade.DeleteOrderForCloseJob.md) | 8.6 | Done (Batch 25) |
| [Trade.DeleteOrderForExecutionChangeLogJob](Stored Procedures/Trade.DeleteOrderForExecutionChangeLogJob.md) | 8.4 | Done (Batch 25) |
| [Trade.DeleteOrderForOpenJob](Stored Procedures/Trade.DeleteOrderForOpenJob.md) | 8.6 | Done (Batch 25) |
| [Trade.DELGetCESQuery](Stored Procedures/Trade.DELGetCESQuery.md) | 8.0 | Done (Batch 25) |
| [Trade.DelistAlert](Stored Procedures/Trade.DelistAlert.md) | 8.4 | Done (Batch 25) |
| [Trade.DelistStock](Stored Procedures/Trade.DelistStock.md) | 9.0 | Done (Batch 25) |
| [Trade.DeltaDiffDataAdd](Stored Procedures/Trade.DeltaDiffDataAdd.md) | 8.6 | Done (Batch 25) |
| [Trade.DemoUpdateTreeOnDetachment](Stored Procedures/Trade.DemoUpdateTreeOnDetachment.md) | 8.6 | Done (Batch 25) |
| [Trade.DetachFromParentOrder](Stored Procedures/Trade.DetachFromParentOrder.md) | 8.2 | Done (Batch 25) |
| [Trade.DetachFromParentPosition](Stored Procedures/Trade.DetachFromParentPosition.md) | 8.6 | Done (Batch 25) |
| [Trade.DetachPositionsByCountryAndInstrument](Stored Procedures/Trade.DetachPositionsByCountryAndInstrument.md) | 8.4 | Done (Batch 25) |
| [Trade.DetachPositionsFromMirror](Stored Procedures/Trade.DetachPositionsFromMirror.md) | 8.8 | Done (Batch 25) |
| [Trade.DisableBslJobForSplit](Stored Procedures/Trade.DisableBslJobForSplit.md) | 8.2 | Done (Batch 25) |
| [Trade.DisableInstrument](Stored Procedures/Trade.DisableInstrument.md) | 8.0 | Done (Batch 25) |
| [Trade.DividendsGetMirrorState](Stored Procedures/Trade.DividendsGetMirrorState.md) | 7.8 | Done (Batch 25) |
| [Trade.DividendsSetPaymentIsComplete](Stored Procedures/Trade.DividendsSetPaymentIsComplete.md) | 8.0 | Done (Batch 25) |
| [Trade.DividendsSetPaymentIsComplete_DryRun](Stored Procedures/Trade.DividendsSetPaymentIsComplete_DryRun.md) | 7.8 | Done (Batch 25) |
| [Trade.DividendsSetPaymentStatus](Stored Procedures/Trade.DividendsSetPaymentStatus.md) | 8.0 | Done (Batch 25) |
| [Trade.DividendsSetSnapshotIsReady](Stored Procedures/Trade.DividendsSetSnapshotIsReady.md) | 8.2 | Done (Batch 25) |
| [Trade.DividendsSetSnapshotIsReady_DryRun](Stored Procedures/Trade.DividendsSetSnapshotIsReady_DryRun.md) | 7.8 | Done (Batch 25) |
| [Trade.DMAOrdersStuckAsPlaced](Stored Procedures/Trade.DMAOrdersStuckAsPlaced.md) | 8.4 | Done (Batch 25) |
| [Trade.EffectiveLeveragePositions](Stored Procedures/Trade.EffectiveLeveragePositions.md) | 8.2 | Done (Batch 26) |
| [Trade.EffectiveLeveragePositions_Job](Stored Procedures/Trade.EffectiveLeveragePositions_Job.md) | 8.0 | Done (Batch 26) |
| [Trade.Elad111](Stored Procedures/Trade.Elad111.md) | 8.0 | Done (Batch 26) |
| [Trade.EnableInstrumentLowTouch](Stored Procedures/Trade.EnableInstrumentLowTouch.md) | 8.2 | Done (Batch 26) |
| [Trade.EnqueuePaymentToSvcPayment](Stored Procedures/Trade.EnqueuePaymentToSvcPayment.md) | 8.4 | Done (Batch 26) |
| [Trade.EOW_CloseCustomerPositionByMod](Stored Procedures/Trade.EOW_CloseCustomerPositionByMod.md) | 8.0 | Done (Batch 26) |
| [Trade.ExecuteAllFeeJobs](Stored Procedures/Trade.ExecuteAllFeeJobs.md) | 8.0 | Done (Batch 26) |
| [Trade.ExecuteCashPayment](Stored Procedures/Trade.ExecuteCashPayment.md) | 8.4 | Done (Batch 26) |
| [Trade.ExposuresForAllHedgeServers_Check](Stored Procedures/Trade.ExposuresForAllHedgeServers_Check.md) | 8.2 | Done (Batch 26) |
| [Trade.ExposuresForAllHedgeServers_Update](Stored Procedures/Trade.ExposuresForAllHedgeServers_Update.md) | 8.6 | Done (Batch 26) |
| [Trade.ExposuresForAllHedgeServers_WeekendCleanup](Stored Procedures/Trade.ExposuresForAllHedgeServers_WeekendCleanup.md) | 8.0 | Done (Batch 26) |
| [Trade.FailedClientCloseRequestsReport](Stored Procedures/Trade.FailedClientCloseRequestsReport.md) | 8.2 | Done (Batch 26) |
| [Trade.FailedDelayedCopyOrders](Stored Procedures/Trade.FailedDelayedCopyOrders.md) | 8.2 | Done (Batch 26) |
| [Trade.FeeInPercentageConfigurationsTblValidate](Stored Procedures/Trade.FeeInPercentageConfigurationsTblValidate.md) | 8.0 | Done (Batch 21) |
| [Trade.FixFinanacialData](Stored Procedures/Trade.FixFinanacialData.md) | 8.4 | Done (Batch 26) |
| [Trade.FixPerLotConfigurationsTblValidate](Stored Procedures/Trade.FixPerLotConfigurationsTblValidate.md) | 8.0 | Done (Batch 21) |
| [Trade.FlushTSLForInstrumentID](Stored Procedures/Trade.FlushTSLForInstrumentID.md) | 8.0 | Done (Batch 22) |
| [Trade.FlushTSLForSpecificTree](Stored Procedures/Trade.FlushTSLForSpecificTree.md) | 8.5 | Done (Batch 21) |
| [Trade.ForkByDB](Stored Procedures/Trade.ForkByDB.md) | 7.5 | Done (Batch 30) |
| [Trade.FundBacktestDataDelete](Stored Procedures/Trade.FundBacktestDataDelete.md) | 8.0 | Done (Batch 26) |
| [Trade.FundMgrSync](Stored Procedures/Trade.FundMgrSync.md) | 8.2 | Done (Batch 26) |
| [Trade.Gain_CheckSysReplicationState](Stored Procedures/Trade.Gain_CheckSysReplicationState.md) | 8.0 | Done (Batch 26) |
| [Trade.Gain_CheckWithdrawalStatus](Stored Procedures/Trade.Gain_CheckWithdrawalStatus.md) | 8.0 | Done (Batch 26) |
| [Trade.Gain_GetActiveCustomers](Stored Procedures/Trade.Gain_GetActiveCustomers.md) | 8.0 | Done (Batch 26) |
| [Trade.Gain_GetActiveCustomersWithTempTbl](Stored Procedures/Trade.Gain_GetActiveCustomersWithTempTbl.md) | 8.0 | Done (Batch 26) |
| [Trade.Gain_GetCustomersAnonID](Stored Procedures/Trade.Gain_GetCustomersAnonID.md) | 8.0 | Done (Batch 26) |
| [Trade.Gain_GetCustomersCIDsByAnonID](Stored Procedures/Trade.Gain_GetCustomersCIDsByAnonID.md) | 8.0 | Done (Batch 26) |
| [Trade.Gain_GetCustomersWithMultiplePayoutDays](Stored Procedures/Trade.Gain_GetCustomersWithMultiplePayoutDays.md) | 8.2 | Done (Batch 26) |
| [Trade.Gain_GetPendingBonusesAndWithdrawals](Stored Procedures/Trade.Gain_GetPendingBonusesAndWithdrawals.md) | 8.2 | Done (Batch 26) |
| [Trade.Gain_LoadCashflows](Stored Procedures/Trade.Gain_LoadCashflows.md) | 8.4 | Done (Batch 26) |
| [Trade.Gain_UpdateNewBonuses](Stored Procedures/Trade.Gain_UpdateNewBonuses.md) | 7.8 | Done (Batch 26) |
| [Trade.GenerateCloseByUnitsPositionsList](Stored Procedures/Trade.GenerateCloseByUnitsPositionsList.md) | 8.4 | Done (Batch 26) |
| [Trade.GenerateCloseMultiplePositionsList](Stored Procedures/Trade.GenerateCloseMultiplePositionsList.md) | 8.2 | Done (Batch 26) |
| [Trade.GetAccountAssets](Stored Procedures/Trade.GetAccountAssets.md) | 8.0 | Done (Batch 26) |
| [Trade.GetAccountAssetsForLiquidation](Stored Procedures/Trade.GetAccountAssetsForLiquidation.md) | 8.4 | Done (Batch 26) |
| Trade.GetAccountOrdersForLiquidation | - | Queued (Batch 54, #1) |
| [Trade.GetAccountPartialExitOrders](Stored Procedures/Trade.GetAccountPartialExitOrders.md) | 7.8 | Done (Batch 26) |
| [Trade.GetActiveChildMirrorsByParentCIDAndDate](Stored Procedures/Trade.GetActiveChildMirrorsByParentCIDAndDate.md) | 7.8 | Done (Batch 26) |
| [Trade.GetActiveCopiersForParents](Stored Procedures/Trade.GetActiveCopiersForParents.md) | 8.0 | Done (Batch 26) |
| [Trade.GetAdminPositionLogByAdminPositionID](Stored Procedures/Trade.GetAdminPositionLogByAdminPositionID.md) | 7.6 | Done (Batch 26) |
| [Trade.GetAdminPositionLogByPositionID](Stored Procedures/Trade.GetAdminPositionLogByPositionID.md) | 7.6 | Done (Batch 26) |
| [Trade.GetAdminPositionLogByRequestID](Stored Procedures/Trade.GetAdminPositionLogByRequestID.md) | 7.6 | Done (Batch 26) |
| [Trade.GetAdminPositions](Stored Procedures/Trade.GetAdminPositions.md) | 8.0 | Done (Batch 27) |
| [Trade.GetAdminPositionsWithCID](Stored Procedures/Trade.GetAdminPositionsWithCID.md) | 8.2 | Done (Batch 26) |
| [Trade.GetAdminPositionsWithoutCID](Stored Procedures/Trade.GetAdminPositionsWithoutCID.md) | 8.0 | Done (Batch 26) |
| [Trade.GetAggregatedPositionsForDataApi](Stored Procedures/Trade.GetAggregatedPositionsForDataApi.md) | 8.4 | Done (Batch 26) |
| [Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection](Stored Procedures/Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection.md) | 8.0 | Done (Batch 26) |
| [Trade.GetAleErrorReport](Stored Procedures/Trade.GetAleErrorReport.md) | 8.2 | Done (Batch 26) |
| [Trade.GetAleErrorReportNew](Stored Procedures/Trade.GetAleErrorReportNew.md) | 8.0 | Done (Batch 26) |
| [Trade.GetAleErrorReportV2](Stored Procedures/Trade.GetAleErrorReportV2.md) | 7.8 | Done (Batch 26) |
| [Trade.GetAllAccountAssetsForLiquidation](Stored Procedures/Trade.GetAllAccountAssetsForLiquidation.md) | 8.2 | Done (Batch 26) |
| [Trade.GetAllBulkOperationsAllowedCids](Stored Procedures/Trade.GetAllBulkOperationsAllowedCids.md) | 7.6 | Done (Batch 26) |
| [Trade.GetAllBusinessSummaryForAPI](Stored Procedures/Trade.GetAllBusinessSummaryForAPI.md) | 7.6 | Done (Batch 26) |
| [Trade.GetAllCurrencyDatasForAPI](Stored Procedures/Trade.GetAllCurrencyDatasForAPI.md) | 7.6 | Done (Batch 26) |
| [Trade.GetAllExchangeInfosForAPI](Stored Procedures/Trade.GetAllExchangeInfosForAPI.md) | 7.4 | Done (Batch 26) |
| [Trade.GetAllFeeInPercentageConfigurations](Stored Procedures/Trade.GetAllFeeInPercentageConfigurations.md) | 7.8 | Done (Batch 26) |
| [Trade.GetAllFixPerLotConfigurations](Stored Procedures/Trade.GetAllFixPerLotConfigurations.md) | 7.8 | Done (Batch 26) |
| [Trade.GetAllFuturesMetadataSecurityOpsAPI](Stored Procedures/Trade.GetAllFuturesMetadataSecurityOpsAPI.md) | 7.6 | Done (Batch 27) |
| [Trade.GetAllImageInfosForAPI](Stored Procedures/Trade.GetAllImageInfosForAPI.md) | 7.2 | Done (Batch 27) |
| [Trade.GetAllImageInfosForAPIExtended](Stored Procedures/Trade.GetAllImageInfosForAPIExtended.md) | 7.4 | Done (Batch 27) |
| [Trade.GetAllInstrumentCategoriesForAPI](Stored Procedures/Trade.GetAllInstrumentCategoriesForAPI.md) | 7.8 | Done (Batch 27) |
| [Trade.GetAllInstrumentData](Stored Procedures/Trade.GetAllInstrumentData.md) | 8.0 | Done (Batch 27) |
| [Trade.GetAllInstrumentDisplayDatasForAPI](Stored Procedures/Trade.GetAllInstrumentDisplayDatasForAPI.md) | 7.6 | Done (Batch 27) |
| [Trade.GetAllInstrumentTypesForAPI](Stored Procedures/Trade.GetAllInstrumentTypesForAPI.md) | 7.4 | Done (Batch 27) |
| [Trade.GetAllInstrumentTypeSubCategoryForAPI](Stored Procedures/Trade.GetAllInstrumentTypeSubCategoryForAPI.md) | 7.4 | Done (Batch 27) |
| [Trade.GetAllInterestRates](Stored Procedures/Trade.GetAllInterestRates.md) | 7.8 | Done (Batch 27) |
| [Trade.GetAllInterestRates_TRDOPS](Stored Procedures/Trade.GetAllInterestRates_TRDOPS.md) | 7.6 | Done (Batch 27) |
| [Trade.GetAllocationData](Stored Procedures/Trade.GetAllocationData.md) | 8.2 | Done (Batch 27) |
| [Trade.GetAllocationDataResiduals](Stored Procedures/Trade.GetAllocationDataResiduals.md) | 7.8 | Done (Batch 27) |
| [Trade.GetAllPositionsWithNoLock](Stored Procedures/Trade.GetAllPositionsWithNoLock.md) | 7.8 | Done (Batch 27) |
| [Trade.GetAllStocksIndustriesForAPI](Stored Procedures/Trade.GetAllStocksIndustriesForAPI.md) | 7.2 | Done (Batch 27) |
| [Trade.GetBacktraderCustomerData](Stored Procedures/Trade.GetBacktraderCustomerData.md) | 8.4 | Done (Batch 27) |
| [Trade.GetBacktraderIsUserUS](Stored Procedures/Trade.GetBacktraderIsUserUS.md) | 7.8 | Done (Batch 27) |
| [Trade.GetBlockedPlayerStatusIds](Stored Procedures/Trade.GetBlockedPlayerStatusIds.md) | 7.8 | Done (Batch 27) |
| [Trade.GetBulkOperationsAllowedCids](Stored Procedures/Trade.GetBulkOperationsAllowedCids.md) | 7.8 | Done (Batch 27) |
| [Trade.GetCalculatedFeesConfig_TRDOPS](Stored Procedures/Trade.GetCalculatedFeesConfig_TRDOPS.md) | 8.0 | Done (Batch 27) |
| [Trade.GetCashingTerminalIDs](Stored Procedures/Trade.GetCashingTerminalIDs.md) | 7.2 | Done (Batch 27) |
| [Trade.GetCESQuery](Stored Procedures/Trade.GetCESQuery.md) | 7.8 | Done (Batch 27) |
| [Trade.GetCIDAccountAssetsForLiquidation](Stored Procedures/Trade.GetCIDAccountAssetsForLiquidation.md) | 8.6 | Done (Batch 27) |
| [Trade.GetCIDByGCID](Stored Procedures/Trade.GetCIDByGCID.md) | 7.4 | Done (Batch 27) |
| [Trade.GetCIDsForIndexDividends](Stored Procedures/Trade.GetCIDsForIndexDividends.md) | 8.8 | Done (Batch 27) |
| [Trade.GetClientPortfolioForAPI](Stored Procedures/Trade.GetClientPortfolioForAPI.md) | 7.5 | Done (Batch 30) |
| [Trade.GetClosedPositionsFromTimestamp](Stored Procedures/Trade.GetClosedPositionsFromTimestamp.md) | 7.0 | Done (Batch 28) |
| [Trade.GetCloseExecutionPlan](Stored Procedures/Trade.GetCloseExecutionPlan.md) | 8.2 | Done (Batch 28) |
| [Trade.GetCloseOrderExecutedUnits](Stored Procedures/Trade.GetCloseOrderExecutedUnits.md) | 7.8 | Done (Batch 28) |
| [Trade.GetClosingTreeUnitsByPositionID](Stored Procedures/Trade.GetClosingTreeUnitsByPositionID.md) | 8.0 | Done (Batch 28) |
| [Trade.GetClosingTreeUnitsByPositionID1](Stored Procedures/Trade.GetClosingTreeUnitsByPositionID1.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCommissionsByInstrumentHedgeServer](Stored Procedures/Trade.GetCommissionsByInstrumentHedgeServer.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCommissionsByInstrumentHedgeServer_New](Stored Procedures/Trade.GetCommissionsByInstrumentHedgeServer_New.md) | 7.8 | Done (Batch 28) |
| [Trade.GetCommissionsByInstrumentHedgeServer_New_SS](Stored Procedures/Trade.GetCommissionsByInstrumentHedgeServer_New_SS.md) | 7.8 | Done (Batch 28) |
| [Trade.GetCompensationReasons](Stored Procedures/Trade.GetCompensationReasons.md) | 7.0 | Done (Batch 28) |
| [Trade.GetComplianceGroupByCID](Stored Procedures/Trade.GetComplianceGroupByCID.md) | 7.0 | Done (Batch 28) |
| [Trade.GetConversionReport](Stored Procedures/Trade.GetConversionReport.md) | 7.0 | Done (Batch 28) |
| [Trade.GetCopyTradeSettlementRestrictions](Stored Procedures/Trade.GetCopyTradeSettlementRestrictions.md) | 6.4 | Done (Batch 28) |
| [Trade.GetCorporateActionType](Stored Procedures/Trade.GetCorporateActionType.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCorporateInstrumentActions](Stored Procedures/Trade.GetCorporateInstrumentActions.md) | 7.0 | Done (Batch 28) |
| [Trade.GetCountInstrumentOpenTrades](Stored Procedures/Trade.GetCountInstrumentOpenTrades.md) | 7.0 | Done (Batch 28) |
| [Trade.GetCountryIDsWithName](Stored Procedures/Trade.GetCountryIDsWithName.md) | 7.0 | Done (Batch 28) |
| [Trade.GetCurrencyConversions](Stored Procedures/Trade.GetCurrencyConversions.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCurrentHedgePositionSize](Stored Procedures/Trade.GetCurrentHedgePositionSize.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCurrentInsights](Stored Procedures/Trade.GetCurrentInsights.md) | 7.8 | Done (Batch 28) |
| [Trade.GetCurrPosValue](Stored Procedures/Trade.GetCurrPosValue.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCustomApexMapping](Stored Procedures/Trade.GetCustomApexMapping.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCustomerBlockUnBlockReasonsForAPI](Stored Procedures/Trade.GetCustomerBlockUnBlockReasonsForAPI.md) | 7.0 | Done (Batch 28) |
| [Trade.GetCustomerDataAndRestrictions](Stored Procedures/Trade.GetCustomerDataAndRestrictions.md) | 8.0 | Done (Batch 28) |
| [Trade.GetCustomerDataByGCID](Stored Procedures/Trade.GetCustomerDataByGCID.md) | 7.4 | Done (Batch 28) |
| [Trade.GetCustomerManualOpenPositions](Stored Procedures/Trade.GetCustomerManualOpenPositions.md) | 8.0 | Done (Batch 29) |
| [Trade.GetCustomerRealPositionsData](Stored Procedures/Trade.GetCustomerRealPositionsData.md) | 8.0 | Done (Batch 29) |
| [Trade.GetCustomerRestrictionsForAPI](Stored Procedures/Trade.GetCustomerRestrictionsForAPI.md) | 7.2 | Done (Batch 28) |
| [Trade.GetCustomerRestrictionsWhiteList](Stored Procedures/Trade.GetCustomerRestrictionsWhiteList.md) | 8.0 | Done (Batch 29) |
| [Trade.GetCustomersDataWithCopyRestirctions](Stored Procedures/Trade.GetCustomersDataWithCopyRestirctions.md) | 8.0 | Done (Batch 29) |
| [Trade.GetCustomersDataWithRestirctions](Stored Procedures/Trade.GetCustomersDataWithRestirctions.md) | 8.0 | Done (Batch 29) |
| [Trade.GetCustomersLivePositionData](Stored Procedures/Trade.GetCustomersLivePositionData.md) | 8.0 | Done (Batch 29) |
| [Trade.GetCustomersRestrictionsByTypesForAPI](Stored Procedures/Trade.GetCustomersRestrictionsByTypesForAPI.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDailyActiveMirrors](Stored Procedures/Trade.GetDailyActiveMirrors.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDataForCloseMirrorPositions](Stored Procedures/Trade.GetDataForCloseMirrorPositions.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDataForCloseMirrorPositionsMOTElad](Stored Procedures/Trade.GetDataForCloseMirrorPositionsMOTElad.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDataForPositionAdjustment](Stored Procedures/Trade.GetDataForPositionAdjustment.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDelayedOrderForCloseWithPaging](Stored Procedures/Trade.GetDelayedOrderForCloseWithPaging.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDelayedOrderForOpenWithPaging](Stored Procedures/Trade.GetDelayedOrderForOpenWithPaging.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDemoCopiedCids](Stored Procedures/Trade.GetDemoCopiedCids.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDetachRequiredData](Stored Procedures/Trade.GetDetachRequiredData.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDetachTreePositionIDs](Stored Procedures/Trade.GetDetachTreePositionIDs.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendNumPaidPositions](Stored Procedures/Trade.GetDividendNumPaidPositions.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendPaidPositionsHash](Stored Procedures/Trade.GetDividendPaidPositionsHash.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendsByStatus](Stored Procedures/Trade.GetDividendsByStatus.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendsForPayment](Stored Procedures/Trade.GetDividendsForPayment.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendsForPayment_DryRun](Stored Procedures/Trade.GetDividendsForPayment_DryRun.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendsForSnapshot](Stored Procedures/Trade.GetDividendsForSnapshot.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendsForSnapshot_DryRun](Stored Procedures/Trade.GetDividendsForSnapshot_DryRun.md) | 8.0 | Done (Batch 29) |
| [Trade.GetDividendsPaidAmount](Stored Procedures/Trade.GetDividendsPaidAmount.md) | 8.0 | Done (Batch 29) |
| [Trade.GetEnabledAndListedInstruments](Stored Procedures/Trade.GetEnabledAndListedInstruments.md) | 8.0 | Done (Batch 29) |
| [Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue](Stored Procedures/Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue.md) | 8.5 | Done (Batch 30) |
| [Trade.GetEnumMappings_TRDOPS](Stored Procedures/Trade.GetEnumMappings_TRDOPS.md) | 7.5 | Done (Batch 30) |
| [Trade.GetEstimatedClosingTreeUnitsByPositionID](Stored Procedures/Trade.GetEstimatedClosingTreeUnitsByPositionID.md) | 7.5 | Done (Batch 30) |
| [Trade.GetEstimatedTreeUnitsByCID](Stored Procedures/Trade.GetEstimatedTreeUnitsByCID.md) | 7.5 | Done (Batch 30) |
| [Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk](Stored Procedures/Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk.md) | 7.5 | Done (Batch 30) |
| [Trade.GetEstimatedTreeUnitsByCIDMotiJUNK](Stored Procedures/Trade.GetEstimatedTreeUnitsByCIDMotiJUNK.md) | 7.5 | Done (Batch 30) |
| [Trade.GetExchangeIDsByTimeUTC](Stored Procedures/Trade.GetExchangeIDsByTimeUTC.md) | 7.0 | Done (Batch 30) |
| [Trade.GetExcludeHaltInstruments](Stored Procedures/Trade.GetExcludeHaltInstruments.md) | 7.0 | Done (Batch 30) |
| [Trade.GetExecutedClosePositionIDs](Stored Procedures/Trade.GetExecutedClosePositionIDs.md) | 7.5 | Done (Batch 30) |
| [Trade.GetExecutedOpenPositionCorrelationIDs](Stored Procedures/Trade.GetExecutedOpenPositionCorrelationIDs.md) | 7.5 | Done (Batch 30) |
| [Trade.GetExtetendedCustomerDataByGCID](Stored Procedures/Trade.GetExtetendedCustomerDataByGCID.md) | 7.0 | Done (Batch 30) |
| [Trade.GetFeeOperationTypesDictionary](Stored Procedures/Trade.GetFeeOperationTypesDictionary.md) | 7.0 | Done (Batch 30) |
| [Trade.GetFirmAggregation](Stored Procedures/Trade.GetFirmAggregation.md) | 7.5 | Done (Batch 30) |
| [Trade.GetFirmAggregationHWM](Stored Procedures/Trade.GetFirmAggregationHWM.md) | 7.5 | Done (Batch 30) |
| [Trade.GetForexRates](Stored Procedures/Trade.GetForexRates.md) | 7.0 | Done (Batch 30) |
| [Trade.GetFundCidsBulk](Stored Procedures/Trade.GetFundCidsBulk.md) | 7.0 | Done (Batch 30) |
| [Trade.GetFundInfo](Stored Procedures/Trade.GetFundInfo.md) | 7.5 | Done (Batch 30) |
| [Trade.GetFundMetaData](Stored Procedures/Trade.GetFundMetaData.md) | 7.5 | Done (Batch 30) |
| [Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI](Stored Procedures/Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI.md) | 7.0 | Done (Batch 30) |
| [Trade.GetGCIDByCID](Stored Procedures/Trade.GetGCIDByCID.md) | 7.0 | Done (Batch 30) |
| [Trade.GetGcidByCidAndParentGcidByParentUserName](Stored Procedures/Trade.GetGcidByCidAndParentGcidByParentUserName.md) | 8.5 | Done (Batch 31, #1) |
| [Trade.GetGuarenteedSLTP_CIDBlacklist](Stored Procedures/Trade.GetGuarenteedSLTP_CIDBlacklist.md) | 7.8 | Done (Batch 31, #2) |
| [Trade.GetGuruOpenPositionsWithCustomerData](Stored Procedures/Trade.GetGuruOpenPositionsWithCustomerData.md) | 8.2 | Done (Batch 31, #3) |
| [Trade.GetHedgeCost](Stored Procedures/Trade.GetHedgeCost.md) | 8.0 | Done (Batch 31, #4) |
| [Trade.GetHedgedCustomerPosition](Stored Procedures/Trade.GetHedgedCustomerPosition.md) | 8.0 | Done (Batch 31, #5) |
| [Trade.GetHistoryAndLivePrivatePositionsByCid](Stored Procedures/Trade.GetHistoryAndLivePrivatePositionsByCid.md) | 8.2 | Done (Batch 31, #6) |
| [Trade.GetHistoryInsights](Stored Procedures/Trade.GetHistoryInsights.md) | 8.5 | Done (Batch 31, #7) |
| [Trade.GetHistoryInsightsTest](Stored Procedures/Trade.GetHistoryInsightsTest.md) | 7.5 | Done (Batch 31, #8) |
| [Trade.GetInstrumentAssetClassMappingsByIds](Stored Procedures/Trade.GetInstrumentAssetClassMappingsByIds.md) | 7.5 | Done (Batch 31, #9) |
| [Trade.GetInstrumentByCreateData](Stored Procedures/Trade.GetInstrumentByCreateData.md) | 7.5 | Done (Batch 31, #10) |
| [Trade.GetInstrumentByIdSecurityOpsAPI](Stored Procedures/Trade.GetInstrumentByIdSecurityOpsAPI.md) | 7.5 | Done (Batch 31, #11) |
| [Trade.GetInstrumentConfigurationsByPriceServerID](Stored Procedures/Trade.GetInstrumentConfigurationsByPriceServerID.md) | 7.5 | Done (Batch 31, #12) |
| [Trade.GetInstrumentConfigurationUpdate](Stored Procedures/Trade.GetInstrumentConfigurationUpdate.md) | 8.0 | Done (Batch 31, #13) |
| [Trade.GetInstrumentConfigurationWrapper](Stored Procedures/Trade.GetInstrumentConfigurationWrapper.md) | 7.5 | Done (Batch 31, #14) |
| [Trade.GetInstrumentConversionsByPriceServerID](Stored Procedures/Trade.GetInstrumentConversionsByPriceServerID.md) | 7.8 | Done (Batch 31, #15) |
| [Trade.GetInstrumentCusip](Stored Procedures/Trade.GetInstrumentCusip.md) | 7.0 | Done (Batch 31, #16) |
| [Trade.GetInstrumentDataForAPI](Stored Procedures/Trade.GetInstrumentDataForAPI.md) | 8.5 | Done (Batch 31, #17) |
| [Trade.GetInstrumentDataForAPITest](Stored Procedures/Trade.GetInstrumentDataForAPITest.md) | 7.5 | Done (Batch 31, #18) |
| [Trade.GetInstrumentDesignatedSystem](Stored Procedures/Trade.GetInstrumentDesignatedSystem.md) | 7.0 | Done (Batch 31, #19) |
| [Trade.GetInstrumentGroupsDictionary](Stored Procedures/Trade.GetInstrumentGroupsDictionary.md) | 7.0 | Done (Batch 31, #20) |
| [Trade.GetInstrumentIdsToIgnoreLimit](Stored Procedures/Trade.GetInstrumentIdsToIgnoreLimit.md) | 8.0 | Done (Batch 31, #21) |
| [Trade.GetInstrumentIDToAllowedRateDiff](Stored Procedures/Trade.GetInstrumentIDToAllowedRateDiff.md) | 7.0 | Done (Batch 31, #22) |
| [Trade.GetInstrumentInSplit](Stored Procedures/Trade.GetInstrumentInSplit.md) | 7.5 | Done (Batch 31, #23) |
| [Trade.GetInstrumentInterestRates](Stored Procedures/Trade.GetInstrumentInterestRates.md) | 8.5 | Done (Batch 31, #24) |
| [Trade.GetInstrumentInterestRates_TRDOPS](Stored Procedures/Trade.GetInstrumentInterestRates_TRDOPS.md) | 8.5 | Done (Batch 31, #25) |
| [Trade.GetInstrumentMarginsForFutures](Stored Procedures/Trade.GetInstrumentMarginsForFutures.md) | 8.5 | Done (Batch 32, #1) |
| [Trade.GetInstrumentPrecision](Stored Procedures/Trade.GetInstrumentPrecision.md) | 8.8 | Done (Batch 32, #2) |
| [Trade.GetInstrumentsAndInstrumentsGroups](Stored Procedures/Trade.GetInstrumentsAndInstrumentsGroups.md) | 8.2 | Done (Batch 32, #3) |
| [Trade.GetInstrumentsByExchangeIds](Stored Procedures/Trade.GetInstrumentsByExchangeIds.md) | 8.5 | Done (Batch 32, #4) |
| [Trade.GetInstrumentsByOmeID](Stored Procedures/Trade.GetInstrumentsByOmeID.md) | 8.2 | Done (Batch 32, #5) |
| [Trade.GetInstrumentsData](Stored Procedures/Trade.GetInstrumentsData.md) | 8.5 | Done (Batch 32, #6) |
| [Trade.GetInstrumentsForDataApi](Stored Procedures/Trade.GetInstrumentsForDataApi.md) | 8.2 | Done (Batch 32, #7) |
| [Trade.GetInstrumentsForSevision](Stored Procedures/Trade.GetInstrumentsForSevision.md) | 8.2 | Done (Batch 32, #8) |
| [Trade.GetInstrumentsGroupsWithDescriptions](Stored Procedures/Trade.GetInstrumentsGroupsWithDescriptions.md) | 7.8 | Done (Batch 32, #9) |
| [Trade.GetInstrumentShardingMap](Stored Procedures/Trade.GetInstrumentShardingMap.md) | 8.0 | Done (Batch 32, #10) |
| [Trade.GetInstrumentSlippage](Stored Procedures/Trade.GetInstrumentSlippage.md) | 8.5 | Done (Batch 32, #11) |
| [Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds](Stored Procedures/Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds.md) | 8.2 | Done (Batch 32, #12) |
| [Trade.GetInstrumentsRates](Stored Procedures/Trade.GetInstrumentsRates.md) | 9.0 | Done (Batch 32, #13) |
| [Trade.GetInstrumentsRateSourceAllocationsByExchangeIds](Stored Procedures/Trade.GetInstrumentsRateSourceAllocationsByExchangeIds.md) | 8.2 | Done (Batch 32, #14) |
| [Trade.GetInstrumentsTimeframeID](Stored Procedures/Trade.GetInstrumentsTimeframeID.md) | 8.0 | Done (Batch 32, #15) |
| [Trade.GetInstrumentsUpdatableDataForOpsAPI](Stored Procedures/Trade.GetInstrumentsUpdatableDataForOpsAPI.md) | 8.5 | Done (Batch 32, #16) |
| [Trade.GetInstrumentSymbolFull](Stored Procedures/Trade.GetInstrumentSymbolFull.md) | 8.0 | Done (Batch 32, #17) |
| [Trade.GetInstrumentToFeeConfiguration](Stored Procedures/Trade.GetInstrumentToFeeConfiguration.md) | 8.2 | Done (Batch 32, #18) |
| [Trade.GetInstrumentToTickerMapping](Stored Procedures/Trade.GetInstrumentToTickerMapping.md) | 8.0 | Done (Batch 32, #19) |
| [Trade.GetInstrumentType](Stored Procedures/Trade.GetInstrumentType.md) | 7.8 | Done (Batch 32, #20) |
| [Trade.GetInstrumentWithSpread](Stored Procedures/Trade.GetInstrumentWithSpread.md) | 8.5 | Done (Batch 32, #21) |
| [Trade.GetInterestDaily_for_Azure](Stored Procedures/Trade.GetInterestDaily_for_Azure.md) | 8.8 | Done (Batch 32, #22) |
| [Trade.GetInterestRateOverrides](Stored Procedures/Trade.GetInterestRateOverrides.md) | 8.5 | Done (Batch 32, #23) |
| [Trade.GetInterestRateOverrides_TRDOPS](Stored Procedures/Trade.GetInterestRateOverrides_TRDOPS.md) | 8.7 | Done (Batch 32, #24) |
| [Trade.GetInternalLeveragesWhiteList](Stored Procedures/Trade.GetInternalLeveragesWhiteList.md) | 8.0 | Done (Batch 32, #25) |
| [Trade.GetInvalidDividendsByCorrection](Stored Procedures/Trade.GetInvalidDividendsByCorrection.md) | 8.5 | Done (Batch 33) |
| [Trade.GetIsRedeemAllowed](Stored Procedures/Trade.GetIsRedeemAllowed.md) | 8.2 | Done (Batch 33) |
| [Trade.GetLastPriceRateID](Stored Procedures/Trade.GetLastPriceRateID.md) | 8.0 | Done (Batch 33) |
| [Trade.GetLeverageRestrictionsByCid](Stored Procedures/Trade.GetLeverageRestrictionsByCid.md) | 8.5 | Done (Batch 33) |
| [Trade.GetLeveragesRestrictionsWhiteList](Stored Procedures/Trade.GetLeveragesRestrictionsWhiteList.md) | 8.2 | Done (Batch 33) |
| [Trade.GetLeveragesWhiteListUsersDistinctGcidsList](Stored Procedures/Trade.GetLeveragesWhiteListUsersDistinctGcidsList.md) | 8.0 | Done (Batch 33) |
| [Trade.GetLivePositionWithPartialCloseData](Stored Procedures/Trade.GetLivePositionWithPartialCloseData.md) | 8.8 | Done (Batch 33) |
| [Trade.GetLoadedInstrumentsForCommission](Stored Procedures/Trade.GetLoadedInstrumentsForCommission.md) | 8.2 | Done (Batch 33) |
| [Trade.GetMarketRangeValidationTypes](Stored Procedures/Trade.GetMarketRangeValidationTypes.md) | 8.0 | Done (Batch 33) |
| [Trade.GetMaxAmountToWithdraw](Stored Procedures/Trade.GetMaxAmountToWithdraw.md) | 8.8 | Done (Batch 33) |
| [Trade.GetMaxLeverageByInstrumentForExposureForCID](Stored Procedures/Trade.GetMaxLeverageByInstrumentForExposureForCID.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMinCopyPositonAmountMaintenanceFeatureValues](Stored Procedures/Trade.GetMinCopyPositonAmountMaintenanceFeatureValues.md) | 8.0 | Done (Batch 30) |
| [Trade.GetMirrorAllStocksOrders](Stored Procedures/Trade.GetMirrorAllStocksOrders.md) | 8.0 | Done (Batch 33) |
| [Trade.GetMirrorCloseSagaByID](Stored Procedures/Trade.GetMirrorCloseSagaByID.md) | 8.2 | Done (Batch 33) |
| [Trade.GetMirrorCloseSagasByModAndResult](Stored Procedures/Trade.GetMirrorCloseSagasByModAndResult.md) | 8.2 | Done (Batch 33) |
| [Trade.GetMirrorData](Stored Procedures/Trade.GetMirrorData.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorDataByMirrorID](Stored Procedures/Trade.GetMirrorDataByMirrorID.md) | 8.2 | Done (Batch 33) |
| [Trade.GetMirrorDataWithCIDAndMirrorIdForAPI](Stored Procedures/Trade.GetMirrorDataWithCIDAndMirrorIdForAPI.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorDataWithCIDAndMirrorIdForSSE](Stored Procedures/Trade.GetMirrorDataWithCIDAndMirrorIdForSSE.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorDataWithCIDForAPI](Stored Procedures/Trade.GetMirrorDataWithCIDForAPI.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorEquity](Stored Procedures/Trade.GetMirrorEquity.md) | 8.0 | Done (Batch 33) |
| [Trade.GetMirrorEquityData](Stored Procedures/Trade.GetMirrorEquityData.md) | 8.8 | Done (Batch 33) |
| [Trade.GetMirrorEquityDataInnerMOT](Stored Procedures/Trade.GetMirrorEquityDataInnerMOT.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorHierarchy](Stored Procedures/Trade.GetMirrorHierarchy.md) | 8.8 | Done (Batch 33) |
| [Trade.GetMirrorHierarchyExcludeOpenedPositions](Stored Procedures/Trade.GetMirrorHierarchyExcludeOpenedPositions.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorHierarchyIncludeOpenedPositions](Stored Procedures/Trade.GetMirrorHierarchyIncludeOpenedPositions.md) | 8.5 | Done (Batch 33) |
| [Trade.GetMirrorNonStocksPositions](Stored Procedures/Trade.GetMirrorNonStocksPositions.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMirrorOrderIdForSSEDetach](Stored Procedures/Trade.GetMirrorOrderIdForSSEDetach.md) | 7.5 | Done (Batch 34) |
| [Trade.GetMirrorParentUserName](Stored Procedures/Trade.GetMirrorParentUserName.md) | 7.5 | Done (Batch 34) |
| [Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE](Stored Procedures/Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE.md) | 7.5 | Done (Batch 34) |
| [Trade.GetMirrorPositionData](Stored Procedures/Trade.GetMirrorPositionData.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMirrorPositionsForDetach](Stored Procedures/Trade.GetMirrorPositionsForDetach.md) | 7.5 | Done (Batch 34) |
| [Trade.GetMirrorRegisterData](Stored Procedures/Trade.GetMirrorRegisterData.md) | 8.5 | Done (Batch 34) |
| [Trade.GetMirrorsByCID](Stored Procedures/Trade.GetMirrorsByCID.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMirrorState](Stored Procedures/Trade.GetMirrorState.md) | 8.0 | Done (Batch 34) |
| [Trade.GetMirrorStocksOrders](Stored Procedures/Trade.GetMirrorStocksOrders.md) | 7.5 | Done (Batch 34) |
| [Trade.GetMirrorStocksPositionsIDs](Stored Procedures/Trade.GetMirrorStocksPositionsIDs.md) | 8.0 | Done (Batch 34) |
| [Trade.GetMirrorStopLossData](Stored Procedures/Trade.GetMirrorStopLossData.md) | 7.5 | Done (Batch 34) |
| [Trade.GetMirrorTypesValidationsDefaults](Stored Procedures/Trade.GetMirrorTypesValidationsDefaults.md) | 8.0 | Done (Batch 34) |
| [Trade.GetMirrorValidation](Stored Procedures/Trade.GetMirrorValidation.md) | 8.2 | Done (Batch 34) |
| [Trade.GetMirrorValidationRulesXML](Stored Procedures/Trade.GetMirrorValidationRulesXML.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMostPopularInstrumentsForAPI](Stored Procedures/Trade.GetMostPopularInstrumentsForAPI.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMSLInstrumentsData](Stored Procedures/Trade.GetMSLInstrumentsData.md) | 8.0 | Done (Batch 34) |
| [Trade.GetMSLMirrorData](Stored Procedures/Trade.GetMSLMirrorData.md) | 8.0 | Done (Batch 34) |
| [Trade.GetMSLPositionData](Stored Procedures/Trade.GetMSLPositionData.md) | 8.2 | Done (Batch 34) |
| [Trade.GetMSLSpreadGroups](Stored Procedures/Trade.GetMSLSpreadGroups.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMSLStocksOrders](Stored Procedures/Trade.GetMSLStocksOrders.md) | 7.8 | Done (Batch 34) |
| [Trade.GetMultiMirrorsData](Stored Procedures/Trade.GetMultiMirrorsData.md) | 8.0 | Done (Batch 34) |
| [Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection](Stored Procedures/Trade.GetNetOpenPositionDollarValueByInstrumentPerDirection.md) | 8.2 | Done (Batch 34) |
| [Trade.GetNumberOfInstrumentOpenPositions](Stored Procedures/Trade.GetNumberOfInstrumentOpenPositions.md) | 8.0 | Done (Batch 34) |
| [Trade.GetOpenCustomerTradesForInstrument](Stored Procedures/Trade.GetOpenCustomerTradesForInstrument.md) | 7.8 | Done (Batch 34) |
| [Trade.GetOpenExecutionPlan](Stored Procedures/Trade.GetOpenExecutionPlan.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOpenMirrorIDSByParentCID](Stored Procedures/Trade.GetOpenMirrorIDSByParentCID.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOpenOrderExecutedUnits](Stored Procedures/Trade.GetOpenOrderExecutedUnits.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOpenOrdersForCloseMirror](Stored Procedures/Trade.GetOpenOrdersForCloseMirror.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOpenPositionActionTypes](Stored Procedures/Trade.GetOpenPositionActionTypes.md) | 8.2 | Done (Batch 35) |
| [Trade.GetOpenPositionData](Stored Procedures/Trade.GetOpenPositionData.md) | 8.5 | Done (Batch 35) |
| [Trade.GetOpenPositions](Stored Procedures/Trade.GetOpenPositions.md) | 7.5 | Done (Batch 35) |
| [Trade.GetOpenPositionsData](Stored Procedures/Trade.GetOpenPositionsData.md) | 8.5 | Done (Batch 35) |
| [Trade.GetOpenPositionsFromTimestamp](Stored Procedures/Trade.GetOpenPositionsFromTimestamp.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOpenPositionsFromTimestamp_ByRowVersion](Stored Procedures/Trade.GetOpenPositionsFromTimestamp_ByRowVersion.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOpenTradesCopiedCount](Stored Procedures/Trade.GetOpenTradesCopiedCount.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOrderDetails](Stored Procedures/Trade.GetOrderDetails.md) | 7.5 | Done (Batch 35) |
| [Trade.GetOrderEntry](Stored Procedures/Trade.GetOrderEntry.md) | 7.5 | Done (Batch 35) |
| [Trade.GetOrderExit](Stored Procedures/Trade.GetOrderExit.md) | 7.5 | Done (Batch 35) |
| [Trade.GetOrderForClose](Stored Procedures/Trade.GetOrderForClose.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOrderForCloseContextData](Stored Procedures/Trade.GetOrderForCloseContextData.md) | 8.5 | Done (Batch 35) |
| [Trade.GetOrderForCloseContextData_EladTest](Stored Procedures/Trade.GetOrderForCloseContextData_EladTest.md) | 7.0 | Done (Batch 35) |
| [Trade.GetOrderForCloseInfo](Stored Procedures/Trade.GetOrderForCloseInfo.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOrderForCloseOvt](Stored Procedures/Trade.GetOrderForCloseOvt.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOrderForClosePositionsOvt](Stored Procedures/Trade.GetOrderForClosePositionsOvt.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOrderForOpen](Stored Procedures/Trade.GetOrderForOpen.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOrderForOpenContextData](Stored Procedures/Trade.GetOrderForOpenContextData.md) | 8.5 | Done (Batch 35) |
| [Trade.GetOrderForOpenIdsForCloseMirror](Stored Procedures/Trade.GetOrderForOpenIdsForCloseMirror.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOrderForOpenInfo](Stored Procedures/Trade.GetOrderForOpenInfo.md) | 7.8 | Done (Batch 35) |
| [Trade.GetOrderForOpenOvt](Stored Procedures/Trade.GetOrderForOpenOvt.md) | 8.0 | Done (Batch 35) |
| [Trade.GetOrderForOpenPositionsOvt](Stored Procedures/Trade.GetOrderForOpenPositionsOvt.md) | 7.8 | Done (Batch 36) |
| [Trade.GetOrderHierarchy](Stored Procedures/Trade.GetOrderHierarchy.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest.md) | 7.0 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV](Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentIDAndModDIV.md) | 8.5 | Done (Batch 36) |
| [Trade.GetOrdersByInstrumentIDAndModDIV](Stored Procedures/Trade.GetOrdersByInstrumentIDAndModDIV.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersDataWithCIDAndOrderIdForAPI](Stored Procedures/Trade.GetOrdersDataWithCIDAndOrderIdForAPI.md) | 7.8 | Done (Batch 36) |
| [Trade.GetOrdersDataWithCIDForAPI](Stored Procedures/Trade.GetOrdersDataWithCIDForAPI.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersEntryByInstrumentIDAndModDIV ](Stored Procedures/Trade.GetOrdersEntryByInstrumentIDAndModDIV.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersEntryClosedNotification](Stored Procedures/Trade.GetOrdersEntryClosedNotification.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI](Stored Procedures/Trade.GetOrdersEntryDataWithCIDAndOrderIdForAPI.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrdersEntryDataWithCIDForAPI](Stored Procedures/Trade.GetOrdersEntryDataWithCIDForAPI.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersEntryForMirror](Stored Procedures/Trade.GetOrdersEntryForMirror.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersExitByInstrumentIDAndModDIV](Stored Procedures/Trade.GetOrdersExitByInstrumentIDAndModDIV.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI](Stored Procedures/Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersExitDataWithCIDForAPI](Stored Procedures/Trade.GetOrdersExitDataWithCIDForAPI.md) | 7.5 | Done (Batch 36) |
| [Trade.GetOrdersForDataApi](Stored Procedures/Trade.GetOrdersForDataApi.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrdersForExecutionReport](Stored Procedures/Trade.GetOrdersForExecutionReport.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrdersForExecutionReportDrillDown](Stored Procedures/Trade.GetOrdersForExecutionReportDrillDown.md) | 8.0 | Done (Batch 36) |
| [Trade.GetOrdersForExecutionReportDrillDownTest](Stored Procedures/Trade.GetOrdersForExecutionReportDrillDownTest.md) | 8.7 | Done (Batch 37) |
| [Trade.GetOrdersForExecutionReportTest](Stored Procedures/Trade.GetOrdersForExecutionReportTest.md) | 8.0 | Done (Batch 37) |
| [Trade.GetOrdersForExecutionReportV2](Stored Procedures/Trade.GetOrdersForExecutionReportV2.md) | 8.5 | Done (Batch 37) |
| [Trade.GetOrdersForExecutionReportV2_JUNK](Stored Procedures/Trade.GetOrdersForExecutionReportV2_JUNK.md) | 8.2 | Done (Batch 37) |
| [Trade.GetOrdersForExecutionReportV3Junk](Stored Procedures/Trade.GetOrdersForExecutionReportV3Junk.md) | 8.5 | Done (Batch 37) |
| [Trade.GetOrphanedPositionsData](Stored Procedures/Trade.GetOrphanedPositionsData.md) | 8.8 | Done (Batch 37) |
| [Trade.GetOrphanedPositionsDataTest](Stored Procedures/Trade.GetOrphanedPositionsDataTest.md) | 8.5 | Done (Batch 37) |
| [Trade.GetParentCIDByMirrorID](Stored Procedures/Trade.GetParentCIDByMirrorID.md) | 7.5 | Done (Batch 37) |
| [Trade.GetParentPositionsFromSpecificID](Stored Procedures/Trade.GetParentPositionsFromSpecificID.md) | 7.0 | Done (Batch 37) |
| [Trade.GetParentPositionWithMirrorData](Stored Procedures/Trade.GetParentPositionWithMirrorData.md) | 8.8 | Done (Batch 37) |
| [Trade.GetPartitionDrawDownActiveCustomers](Stored Procedures/Trade.GetPartitionDrawDownActiveCustomers.md) | 8.5 | Done (Batch 37) |
| [Trade.GetPayedDividendsAndPositions](Stored Procedures/Trade.GetPayedDividendsAndPositions.md) | 8.5 | Done (Batch 37) |
| [Trade.GetPendingOrders](Stored Procedures/Trade.GetPendingOrders.md) | 7.8 | Done (Batch 37) |
| [Trade.GetPercisionsAndType](Stored Procedures/Trade.GetPercisionsAndType.md) | 7.5 | Done (Batch 37) |
| [Trade.GetPlacedOrdersForCloseByPositionId](Stored Procedures/Trade.GetPlacedOrdersForCloseByPositionId.md) | 8.0 | Done (Batch 37) |
| [Trade.GetPortfolioAggregates](Stored Procedures/Trade.GetPortfolioAggregates.md) | 9.2 | Done (Batch 37) |
| [Trade.GetPositionCountForCID](Stored Procedures/Trade.GetPositionCountForCID.md) | 7.5 | Done (Batch 37) |
| [Trade.GetPositionDataForAllocation](Stored Procedures/Trade.GetPositionDataForAllocation.md) | 8.5 | Done (Batch 37) |
| [Trade.GetPositionDataFromReal](Stored Procedures/Trade.GetPositionDataFromReal.md) | 8.5 | Done (Batch 37) |
| [Trade.GetPositionHierarchy](Stored Procedures/Trade.GetPositionHierarchy.md) | 8.8 | Done (Batch 37) |
| [Trade.GetPositionHierarchy_Rollback](Stored Procedures/Trade.GetPositionHierarchy_Rollback.md) | 7.8 | Done (Batch 37) |
| [Trade.GetPositionsBreakdownForDataApi](Stored Procedures/Trade.GetPositionsBreakdownForDataApi.md) | 8.8 | Done (Batch 37) |
| [Trade.GetPositionsByFilters](Stored Procedures/Trade.GetPositionsByFilters.md) | 9.0 | Done (Batch 37) |
| [Trade.GetPositionsByInstrumentIDAndModDIV](Stored Procedures/Trade.GetPositionsByInstrumentIDAndModDIV.md) | 8.5 | Done (Batch 37) |
| [Trade.GetPositionsByTimeRange](Stored Procedures/Trade.GetPositionsByTimeRange.md) | 8.0 | Done (Batch 37) |
| [Trade.GetPositionsChangesForDataApi](Stored Procedures/Trade.GetPositionsChangesForDataApi.md) | 8.5 | Done (Batch 38) |
| [Trade.GetPositionsCountForMirrorsInAlignment](Stored Procedures/Trade.GetPositionsCountForMirrorsInAlignment.md) | 8.2 | Done (Batch 38) |
| [Trade.GetPositionsDataForCloseMirror](Stored Procedures/Trade.GetPositionsDataForCloseMirror.md) | 8.5 | Done (Batch 38) |
| [Trade.GetPositionsDataWithCIDAndPositionIdForAPI](Stored Procedures/Trade.GetPositionsDataWithCIDAndPositionIdForAPI.md) | 9.2 | Done (Batch 38) |
| [Trade.GetPositionsDataWithCIDForAPI](Stored Procedures/Trade.GetPositionsDataWithCIDForAPI.md) | 9.2 | Done (Batch 38) |
| [Trade.GetPositionsForCloseMirror](Stored Procedures/Trade.GetPositionsForCloseMirror.md) | 8.8 | Done (Batch 38) |
| [Trade.GetPositionsForCloseMirrorMot](Stored Procedures/Trade.GetPositionsForCloseMirrorMot.md) | 8.8 | Done (Batch 38) |
| [Trade.GetPositionsForDataApi](Stored Procedures/Trade.GetPositionsForDataApi.md) | 8.8 | Done (Batch 38) |
| [Trade.GetPositionsForDividendSnapshot](Stored Procedures/Trade.GetPositionsForDividendSnapshot.md) | 9.0 | Done (Batch 38) |
| [Trade.GetPositionsForFeeBulkGeneral](Stored Procedures/Trade.GetPositionsForFeeBulkGeneral.md) | 9.0 | Done (Batch 38) |
| [Trade.GetPositionsForFeeBulkGeneral_Aus](Stored Procedures/Trade.GetPositionsForFeeBulkGeneral_Aus.md) | 9.0 | Done (Batch 38) |
| [Trade.GetPositionsForFeeProcess](Stored Procedures/Trade.GetPositionsForFeeProcess.md) | 8.8 | Done (Batch 38) |
| [Trade.GetPositionsTree](Stored Procedures/Trade.GetPositionsTree.md) | 8.8 | Done (Batch 38) |
| [Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk](Stored Procedures/Trade.GetPositionThatShouldBeOpenedByParentID_DEBUGJunk.md) | 7.5 | Done (Batch 38) |
| [Trade.GetPriceLatency](Stored Procedures/Trade.GetPriceLatency.md) | 8.8 | Done (Batch 38) |
| [Trade.GetProviderInstrumentsByExchangeIds](Stored Procedures/Trade.GetProviderInstrumentsByExchangeIds.md) | 8.5 | Done (Batch 38) |
| [Trade.GetProviderToInstrumentData](Stored Procedures/Trade.GetProviderToInstrumentData.md) | 8.8 | Done (Batch 38) |
| [Trade.GetPublicClientPortfolioForAPI](Stored Procedures/Trade.GetPublicClientPortfolioForAPI.md) | 8.5 | Done (Batch 38) |
| [Trade.GetPublicMirrorDataWithCIDForAPI](Stored Procedures/Trade.GetPublicMirrorDataWithCIDForAPI.md) | 8.5 | Done (Batch 38) |
| [Trade.GetPublicMirrorDataWithMirrorIdForAPI](Stored Procedures/Trade.GetPublicMirrorDataWithMirrorIdForAPI.md) | 8.2 | Done (Batch 38) |
| [Trade.GetPublicOrdersDataWithCIDForAPI](Stored Procedures/Trade.GetPublicOrdersDataWithCIDForAPI.md) | 8.0 | Done (Batch 38) |
| [Trade.GetPublicOrdersDataWithOrderIdForAPI](Stored Procedures/Trade.GetPublicOrdersDataWithOrderIdForAPI.md) | 8.0 | Done (Batch 38) |
| [Trade.GetPublicOrdersEntryDataWithCIDForAPI](Stored Procedures/Trade.GetPublicOrdersEntryDataWithCIDForAPI.md) | 8.0 | Done (Batch 38) |
| [Trade.GetPublicOrdersEntryDataWithOrderIdForAPI](Stored Procedures/Trade.GetPublicOrdersEntryDataWithOrderIdForAPI.md) | 8.0 | Done (Batch 38) |
| [Trade.GetPublicOrdersExitDataWithCIDForAPI](Stored Procedures/Trade.GetPublicOrdersExitDataWithCIDForAPI.md) | 8.2 | Done (Batch 38) |
| [Trade.GetPublicOrdersExitDataWithOrderIdForAPI](Stored Procedures/Trade.GetPublicOrdersExitDataWithOrderIdForAPI.md) | 8.5 | Done (Batch 39) |
| [Trade.GetPublicPositionsDataWithCIDForAPI](Stored Procedures/Trade.GetPublicPositionsDataWithCIDForAPI.md) | 8.8 | Done (Batch 39) |
| [Trade.GetPublicPositionsDataWithPositionIdForAPI](Stored Procedures/Trade.GetPublicPositionsDataWithPositionIdForAPI.md) | 8.8 | Done (Batch 39) |
| [Trade.GetPublicStockOrdersDataWithCIDForAPI](Stored Procedures/Trade.GetPublicStockOrdersDataWithCIDForAPI.md) | 8.5 | Done (Batch 39) |
| [Trade.GetPublicStockOrdersDataWithOrderIdForAPI](Stored Procedures/Trade.GetPublicStockOrdersDataWithOrderIdForAPI.md) | 8.5 | Done (Batch 39) |
| [Trade.GetRankingGainPartitionActiveCustomers](Stored Procedures/Trade.GetRankingGainPartitionActiveCustomers.md) | 8.5 | Done (Batch 39) |
| [Trade.GetRateInDollarsForDividends](Stored Procedures/Trade.GetRateInDollarsForDividends.md) | 9.0 | Done (Batch 39) |
| [Trade.GetRealizedCustomersData](Stored Procedures/Trade.GetRealizedCustomersData.md) | 8.8 | Done (Batch 39) |
| [Trade.GetRebalancePositions](Stored Procedures/Trade.GetRebalancePositions.md) | 8.8 | Done (Batch 39) |
| [Trade.GetRestrictedForSettlmentCountryIds](Stored Procedures/Trade.GetRestrictedForSettlmentCountryIds.md) | 8.0 | Done (Batch 39) |
| [Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType](Stored Procedures/Trade.GetRestrictedForSettlmentCountryIdsByInstrumentType.md) | 8.5 | Done (Batch 39) |
| [Trade.GetRestrictionsByTradingOperationTypes](Stored Procedures/Trade.GetRestrictionsByTradingOperationTypes.md) | 9.2 | Done (Batch 39) |
| [Trade.GetRestrictionsByTradingOperationTypes_Debug](Stored Procedures/Trade.GetRestrictionsByTradingOperationTypes_Debug.md) | 8.5 | Done (Batch 39) |
| [Trade.GetRestrictionsByTradingOperationTypesTest](Stored Procedures/Trade.GetRestrictionsByTradingOperationTypesTest.md) | 8.5 | Done (Batch 39) |
| [Trade.GetRolloverFeeAlertThresholds](Stored Procedures/Trade.GetRolloverFeeAlertThresholds.md) | 8.5 | Done (Batch 39) |
| [Trade.GetRolloverFeeMarkups](Stored Procedures/Trade.GetRolloverFeeMarkups.md) | 8.2 | Done (Batch 39) |
| [Trade.GetSbrEvents](Stored Procedures/Trade.GetSbrEvents.md) | 9.0 | Done (Batch 39) |
| [Trade.GetSmartCopyRestrictions](Stored Procedures/Trade.GetSmartCopyRestrictions.md) | 9.0 | Done (Batch 39) |
| [Trade.GetSmartCopyRestrictions_TRDOPS](Stored Procedures/Trade.GetSmartCopyRestrictions_TRDOPS.md) | 8.8 | Done (Batch 39) |
| [Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI](Stored Procedures/Trade.GetStockOrdersDataWithCIDAndOrderIdForAPI.md) | 8.5 | Done (Batch 39) |
| [Trade.GetStockOrdersDataWithCIDForAPI](Stored Procedures/Trade.GetStockOrdersDataWithCIDForAPI.md) | 8.5 | Done (Batch 39) |
| [Trade.GetTradeActivityActionTypes](Stored Procedures/Trade.GetTradeActivityActionTypes.md) | 8.5 | Done (Batch 39) |
| [Trade.GetTraderDisplayableInstrumentDataForAPI](Stored Procedures/Trade.GetTraderDisplayableInstrumentDataForAPI.md) | 8.5 | Done (Batch 39) |
| [Trade.GetTradingDATAforCopyFund](Stored Procedures/Trade.GetTradingDATAforCopyFund.md) | 9.0 | Done (Batch 39) |
| [Trade.GetTradingRiskStatus](Stored Procedures/Trade.GetTradingRiskStatus.md) | 9.0 | Done (Batch 39) |
| [Trade.GetTreeNodesByParentCID](Stored Procedures/Trade.GetTreeNodesByParentCID.md) | 8.5 | Done (Batch 40) |
| [Trade.GetTreeNodesByParentCID_Inner](Stored Procedures/Trade.GetTreeNodesByParentCID_Inner.md) | 8.8 | Done (Batch 40) |
| [Trade.GetTreeNodesByParentCID_InnerDebugJunk](Stored Procedures/Trade.GetTreeNodesByParentCID_InnerDebugJunk.md) | 8.0 | Done (Batch 40) |
| [Trade.GetTreeNodesByParentCIDDebug](Stored Procedures/Trade.GetTreeNodesByParentCIDDebug.md) | 7.5 | Done (Batch 40) |
| [Trade.GetTreeNodesByParentPositionAndTreeId](Stored Procedures/Trade.GetTreeNodesByParentPositionAndTreeId.md) | 8.8 | Done (Batch 40) |
| [Trade.GetTreeNodesByParentPositionAndTreeIdTest](Stored Procedures/Trade.GetTreeNodesByParentPositionAndTreeIdTest.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUnrealizedCustomersData](Stored Procedures/Trade.GetUnrealizedCustomersData.md) | 8.5 | Done (Batch 40) |
| [Trade.GetUserAndPositionData](Stored Procedures/Trade.GetUserAndPositionData.md) | 9.0 | Done (Batch 40) |
| [Trade.GetUserData](Stored Procedures/Trade.GetUserData.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUserEquityData](Stored Procedures/Trade.GetUserEquityData.md) | 9.0 | Done (Batch 40) |
| [Trade.GetUserEquityDataInnerMOT](Stored Procedures/Trade.GetUserEquityDataInnerMOT.md) | 9.0 | Done (Batch 40) |
| [Trade.GetUserInfo](Stored Procedures/Trade.GetUserInfo.md) | 9.0 | Done (Batch 40) |
| [Trade.GetUserInfoByGCIDs](Stored Procedures/Trade.GetUserInfoByGCIDs.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUserInfoForFee](Stored Procedures/Trade.GetUserInfoForFee.md) | 8.2 | Done (Batch 40) |
| [Trade.GetUserInfoSlim](Stored Procedures/Trade.GetUserInfoSlim.md) | 8.5 | Done (Batch 40) |
| [Trade.GetUserInfoWithCopyRestirctions](Stored Procedures/Trade.GetUserInfoWithCopyRestirctions.md) | 9.0 | Done (Batch 40) |
| [Trade.GetUserInstrumentIdsOnly](Stored Procedures/Trade.GetUserInstrumentIdsOnly.md) | 9.0 | Done (Batch 40) |
| [Trade.GetUserOpenPositionIDS](Stored Procedures/Trade.GetUserOpenPositionIDS.md) | 8.5 | Done (Batch 40) |
| [Trade.GetUserRegulationsByBatch](Stored Procedures/Trade.GetUserRegulationsByBatch.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUsersDataByFilters](Stored Procedures/Trade.GetUsersDataByFilters.md) | 8.5 | Done (Batch 40) |
| [Trade.GetUsersFromBSLTables](Stored Procedures/Trade.GetUsersFromBSLTables.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUsersUnrealizedEquityData](Stored Procedures/Trade.GetUsersUnrealizedEquityData.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUsersUnrealizedEquityDataJunk](Stored Procedures/Trade.GetUsersUnrealizedEquityDataJunk.md) | 8.2 | Done (Batch 40) |
| [Trade.GetUserTradeStatusData](Stored Procedures/Trade.GetUserTradeStatusData.md) | 8.8 | Done (Batch 40) |
| [Trade.GetUserWithRestirctions](Stored Procedures/Trade.GetUserWithRestirctions.md) | 9.2 | Done (Batch 40) |
| [Trade.GetUsRegulationIds](Stored Procedures/Trade.GetUsRegulationIds.md) | 8.5 | Done (Batch 41) |
| [Trade.GetUsTerritoriesCountryIds](Stored Procedures/Trade.GetUsTerritoriesCountryIds.md) | 8.2 | Done (Batch 41) |
| [Trade.GetVirtualHumanAllocations](Stored Procedures/Trade.GetVirtualHumanAllocations.md) | 8.2 | Done (Batch 41) |
| [Trade.GetVirtualOpenPositions](Stored Procedures/Trade.GetVirtualOpenPositions.md) | 8.5 | Done (Batch 41) |
| [Trade.HedgeClose](Stored Procedures/Trade.HedgeClose.md) | 9.0 | Done (Batch 41) |
| [Trade.HedgeCloseRequestAdd](Stored Procedures/Trade.HedgeCloseRequestAdd.md) | 8.8 | Done (Batch 41) |
| [Trade.HedgeCloseRequestAdd_Original](Stored Procedures/Trade.HedgeCloseRequestAdd_Original.md) | 8.0 | Done (Batch 41) |
| [Trade.HedgeEditStopLost](Stored Procedures/Trade.HedgeEditStopLost.md) | 8.0 | Done (Batch 41) |
| [Trade.HedgeEditTakeProfit](Stored Procedures/Trade.HedgeEditTakeProfit.md) | 8.0 | Done (Batch 41) |
| [Trade.HedgeExposureAndRequestQuery](Stored Procedures/Trade.HedgeExposureAndRequestQuery.md) | 8.5 | Done (Batch 41) |
| [Trade.HedgeExposureQuery](Stored Procedures/Trade.HedgeExposureQuery.md) | 8.8 | Done (Batch 41) |
| [Trade.HedgeExposureQuery_Org](Stored Procedures/Trade.HedgeExposureQuery_Org.md) | 8.5 | Done (Batch 41) |
| [Trade.HedgeExposureQueryWithActiveParent](Stored Procedures/Trade.HedgeExposureQueryWithActiveParent.md) | 8.8 | Done (Batch 41) |
| [Trade.HedgeExposureWithNoRequests](Stored Procedures/Trade.HedgeExposureWithNoRequests.md) | 8.8 | Done (Batch 41) |
| [Trade.HedgeExposureWithNoRequestsWithActiveParent](Stored Procedures/Trade.HedgeExposureWithNoRequestsWithActiveParent.md) | 8.5 | Done (Batch 41) |
| [Trade.HedgeOpen](Stored Procedures/Trade.HedgeOpen.md) | 9.0 | Done (Batch 41) |
| [Trade.HedgeOpenRequestAdd](Stored Procedures/Trade.HedgeOpenRequestAdd.md) | 8.8 | Done (Batch 41) |
| [Trade.HedgeRemove](Stored Procedures/Trade.HedgeRemove.md) | 9.0 | Done (Batch 41) |
| [Trade.HedgeRemoveAll](Stored Procedures/Trade.HedgeRemoveAll.md) | 8.2 | Done (Batch 41) |
| [Trade.HedgeRemoveDiff](Stored Procedures/Trade.HedgeRemoveDiff.md) | 8.2 | Done (Batch 41) |
| [Trade.HedgeRemoveFully](Stored Procedures/Trade.HedgeRemoveFully.md) | 8.2 | Done (Batch 41) |
| [Trade.HedgeRequestRemove](Stored Procedures/Trade.HedgeRequestRemove.md) | 8.0 | Done (Batch 41) |
| [Trade.HedgingCheckUsersEquity](Stored Procedures/Trade.HedgingCheckUsersEquity.md) | 8.8 | Done (Batch 41) |
| [Trade.IndexDividends_SetStatus](Stored Procedures/Trade.IndexDividends_SetStatus.md) | 8.5 | Done (Batch 41) |
| [Trade.IndexDividends24HoursEmailReport](Stored Procedures/Trade.IndexDividends24HoursEmailReport.md) | 8.8 | Done (Batch 41) |
| [Trade.IndexDividendsDaylyNotPaidEmailReport](Stored Procedures/Trade.IndexDividendsDaylyNotPaidEmailReport.md) | 8.0 | Done (Batch 42) |
| [Trade.IndexDividendsEmail](Stored Procedures/Trade.IndexDividendsEmail.md) | 8.2 | Done (Batch 42) |
| [Trade.InsertActiveCredit](Stored Procedures/Trade.InsertActiveCredit.md) | 8.2 | Done (Batch 42) |
| [Trade.InsertActiveCreditPartition](Stored Procedures/Trade.InsertActiveCreditPartition.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertAsyncRecord](Stored Procedures/Trade.InsertAsyncRecord.md) | 9.2 | Done (Batch 42) |
| [Trade.InsertBSLMessagesIntoQueue](Stored Procedures/Trade.InsertBSLMessagesIntoQueue.md) | 9.0 | Done (Batch 42) |
| [Trade.InsertCopyTradeSettlementRestrictions](Stored Procedures/Trade.InsertCopyTradeSettlementRestrictions.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertCopyTradeSettlementRestrictions_TRDOPS](Stored Procedures/Trade.InsertCopyTradeSettlementRestrictions_TRDOPS.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertDividend](Stored Procedures/Trade.InsertDividend.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertEventsIntoSbrQueueTable](Stored Procedures/Trade.InsertEventsIntoSbrQueueTable.md) | 7.5 | Done (Batch 21) |
| [Trade.InsertIndexDividend](Stored Procedures/Trade.InsertIndexDividend.md) | 9.0 | Done (Batch 42) |
| [Trade.InsertInstrumentDealing](Stored Procedures/Trade.InsertInstrumentDealing.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertInstrumentGroup](Stored Procedures/Trade.InsertInstrumentGroup.md) | 8.0 | Done (Batch 42) |
| [Trade.InsertInstrumentHalt](Stored Procedures/Trade.InsertInstrumentHalt.md) | 8.0 | Done (Batch 42) |
| [Trade.InsertInstrumentMarketData](Stored Procedures/Trade.InsertInstrumentMarketData.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertInstrumentMetaData](Stored Procedures/Trade.InsertInstrumentMetaData.md) | 9.0 | Done (Batch 42) |
| [Trade.InsertInstrumentMetadataSecurityOpsAPI](Stored Procedures/Trade.InsertInstrumentMetadataSecurityOpsAPI.md) | 9.0 | Done (Batch 42) |
| [Trade.InsertInstrumentRealTable](Stored Procedures/Trade.InsertInstrumentRealTable.md) | 8.8 | Done (Batch 42) |
| [Trade.InsertInstrumentTradingData](Stored Procedures/Trade.InsertInstrumentTradingData.md) | 8.8 | Done (Batch 42) |
| [Trade.InsertInterestWhitelist](Stored Procedures/Trade.InsertInterestWhitelist.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertIntoBSLUsersWhiteList](Stored Procedures/Trade.InsertIntoBSLUsersWhiteList.md) | 8.5 | Done (Batch 42) |
| [Trade.InsertLeveragesRestrictionsWhiteList](Stored Procedures/Trade.InsertLeveragesRestrictionsWhiteList.md) | 8.2 | Done (Batch 42) |
| [Trade.InsertLiquidityProviderContract](Stored Procedures/Trade.InsertLiquidityProviderContract.md) | 8.8 | Done (Batch 42) |
| [Trade.InsertMostPopularInstruments](Stored Procedures/Trade.InsertMostPopularInstruments.md) | 9.0 | Done (Batch 42) |
| [Trade.InsertMultipleIndexDividends](Stored Procedures/Trade.InsertMultipleIndexDividends.md) | 8.8 | Done (Batch 42) |
| [Trade.InsertNewTradingResourceDefault](Stored Procedures/Trade.InsertNewTradingResourceDefault.md) | 9.0 | Done (Batch 42) |
| [Trade.InsertRebalanceRequests](Stored Procedures/Trade.InsertRebalanceRequests.md) | 8.5 | Done (Batch 43) |
| [Trade.InsertSplitToPriceDB](Stored Procedures/Trade.InsertSplitToPriceDB.md) | 8.5 | Done (Batch 43) |
| [Trade.InsertSucssesPositionWithErrorToSbr](Stored Procedures/Trade.InsertSucssesPositionWithErrorToSbr.md) | 8.8 | Done (Batch 43) |
| [Trade.InsertTradingInstrumentGroupName](Stored Procedures/Trade.InsertTradingInstrumentGroupName.md) | 8.5 | Done (Batch 43) |
| [Trade.InsertTradonomiContactDailySchedule](Stored Procedures/Trade.InsertTradonomiContactDailySchedule.md) | 8.8 | Done (Batch 43) |
| [Trade.InsertTradonomyContract](Stored Procedures/Trade.InsertTradonomyContract.md) | 9.0 | Done (Batch 43) |
| [Trade.InsertTSLDataToSyncTbl](Stored Procedures/Trade.InsertTSLDataToSyncTbl.md) | 9.0 | Done (Batch 43) |
| [Trade.InstrumentAdd](Stored Procedures/Trade.InstrumentAdd.md) | 9.0 | Done (Batch 43) |
| [Trade.InstrumentRateSourceAdd](Stored Procedures/Trade.InstrumentRateSourceAdd.md) | 9.0 | Done (Batch 43) |
| [Trade.InstrumentRateSourceDelete](Stored Procedures/Trade.InstrumentRateSourceDelete.md) | 8.5 | Done (Batch 43) |
| [Trade.InstrumentRateSourceEdit](Stored Procedures/Trade.InstrumentRateSourceEdit.md) | 8.5 | Done (Batch 43) |
| [Trade.InstrumentTypesAndCountriesForCFDFee](Stored Procedures/Trade.InstrumentTypesAndCountriesForCFDFee.md) | 8.5 | Done (Batch 43) |
| [Trade.InterestGetDailyRawData](Stored Procedures/Trade.InterestGetDailyRawData.md) | 9.0 | Done (Batch 43) |
| [Trade.InterestGetDailyRawDataHistorical](Stored Procedures/Trade.InterestGetDailyRawDataHistorical.md) | 9.0 | Done (Batch 43) |
| [Trade.InterestGetDailyRawDataNEWELAD](Stored Procedures/Trade.InterestGetDailyRawDataNEWELAD.md) | 8.5 | Done (Batch 43) |
| [Trade.InterestGetDailyRawDataTest](Stored Procedures/Trade.InterestGetDailyRawDataTest.md) | 8.5 | Done (Batch 43) |
| [Trade.IsAccountInLiquidationWhitelist](Stored Procedures/Trade.IsAccountInLiquidationWhitelist.md) | 8.5 | Done (Batch 43) |
| [Trade.IsCIDInLiquidation](Stored Procedures/Trade.IsCIDInLiquidation.md) | 8.5 | Done (Batch 43) |
| [Trade.IsCopying](Stored Procedures/Trade.IsCopying.md) | 8.5 | Done (Batch 43) |
| [Trade.IsCreateLoop](Stored Procedures/Trade.IsCreateLoop.md) | 9.0 | Done (Batch 43) |
| [Trade.IsMSLRatesEqualsToEndForexRate](Stored Procedures/Trade.IsMSLRatesEqualsToEndForexRate.md) | 9.0 | Done (Batch 43) |
| [Trade.IsMSLRatesEqualsToEndForexRateV2](Stored Procedures/Trade.IsMSLRatesEqualsToEndForexRateV2.md) | 8.8 | Done (Batch 43) |
| [Trade.IsNewPositionOrphan](Stored Procedures/Trade.IsNewPositionOrphan.md) | 9.0 | Done (Batch 43) |
| [Trade.IsOrderForCloseClosed](Stored Procedures/Trade.IsOrderForCloseClosed.md) | 9.0 | Done (Batch 43) |
| [Trade.IsOrderForOpenClosed](Stored Procedures/Trade.IsOrderForOpenClosed.md) | 9.0 | Done (Batch 43) |
| [Trade.Job_GenerateFundAllocation](Stored Procedures/Trade.Job_GenerateFundAllocation.md) | 8.5 | Done (Batch 44) |
| [Trade.JUNK_ChangeMirrorAmount](Stored Procedures/Trade.JUNK_ChangeMirrorAmount.md) | 8.8 | Done (Batch 44) |
| [Trade.ManualModifySLForCriptoPositions](Stored Procedures/Trade.ManualModifySLForCriptoPositions.md) | 8.8 | Done (Batch 45) |
| [Trade.ManualPositionClose](Stored Procedures/Trade.ManualPositionClose.md) | 9.0 | Done (Batch 22) |
| [Trade.ManualPositionClose_Casing](Stored Procedures/Trade.ManualPositionClose_Casing.md) | 8.5 | Done (Batch 44) |
| [Trade.ManualPositionClose_Crisis](Stored Procedures/Trade.ManualPositionClose_Crisis.md) | 9.0 | Done (Batch 22) |
| [Trade.ManualPositionStopLoss](Stored Procedures/Trade.ManualPositionStopLoss.md) | 8.8 | Done (Batch 45) |
| [Trade.ManualPositionTakeProfit](Stored Procedures/Trade.ManualPositionTakeProfit.md) | 8.8 | Done (Batch 45) |
| [Trade.ManualRenlance](Stored Procedures/Trade.ManualRenlance.md) | 8.8 | Done (Batch 44) |
| [Trade.MarkDividendPositionAsPaid](Stored Procedures/Trade.MarkDividendPositionAsPaid.md) | 8.8 | Done (Batch 44) |
| [Trade.MarkTradonomiContractAsActive](Stored Procedures/Trade.MarkTradonomiContractAsActive.md) | 8.8 | Done (Batch 44) |
| [Trade.MatchInstrumentIDToTickerName](Stored Procedures/Trade.MatchInstrumentIDToTickerName.md) | 8.8 | Done (Batch 44) |
| [Trade.Merge_IndexDividends_DryRun](Stored Procedures/Trade.Merge_IndexDividends_DryRun.md) | 9.0 | Done (Batch 44) |
| [Trade.MigrateInstrument](Stored Procedures/Trade.MigrateInstrument.md) | 9.0 | Done (Batch 44) |
| [Trade.MirrorDividendWithdrawal](Stored Procedures/Trade.MirrorDividendWithdrawal.md) | 9.0 | Done (Batch 44) |
| [Trade.MirrorPauseCopy](Stored Procedures/Trade.MirrorPauseCopy.md) | 8.8 | Done (Batch 44) |
| [Trade.MirrorReopen](Stored Procedures/Trade.MirrorReopen.md) | 9.0 | Done (Batch 44) |
| [Trade.MirrorsReopen](Stored Procedures/Trade.MirrorsReopen.md) | 8.8 | Done (Batch 45) |
| [Trade.MirrorsStopLossToBeCompensatedByPercentageDiff](Stored Procedures/Trade.MirrorsStopLossToBeCompensatedByPercentageDiff.md) | 9.0 | Done (Batch 44) |
| [Trade.MovePositionsHedgeServers](Stored Procedures/Trade.MovePositionsHedgeServers.md) | 9.0 | Done (Batch 44) |
| [Trade.MovePositionsHedgeServersByRerouteService](Stored Procedures/Trade.MovePositionsHedgeServersByRerouteService.md) | 9.0 | Done (Batch 44) |
| [Trade.NewCheckBSL](Stored Procedures/Trade.NewCheckBSL.md) | 9.0 | Done (Batch 44) |
| [Trade.OmeCheck](Stored Procedures/Trade.OmeCheck.md) | 9.0 | Done (Batch 44) |
| [Trade.OpenOrdersSplit](Stored Procedures/Trade.OpenOrdersSplit.md) | 8.5 | Done (Batch 21) |
| [Trade.OrderEntryClose](Stored Procedures/Trade.OrderEntryClose.md) | 9.0 | Done (Batch 44) |
| [Trade.OrderEntryOpen](Stored Procedures/Trade.OrderEntryOpen.md) | 8.8 | Done (Batch 45) |
| [Trade.OrderExitClose](Stored Procedures/Trade.OrderExitClose.md) | 9.0 | Done (Batch 45) |
| [Trade.OrderExitEdit](Stored Procedures/Trade.OrderExitEdit.md) | 9.0 | Done (Batch 45) |
| [Trade.OrderExitOpen](Stored Procedures/Trade.OrderExitOpen.md) | 9.0 | Done (Batch 45) |
| [Trade.OrderForCloseCreate](Stored Procedures/Trade.OrderForCloseCreate.md) | 9.0 | Done (Batch 44) |
| [Trade.OrderForCloseJob](Stored Procedures/Trade.OrderForCloseJob.md) | 9.0 | Done (Batch 44) |
| [Trade.OrderForCloseUpdate](Stored Procedures/Trade.OrderForCloseUpdate.md) | 8.5 | Done (Batch 21) |
| [Trade.OrderForOpenCreate](Stored Procedures/Trade.OrderForOpenCreate.md) | 9.0 | Done (Batch 44) |
| [Trade.OrderForOpenCreateWrapper](Stored Procedures/Trade.OrderForOpenCreateWrapper.md) | 9.0 | Done (Batch 45) |
| [Trade.OrderForOpenJob](Stored Procedures/Trade.OrderForOpenJob.md) | 8.8 | Done (Batch 45) |
| [Trade.OrderForOpenUpdate](Stored Procedures/Trade.OrderForOpenUpdate.md) | 9.0 | Done (Batch 45) |
| [Trade.OrdersAdd](Stored Procedures/Trade.OrdersAdd.md) | 9.0 | Done (Batch 44) |
| [Trade.OrdersChangeLogAdd](Stored Procedures/Trade.OrdersChangeLogAdd.md) | 7.5 | Done (Batch 21) |
| [Trade.OrdersClientRemove](Stored Procedures/Trade.OrdersClientRemove.md) | 9.0 | Done (Batch 45) |
| [Trade.OrdersClose](Stored Procedures/Trade.OrdersClose.md) | 9.0 | Done (Batch 45) |
| [Trade.OrdersEntryChangeLogAdd](Stored Procedures/Trade.OrdersEntryChangeLogAdd.md) | 7.5 | Done (Batch 21) |
| [Trade.OrdersExitChangeLogAdd](Stored Procedures/Trade.OrdersExitChangeLogAdd.md) | 7.5 | Done (Batch 21) |
| [Trade.OrdersFailAdd](Stored Procedures/Trade.OrdersFailAdd.md) | 9.0 | Done (Batch 44) |
| [Trade.OrdersMarketFailAdd](Stored Procedures/Trade.OrdersMarketFailAdd.md) | 8.8 | Done (Batch 44) |
| [Trade.OrdersServerRemove](Stored Procedures/Trade.OrdersServerRemove.md) | 9.0 | Done (Batch 45) |
| [Trade.PayCashAirdropByPayDateAndTerminalID](Stored Procedures/Trade.PayCashAirdropByPayDateAndTerminalID.md) | 9.0 | Done (Batch 45) |
| [Trade.PayCashDividendByPayDate](Stored Procedures/Trade.PayCashDividendByPayDate.md) | 9.0 | Done (Batch 45) |
| [Trade.PayCashTerminalIdByManualData](Stored Procedures/Trade.PayCashTerminalIdByManualData.md) | 9.0 | Done (Batch 45) |
| [Trade.PayDividendsForPositions](Stored Procedures/Trade.PayDividendsForPositions.md) | 9.0 | Done (Batch 45) |
| [Trade.PayForFeeProcess](Stored Procedures/Trade.PayForFeeProcess.md) | 9.0 | Done (Batch 45) |
| [Trade.PayInterest](Stored Procedures/Trade.PayInterest.md) | 9.0 | Done (Batch 45) |
| [Trade.PersistAccountLiquidationSaga](Stored Procedures/Trade.PersistAccountLiquidationSaga.md) | 9.0 | Done (Batch 45) |
| [Trade.PersistMirrorCloseSaga](Stored Procedures/Trade.PersistMirrorCloseSaga.md) | 9.0 | Done (Batch 45) |
| [Trade.PortfolioForApiInnerMot](Stored Procedures/Trade.PortfolioForApiInnerMot.md) | 7.5 | Done (Batch 30) |
| [Trade.PosionByRowVersionID](Stored Procedures/Trade.PosionByRowVersionID.md) | 9.0 | Done (Batch 45) |
| [Trade.PositionAdjustment](Stored Procedures/Trade.PositionAdjustment.md) | 9.2 | Done (Batch 45) |
| [Trade.PositionAirdrop](Stored Procedures/Trade.PositionAirdrop.md) | 9.2 | Done (Batch 45) |
| [Trade.PositionAirdropAdd](Stored Procedures/Trade.PositionAirdropAdd.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionClose](Stored Procedures/Trade.PositionClose.md) | 9.4 | Done (Batch 46) |
| [Trade.PositionCloseRequestAdd](Stored Procedures/Trade.PositionCloseRequestAdd.md) | 8.8 | Done (Batch 46) |
| [Trade.PositionCloseValidation](Stored Procedures/Trade.PositionCloseValidation.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionCloseWithTimeout](Stored Procedures/Trade.PositionCloseWithTimeout.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionEditExternalInfo](Stored Procedures/Trade.PositionEditExternalInfo.md) | 8.8 | Done (Batch 46) |
| [Trade.PositionEditIsTSLEnabled](Stored Procedures/Trade.PositionEditIsTSLEnabled.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionEditSLWithTimeout](Stored Procedures/Trade.PositionEditSLWithTimeout.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionEditStopLoss](Stored%20Procedures/Trade.PositionEditStopLoss.md) | 9.2 | Done (Batch 46) |
| [Trade.PositionEditStopLoss_Validation](Stored Procedures/Trade.PositionEditStopLoss_Validation.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionEditTakeProfit](Stored Procedures/Trade.PositionEditTakeProfit.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionEditTakeProfit25102021](Stored Procedures/Trade.PositionEditTakeProfit25102021.md) | 8.8 | Done (Batch 46) |
| [Trade.PositionOpen](Stored Procedures/Trade.PositionOpen.md) | 9.0 | Done (Batch 21) |
| [Trade.PositionOpenForFork](Stored Procedures/Trade.PositionOpenForFork.md) | 7.5 | Done (Batch 30) |
| [Trade.PositionOpenRequestAdd](Stored Procedures/Trade.PositionOpenRequestAdd.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionOpenWithTimeout](Stored Procedures/Trade.PositionOpenWithTimeout.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionReopen](Stored Procedures/Trade.PositionReopen.md) | 9.2 | Done (Batch 46) |
| [Trade.PositionsGuaranteedSLWasNotAligned](Stored Procedures/Trade.PositionsGuaranteedSLWasNotAligned.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionsHedgeServerChangeSummaryLogInsert](Stored Procedures/Trade.PositionsHedgeServerChangeSummaryLogInsert.md) | 8.8 | Done (Batch 46) |
| [Trade.PositionsIsUS](Stored Procedures/Trade.PositionsIsUS.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionsReopen](Stored%20Procedures/Trade.PositionsReopen.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionsWithWrongPnLAlert](Stored%20Procedures/Trade.PositionsWithWrongPnLAlert.md) | 9.0 | Done (Batch 46) |
| [Trade.PositionTbl_SetIsSettled](Stored Procedures/Trade.PositionTbl_SetIsSettled.md) | 8.0 | Done (Batch 21) |
| [Trade.PostClosePositionActions](Stored%20Procedures/Trade.PostClosePositionActions.md) | 9.2 | Done (Batch 46) |
| [Trade.PostDetachPositionFromMirror](Stored%20Procedures/Trade.PostDetachPositionFromMirror.md) | 9.0 | Done (Batch 46) |
| [Trade.PostEditStopLossPosition](Stored%20Procedures/Trade.PostEditStopLossPosition.md) | 9.0 | Done (Batch 46) |
| [Trade.PostOpenPositionActions](Stored%20Procedures/Trade.PostOpenPositionActions.md) | 9.0 | Done (Batch 46) |
| [Trade.PostPositionOpenForSdrtCharge](Stored%20Procedures/Trade.PostPositionOpenForSdrtCharge.md) | 9.2 | Done (Batch 46) |
| [Trade.ProviderInstrumentLeverageAdd](Stored Procedures/Trade.ProviderInstrumentLeverageAdd.md) | 9.2 | Done (Batch 47) |
| [Trade.ProviderInstrumentLeverageDelete](Stored Procedures/Trade.ProviderInstrumentLeverageDelete.md) | 9.4 | Done (Batch 47) |
| [Trade.ProviderInstrumentLeverageEdit](Stored Procedures/Trade.ProviderInstrumentLeverageEdit.md) | 9.0 | Done (Batch 47) |
| [Trade.ProviderToInstrumentAdd](Stored Procedures/Trade.ProviderToInstrumentAdd.md) | 9.0 | Done (Batch 47) |
| [Trade.ProviderToInstrumentDelete](Stored Procedures/Trade.ProviderToInstrumentDelete.md) | 9.0 | Done (Batch 47) |
| [Trade.ProviderToInstrumentEdit](Stored Procedures/Trade.ProviderToInstrumentEdit.md) | 9.0 | Done (Batch 47) |
| [Trade.ProviderToInstrumentSetMaxPositionUnits](Stored Procedures/Trade.ProviderToInstrumentSetMaxPositionUnits.md) | 9.0 | Done (Batch 47) |
| [Trade.ProviderToInstrumentSetMimPositionAmount](Stored Procedures/Trade.ProviderToInstrumentSetMimPositionAmount.md) | 9.2 | Done (Batch 47) |
| [Trade.RegisterMirror](Stored%20Procedures/Trade.RegisterMirror.md) | 9.0 | Done (Batch 44) |
| [Trade.RejectedOrders](Stored Procedures/Trade.RejectedOrders.md) | 9.0 | Done (Batch 47) |
| [Trade.RemoveInstrumentHalt](Stored Procedures/Trade.RemoveInstrumentHalt.md) | 9.0 | Done (Batch 47) |
| [Trade.RemoveLiquidityProviderContract](Stored Procedures/Trade.RemoveLiquidityProviderContract.md) | 9.0 | Done (Batch 47) |
| [Trade.RemoveTradonomiContract](Stored Procedures/Trade.RemoveTradonomiContract.md) | 9.0 | Done (Batch 47) |
| [Trade.ReopenForUnalignedSlCryptoPositions](Stored Procedures/Trade.ReopenForUnalignedSlCryptoPositions.md) | 9.4 | Done (Batch 47) |
| [Trade.ReopenOperation_Get](Stored Procedures/Trade.ReopenOperation_Get.md) | 9.0 | Done (Batch 47) |
| [Trade.ReopenOperationAdd](Stored Procedures/Trade.ReopenOperationAdd.md) | 9.0 | Done (Batch 47) |
| [Trade.ReopenOperationCancel](Stored Procedures/Trade.ReopenOperationCancel.md) | 9.2 | Done (Batch 47) |
| [Trade.ReopenOperationSendApprovalRequest](Stored Procedures/Trade.ReopenOperationSendApprovalRequest.md) | 9.2 | Done (Batch 47) |
| [Trade.ReopenOperationSendResult](Stored Procedures/Trade.ReopenOperationSendResult.md) | 9.0 | Done (Batch 47) |
| [Trade.ReopenOperationValidation](Stored Procedures/Trade.ReopenOperationValidation.md) | 9.4 | Done (Batch 47) |
| [Trade.Report_PositionsFailSummary](Stored Procedures/Trade.Report_PositionsFailSummary.md) | 9.0 | Done (Batch 47) |
| [Trade.ReportWrongDataInCustomerMoney](Stored Procedures/Trade.ReportWrongDataInCustomerMoney.md) | 9.2 | Done (Batch 47) |
| [Trade.ReportWrongDataInCustomerMoney_1](Stored Procedures/Trade.ReportWrongDataInCustomerMoney_1.md) | 9.2 | Done (Batch 47) |
| [Trade.ReportWrongDataInCustomerMoney_New](Stored Procedures/Trade.ReportWrongDataInCustomerMoney_New.md) | 9.0 | Done (Batch 47) |
| [Trade.ReportWrongDataInCustomerMoneyNew](Stored Procedures/Trade.ReportWrongDataInCustomerMoneyNew.md) | 9.0 | Done (Batch 48) |
| [Trade.ReportWrongDataInCustomerMoneyOLD](Stored Procedures/Trade.ReportWrongDataInCustomerMoneyOLD.md) | 9.0 | Done (Batch 48) |
| [Trade.ReportWrongDataInHistoryCredit](Stored Procedures/Trade.ReportWrongDataInHistoryCredit.md) | 9.0 | Done (Batch 48) |
| [Trade.ReportWrongDataInHistoryCredit_NewElad](Stored Procedures/Trade.ReportWrongDataInHistoryCredit_NewElad.md) | 9.2 | Done (Batch 48) |
| [Trade.ReverseSplit](Stored Procedures/Trade.ReverseSplit.md) | 9.0 | Done (Batch 48) |
| [Trade.RollbackTakeProfitByInstrumentID](Stored Procedures/Trade.RollbackTakeProfitByInstrumentID.md) | 9.0 | Done (Batch 48) |
| [Trade.RolloutAboveDollarPrecision](Stored Procedures/Trade.RolloutAboveDollarPrecision.md) | 9.2 | Done (Batch 48) |
| [Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument](Stored Procedures/Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument.md) | 9.2 | Done (Batch 48) |
| [Trade.RolloutAboveDollarPrecisionForOrders](Stored Procedures/Trade.RolloutAboveDollarPrecisionForOrders.md) | 9.0 | Done (Batch 48) |
| [Trade.RolloutAboveDollarPrecisionForPositions](Stored Procedures/Trade.RolloutAboveDollarPrecisionForPositions.md) | 9.0 | Done (Batch 48) |
| [Trade.RolloverFeesAlertIfNeeded](Stored Procedures/Trade.RolloverFeesAlertIfNeeded.md) | 9.2 | Done (Batch 48) |
| [Trade.RolloverFeesAlertIfNeeded1](Stored Procedures/Trade.RolloverFeesAlertIfNeeded1.md) | 9.0 | Done (Batch 48) |
| [Trade.RunSplitAtDemo](Stored Procedures/Trade.RunSplitAtDemo.md) | 9.0 | Done (Batch 48) |
| [Trade.SendMessagesToBSL](Stored Procedures/Trade.SendMessagesToBSL.md) | 9.2 | Done (Batch 48) |
| [Trade.SendUnBlockMessage](Stored Procedures/Trade.SendUnBlockMessage.md) | 9.2 | Done (Batch 48) |
| [Trade.SetAdminPositionFailInfo](Stored Procedures/Trade.SetAdminPositionFailInfo.md) | 9.0 | Done (Batch 48) |
| [Trade.SetAdminPositionState](Stored Procedures/Trade.SetAdminPositionState.md) | 9.2 | Done (Batch 48) |
| [Trade.SetBulkOperationsAllowedCids](Stored Procedures/Trade.SetBulkOperationsAllowedCids.md) | 9.0 | Done (Batch 48) |
| [Trade.SetCurrencyPrice](Stored Procedures/Trade.SetCurrencyPrice.md) | 9.0 | Done (Batch 48) |
| [Trade.SetCurrencyPriceFail](Stored Procedures/Trade.SetCurrencyPriceFail.md) | 9.0 | Done (Batch 48) |
| [Trade.SetCurrencyPriceHistoryInsert_New](Stored Procedures/Trade.SetCurrencyPriceHistoryInsert_New.md) | 9.2 | Done (Batch 48) |
| [Trade.SetGuarenteedSLTP_CIDBlacklist](Stored Procedures/Trade.SetGuarenteedSLTP_CIDBlacklist.md) | 9.0 | Done (Batch 48) |
| [Trade.SetHedgeOrderID](Stored Procedures/Trade.SetHedgeOrderID.md) | 9.0 | Done (Batch 48) |
| [Trade.SetInstrumentMarginsForFutures](Stored Procedures/Trade.SetInstrumentMarginsForFutures.md) | 9.2 | Done (Batch 48) |
| [Trade.SetInstrumentsDataForOpsAPI](Stored Procedures/Trade.SetInstrumentsDataForOpsAPI.md) | 9.2 | Done (Batch 48) |
| [Trade.SetInstrumentSlippage](Stored Procedures/Trade.SetInstrumentSlippage.md) | 9.0 | Done (Batch 49) |
| [Trade.SetIsNoStopLossIsNoTakeProfitDelta](Stored Procedures/Trade.SetIsNoStopLossIsNoTakeProfitDelta.md) | 9.2 | Done (Batch 49) |
| [Trade.SetIsNoStopLossIsNoTakeProfitInit](Stored Procedures/Trade.SetIsNoStopLossIsNoTakeProfitInit.md) | 9.0 | Done (Batch 49) |
| [Trade.SetIsRedeemAllowed](Stored Procedures/Trade.SetIsRedeemAllowed.md) | 9.2 | Done (Batch 49) |
| [Trade.SetMirrorAlignmentStatus](Stored Procedures/Trade.SetMirrorAlignmentStatus.md) | 9.4 | Done (Batch 49) |
| [Trade.SetMirrorStopLossPercentage](Stored Procedures/Trade.SetMirrorStopLossPercentage.md) | 9.4 | Done (Batch 49) |
| [Trade.SetNextLiquidityAccountID](Stored Procedures/Trade.SetNextLiquidityAccountID.md) | 9.0 | Done (Batch 49) |
| [Trade.SetNextLiquidityProviderID](Stored Procedures/Trade.SetNextLiquidityProviderID.md) | 9.0 | Done (Batch 49) |
| [Trade.SetTradonomiToLPContracts](Stored Procedures/Trade.SetTradonomiToLPContracts.md) | 9.0 | Done (Batch 49) |
| [Trade.SI_GetMirrorByCID](Stored Procedures/Trade.SI_GetMirrorByCID.md) | 9.0 | Done (Batch 49) |
| [Trade.SI_GetPositionDataBy_CO](Stored Procedures/Trade.SI_GetPositionDataBy_CO.md) | 9.0 | Done (Batch 49) |
| [Trade.SI_GetProviderToInstrument](Stored Procedures/Trade.SI_GetProviderToInstrument.md) | 9.0 | Done (Batch 49) |
| [Trade.SI_GetSpreadGroup](Stored Procedures/Trade.SI_GetSpreadGroup.md) | 9.0 | Done (Batch 49) |
| [Trade.sp_GetPositionData](Stored Procedures/Trade.sp_GetPositionData.md) | 9.0 | Done (Batch 49) |
| [Trade.SplitbyJob](Stored Procedures/Trade.SplitbyJob.md) | 9.2 | Done (Batch 49) |
| [Trade.SplitHoldingFees](Stored Procedures/Trade.SplitHoldingFees.md) | 9.2 | Done (Batch 49) |
| [Trade.SplitOpenPositions](Stored Procedures/Trade.SplitOpenPositions.md) | 9.0 | Done (Batch 21) |
| [Trade.SpreadAdd](Stored Procedures/Trade.SpreadAdd.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadDelete](Stored Procedures/Trade.SpreadDelete.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadEdit](Stored Procedures/Trade.SpreadEdit.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadGroupAdd](Stored Procedures/Trade.SpreadGroupAdd.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadGroupDelete](Stored Procedures/Trade.SpreadGroupDelete.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadGroupEdit](Stored Procedures/Trade.SpreadGroupEdit.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadToGroupLink](Stored Procedures/Trade.SpreadToGroupLink.md) | 9.0 | Done (Batch 49) |
| [Trade.SpreadToGroupUnLink](Stored Procedures/Trade.SpreadToGroupUnLink.md) | 9.0 | Done (Batch 49) |
| [Trade.SSRS_AsyncLatencyReport](Stored Procedures/Trade.SSRS_AsyncLatencyReport.md) | 9.2 | Done (Batch 49) |
| [Trade.SSRS_CustomerCopyPositions](Stored Procedures/Trade.SSRS_CustomerCopyPositions.md) | 9.0 | Done (Batch 50) |
| [Trade.SSRS_DuringDowntimeReport](Stored Procedures/Trade.SSRS_DuringDowntimeReport.md) | 9.0 | Done (Batch 50) |
| [Trade.SSRS_GetOrphanedPositionsData](Stored Procedures/Trade.SSRS_GetOrphanedPositionsData.md) | 9.2 | Done (Batch 50) |
| [Trade.SSRS_Market_Open_Data](Stored Procedures/Trade.SSRS_Market_Open_Data.md) | 9.2 | Done (Batch 50) |
| [Trade.SSRS_NonAsyncLatencyReport](Stored Procedures/Trade.SSRS_NonAsyncLatencyReport.md) | 9.2 | Done (Batch 50) |
| [Trade.SSRSInstrumentAsync_PositionsOpenAndClose](Stored Procedures/Trade.SSRSInstrumentAsync_PositionsOpenAndClose.md) | 9.2 | Done (Batch 50) |
| [Trade.StuckOrders](Stored Procedures/Trade.StuckOrders.md) | 9.2 | Done (Batch 50) |
| [Trade.SyncConfigurationAdd](Stored Procedures/Trade.SyncConfigurationAdd.md) | 9.0 | Done (Batch 47) |
| [Trade.SyncLeveragesList](Stored Procedures/Trade.SyncLeveragesList.md) | 9.0 | Done (Batch 47) |
| [Trade.TAPI_GetCreditHistoryByCID](Stored Procedures/Trade.TAPI_GetCreditHistoryByCID.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetCreditHistoryByCIDAgg](Stored Procedures/Trade.TAPI_GetCreditHistoryByCIDAgg.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCID](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCID.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit.md) | 9.4 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows.md) | 9.0 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit.md) | 9.0 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy.md) | 9.0 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit.md) | 9.0 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual.md) | 9.0 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit](Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit.md) | 9.0 | Done (Batch 50) |
| [Trade.TAPI_GetHistoryMirrorByCidAndParentCid](Stored Procedures/Trade.TAPI_GetHistoryMirrorByCidAndParentCid.md) | 9.4 | Done (Batch 50) |
| [Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg](Stored Procedures/Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg.md) | 9.2 | Done (Batch 50) |
| [Trade.TAPI_GetHistoryPortfolioAgg](Stored Procedures/Trade.TAPI_GetHistoryPortfolioAgg.md) | 9.4 | Done (Batch 50) |
| [Trade.TAPI_GetHistoryPortfolioBreakdownAgg](Stored Procedures/Trade.TAPI_GetHistoryPortfolioBreakdownAgg.md) | 9.4 | Done (Batch 50) |
| [Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments](Stored Procedures/Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople](Stored Procedures/Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId](Stored Procedures/Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId](Stored Procedures/Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg](Stored Procedures/Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId](Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId.md) | 9.4 | Done (Batch 51) |
| [Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg](Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg.md) | 9.4 | Done (Batch 51) |
| [Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows](Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy](Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds](Stored Procedures/Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPostionsUnitsByInstrumentTypeId](Stored Procedures/Trade.TAPI_GetPostionsUnitsByInstrumentTypeId.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount](Stored Procedures/Trade.TAPI_GetPrivateUserHistoryClosedPositionsCount.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount](Stored Procedures/Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicFlatCreditHistoryByCID](Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCID.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg](Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg.md) | 9.4 | Done (Batch 51) |
| [Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy](Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual](Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId](Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg](Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid](Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg](Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest](Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryPortfolioAgg](Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioAgg.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg](Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg.md) | 9.4 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy](Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual](Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId](Stored Procedures/Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg](Stored Procedures/Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId](Stored Procedures/Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorId.md) | 9.2 | Done (Batch 51) |
| [Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest](Stored Procedures/Trade.TAPI_GetPublicMirrorHistoryDataWithCIDAndMirrorIdTest.md) | 9.0 | Done (Batch 51) |
| [Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid](Stored Procedures/Trade.TAPI_GetTotalInvestedHistoryAndLivePrivatePositionsByCid.md) | 9.2 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderAumTimeSeries](Stored Procedures/Trade.TDAPI_GetLeaderAumTimeSeries.md) | 9.2 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderCashFlows](Stored Procedures/Trade.TDAPI_GetLeaderCashFlows.md) | 9.2 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderDataTimeSeries](Stored Procedures/Trade.TDAPI_GetLeaderDataTimeSeries.md) | 9.2 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers.md) | 9.2 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers_After_2025](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_After_2025.md) | 8.8 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic.md) | 8.8 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025.md) | 9.0 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers_MirrorTest](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_MirrorTest.md) | 8.5 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers_OLD](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_OLD.md) | 8.5 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiers_TestVersion](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_TestVersion.md) | 8.5 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderJoinedCopiersElad](Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiersElad.md) | 8.8 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderLeavingCopiers](Stored Procedures/Trade.TDAPI_GetLeaderLeavingCopiers.md) | 9.2 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries](Stored Procedures/Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries.md) | 9.0 | Done (Batch 51) |
| [Trade.TDAPI_GetLeaderStats](Stored Procedures/Trade.TDAPI_GetLeaderStats.md) | 9.2 | Done (Batch 51) |
| [Trade.TmpInsertUsersToBSLBlackListTable](Stored Procedures/Trade.TmpInsertUsersToBSLBlackListTable.md) | 9.0 | Done (Batch 51) |
| [Trade.TruncateFeeNightProcess](Stored Procedures/Trade.TruncateFeeNightProcess.md) | 8.8 | Done (Batch 51) |
| [Trade.UnRegisterMirrorForMoe](Stored Procedures/Trade.UnRegisterMirrorForMoe.md) | 9.2 | Done (Batch 51) |
| [Trade.UpdateApexID](Stored Procedures/Trade.UpdateApexID.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateApexIDOld](Stored Procedures/Trade.UpdateApexIDOld.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateBslLastExecute](Stored Procedures/Trade.UpdateBslLastExecute.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateCashingOperationMonitorAndMailing](Stored Procedures/Trade.UpdateCashingOperationMonitorAndMailing.md) | 9.2 | Done (Batch 51) |
| [Trade.UpdateCusip](Stored Procedures/Trade.UpdateCusip.md) | 9.2 | Done (Batch 51) |
| [Trade.UpdateCustomerMoneyCashoutRollback](Stored Procedures/Trade.UpdateCustomerMoneyCashoutRollback.md) | 9.2 | Done (Batch 51) |
| [Trade.UpdateDesignatedExecutionSystemBulk](Stored Procedures/Trade.UpdateDesignatedExecutionSystemBulk.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateDividend](Stored Procedures/Trade.UpdateDividend.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateEtorianUsersCopiedBlockRestriction](Stored Procedures/Trade.UpdateEtorianUsersCopiedBlockRestriction.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateFeatureThresholdValues](Stored Procedures/Trade.UpdateFeatureThresholdValues.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateFeeInPercentageConfigurations](Stored Procedures/Trade.UpdateFeeInPercentageConfigurations.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateFixPerLotConfigurations](Stored Procedures/Trade.UpdateFixPerLotConfigurations.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping](Stored Procedures/Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet](Stored Procedures/Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet.md) | 8.5 | Done (Batch 51) |
| [Trade.UpdateFuturesMetadataSecurityOpsAPI](Stored Procedures/Trade.UpdateFuturesMetadataSecurityOpsAPI.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateFuturesOpsConfigurations](Stored Procedures/Trade.UpdateFuturesOpsConfigurations.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateFuturesTradingConfigurations](Stored Procedures/Trade.UpdateFuturesTradingConfigurations.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateIndexDividends](Stored Procedures/Trade.UpdateIndexDividends.md) | 9.2 | Done (Batch 51) |
| [Trade.UpdateInstrumentCurrency](Stored Procedures/Trade.UpdateInstrumentCurrency.md) | 8.5 | Done (Batch 51) |
| [Trade.UpdateInstrumentExchange](Stored Procedures/Trade.UpdateInstrumentExchange.md) | 9.0 | Done (Batch 51) |
| [Trade.UpdateInstrumentsAvailableLeverages](Stored Procedures/Trade.UpdateInstrumentsAvailableLeverages.md) | 9.2 | Done (Batch 51) |
| [Trade.UpdateInstrumentsMarketRange](Stored Procedures/Trade.UpdateInstrumentsMarketRange.md) | 8.8 | Done (Batch 51) |
| [Trade.UpdateInstrumentsMaxPositionUnits](Stored Procedures/Trade.UpdateInstrumentsMaxPositionUnits.md) | 8.8 | Done (Batch 51) |
| [Trade.UpdateInstrumentsMaxRateDiffPercentage](Stored Procedures/Trade.UpdateInstrumentsMaxRateDiffPercentage.md) | 8.8 | Done (Batch 51) |
| [Trade.UpdateInstrumentsMaxStopLossPrecentage](Stored Procedures/Trade.UpdateInstrumentsMaxStopLossPrecentage.md) | 8.8 | Done (Batch 51) |
| [Trade.UpdateInstrumentsMetaDataConfigurations](Stored Procedures/Trade.UpdateInstrumentsMetaDataConfigurations.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateInstrumentsMetaDataConfigurationsExtend](Stored Procedures/Trade.UpdateInstrumentsMetaDataConfigurationsExtend.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateInstrumentsMinPositionAmount](Stored Procedures/Trade.UpdateInstrumentsMinPositionAmount.md) | 8.8 | Done (Batch 51) |
| [Trade.UpdateInstrumentsNWADecreasePercentage](Stored Procedures/Trade.UpdateInstrumentsNWADecreasePercentage.md) | 8.8 | Done (Batch 51) |
| [Trade.UpdateInstrumentsPrecision](Stored Procedures/Trade.UpdateInstrumentsPrecision.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentsSymbolFull](Stored Procedures/Trade.UpdateInstrumentsSymbolFull.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentsSymbolFullExtend](Stored Procedures/Trade.UpdateInstrumentsSymbolFullExtend.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentsTradingConfigurations](Stored Procedures/Trade.UpdateInstrumentsTradingConfigurations.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentsTradingConfigurationsTmp](Stored Procedures/Trade.UpdateInstrumentsTradingConfigurationsTmp.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentsTradingOrdersConfigurations](Stored Procedures/Trade.UpdateInstrumentsTradingOrdersConfigurations.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentToFeeConfigTable](Stored Procedures/Trade.UpdateInstrumentToFeeConfigTable.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateInstrumentToFeeConfigTableV2](Stored Procedures/Trade.UpdateInstrumentToFeeConfigTableV2.md) | 8.5 | Done (Batch 21) |
| [Trade.UpdateInstrumentToFeeConfigurations_TRDOPS](Stored Procedures/Trade.UpdateInstrumentToFeeConfigurations_TRDOPS.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInstrumentType](Stored Procedures/Trade.UpdateInstrumentType.md) | 8.8 | Done (Batch 52) |
| [Trade.UpdateInterestRate](Stored Procedures/Trade.UpdateInterestRate.md) | 8.8 | Done (Batch 52) |
| [Trade.UpdateInterestRateOverride](Stored Procedures/Trade.UpdateInterestRateOverride.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateInterestRateOverride_TRDOPS](Stored Procedures/Trade.UpdateInterestRateOverride_TRDOPS.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateInterestRates_TRDOPS](Stored Procedures/Trade.UpdateInterestRates_TRDOPS.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateIsSettled](Stored Procedures/Trade.UpdateIsSettled.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateIsSettledValidation](Stored Procedures/Trade.UpdateIsSettledValidation.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdatePositionRedeemStatus](Stored Procedures/Trade.UpdatePositionRedeemStatus.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdatePositionsTakeProfitByInstrumentID](Stored Procedures/Trade.UpdatePositionsTakeProfitByInstrumentID.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateProviderToInstrumentLeverageMaintenance](Stored Procedures/Trade.UpdateProviderToInstrumentLeverageMaintenance.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateProviderToInstrumentOverNightFee](Stored Procedures/Trade.UpdateProviderToInstrumentOverNightFee.md) | 9.0 | Done (Batch 53) |
| [Trade.UpdateRolloverFeeMarkup](Stored Procedures/Trade.UpdateRolloverFeeMarkup.md) | 9.2 | Done (Batch 52) |
| [Trade.UpdateRolloverFeeThreshold](Stored Procedures/Trade.UpdateRolloverFeeThreshold.md) | 8.8 | Done (Batch 52) |
| [Trade.UpdateTotalCash](Stored Procedures/Trade.UpdateTotalCash.md) | 9.0 | Done (Batch 52) |
| [Trade.UpdateTradingInstrumentGroupName](Stored Procedures/Trade.UpdateTradingInstrumentGroupName.md) | 9.0 | Done (Batch 53) |
| [Trade.UpdateTradonomiToLiquidityProviderContracts](Stored Procedures/Trade.UpdateTradonomiToLiquidityProviderContracts.md) | 9.0 | Done (Batch 53) |
| [Trade.UpdateTree](Stored Procedures/Trade.UpdateTree.md) | 9.0 | Done (Batch 22) |
| [Trade.UpdateTreeFromRealForSplit](Stored Procedures/Trade.UpdateTreeFromRealForSplit.md) | 9.0 | Done (Batch 53) |
| [Trade.UpsertFuturesInstrumentRiskSettings](Stored Procedures/Trade.UpsertFuturesInstrumentRiskSettings.md) | 9.0 | Done (Batch 51) |
| [Trade.UpsertProviderMarginMarkupByInstrument](Stored Procedures/Trade.UpsertProviderMarginMarkupByInstrument.md) | 9.0 | Done (Batch 51) |
| [Trade.USAggregatePositionBySymbol](Stored Procedures/Trade.USAggregatePositionBySymbol.md) | 9.0 | Done (Batch 53) |
| [Trade.USAggregatePositionBySymbolForMonitor](Stored Procedures/Trade.USAggregatePositionBySymbolForMonitor.md) | 9.0 | Done (Batch 53) |
| [Trade.UsUsersCryptoStat](Stored Procedures/Trade.UsUsersCryptoStat.md) | 9.0 | Done (Batch 53) |
| [Trade.ValidateFeeInPercentageConfigurations](Stored Procedures/Trade.ValidateFeeInPercentageConfigurations.md) | 9.0 | Done (Batch 53) |
| [Trade.ValidateFixPerLotConfigurations](Stored Procedures/Trade.ValidateFixPerLotConfigurations.md) | 9.0 | Done (Batch 53) |
| [Trade.VerifyPublicUser](Stored Procedures/Trade.VerifyPublicUser.md) | 9.0 | Done (Batch 53) |
| [Trade.ViewBulkOrders](Stored Procedures/Trade.ViewBulkOrders.md) | 9.0 | Done (Batch 53) |

## Synonyms (23)

| Object | Quality | Status |
|--------|---------|--------|
| [Trade.ApexSYN_EXT869_CashActivity](Synonyms/Trade.ApexSYN_EXT869_CashActivity.md) | 7.5 | Done (Batch 18) |
| [Trade.ApexSYN_EXT922_DividendReport](Synonyms/Trade.ApexSYN_EXT922_DividendReport.md) | 7.5 | Done (Batch 18) |
| [Trade.ApexSYN_SodFiles](Synonyms/Trade.ApexSYN_SodFiles.md) | 7.5 | Done (Batch 18) |
| [Trade.DividendPositionsSnapshot](Synonyms/Trade.DividendPositionsSnapshot.md) | 7.0 | Done (Batch 18) |
| [Trade.DividendPositionsSnapshotArchive](Synonyms/Trade.DividendPositionsSnapshotArchive.md) | 7.0 | Done (Batch 18) |
| [Trade.FutureInstruments](Synonyms/Trade.FutureInstruments.md) | 7.5 | Done (Batch 18) |
| [Trade.InstrumentClosingPriceSourceData](Synonyms/Trade.InstrumentClosingPriceSourceData.md) | 7.5 | Done (Batch 18) |
| [Trade.InstrumentTimeZones](Synonyms/Trade.InstrumentTimeZones.md) | 7.0 | Done (Batch 18) |
| [Trade.InterestDaily](Synonyms/Trade.InterestDaily.md) | 7.0 | Done (Batch 18) |
| [Trade.MergedDailySchedules](Synonyms/Trade.MergedDailySchedules.md) | 7.8 | Done (Batch 18) |
| [Trade.SYN_ExecuteAllFeeJobs](Synonyms/Trade.SYN_ExecuteAllFeeJobs.md) | 7.5 | Done (Batch 18) |
| [Trade.SYN_FeeNightProcess](Synonyms/Trade.SYN_FeeNightProcess.md) | 7.5 | Done (Batch 23) |
| [Trade.Syn_InterestDaily_July](Synonyms/Trade.Syn_InterestDaily_July.md) | 7.5 | Done (Batch 23) |
| [Trade.Syn_TradeOrphanedPositionsCloseByJob](Synonyms/Trade.Syn_TradeOrphanedPositionsCloseByJob.md) | 7.5 | Done (Batch 23) |
| [Trade.SYN_TruncateFeeNightProcess](Synonyms/Trade.SYN_TruncateFeeNightProcess.md) | 8.0 | Done (Batch 23) |
| [Trade.SynApexTradingUserData](Synonyms/Trade.SynApexTradingUserData.md) | 7.5 | Done (Batch 23) |
| [Trade.SynBackTrader2CloseRequest](Synonyms/Trade.SynBackTrader2CloseRequest.md) | 7.5 | Done (Batch 23) |
| [Trade.SynDividendPositionsSnapshot](Synonyms/Trade.SynDividendPositionsSnapshot.md) | 7.0 | Done (Batch 23) |
| [Trade.SynPdtOperations](Synonyms/Trade.SynPdtOperations.md) | 7.0 | Done (Batch 23) |
| [Trade.SynPositionEndedWithTOError](Synonyms/Trade.SynPositionEndedWithTOError.md) | 8.0 | Done (Batch 23) |
| [Trade.SynPositionTimeOuts](Synonyms/Trade.SynPositionTimeOuts.md) | 8.0 | Done (Batch 23) |
| [Trade.SynRealCustomers](Synonyms/Trade.SynRealCustomers.md) | 7.5 | Done (Batch 23) |
| [Trade.SynRealPortfolioEquitySnapshotTbl](Synonyms/Trade.SynRealPortfolioEquitySnapshotTbl.md) | 7.5 | Done (Batch 23) |

## User Defined Types (126)

| Object | Quality | Status |
|--------|---------|--------|
| [Trade.AdminPositionTbl](User Defined Types/Trade.AdminPositionTbl.md) | 7.8 | Done (Batch 8) |
| [Trade.AllOpenOrdersTableType_MOT](User Defined Types/Trade.AllOpenOrdersTableType_MOT.md) | 8.2 | Done (Batch 8) |
| [Trade.ApexIDsList](User Defined Types/Trade.ApexIDsList.md) | 8.5 | Done (Batch 8) |
| [Trade.ApexIdsListTbl](User Defined Types/Trade.ApexIdsListTbl.md) | 8.5 | Done (Batch 8) |
| [Trade.BlockedCustomerOperationTypeIDs](User Defined Types/Trade.BlockedCustomerOperationTypeIDs.md) | 8.5 | Done (Batch 8) |
| [Trade.BlockOperations](User Defined Types/Trade.BlockOperations.md) | 8.2 | Done (Batch 8) |
| [Trade.BulkCopyTradeSettlementRestrictionsTbl](User Defined Types/Trade.BulkCopyTradeSettlementRestrictionsTbl.md) | 8.5 | Done (Batch 8) |
| [Trade.BulkOperationsAllowedCidsTbl](User Defined Types/Trade.BulkOperationsAllowedCidsTbl.md) | 8.2 | Done (Batch 8) |
| [Trade.CashPaymentsTbl](User Defined Types/Trade.CashPaymentsTbl.md) | 8.0 | Done (Batch 8) |
| [Trade.CidList](User Defined Types/Trade.CidList.md) | 8.8 | Done (Batch 7) |
| [Trade.CIDsAndPositionIDs](User Defined Types/Trade.CIDsAndPositionIDs.md) | 8.2 | Done (Batch 8) |
| [Trade.CidToMirrorId](User Defined Types/Trade.CidToMirrorId.md) | 7.8 | Done (Batch 8) |
| [Trade.CidToMirrorIdElad](User Defined Types/Trade.CidToMirrorIdElad.md) | 7.2 | Done (Batch 8) |
| [Trade.CloseExecutionPlanTbl](User Defined Types/Trade.CloseExecutionPlanTbl.md) | 8.2 | Done (Batch 8) |
| [Trade.CM_DeleteLeveragesRestrictionsWhiteListTable](User Defined Types/Trade.CM_DeleteLeveragesRestrictionsWhiteListTable.md) | 8.0 | Done (Batch 8) |
| [Trade.CM_UpdateLeveragesRestrictionsWhiteListTable](User Defined Types/Trade.CM_UpdateLeveragesRestrictionsWhiteListTable.md) | 8.2 | Done (Batch 8) |
| [Trade.CopyTradeSettlementRestrictionsTbl](User Defined Types/Trade.CopyTradeSettlementRestrictionsTbl.md) | 8.2 | Done (Batch 8) |
| [Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS](User Defined Types/Trade.CopyTradeSettlementRestrictionsTbl_TRDOPS.md) | 8.3 | Done (Batch 8) |
| [Trade.CusipConfigTbl](User Defined Types/Trade.CusipConfigTbl.md) | 8.5 | Done (Batch 8) |
| [Trade.CusipsListTbl](User Defined Types/Trade.CusipsListTbl.md) | 8.2 | Done (Batch 8) |
| [Trade.DelayedOrdersForClose_MOT](User Defined Types/Trade.DelayedOrdersForClose_MOT.md) | 8.2 | Done (Batch 8) |
| [Trade.DelayedOrdersForCloseType](User Defined Types/Trade.DelayedOrdersForCloseType.md) | 8.2 | Done (Batch 8) |
| [Trade.DeleteIndexDividendsTbl](User Defined Types/Trade.DeleteIndexDividendsTbl.md) | 8.5 | Done (Batch 8) |
| [Trade.DesignatedExecutionSystemUpdate](User Defined Types/Trade.DesignatedExecutionSystemUpdate.md) | 8.8 | Done (Batch 8) |
| [Trade.DetachPositionsFromMirror](User Defined Types/Trade.DetachPositionsFromMirror.md) | 8.2 | Done (Batch 8) |
| [Trade.DetachPositionsFromMirrorPosition](User Defined Types/Trade.DetachPositionsFromMirrorPosition.md) | 8.4 | Done (Batch 8) |
| [Trade.DetachPositionsFromMirrorTree](User Defined Types/Trade.DetachPositionsFromMirrorTree.md) | 7.5 | Done (Batch 9) |
| [Trade.DividendsPaidTbl](User Defined Types/Trade.DividendsPaidTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.DividendTbl](User Defined Types/Trade.DividendTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.ExchangeHedgeGroupsTbl](User Defined Types/Trade.ExchangeHedgeGroupsTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.FeatureThresholdValuesType](User Defined Types/Trade.FeatureThresholdValuesType.md) | 7.5 | Done (Batch 9) |
| [Trade.FeeInPercentageConfigUpdateTbl](User Defined Types/Trade.FeeInPercentageConfigUpdateTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.FeeInPercentageConfigurationsTbl](User Defined Types/Trade.FeeInPercentageConfigurationsTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.FeeInPercentageInstrumentDataTbl](User Defined Types/Trade.FeeInPercentageInstrumentDataTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.FeeUpdateList](User Defined Types/Trade.FeeUpdateList.md) | 7.5 | Done (Batch 9) |
| [Trade.FixPerLotConfigUpdateTbl](User Defined Types/Trade.FixPerLotConfigUpdateTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.FixPerLotConfigurationsTbl](User Defined Types/Trade.FixPerLotConfigurationsTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.FixPerLotInstrumentDataTbl](User Defined Types/Trade.FixPerLotInstrumentDataTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.Gain_CashFlowProviderCustomers](User Defined Types/Trade.Gain_CashFlowProviderCustomers.md) | 7.5 | Done (Batch 9) |
| [Trade.Gain_GuidList](User Defined Types/Trade.Gain_GuidList.md) | 7.5 | Done (Batch 9) |
| [Trade.Gain_WithdrawalMatcherBonus](User Defined Types/Trade.Gain_WithdrawalMatcherBonus.md) | 7.5 | Done (Batch 9) |
| [Trade.GetTreeNodesByParentPositionAndTreeId_MOT](User Defined Types/Trade.GetTreeNodesByParentPositionAndTreeId_MOT.md) | 7.5 | Done (Batch 9) |
| [Trade.GranularAggregatesTableType_MOT](User Defined Types/Trade.GranularAggregatesTableType_MOT.md) | 7.5 | Done (Batch 9) |
| [Trade.IdIntList](User Defined Types/Trade.IdIntList.md) | 8.5 | Done (Batch 7) |
| [Trade.InstrumentAggregatesTableType_MOT](User Defined Types/Trade.InstrumentAggregatesTableType_MOT.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentAvailableLeveragesConfigTable](User Defined Types/Trade.InstrumentAvailableLeveragesConfigTable.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentGroupNameAndIDTbl](User Defined Types/Trade.InstrumentGroupNameAndIDTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentGroupNameTbl](User Defined Types/Trade.InstrumentGroupNameTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentGroupsTbl](User Defined Types/Trade.InstrumentGroupsTbl.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentHedgeServerPairData](User Defined Types/Trade.InstrumentHedgeServerPairData.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentIDsTbl](User Defined Types/Trade.InstrumentIDsTbl.md) | 8.5 | Done (Batch 7) |
| [Trade.InstrumentMarketRangeConfigTable](User Defined Types/Trade.InstrumentMarketRangeConfigTable.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentMaxPositionUnitsConfigTable](User Defined Types/Trade.InstrumentMaxPositionUnitsConfigTable.md) | 7.5 | Done (Batch 9) |
| [Trade.InstrumentMaxSLConfigTable](User Defined Types/Trade.InstrumentMaxSLConfigTable.md) | 7.6 | Done (Batch 10) |
| [Trade.InstrumentMinPositionAmountConfigTable](User Defined Types/Trade.InstrumentMinPositionAmountConfigTable.md) | 7.6 | Done (Batch 10) |
| [Trade.InstrumentNWADecreasePercentageConfigTable](User Defined Types/Trade.InstrumentNWADecreasePercentageConfigTable.md) | 7.6 | Done (Batch 10) |
| [Trade.InstrumentPrecisionConfigTable](User Defined Types/Trade.InstrumentPrecisionConfigTable.md) | 7.6 | Done (Batch 10) |
| [Trade.InstrumentsIDListSetMarginTbl](User Defined Types/Trade.InstrumentsIDListSetMarginTbl.md) | 7.8 | Done (Batch 10) |
| [Trade.InstrumentsIDListSetParamsTbl](User Defined Types/Trade.InstrumentsIDListSetParamsTbl.md) | 8.0 | Done (Batch 10) |
| [Trade.InstrumentsIDListSetSlippageTbl](User Defined Types/Trade.InstrumentsIDListSetSlippageTbl.md) | 7.3 | Done (Batch 10) |
| [Trade.InstrumentsMaxRateDiffConfigTable](User Defined Types/Trade.InstrumentsMaxRateDiffConfigTable.md) | 7.5 | Done (Batch 10) |
| [Trade.InstrumentsMetaDataConfigTbl](User Defined Types/Trade.InstrumentsMetaDataConfigTbl.md) | 7.8 | Done (Batch 10) |
| [Trade.InstrumentsMetaDataConfigTblExtend](User Defined Types/Trade.InstrumentsMetaDataConfigTblExtend.md) | 7.8 | Done (Batch 10) |
| [Trade.InstrumentsOrdersConfigTbl](User Defined Types/Trade.InstrumentsOrdersConfigTbl.md) | 7.8 | Done (Batch 10) |
| [Trade.InstrumentsTradingConfigTbl](User Defined Types/Trade.InstrumentsTradingConfigTbl.md) | 8.2 | Done (Batch 10) |
| [Trade.InstrumentsTradingConfigTblTmp](User Defined Types/Trade.InstrumentsTradingConfigTblTmp.md) | 7.2 | Done (Batch 10) |
| [Trade.InstrumentToFeeConfigType](User Defined Types/Trade.InstrumentToFeeConfigType.md) | 7.8 | Done (Batch 10) |
| [Trade.InstrumentToFeeConfigType_TRDOPS](User Defined Types/Trade.InstrumentToFeeConfigType_TRDOPS.md) | 8.0 | Done (Batch 10) |
| [Trade.InstrumentToFeeConfigTypeV2](User Defined Types/Trade.InstrumentToFeeConfigTypeV2.md) | 8.2 | Done (Batch 10) |
| [Trade.InterestRateOverrideIDsTbl_TRDOPS](User Defined Types/Trade.InterestRateOverrideIDsTbl_TRDOPS.md) | 7.5 | Done (Batch 10) |
| [Trade.InterestWhitelist](User Defined Types/Trade.InterestWhitelist.md) | 7.5 | Done (Batch 10) |
| [Trade.Leverage1MaintenanceMarginUpdate](User Defined Types/Trade.Leverage1MaintenanceMarginUpdate.md) | 7.8 | Done (Batch 10) |
| [Trade.LiquidityProviderContractTableType](User Defined Types/Trade.LiquidityProviderContractTableType.md) | 7.8 | Done (Batch 10) |
| [Trade.MimoPosition](User Defined Types/Trade.MimoPosition.md) | 6.5 | Done (Batch 10) |
| [Trade.MimoRawData](User Defined Types/Trade.MimoRawData.md) | 6.5 | Done (Batch 10) |
| [Trade.MirrorAndDividendTbl](User Defined Types/Trade.MirrorAndDividendTbl.md) | 6.5 | Done (Batch 10) |
| [Trade.MultiIndexDividendsInsertTbl](User Defined Types/Trade.MultiIndexDividendsInsertTbl.md) | 7.5 | Done (Batch 10) |
| [Trade.OMEMatchingTableType](User Defined Types/Trade.OMEMatchingTableType.md) | 7.2 | Done (Batch 10) |
| [Trade.OpenExecutionPlanTbl](User Defined Types/Trade.OpenExecutionPlanTbl.md) | 7.6 | Done (Batch 10) |
| [Trade.OpenPositionData](User Defined Types/Trade.OpenPositionData.md) | 7.2 | Done (Batch 10) |
| [Trade.OpenPositionDataSlim](User Defined Types/Trade.OpenPositionDataSlim.md) | 7.5 | Done (Batch 10) |
| [Trade.OrderForCloseSummaryReportData](User Defined Types/Trade.OrderForCloseSummaryReportData.md) | 7.6 | Done (Batch 10) |
| [Trade.OrderForOpenSummaryReportData](User Defined Types/Trade.OrderForOpenSummaryReportData.md) | 7.5 | Done (Batch 10) |
| [Trade.OrderIDsTbl](User Defined Types/Trade.OrderIDsTbl.md) | 8.0 | Done (Batch 7) |
| [Trade.OrdersForCloseType](User Defined Types/Trade.OrdersForCloseType.md) | 7.5 | Done (Batch 10) |
| [Trade.OrderStatusCheckResultTbl](User Defined Types/Trade.OrderStatusCheckResultTbl.md) | 7.4 | Done (Batch 10) |
| [Trade.OrderWithPositions_MOT](User Defined Types/Trade.OrderWithPositions_MOT.md) | 7.6 | Done (Batch 10) |
| [Trade.OrpanedPositionDetailsType](User Defined Types/Trade.OrpanedPositionDetailsType.md) | 7.5 | Done (Batch 10) |
| [Trade.OutputCustomer_ClosePosition_MOT](User Defined Types/Trade.OutputCustomer_ClosePosition_MOT.md) | 8.8 | Done (Batch 10) |
| [Trade.OutputPosition_ClosePosition_MOT](User Defined Types/Trade.OutputPosition_ClosePosition_MOT.md) | 8.5 | Done (Batch 10) |
| [Trade.PositionAirdropTbl](User Defined Types/Trade.PositionAirdropTbl.md) | 8.5 | Done (Batch 10) |
| [Trade.PositionAnsDividendTbl](User Defined Types/Trade.PositionAnsDividendTbl.md) | 8.5 | Done (Batch 10) |
| [Trade.PositionData_MOT](User Defined Types/Trade.PositionData_MOT.md) | 7.8 | Done (Batch 10) |
| [Trade.PositionIDsTbl](User Defined Types/Trade.PositionIDsTbl.md) | 8.5 | Done (Batch 7) |
| [Trade.PositionIDsTbl_MOT](User Defined Types/Trade.PositionIDsTbl_MOT.md) | 7.8 | Done (Batch 10) |
| [Trade.PositionList](User Defined Types/Trade.PositionList.md) | 7.8 | Done (Batch 10) |
| [Trade.PositionPriceRateIDTableType](User Defined Types/Trade.PositionPriceRateIDTableType.md) | 7.5 | Done (Batch 10) |
| [Trade.PositionsAndNewSL](User Defined Types/Trade.PositionsAndNewSL.md) | 7.5 | Done (Batch 10) |
| [Trade.PositionsForDividendPaymentTbl](User Defined Types/Trade.PositionsForDividendPaymentTbl.md) | 7.8 | Done (Batch 10) |
| [Trade.Rebalance](User Defined Types/Trade.Rebalance.md) | 7.5 | Done (Batch 10) |
| [Trade.RebalanceTbl](User Defined Types/Trade.RebalanceTbl.md) | 7.8 | Done (Batch 10) |
| [Trade.ReopenOperationDataTbl](User Defined Types/Trade.ReopenOperationDataTbl.md) | 6.5 | Done (Batch 10) |
| [Trade.ReverseSplitType](User Defined Types/Trade.ReverseSplitType.md) | 7.5 | Done (Batch 10) |
| [Trade.SetBalanceOpenPosition_MOT](User Defined Types/Trade.SetBalanceOpenPosition_MOT.md) | 7.2 | Done (Batch 10) |
| [Trade.SettlementTypeIDsTbl](User Defined Types/Trade.SettlementTypeIDsTbl.md) | 7.4 | Done (Batch 10) |
| [Trade.SymbolsList](User Defined Types/Trade.SymbolsList.md) | 8.5 | Done (Batch 7) |
| [Trade.SymbolsListTest](User Defined Types/Trade.SymbolsListTest.md) | 6.2 | Done (Batch 10) |
| [Trade.SyncConfigurationAdd](User Defined Types/Trade.SyncConfigurationAdd.md) | 7.2 | Done (Batch 10) |
| [Trade.SyncTSLTblType](User Defined Types/Trade.SyncTSLTblType.md) | 6.5 | Done (Batch 10) |
| [Trade.TicketNames](User Defined Types/Trade.TicketNames.md) | 8.0 | Done (Batch 7) |
| [Trade.TinyIntList](User Defined Types/Trade.TinyIntList.md) | 8.0 | Done (Batch 7) |
| [Trade.TradingOperationTypeIDs](User Defined Types/Trade.TradingOperationTypeIDs.md) | 6.7 | Done (Batch 10) |
| [Trade.Tv_FuturesInstrumentRiskSettings](User Defined Types/Trade.Tv_FuturesInstrumentRiskSettings.md) | 6.8 | Done (Batch 10) |
| [Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping](User Defined Types/Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping.md) | 7.0 | Done (Batch 10) |
| [Trade.Tv_InstrumentToTickerMapping](User Defined Types/Trade.Tv_InstrumentToTickerMapping.md) | 6.5 | Done (Batch 10) |
| [Trade.Tv_ProviderMarginMarkupByInstrument](User Defined Types/Trade.Tv_ProviderMarginMarkupByInstrument.md) | 6.5 | Done (Batch 10) |
| [Trade.Tv_RegisterMirror](User Defined Types/Trade.Tv_RegisterMirror.md) | 8.2 | Done (Batch 10) |
| [Trade.UnBlockOperations](User Defined Types/Trade.UnBlockOperations.md) | 6.5 | Done (Batch 10) |
| [Trade.UpdateIndexDividendsTbl](User Defined Types/Trade.UpdateIndexDividendsTbl.md) | 7.8 | Done (Batch 10) |
| [Trade.UpdateInterestRateOverrideTbl](User Defined Types/Trade.UpdateInterestRateOverrideTbl.md) | 7.2 | Done (Batch 10) |
| [Trade.UpdateInterestRateOverrideTbl_TRDOPS](User Defined Types/Trade.UpdateInterestRateOverrideTbl_TRDOPS.md) | 7.2 | Done (Batch 10) |
| [Trade.UpdateInterestRateTbl](User Defined Types/Trade.UpdateInterestRateTbl.md) | 7.2 | Done (Batch 10) |
| [Trade.UpdateInterestRateTbl_TRDOPS](User Defined Types/Trade.UpdateInterestRateTbl_TRDOPS.md) | 7.2 | Done (Batch 10) |
| [Trade.UpdateRolloverFeeThresholdTbl](User Defined Types/Trade.UpdateRolloverFeeThresholdTbl.md) | 7.0 | Done (Batch 10) |
| [Trade.UserPositionsTableType_MOT](User Defined Types/Trade.UserPositionsTableType_MOT.md) | 7.5 | Done (Batch 10) |
| [Trade.UsersDataFilters](User Defined Types/Trade.UsersDataFilters.md) | 7.3 | Done (Batch 10) |

