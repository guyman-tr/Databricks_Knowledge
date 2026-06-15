-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_tblaff_banners  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN BannerID COMMENT 'Primary key. Referenced by tblaff_GroupBanners, tblaff_MediaTagBanner, and commission event tables (tblaff_Sales.BannerID, etc.) for conversion attribution.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN CategoryID COMMENT 'References [dbo.tblaff_Categories](dbo.tblaff_Categories.md).CategoryID. Content category of the banner.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Type COMMENT 'References [dbo.tblaff_BannerTypes](dbo.tblaff_BannerTypes.md).BannerTypeID. Media format: 1=GIF, 2=Flash, 3=Text, 4=Rotating, 5=Links, 6=Widgets, 7=Videos, 8=Articles, 9=White Labels, 10=Mailers, 11=Education, 12=Logos.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN BannerName COMMENT 'Display name of the banner asset for admin and affiliate portal listing.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN ImageURL COMMENT 'URL to the banner image/asset file. For GIF/Flash banners, points to the creative file.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN TargetURL COMMENT 'Click-through URL. Where users are directed when they click the banner. Typically includes tracking parameters.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN AltText COMMENT 'HTML alt text for the banner image. Used for accessibility and SEO.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Width COMMENT 'Banner width in pixels. Standard IAB sizes (728, 300, 160, etc.). 0 = variable/responsive.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Height COMMENT 'Banner height in pixels. 0 = variable/responsive.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN PerSale COMMENT 'Banner optimized for sale/deposit conversion tracking.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN PerLead COMMENT 'Banner optimized for lead generation tracking.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN PerClick COMMENT 'Banner optimized for click-based tracking.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN NotesToAffiliate COMMENT 'Instructions or notes for affiliates about how to best use this banner.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN AdvancedBanner COMMENT 'Whether this banner uses advanced/custom HTML instead of a standard image. 1 = custom AdCode content.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN AdCode COMMENT 'Custom HTML/JavaScript ad code for advanced banners (AdvancedBanner=1). Affiliates paste this code directly into their sites.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN TargetWindow COMMENT 'HTML target window for the click-through link (e.g., "_blank", "_self", "_top").';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN LanguageID COMMENT 'References [dbo.tblaff_Languages](dbo.tblaff_Languages.md).LanguageID. Locale of the banner content. Default 1 (English).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN BrandID COMMENT 'References [dbo.tblaff_Brands](dbo.tblaff_Brands.md).BrandID. Brand/entity for regulatory targeting.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN Priority COMMENT 'Display priority/sort order for banners within the same category. Lower values may appear first.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_banners ALTER COLUMN IsArchived COMMENT 'Archive flag. 1 = hidden from affiliate selection. 0 = active.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:23:59 UTC
-- Statements: 20/20 succeeded
-- ====================
