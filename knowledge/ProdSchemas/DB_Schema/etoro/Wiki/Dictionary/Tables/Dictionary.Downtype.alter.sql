-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_downtype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Downtype.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtype SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the categories of downtime incidents - the "what kind" of problem occurred across platform systems. Categorizing downtime incidents by type enables pattern analysis (e.g., "we have recurring hedge failures") and helps route incidents to the appropriate team. Each category maps to a specific functional area of the platform. Referenced by `BackOffice.Downtime.DowntypeID` (explicit FK) and by `Dictionary.DowntimeSystemToDowntype` which maps valid downtypes per system. Not all downtypes apply to all systems.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_downtype ALTER COLUMN DowntypeID COMMENT 'Primary key. Downtime category identifier (1-17).';
ALTER TABLE main.general.bronze_etoro_dictionary_downtype ALTER COLUMN Name COMMENT 'Category label. Unique index ensures no duplicates.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:00 UTC
-- Statements: 3/3 succeeded
-- ====================
