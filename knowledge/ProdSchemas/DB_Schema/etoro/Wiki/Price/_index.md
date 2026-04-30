# Price Schema - Documentation Index

> Database: etoro | Schema: Price | Generated: 2026-03-18
> Batch orchestration index. Run `/sql-semantic-doc-batch etoro DB, Price Schema` to continue.

| Metric | Value |
|--------|-------|
| **Total Objects** | 110 |
| **Documented** | 110 (100%) |
| **Remaining** | 0 |
| **Last Updated** | 2026-03-18 |
| **Batches Completed** | 5 |

---

---

## User Defined Types (10)

| Object | Quality | Status |
|--------|---------|--------|
| [Price.CurrencyPriceSeconadryTable](User%20Defined%20Types/Price.CurrencyPriceSeconadryTable.md) | 8.5 | Done (Batch 1) |
| [Price.CurrencyPriceSeconadryTableWithUnitMargin](User%20Defined%20Types/Price.CurrencyPriceSeconadryTableWithUnitMargin.md) | 8.5 | Done (Batch 1) |
| [Price.CurrencyPriceTable](User%20Defined%20Types/Price.CurrencyPriceTable.md) | 8.5 | Done (Batch 1) |
| [Price.CurrencyPriceTableWithConversionRate](User%20Defined%20Types/Price.CurrencyPriceTableWithConversionRate.md) | 8.5 | Done (Batch 1) |
| [Price.CurrencyPriceTableWithUnitMargin](User%20Defined%20Types/Price.CurrencyPriceTableWithUnitMargin.md) | 8.5 | Done (Batch 1) |
| [Price.ExchangeIDList](User%20Defined%20Types/Price.ExchangeIDList.md) | 8.0 | Done (Batch 1) |
| [Price.InstrumentDailyUnitMarginTable](User%20Defined%20Types/Price.InstrumentDailyUnitMarginTable.md) | 8.5 | Done (Batch 1) |
| [Price.InstrumentsIDsList](User%20Defined%20Types/Price.InstrumentsIDsList.md) | 8.5 | Done (Batch 1) |
| [Price.PricingConfigurationList](User%20Defined%20Types/Price.PricingConfigurationList.md) | 8.8 | Done (Batch 1) |
| [Price.ThresholdsTypeValue](User%20Defined%20Types/Price.ThresholdsTypeValue.md) | 8.8 | Done (Batch 1) |

---

## Tables (39)

### Level 0 - No Price-internal dependencies (31 tables)

