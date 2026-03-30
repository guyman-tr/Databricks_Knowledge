-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_DDR_Aggregation_ThisWeek
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- DDR dashboard-style aggregates for the **calendar week containing `@edate`**, rolled up by periodic snapshot dimensions at `@edate`. **Time logic:** `BI_DB_DDR_Customer_Periodic_Status` uses `Date = @edate` with week-to-date flags in `*_ThisWeek` columns. `BI_DB_V_DDR_MIMO`, `BI_DB_V_DDR_Revenue_Breakdown`, `BI_DB_V_DDR_Non_Revenue_Actions`, and `BI_DB_V_DDR_PnL` are summed per customer over **`Date` from `DATEADD(week, DATEDIFF(ww, 0, @edate), -1)` through `@edate`** (week boundary as in the function). `BI_DB_V_DDR_AUM` is **`Date = @edate` only**. `*_FTDA` uses `MAX` of daily FTDA columns over that same week-to-date window in `BI_DB_DDR_Customer_Daily_Status`, then `SUM(CASE WHEN …)` with `*_ThisWeek` first-deposit flags in the final select.

