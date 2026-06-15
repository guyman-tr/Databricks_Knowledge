-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_mediatag  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN TagID COMMENT 'Auto-incrementing identifier. Clustered index key for physical ordering.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN TagName COMMENT 'Primary key. Unique tag identifier used in tracking URLs and campaign attribution (e.g., "summer_2024_banner_a").';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN TranslationKey COMMENT 'Localization key for displaying the tag name in multiple languages in the affiliate portal UI.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN ValidFrom COMMENT 'System-versioning period start. Tracks when this tag definition became active.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_mediatag ALTER COLUMN ValidTo COMMENT 'System-versioning period end. ''9999-12-31'' for current rows.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:20 UTC
-- Statements: 5/5 succeeded
-- ====================
