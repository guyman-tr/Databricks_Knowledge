-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_DDR_Aggregation_MoM
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Month-level DDR aggregates per customer with **`Period` = YYYYMM** between `@StartYearMonth` and `@EndYearMonth`. **Time logic:** `BI_DB_DDR_Customer_Periodic_Status` is filtered to **month-end rows only** (`DateID` = `MAX(DateID)` per `LEFT(DateID,6)` in the range). Within that set, the PERIODIC CTE groups by `RealCID` and month and applies `MAX` on dimension columns and `SUM` on `*_ThisMonth` counters. `BI_DB_V_DDR_MIMO`, revenue, PnL, and non-revenue views are aggregated **per `RealCID` and calendar month** (`GROUP BY LEFT(DateID,6)`), summing **all days in each month** that fall in the parameter range. AUM uses the **same month-end `DateID` rows** as periodic status. `*_FTDA` outputs are literal **0** in this variant (not computed). Many detailed MIMO/revenue columns are omitted or commented out in the function compared to the single-`@edate` TVFs.

