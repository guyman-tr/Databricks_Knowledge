-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_dictionary_eligibilitystatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.EligibilityStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_eligibilitystatus SET TBLPROPERTIES (
    'comment' = '`Dictionary.EligibilityStatus` is a static reference table that represents the binary eligibility gate controlling whether a user is permitted to proceed with a particular product, feature, or account action. It is intentionally minimal - just two values - reflecting the fact that eligibility at this level is an all-or-nothing decision: either the user satisfies all conditions and is `Allowed`, or they do not and are `Disallowed`. The `Disallowed` state (ID 0) may result from failing an appropriateness test, not meeting residency requirements, being flagged by compliance controls, or having an incomplete verification status. The `Allowed` state (ID 1) indicates that all prerequisite checks have passed and the user may proceed. `Apex.Options` stores this value as `EligibilityStatusID`, meaning the eligibility determination for options trading is captured per user and auditable through...'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_eligibilitystatus ALTER COLUMN EligibilityStatusID COMMENT 'Numeric identifier; 0 = Disallowed, 1 = Allowed.';
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_eligibilitystatus ALTER COLUMN Name COMMENT 'Human-readable label for the eligibility gate outcome.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:11 UTC
-- Statements: 3/3 succeeded
-- ====================
