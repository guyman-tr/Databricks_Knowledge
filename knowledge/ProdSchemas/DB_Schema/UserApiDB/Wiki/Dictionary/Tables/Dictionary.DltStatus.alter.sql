-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_userapidb_dictionary_dltstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Dictionary/Tables/Dictionary.DltStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_userapidb_dictionary_dltstatus ALTER COLUMN DltStatusID COMMENT 'Primary key. DLT verification state: 1=Pending, 2=Ongoing, 3=Failed, 4=Passed, 5=Inactive. See [DLT Status](_glossary.md#dlt-status).';
ALTER TABLE main.general.bronze_userapidb_dictionary_dltstatus ALTER COLUMN Name COMMENT 'Human-readable status label used in monitoring dashboards and compliance reports.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:02 UTC
-- Statements: 2/2 succeeded
-- ====================
