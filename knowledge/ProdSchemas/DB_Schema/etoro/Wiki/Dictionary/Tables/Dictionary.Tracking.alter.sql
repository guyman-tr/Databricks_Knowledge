-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.Tracking
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Tracking.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_tracking
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_tracking (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_tracking SET TBLPROPERTIES (
    'comment' = 'Maps tracking device identifier types for mobile attribution and analytics (AppsFlyer, Firebase). Source: etoro.Dictionary.Tracking on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Tracking.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_tracking SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'Tracking',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_tracking ALTER COLUMN AppsFlyerDeviceID COMMENT 'Primary key identifying the tracking identifier type. 1=AppsFlyer, 2=Cookie, 3=Firebase. Named for historical reasons (originally AppsFlyer-only). (Tier 1 - upstream wiki, etoro.Dictionary.Tracking)';
ALTER TABLE main.general.bronze_etoro_dictionary_tracking ALTER COLUMN UserUniqueIdentifierCookie COMMENT 'Name/label of the tracking identifier type. Describes the source system for the device identifier. (Tier 1 - upstream wiki, etoro.Dictionary.Tracking)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
