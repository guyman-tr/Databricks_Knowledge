-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_AdminFee
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns **administration fee** revenue at position grain from `BI_DB_Fact_Customer_Action_Position_Distribution` where **ActionTypeID IN (36)** and **CompensationReasonID = 117**. The output metric **AdminFee** is **-1 × Amount** (sign convention). Rows include instrument type, copy/margin/SQF flags from `Dim_Instrument` and `Function_Instrument_Snapshot_Enriched(@edateInt)`.

