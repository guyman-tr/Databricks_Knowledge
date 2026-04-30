-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.DepositRollbackTracking
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_depositrollbacktracking
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_depositrollbacktracking (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking SET TBLPROPERTIES (
    'comment' = 'Audit log for deposit rollback operations - records every chargeback, refund, reversal, and cancellation action applied to a deposit, including the amount, currency, exchange rates, manager, reason, and rollback status. Source: etoro.Billing.DepositRollbackTracking on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.DepositRollbackTracking.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'DepositRollbackTracking',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN RollbackID COMMENT 'Surrogate primary key. Auto-incremented. NOT FOR REPLICATION prevents identity gaps on replication subscribers. bigint allows for high volume over time. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN CID COMMENT 'Customer whose deposit is being rolled back. Explicit FK to Customer.CustomerStatic(CID). Populated from Billing.Deposit.CID at time of rollback. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN DepositID COMMENT 'The deposit being rolled back. Explicit FK to Billing.Deposit(DepositID). Multiple rollback rows may exist per DepositID (e.g., chargeback then cancel). (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN PaymentStatusID COMMENT 'Type of rollback action. Explicit FK to Dictionary.PaymentStatus. Allowed values: 2=Approved(CancelRollback), 11=Chargeback, 12=Refund, 26=RefundAsChargeback, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit. Distribution: 12=51%, 39=16%, 2=16%, 11=12%, 26=5%. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN TotalRollbackAmountInUSD COMMENT 'Cumulative total amount rolled back for this deposit across all actions, in USD. Represents the running total at the time of this action. May exceed RollbackAmountInUSD for partial rollbacks. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN TotalRollbackAmountInCurrency COMMENT 'Same as TotalRollbackAmountInUSD but in the deposit''s original currency. Populated from @TotalRollbackAmountInCurrency parameter. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN RollbackAmountInUSD COMMENT 'Amount rolled back by this specific action, in USD. Computed if not provided: @RollbackAmountInCurrency @ExchangeRate. Used in Customer.SetBalance call: CAST(RollbackAmountInUSD 100 AS INT) = amount in cents. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN RollbackAmountInCurrency COMMENT 'Amount rolled back by this specific action, in the deposit''s original currency. The primary input amount from the caller. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN CurrencyID COMMENT 'Currency of the original deposit. Inherited from Billing.Deposit.CurrencyID at time of rollback. Implicit FK to Dictionary.Currency. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN ExchangeRate COMMENT 'Exchange rate used for currency conversion at time of rollback. User-defined type dtPrice (decimal). Defaults to the original deposit ExchangeRate if not explicitly passed. Used to convert RollbackAmountInCurrency to USD. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN BaseExchangeRate COMMENT 'Base exchange rate from the original deposit, carried forward to the rollback record for PIP calculation consistency. Inherited from Billing.Deposit.BaseExchangeRate. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN ExchangeFee COMMENT 'Exchange fee from the original deposit, inherited at rollback time. Used in PIP calculations via Billing.CalculateDepositRollbackPIPsUSD. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN ReferenceNumber COMMENT 'External payment processor reference number for this rollback action (e.g., chargeback case ID, refund transaction ID). NULL when not provided by the processor. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN RollbackReasonID COMMENT 'Categorizes why the rollback was performed. Lookup table not in SSDT repo. Dominant values: 0=no specific reason (56%), 2=most common tracked reason (43%). 18 distinct values observed. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN Comments COMMENT 'Free-text notes added by the manager performing the rollback. Passed to Customer.SetBalance as @Description. NULL when not provided. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN RollbackDate COMMENT 'The effective date of the rollback (e.g., date the chargeback was received from the processor). Distinct from CreateDate - represents when the event occurred in the external system, not when it was recorded in eToro''s database. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN CreateDate COMMENT 'UTC timestamp when this rollback record was created in eToro''s system. Set to GETDATE() at time of procedure execution. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of last modification. Initially set to GETDATE() = same as CreateDate. Updated when IsCanceled is set to 1 by a subsequent cancel-rollback action. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN ManagerID COMMENT 'Back-office manager who performed the rollback. Explicit FK to BackOffice.Manager(ManagerID). Passed to Customer.SetBalance for audit trail. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_depositrollbacktracking ALTER COLUMN IsCanceled COMMENT 'Whether this rollback was subsequently canceled. 0=active rollback (default on insert), 1=canceled by a later PaymentStatusID=2 action on the same deposit. 2,909 rows (16%) have IsCanceled=1. When canceling, all IsCanceled=0 rows for the DepositID are set to 1 before the new row is inserted. (Tier 1 - upstream wiki, etoro.Billing.DepositRollbackTracking)';

