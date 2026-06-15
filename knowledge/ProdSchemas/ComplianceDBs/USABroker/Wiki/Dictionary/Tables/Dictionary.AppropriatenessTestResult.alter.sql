-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AppropriatenessTestResult.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult SET TBLPROPERTIES (
    'comment' = '`Dictionary.AppropriatenessTestResult` is a static reference table that encodes the three possible outcomes of a user''s appropriateness assessment: not yet evaluated (`None`), assessment failed (`Failed`), and assessment passed (`Passed`). This binary pass/fail outcome - with a sentinel for the uninitialised state - drives downstream access-control decisions across the platform. A `Passed` result allows the user to proceed with trading the assessed product type (e.g., Options, CFDs, FPSL). A `Failed` result triggers a restriction or an offer to proceed with a risk acknowledgement, depending on the product and jurisdiction. The `None` state indicates the assessment has not yet been run for that product. The table is referenced by `Apex.Options`, which stores the current appropriateness test result for each user/product combination as part of the options eligibility workflow.'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult ALTER COLUMN AppropriatenessTestResultID COMMENT 'Numeric identifier for the assessment outcome; 0 is the conventional null/not-applicable sentinel.';
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult ALTER COLUMN Name COMMENT 'Short label representing the assessment verdict stored in referencing tables.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:10 UTC
-- Statements: 3/3 succeeded
-- ====================
