-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Deposit_DataFactory
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_deposit_datafactory
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_deposit_datafactory (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory SET TBLPROPERTIES (
    'comment' = 'BI-optimized view of the deposit audit log - filters out known spam customers and excludes bulk XML and late-added fee columns to provide a clean, analysis-ready interface to History.Deposit for data pipelines and reporting. Source: etoro.History.Deposit_DataFactory on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Deposit_DataFactory',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN Occurred COMMENT 'UTC timestamp of this deposit event. The base table CLUSTERED index sorts on (Occurred, DepositID). Primary time axis for BI time-series analysis. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN DepositID COMMENT 'Identifier of the deposit record being audited. One DepositID appears multiple times as the deposit progresses through status stages. FK to Billing.Deposit (implicit). (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN CID COMMENT 'Customer who made the deposit. Filtered: CID=43496401 excluded (spam account). Central key for per-customer deposit analytics. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN FundingID COMMENT 'Specific payment instrument used (credit card, bank account, PayPal, etc.). References Billing.Funding. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN CurrencyID COMMENT 'Currency of the deposit amount. Live data shows 2=EUR, 3=other currencies. References Dictionary.Currency. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN PaymentStatusID COMMENT 'Deposit processing state at this event. 1=New, 2=Approved, 5=InProcess, 13=Failed, 11=Chargeback, 36=PendingReview. The primary "what changed" field in the event log. (Source: Dictionary.PaymentStatus) (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ManagerID COMMENT 'Back-office manager who manually triggered this deposit state change. NULL for automated payment processor events. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN RiskManagementStatusID COMMENT 'Risk engine evaluation result for this deposit event. Non-null when a risk rule was applied. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN Amount COMMENT 'Gross deposit amount in the deposit''s currency before fees/commissions. The face value requested by the customer. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ExchangeRate COMMENT 'Exchange rate applied to convert the deposit currency to the account''s base currency. NULL if same-currency deposit. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN PaymentDate COMMENT 'Payment provider''s confirmed transaction date. May differ from Occurred when provider confirmation is delayed. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ModificationDate COMMENT 'Timestamp of the last modification to the source Billing.Deposit record at the time this history row was captured. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN TransactionID COMMENT 'Short 6-character internal transaction reference code. Legacy field from early eToro. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN IPAddress COMMENT 'Customer''s IP address at deposit time, stored as a numeric integer (legacy IP-as-integer format). Used for fraud geo-analysis. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN Approved COMMENT 'Legacy approval flag. 1=deposit was approved. Predates the full PaymentStatusID system; maintained for backward compatibility. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN Commission COMMENT 'Platform commission (fee) deducted from the deposit. 0 for most standard deposits. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ClearingHouseEffectiveDate COMMENT 'Date the clearing house (bank) recognized the transaction. May lag PaymentDate by 1-3 business days for wire transfers. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN OldPaymentID COMMENT 'Reference to a superseded/replaced payment record. Used when a deposit is re-submitted from a legacy payment system. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN IsFTD COMMENT 'First-Time Deposit flag. 1=this event was the customer''s qualifying first deposit. Critical for marketing attribution, bonus eligibility, and KYC compliance triggers. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ProcessorValueDate COMMENT 'Value date assigned by the payment processor - when funds become available to eToro. Important for treasury/cash management. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN RefundVerificationCode COMMENT 'Verification code required to authorize a refund. Security measure ensuring refunds match the original deposit. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN DepotID COMMENT 'Depot/vault identifier for the funds. Used in multi-entity or multi-jurisdiction fund segregation. NULL for standard retail deposits. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN MatchStatusID COMMENT 'Wire transfer matching status. For bank wire deposits where the incoming transfer must be matched to the deposit request. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN FunnelID COMMENT 'Marketing/acquisition funnel the customer was on at deposit time. Used for conversion analytics and campaign ROI. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN Code COMMENT 'Promotional or campaign code applied at deposit time. NULL for no-promo deposits. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ExTransactionID COMMENT 'External transaction ID from the payment provider. Used for provider-side reconciliation and dispute filing. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN CampaignCodeID COMMENT 'Campaign code that qualified this deposit for a bonus. NULL if deposit was not part of a bonus campaign. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN BonusStatusID COMMENT 'Processing state of the bonus associated with this deposit. Tracks whether bonus was awarded, failed, or pending. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN BonusAmount COMMENT 'Bonus credit amount granted based on this deposit. NULL if no bonus was applicable. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN BonusErrorCode COMMENT 'Error code when bonus processing failed. 1=Campaign inactive, 2=Already received, 3=Max users reached, 4=Max amount reached, 5=User cap reached, 6=Bonus max reached. NULL=no error. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN SessionID COMMENT 'Web/API session ID at deposit submission time. Links to session audit tables for end-to-end request tracing. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN DepositTypeID COMMENT 'Deposit transaction type. Live data shows 5=RecurringInvestment. 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. (Source: Dictionary.DepositType) (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ID COMMENT 'Surrogate PK for this audit event row. Auto-incrementing - higher ID = later event. Not the same as DepositID. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN DRStatusID COMMENT 'Dispute/Reversal status. 0=no dispute. Non-zero=chargeback or reversal process active. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN DRDate COMMENT 'Date when the dispute/reversal was opened or last updated. NULL when DRStatusID=0. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Merchant ID configuration at the time of this deposit. Identifies which payment gateway MID processed this deposit. References History.ProtocolMIDSettings. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ExchangeFee COMMENT 'Fixed fee component for currency exchange in minor units. Applied when deposit currency differs from account currency. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN BaseExchangeRate COMMENT 'Base exchange rate before markup. Paired with ExchangeRate to calculate the markup applied on top of the mid-market rate. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN PaymentGeneration COMMENT 'Payment system generation/version indicator. Live data shows 1=first-generation pipeline. Distinguishes deposits processed by different versions. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN ProcessRegulationID COMMENT 'Regulatory jurisdiction under which this deposit was processed. Determines compliance rules and reporting requirements. (Source: Dictionary.Regulation) (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN IsSetBalanceCompleted COMMENT 'Whether the Customer.SetBalance call that accompanies deposit approval completed successfully. 1=balance updated; NULL/0=pending or failed. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN RoutingReasonID COMMENT 'Reason the deposit was routed to a specific payment processor. Used in multi-processor setups. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
ALTER TABLE main.bi_db.bronze_etoro_history_deposit_datafactory ALTER COLUMN MerchantAccountID COMMENT 'Specific merchant account within a payment provider that processed this deposit. More granular than ProtocolMIDSettingsID. (Tier 1 - upstream wiki, etoro.History.Deposit_DataFactory)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