| Object | Quality | Status |
|--------|---------|--------|
| [Price.AccountRateSource](Tables/Price.AccountRateSource.md) | 9.2 | Done (Batch 1) |
| [Price.ActiveSkew](Tables/Price.ActiveSkew.md) | 8.3 | Done (Batch 1) |
| [Price.BuyRatio](Tables/Price.BuyRatio.md) | 8.5 | Done (Batch 1) |
| [Price.BuyRatio_old](Tables/Price.BuyRatio_old.md) | 7.5 | Done (Batch 1) |
| [Price.BuyRatioSkewConditions](Tables/Price.BuyRatioSkewConditions.md) | 8.5 | Done (Batch 1) |
| [Price.BuyRatioThresholds](Tables/Price.BuyRatioThresholds.md) | 8.8 | Done (Batch 1) |
| [Price.CustomInstruments](Tables/Price.CustomInstruments.md) | 9.0 | Done (Batch 1) |
| [Price.CustomInstrumentsConfiguration](Tables/Price.CustomInstrumentsConfiguration.md) | 9.0 | Done (Batch 1) |
| [Price.Exchange](Tables/Price.Exchange.md) | 9.2 | Done (Batch 1) |
| [Price.FuturesContracts](Tables/Price.FuturesContracts.md) | 8.8 | Done (Batch 1) |
| [Price.InstrumentConfiguration](Tables/Price.InstrumentConfiguration.md) | 9.0 | Done (Batch 1) |
| [Price.InstrumentDailyUnitMargin](Tables/Price.InstrumentDailyUnitMargin.md) | 9.0 | Done (Batch 1) |
| [Price.InstrumentTypeConfiguration](Tables/Price.InstrumentTypeConfiguration.md) | 9.2 | Done (Batch 1) |
| [Price.LiquidityAccountToInstrument](Tables/Price.LiquidityAccountToInstrument.md) | 9.2 | Done (Batch 1) |
| [Price.LiquidityAccountToInstrument_bck_20210722](Tables/Price.LiquidityAccountToInstrument_bck_20210722.md) | 7.5 | Done (Batch 1) |
| [Price.BenchmarkFeedConfiguration](Tables/Price.BenchmarkFeedConfiguration.md) | 8.5 | Done (Batch 2) |
| [Price.ExchangeNameToProvider](Tables/Price.ExchangeNameToProvider.md) | 7.8 | Done (Batch 2) |
| [Price.InstrumentRateSources](Tables/Price.InstrumentRateSources.md) | 9.2 | Done (Batch 2) |
| [Price.LiquidityProviderPriceSource](Tables/Price.LiquidityProviderPriceSource.md) | 8.8 | Done (Batch 2) |
| [Price.LiquidityProviderQuantities](Tables/Price.LiquidityProviderQuantities.md) | 7.5 | Done (Batch 2) |
| [Price.MarkupInstrumentAccounts](Tables/Price.MarkupInstrumentAccounts.md) | 7.5 | Done (Batch 2) |
| [Price.OMPDActiveThreshold](Tables/Price.OMPDActiveThreshold.md) | 9.0 | Done (Batch 2) |
| [Price.OMPDThresholdValues](Tables/Price.OMPDThresholdValues.md) | 9.2 | Done (Batch 2) |
| [Price.PCSToLiquidityAccount](Tables/Price.PCSToLiquidityAccount.md) | 9.0 | Done (Batch 2) |
| [Price.PriceAlgoSkewConditions](Tables/Price.PriceAlgoSkewConditions.md) | 7.0 | Done (Batch 2) |
| [Price.PriceAlgoThresholds](Tables/Price.PriceAlgoThresholds.md) | 7.0 | Done (Batch 2) |
| [Price.PriceServerToLiquidityAccount](Tables/Price.PriceServerToLiquidityAccount.md) | 7.8 | Done (Batch 2) |
| [Price.PricingConfigurations](Tables/Price.PricingConfigurations.md) | 9.2 | Done (Batch 2) |
| [Price.SkewCostThresholds](Tables/Price.SkewCostThresholds.md) | 7.0 | Done (Batch 2) |
| [Price.SkewModels](Tables/Price.SkewModels.md) | 9.2 | Done (Batch 2) |
| [Price.SpotInstrumentMapping](Tables/Price.SpotInstrumentMapping.md) | 8.8 | Done (Batch 2) |
| [Price.SpotInstrumentsMapping](Tables/Price.SpotInstrumentsMapping.md) | 7.5 | Done (Batch 2) |
| [Price.SpreadThresholdConfiguration](Tables/Price.SpreadThresholdConfiguration.md) | 8.5 | Done (Batch 2) |
| [Price.Templates](Tables/Price.Templates.md) | 9.0 | Done (Batch 2) |

### Level 1 - Depends on Price Level-0 tables (8 tables)

| Object | Quality | Status | Key Dependencies |
|--------|---------|--------|-----------------|
| [Price.BenchmarkFeedConfiguration](Tables/Price.BenchmarkFeedConfiguration.md) | 8.5 | Done (Batch 2) | Price.AccountRateSource, Dictionary.CurrencyType |
| [Price.ExchangeNameToProvider](Tables/Price.ExchangeNameToProvider.md) | 7.8 | Done (Batch 2) | Price.Exchange, Trade.LiquidityProviderType |
| [Price.InstanceIDToSkewModelID](Tables/Price.InstanceIDToSkewModelID.md) | 9.0 | Done (Batch 2) | Price.SkewModels |
| [Price.InstrumentRateSources](Tables/Price.InstrumentRateSources.md) | 9.2 | Done (Batch 2) | Price.AccountRateSource, Trade.Instrument |
| [Price.InstrumentSkewModel](Tables/Price.InstrumentSkewModel.md) | 8.8 | Done (Batch 2) | Price.SkewModels, Trade.Instrument |
| [Price.InstrumentToTemplate](Tables/Price.InstrumentToTemplate.md) | 9.0 | Done (Batch 2) | Price.Templates, Trade.Instrument |
| [Price.SkewModelValue](Tables/Price.SkewModelValue.md) | 9.2 | Done (Batch 2) | Price.SkewModels |
| [Price.TemplateRateSourceAllocations](Tables/Price.TemplateRateSourceAllocations.md) | 9.0 | Done (Batch 2) | Price.AccountRateSource, Price.Templates |

