-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InstrumentMetaData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_instrumentmetadata
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_instrumentmetadata (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table storing prior row versions of Trade.InstrumentMetaData, capturing every change to instrument display names, tickers, fees, visibility, and classification for all tradable instruments. Source: etoro.History.InstrumentMetaData on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InstrumentMetaData',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentID COMMENT 'The instrument this history version belongs to. PK in Trade.InstrumentMetaData (one live row per instrument). Multiple history rows here for the same InstrumentID capture its metadata evolution. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentDisplayName COMMENT 'Human-readable display name shown in the eToro UI for this instrument (e.g., "EUR/USD", "Apple", "Bitcoin"). Audited by AuditInsert/Update/Delete triggers -> History.AuditHistory. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentTypeImage COMMENT 'URL or path to the image representing the instrument type category (not the instrument itself). (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN Ticker COMMENT 'Ticker symbol used for price feed lookup. Observed value: "/ticker" - may be overridden per instrument. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN ChartTicker COMMENT 'Ticker symbol used specifically for charting data source lookups. May differ from Ticker for some instruments. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentImageSmall COMMENT 'URL to the small (thumbnail) icon image for this instrument, displayed in instrument lists. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentImageMedium COMMENT 'URL to the medium-size image for this instrument. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentImageLarge COMMENT 'URL to the large image for this instrument, used in instrument detail pages. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN Exchange COMMENT 'Exchange name as a free-text string (e.g., "NASDAQ", "NYSE"). Supplemented by ExchangeID (the structured FK). This column may be a legacy display field. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN Industry COMMENT 'Industry classification for stock instruments (e.g., "Technology", "Healthcare"). Audited by ASM triggers -> History.AuditHistory. NULL for non-stock instruments. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN CompanyInfo COMMENT 'Free-text company description displayed on the instrument detail page. Rich text describing the company''s business and background. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN DailyRolloverFee COMMENT 'Daily overnight/rollover fee rate applied to leveraged CFD positions in this instrument. Expressed as a percentage or absolute value per day. NULL = fee not configured. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN WeekendRolloverFee COMMENT 'Weekend-specific rollover fee charged for positions held over the weekend (Friday close to Monday open, typically 3x daily). NULL = not configured. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN ContractRolloverFee COMMENT 'Rollover fee applied when a futures contract rolls to the next expiry period. Audited by ASM triggers. NULL for non-futures instruments. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentVisible COMMENT 'Visibility flag: 1=visible to customers (default), 0=hidden. Controls whether the instrument appears in search and trading interfaces. Audited by ASM triggers -> History.AuditHistory. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN Symbol COMMENT 'Short trading symbol for the instrument (e.g., "EURUSD", "AAPL"). Used in price feeds and internal references. Audited by ASM triggers. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN CandleTimeframeGroup COMMENT 'FK to Trade.CandleIntervalGroups (FK_InstrumentMetaData_CandleIntervalGroups). Determines which candle timeframe intervals are available for this instrument''s charts. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN SymbolFull COMMENT 'Fully-qualified unique symbol string for the instrument (e.g., "Drm.797" for dormant instruments). UNIQUE constraint on Trade.InstrumentMetaData (UNQ_TradeInstrumentMetaData_SymbolFull). Audited by ASM triggers. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN Tradable COMMENT 'Whether customers can currently trade this instrument: 1=tradable, 0=not tradable (suspended, delisted, or not yet launched). Audited by ASM triggers -> History.AuditHistory. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN ExchangeID COMMENT 'FK to Trade.Exchange (structural). Identifies the exchange where this instrument is traded. Validated on UPDATE by trigger trg_update_Trade_InstrumentMetaData - prevents assignment to an exchange without a fee definition in Trade.ExchangeInstrumentFeeDefinition. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN StocksIndustryID COMMENT 'Numeric ID of the stock''s industry sector. FK to a stocks industry lookup table. NULL for non-stock instruments. Supplements the free-text Industry column with a structured classification. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number for the instrument. Audited by ASM triggers -> History.AuditHistory. NULL for instruments not mapped to a global security identifier. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN ISINCountryCode COMMENT 'Country code component of the ISIN (first 2 characters of ISIN, e.g., "US", "GB"). Audited by ASM triggers. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN ContractExpire COMMENT 'Whether this futures/CFD instrument has a contract expiry date: 0=perpetual (no expiry), 1=expires. DEFAULT 0. Audited by ASM triggers -> History.AuditHistory. Triggers futures rollover processing when 1. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentTypeSubCategoryID COMMENT 'Sub-category classification within the instrument''s type. Provides finer granularity than InstrumentTypeID (e.g., distinguishing ETFs from indices within the same type group). (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type classification. FK to Dictionary.CurrencyType (FK_InstrumentMetaData_InstrumentType). Observed: 1=FX pair, 4=Index/ETF, 10=custom/synthetic. Determines trading rules, fee schedules, and hedging behavior. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN PriceSourceID COMMENT 'ID of the price data source for this instrument. DEFAULT 0 = default/unspecified source. Used by the Price engine to route price feed subscriptions. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN Cusip COMMENT 'CUSIP identifier (Committee on Uniform Securities Identification Procedures). US-centric securities identifier. Indexed in Trade.InstrumentMetaData (IX_Cusip). NULL for non-US or non-CUSIP instruments. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN CreateDate COMMENT 'UTC timestamp when the instrument metadata row was first created. DEFAULT getutcdate() set at row insertion. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN UnderlyingExchangeID COMMENT 'For derivative instruments (futures, CFDs), the exchange of the underlying asset. May differ from ExchangeID when eToro lists a derivative on one exchange tracking an asset traded on another. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN DbLoginName COMMENT 'Materialized snapshot of suser_name() at version close time. Identifies who changed the metadata. Observed: "DevTradingSTG" for automated batch updates. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN AppLoginName COMMENT 'Materialized snapshot of context_info() at version close time. Typically NULL. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN SysStartTime COMMENT 'Start of validity for this metadata version. Set by SQL Server temporal engine. Rows with SysStartTime=SysEndTime are insert artifacts from Tr_T_InstrumentMetaData_INSERT. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN SysEndTime COMMENT 'End of validity for this metadata version. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal scan performance. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN SEDOL COMMENT 'Stock Exchange Daily Official List identifier. UK-centric securities identifier (7-character alphanumeric). NULL for non-SEDOL instruments. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN SubCategory COMMENT 'Freeform sub-category label providing additional classification context beyond InstrumentTypeSubCategoryID. (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
ALTER TABLE main.bi_db.bronze_etoro_history_instrumentmetadata ALTER COLUMN CFICode COMMENT 'Classification of Financial Instruments code (ISO 10962). 6-character standardized code describing the instrument type at the international regulatory level (e.g., "ESVUFR" for common equity). (Tier 1 - upstream wiki, etoro.History.InstrumentMetaData)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
