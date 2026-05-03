-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.CashoutRollbackTracking
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_cashoutrollbacktracking
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_cashoutrollbacktracking (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking SET TBLPROPERTIES (
    'comment' = 'Audit trail for cashout (withdrawal) rollback events; each row records one rollback transaction - a reversal of a processed payment leg - with both the partial rollback amount and the running cumulative rollback total for the withdrawal. Source: etoro.Billing.CashoutRollbackTracking on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CashoutRollbackTracking.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'CashoutRollbackTracking',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN RollbackID COMMENT 'Auto-incrementing primary key for this rollback event record. Output via @RollbackID OUTPUT parameter of AddCashoutRollbackTrackingRecord. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN CID COMMENT 'Customer ID of the account whose withdrawal is being rolled back. Not passed directly by the caller - derived inside AddCashoutRollbackTrackingRecord by querying Billing.Withdraw for the given WithdrawID. Implicit FK to Customer.CustomerStatic(CID). (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN WitdrawToFundingID COMMENT 'ID of the specific payment leg (Billing.WithdrawToFunding) being rolled back. Note: column name has a typo ("Witdraw" not "Withdraw") inherited from the original design. Has a NC index for lookup performance. Implicit FK to Billing.WithdrawToFunding(ID). (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN PaymentStatusID COMMENT 'Status of the rollback at time of recording. Always 2 across all 7,349 rows (set from @CashoutStatusID parameter). Uses the same CashoutStatus lookup as Billing.Withdraw. The constant value 2 suggests rollbacks are only recorded when the payment is in a specific pre-rollback state. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN TotalRollbackAmountInUSD COMMENT 'Running cumulative total of all rollback amounts (in USD) applied to the same WitdrawToFundingID at the time this event is recorded. Passed by the caller; caller maintains the running total externally. Can be negative when corrections are applied. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN TotalRollbackAmountInCurrency COMMENT 'Running cumulative total in the original transaction currency (identified by CurrencyID). Parallel to TotalRollbackAmountInUSD but in the customer-facing currency. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN RollbackAmountInUSD COMMENT 'The incremental amount (in USD) reversed in this specific rollback event. Negative values indicate a rollback correction (reversal of a previous rollback). Summed by GetCashoutRollbackAmounts to compute net rollback totals. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN RollbackAmountInCurrency COMMENT 'The incremental amount in the original transaction currency for this rollback event. Parallel to RollbackAmountInUSD. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN CurrencyID COMMENT 'Currency of the amount columns (*InCurrency). Implicit FK to Dictionary.Currency. Passed in by caller (optional, defaults to NULL in proc signature but stored as NOT NULL). Common values: 1=USD, 2=EUR. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN ExchangeRate COMMENT 'Exchange rate between the rollback currency and USD applicable at the time of this rollback event. Passed by the caller, distinct from the original withdrawal exchange rate. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN BaseExchangeRate COMMENT 'Base exchange rate from the original Billing.WithdrawToFunding leg, copied at rollback time by AddCashoutRollbackTrackingRecord (not passed by the caller - fetched automatically from WithdrawToFunding). Uses dbo.dtPrice UDT (decimal price type). (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN ExchangeFee COMMENT 'Exchange fee percentage from the original Billing.WithdrawToFunding leg, copied at rollback time alongside BaseExchangeRate. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN ReferenceNumber COMMENT 'Optional external reference number for the rollback transaction (e.g., payment provider reference for the refund). NULL when no external reference is available. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN RollbackReasonID COMMENT 'Reason code for the rollback. Maps to @RollbackType parameter in AddCashoutRollbackTrackingRecord. No Dictionary lookup table found. Observed values: 0 (1,170 rows - default/unknown), 1 (70 rows), 3 (6,080 rows - dominant), 4 (29 rows - appears in correction events). (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN Comments COMMENT 'Optional free-text notes about the rollback reason or context. NULL in most entries. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN RollbackDate COMMENT 'Date/time when the rollback event occurred (as reported by the caller via @RollbackDate). Distinct from CreateDate - allows back-dating when recording a rollback that was initiated at a different time. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN CreateDate COMMENT 'UTC timestamp when this tracking record was inserted. Always set to GETUTCDATE() inside AddCashoutRollbackTrackingRecord, not controlled by caller. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN ModificationDate COMMENT 'Set to GETUTCDATE() at INSERT (same as CreateDate). No UPDATE procedure found, so this field may remain equal to CreateDate for all rows. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN ManagerID COMMENT 'ID of the back-office manager who initiated the rollback, or 0 for system-initiated rollbacks. Passed via @ManagerID (optional parameter). Implicit FK to BackOffice.Manager or similar admin user table. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN IsCanceled COMMENT 'Always 0 across all 7,349 rows. Hardcoded to 0 in AddCashoutRollbackTrackingRecord INSERT. No UPDATE procedure changes it. May have been intended to allow cancelling a rollback record but the feature was never implemented. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN WithdrawID COMMENT 'The parent withdrawal request ID (Billing.Withdraw.WithdrawID). Never NULL in practice (all 7,349 rows populated). Implicit FK to Billing.Withdraw. Enables grouping rollback events by withdrawal in GetCashoutRollbackAmounts. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN WithdrawToFundingActionID COMMENT 'The most recent History.WithdrawToFundingAction.WithdrawToFundingActionID for the payment leg at the time of rollback. Fetched automatically inside AddCashoutRollbackTrackingRecord; not passed by caller. Links this rollback to its corresponding action history entry. Implicit FK to History.WithdrawToFundingAction. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
ALTER TABLE main.billing.bronze_etoro_billing_cashoutrollbacktracking ALTER COLUMN CreditID COMMENT 'Always NULL in current data. Likely reserved for linking to a credit note or credit account entry issued as part of the rollback. Feature not yet implemented or not used in current flows. (Tier 1 - upstream wiki, etoro.Billing.CashoutRollbackTracking)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
