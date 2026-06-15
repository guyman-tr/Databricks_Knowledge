-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_usabroker_dictionary_reasoningstatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ReasoningStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_reasoningstatus SET TBLPROPERTIES (
    'comment' = '`Dictionary.ReasoningStatus` is a static reference table that tracks the workflow state of the Options Reasoning Form process - the journey a user goes through when they request to downgrade or opt out of options trading access. When an options-enabled user wishes to reduce their trading permissions, the platform presents a reasoning questionnaire to capture a documented rationale before processing the downgrade. The five statuses reflect the stages of that workflow. `None` is the baseline for users who are not in a reasoning workflow. `PendingReasoningScreen` means the user has been prompted but not yet completed the form. `PendingManualReview` means the completed form has been escalated for a human compliance reviewer to assess. `Allowed` means the reasoning process is complete and the downgrade may proceed.'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_reasoningstatus ALTER COLUMN ReasoningStatusID COMMENT 'Numeric identifier for the reasoning workflow stage; 0 is the sentinel for not in workflow.';
ALTER TABLE main.bi_db.bronze_usabroker_dictionary_reasoningstatus ALTER COLUMN ReasoningStatusText COMMENT 'Descriptive label for the workflow stage; note the non-standard column name (not `Name`) reflecting the text-centric nature of the status.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:17 UTC
-- Statements: 3/3 succeeded
-- ====================
