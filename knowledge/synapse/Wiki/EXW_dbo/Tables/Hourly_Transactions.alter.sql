-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Hourly_Transactions
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Hourly_Transactions is a near-real-time transaction monitoring table for the eToro Wallet, covering all completed wallet transactions from the last 5 days. It is rebuilt from scratch on every hourly SP_EXW_Hourly run. Each row corresponds to one transaction from the WalletDB transaction view, enriched with a human-readable Activity label and USD valuation at the per-hour price. The table is designed for Tableau KPI operations dashboards - enabling the team to monitor real-time flows of redemptions, money-out, AML cashbacks, funding, and conversions. It does not replace the EXW_FactTransactions table (which is the permanent historical record) but provides a lower-latency snapshot with hourly price granularity.

