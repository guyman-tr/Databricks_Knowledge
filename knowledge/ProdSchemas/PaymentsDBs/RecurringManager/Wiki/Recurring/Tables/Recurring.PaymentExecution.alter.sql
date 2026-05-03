-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Recurring.PaymentExecution
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_recurring_paymentexecution
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_recurring_paymentexecution (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution SET TBLPROPERTIES (
    'comment' = 'Core transactional table tracking individual execution cycles of recurring payments - each row represents one attempt to charge a customer''s payment method for a specific cycle of their recurring plan. Source: RecurringManager.Recurring.PaymentExecution on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecution.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Recurring',
    'source_table' = 'PaymentExecution',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN PaymentExecutionId COMMENT 'Auto-incrementing primary key. Current max ~859,547. Referenced by PaymentExecutionDepositResult, PaymentExecutionRequest, Notification, and Scheduler.Execution. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN PaymentId COMMENT 'FK to Recurring.Payment.PaymentId. Identifies which recurring plan this execution belongs to. Multiple executions per payment over time (one per billing cycle + retries). Indexed for lookup (IX_PaymentExecution_PaymentId) and composite queries. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN StatusId COMMENT 'Execution lifecycle status. FK to Dictionary.PaymentExecutionStatus: 1=Planned (1.9%), 2=InProcess, 3=SentToBilling (0.003%), 4=SendToBillingFailed, 5=SoftDeclined (1.3%), 6=HardDeclined (7.5%), 7=Approved (76.5%), 8=Cancelled (12.6%), 9=Skipped (0.2%), 10=Retry. Updated by UpdatePaymentExecutionStatus with optimistic concurrency on previous state. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN CycleNumber COMMENT 'Which billing cycle this execution represents (1 = first cycle, 2 = second, etc.). Combined with Retries to uniquely identify an execution attempt. Part of the unique filtered index for Planned executions. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN Retries COMMENT 'Retry count within the cycle (1 = first attempt). Used by CreatePaymentExecution in the duplicate check: NOT EXISTS (PaymentId + StatusId + Retries). Part of the unique filtered index for Planned executions. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN CreateDate COMMENT 'UTC timestamp when this execution was created by CreatePaymentExecution. Auto-set via default constraint. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the last status change. Set to GETUTCDATE() by UpdatePaymentExecutionStatus and CreatePaymentExecution. NULL if never modified after creation. Used by alert SPs for time-window filtering of stuck executions. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN SysStartTime COMMENT 'System-versioning row start time (HIDDEN). (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecution ALTER COLUMN SysEndTime COMMENT 'System-versioning row end time (HIDDEN). History stored in History.PaymentExecution. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecution)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:40:10 UTC
-- Bronze deploy: RecurringManager batch 1
-- ====================
