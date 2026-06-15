-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_scheduledjobstatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ScheduledJobStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledjobstatus SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the execution status of BackOffice scheduled jobs. Each value represents a state in the job execution lifecycle - running, completed, or failed. eToro''s BackOffice scheduler runs automated tasks (API calls, queue processing, internal jobs) on cron schedules. Each execution is logged in `BackOffice.ScheduledJobHistory` with a status ID from this table, enabling monitoring dashboards to track job health and alerting on failures. When a scheduled job starts, a history record is created with `StatusID = 1` (Running). Upon completion, the status is updated to `2` (Completed) or `3` (Failed) with optional exception details. The `BackOffice.ScheduledJobHistory` table has an explicit FK to this lookup.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledjobstatus ALTER COLUMN ScheduledJobStatusID COMMENT 'Primary key. Job execution status: 1=Running, 2=Completed, 3=Failed.';
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledjobstatus ALTER COLUMN ScheduledJobStatusName COMMENT 'Human-readable status label for monitoring dashboards and job history reports.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:18 UTC
-- Statements: 3/3 succeeded
-- ====================
