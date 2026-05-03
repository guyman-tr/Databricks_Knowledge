-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_Total
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Returns collectible revenue at customer-by-date grain aligned with DDR (daily revenue-generating actions), joined to snapshot customer attributes for segmentation. Staking is unioned separately from `Function_Revenue_StakingFee` (with one-month lag vs DDR) and excluded metric rows named `StakingLagOneMonth` from the main fact.

