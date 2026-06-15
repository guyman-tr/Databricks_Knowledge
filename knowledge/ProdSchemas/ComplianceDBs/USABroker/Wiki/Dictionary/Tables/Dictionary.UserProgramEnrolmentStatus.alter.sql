-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_usabroker_dictionary_userprogramenrolmentstatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.UserProgramEnrolmentStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_usabroker_dictionary_userprogramenrolmentstatus SET TBLPROPERTIES (
    'comment' = '`Dictionary.UserProgramEnrolmentStatus` is a static reference table that encodes the three possible enrolment states a user can hold in any optional brokerage programme (such as FPSL, crypto staking, or proxy voting). It represents the user''s expressed preference and the system''s confirmation of that preference for each programme they have interacted with. `None` (ID 0) is the sentinel for users who have never been processed through the enrolment workflow for a particular programme - their status is neither opted in nor opted out, but simply uninitialised. `OptIn` (ID 1) means the user has actively chosen to participate in the programme and the enrolment has been accepted. `OptOut` (ID 2) means the user has explicitly withdrawn from the programme after previously opting in, or has declined enrolment at the point of offer.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_usabroker_dictionary_userprogramenrolmentstatus ALTER COLUMN UserProgramEnrolmentStatusID COMMENT 'Stable numeric identifier for the enrolment state; 0 is the sentinel for not yet processed.';
ALTER TABLE main.general.bronze_usabroker_dictionary_userprogramenrolmentstatus ALTER COLUMN Name COMMENT 'Short label for the enrolment state used in application logic, reporting, and user-facing status displays.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:33 UTC
-- Statements: 3/3 succeeded
-- ====================
