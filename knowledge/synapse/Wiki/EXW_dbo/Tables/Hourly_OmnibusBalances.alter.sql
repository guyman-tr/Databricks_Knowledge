-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Hourly_OmnibusBalances
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Hourly_OmnibusBalances tracks the balance position of the 36 omnibus/system wallets managed by eToro Wallet Exchange, broken down by cryptocurrency and by balance-as-of date. It is one of six tables rebuilt each hour by SP_EXW_Hourly and is designed to feed operational KPI dashboards (e.g., Tableau) with near-real-time visibility into how much crypto is held in eToro''s own inventory wallets — separate from customer wallets. **Scope**: Gcid ≤ 0 wallets only. These are pre-funded pool wallets, omnibus wallets for specific transaction types (Redeem, Payment, Funding, Conversion, C2F, StakingRefund), and system wallets not belonging to individual customers. **Row structure**: One row per WalletID × CryptoID per BalanceDate. Unlike Hourly_CustomerBalances, this table retains the per-wallet granularity (not aggregated to crypto-level totals). ReportDate is always the SP run date; BalanceDate 

