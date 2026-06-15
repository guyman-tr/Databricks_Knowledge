-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_fiktivo_dictionary_marketingregion  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_fiktivo_dictionary_marketingregion ALTER COLUMN MarketingRegionID COMMENT 'Primary key identifying the marketing region. Values: 0=Unknown, 1=Arabic, 2=Asia, 3=Australia, 4=Canada, 5=French, 6=German, 7=India, 8=Italian, 9=North Europe, 10=ROE, 11=ROW, 12=South Africa, 13=Spanish & Portuguese, 14=UK, 15=USA. See [Marketing Region](../../_glossary.md#marketing-region) for full definitions.';
ALTER TABLE main.experience.bronze_fiktivo_dictionary_marketingregion ALTER COLUMN Name COMMENT 'Human-readable region label. Subject to UNIQUE constraint (UK_DMR_Name) ensuring no duplicate names. Used in reporting displays, admin filters, and commission plan configuration.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:13 UTC
-- Statements: 2/2 succeeded
-- ====================
