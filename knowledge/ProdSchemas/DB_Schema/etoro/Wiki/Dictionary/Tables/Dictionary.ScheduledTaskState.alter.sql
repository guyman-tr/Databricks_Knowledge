-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_scheduledtaskstate
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ScheduledTaskState.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledtaskstate SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the execution states for post-deposit scheduled tasks. Tracks whether a task for a given deposit is new, in-process, completed, failed, or excluded from processing. The billing system tracks multiple post-deposit tasks (AppsFlyer, RabbitMQ FTD, Pixel, Mixpanel, DepositDR) per deposit in `Billing.ScheduledTaskState`. Each task transitions through states as it''s picked up, processed, and completed. This dictionary provides the state vocabulary. The PK column name (`PostDepositTaskStateID`) reveals the original design - these are specifically post-deposit task states. When a deposit is created, task state rows are initialized at state 0 (new). Worker processes query for `TaskState = 0` to find pending work. Tasks move to `3` (inprocess) during execution, then to `1` (success) or `2` (failure) upon completion.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledtaskstate ALTER COLUMN PostDepositTaskStateID COMMENT 'Primary key. Task execution state: 0=new, 1=success, 2=failure, 3=inprocess, 4=noprocess. The PK name reveals its origin as a post-deposit tracking feature. Maps to `Billing.ScheduledTaskState.TaskState`.';
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledtaskstate ALTER COLUMN Name COMMENT 'Lowercase state label used in monitoring and diagnostic queries.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:22 UTC
-- Statements: 3/3 succeeded
-- ====================