---

## Synonyms (1)

| Object | Quality | Status | Target |
|--------|---------|--------|--------|
| [Price.Instrument](Synonyms/Price.Instrument.md) | 7.5 | Done (Batch 2) | [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument] |

---

## Views (16)

| Object | Quality | Status |
|--------|---------|--------|
| [Price.GetAccountRateSourceMapping](Views/Price.GetAccountRateSourceMapping.md) | 8.8 | Done (Batch 3) |
| [Price.GetAllowedAccountRateSources](Views/Price.GetAllowedAccountRateSources.md) | 8.8 | Done (Batch 3) |
| [Price.GetCrossToMajorConversions](Views/Price.GetCrossToMajorConversions.md) | 9.0 | Done (Batch 3) |
| [Price.GetInstrumentAllocationData](Views/Price.GetInstrumentAllocationData.md) | 9.2 | Done (Batch 3) |
| [Price.GetInstrumentConfiguration](Views/Price.GetInstrumentConfiguration.md) | 8.8 | Done (Batch 3) |
| [Price.GetInstrumentDisplayData](Views/Price.GetInstrumentDisplayData.md) | 9.0 | Done (Batch 3) |
| [Price.GetInstrumentPriceSources](Views/Price.GetInstrumentPriceSources.md) | 8.8 | Done (Batch 3) |
| [Price.GetInstrumentRateSources](Views/Price.GetInstrumentRateSources.md) | 9.2 | Done (Batch 3) |
| [Price.GetInstrumentsShards](Views/Price.GetInstrumentsShards.md) | 9.0 | Done (Batch 3) |
| [Price.GetMarkupInstrumentAccounts](Views/Price.GetMarkupInstrumentAccounts.md) | 8.8 | Done (Batch 3) |
| [Price.GetPriceAccounts](Views/Price.GetPriceAccounts.md) | 9.0 | Done (Batch 3) |
| [Price.GetPriceServerAccountAllocation](Views/Price.GetPriceServerAccountAllocation.md) | 8.8 | Done (Batch 3) |
| [Price.GetRateSourceConfiguration](Views/Price.GetRateSourceConfiguration.md) | 9.0 | Done (Batch 3) |
| [Price.GetSpreadConfiguration](Views/Price.GetSpreadConfiguration.md) | 9.0 | Done (Batch 3) |
| [Price.GetSpreadConfigurationFeed](Views/Price.GetSpreadConfigurationFeed.md) | 9.2 | Done (Batch 3) |
| [Price.GetTopRateSourceAllocations](Views/Price.GetTopRateSourceAllocations.md) | 9.0 | Done (Batch 3) |

---

## Stored Procedures (44)

