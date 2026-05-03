-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.InstrumentSpread
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentSpread.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_instrumentspread
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_instrumentspread (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread SET TBLPROPERTIES (
    'comment' = 'Per-instrument, per-feed bid/ask spread configuration that defines how each tradeable instrument is quoted and how spread thresholds are monitored across price feeds. Source: etoro.Trade.InstrumentSpread on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentSpread.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'InstrumentSpread',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. The tradeable instrument this spread config applies to. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN SpreadTypeID COMMENT 'How spread values are expressed: 1=SpreadInPips (absolute pips), 2=PrecentageSpread (percentage of rate). (Dictionary.SpreadType) (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN Bid COMMENT 'Bid-side spread offset. Typically negative (pips subtracted from mid-price). Interpreted per SpreadTypeID. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN Ask COMMENT 'Ask-side spread offset. Typically positive (pips added to mid-price). Interpreted per SpreadTypeID. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN MarketSpreadThreshold COMMENT 'Maximum acceptable spread before alerting. Unit determined by SpreadThresholdTypeID. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN ReferenceBid COMMENT 'Baseline bid rate for spread calculation. Default 0. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN ReferenceAsk COMMENT 'Baseline ask rate for spread calculation. Default 0. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN SpreadThresholdTypeID COMMENT 'Threshold unit: 1=NOP (Number of Pips), 2=NOE (Number of Entries). (Dictionary.SpreadThresholdType) (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN FeedID COMMENT 'Price feed identifier. 1=primary feed (used by execution), 2=secondary feed. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). Database login that last modified the row. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context from session. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN SysStartTime COMMENT 'Temporal start. Set when row becomes current. System versioning. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN SysEndTime COMMENT 'Temporal end. 9999-12-31 for current rows. System versioning. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
ALTER TABLE main.trading.bronze_etoro_trade_instrumentspread ALTER COLUMN HostName COMMENT 'Computed: host_name(). Server host that last modified the row. (Tier 1 - upstream wiki, etoro.Trade.InstrumentSpread)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
