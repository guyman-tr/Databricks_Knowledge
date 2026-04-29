# DWH_dbo.Dim_Instrument — Column Lineage

## Source Objects

| # | Source Object | Type | Database | Schema | How Used | Wiki Available |
|---|--------------|------|----------|--------|----------|---------------|
| 1 | Trade.GetInstrument | View | etoro | Trade | Primary source via DWH_staging.etoro_Trade_GetInstrument — InstrumentID, InstrumentTypeID, Name, BuyCurrencyID, SellCurrencyID, TradeRange, DollarRatio, PipDifferenceThreshold, IsMajor | Yes |
| 2 | Dictionary.Currency | Table | etoro | Dictionary | Joined twice for BuyCurrency (Abbreviation) and SellCurrency (Abbreviation) via DWH_staging.etoro_Dictionary_Currency | Yes |
| 3 | Trade.InstrumentMetaData | Table | etoro | Trade | LEFT JOIN via DWH_staging.etoro_Trade_InstrumentMetaData — InstrumentDisplayName, Industry, CompanyInfo, Exchange, ISINCode, ISINCountryCode, Tradable, Symbol, SymbolFull | Yes |
| 4 | Trade.ProviderToInstrument | Table | etoro | Trade | LEFT JOIN via DWH_staging.etoro_Trade_ProviderToInstrument — BonusCreditUsePercent, Precision, AllowBuy, AllowSell, VisibleInternallyOnly, ProviderID, InitialMarginInAssetCurrency (as eToroMarginPerLot) | Yes |
| 5 | Trade.InstrumentCusip | View | etoro | Trade | LEFT JOIN via DWH_staging.etoro_Trade_InstrumentCusip — CUSIP | Yes |
| 6 | Trade.InstrumentGroups | Table | etoro | Trade | Subquery via DWH_staging.etoro_Trade_InstrumentGroups WHERE GroupID=25 — drives IsFuture flag | Yes |
| 7 | Trade.FuturesMetaData | Table | etoro | Trade | LEFT JOIN via DWH_staging.etoro_Trade_FuturesMetaData — Multiplier | Yes |
| 8 | Trade.FuturesInstrumentsInitialMarginByProviderMapping | Table | etoro | Trade | LEFT JOIN via DWH_staging — InitialMargin (as ProviderMarginPerLot) | Yes |
| 9 | Trade.Instrument | Table | etoro | Trade | LEFT JOIN via DWH_staging.etoro_Trade_Instrument — OperationMode | Yes |
| 10 | Rankings.StockInfo.InstrumentData | Table | Rankings | StockInfo | Via DWH_staging.Rankings_StockInfo_InstrumentData — ADV_Last3Months, MKTcap, SharesOutStanding (post-insert UPDATE) | No |
| 11 | Rankings.StockInfo.Metadata | Table | Rankings | StockInfo | Via DWH_staging.Rankings_StockInfo_Metadata — joins for KeyName resolution | No |
| 12 | Ext_Dim_Instrument_Classification_Static | Table | Synapse | DWH_dbo | Post-insert UPDATE — AssetClass, IndustryGroup | No |
| 13 | Ext_Dim_Instrument_StockInfo_InstrumentData_Platform | Table | Synapse | DWH_dbo | Post-insert UPDATE — PlatformSector, PlatformIndustry | No |
| 14 | Ext_Dim_Instrument_ReceivedOnPriceServerStatic | Table | Synapse | DWH_dbo | Post-insert UPDATE — ReceivedOnPriceServer | No |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | InstrumentID | Trade.GetInstrument | InstrumentID | Passthrough | Tier 1 |
| 2 | InstrumentTypeID | Trade.GetInstrument | InstrumentTypeID | Passthrough | Tier 1 |
| 3 | InstrumentType | SP_Dim_Instrument | InstrumentTypeID | CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other | Tier 2 |
| 4 | Name | Trade.GetInstrument | Name | Passthrough | Tier 1 |
| 5 | DWHInstrumentID | Trade.GetInstrument | InstrumentID | Alias (InstrumentID AS DWHInstrumentID) | Tier 1 |
| 6 | StatusID | SP_Dim_Instrument | — | Hardcoded 1 for all data rows, NULL for sentinel | Tier 2 |
| 7 | BuyCurrencyID | Trade.GetInstrument | BuyCurrencyID | Passthrough | Tier 1 |
| 8 | SellCurrencyID | Trade.GetInstrument | SellCurrencyID | Passthrough | Tier 1 |
| 9 | BuyCurrency | Dictionary.Currency | Abbreviation | Passthrough (buy-side join on BuyCurrencyID=CurrencyID) | Tier 1 |
| 10 | SellCurrency | Dictionary.Currency | Abbreviation | Passthrough (sell-side join on SellCurrencyID=CurrencyID) | Tier 1 |
| 11 | TradeRange | Trade.GetInstrument | TradeRange | Passthrough | Tier 1 |
| 12 | DollarRatio | Trade.GetInstrument | DollarRatio | Passthrough | Tier 1 |
| 13 | PipDifferenceThreshold | Trade.GetInstrument | PipDifferenceThreshold | Passthrough | Tier 1 |
| 14 | IsMajorID | Trade.GetInstrument | IsMajor | Rename (IsMajor AS IsMajorID) | Tier 1 |
| 15 | IsMajor | SP_Dim_Instrument | IsMajor | CASE WHEN b.IsMajor = 1 THEN 'Yes' ELSE 'No' | Tier 2 |
| 16 | UpdateDate | SP_Dim_Instrument | — | GETDATE() | Tier 2 |
| 17 | InsertDate | SP_Dim_Instrument | — | GETDATE() | Tier 2 |
| 18 | InstrumentDisplayName | Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough | Tier 1 |
| 19 | Industry | Trade.InstrumentMetaData | Industry | Passthrough | Tier 1 |
| 20 | CompanyInfo | Trade.InstrumentMetaData | CompanyInfo | Passthrough | Tier 1 |
| 21 | Exchange | Trade.InstrumentMetaData | Exchange | Passthrough | Tier 1 |
| 22 | ISINCode | Trade.InstrumentMetaData | ISINCode | Passthrough | Tier 1 |
| 23 | ISINCountryCode | Trade.InstrumentMetaData | ISINCountryCode | Passthrough | Tier 1 |
| 24 | Tradable | Trade.InstrumentMetaData | Tradable | CASE WHEN Tradable IN (1,0) THEN CAST(Tradable AS int) — preserves value, type cast only | Tier 1 |
| 25 | Symbol | Trade.InstrumentMetaData | Symbol | Passthrough | Tier 1 |
| 26 | ReceivedOnPriceServer | Ext_Dim_Instrument_ReceivedOnPriceServerStatic | ReceivedOnPriceServer | Post-insert UPDATE from PriceLog_History_CurrencyPrice_Active min(ReceivedOnPriceServer) | Tier 2 |
| 27 | BonusCreditUsePercent | Trade.ProviderToInstrument | BonusCreditUsePercent | Passthrough | Tier 1 |
| 28 | SymbolFull | Trade.InstrumentMetaData | SymbolFull | Passthrough | Tier 1 |
| 29 | CUSIP | Trade.InstrumentCusip | CUSIP | Passthrough | Tier 1 |
| 30 | Precision | Trade.ProviderToInstrument | Precision | Passthrough | Tier 1 |
| 31 | AllowBuy | Trade.ProviderToInstrument | AllowBuy | CAST(AllowBuy AS int) — type cast only | Tier 1 |
| 32 | AllowSell | Trade.ProviderToInstrument | AllowSell | CAST(AllowSell AS int) — type cast only | Tier 1 |
| 33 | AssetClass | Ext_Dim_Instrument_Classification_Static | AssetClass | Post-insert UPDATE | Tier 3 |
| 34 | IndustryGroup | Ext_Dim_Instrument_Classification_Static | IndustryGroup | Post-insert UPDATE | Tier 3 |
| 35 | ADV_Last3Months | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE WHERE KeyName='AverageDailyVolumeLast3Months-TTM' | Tier 2 |
| 36 | MKTcap | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE WHERE KeyName='MarketCapitalization-TTM' OR 'CryptoMarketCap' via ISNULL | Tier 2 |
| 37 | SharesOutStanding | Rankings.StockInfo.InstrumentData | NumVal | Post-insert UPDATE WHERE KeyName='SharesOutstandingCurrent-Annual' | Tier 2 |
| 38 | VisibleInternallyOnly | Trade.ProviderToInstrument | VisibleInternallyOnly | CAST(VisibleInternallyOnly AS int) — type cast only | Tier 1 |
| 39 | PlatformSector | Ext_Dim_Instrument_StockInfo_InstrumentData_Platform | PlatformSector | Post-insert UPDATE from Rankings MetadataID=8436 | Tier 2 |
| 40 | PlatformIndustry | Ext_Dim_Instrument_StockInfo_InstrumentData_Platform | PlatformIndustry | Post-insert UPDATE from Rankings MetadataID=8280 | Tier 2 |
| 41 | IsFuture | SP_Dim_Instrument | InstrumentGroups.GroupID=25 | CASE WHEN InstrumentID IN (SELECT InstrumentID FROM InstrumentGroups WHERE GroupID=25) THEN 1 ELSE 0 | Tier 2 |
| 42 | Multiplier | Trade.FuturesMetaData | Multiplier | Passthrough | Tier 1 |
| 43 | ProviderID | Trade.ProviderToInstrument | ProviderID | Passthrough | Tier 1 |
| 44 | ProviderMarginPerLot | Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | Rename (InitialMargin AS ProviderMarginPerLot) | Tier 1 |
| 45 | eToroMarginPerLot | Trade.ProviderToInstrument | InitialMarginInAssetCurrency | Rename (InitialMarginInAssetCurrency AS eToroMarginPerLot) | Tier 1 |
| 46 | SettlementTime | Trade.FuturesMetaData | SettlementTime | CAST(FORMAT(DATEPART(HOUR, SettlementTime)*100 + DATEPART(MINUTE, SettlementTime)*1, '00:00') AS time) — reformatted | Tier 1 |
| 47 | OperationMode | Trade.Instrument | OperationMode | Passthrough | Tier 1 |
