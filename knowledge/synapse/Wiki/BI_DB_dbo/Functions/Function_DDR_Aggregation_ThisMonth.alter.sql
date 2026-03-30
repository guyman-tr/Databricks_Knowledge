-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_DDR_Aggregation_ThisMonth
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- DDR dashboard-style aggregates for the **calendar month containing `@edate`**, rolled up by periodic snapshot dimensions at `@edate`. **Time logic:** `BI_DB_DDR_Customer_Periodic_Status` contributes one row per customer with `Date = @edate` (month-to-date flags in `*_ThisMonth` columns). `BI_DB_V_DDR_MIMO`, `BI_DB_V_DDR_Revenue_Breakdown`, `BI_DB_V_DDR_Non_Revenue_Actions`, and `BI_DB_V_DDR_PnL` are summed per customer over **`Date` from first day of that calendar month through `@edate`**. `BI_DB_V_DDR_AUM` is taken **only for `Date = @edate`** (as-of snapshot), then summed across customers in each output group. First-time-deposit amounts (`*_FTDA`) use `MAX` of the daily FTDA fields over the same month-to-date window in `BI_DB_DDR_Customer_Daily_Status`, then `SUM(CASE WHEN …)` with the month-to-date first-deposit flags from periodic status in the final select.

