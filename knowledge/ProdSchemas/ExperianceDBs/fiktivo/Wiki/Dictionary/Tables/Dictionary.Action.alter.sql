-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_fiktivo_dictionary_action  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.Action.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_fiktivo_dictionary_action ALTER COLUMN ActionID COMMENT 'Primary key identifying the audit action type. Values: 1=Insert, 2=Update, 3=Delete. See [Action](../../_glossary.md#action) for full business definitions. Referenced by dbo.AuditLog.ActionID.';
ALTER TABLE main.general.bronze_fiktivo_dictionary_action ALTER COLUMN Name COMMENT 'Human-readable label for the action type. Used in audit log displays and admin reports. Standard DML operation names: "Insert", "Update", "Delete".';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:07 UTC
-- Statements: 2/2 succeeded
-- ====================
