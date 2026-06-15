-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_BannerTypes.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes ALTER COLUMN BannerTypeID COMMENT 'Primary key. Auto-incrementing identifier. Referenced by tblaff_Banners.Type to classify each banner by its media format. Values: 1=GIF Banners, 2=Flash Banners, 3=Text Banners, 4=Rotating Banners, 5=Links & Landing Pages, 6=Widgets, 7=Videos & Tutorials, 8=Articles & Reviews, 9=White Labels, 10=Mailers, 11=Education Tools, 12=Logos.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes ALTER COLUMN BannerTypeName COMMENT 'Display name for the banner type. Shown in admin UI and affiliate banner selection filters.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:05 UTC
-- Statements: 2/2 succeeded
-- ====================
