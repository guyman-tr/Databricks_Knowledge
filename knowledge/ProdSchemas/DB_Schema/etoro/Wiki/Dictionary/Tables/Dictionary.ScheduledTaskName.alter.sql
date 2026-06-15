-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_scheduledtaskname
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ScheduledTaskName.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledtaskname SET TBLPROPERTIES (
    'comment' = 'A lookup table identifying post-deposit scheduled tasks that run after a deposit is processed. Each entry represents a specific integration or notification pipeline that must execute as part of deposit completion. When a deposit is processed by the billing system, several downstream tasks must execute - sending data to AppsFlyer for attribution, publishing FTD (First Time Deposit) events to RabbitMQ, firing tracking pixels, sending events to Mixpanel, and processing deposit dispute resolution. This table names each of those tasks so the `Billing.ScheduledTaskState` table can track their execution per deposit. The `Billing.ScheduledTaskState` table has a composite key of `(DepositID, TaskID)`. When a deposit is created (via `Billing.DepositAdd`), task state records are initialized for each applicable task.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledtaskname ALTER COLUMN TaskID COMMENT 'Primary key. Scheduled task identifier: 1=AppsFlyer, 2=RabbitMqFtd, 3=DepositPixel, 4=MixPanel, 5=DepositDR. Used as part of composite key in `Billing.ScheduledTaskState`.';
ALTER TABLE main.general.bronze_etoro_dictionary_scheduledtaskname ALTER COLUMN TaskName COMMENT 'Human-readable task name identifying the external integration or processing pipeline.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:20 UTC
-- Statements: 3/3 succeeded
-- ====================
