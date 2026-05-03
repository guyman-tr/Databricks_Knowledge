-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- DDR dashboard-style aggregates for the **calendar quarter containing `@edate`**, rolled up by periodic snapshot dimensions at `@edate`. **Time logic:** `BI_DB_DDR_Customer_Periodic_Status` uses `Date = @edate` with quarter-to-date flags in `*_ThisQuarter` columns. `BI_DB_V_DDR_MIMO`, `BI_DB_V_DDR_Revenue_Breakdown`, `BI_DB_V_DDR_Non_Revenue_Actions`, and `BI_DB_V_DDR_PnL` are summed per customer over **`Date` from first day of the quarter through `@edate`** (`DATEADD(qq, DATEDIFF(qq, 0, @edate), 0)` … `@edate`). `BI_DB_V_DDR_AUM` is **`Date = @edate` only**. `*_FTDA` uses `MAX` of daily FTDA over that quarter-to-date window, then `SUM(CASE WHEN …)` with periodic first-deposit flags.

