-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.Spread
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Spread.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_spread
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_spread (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_spread SET TBLPROPERTIES (
    'comment' = 'Spread (bid-ask markup) configuration per instrument per provider. Defines pips to add to bid and ask for customer pricing. Source: etoro.Trade.Spread on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Spread.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_spread SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'Spread',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_spread ALTER COLUMN SpreadID COMMENT 'Primary key. Allocated by Internal.GetSpreadID in Trade.SpreadAdd. Used by Trade.SpreadToGroup to link spreads to groups. (Tier 1 - upstream wiki, etoro.Trade.Spread)';
ALTER TABLE main.trading.bronze_etoro_trade_spread ALTER COLUMN ProviderID COMMENT 'FK part -> Trade.ProviderToInstrument. Execution provider. (Tier 1 - upstream wiki, etoro.Trade.Spread)';
ALTER TABLE main.trading.bronze_etoro_trade_spread ALTER COLUMN InstrumentID COMMENT 'FK part -> Trade.ProviderToInstrument. Tradeable instrument. (Tier 1 - upstream wiki, etoro.Trade.Spread)';
ALTER TABLE main.trading.bronze_etoro_trade_spread ALTER COLUMN Bid COMMENT 'Pip offset for bid. Applied when quoting buy price. Audited by ASM triggers. (Tier 1 - upstream wiki, etoro.Trade.Spread)';
ALTER TABLE main.trading.bronze_etoro_trade_spread ALTER COLUMN Ask COMMENT 'Pip offset for ask. Applied when quoting sell price. Audited by ASM triggers. (Tier 1 - upstream wiki, etoro.Trade.Spread)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
