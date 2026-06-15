-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_downtimesystemtodowntype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DowntimeSystemToDowntype.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimesystemtodowntype SET TBLPROPERTIES (
    'comment' = 'A many-to-many junction table that maps which downtime categories (downtypes) are applicable to each platform system. Controls the valid dropdown options when reporting a downtime incident. Different systems have different failure modes - a "Dealing Desk" issue doesn''t apply to the Website, and "etoro.com" downtime doesn''t apply to the trading platform. This table constrains which downtype categories are selectable per system in the BackOffice incident form. When an operator selects a system in the downtime reporting form, this mapping determines which downtype categories appear as valid options. Both columns have explicit FKs to their respective lookup tables.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtimesystemtodowntype ALTER COLUMN DowntimeSystemID COMMENT 'FK to Dictionary.DowntimeSystem. Identifies the platform system. Part of composite PK.';
ALTER TABLE main.general.bronze_etoro_dictionary_downtimesystemtodowntype ALTER COLUMN DowntypeID COMMENT 'FK to Dictionary.Downtype. Identifies the downtime category. Part of composite PK.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:59 UTC
-- Statements: 3/3 succeeded
-- ====================
