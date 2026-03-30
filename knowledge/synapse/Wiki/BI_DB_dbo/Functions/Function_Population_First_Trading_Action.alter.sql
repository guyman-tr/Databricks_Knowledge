-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_First_Trading_Action
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns each customer’s **first eligible trading-platform action** row: **`Fact_CustomerAction`** with **`ActionTypeID IN (1, 17, 39)`** (open / mirror-style opens), **`(IsAirDrop = 0 OR IsAirDrop IS NULL)`**, ordered by **`DateID`, `Occurred`**, **`ROW_NUMBER` = 1** per `RealCID`. Optional **`@IsDepositor`** filters to **`Dim_Customer.IsDepositor = 1`**. **FirstActionType** rolls up instrument type and copy-fund mirror type.

