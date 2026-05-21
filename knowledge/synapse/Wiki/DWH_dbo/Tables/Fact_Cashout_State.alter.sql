-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Cashout_State
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CID COMMENT 'Customer ID. Identifies the eToro customer who submitted the cashout request. Clustered index key (co-locates customer rows within distributions). References DWH_dbo.Dim_Customer. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN TransactionType COMMENT 'Classification of the withdrawal transaction method (e.g., credit card, wire transfer, e-wallet). String label providing context for the cashout routing path. (Tier 3 - column naming)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN PreviousStatus COMMENT 'String label of the cashout status immediately before the current state. Enables state transition analysis without joining to a history table. (Tier 3 - column naming)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN WithdrawID COMMENT 'Identifier for the associated withdrawal request in the cashout pipeline. May reference Billing.Cashout or Billing.Withdraw tables in production. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN WPID COMMENT 'Withdrawal payment processing ID. Identifies the specific payment processing record associated with this cashout. (Tier 3 - column naming)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN DepositID COMMENT 'Original deposit ID linked to this cashout (for refund/chargeback scenarios). References Fact_BillingDeposit.DepositID when the cashout is associated with a deposit reversal. (Tier 3 - column naming)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN FundingID COMMENT 'Payment instrument (credit card, bank account, e-wallet) used for the cashout payout. References Billing.Funding. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN DepotID COMMENT 'Identifies the Billing.Depot (acquirer/gateway configuration) processing this cashout. Determines which payment processor handles the transaction. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CashoutStatusID COMMENT 'Numeric status code for the current cashout state. References DWH_dbo.Dim_CashoutStatus (if documented). Companion to the string `CashoutStatus` column. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CashoutStatus COMMENT 'String label of the current cashout status. Stored as a denormalized string alongside CashoutStatusID to avoid requiring a Dim join for simple status filtering. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN Amount COMMENT 'Cashout amount in the customer''s requested currency (CurrencyID). 4 decimal place precision. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CurrencyID COMMENT 'Currency of the cashout amount. References DWH_dbo.Dim_Currency. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN AmountInUSD COMMENT 'Cashout amount converted to USD (Amount × ExchangeRate). Pre-computed for reporting convenience. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup. Used to compute the exchange fee spread: ExchangeRate - BaseExchangeRate = fee per unit. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExchangeFee COMMENT 'Exchange fee in a provider-specific integer encoding (typically basis points). (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExchangeRate COMMENT 'Applied exchange rate from cashout currency to USD, including fee markup. Higher precision (23,8) than BaseExchangeRate (16,8). (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExTransactionID COMMENT 'External (payment provider) transaction ID for this cashout. Used for provider-side reconciliation. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the most recent modification to this cashout record. Source value from production. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN RequestDate COMMENT 'UTC timestamp when the cashout was requested by the customer. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Merchant ID (MID) configuration profile used for processing. References Billing.ProtocolMIDSettings. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN MerchantAccountID COMMENT 'Merchant account legal entity used for regulatory routing. References Billing.MerchantAccountRouting. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN PIPsInUSD COMMENT 'Exchange fee value in USD (the "PIPs" - percentage in points - converted to USD absolute amount). Used for fee revenue reporting. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExchaFeeInPercentage COMMENT 'Exchange fee as a percentage of the cashout amount (0.00-100.00). Normalized fee rate for comparison across currencies. Note: column name appears to have a typo ("Excha" vs "Exchange"). (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN MID COMMENT 'Merchant ID string - the actual MID identifier used with the payment processor. String representation of the MID for reporting/display. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN MIDName COMMENT 'Human-readable label for the Merchant ID configuration. Display name for the MID used in reporting. (Tier 3 - column naming)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ModificationDateID COMMENT 'Integer date key in YYYYMMDD format derived from ModificationDate by truncating to midnight and converting via style 112: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, ModificationDate), 0), 112))`. Used as the ETL key for the daily DELETE+INSERT pattern in SP_Fact_Cashout_State.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() at SP execution time. Not from the production source. Use for ETL freshness monitoring. (Tier 2 - SP_Fact_Cashout_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CreditID COMMENT 'Credit account identifier associated with this cashout. Added 2025-08-13 by guym to support credit account tracking. NULL for cashouts not linked to a credit account. (Tier 2 - SP_Fact_Cashout_State)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN TransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN PreviousStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN WPID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN DepotID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CashoutStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CashoutStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN AmountInUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN RequestDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ProtocolMIDSettingsID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN MerchantAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN PIPsInUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ExchaFeeInPercentage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN MID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state ALTER COLUMN CreditID SET TAGS ('pii' = 'none');

