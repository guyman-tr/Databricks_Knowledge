-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_recurringinvestment_dictionary_planstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planstatus ALTER COLUMN ID COMMENT 'Unique numeric identifier for the plan status. 0=Initializing (failed creation), 1=Active (only operational status), 2=Cancelled (terminal), 3=Stopped (unused), 4=Invalid (unused). See [Plan Status](../../_glossary.md#plan-status).';
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planstatus ALTER COLUMN StatusName COMMENT 'Human-readable label for the plan lifecycle state.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:36 UTC
-- Statements: 2/2 succeeded
-- ====================
