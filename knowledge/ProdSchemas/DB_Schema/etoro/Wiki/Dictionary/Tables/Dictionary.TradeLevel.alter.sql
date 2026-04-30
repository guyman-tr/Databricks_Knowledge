-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.TradeLevel
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TradeLevel.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_tradelevel
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_tradelevel (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_tradelevel SET TBLPROPERTIES (
    'comment' = 'Classifies customer trading platform access levels (Normal, eToro Pro, eToro Visual, etc.). Source: etoro.Dictionary.TradeLevel on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.TradeLevel.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_tradelevel SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'TradeLevel',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_tradelevel ALTER COLUMN TradeLevelID COMMENT 'Primary key identifying the trade level. 0=Normal (default), 1=eToro Pro, 2=eToro Visual, 3=Pro Only, 4=Visual Only. Referenced by Customer.CustomerStatic and History.Customer. (Tier 1 - upstream wiki, etoro.Dictionary.TradeLevel)';
ALTER TABLE main.general.bronze_etoro_dictionary_tradelevel ALTER COLUMN Name COMMENT 'Platform level label. Fixed-width with trailing spaces. Unique via DTDL_NAME index. (Tier 1 - upstream wiki, etoro.Dictionary.TradeLevel)';