| Object | Quality | Status |
|--------|---------|--------|
| [Price.AddBuyRatio](Stored%20Procedures/Price.AddBuyRatio.md) | 8.8 | Done (Batch 3) |
| [Price.CheckPricingConfigurationsExistence](Stored%20Procedures/Price.CheckPricingConfigurationsExistence.md) | 8.8 | Done (Batch 3) |
| [Price.CleanUnmappedInstrumentRateSources](Stored%20Procedures/Price.CleanUnmappedInstrumentRateSources.md) | 8.7 | Done (Batch 3) |
| [Price.CreateActiveOMPDThresholdByInstrumentId](Stored%20Procedures/Price.CreateActiveOMPDThresholdByInstrumentId.md) | 9.0 | Done (Batch 3) |
| [Price.CreateInstrumentOMPDThresholdByInstrumentId](Stored%20Procedures/Price.CreateInstrumentOMPDThresholdByInstrumentId.md) | 9.0 | Done (Batch 3) |
| [Price.DeleteLiquidityProviderPriceSource](Stored%20Procedures/Price.DeleteLiquidityProviderPriceSource.md) | 9.0 | Done (Batch 3) |
| [Price.DeleteOMPDThresholdByInstrumentID](Stored%20Procedures/Price.DeleteOMPDThresholdByInstrumentID.md) | 9.0 | Done (Batch 3) |
| [Price.DelistInstrument](Stored%20Procedures/Price.DelistInstrument.md) | 8.8 | Done (Batch 4) |
| [Price.FillGapsInDailyUnitMargin](Stored%20Procedures/Price.FillGapsInDailyUnitMargin.md) | 8.8 | Done (Batch 3) |
| [Price.GetActiveOMPDThresholdByInstrumentIds](Stored%20Procedures/Price.GetActiveOMPDThresholdByInstrumentIds.md) | 9.2 | Done (Batch 3) |
| [Price.GetAllInstrumentsDataByInstrumentTypeID](Stored%20Procedures/Price.GetAllInstrumentsDataByInstrumentTypeID.md) | 9.0 | Done (Batch 4) |
| [Price.GetAllLiquidityProviderPriceSource](Stored%20Procedures/Price.GetAllLiquidityProviderPriceSource.md) | 8.8 | Done (Batch 4) |
| [Price.GetCurrentPricesSnapshot](Stored%20Procedures/Price.GetCurrentPricesSnapshot.md) | 8.8 | Done (Batch 4) |
| [Price.GetCustomCrossInstruments](Stored%20Procedures/Price.GetCustomCrossInstruments.md) | 9.0 | Done (Batch 4) |
| [Price.GetInstrumentsOMPDThresholdByExchangeIds](Stored%20Procedures/Price.GetInstrumentsOMPDThresholdByExchangeIds.md) | 9.0 | Done (Batch 4) |
| [Price.GetInstrumentsOMPDThresholdByInstrumentIds](Stored%20Procedures/Price.GetInstrumentsOMPDThresholdByInstrumentIds.md) | 9.0 | Done (Batch 4) |
| [Price.GetInstrumentTypeIDByInstrumentID](Stored%20Procedures/Price.GetInstrumentTypeIDByInstrumentID.md) | 8.5 | Done (Batch 4) |
| [Price.GetNonExpiredFutures](Stored%20Procedures/Price.GetNonExpiredFutures.md) | 8.5 | Done (Batch 4) |
| [Price.GetOMPDThresholdTypes](Stored%20Procedures/Price.GetOMPDThresholdTypes.md) | 8.5 | Done (Batch 4) |
| [Price.GetPriceAllocationDiscrepancy](Stored%20Procedures/Price.GetPriceAllocationDiscrepancy.md) | 8.5 | Done (Batch 4) |
| [Price.GetPricingConfigurations](Stored%20Procedures/Price.GetPricingConfigurations.md) | 9.0 | Done (Batch 4) |
| [Price.GetPricingConfigurationsByInstrumentIds](Stored%20Procedures/Price.GetPricingConfigurationsByInstrumentIds.md) | 8.8 | Done (Batch 4) |
| [Price.GetTickerInfo](Stored%20Procedures/Price.GetTickerInfo.md) | 9.0 | Done (Batch 4) |
| [Price.InsertLiquidityProviderPriceSource](Stored%20Procedures/Price.InsertLiquidityProviderPriceSource.md) | 9.0 | Done (Batch 4) |
| [Price.InsertPricingConfiguration](Stored%20Procedures/Price.InsertPricingConfiguration.md) | 9.0 | Done (Batch 4) |
| [Price.InstrumentRateSourceAdd](Stored%20Procedures/Price.InstrumentRateSourceAdd.md) | 8.8 | Done (Batch 4) |
| [Price.InstrumentRateSourceEdit](Stored%20Procedures/Price.InstrumentRateSourceEdit.md) | 8.8 | Done (Batch 4) |
| [Price.SetActiveSkew](Stored%20Procedures/Price.SetActiveSkew.md) | 9.0 | Done (Batch 4) |
| [Price.SetCurrencyPriceBulk](Stored%20Procedures/Price.SetCurrencyPriceBulk.md) | 7.5 | Done (Batch 4) |
| [Price.SetCurrencyPriceBulkSecondary](Stored%20Procedures/Price.SetCurrencyPriceBulkSecondary.md) | 8.8 | Done (Batch 4) |
| [Price.SetCurrencyPriceBulkSecondaryWithUnitMargin](Stored%20Procedures/Price.SetCurrencyPriceBulkSecondaryWithUnitMargin.md) | 8.8 | Done (Batch 4) |
| [Price.SetCurrencyPriceBulkWithConversionRate](Stored%20Procedures/Price.SetCurrencyPriceBulkWithConversionRate.md) | 8.8 | Done (Batch 4) |
| [Price.SetCurrencyPriceBulkWithUnitMargin](Stored%20Procedures/Price.SetCurrencyPriceBulkWithUnitMargin.md) | 8.8 | Done (Batch 4) |
| [Price.SetDailyUnitMarginBulk](Stored%20Procedures/Price.SetDailyUnitMarginBulk.md) | 8.8 | Done (Batch 4) |
| [Price.SetSpread](Stored%20Procedures/Price.SetSpread.md) | 8.5 | Done (Batch 5) |
| [Price.SwapContracts](Stored%20Procedures/Price.SwapContracts.md) | 9.0 | Done (Batch 5) |
| [Price.SyncPriceConfiguration](Stored%20Procedures/Price.SyncPriceConfiguration.md) | 8.0 | Done (Batch 5) |
| [Price.UpdateActiveOMPDThresholdByInstrumentId](Stored%20Procedures/Price.UpdateActiveOMPDThresholdByInstrumentId.md) | 9.0 | Done (Batch 5) |
| [Price.UpdateInstrumentOMPDThresholdByInstrumentId](Stored%20Procedures/Price.UpdateInstrumentOMPDThresholdByInstrumentId.md) | 9.0 | Done (Batch 5) |
| [Price.UpdateInstrumentRateSources](Stored%20Procedures/Price.UpdateInstrumentRateSources.md) | 9.0 | Done (Batch 5) |
| [Price.UpdateInstrumentThresholdsWithActiveThreshold](Stored%20Procedures/Price.UpdateInstrumentThresholdsWithActiveThreshold.md) | 9.2 | Done (Batch 5) |
| [Price.UpdateLiquidityProviderPriceSource](Stored%20Procedures/Price.UpdateLiquidityProviderPriceSource.md) | 9.2 | Done (Batch 5) |
| [Price.UpdatePricingConfigurations](Stored%20Procedures/Price.UpdatePricingConfigurations.md) | 9.2 | Done (Batch 5) |
| [Price.UpsertSkewModelValue](Stored%20Procedures/Price.UpsertSkewModelValue.md) | 9.0 | Done (Batch 5) |

