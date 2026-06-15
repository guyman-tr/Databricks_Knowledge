-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_downtimeclosestatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DowntimeCloseStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimeclosestatus SET TBLPROPERTIES (
    'comment' = 'A lookup table that defines the resolution categories available when closing a downtime incident in the BackOffice incident management system. When support staff close a downtime incident, they must classify how the issue was resolved. This table provides the standard set of resolution outcomes, enabling consistent categorization and reporting on incident resolution patterns. Referenced by `BackOffice.Downtime.DowntimeCloseStatusID` (explicit FK) when a manager closes a downtime incident via the `BackOffice.DowntimeClose` procedure. The resolution status is written alongside the closing manager''s ID, timestamp, and comment.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimeclosestatus ALTER COLUMN DowntimeCloseStatusID COMMENT 'Primary key. Resolution category identifier (1-4).';
ALTER TABLE main.general.bronze_etoro_dictionary_downtimeclosestatus ALTER COLUMN Name COMMENT 'Human-readable resolution label: Fixed, Not Reproducible, Duplicate Item, By Desgin.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:53 UTC
-- Statements: 3/3 succeeded
-- ====================
