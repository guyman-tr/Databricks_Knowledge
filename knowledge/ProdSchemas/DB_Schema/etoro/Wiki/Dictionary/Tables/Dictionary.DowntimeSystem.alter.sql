-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_downtimesystem
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DowntimeSystem.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimesystem SET TBLPROPERTIES (
    'comment' = 'A lookup table identifying the major platform systems that can experience downtime incidents - the "where" of an incident. When reporting a downtime incident, operations staff must specify which system is affected. This table provides the canonical list of monitorable platform components, enabling per-system incident tracking and uptime reporting. Referenced by `BackOffice.Downtime.DowntimeSystemID` (explicit FK) and by `Dictionary.DowntimeSystemToDowntype` (explicit FK) which maps each system to its applicable downtime categories.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimesystem ALTER COLUMN DowntimeSystemID COMMENT 'Primary key. System identifier.';
ALTER TABLE main.general.bronze_etoro_dictionary_downtimesystem ALTER COLUMN Name COMMENT 'System name. Unique index ensures no duplicates.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:57 UTC
-- Statements: 3/3 succeeded
-- ====================
