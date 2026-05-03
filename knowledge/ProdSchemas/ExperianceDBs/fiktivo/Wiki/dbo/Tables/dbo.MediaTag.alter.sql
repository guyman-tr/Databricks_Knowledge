-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.MediaTag
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_mediatag
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_mediatag (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag SET TBLPROPERTIES (
    'comment' = 'Tracking tag definitions that affiliates attach to their marketing links for campaign attribution and performance measurement. Source: fiktivo.dbo.MediaTag on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'MediaTag',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN TagID COMMENT 'Auto-incrementing identifier. Clustered index key for physical ordering. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTag)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN TagName COMMENT 'Primary key. Unique tag identifier used in tracking URLs and campaign attribution (e.g., "summer_2024_banner_a"). (Tier 1 - upstream wiki, fiktivo.dbo.MediaTag)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN TranslationKey COMMENT 'Localization key for displaying the tag name in multiple languages in the affiliate portal UI. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTag)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN Trace COMMENT 'Computed audit column. JSON with session metadata (HostName, AppName, SUserName, SPID). (Tier 1 - upstream wiki, fiktivo.dbo.MediaTag)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN ValidFrom COMMENT 'System-versioning period start. Tracks when this tag definition became active. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTag)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN ValidTo COMMENT 'System-versioning period end. ''9999-12-31'' for current rows. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTag)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
