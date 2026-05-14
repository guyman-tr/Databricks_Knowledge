-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals > Reversal companion to BI_DB_DepositWithdrawFee - ~19.8K rows capturing deposit chargebacks, refunds, reversed deposits, cashout rollbacks, and their cancelled variants from 2023-01-03 to present. Built daily by `SP_DepositWithdrawFee` from `Fact_Deposit_State` (WHERE TransactionType != ''Deposit'') UNION ALL `Fact_Cashout_State` (WHERE TransactionType != ''Withdraw''), enriched with customer snapshot attributes, payment metadata, and post-insert amount sign corrections. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | SP_DepositWithdrawFee from Fact_Deposit_State + Fact_Cashout_State (reversal subsets) | | **Key Identifier** | No PK; grain = DepositWithdrawID + TransactionID per DateID | | **Distribution** | HASH(CID) | | **Index** | CLUSTERED COLUMNSTORE INDEX | | **Colum'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN DateID COMMENT 'Business date as YYYYMMDD for the load (@StartDateID parameter). Used as the DELETE/INSERT partition key. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CID COMMENT 'Customer ID (RealCID) from the deposit or cashout state record. HASH distribution key. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN DepositWithdrawID COMMENT 'DepositID (deposit reversals) or WithdrawID (withdraw rollbacks) - the stable identifier for the original cash event being reversed. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Occurred COMMENT 'Event timestamp (ModificationDate from Fact_Deposit_State or Fact_Cashout_State). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CreditTypeID COMMENT 'Intentionally NULL in the current procedure. Legacy column retired per SR-313302 (2025-05-07). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN TransactionID COMMENT 'Synthetic identifier: CAST(DepositID AS VARCHAR(50)) + ''D'' for deposit reversals, CAST(WPID AS VARCHAR(50)) + ''W'' for withdraw rollbacks. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Date COMMENT 'Calendar date of ModificationDate. CAST(ModificationDate AS DATE). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Customer COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. CAST to VARCHAR(50) from Dim_Customer.ExternalID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN TransactionType COMMENT 'Reversal type from the state fact. Values: Refund, Chargeback, ChargebackReversal, ReversedDeposit, CashoutRollback, CancelledRefund, CancelledChargeback, CancelledCashoutRollback, CancelledChargebackReversal, CancelledReversedDeposit, CancelledRefundReversal. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PaymentMethod COMMENT 'Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Passthrough from Dim_FundingType. (Tier 1 - Dictionary.FundingType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Amount COMMENT 'Transaction amount in original currency. ABS() at insert, then signed via #amountDirections and edge-case corrections. Negative for refunds/chargebacks, positive for chargeback reversals/cashout rollbacks. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Currency COMMENT 'Ticker symbol (e.g., USD, EUR, GBP). Use this for human-readable currency identification. Passthrough from Dim_Currency. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExchangeRate COMMENT 'FX rate from the state fact row. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN AmountUSD COMMENT 'USD equivalent amount. ABS(AmountInUSD) at insert, then signed via #amountDirections and edge-case corrections. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN RegulationID COMMENT 'Regulatory entity governing this customer at the time of the reversal. Point-in-time snapshot from Fact_SnapshotCustomer via Dim_Range date bridge. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN LabelID COMMENT 'White-label brand ID at the time of the reversal. From Fact_SnapshotCustomer (withdraw path) or Dim_Customer (deposit path). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PlayerLevelID COMMENT 'eToro Club loyalty tier at the time of the reversal. Point-in-time snapshot from Fact_SnapshotCustomer. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Passthrough from Dim_Regulation. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Label COMMENT 'Brand name displayed in BackOffice interfaces, reports, and internal systems. Passthrough from Dim_Label. (Tier 1 - Dictionary.Label)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN IsValidCustomer COMMENT '1 when not Internal (PlayerLevelID != 4), not label 30/26, and not CountryID=250. Point-in-time snapshot from Fact_SnapshotCustomer. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN UpdateDate COMMENT 'Row load timestamp (GETDATE() at insert). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup from the state fact. Spread = ExchangeRate minus BaseExchangeRate. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExchangeFee COMMENT 'Exchange fee from the state fact in provider-specific encoding. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExternalTransactionID COMMENT 'Payment provider transaction ID (ExTransactionID from state fact). Used for provider-side reconciliation. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Depot COMMENT 'Human-readable depot name (e.g., ''MoneyBookers USD'', ''Neteller'', ''Wire''). Used in admin dashboards, routing logs, and discrepancy reports. Passthrough from Dim_BillingDepot. (Tier 1 - Billing.Depot)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN MIDValue COMMENT 'Merchant ID value from the state fact (MID column). Identifies the acquiring bank''s merchant account. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Club COMMENT 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Passthrough from Dim_PlayerLevel. (Tier 1 - Dictionary.PlayerLevel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PlayerStatus COMMENT 'Human-readable restriction state label (e.g., Normal, Blocked, Trade & MIMO Blocked). Passthrough from Dim_PlayerStatus. (Tier 1 - Dictionary.PlayerStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PIPsCalculation COMMENT 'ABS(ISNULL(PIPsInUSD,0)) at insert; signed via #amountDirections (Withdraw type keeps original sign); further corrected via Fact_CustomerAction JOIN for CashoutRollback/CancelledCashoutRollback/CancelledChargebackReversal edge cases. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN RegCountry COMMENT 'Full country name in English for the customer''s registration country. Passthrough from Dim_Country via snapshot CountryID (withdraw) or Dim_Customer.CountryID (deposit). (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN RegCountryByIP COMMENT 'Full country name in English for the customer''s IP-detected country. Passthrough from Dim_Country via Dim_Customer.CountryIDByIP. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CardType COMMENT 'Card network brand. Deposit path: raw CardType string from Fact_Deposit_State. Withdraw path: CarTypeName from Dim_CardType via Fact_BillingWithdraw.CardTypeIDAsInteger. Values: Visa, Master Card, Maestro, N/A. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CardCategory COMMENT 'Card product category (e.g., ''Visa Classic'', ''Gold MasterCardr Card'', ''Debit MasterCardr (Enhanced)''). From Fact_Deposit_State.CardCategory (deposit) or Fact_BillingWithdraw.CardCategory (withdraw). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN BinCountry COMMENT 'Full country name in English for the country associated with the card BIN code. Passthrough from Dim_Country via BinCountryIDAsInteger from Fact_BillingDeposit (deposit) or Fact_BillingWithdraw (withdraw). (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN MOPCountry COMMENT 'Not populated (NULL literal) in current SP build. Reserved column for method-of-payment country. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN IsGermanBaFin COMMENT 'Not populated (NULL literal) in current SP build. Reserved column for German BaFin regulatory flag. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN IsIBANTrade COMMENT '1 when the billing fact FlowID indicates IBAN processing: FlowID = 1 (deposit path) or FlowID = 2 (withdraw path); else 0. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN MIDName COMMENT 'Human-readable merchant ID display name from the state fact (e.g., ''eToroEU'', ''eToroUS'', ''EMUK'', ''ACH(Silvergate)''). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN GuruStatus COMMENT 'Human-readable PI tier name: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Passthrough from Dim_GuruStatus. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PreviousTransactionStatus COMMENT 'Prior status on the state fact before the current modification (PreviousStatus column). Empty string for initial creation events. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN TransactionStatus COMMENT 'Current status from the state fact (DepositStatus for deposit path, CashoutStatus for withdraw path). Values: Refund, Chargeback, ChargebackReversal, Approved, ReversedDeposit, Processed, Partialy Reversed, Reversed, RefundReversal. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN DepositID COMMENT 'Populated on deposit reversal rows; NULL on withdraw rollback rows. References Fact_BillingDeposit.DepositID. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN WithdrawPaymentID COMMENT 'Populated on withdraw rollback rows; NULL on deposit reversal rows. References Fact_BillingWithdraw.WithdrawPaymentID. (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CreditID COMMENT 'Credit record ID from the state fact. Used for Fact_CustomerAction JOIN in post-insert PIPsCalculation sign corrections. Added SR-328549 (2025-08-10). (Tier 2 - SP_DepositWithdrawFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExchangeFeePercentage COMMENT 'Exchange fee as a percentage. Sourced from Fact_Deposit_State.FeeInPercentage (deposit path) or Fact_Cashout_State.ExchaFeeInPercentage (withdraw path). Added SR-359957 (2026-03-04). (Tier 2 - SP_DepositWithdrawFee)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN DepositWithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CreditTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Customer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN TransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PaymentMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExternalTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN MIDValue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PIPsCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN RegCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN RegCountryByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CardType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN BinCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN MOPCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN IsIBANTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN GuruStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN PreviousTransactionStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN TransactionStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN ExchangeFeePercentage SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:49:01 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 92/92 succeeded
-- ====================
