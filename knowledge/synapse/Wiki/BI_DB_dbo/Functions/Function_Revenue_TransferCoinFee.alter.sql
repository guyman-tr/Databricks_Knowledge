-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_TransferCoinFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Transfer-to-coin redeem commission revenue: `Fact_CustomerAction` rows with `ActionTypeID` 30 and `IsRedeem` 1, exposed as `TransferCoinFee` from `Commission`, with full snapshot customer profile columns for segmentation.

