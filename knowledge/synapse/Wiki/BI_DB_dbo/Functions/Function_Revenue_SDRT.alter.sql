-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_SDRT
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Returns UK **SDRT** (Stamp Duty Reserve Tax) style fee rows from the customer action position distribution (`ActionTypeID` 35, `IsFeeDividend` 3), with amount flipped to revenue sign as `SDRT`, copy and margin flags, and instrument type from `Dim_Instrument`. (SQL header comment refers generically to dividend/fee distribution; business filter is `IsFeeDividend` = 3.)

