-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.vWithdrawToFunding
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_vwithdrawtofunding
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_vwithdrawtofunding (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding SET TBLPROPERTIES (
    'comment' = 'Full-projection view of Billing.WithdrawToFunding with WITH(NOLOCK) hint and the addition of ExchangeFeeInUSD and ExchangeFeeInPercentage columns (added Ran Ovadia 17/09/2024). Provides the complete withdrawal payment leg dataset for external consumers. Source: etoro.Billing.vWithdrawToFunding on the etoro production database, ingested via the Generic Pipeline (Merge strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'vWithdrawToFunding',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN WithdrawID COMMENT 'FK to Billing.Withdraw. The parent withdrawal request. One WithdrawID can have multiple payment legs. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN FundingID COMMENT 'FK to Billing.Funding. The payment instrument used for this withdrawal leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN CashoutStatusID COMMENT 'Current status of this withdrawal leg. References Dictionary.CashoutStatus. 3=Processed (money sent). NOT filtered in this view - all statuses returned. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ProcessCurrencyID COMMENT 'Currency in which the withdrawal was processed. References Dictionary.Currency. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ManagerID COMMENT 'Assigned manager/agent ID for manual review of this withdrawal leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ExchangeRate COMMENT 'Exchange rate applied to convert the withdrawal to USD. The customer-facing rate including FX markup. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN Amount COMMENT 'Withdrawal leg amount in ProcessCurrencyID. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ModificationDate COMMENT 'Last modification timestamp of this withdrawal leg record. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ID COMMENT 'PK of Billing.WithdrawToFunding. Unique identifier for this withdrawal payment leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN DepositID COMMENT 'FK to Billing.Deposit. Set when the withdrawal is a refund of a specific deposit (e.g., credit card refund must go back to original deposit''s card). (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN RefundAmountInDepositCurrency COMMENT 'The USD-equivalent amount of this withdrawal leg. Used in FX fee calculations in GetWithdrawToFundingFXFeeAmount. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN CashoutTypeID COMMENT 'Type of cashout/withdrawal. References Dictionary.CashoutType. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN VerificationCode COMMENT 'Verification/confirmation code for this withdrawal leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ProcessorValueDate COMMENT 'Value date from the payment processor for this leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN MatchStatusID COMMENT 'Reconciliation matching status. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN DepotID COMMENT 'FK to Billing.Depot. Gateway/depot that processed this withdrawal leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN BaseExchangeRate COMMENT 'Market/interbank exchange rate (without FX markup) at time of processing. Used with ExchangeRate to compute FX fee spread. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN CashoutModeID COMMENT 'Mode of the cashout operation. References Dictionary.CashoutMode. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN AutoPaymentStartDate COMMENT 'Start date of the automatic payment schedule (for recurring withdrawals). (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ProtocolMIDSettingsID COMMENT 'FK to Billing.ProtocolMIDSettings. The specific MID configuration used for this withdrawal. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ExchangeFee COMMENT 'Raw FX fee value in the rate''s decimal form. Used in BaseExchangeRate derivation (WireTransfer path): BaseRate = ExchangeRate - ExchangeFee/10^Multiplier. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN CreationDate COMMENT 'Timestamp when this withdrawal leg was created. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN AdditionalInformation COMMENT 'Free-text additional context for this withdrawal leg (notes, processor responses). (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN VendorCode COMMENT 'Vendor/processor-specific reference code for this withdrawal. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN MerchantAccountID COMMENT 'FK to merchant account used for processing. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN SchemeId COMMENT 'Payment scheme identifier (e.g., Visa, Mastercard scheme for card withdrawals). (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ResponseID COMMENT 'Payment processor response identifier for this withdrawal leg. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN RequestExecuteEntryMethodId COMMENT 'Entry method used when this withdrawal request was executed. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ExchangeFeeInUSD COMMENT 'FX fee expressed in USD. Added 17/09/2024 by Ran Ovadia. Part of the 2024 FX fee transparency initiative. NULL for pre-2024 records. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
ALTER TABLE main.billing.bronze_etoro_billing_vwithdrawtofunding ALTER COLUMN ExchangeFeeInPercentage COMMENT 'FX fee expressed as a percentage of the withdrawal amount. Added 17/09/2024. NULL for pre-2024 records. (Tier 1 - upstream wiki, etoro.Billing.vWithdrawToFunding)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
