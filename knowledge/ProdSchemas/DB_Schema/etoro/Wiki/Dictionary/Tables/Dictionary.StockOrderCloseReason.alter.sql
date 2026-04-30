-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.StockOrderCloseReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.StockOrderCloseReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_stockorderclosereason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_stockorderclosereason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_stockorderclosereason SET TBLPROPERTIES (
    'comment' = 'Classifies the reason why a stock order was closed or cancelled in the trading system. Source: etoro.Dictionary.StockOrderCloseReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.StockOrderCloseReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_stockorderclosereason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'StockOrderCloseReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_stockorderclosereason ALTER COLUMN OrderCloseReasonID COMMENT 'Primary key identifying the close reason. Referenced by History.StocksOrders.OrderCloseReasonID (default 1 = Normal). Values: 1=Normal, 3=Parent Order Canceled, 4=Mirror Closed, 5=Parent Mirror Closed, 10=Cancel. (Tier 1 - upstream wiki, etoro.Dictionary.StockOrderCloseReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_stockorderclosereason ALTER COLUMN Name COMMENT 'Human-readable label for the close reason. Fixed-width char(50) with trailing spaces. (Tier 1 - upstream wiki, etoro.Dictionary.StockOrderCloseReason)';

