-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FundIntervalType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundIntervalType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_fundintervaltype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_fundintervaltype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_fundintervaltype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the two fund interval modes — BackTesting and Real — used to distinguish simulated vs live fund allocation intervals in the CopyFunds/SmartPortfolio system. Source: etoro.Dictionary.FundIntervalType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FundIntervalType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_fundintervaltype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FundIntervalType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_fundintervaltype ALTER COLUMN FundIntervalType COMMENT 'Primary key identifying the interval mode. 1=BackTesting (simulated), 2=Real (live execution). Referenced by Trade.FundInterval to classify each rebalancing interval as simulated or live. (Tier 1 - upstream wiki, etoro.Dictionary.FundIntervalType)';
ALTER TABLE main.general.bronze_etoro_dictionary_fundintervaltype ALTER COLUMN FundIntervalTypeDesc COMMENT 'Human-readable label for the interval type (BackTesting/Real). Used in reporting and fund management UI to distinguish simulated from live intervals. (Tier 1 - upstream wiki, etoro.Dictionary.FundIntervalType)';

