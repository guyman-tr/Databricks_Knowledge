-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.StocksIndustry
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.StocksIndustry.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_stocksindustry
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_stocksindustry (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_stocksindustry SET TBLPROPERTIES (
    'comment' = 'Classifies stock instruments by industry sector for platform categorization, filtering, and API display. Source: etoro.Dictionary.StocksIndustry on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.StocksIndustry.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_stocksindustry SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'StocksIndustry',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_stocksindustry ALTER COLUMN IndustryID COMMENT 'Primary key identifying the industry sector. Sequential 1-9. Referenced by Trade.InstrumentMetaData.IndustryID and History.InstrumentMetaData.IndustryID. (Tier 1 - upstream wiki, etoro.Dictionary.StocksIndustry)';
ALTER TABLE main.general.bronze_etoro_dictionary_stocksindustry ALTER COLUMN IndustryName COMMENT 'Human-readable industry sector label. Variable-length, no trailing spaces. Used in API responses and platform UI for stock categorization. (Tier 1 - upstream wiki, etoro.Dictionary.StocksIndustry)';

