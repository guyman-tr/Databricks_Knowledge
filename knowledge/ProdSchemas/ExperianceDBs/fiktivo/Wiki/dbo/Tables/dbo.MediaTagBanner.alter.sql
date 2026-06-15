-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_mediatagbanner  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTagBanner.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN BannerID COMMENT 'Foreign key to dbo.tblaff_Banners.BannerID. Identifies the marketing banner being tagged. Part of the composite primary key.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN TagID COMMENT 'Foreign key to dbo.MediaTag.TagID. Identifies the media tag applied to the banner. Part of the composite primary key.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN ValidFrom COMMENT 'System-versioned temporal column. Timestamp when this tag assignment became effective. Automatically set by SQL Server on INSERT/UPDATE. GENERATED ALWAYS AS ROW START.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatagbanner ALTER COLUMN ValidTo COMMENT 'System-versioned temporal column. Timestamp when this tag assignment was superseded or removed. ''9999-12-31'' for current assignments. GENERATED ALWAYS AS ROW END.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:23 UTC
-- Statements: 4/4 succeeded
-- ====================
