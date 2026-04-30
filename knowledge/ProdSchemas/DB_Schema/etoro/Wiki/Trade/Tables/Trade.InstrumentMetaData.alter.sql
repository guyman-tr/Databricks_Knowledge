-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentMetaData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrumentmetadata
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrumentmetadata (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata SET TBLPROPERTIES (
    'comment' = 'Extended metadata for each tradeable instrument (display names, symbols, images, regulatory identifiers, fee config) - UI presentation and operational config layer that supplements Trade.Instrument. Source: etoro.Trade.InstrumentMetaData on the etoro production database, ingested via the Generic Pipeline (Override strategy, 30-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentMetaData',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '30'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentID COMMENT 'Primary key. References Trade.Instrument.InstrumentID. Same value as Dictionary.Currency.CurrencyID for the instrument. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentDisplayName COMMENT 'Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentTypeImage COMMENT 'URL or path for instrument type icon. Nullable; CDN avatars often built from InstrumentID instead (InstrumentImageSmall/etc). (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN Ticker COMMENT 'Ticker path for price/quote APIs. Trade.InsertInstrumentMetaData sets ''/ticker'' by default. Used for external ticker lookups. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN ChartTicker COMMENT 'Alternate ticker for charting services. Null when same as Ticker. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentImageSmall COMMENT 'CDN URL for small avatar. Trade.InsertInstrumentMetaData builds: etoro-cdn.etorostatic.com/market-avatars/{InstrumentID}/35x35.png. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentImageMedium COMMENT 'CDN URL for medium avatar. Pattern: .../50x50.png. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentImageLarge COMMENT 'CDN URL for large avatar. Pattern: .../150x150.png. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN Exchange COMMENT 'Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN Industry COMMENT 'Industry sector label (e.g., "Technology", "Consumer Goods"). Used for stocks; NULL for forex/crypto. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN CompanyInfo COMMENT 'Extended company/instrument description. Nullable. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN DailyRolloverFee COMMENT 'Overnight holding fee rate for weekdays, per lot/unit. NULL when not configured. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN WeekendRolloverFee COMMENT 'Overnight fee for weekend holds. NULL when not configured. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN ContractRolloverFee COMMENT 'Rollover fee for contract-based instruments (futures, etc.). NULL when N/A. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentVisible COMMENT 'Visibility: 1 = shown in UI, 0 = hidden. Default 1. dbo.EnableInstrument/Trade.DisableInstrument set this. Filtered by GetInstrumentsRates, GetEnabledAndListedInstruments. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN Symbol COMMENT 'Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN CandleTimeframeGroup COMMENT 'FK to Trade.CandleIntervalGroups.GroupID. 1=Forex, 2=Stocks. Controls which chart intervals are available. See Trade.CandleIntervalGroups. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN SymbolFull COMMENT 'Full/canonical symbol, UNIQUE. Used for instrument lookup (e.g., Trade.GetOrdersForExecutionReportV2_JUNK: SELECT InstrumentID FROM InstrumentMetaData WHERE Symbol = @Symbol). Primary identifier in Security Ops API. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN Tradable COMMENT '1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. Required for GetInstrumentsRates, GetEnabledAndListedInstruments. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN ExchangeID COMMENT 'FK to Price.Exchange. Primary exchange for this instrument. Used for fee config (Trade.ExchangeInstrumentFeeDefinition), price feed routing. trg_update_Trade_InstrumentMetaData validates ExchangeID exists in ExchangeInstrumentFeeDefinition. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN StocksIndustryID COMMENT 'Industry classification for stocks. Dictionary.StocksIndustry or similar. NULL for forex/crypto. Used in Trade.GetInstrumentMetaDataExtend as Industry (ISNULL to 0). (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number. Required for stocks (e.g., US0378331005 for Apple). NULL for forex/crypto. Used for compliance and dividend matching. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN ISINCountryCode COMMENT 'Country prefix of ISIN (e.g., "US"). Audit-tracked. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN ContractExpire COMMENT '1 = instrument has expiry (futures, options). 0 = no expiry (stocks, forex, crypto). Default 0. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentTypeSubCategoryID COMMENT 'Subclassification within asset class. References Dictionary or lookup. NULL for most instruments. Trade.GetAllInstrumentTypeSubCategoryForAPI exposes subcategories. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN InstrumentTypeID COMMENT 'Asset class. FK to Dictionary.CurrencyType.CurrencyTypeID. 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. See Dictionary.CurrencyType. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN PriceSourceID COMMENT 'Price feed source. 0 = eToro internal. 3 = Xignite (stocks/ETF). Validated via Dictionary.PriceSourceName. Used for price routing and allocation. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN Cusip COMMENT 'CUSIP identifier (US/Canada securities). Trade.UpdateCusip, Trade.GetInstrumentCusip, Trade.CusipsToInstrumentIDs. Indexed (IX_Cusip). (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN CreateDate COMMENT 'UTC timestamp when the instrument metadata row was created. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN UnderlyingExchangeID COMMENT 'Exchange for underlying when instrument is derivative. NULL for spot instruments. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). Current DB login for audit context. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context for audit. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN SysStartTime COMMENT 'System-versioning start. Generated always as row start. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN SysEndTime COMMENT 'System-versioning end. Generated always as row end. History in History.InstrumentMetaData. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN SEDOL COMMENT 'SEDOL identifier (UK securities). Alternative to ISIN/CUSIP for some instruments. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN SubCategory COMMENT 'Human-readable subcategory label. May duplicate InstrumentTypeSubCategoryID. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentmetadata ALTER COLUMN CFICode COMMENT 'Classification of Financial Instruments code (ISO 10962). 6-character code for instrument classification. Trade.InsertInstrumentMetaData accepts @CFICode. (Tier 1 - upstream wiki, etoro.Trade.InstrumentMetaData)';

