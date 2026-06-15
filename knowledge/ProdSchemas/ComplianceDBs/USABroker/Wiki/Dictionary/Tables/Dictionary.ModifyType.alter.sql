-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_modifytype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ModifyType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_modifytype SET TBLPROPERTIES (
    'comment' = '`Dictionary.ModifyType` is a static reference table that classifies the nature of an operation recorded in the `Apex.RequestLog`. Every request sent to the Apex broker-dealer platform on behalf of a user falls into one of three lifecycle categories: creating a new account (`Create`), modifying an existing account (`Update`), or closing an account (`Close`). This classification is fundamental to audit trail integrity. Compliance and operations teams rely on `ModifyType` to filter the request log to a specific operation class - for example, to count all account closures in a period, or to investigate whether an update request preceded a compliance flag. The three values map directly to the three request types supported by the Apex API.'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_modifytype ALTER COLUMN ModifyTypeID COMMENT 'Numeric identifier for the operation type.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_modifytype ALTER COLUMN Name COMMENT 'Human-readable label for the operation class; wider than most Dictionary name columns to accommodate future verbose values.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:42 UTC
-- Statements: 3/3 succeeded
-- ====================
