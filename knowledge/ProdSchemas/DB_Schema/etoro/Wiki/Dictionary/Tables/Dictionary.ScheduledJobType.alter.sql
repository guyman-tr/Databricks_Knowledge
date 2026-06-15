-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_scheduledjobtype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ScheduledJobType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledjobtype SET TBLPROPERTIES (
    'comment' = 'A lookup table classifying BackOffice scheduled jobs by their execution mechanism. Each type represents a different way the job scheduler invokes the job - via HTTP API call, message queue, or internal direct execution. eToro''s BackOffice scheduler supports multiple invocation patterns for automated tasks. Jobs can call external APIs, enqueue work items for asynchronous processing, or execute internal methods directly. This classification determines how the scheduler dispatches each job and which infrastructure path the execution follows. When defining a scheduled job in `BackOffice.ScheduledJob`, the `ScheduledJobTypeID` is set to indicate the execution mechanism. The job scheduler reads this type to determine whether to make an HTTP call (ApiJob), publish to a queue (InQueueJob), or call an internal method directly (InternalJob).'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledjobtype ALTER COLUMN ScheduledJobTypeID COMMENT 'Primary key. Job type identifier: 1=ApiJob, 2=InQueueJob, 3=InternalJob.';
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledjobtype ALTER COLUMN ScheduledJobType COMMENT 'Human-readable label for the job execution mechanism. Used in job configuration UI and monitoring.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:19 UTC
-- Statements: 3/3 succeeded
-- ====================
