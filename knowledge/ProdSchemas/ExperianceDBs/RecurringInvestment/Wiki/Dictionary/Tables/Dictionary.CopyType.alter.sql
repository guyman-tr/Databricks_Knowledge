-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_recurringinvestment_dictionary_copytype  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyType.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copytype ALTER COLUMN ID COMMENT 'Unique numeric identifier for the copy type. 0=None (direct instrument), 1=PI (Popular Investor copy), 4=SmartPortfolio (managed portfolio copy). See [Copy Type](../../_glossary.md#copy-type).';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_copytype ALTER COLUMN Name COMMENT 'Human-readable label for the copy trading relationship type.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:20 UTC
-- Statements: 2/2 succeeded
-- ====================
