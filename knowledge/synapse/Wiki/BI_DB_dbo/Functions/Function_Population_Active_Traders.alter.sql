-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Active_Traders
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Flags **DDR-style “active traders”** per customer per `DateID` inside `[@sdateInt, @edateInt]`. **TP leg:** **`Fact_CustomerAction`** with **`ActionTypeID IN (1, 39, 15, 17)`**, **`ISNULL(IsAirDrop,0) = 0`**, customer in **`Fact_SnapshotCustomer`** with **`IsValidCustomer = 1`**, **`DateID`** in range and inside snapshot **`Dim_Range`**. **Options leg:** **`Function_Revenue_OptionsPlatform(@sdateInt, @edateInt, 1)`** rows with **`ActionTypeID = 1`**, joined to **`Dim_Customer`** for `GCID`. Unioned rows drive **`MAX(CASE …)`** asset-class and copy flags.

