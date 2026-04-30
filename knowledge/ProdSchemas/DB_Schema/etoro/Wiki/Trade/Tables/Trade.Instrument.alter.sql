-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.Instrument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Instrument.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrument
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrument (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrument SET TBLPROPERTIES (
    'comment' = 'Core instrument definition table that pairs a buy currency/asset with a sell currency to define every tradeable instrument on the eToro platform. Source: etoro.Trade.Instrument on the etoro production database, ingested via the Generic Pipeline (Override strategy, 30-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Instrument.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'Instrument',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '30'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN InstrumentID COMMENT 'Primary key identifying the tradeable instrument pair. Allocated by Internal.GetInstrumentID during creation via Trade.InstrumentAdd. Values range from 0 (system placeholder) to 21,100,110. Referenced by virtually every trading table. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN BuyCurrencyID COMMENT 'The buy-side asset of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the base currency (e.g., EUR in EUR/USD). For stocks/ETFs/crypto: the asset itself (BuyCurrencyID = the asset''s CurrencyID in Dictionary.Currency). 10,252 distinct values. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN SellCurrencyID COMMENT 'The sell-side (denomination) currency of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading currency (USD, EUR, GBX). 67 distinct values - far fewer than BuyCurrencyID since many assets share the same denomination. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN TradeRange COMMENT 'The allowed trade range (pip distance) for the instrument. Determines how far from market price a pending order can be placed. Set during instrument creation via Trade.InstrumentAdd. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN DollarRatio COMMENT 'Price scaling factor for USD normalization. Most instruments = 1. Japanese Yen pairs = 100 (because JPY prices are 100x larger numerically). Used in P&L and conversion rate calculations across the platform. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN Passport COMMENT 'Row version / concurrency token. Automatically maintained by SQL Server. Returned as OUTPUT from Trade.InstrumentAdd for optimistic concurrency control. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN PipDifferenceThreshold COMMENT 'Maximum allowed pip difference threshold for the instrument. Used for price validation - if a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. Values range from 1 to 10,000. Audited on INSERT/UPDATE/DELETE. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN IsMajor COMMENT 'Flag indicating whether the instrument is classified as a "major" instrument. 1 = major (5,831 instruments, includes all major forex pairs and many popular assets), 0 = minor (4,654 instruments). Affects spread calculations, margin requirements, and regulatory leverage caps (ESMA allows higher leverage for major forex pairs). (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN PriceServerID COMMENT 'Identifies which price server feeds rate data for this instrument. 14 distinct values (1-10, 15, 16, 25, 100). NULL for 1 record (the system placeholder). Determines the source of real-time price feeds. Audited on INSERT/UPDATE/DELETE. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN ShardID COMMENT 'Database shard assignment for the instrument. Determines which database shard stores position and order data. Values: 0 (1 - placeholder), 1 (4,564 instruments), 2 (4,712), 8 (1,208). Audited on INSERT/UPDATE/DELETE. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN OMEID COMMENT 'Order Matching Engine instance assignment. Determines which OME server handles order matching for this instrument. Values: 1 (1 - system), 2 (2,622), 3 (2,621), 4 (2,620), 5 (2,621). Round-robin distribution across 4 active OME instances. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN DbLoginName COMMENT 'Computed: SUSER_NAME(). Captures the SQL Server login name of the current session. Used for audit trail purposes alongside the ASM triggers. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(VARCHAR(500), CONTEXT_INFO()). Reads the application-set context info to identify which application service made the change. Used for audit trail alongside DbLoginName. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN SysStartTime COMMENT 'System versioning row start time. Automatically set when a row is inserted or updated. Part of the temporal table mechanism tracking all changes to History.Instrument. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN SysEndTime COMMENT 'System versioning row end time. Set to max datetime for current rows. When a row is updated or deleted, the previous version''s SysEndTime is set to the modification time in History.Instrument. (Tier 1 - upstream wiki, etoro.Trade.Instrument)';
ALTER TABLE main.trading.bronze_etoro_trade_instrument ALTER COLUMN OperationMode COMMENT 'Trading operation mode for the instrument. 0 = Standard mode (10,402 instruments - default for all asset types), 1 = Alternate mode (83 instruments - primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). (Tier 1 - upstream wiki, etoro.Trade.Instrument)';

