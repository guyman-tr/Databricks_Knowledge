-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Withdraw_Fees
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CID COMMENT 'Customer ID. CLUSTERED INDEX key. (Tier 2 - SP_Fact_Withdraw_Fees_DL_To_Synapse passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WithdrawID COMMENT 'Withdrawal event identifier. Primary key for this cashout. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WithdrawProcessingID COMMENT 'Withdrawal processing order ID. Used in payment processing workflow. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN DepositID COMMENT 'Original deposit identifier linked to this withdrawal. Required for card-match compliance - funds must return to originating payment card. NULL for non-card-match withdrawals. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN FundingID COMMENT 'Funding method integer identifier. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WithdrawStatus COMMENT 'Final withdrawal processing status. Values (live): Processed(99.9%), Partially Processed, Partialy Reversed (typo - missing ''l'' in production), Rejected, Reversed, InProcess. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PaymentOrderStatus COMMENT 'Payment order status - distinct from overall withdrawal status; CS docs describe withdrawal/cashout status by method (MOP) and stage in Cashout History. (Tier 4 - Confluence, Withdrawal in BO and Statuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN StatusModificationTime COMMENT 'Timestamp of last status change. Source for ModificationDateID. ETL WHERE filter key. (Tier 2 - SP passthrough + WHERE clause)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ModificationDateID COMMENT 'ETL date key from StatusModificationTime: YYYYMMDD integer. Efficient date-range filter. (Tier 2 - SP computed: convert(int,...StatusModificationTime...112))';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ProcessTime COMMENT 'Withdrawal processing completion time. Range: 2021-12-01 to 2024-06-30. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN RequestTime COMMENT 'Customer cashout request submission time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ProcessorValueDate COMMENT 'Payment processor value date for settlement (when the provider books the transaction); may differ from `ProcessTime`. (Tier 4 - Confluence, Withdrawal in BO and Statuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (getdate()). Range: 2024-01-08 to 2024-07-01. (Tier 2 - SP computed: getdate())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN NetCashoutDollarAmount COMMENT 'Net withdrawal amount in USD after fee deduction. Primary monetary measure. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN NetAmountinOrigCurrency COMMENT 'Net withdrawal in customer''s original currency. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Currency COMMENT 'Customer withdrawal currency code. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN FeeInPIPs COMMENT 'Withdrawal fee in price interest points. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PIPsinUSD COMMENT 'USD value of withdrawal fee. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ExchangeRate COMMENT 'Exchange rate applied for currency conversion. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PreparationType COMMENT 'How the withdrawal was prepared in the cashout pipeline (e.g. manual vs automated preparation in CO workflows). (Tier 4 - Confluence, Cashout (CO) Approval Checks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ExecutionType COMMENT 'How execution was performed after preparation (internal routing to provider/billing). (Tier 4 - Confluence, Cashout (CO) Processing)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Executedby COMMENT 'Actor or system step associated with execution (aligns with BO cashout/withdrawal processing terminology). (Tier 4 - Confluence, Cashout (CO) Processing)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CashoutType COMMENT 'Classification of the cashout path (e.g. standard withdrawal vs internal transfer flows in related product docs). (Tier 4 - Confluence, Withdrawal issues)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN BackOfficeWithdrawReason COMMENT 'BackOffice reason for the withdrawal request (customer-initiated, compliance, manual payout, etc.). (Tier 4 - Confluence, Withdrawal issues)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN VerificationCode COMMENT 'Processor or gateway verification code on the withdrawal. (Tier 4 - Confluence, Lost Cashout (CO) - Credit/Debit Card (CC))';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN VendorCode COMMENT 'Payment vendor-specific code from the provider. (Tier 4 - Confluence, Withdrawal in BO and Statuses)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN FundingMethod COMMENT 'Withdrawal channel. Values (live): CreditCard(31.8%), WireTransfer(23.1%), eToroMoney(21.1%), PayPal(10.9%), eToroCryptoWallet(8.1%), OnlineBanking, iDEAL, PWMB, ACH, Trustly, MoneyBookers, Przelewy24, EtoroOptions, Neteller, Payoneer, UnionPay. (Tier 3 - live data distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Brand COMMENT 'Card network brand (Visa, Master Card, etc.) for card withdrawals. NULL for non-card methods. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Depot COMMENT 'Payment gateway/processor. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN MID COMMENT 'Merchant ID for processor settlement. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN MIDName COMMENT 'Human-readable MID description. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PaymentDetails COMMENT 'Method-specific payment details (bank account info for wire, etc.). (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CustomerStatus COMMENT 'Customer account status at withdrawal time (e.g. limited/blocked accounts affect manual cashout handling). (Tier 4 - Confluence, Cashout (CO) Approval Checks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CustomerLevel COMMENT 'Customer tier/club level at withdrawal time; fee exemptions (e.g. Platinum+ withdrawal fee) are documented in fee-group logic. (Tier 4 - Confluence, Fee Group Logic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction for this customer. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WhiteLabel COMMENT 'White-label brand name. (Tier 2 - SP passthrough)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WithdrawProcessingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WithdrawStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PaymentOrderStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN StatusModificationTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ProcessTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN RequestTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ProcessorValueDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN NetCashoutDollarAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN NetAmountinOrigCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN FeeInPIPs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PIPsinUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PreparationType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN ExecutionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Executedby SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CashoutType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN BackOfficeWithdrawReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN VerificationCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN VendorCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN FundingMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Brand SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN MID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN PaymentDetails SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CustomerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN CustomerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees ALTER COLUMN WhiteLabel SET TAGS ('pii' = 'none');

