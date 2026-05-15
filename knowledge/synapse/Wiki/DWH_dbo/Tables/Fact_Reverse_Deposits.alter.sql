-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Reverse_Deposits
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CID COMMENT 'Customer ID. CLUSTERED INDEX key. (Tier 2 - SP_Fact_Reverse_Deposits_DL_To_Synapse passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositID COMMENT 'Billing deposit identifier. Links this reversal to the original deposit in Fact_Deposit_Fees and Fact_BillingDeposit. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN WhiteLabelID COMMENT 'White-label brand integer identifier. Numeric FK to white-label lookup. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN OldPaymentID COMMENT 'Legacy payment system identifier. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN FundingID COMMENT 'Funding method integer identifier (19 types). (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositStatus COMMENT 'Status at last load. Values (live): Refund(63.7%), Chargeback(26.4%), ChargebackReversal(5.4%), Approved(3.2%), ReversedDeposit(1.2%), RefundReversal(0.1%). (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN PreviousDepositStatus COMMENT 'Deposit status before the final DepositStatus transition. Captures the pre-reversal state. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositStatusModificationTime COMMENT 'Timestamp of final status change. Source for ModificationDateID derivation. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ModificationDateID COMMENT 'ETL date key derived from DepositStatusModificationTime: convert(int, convert(varchar, dateadd(...), 112)). Format: YYYYMMDD. (Tier 2 - SP_Fact_Reverse_Deposits_DL_To_Synapse computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositTime COMMENT 'Original deposit submission timestamp. Range: 2020-05-11 to 2024-06-20. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (getdate()). Range: 2023-12-25 to 2024-06-29. (Tier 2 - SP computed: getdate())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackDate COMMENT 'Date the rollback was executed. Range: 2021-05-05 to 2024-06-28. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackAmount COMMENT 'Rollback amount in original deposit currency. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackUSDAmount COMMENT 'Rollback amount converted to USD at rollback-time exchange rate. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackReason COMMENT 'Business reason for rollback. 30 distinct values; Fraud=86%. Full list: Fraud, Successful Dispute, Wrong Deposit ID/Amount, Technical/Service/Complaint, Fake Docs, Rollback Adjustment, Attack, Processor Reimbursement, and 22 others. (Tier 3 - live data distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackCanceled COMMENT 'Non-NULL if rollback was subsequently cancelled (deposit reinstated). Ops procedures register Chargeback Reversal / Refund Reversal on top of an existing charged-back line in Back Office. (Tier 4 - Confluence, WorldPay Disputes)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ReferenceNumber COMMENT 'External reference for chargeback/refund reconciliation - e.g. reference from processor chargeback reports (PP CHB column A) when registering rollback in BO. (Tier 4 - Confluence, PayPal Chargebacks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositAmount COMMENT 'Original deposit amount in customer currency. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositUSDAmount COMMENT 'Original deposit amount in USD at deposit-time rate. Enables USD-normalized analysis. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Currency COMMENT 'Customer''s deposit currency. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ExchangeRate COMMENT 'Exchange rate applied at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ConversionFee COMMENT 'Fee for currency conversion on deposit/withdrawal flows; internal docs describe conversion fees in PIPs or percentages depending on method and region. (Tier 4 - Confluence, Conversion Fee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN PIPsInUSD COMMENT 'USD value of PIPs fee associated with this deposit. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Balance COMMENT 'Customer account balance at rollback time. Point-in-time snapshot from BackOffice risk report. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalDeposits COMMENT 'Customer lifetime total deposits at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalProcessedCashouts COMMENT 'Customer lifetime total processed cashouts at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalCommissions COMMENT 'Customer total commissions earned/paid at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalPnL COMMENT 'Customer total profit and loss at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalCompensations COMMENT 'Customer total compensation credits at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalCredits COMMENT 'Customer total credit balance at rollback time. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN FundingMethod COMMENT 'Payment method name (CreditCard, PayPal, etc.). (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Brand COMMENT 'Card network brand (Visa, Master Card, etc.). (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Depot COMMENT 'Payment gateway/processor name. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN MID COMMENT 'Merchant ID for payment processor settlement. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN MIDName COMMENT 'Human-readable MID description. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN PaymentDetails COMMENT 'Method-specific payment details. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ThreedsParameters COMMENT '3D Secure authentication parameters. (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ThreedsResponse COMMENT '3D Secure authentication result. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction for this customer. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN WhiteLabel COMMENT 'White-label brand name. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CustomerStatus COMMENT 'Customer account status at rollback time. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RiskStatus COMMENT 'Risk management status. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN VerificationLevel COMMENT 'Customer KYC/verification level at rollback time. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CustomerLevel COMMENT 'Customer tier (Silver, Gold, Platinum, etc.). [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CountryByRegIP COMMENT 'Country from registration IP address. (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN AccountManager COMMENT 'Assigned account manager at rollback time. (Tier 4 - inferred)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN WhiteLabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN OldPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN PreviousDepositStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositStatusModificationTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RollbackCanceled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ReferenceNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN DepositUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ConversionFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN PIPsInUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Balance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalDeposits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalProcessedCashouts SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalCommissions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalCompensations SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN TotalCredits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN FundingMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Brand SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN MID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN PaymentDetails SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ThreedsParameters SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN ThreedsResponse SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN WhiteLabel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CustomerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN RiskStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN VerificationLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CustomerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN CountryByRegIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits ALTER COLUMN AccountManager SET TAGS ('pii' = 'none');