---

## Dependency Graph Summary

### Cross-Schema Dependencies (all resolved - referenced schemas fully documented)

| Referenced Object | Used By (Price tables) |
|------------------|----------------------|
| Trade.Instrument | BuyRatioSkewConditions, CustomInstruments, CustomInstrumentsConfiguration, FuturesContracts, InstrumentConfiguration, InstrumentDailyUnitMargin, InstrumentRateSources, InstrumentSkewModel, InstrumentToTemplate, LiquidityAccountToInstrument, LiquidityProviderQuantities, MarkupInstrumentAccounts, PriceAlgoSkewConditions, SkewCostThresholds, SpotInstrumentMapping, SpotInstrumentsMapping, SpreadThresholdConfiguration |
| Trade.LiquidityAccounts | FuturesContracts, LiquidityAccountToInstrument, MarkupInstrumentAccounts, PCSToLiquidityAccount, PriceServerToLiquidityAccount, SpotInstrumentMapping, SpotInstrumentsMapping |
| Trade.LiquidityProviderType | ExchangeNameToProvider, LiquidityProviderQuantities |
| Trade.LiquidityProviders | LiquidityProviderPriceSource |
| Trade.InstrumentMetaData | OMPDActiveThreshold |
| Dictionary.Country | Exchange |
| Dictionary.CurrencyType | BenchmarkFeedConfiguration, InstrumentTypeConfiguration |
| Dictionary.OMPDThresholdType | OMPDActiveThreshold, OMPDThresholdValues |
| Dictionary.SpreadThresholdType | SpreadThresholdConfiguration |
| Dictionary.PriceSourceName | LiquidityProviderPriceSource |

### Price-Internal Dependencies (Level 1 depends on Level 0)

| Level 0 Table | Consumed By (Level 1) |
|--------------|----------------------|
| Price.AccountRateSource | BenchmarkFeedConfiguration, InstrumentRateSources, TemplateRateSourceAllocations |
| Price.Exchange | ExchangeNameToProvider |
| Price.SkewModels | InstanceIDToSkewModelID, InstrumentSkewModel, SkewModelValue |
| Price.Templates | InstrumentToTemplate, TemplateRateSourceAllocations |
