-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_ConversionFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns **deposit/withdraw conversion-fee** rows from `BI_DB_DepositWithdrawFee`: **ConversionFee** is **PIPsCalculation** for rows with **DateID BETWEEN @sdateInt AND @edateInt**, joined to customer snapshot as-of the fee date (`Dim_Range`) and optionally to **Fact_BillingDeposit** / **Fact_BillingWithdraw** to expose **IsRecurring** on matched deposits (LEFT JOIN on parsed `TransactionID` when `TransactionType` is `Deposit` or `Withdraw`).

