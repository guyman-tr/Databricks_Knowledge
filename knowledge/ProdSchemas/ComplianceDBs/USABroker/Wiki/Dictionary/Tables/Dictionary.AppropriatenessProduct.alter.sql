-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AppropriatenessProduct.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct SET TBLPROPERTIES (
    'comment' = '`Dictionary.AppropriatenessProduct` is a static reference table that classifies the financial products for which an appropriateness assessment must be performed before a user may trade. Appropriateness testing is a regulatory requirement - under frameworks such as MiFID II and equivalent US rules - that obligates the broker to evaluate whether a client has sufficient knowledge and experience for a given product type. Each row represents a product category that has its own appropriateness questionnaire, scoring logic, and eligibility outcome. The `None` entry (ID 0) acts as a sentinel value for contexts where no specific product has yet been evaluated. The remaining three entries cover the major retail product lines offered: CFDs (Contracts for Difference), FPSL (Fully Paid Securities Lending), and Options.'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct ALTER COLUMN AppropriatenessProductID COMMENT 'Numeric identifier for the product category; 0 is the conventional null/not-applicable sentinel.';
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct ALTER COLUMN Name COMMENT 'Short product code used throughout the application layer to identify the assessed product type.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:09 UTC
-- Statements: 3/3 succeeded
-- ====================
