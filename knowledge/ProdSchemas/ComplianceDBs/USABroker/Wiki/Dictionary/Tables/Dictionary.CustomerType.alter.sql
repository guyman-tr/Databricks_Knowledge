-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_customertype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.CustomerType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_customertype SET TBLPROPERTIES (
    'comment' = '`Dictionary.CustomerType` is a static reference table that classifies the legal structure of a brokerage account held by a user. The account type governs a wide range of downstream rules: which agreements must be signed, which tax forms are required, who is authorised to transact, and which regulatory disclosures apply. The four types reflect the US broker-dealer product catalogue. `INDIVIDUAL` accounts are standard retail accounts held in a single person''s name. `IRA` (Individual Retirement Account) accounts carry specific tax-advantaged rules, mandatory IRA adoption agreements, and contribution limits. `JOINT` accounts are held by two or more individuals and require a joint account agreement. `CUSTODIAN` accounts are managed by an adult on behalf of a minor under UGMA/UTMA statutes.'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_customertype ALTER COLUMN CustomerTypeID COMMENT 'Stable numeric identifier for the account/customer type.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_customertype ALTER COLUMN Name COMMENT 'Uppercase string code used throughout the application layer to identify the account structure.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:39 UTC
-- Statements: 3/3 succeeded
-- ====================
