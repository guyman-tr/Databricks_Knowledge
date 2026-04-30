-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.ProviderToInstrument_Daily
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.ProviderToInstrument_Daily.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_providertoinstrument_daily
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_providertoinstrument_daily (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily SET TBLPROPERTIES (
    'comment' = 'Simple SELECT * wrapper on Trade.ProviderToInstrument providing a stable access point for daily batch processes and cross-database linked server queries. Source: etoro.Trade.ProviderToInstrument_Daily on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.ProviderToInstrument_Daily.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'ProviderToInstrument_Daily',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily ALTER COLUMN ProviderID COMMENT 'Part of PK. Provider identifier. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument_Daily)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily ALTER COLUMN InstrumentID COMMENT 'Part of PK. FK to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument_Daily)';
ALTER TABLE main.trading.bronze_etoro_trade_providertoinstrument_daily ALTER COLUMN (all other ProviderToInstrument columns) COMMENT 'Precision, UnitMargin, AllowedRateDiffPercentage, Enabled, AllowBuy, AllowSell, etc. See Trade.ProviderToInstrument. (Tier 1 - upstream wiki, etoro.Trade.ProviderToInstrument_Daily)';

