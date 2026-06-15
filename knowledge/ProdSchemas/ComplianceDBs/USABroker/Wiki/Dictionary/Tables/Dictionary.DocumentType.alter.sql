-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_documenttype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.DocumentType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_documenttype SET TBLPROPERTIES (
    'comment' = '`Dictionary.DocumentType` is a static reference table that enumerates the categories of identity and compliance documents that can be submitted as part of a CIP (Customer Identification Program) investigation for a brokerage account. These document types reflect the identity-verification requirements imposed by US anti-money-laundering (AML) and KYC regulations, particularly FinCEN''s CIP rules under the Bank Secrecy Act. When a user''s identity cannot be verified automatically through the Sketch CIP pipeline, a manual investigation is opened and one or more supporting documents must be collected. The `DocumentType` code recorded in `Apex.InvestigationDocument` tells compliance reviewers what kind of document was uploaded so they can assess its validity for CIP purposes. The table includes primary identity documents (driver''s licence, passport, state ID, military ID), Social Security...'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_documenttype ALTER COLUMN DocumentTypeID COMMENT 'Stable numeric identifier for the document category.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_documenttype ALTER COLUMN Name COMMENT 'Uppercase underscore-delimited code that identifies the document class in application logic and reporting.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:40 UTC
-- Statements: 3/3 succeeded
-- ====================
