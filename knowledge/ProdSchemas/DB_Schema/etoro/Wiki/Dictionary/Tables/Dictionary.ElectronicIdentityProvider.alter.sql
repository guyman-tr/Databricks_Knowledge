-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_electronicidentityprovider
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ElectronicIdentityProvider.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_electronicidentityprovider SET TBLPROPERTIES (
    'comment' = 'A lookup table identifying the third-party vendors that perform electronic identity verification checks for eToro customers. eToro uses multiple identity verification providers across different markets and regulatory jurisdictions. This table catalogs which provider performed a given verification, enabling audit trails and provider-specific result interpretation. Referenced by `BackOffice.ElectronicIdentityCheck.ElectronicIdentityProviderID` (implicit FK). Set when EID results are recorded via `BackOffice.SetElectronicIdentityCheck` and read by `BackOffice.GetElectronicIdentityCheck`.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_electronicidentityprovider ALTER COLUMN ElectronicIdentityProviderID COMMENT 'Primary key. Provider identifier.';
ALTER TABLE main.general.bronze_etoro_dictionary_electronicidentityprovider ALTER COLUMN Name COMMENT 'Provider name/abbreviation. Nullable but all current rows populated.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:05 UTC
-- Statements: 3/3 succeeded
-- ====================
