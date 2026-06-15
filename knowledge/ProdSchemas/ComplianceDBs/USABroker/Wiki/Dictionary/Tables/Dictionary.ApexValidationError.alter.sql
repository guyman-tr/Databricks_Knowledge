-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_apexvalidationerror
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ApexValidationError.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_apexvalidationerror SET TBLPROPERTIES (
    'comment' = '`Dictionary.ApexValidationError` is a static reference table that enumerates every distinct error condition the Apex integration layer can surface when a user account creation or update request fails validation. Each row provides a stable numeric identifier and a camelCase name that the application layer maps to a user-facing message or a compliance workflow branch. The table exists because the Apex platform (the US broker-dealer account management system) returns structured error codes rather than free-text descriptions. Storing those codes in this lookup table decouples the raw numeric value stored in `Apex.UserValidationErrors` from the human-readable label, enabling consistent reporting and alerting without hardcoding strings in application code. Operationally, the error codes fall into several categories: general API/schema problems (IDs 1 - 2), personal data validation failures...'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_apexvalidationerror ALTER COLUMN ApexValidationErrorID COMMENT 'Stable numeric identifier assigned by Apex; referenced by `Apex.UserValidationErrors.ApexValidationErrorID`.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_apexvalidationerror ALTER COLUMN Name COMMENT 'CamelCase error code name as returned by the Apex API; used as the programmatic handle in application logic and reporting.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:38 UTC
-- Statements: 3/3 succeeded
-- ====================
