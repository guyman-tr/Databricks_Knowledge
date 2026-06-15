-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_electronicidentitycheck
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ElectronicIdentityCheck.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_electronicidentitycheck SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the outcome levels of electronic identity verification checks - how many independent data sources confirmed a customer''s identity. Electronic identity verification works by cross-referencing customer information against external databases (credit agencies, electoral rolls, utility records, etc.). The number of matching sources determines the verification strength. This table classifies the outcome from zero matches to two-source confirmation. Referenced by `BackOffice.ElectronicIdentityCheck.ElectronicIdentityCheckID` (implicit FK) and read by `BackOffice.GetElectronicIdentityCheck`, `BackOffice.SetElectronicIdentityCheck`, `BackOffice.GetCustomerByCID`, and multiple UserApiDB aggregation procedures.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_electronicidentitycheck ALTER COLUMN ElectronicIdentityCheckID COMMENT 'Primary key. Verification outcome level (0=None, 1=One Source, 2=Two Sources, 3=No Match).';
ALTER TABLE main.general.bronze_etoro_dictionary_electronicidentitycheck ALTER COLUMN Name COMMENT 'Outcome label. Nullable but all current rows populated.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:03 UTC
-- Statements: 3/3 succeeded
-- ====================
