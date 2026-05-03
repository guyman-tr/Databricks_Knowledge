-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_DDR_Aggregation_YoY
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Year-level DDR aggregates per customer with **`Period` = calendar year (YYYY)** between `@StartYear` and `@EndYear`. **Time logic:** `BI_DB_DDR_Customer_Periodic_Status` is filtered to **one row per year per customer**: `DateID` must equal `MAX(DateID)` grouped by `LEFT(DateID, 4)` within the year range (the latest available snapshot day in that year). The PERIODIC CTE then groups by `RealCID` and `LEFT(DateID,4)` with `MAX` on dimensions and `SUM` on `*_ThisYear` counters. `BI_DB_V_DDR_MIMO`, revenue, PnL, and non-revenue views aggregate **per `RealCID` and calendar year** (`GROUP BY LEFT(DateID,4)`), summing **all days in each year** in range. AUM aligns to the same year-end `DateID` rows as periodic status. `*_FTDA` outputs are literal **0**. Column coverage matches the reduced MoM-style shape (many detailed fields omitted in SQL).

