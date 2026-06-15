-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_flow  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Flow.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_flow ALTER COLUMN FlowID COMMENT 'Primary key identifying the execution flow type. 1=Open Trade Execution, 2=Close Trade Execution, 3=Internal Transfer. Referenced by BackOffice and Billing procedures to classify financial operations by their trade lifecycle context.';
ALTER TABLE main.general.bronze_etoro_dictionary_flow ALTER COLUMN Description COMMENT 'Human-readable label for the flow type. Displayed in BackOffice billing screens, cashout request views, and withdrawal reports. Used for filtering and grouping operations by trade lifecycle stage.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:57 UTC
-- Statements: 2/2 succeeded
-- ====================
