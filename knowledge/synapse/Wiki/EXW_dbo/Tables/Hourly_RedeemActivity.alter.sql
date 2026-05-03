-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.Hourly_RedeemActivity
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Hourly_RedeemActivity summarises customer redemption transaction volume for the rolling 7 most recent calendar days, aggregated to one row per cryptocurrency per day. It is one of six tables rebuilt each hour by SP_EXW_Hourly and feeds Tableau operational KPI dashboards with near-real-time visibility into how many redemption transactions are flowing and their USD value - without requiring queries against the full historical WalletDB transaction tables. **Scope**: Sent transactions with TransactionTypeId = 0 (Redeem) only. TransactionTypeId = 8 (RedeemAsic) is excluded. Only cryptos that had at least one qualifying redemption on a given date produce a row - there are no zero-count placeholder rows. **Row structure**: One row per CryptoID × calendar Date per SP run. The `Date` column is the transaction date (when the redeem was sent), not the SP run date. `ReportDate` is the SP run date. T

