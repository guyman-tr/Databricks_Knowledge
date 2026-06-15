-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_scheduledtaskstate
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.billing.bronze_etoro_billing_scheduledtaskstate SET TBLPROPERTIES (
    'comment' = 'Deposit-level task execution state table - tracks which deposits are pending, in-progress, or completed for each of the 8 post-deposit processing pipelines (AppsFlyer, pixels, RabbitMQ FTD, Mixpanel, etc.).'
);

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_scheduledtaskstate ALTER COLUMN DepositID COMMENT 'The deposit being processed. Part of the composite PK. Implicit FK to Billing.Deposit(DepositID). `GetScheduledTask*` procedures JOIN `Billing.Deposit D ON STS.DepositID = D.DepositID` to get deposit data for processing.';
ALTER TABLE main.billing.bronze_etoro_billing_scheduledtaskstate ALTER COLUMN TaskID COMMENT 'The task type. Part of the composite PK. References Billing.ScheduledTaskConfig(TaskID). Values 1-8. Each TaskID represents a different downstream system: 1=AppsFlyer, 2=RabbitMQ FTD, 3=RabbitMQ FTD remote, 5=Monitor, 7=Deposit processing, 8=Mixpanel (inferred from procedure names).';
ALTER TABLE main.billing.bronze_etoro_billing_scheduledtaskstate ALTER COLUMN TaskState COMMENT 'Execution state. Default=0. 0=Pending (waiting to be fetched), 1=Done/Processed (primary completion), 2=Second-phase done (TaskID=3 only), 3=In-Progress (transient, set during batch fetch), 4=Final done (TaskID=1/AppsFlyer only).';
ALTER TABLE main.billing.bronze_etoro_billing_scheduledtaskstate ALTER COLUMN ReasonID COMMENT 'Outcome reason code. Set by `UpdateScheduledTaskState`. NULL for pending and in-progress rows. Non-null values indicate specific processing outcomes (success codes, failure reasons). Exact values require application code review.';
ALTER TABLE main.billing.bronze_etoro_billing_scheduledtaskstate ALTER COLUMN Created COMMENT 'UTC timestamp of the last state change. Defaults to getutcdate() on INSERT. Updated by scheduler procedures (using GetDate() - local time inconsistency). For pending rows reflects deposit creation time. For in-progress/done reflects when the state was last changed.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:27 UTC
-- Statements: 6/6 succeeded
-- ====================
