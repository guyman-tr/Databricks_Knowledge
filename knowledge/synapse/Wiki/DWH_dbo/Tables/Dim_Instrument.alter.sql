-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Instrument
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_Instrument` is the DWH''s master reference for all tradeable instruments on the eToro platform. It extends the foundational trade pair definition from `Trade.Instrument` (which specifies the buy/sell currency pairing for each instrument) with rich analytics metadata: display names and company info from `Trade.InstrumentMetaData`, trading configuration from `Trade.ProviderToInstrument`, financial market data (market cap, ADV, shares outstanding) from the Rankings/StockInfo system, Bloomberg-style asset classification, and futures-specific parameters. The result is a 47-column analytics hub that serves as the primary instrument lookup for fact table enrichment across DWH analytics. The production source is `etoro.Trade.GetInstrument` (a view on the production etoroDB-REAL server), which combines `Trade.Instrument` with multiple related tables. The Generic Pipeline exports this view daily to `Bronze/etoro/Trade/GetInstrument/` (UC: `trading.bronze_etoro_trade_getinstrument`). The DWH ETL SP (`SP_D...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (InstrumentID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentID COMMENT 'Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentTypeID COMMENT 'From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentType COMMENT 'ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Name COMMENT 'Display name computed by Trade.GetInstrument as BuyCurrency Abbreviation + ''/'' + SellCurrency Abbreviation (e.g., EUR/USD for forex, AAPL/USD for stocks). Not a company name; see InstrumentDisplayName for human-readable labels.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN DWHInstrumentID COMMENT 'Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all data rows; NULL for sentinel row (InstrumentID=0). (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN BuyCurrencyID COMMENT 'Buy-side currency abbreviation. For forex: base currency code; for stocks: the asset code (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SellCurrencyID COMMENT 'FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN BuyCurrency COMMENT 'Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side join. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SellCurrency COMMENT 'Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN TradeRange COMMENT 'Allowed trade range (pip distance) for pending orders. From Trade.Instrument. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN DollarRatio COMMENT 'Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN PipDifferenceThreshold COMMENT 'Max pip difference for price validation. From Trade.Instrument. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IsMajorID COMMENT '1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit). (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IsMajor COMMENT 'ETL-computed label from IsMajorID: ''Yes'' when IsMajor=1, ''No'' otherwise. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN UpdateDate COMMENT 'ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InsertDate COMMENT 'ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentDisplayName COMMENT 'Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Industry COMMENT 'Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN CompanyInfo COMMENT 'Extended company/instrument description. Nullable. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Exchange COMMENT 'Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number. Required for stocks (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ISINCountryCode COMMENT 'Country prefix of ISIN (e.g., "US"). Audit-tracked. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Tradable COMMENT '1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Symbol COMMENT 'Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ReceivedOnPriceServer COMMENT 'Earliest price-server timestamp from PriceLog_History_CurrencyPrice_Active for the prior day, persisted via Ext_Dim_Instrument_ReceivedOnPriceServerStatic. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN BonusCreditUsePercent COMMENT 'Percentage of position that can use bonus credit. From Trade.ProviderToInstrument. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SymbolFull COMMENT 'Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 - Trade.InstrumentMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN CUSIP COMMENT 'CUSIP code sourced from Trade.InstrumentCusip (not InstrumentMetaData). Committee on Uniform Securities Identification Procedures identifier for US/Canada securities. NULL for forex, crypto, and many non-US instruments.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Precision COMMENT 'Decimal places for price display and rounding. From Trade.ProviderToInstrument. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN AllowBuy COMMENT '1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN AllowSell COMMENT '1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN AssetClass COMMENT 'Asset class classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. NULL for 13,557 of 15,707 rows. (Tier 3 - Ext_Dim_Instrument_Classification_Static, no upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IndustryGroup COMMENT 'Industry group classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. (Tier 3 - Ext_Dim_Instrument_Classification_Static, no upstream wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ADV_Last3Months COMMENT 'Average daily trading volume over the last 3 months (TTM). From Rankings.StockInfo.InstrumentData MetadataID=8557. (Tier 2 - SP_Dim_Instrument, Rankings.StockInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN MKTcap COMMENT 'Market capitalization. ISNULL(MarketCapitalization-TTM, CryptoMarketCap) - uses stock market cap when available, falls back to crypto market cap. From Rankings.StockInfo MetadataID=8735/9315. (Tier 2 - SP_Dim_Instrument, Rankings.StockInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SharesOutStanding COMMENT 'Current shares outstanding (annual). From Rankings.StockInfo.InstrumentData MetadataID=8444. (Tier 2 - SP_Dim_Instrument, Rankings.StockInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN VisibleInternallyOnly COMMENT '1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN PlatformSector COMMENT 'Platform-level sector classification from Rankings.StockInfo MetadataID=8436 (StrVal pivot). E.g., "Electronic Technology", "Technology Services". (Tier 2 - SP_Dim_Instrument, Rankings.StockInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN PlatformIndustry COMMENT 'Platform-level industry classification from Rankings.StockInfo MetadataID=8280 (StrVal pivot). E.g., "Telecommunications Equipment", "Internet Software Or Services". (Tier 2 - SP_Dim_Instrument, Rankings.StockInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IsFuture COMMENT '1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Multiplier COMMENT 'Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows). (Tier 1 - Trade.FuturesMetaData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ProviderID COMMENT 'FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tribe). From Trade.ProviderToInstrument. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ProviderMarginPerLot COMMENT 'Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument''s base currency. Renamed from InitialMargin. (Tier 1 - Trade.FuturesInstrumentsInitialMarginByProviderMapping)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN eToroMarginPerLot COMMENT 'Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument. (Tier 1 - Trade.ProviderToInstrument)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SettlementTime COMMENT 'Time-of-day settlement from Trade.FuturesMetaData, reformatted in SP_Dim_Instrument via FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), ''00:00'') and cast to TIME. Primarily relevant for futures instruments. NULL for non-futures.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN OperationMode COMMENT 'Trading operation mode: 0=Standard (13,140 instruments), 1=Alternate (2,566, primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). From Trade.Instrument. (Tier 1 - Trade.Instrument)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN DWHInstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN BuyCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SellCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN BuyCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN TradeRange SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN DollarRatio SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN PipDifferenceThreshold SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IsMajorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IsMajor SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Industry SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN CompanyInfo SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ISINCountryCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Tradable SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ReceivedOnPriceServer SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN BonusCreditUsePercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SymbolFull SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN CUSIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Precision SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN AllowBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN AllowSell SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN AssetClass SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IndustryGroup SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ADV_Last3Months SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN MKTcap SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SharesOutStanding SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN VisibleInternallyOnly SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN PlatformSector SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN PlatformIndustry SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN Multiplier SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ProviderID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN ProviderMarginPerLot SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN eToroMarginPerLot SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN SettlementTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument ALTER COLUMN OperationMode SET TAGS ('pii' = 'none');

