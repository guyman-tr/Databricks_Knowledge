-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Recurring.PaymentExecutionDepositResult
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult SET TBLPROPERTIES (
    'comment' = 'Records the outcome of each billing processor deposit attempt for a payment execution, storing the processor''s response status, the resulting deposit ID, the USD-equivalent amount, and the decline classification. Source: RecurringManager.Recurring.PaymentExecutionDepositResult on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.PaymentExecutionDepositResult.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Recurring',
    'source_table' = 'PaymentExecutionDepositResult',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN PaymentExecutionDepositResultId COMMENT 'Auto-incrementing primary key. PAGE compressed. Current max ~354,564. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN PaymentExecutionId COMMENT 'FK to Recurring.PaymentExecution.PaymentExecutionId. Links this result to the execution that triggered the billing attempt. Part of the upsert key with CycleNumber. Indexed (PAGE compressed). (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN CycleNumber COMMENT 'Billing cycle number matching the execution''s cycle. Part of the upsert key with PaymentExecutionId. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN AmountInUsd COMMENT 'The deposit amount converted to USD. Used for financial reporting and reconciliation. The original amount in the payment''s currency is stored in PaymentExecutionRequest.Amount. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN DepositId COMMENT 'External reference to the deposit transaction in the billing/payments system. Created by the payment processor when the charge is initiated. Used for reconciliation between the recurring system and the billing ledger. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN PaymentStatusId COMMENT 'Raw billing processor response status. NOT from Dictionary.PaymentExecutionStatus - these are external billing system codes: 2=Approved (89.5%), 3=Declined (10%), 35=Severe failure (0.5%), 4=Other failure (0.1%). Maps to ExecutionStatusResultConfig for outcome classification. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN StatusCode COMMENT 'Specific billing processor sub-code for declined transactions. NULL for successful deposits. Combined with PaymentStatusId, used to look up the handling rule in ExecutionStatusResultConfig (e.g., code 1214=insufficient funds, code 1960=expired card). (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN GroupKey COMMENT 'Grouping key for batched deposit results. Typically empty string in current data. May be used for multi-part transactions or grouped charges. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN ExecutionResultStatusId COMMENT 'System''s classification of the billing result. FK to Dictionary.ExecutionResultStatus: 1=Success (89.5%), 2=SoftDecline (3.2%), 3=HardDecline (7.4%). Determined by looking up (PaymentStatusId, StatusCode) in ExecutionStatusResultConfig. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN PaymentDate COMMENT 'Timestamp of when the billing processor actually processed the payment. May differ from CreateDate if there was a processing delay. NULL in some edge cases. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN CreateDate COMMENT 'UTC timestamp when this result row was first created. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the last update. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult on both insert and update. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN SysStartTime COMMENT 'System-versioning row start time (HIDDEN). (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_paymentexecutiondepositresult ALTER COLUMN SysEndTime COMMENT 'System-versioning row end time (HIDDEN). History in History.PaymentExecutionDepositResult. (Tier 1 - upstream wiki, RecurringManager.Recurring.PaymentExecutionDepositResult)';

