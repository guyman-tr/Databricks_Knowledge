-- =============================================================================
-- Databricks ALTER Script: bronze RecurringManager.Recurring.Payment
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md
-- Layer: bronze
-- UC Target: main.billing.bronze_recurringmanager_recurring_payment
-- =============================================================================

-- ---- UC Target: main.billing.bronze_recurringmanager_recurring_payment (business_group=billing) ----
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment SET TBLPROPERTIES (
    'comment' = 'Core transactional table storing recurring payment subscriptions - each row represents a customer''s recurring deposit or recurring investment plan with its current status, amount, and payment method. Source: RecurringManager.Recurring.Payment on the RecurringManager production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Recurring/Tables/Recurring.Payment.md).'
);

ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'RecurringManager',
    'source_schema' = 'Recurring',
    'source_table' = 'Payment',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN PaymentId COMMENT 'Auto-incrementing primary key uniquely identifying each recurring payment plan. Referenced by PaymentExecution.PaymentId, PaymentConsent.PaymentId, and Scheduler.Plan.PaymentId. Current max ~200,820. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN Cid COMMENT 'Customer ID identifying the account holder who owns this recurring plan. Indexed for lookups by customer (IX_RecurringPayment_CID). Used by GetPaymentsByCid and Alert_CIDWithMoreThanAllowed to find all plans for a customer. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN FundingId COMMENT 'External reference to the customer''s payment method (credit card, bank account, etc.) in the billing/payments system. Can be updated via UpdatePayment when a customer changes their funding source, and reverted via RevertPayment. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN Amount COMMENT 'The recurring payment amount in the currency specified by CurrencyId. Represents the fixed amount charged each execution cycle. Can be modified via UpdatePayment and reverted via RevertPayment. Observed range: 50-1,300 in sample data. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN CurrencyId COMMENT 'Currency of the recurring payment amount. References an external currency dictionary (likely etoro Dictionary.Currency). Top values: 1 (49% - likely USD), 2 (25% - likely EUR), 3 (16% - likely GBP), 5 (6% - likely AUD). 26 distinct currencies observed. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN StatusId COMMENT 'Payment plan lifecycle status. No explicit Dictionary table exists in this database - values inferred from code and data: 1=Active (8.2%, created by CreatePayment, included in duplicate check), 2=Cancelled (57.1%, voluntary termination), 3=Blocked (34.1%, hard decline from processor), 4=Invalid (0.01%, rare terminal state), 5=Pending/Paused (0.6%, included with Active in duplicate prevention). Indexed for filtering (IX_RecurringPayment_StatusId). (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN CreateDate COMMENT 'UTC timestamp when the payment plan was first created by CreatePayment. Auto-set via default constraint. Indexed for time-range queries (IX_RecurringPayment_CreateDate). Used by alert SPs to find recently created but unscheduled payments. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the last modification to this payment. Set to GETUTCDATE() by UpdatePayment on every update. NULL if never modified after creation. Used by alert SPs with time-window filtering. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN StatusReasonId COMMENT 'Reason why the payment reached its current status. FK to Dictionary.StatusReason: 1=RemovedMOP (1.5% - payment method removed), 2=CancelledByUser (34% - voluntary cancellation), 3=CancelledByBO (0.001% - back-office cancellation), 4=CanceledInvestment (6% - investment program cancelled), 5=HardDecline (6% - processor permanently declined). NULL for active payments (53%). (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN RecurringProgramTypeId COMMENT 'Type of recurring program. FK to Dictionary.RecurringProgramType: 1=RecurringDeposit (84% - periodic account deposits), 2=RecurringInvestment (16% - periodic portfolio investments). Defaults to 1. A customer can have only one active plan per type (enforced by CreatePayment). (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN VersionStamp COMMENT 'Optimistic concurrency token (GUID format). Set when a modification is in progress. RevertPayment checks WHERE VersionStamp LIKE @VersionStamp before reverting - if another process changed it, the revert is a no-op. Cleared to NULL on successful revert. NULL for most rows (no pending modification). (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN AuthenticationId COMMENT 'Reference to an external authentication/authorization record for the payment method. Populated when the funding method requires SCA (Strong Customer Authentication) or similar verification. NULL when no authentication is needed (e.g., previously authorized methods). (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN Generation COMMENT 'Modification counter tracking how many update rounds the plan has undergone. 0=original/unmodified (98%), 1=modified once (2%). Reset to 0 by UpdatePayment on non-status updates; preserved on status changes. Used with VersionStamp for concurrency control. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN SysStartTime COMMENT 'System-versioning row start time (HIDDEN). Marks when this version of the row became current. Auto-managed by SQL Server temporal tables. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';
ALTER TABLE main.billing.bronze_recurringmanager_recurring_payment ALTER COLUMN SysEndTime COMMENT 'System-versioning row end time (HIDDEN). Set to max datetime for current rows; updated to actual end time when the row is modified. History rows are stored in History.Payment. (Tier 1 - upstream wiki, RecurringManager.Recurring.Payment)';

