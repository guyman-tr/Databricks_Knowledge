-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FundType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_fundtype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_fundtype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_fundtype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the three CopyFunds/SmartPortfolio fund categories - TopTraders (copy-based), Partners (external), and Market (thematic index-based). Source: etoro.Dictionary.FundType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_fundtype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FundType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_fundtype ALTER COLUMN FundTypeID COMMENT 'Primary key identifying the fund category. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). Referenced by Trade.Fund to classify each CopyFund/SmartPortfolio. Replicated to SettingsDB for configuration management. (Tier 1 - upstream wiki, etoro.Dictionary.FundType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundtype ALTER COLUMN Description COMMENT 'Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category. (Tier 1 - upstream wiki, etoro.Dictionary.FundType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
