-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Deposit_State
-- Generated: 2026-05-14 15:07:44 UTC | phase1 stub overwrite
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CreditID COMMENT 'Unique identifier for the deposit/credit record in the billing system. Passed through from DWH_staging.etoro_Billing_BI_Deposit_State_Report. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN FromDate COMMENT 'Start of the day window for this deposit state record. Set to midnight of ModificationDate (e.g., 2026-03-10 00:00:00). Used as a partitioning boundary by the ETL. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN EndDate COMMENT 'End of the day window for this deposit state record. Set to midnight of the next day (e.g., 2026-03-11 00:00:00). Paired with FromDate to define the date boundary. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CID COMMENT 'Customer ID. Unique identifier for the eToro customer who made the deposit. CLUSTERED INDEX key -- use in WHERE/JOIN for efficient customer-level queries. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CurrencyID COMMENT 'Deposit currency identifier. Foreign key to DWH_dbo.Dim_Currency. 26 distinct currencies in production. Identifies the currency of the Amount field. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN DepositID COMMENT 'Unique deposit transaction identifier. 19.37M distinct DepositIDs (near 1:1 with rows). Primary business key for tracing individual deposits. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN DepotID COMMENT 'Billing depot (payment gateway) identifier. Foreign key to DWH_dbo.Dim_BillingDepot. 37 distinct depots in production (eToroMoneyEU, NuveiEMUK, eToroMoneyAU etc). (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN FundingID COMMENT 'Funding record identifier linking this deposit to the customer''s funding account/method. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN PaymentStatusID COMMENT 'Payment processing status code. Foreign key to DWH_dbo.Dim_PaymentStatus. 7 values in production: 2=Approved (99.8%), 12=Refund, 11=Chargeback, 37=ChargebackReversal, 38=RefundReversal, 39=[UNVERIFIED], 3=Decline. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CardType COMMENT 'Card type label from payment provider (e.g., "Master Card", "Visa", "N/A" for non-card payments). Not normalized -- stored as text. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CardCategory COMMENT 'Card product category from payment provider (e.g., "Gold MasterCard Card", "N/A" for non-card). More granular than CardType. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN MID COMMENT 'Merchant Identifier code. Identifies the acquiring bank''s merchant account used to process the deposit (e.g., "eToroMoneyEU", "NuveiEMUK"). (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN MIDName COMMENT 'Human-readable name for the MID (e.g., "eToroEU", "eToroUK", "EMUK"). Corresponds to the eToro entity or gateway brand. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN BaseExchangeRate COMMENT 'Base (pre-fee) exchange rate between deposit currency and USD. Used to calculate the USD equivalent before exchange fees. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ExchangeFee COMMENT 'Exchange fee indicator; CS deposit conversion guidance references **fee in PIPs** and exchange fee in USD alongside base vs effective rate - consistent with fee encoded as points/tier (observed 0, 52, 70, 101). (Tier 4 - Confluence, Deposit conversion fee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ExchangeRate COMMENT 'Effective exchange rate applied to the deposit (post-fee). AmountInUSD = Amount * ExchangeRate. Compare to BaseExchangeRate to derive the fee impact. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ModificationDate COMMENT 'Timestamp when this deposit record was last modified in the billing system. Primary time axis for this table. Used in the daily ETL window filter. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN AmountInUSD COMMENT 'Deposit amount converted to USD. Computed as Amount * ExchangeRate. Standard financial reporting currency. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN Amount COMMENT 'Deposit amount in the original deposit currency (CurrencyID). Customer-facing transaction amount. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Protocol-level MID settings identifier. Foreign key to DWH_dbo.Dim_BillingProtocolMIDSettingsID. 0 for most rows (no special protocol settings). (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN MerchantAccountID COMMENT 'Merchant account identifier at the payment processor level. More granular than MID -- identifies the specific merchant account within the depot. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ExTransactionID COMMENT 'External transaction identifier from the payment processor or gateway. Used for reconciliation with the acquiring bank or payment provider. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN DepositStatus COMMENT 'Current deposit status label. 7 values: Deposit (99.9%), Refund, Chargeback, ChargebackReversal, Approved, ReversedDeposit, RefundReversal. Reflects the state at ModificationDate. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN PreviousStatus COMMENT 'Deposit status before the current modification. Empty string for initial creation events. Used to track state transitions (e.g., "Deposit" -> "Chargeback"). (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN TransactionType COMMENT 'Transaction event type classification. 10 values: Deposit, Refund, Chargeback, ChargebackReversal, CancelledRefund, ReversedDeposit, CancelledChargeback, CancelledReversedDeposit, CancelledChargebackReversal, CancelledRefundReversal. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN PIPsInUSD COMMENT '**PIP in USD** - finance definition: conversion-fee revenue in USD (original amount × spread between base and effective rate, or amount × conversion fee / 10000 per FC playbook). Aligns with small USD amounts on deposit lines. Observed 0.00 - 5.30. (Tier 4 - Confluence, Conversion fee Revenue Calculation (PIP in USD))';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN FeeInPercentage COMMENT 'Fee applied to the deposit expressed as a percentage (e.g., 0.4498343 = 0.45% fee). (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ModificationDateID COMMENT 'ModificationDate as YYYYMMDD integer (e.g., 20260310). DWH-derived: computed in SP as CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY,0,ModificationDate), 0), 112)). Used for date-range deletes and partitioning. (Tier 2 - SP_Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN UpdateDate COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution time. Tracks when this row was last written to Synapse. (Tier 2 - SP_Fact_Deposit_State)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN FromDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN EndDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN DepotID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CardType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN MID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN AmountInUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ProtocolMIDSettingsID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN MerchantAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ExTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN DepositStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN PreviousStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN TransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN PIPsInUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN FeeInPercentage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

