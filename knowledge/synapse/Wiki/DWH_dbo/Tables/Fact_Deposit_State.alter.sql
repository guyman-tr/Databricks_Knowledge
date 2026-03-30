-- =============================================================================
-- ALTER Script: DWH_dbo.Fact_Deposit_State
-- UC Target:    _Not found in generic pipeline mapping - custom Billing pipeline_
-- Resolution:   Wiki property table
-- Generated:    2026-03-22
-- Source Wiki:   knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Deposit_State.md
-- Quality:      8.2/10
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. TABLE COMMENT
-- ---------------------------------------------------------------------------
ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
SET TBLPROPERTIES (
    'comment' = 'Fact_Deposit_State captures daily snapshots of deposit transaction state changes on the eToro platform. Each row records a deposit (or chargeback/refund event) as it was modified on a given date. The table acts as a daily changelog for the billing deposit pipeline: it does not store the full deposit history from inception, but captures the state as-of each modification date, allowing analysts to see how deposits progressed through their lifecycle (e.g., from Approved to Chargeback) day by day. Data originates from `DWH_staging.etoro_Billing_BI_Deposit_State_Report`, which is a Billing BI report staging view aggregating deposit state data from the eToro billing system. This is a custom Billing pipeline, not part of the standard Generic Pipeline mapping. The table covers data from 2023-01-01 onwards (19.4M rows as of March 2026). Loaded daily by `SP_Fact_Deposit_State(@dt)`. The SP deletes all rows where `ModificationDateID` falls on `@dt`, then reloads from staging for the same date window. `ModificationDat...'
);

-- ---------------------------------------------------------------------------
-- 2. TABLE TAGS
-- ---------------------------------------------------------------------------
ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
SET TAGS (
    'domain' = 'DWH',
    'object_type' = 'Table',
    'synapse_schema' = 'DWH_dbo',
    'synapse_object_name' = 'Fact_Deposit_State',
    'refresh_frequency' = 'Daily incremental (delete-for-date + insert pattern via @dt parameter)',
    'source_system' = 'DWH_staging.etoro_Billing_BI_Deposit_State_Report (Billing BI state report)',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX(CID ASC)',
    'uc_format' = '_Pending - resolved during write-objects_',
    'pipeline' = 'Generic Pipeline (daily export)',
    'semantic_grade' = '8.2',
    'semantic_wiki' = 'DWH_dbo/Tables/Fact_Deposit_State.md'
);

