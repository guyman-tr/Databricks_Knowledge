-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_downtimestatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DowntimeStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimestatus SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the operational impact status of a downtime incident - how severely the affected system is impaired. While `DowntimeSeverity` classifies priority, `DowntimeStatus` describes the nature of the failure: whether the system is completely down, partially malfunctioning, or experiencing an isolated feature failure. This distinction helps operations teams understand what level of functionality remains. Referenced by `BackOffice.Downtime.DowntimeStatusID` (explicit FK). Set when an incident is created via `BackOffice.DowntimeAdd` and updateable via `BackOffice.DowntimeEdit`.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimestatus ALTER COLUMN DowntimeStatusID COMMENT 'Primary key. Impact classification (1=Not Working, 2=Not Working as Should, 3=Specific Feature not Working).';
ALTER TABLE main.general.bronze_etoro_dictionary_downtimestatus ALTER COLUMN Name COMMENT 'Impact description. Two unique indexes enforce name uniqueness (DDCS_NAME and DDTST_NAME - legacy duplication).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:56 UTC
-- Statements: 3/3 succeeded
-- ====================
