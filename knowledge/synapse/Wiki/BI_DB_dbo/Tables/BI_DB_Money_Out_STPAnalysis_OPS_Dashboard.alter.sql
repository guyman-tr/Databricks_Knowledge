-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard > 4.17M-row operations dashboard table tracking completed withdrawal (cashout) straight-through-processing (STP) metrics, covering Oct 2025 to present (7-month rolling window). Each row represents one processed withdrawal payment leg with approval workflow flags (OPS, Risk, Trading, AML, Administrators), execution method, preparation mode, and funding type. Refreshed daily by SP_H_Money_Out_STPAnalysis_OPS_Dashboard via DELETE+INSERT on the daily window. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | etoro.Billing.Withdraw + Billing.vWithdrawToFunding + BackOffice.WithdrawApproval via SP_H_Money_Out_STPAnalysis_OPS_Dashboard | | **Refresh** | Daily (DELETE matching rows + INSERT + purge >7 months) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN WithdrawID COMMENT 'References the parent withdrawal request in Billing.Withdraw. No explicit FK constraint. Multiple rows share a WithdrawID (one per approval group). Part of DELETE+INSERT key alongside CID and WithdrawPaymentID. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN CID COMMENT 'Customer ID. FK to Customer.CustomerStatic. Identifies the customer who submitted the withdrawal request. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN RequestDate COMMENT 'Timestamp when the customer submitted the withdrawal request. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the most recent status change on the payment leg. Used for daily window extraction and 7-month purge boundary. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN ExecutionApproval COMMENT 'How the payment execution was initiated. Resolved from Dictionary.ExecuteEntryMethod.DisplayName via WithdrawToFunding.RequestExecuteEntryMethodId. Auto Execute, Manually Updated, Manual Execute, or empty. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN AutoApproval COMMENT 'Whether the withdrawal was auto-approved or required manual approval. CASE on BackOffice.WithdrawApproval.Comment: ''Auto Approval'' or ''Cleared - Auto Approval'' if Comment matches those strings, else ''Manual''. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN Preparation COMMENT 'Payment leg preparation mode. Resolved from Dim_CashoutMode.CashoutModeName via WithdrawToFunding.CashoutModeID. Auto Create, Mass Auto Create, Manual, or empty. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN WithdrawPaymentID COMMENT 'Payment leg ID from Billing.WithdrawToFunding (Billing.WithdrawToFunding.ID). Identifies the specific payment execution leg for this withdrawal. Part of DELETE+INSERT key. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN FundingType_Sent COMMENT 'Payment method used for the payout. Resolved via JOIN chain: WithdrawToFunding.FundingID -> Billing.Funding_Datafactory.FundingTypeID -> Dim_FundingType.Name. 13 distinct values: eToroMoney, WireTransfer, CreditCard, PayPal, eToroCryptoWallet, EtoroOptions, iDEAL, PWMB, MoneyBookers, Przelewy24, Trustly, Neteller, OnlineBanking. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN OPSApproved COMMENT '1 if the OPS team (UserGroupID=2) manually approved this withdrawal (Approved=1 and Comment not in auto-approval strings), 0 otherwise. Derived from BackOffice.WithdrawApproval via MAX(CASE). (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN RiskApproved COMMENT '1 if the Risk team (UserGroupID=3) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN TradingApproved COMMENT '1 if the Trading team (UserGroupID=6) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN AMLApproved COMMENT '1 if the AML team (UserGroupID=36) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN AmdinistratorsApproved COMMENT '1 if the Administrators group (UserGroupID=1) manually approved this withdrawal, 0 otherwise. Same derivation as OPSApproved. Column name is a typo - should be "AdministratorsApproved". (Tier 2 - SP_H_Money_Out_STPAnalysis_OPS_Dashboard)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN RequestDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN ExecutionApproval SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN AutoApproval SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN Preparation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN FundingType_Sent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN OPSApproved SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN RiskApproved SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN TradingApproved SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN AMLApproved SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_out_stpanalysis_ops_dashboard ALTER COLUMN AmdinistratorsApproved SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:06:07 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 32/32 succeeded
-- ====================
