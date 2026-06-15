-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_userdocumenttype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.UserDocumentType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_userdocumenttype SET TBLPROPERTIES (
    'comment' = '`Dictionary.UserDocumentType` is a static reference table that classifies the category of documents that users upload and associate with their brokerage account profile. These are user-facing document uploads managed at the account level, distinct from `Dictionary.DocumentType` which classifies documents submitted specifically as part of a CIP investigation. The six types span the range of documents a broker-dealer typically collects: the account holder''s signature image (required for agreement execution), government-issued identity documents (stored for KYC records), IRA-specific deposit slips, account transfer forms (ACATS-related), affiliated-entity approval letters, and a catch-all for other supporting documents. `Apex.UserDocument` stores each uploaded file with a `UserDocumentTypeID`, allowing compliance and operations teams to filter, audit, and retrieve specific document...'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_userdocumenttype ALTER COLUMN UserDocumentTypeID COMMENT 'Stable numeric identifier for the user document category.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_userdocumenttype ALTER COLUMN Name COMMENT 'Uppercase underscore-delimited code that identifies the document class in application logic and reporting.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:46 UTC
-- Statements: 3/3 succeeded
-- ====================
