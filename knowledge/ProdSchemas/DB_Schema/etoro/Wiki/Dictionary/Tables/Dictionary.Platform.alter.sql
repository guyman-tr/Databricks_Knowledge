-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Platform
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Platform.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_platform
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_platform (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_platform SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the client platform types (Web, iOS, Android) from which users access the eToro trading application. Source: etoro.Dictionary.Platform on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Platform.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_platform SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Platform',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_platform ALTER COLUMN Id COMMENT 'Platform identifier: 0=Undefined, 1=Web, 2=IOS, 3=Android. Referenced by session tracking, trade records, and analytics tables. (Tier 1 - upstream wiki, etoro.Dictionary.Platform)';
ALTER TABLE main.general.bronze_etoro_dictionary_platform ALTER COLUMN Platform COMMENT 'Platform name: "Undefined", "Web", "IOS", "Android". Used in reporting dashboards and API responses. (Tier 1 - upstream wiki, etoro.Dictionary.Platform)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
