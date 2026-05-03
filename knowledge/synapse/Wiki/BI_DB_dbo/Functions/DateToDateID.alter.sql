-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.DateToDateID
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- Converts a `datetime` value into an integer **DateID** in `YYYYMMDD` form (via `FORMAT` to string then `CAST` to integer-compatible type). Used across BI logic for consistent date keys aligned with warehouse `DateID` columns.

