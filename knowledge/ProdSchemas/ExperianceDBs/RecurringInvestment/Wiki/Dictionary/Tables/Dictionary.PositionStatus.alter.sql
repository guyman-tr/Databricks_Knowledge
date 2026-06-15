-- =============================================================================
-- Databricks ALTER Script: main.experience.bronze_recurringinvestment_dictionary_positionstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PositionStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_positionstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the position status. 1=Success, 2=Failed, 3=InProgress, 4=Unknown, 6=NoPositionOrderCanceledByUser, 7=NoPositionOrderExpiredOrCanceledByEtoro. Gap at ID=5 suggests a deprecated status. See [Position Status](../../_glossary.md#position-status).';
ALTER TABLE main.experience.bronze_recurringinvestment_dictionary_positionstatus ALTER COLUMN PositionStatus COMMENT 'Human-readable label describing the position creation outcome.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:40 UTC
-- Statements: 2/2 succeeded
-- ====================
