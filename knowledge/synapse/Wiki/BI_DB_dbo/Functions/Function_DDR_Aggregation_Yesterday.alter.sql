-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_DDR_Aggregation_Yesterday
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- DDR metrics for **the single calendar day `@edate` only** (not month-to-date). The periodic layer is built from `BI_DB_DDR_Customer_Daily_Status` where `Date = @edate` (daily flags without `_ThisMonth` / `_ThisWeek` suffixes). `BI_DB_V_DDR_MIMO`, `BI_DB_V_DDR_Revenue_Breakdown`, `BI_DB_V_DDR_Non_Revenue_Actions`, and `BI_DB_V_DDR_PnL` are all restricted to **`Date = @edate`**. `BI_DB_V_DDR_AUM` is also **`Date = @edate`**. First-time-deposit amounts (`*_FTDA`) are `SUM(CASE WHEN first-deposit flag THEN daily FTDA ELSE 0 END)` inside the PERIODIC CTE on that same day, then summed again in the outer grouped select.

