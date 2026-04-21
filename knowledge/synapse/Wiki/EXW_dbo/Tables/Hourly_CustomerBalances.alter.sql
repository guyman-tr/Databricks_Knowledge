-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Hourly_CustomerBalances
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Hourly_CustomerBalances provides a rolling 4-day (today through today-3) snapshot of total customer crypto balances aggregated by cryptocurrency. It is one of six tables rebuilt by SP_EXW_Hourly and is designed to feed lightweight operational KPI dashboards (Tableau) that require near-real-time balance views without querying the full WalletDB balance history. Each row represents the total balance held across all customer wallets for a given crypto on a specific snapshot date. Unlike EXW_FactBalance (which is per-user per-day), this table is only per-crypto per-day — it is an aggregate. The table always contains at most 4 BalanceDates: today, today-1, today-2, today-3 (relative to the latest SP run).

