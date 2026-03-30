-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_ConversionFee_WithPositionData
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Same grain as `Function_Revenue_ConversionFee`: **ConversionFee** = **PIPsCalculation** with **DateID BETWEEN @sdateInt AND @edateInt** (plus snapshot `Dim_Range` join). Adds **position-level attributes** for IBAN-linked flows via **BI_DB_Positions_Opened_From_IBAN** / **BI_DB_Positions_Closed_To_IBAN**, then **Dim_Position** / **Dim_Instrument**, and **ExecutionIBANTradeSuccess** when IBAN trade rows lack a resolved position.

