-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.SpreadToGroup
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.SpreadToGroup.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_spreadtogroup
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_spreadtogroup (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_spreadtogroup SET TBLPROPERTIES (
    'comment' = 'Many-to-many bridge table linking spread groups (e.g., Default, Expert) to spread definitions, enabling customer tiers to share or override bid/ask spreads per instrument. Source: etoro.Trade.SpreadToGroup on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.SpreadToGroup.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_spreadtogroup SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'SpreadToGroup',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_spreadtogroup ALTER COLUMN SpreadGroupID COMMENT 'FK to Trade.SpreadGroup. Part of composite PK. Identifies the spread tier (0=Default, 1=Expert, etc.) that includes this spread. (Tier 1 - upstream wiki, etoro.Trade.SpreadToGroup)';
ALTER TABLE main.trading.bronze_etoro_trade_spreadtogroup ALTER COLUMN SpreadID COMMENT 'FK to Trade.Spread. Part of composite PK. Identifies the spread definition (ProviderID, InstrumentID, Bid, Ask) included in this group. (Tier 1 - upstream wiki, etoro.Trade.SpreadToGroup)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
