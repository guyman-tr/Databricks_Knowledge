-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.HighLevelDepositStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the high-level deposit status. 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status).';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_highleveldepositstatus ALTER COLUMN HighLevelDepositStatus COMMENT 'Human-readable label describing the deposit outcome category.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:23 UTC
-- Statements: 2/2 succeeded
-- ====================
