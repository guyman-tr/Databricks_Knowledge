-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.FuturesMetaData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.FuturesMetaData.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_futuresmetadata
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_futuresmetadata (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata SET TBLPROPERTIES (
    'comment' = 'Per-instrument futures contract metadata: contract size, tick, expiration, settlement, and pricing parameters. Source: etoro.Trade.FuturesMetaData on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.FuturesMetaData.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'FuturesMetaData',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN InstrumentID COMMENT 'Primary key. FK to Trade.Instrument. One row per futures instrument. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN Multiplier COMMENT 'Contract size per point. Used for notional and fee calculation. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN MinimalTick COMMENT 'Smallest price increment in contract units. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN LastTradingDateTime COMMENT 'When trading stops for this contract. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN ExpirationDateTime COMMENT 'Contract maturity. 2222-01-01 for perpetuals. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SettlementTime COMMENT 'Time of day for settlement. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN IndexPointValue COMMENT 'Dollar/value per point move. Used in exposure and fee calc. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN DbLoginName COMMENT 'Computed; database login at insert. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN AppLoginName COMMENT 'Computed; application context at insert. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SysStartTime COMMENT 'Row start for system versioning. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SysEndTime COMMENT 'Row end for system versioning. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN SettlementMethod COMMENT 'Settlement type; 0 or NULL. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_trade_futuresmetadata ALTER COLUMN UnitOfMeasure COMMENT 'Unit of measure; 0, 1, or NULL. (Tier 1 - upstream wiki, etoro.Trade.FuturesMetaData)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
