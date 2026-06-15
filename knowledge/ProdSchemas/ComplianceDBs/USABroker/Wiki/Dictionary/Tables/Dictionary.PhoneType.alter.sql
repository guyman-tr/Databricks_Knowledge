-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_phonetype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.PhoneType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_phonetype SET TBLPROPERTIES (
    'comment' = '`Dictionary.PhoneType` is a static reference table that classifies the category of a telephone number provided by a user during account registration or update. Capturing phone type allows the platform to understand the intended use of each number - for example, distinguishing a reachable mobile number (preferred for two-factor authentication and urgent contact) from a work number or fax line. This classification is used in two contexts: `Apex.UserData` stores the primary phone number type for the account holder, and `Apex.UserDataTrustedContact` stores the phone type for the user''s designated trusted contact person, a regulatory requirement under FINRA Rule 4512. The five types cover the standard categories offered by US broker-dealers: Home, Work, Mobile, Fax, and Other.'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_phonetype ALTER COLUMN PhoneTypeID COMMENT 'Stable numeric identifier for the phone number category.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_phonetype ALTER COLUMN Name COMMENT 'Human-readable label for the phone category; notably wide at 150 characters to accommodate future descriptive labels.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:43 UTC
-- Statements: 3/3 succeeded
-- ====================