-- ---------------------------------------------------------------------------
-- 3. COLUMN COMMENTS
-- ---------------------------------------------------------------------------

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN CreditID COMMENT 'Unique identifier for the deposit/credit record in the billing system. Passed through from DWH_staging.etoro_Billing_BI_Deposit_State_Report. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN FromDate COMMENT 'Start of the day window for this deposit state record. Set to midnight of ModificationDate (e.g., 2026-03-10 00:00:00). Used as a partitioning boundary by the ETL. (Tier 3 - live data sampling)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN EndDate COMMENT 'End of the day window for this deposit state record. Set to midnight of the next day (e.g., 2026-03-11 00:00:00). Paired with FromDate to define the date boundary. (Tier 3 - live data sampling)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN CID COMMENT 'Customer ID. Unique identifier for the eToro customer who made the deposit. CLUSTERED INDEX key -- use in WHERE/JOIN for efficient customer-level queries. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN CurrencyID COMMENT 'Deposit currency identifier. Foreign key to DWH_dbo.Dim_Currency. 26 distinct currencies in production. Identifies the currency of the Amount field. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN DepositID COMMENT 'Unique deposit transaction identifier. 19.37M distinct DepositIDs (near 1:1 with rows). Primary business key for tracing individual deposits. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN DepotID COMMENT 'Billing depot (payment gateway) identifier. Foreign key to DWH_dbo.Dim_BillingDepot. 37 distinct depots in production (eToroMoneyEU, NuveiEMUK, eToroMoneyAU etc). (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN FundingID COMMENT 'Funding record identifier linking this deposit to the customer''s funding account/method. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN PaymentStatusID COMMENT 'Payment processing status code. Foreign key to DWH_dbo.Dim_PaymentStatus. 7 values in production: 2=Approved (99.8%), 12=Refund, 11=Chargeback, 37=ChargebackReversal, 38=RefundReversal, 39=[UNVERIFIED], 3=Decline. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN CardType COMMENT 'Card type label from payment provider (e.g., "Master Card", "Visa", "N/A" for non-card payments). Not normalized -- stored as text. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN CardCategory COMMENT 'Card product category from payment provider (e.g., "Gold MasterCard Card", "N/A" for non-card). More granular than CardType. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN MID COMMENT 'Merchant Identifier code. Identifies the acquiring bank''s merchant account used to process the deposit (e.g., "eToroMoneyEU", "NuveiEMUK"). (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN MIDName COMMENT 'Human-readable name for the MID (e.g., "eToroEU", "eToroUK", "EMUK"). Corresponds to the eToro entity or gateway brand. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN BaseExchangeRate COMMENT 'Base (pre-fee) exchange rate between deposit currency and USD. Used to calculate the USD equivalent before exchange fees. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN ExchangeFee COMMENT 'Exchange fee indicator; CS deposit conversion guidance references **fee in PIPs** and exchange fee in USD alongside base vs effective rate - consistent with fee encoded as points/tier (observed 0, 52, 70, 101). (Tier 4 - Confluence, Deposit conversion fee)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN ExchangeRate COMMENT 'Effective exchange rate applied to the deposit (post-fee). AmountInUSD = Amount * ExchangeRate. Compare to BaseExchangeRate to derive the fee impact. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN ModificationDate COMMENT 'Timestamp when this deposit record was last modified in the billing system. Primary time axis for this table. Used in the daily ETL window filter. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN AmountInUSD COMMENT 'Deposit amount converted to USD. Computed as Amount * ExchangeRate. Standard financial reporting currency. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN Amount COMMENT 'Deposit amount in the original deposit currency (CurrencyID). Customer-facing transaction amount. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Protocol-level MID settings identifier. Foreign key to DWH_dbo.Dim_BillingProtocolMIDSettingsID. 0 for most rows (no special protocol settings). (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN MerchantAccountID COMMENT 'Merchant account identifier at the payment processor level. More granular than MID -- identifies the specific merchant account within the depot. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN ExTransactionID COMMENT 'External transaction identifier from the payment processor or gateway. Used for reconciliation with the acquiring bank or payment provider. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN DepositStatus COMMENT 'Current deposit status label. 7 values: Deposit (99.9%), Refund, Chargeback, ChargebackReversal, Approved, ReversedDeposit, RefundReversal. Reflects the state at ModificationDate. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN PreviousStatus COMMENT 'Deposit status before the current modification. Empty string for initial creation events. Used to track state transitions (e.g., "Deposit" -> "Chargeback"). (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN TransactionType COMMENT 'Transaction event type classification. 10 values: Deposit, Refund, Chargeback, ChargebackReversal, CancelledRefund, ReversedDeposit, CancelledChargeback, CancelledReversedDeposit, CancelledChargebackReversal, CancelledRefundReversal. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN PIPsInUSD COMMENT '**PIP in USD** - finance definition: conversion-fee revenue in USD (original amount × spread between base and effective rate, or amount × conversion fee / 10000 per FC playbook). Aligns with small USD amounts on deposit lines. Observed 0.00 - 5.30. (Tier 4 - Confluence, Conversion fee Revenue Calculation (PIP in USD))';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN FeeInPercentage COMMENT 'Fee applied to the deposit expressed as a percentage (e.g., 0.4498343 = 0.45% fee). (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN ModificationDateID COMMENT 'ModificationDate as YYYYMMDD integer (e.g., 20260310). DWH-derived: computed in SP as CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY,0,ModificationDate), 0), 112)). Used for date-range deletes and partitioning. (Tier 2 - SP_Fact_Deposit_State)';

ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_
ALTER COLUMN UpdateDate COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution time. Tracks when this row was last written to Synapse. (Tier 2 - SP_Fact_Deposit_State)';

-- ---------------------------------------------------------------------------
-- 4. COLUMN PII TAGS
-- ---------------------------------------------------------------------------
-- No PII-sensitive columns detected for this object.

-- =============================================================================
-- END OF ALTER SCRIPT
-- =============================================================================

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:32:40 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 0/31 succeeded
-- Error: [PARSE_SYNTAX_ERROR] Syntax error at or near 'found'. SQLSTATE: 42601 (line 1, pos 17) == SQL == ALTER TABLE _Not found in generic pipeline mapping - custom Billing pipeline_ -----------------^^^ ALTER COLUMN UpdateDate COMMENT 'DWH load timestamp. Set to GETDATE() at ETL execution time. Tracks when this row was last written to Synapse. (Tier 2 - SP_Fact_Deposit_State)';
-- ====================
