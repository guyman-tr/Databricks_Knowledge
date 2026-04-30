-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.Withdraw
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_withdraw
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_withdraw (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_withdraw SET TBLPROPERTIES (
    'comment' = 'Core withdrawal request table (1.66M records); each row represents one customer withdrawal request with full lifecycle tracking from pending through processed or cancelled, including amount, fees, commission, and the funding instrument used for payout. Source: etoro.Billing.Withdraw on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_withdraw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'Withdraw',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN WithdrawID COMMENT 'Primary key. IDENTITY starting at 1. Both a PK NONCLUSTERED and a separate CLUSTERED index exist on this column (unusual pattern - PK is non-clustered to allow covering indexes to reference the clustered key). NOT FOR REPLICATION. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN CurrencyID COMMENT 'Currency of the withdrawal amount. FK to Dictionary.Currency (FK_DCUR_BWDR). Indexed (i_CureenyID - note typo in index name). (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN FundingTypeID COMMENT 'Payment method type (Visa/Wire/Neteller/eToroMoney/etc.). References Dictionary.FundingType implicitly. 26 distinct values in live data. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN CID COMMENT 'Customer ID. FK to Customer.CustomerStatic (FK_CCST_BWDR). Indexed in covering indexes (CashoutStatusID+CID, CoveringNew). (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ManagerID COMMENT 'Operations manager who processed or last modified this withdrawal. FK to BackOffice.Manager (FK_BMNG_BWDR). NULL=system-initiated or customer self-service. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN CashoutStatusID COMMENT 'Current withdrawal status. FK to Dictionary.CashoutStatus (FK_DCSS_BWDR). 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/7/8/14/16/17=specialized states. Indexed (multiple covering indexes). (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN RequestDate COMMENT 'Timestamp when the customer submitted the withdrawal request. Included in covering indexes for date-range queries. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN Amount COMMENT 'Gross withdrawal amount in CurrencyID denomination. money type (4 decimal places). Included in covering indexes. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN Commission COMMENT 'Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers; may be non-zero for professional/partner accounts. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN Approved COMMENT 'Whether the withdrawal has received required approval (e.g., compliance/operations sign-off): 1=Approved, 0=Pending approval. DEFAULT=0. Included in covering index for filtered queries. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN IPAddress COMMENT 'Customer''s IP address at request time, stored as integer (IPv4 -> decimal). Fraud detection and audit trail. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the most recent status change or update. Indexed (ix_BillingWithdraw_ModificationDate). Included in covering index. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN Remark COMMENT 'Processing note added by the system or operations staff. Included in covering index INCLUDE list. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN Comment COMMENT 'Additional operations comment. Included in covering index INCLUDE list. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN Fee COMMENT 'Platform fee charged for this withdrawal. Subtracted from the gross Amount. Included in covering index. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN FundingID COMMENT 'FK to Billing.Funding - the payment instrument to which the withdrawal should be paid. NULL if no specific instrument selected at request time. Included in covering index. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN RequestorComments COMMENT 'Notes added by the requesting party (customer or system). DEFAULT NULL. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN SessionID COMMENT 'Audit session identifier linking this withdrawal to a specific user session. DEFAULT NULL. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN CashoutReasonID COMMENT 'Internal reason code for the withdrawal decision (e.g., why it was cancelled or flagged). References an internal catalog. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN SuggestedBonusDeductionAmount COMMENT 'Pre-calculated amount of trading bonus to claw back when the customer withdraws (per bonus terms). DEFAULT=0. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ActualBonusDeductionAmount COMMENT 'Actual bonus amount deducted after processing. May differ from suggested amount if conditions changed. NULL until finalized. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ClientWithdrawReasonID COMMENT 'Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). References a reason catalog implicitly. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ClientWithdrawReasonComment COMMENT 'Customer''s free-text explanation for the withdrawal reason. Max 510 characters. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN AccountCurrencyID COMMENT 'Customer''s eToro account currency, if different from CurrencyID. FK to Dictionary.Currency (FK_DCUR_BWAC). Included in covering index. Used when account and withdrawal currencies differ. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ClientWithdrawCommentID COMMENT 'FK to Dictionary.ClientWithdrawComment (FK_BillingWithdraw_DictionaryClientWithdrawComment). Standardized comment category for the withdrawal (used in customer-facing messaging). (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN ExTransactionID COMMENT 'External transaction identifier from the payment provider. Links this withdrawal record to the provider''s transaction reference. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN WithdrawTypeID COMMENT 'Withdrawal type classification added in a later release. NULL=legacy record (55%). 0=standard withdrawal (41%). 1=special/alternate type (3.7%). 2=second alternate type (0.5%). Used by WithdrawToFundingProcess to determine MoveMoneyReasonID override: WithdrawTypeID=1 + FlowID=2 -> MoveMoneyReasonID=5; WithdrawTypeID=1 + FlowID=3 -> MoveMoneyReasonID=6. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_withdraw ALTER COLUMN FlowID COMMENT 'Processing flow identifier added in a later release. NULL=legacy (59%). 0=standard flow (38%). 2=eToroMoney local currency withdrawal (2.6%, 42,952 records). 3=specific alternate flow (708 records). 9=rare special case (9 records). 1=one record. FlowID=2 with FundingTypeID=33 triggers eToroMoney-specific balance accounting. (Tier 1 - upstream wiki, etoro.Billing.Withdraw)';

