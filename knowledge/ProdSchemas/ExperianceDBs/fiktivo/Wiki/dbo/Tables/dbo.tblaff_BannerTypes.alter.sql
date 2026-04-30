-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_BannerTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_BannerTypes.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying marketing banner assets by their media format or content type (GIF, Flash, Text, Video, Widget, etc.). Source: fiktivo.dbo.tblaff_BannerTypes on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_BannerTypes.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_BannerTypes',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes ALTER COLUMN BannerTypeID COMMENT 'Primary key. Auto-incrementing identifier. Referenced by tblaff_Banners.Type to classify each banner by its media format. Values: 1=GIF Banners, 2=Flash Banners, 3=Text Banners, 4=Rotating Banners, 5=Links & Landing Pages, 6=Widgets, 7=Videos & Tutorials, 8=Articles & Reviews, 9=White Labels, 10=Mailers, 11=Education Tools, 12=Logos. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_BannerTypes)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes ALTER COLUMN BannerTypeName COMMENT 'Display name for the banner type. Shown in admin UI and affiliate banner selection filters. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_BannerTypes)';

