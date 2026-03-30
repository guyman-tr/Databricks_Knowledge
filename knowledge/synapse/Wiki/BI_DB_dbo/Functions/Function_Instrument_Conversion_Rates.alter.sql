-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Instrument_Conversion_Rates
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Builds per-instrument **USD conversion multipliers** (bid/ask, raw and spreaded) as of the latest price row strictly before the datetime boundary implied by `@DateID`. Handles same-currency pairs, direct USD legs, and cross pairs triangulated via USD using sibling `Dim_Instrument` rows and their latest prices.

