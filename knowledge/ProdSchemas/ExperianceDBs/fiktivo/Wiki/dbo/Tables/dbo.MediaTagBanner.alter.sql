-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.MediaTagBanner
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTagBanner.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_mediatagbanner
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_mediatagbanner (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner SET TBLPROPERTIES (
    'comment' = 'Junction table linking marketing banners to media tags, enabling tag-based banner categorization and filtering with full temporal audit trail. Source: fiktivo.dbo.MediaTagBanner on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTagBanner.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'MediaTagBanner',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN BannerID COMMENT 'Foreign key to dbo.tblaff_Banners.BannerID. Identifies the marketing banner being tagged. Part of the composite primary key. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTagBanner)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN TagID COMMENT 'Foreign key to dbo.MediaTag.TagID. Identifies the media tag applied to the banner. Part of the composite primary key. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTagBanner)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN Trace COMMENT 'Computed column (not persisted). Captures database session context as JSON: HostName, AppName, SUserName, SPID, DBName, ObjectName. Provides audit attribution for who created or modified each tag assignment. Formula: concat(...) building a JSON string from system functions. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTagBanner)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN ValidFrom COMMENT 'System-versioned temporal column. Timestamp when this tag assignment became effective. Automatically set by SQL Server on INSERT/UPDATE. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTagBanner)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN ValidTo COMMENT 'System-versioned temporal column. Timestamp when this tag assignment was superseded or removed. ''9999-12-31'' for current assignments. GENERATED ALWAYS AS ROW END. (Tier 1 - upstream wiki, fiktivo.dbo.MediaTagBanner)';

