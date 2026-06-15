-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_dictionary_optionsstatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.OptionsStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_optionsstatus SET TBLPROPERTIES (
    'comment' = '`Dictionary.OptionsStatus` is a static reference table that tracks the lifecycle stage of a user''s options trading application. Options trading is not automatically enabled at account opening; the user must explicitly apply, pass an appropriateness assessment, and receive a formal approval or rejection from the platform''s compliance workflow. The five statuses form an ordered progression: `None` (not yet applied), `Pending` (application submitted, awaiting review), `InProcess` (active review underway), `Approved` (application granted; user may trade options), and `Rejected` (application denied). The `None` sentinel is also used for users who have never expressed interest in options trading. `Apex.Options` stores the current `OptionsStatusID` for each user, making this dictionary the central reference point for options workflow reporting, alerting, and access control decisions.'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_optionsstatus ALTER COLUMN OptionsStatusID COMMENT 'Numeric identifier for the options application lifecycle stage; 0 is the sentinel for no application.';
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_optionsstatus ALTER COLUMN Name COMMENT 'Label representing the stage used in application logic, reporting, and compliance dashboards.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:13 UTC
-- Statements: 3/3 succeeded
-- ====================
