-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_RolloverFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns overnight rollover fee revenue from `BI_DB_Fact_Customer_Action_Position_Distribution` (`ActionTypeID` 35, `IsFeeDividend` 1), negating `Amount` as `RolloverFee`, enriched with instrument type, SQF flag, copy/margin indicators, and customer attributes carried on the distribution row.

