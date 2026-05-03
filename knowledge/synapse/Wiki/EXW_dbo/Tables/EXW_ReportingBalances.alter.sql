-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_ReportingBalances
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_ReportingBalances is a monthly regulatory balance reporting schema for eToro Wallet. Each row is intended to represent one customer''s crypto holdings for a given month-end date, providing regulators (CySEC, FCA, FinCEN, ASIC, etc.) with a complete view of the customer''s wallet position including: - **Opening and closing balances** for the reporting month (in crypto units and USD) - **Life-to-date (LTD) and month-to-date (MTD)** units received and sent - **Regulatory reporting balance** - the balance reported to regulators (may differ from raw blockchain balance due to known-issue wallet adjustments) - **Reconciliation diagnostics** - TrackerBalance comparison, KnownIssueWallet flags, Gap in USD estimation - **Customer context** - Country, Regulation, UserWalletAllowance, compensation status **Relationship to EXW_EOMReportingBalances**: This table is the slimmed schema successor to 

