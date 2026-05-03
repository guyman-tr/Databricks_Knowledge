-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_Banners
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_banners
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_banners (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners SET TBLPROPERTIES (
    'comment' = 'Individual marketing banner/creative assets that affiliates embed on their websites, with targeting by category, language, brand, and type. Source: fiktivo.dbo.tblaff_Banners on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_Banners',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN BannerID COMMENT 'Primary key. Referenced by tblaff_GroupBanners, tblaff_MediaTagBanner, and commission event tables (tblaff_Sales.BannerID, etc.) for conversion attribution. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN CategoryID COMMENT 'References dbo.tblaff_Categories.CategoryID. Content category of the banner. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Type COMMENT 'References dbo.tblaff_BannerTypes.BannerTypeID. Media format: 1=GIF, 2=Flash, 3=Text, 4=Rotating, 5=Links, 6=Widgets, 7=Videos, 8=Articles, 9=White Labels, 10=Mailers, 11=Education, 12=Logos. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN BannerName COMMENT 'Display name of the banner asset for admin and affiliate portal listing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN ImageURL COMMENT 'URL to the banner image/asset file. For GIF/Flash banners, points to the creative file. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN TargetURL COMMENT 'Click-through URL. Where users are directed when they click the banner. Typically includes tracking parameters. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN AltText COMMENT 'HTML alt text for the banner image. Used for accessibility and SEO. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Width COMMENT 'Banner width in pixels. Standard IAB sizes (728, 300, 160, etc.). 0 = variable/responsive. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Height COMMENT 'Banner height in pixels. 0 = variable/responsive. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN PerSale COMMENT 'Banner optimized for sale/deposit conversion tracking. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN PerLead COMMENT 'Banner optimized for lead generation tracking. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN PerClick COMMENT 'Banner optimized for click-based tracking. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN NotesToAffiliate COMMENT 'Instructions or notes for affiliates about how to best use this banner. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN AdvancedBanner COMMENT 'Whether this banner uses advanced/custom HTML instead of a standard image. 1 = custom AdCode content. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN AdCode COMMENT 'Custom HTML/JavaScript ad code for advanced banners (AdvancedBanner=1). Affiliates paste this code directly into their sites. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN TargetWindow COMMENT 'HTML target window for the click-through link (e.g., "_blank", "_self", "_top"). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN LanguageID COMMENT 'References dbo.tblaff_Languages.LanguageID. Locale of the banner content. Default 1 (English). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN BrandID COMMENT 'References dbo.tblaff_Brands.BrandID. Brand/entity for regulatory targeting. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Priority COMMENT 'Display priority/sort order for banners within the same category. Lower values may appear first. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN IsArchived COMMENT 'Archive flag. 1 = hidden from affiliate selection. 0 = active. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Trace COMMENT 'Computed audit column. JSON with session metadata. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN ValidFrom COMMENT 'System-versioning period start. Hidden. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN ValidTo COMMENT 'System-versioning period end. Hidden. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Banners)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
