-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_AML_Users_Report
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_AML_Users_Report is the daily AML (Anti-Money Laundering) compliance snapshot for all eToro Wallet users. It is the primary dataset for the AML team''s daily risk review workflow and external compliance reporting. The table answers: **which Wallet users present AML risk today?** The `IsAMLProblematic` flag (1=risky, 0=clear) consolidates seven independent risk signals - player status, country risk rank, screening status, automated risk score, risk classification, wallet allowance, and age - into a single boolean. As of April 2026: 225,962 users (32.2%) are flagged as AML-problematic. The table is primarily a wide denormalized view combining: - **Identity and status** from EXW_DimUser_Enriched and Dim_Customer - **Wallet access decision** from EXW_UserSettingsWalletAllowance - **AML provider registration** from EXW_AMLProviderID - **Country risk ranking** from Dim_Country.RiskGroupID 

