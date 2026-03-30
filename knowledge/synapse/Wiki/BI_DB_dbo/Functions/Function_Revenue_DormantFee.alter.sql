-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_DormantFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns **dormant account fee** revenue from `Fact_CustomerAction` where `ActionTypeID` = 36 and `CompensationReasonID` = 30, negating `Amount` as `DormantFee`. Customer attributes from `Fact_SnapshotCustomer` aligned via `Dim_Range` for the action date.

