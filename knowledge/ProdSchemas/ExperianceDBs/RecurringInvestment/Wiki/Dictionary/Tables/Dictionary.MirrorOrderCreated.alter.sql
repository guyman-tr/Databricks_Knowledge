-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.MirrorOrderCreated.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated ALTER COLUMN ID COMMENT 'Unique numeric identifier. Only value is 1 (TRUE). NULL in referencing tables means no mirror order created. See [Mirror Order Created](../../_glossary.md#mirror-order-created).';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_mirrorordercreated ALTER COLUMN Name COMMENT 'Human-readable label. Only value is "TRUE".';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:27 UTC
-- Statements: 2/2 succeeded
-- ====================
