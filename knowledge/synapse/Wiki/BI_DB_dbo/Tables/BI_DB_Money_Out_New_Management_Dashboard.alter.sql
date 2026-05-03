-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard > 4.19M-row withdrawal transaction table for the management dashboard, containing every cashout/withdrawal request with customer geography, regulation, payment status, auto-approval flag, SLA hours, preparation mode, execution type, and crypto redeem indicator - sourced from Fact_BillingWithdraw enriched with 6 dimension tables. Rolling 7-month window. Refreshed daily via SP_Money_Out_New_Management_Dashboard (Adi Meidan, 2022-07-13). SB_Daily, Priority 0. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_BillingWithdraw + 6 dimension tables via SP_Money_Out_New_Management_Dashboard | | **Refresh** | Daily DELETE+INSERT by WithdrawID+CID+FundingID, plus DELETE older than 7 months. SB_Daily, Priority 0 | | **Synapse Distribution** | ROUND_ROBIN | | **Syn'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN CID COMMENT 'Customer ID. From Fact_BillingWithdraw.CID. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Country COMMENT 'Customer''s country name at the time of withdrawal. From Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Region COMMENT 'Marketing region name. From Dim_Country.MarketingRegionManualName. E.g., UK, German, French, CEE, Latam, Spain, SEA. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction. From Dim_Regulation.Name via Dim_Country.RegulationID. E.g., FCA, CySEC, FSA Seychelles. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN WithdrawID COMMENT 'Withdrawal request identifier from Fact_BillingWithdraw. NOT unique per row - a single withdrawal can have multiple funding legs. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN FundingID COMMENT 'Funding leg identifier from Fact_BillingWithdraw. Part of the composite key WithdrawID+CID+FundingID. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN FundingTypeID COMMENT 'Funding type code from the withdraw record. From Fact_BillingWithdraw.FundingTypeID. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN WithdrawPaymentID COMMENT 'Payment processing ID. ISNULL(WithdrawPaymentID, 0) - defaults to 0 when NULL. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN CashoutStatusID_Withdraw COMMENT 'Cashout status at the withdraw level. From Fact_BillingWithdraw.CashoutStatusID_Withdraw. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN CashoutStatusID_Funding COMMENT 'Cashout status at the funding leg level. Falls back to CashoutStatusID_Withdraw when NULL. ISNULL(CashoutStatusID_Funding, CashoutStatusID_Withdraw). (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN PaymentStatus COMMENT 'Payment status label. From Dim_CashoutStatus.Name via CashoutStatusID_Funding (primary) or CashoutStatusID_Withdraw (fallback). 13 values: Processed, Canceled, Pending Review, Payment Sent, InProcess, Pending, SentToProvider, RejectedByProvider, Rejected, PendingByProvider, SentToBilling, Under Review, Failed. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN RequestDate COMMENT 'Withdrawal request date and time. From Fact_BillingWithdraw.RequestDate. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Fee COMMENT 'Withdrawal fee amount. From Fact_BillingWithdraw.Fee. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN ModificationDate COMMENT 'Last modification timestamp. From Fact_BillingWithdraw.ModificationDate. Used to filter daily processing window. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN AutoApproval COMMENT 'Whether the withdrawal was auto-approved. AutoApproval (96%) if Comment contains ''Auto Approval'', Manual (4%) otherwise. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN FundingType COMMENT 'Funding type name. From Dim_FundingType.Name via FundingTypeID_Withdraw. E.g., eToroMoney, CreditCard, WireTransfer, PayPal. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN RedeemInd COMMENT 'Crypto wallet redeem indicator. 1 if FundingTypeID_Funding=27 (eToro Crypto Wallet), 0 otherwise. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN SLAHours COMMENT 'Hours between request and last modification. DATEDIFF(HOUR, RequestDate, ModificationDate). 0 for same-hour processing or pending requests. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Preparation COMMENT 'Cashout preparation mode. From Dim_CashoutMode.CashoutModeName, ISNULL to ''Canceled''. 4 values: Auto Create, Canceled, Mass Auto Create, Manual. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN ExecutionApproval COMMENT 'Execution path classification. Manual for bank transfer methods (OnlineBanking, MoneyBookers, UnionPay, Bank Details, WireTransfer), AutoExecuted for all others. (Tier 2 - SP_Money_Out_New_Management_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 - SP_Money_Out_New_Management_Dashboard)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN CashoutStatusID_Withdraw SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN CashoutStatusID_Funding SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN PaymentStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN RequestDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN AutoApproval SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN FundingType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN RedeemInd SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN SLAHours SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN Preparation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN ExecutionApproval SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_new_management_dashboard ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:05:37 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 44/44 succeeded
-- ====================
