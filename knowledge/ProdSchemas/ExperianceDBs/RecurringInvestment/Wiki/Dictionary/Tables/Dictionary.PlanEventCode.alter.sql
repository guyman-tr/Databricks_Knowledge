-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_recurringinvestment_dictionary_planeventcode  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planeventcode ALTER COLUMN ID COMMENT 'Unique numeric event code. Range-based: 100s=success, 200s=deposit fail, 300s=cancel, 400s=creation fail, 500s=order issues, 600s=position issues, 700s=user actions, 800s=eligibility, 900s=instrument, 1000s=validation, 1100s=compliance, 1200+=position errors. See [Plan Event Code](../../_glossary.md#plan-event-code).';
ALTER TABLE main.bi_db.bronze_recurringinvestment_dictionary_planeventcode ALTER COLUMN EventName COMMENT 'Human-readable event name describing the specific lifecycle event. Phase suffixes (_Phase02, _Phase05) indicate detection phase.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:32 UTC
-- Statements: 2/2 succeeded
-- ====================
